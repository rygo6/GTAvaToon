#include "UnityCG.cginc"

#define RAD2DEG (180.0 / UNITY_PI);

Texture2D _GTToonGrabTexture;
float4 _GTToonGrabTexture_TexelSize;
SamplerState _bilinear_clamp_Sampler;
    
float4 _OutlineColor;

float _NormalSampleMult;
float _NormalSampleBias;
float _FarNormalSampleMult;

float _ConvexSampleMult;
float _ConvexSampleBias;
float _FarConvexSampleMult;

float _FarNormalSampleDist;
float _FarDepthSampleDist;

float _LocalEqualizeThreshold;
float _DepthMult;
float _FarDepthMult;
float _DepthBias;
float _DepthGradientMin;
float _DepthGradientMax;
float _DepthEdgeSoftness;

float _DepthContrastMult;
float _FarDepthContrastMult;

float _LineSizeNear;
float _LineSize;
float _NearLineSizeRange;

float _NormalEdgeSoftness;
float _NormalGradientMin;
float _NormalGradientMax;

float _TexelSampleOffset;

#define DIRECTIONAL_SAMPLE_COUNT 4
#define KERNEL_SAMPLE_COUNT 9
// N E S W
static const float2 _SampleOffsets[DIRECTIONAL_SAMPLE_COUNT] = { float2(0,1), float2(1,0), float2(0,-1), float2(-1,0) };
// M N E S W NE NW SE SW
static const float _KernelXSteps[KERNEL_SAMPLE_COUNT] = { 1, 1, 2, 1, 0, 2, 0, 2, 0 };
static const float _KernelYSteps[KERNEL_SAMPLE_COUNT] = { 1, 2, 1, 0, 1, 2, 2, 0, 0 };
static const float2 _KernelOffsets[KERNEL_SAMPLE_COUNT] = {
	float2(0, 0),
	float2(0, 1), float2(1, 0), float2(0, -1), float2(-1, 0),
	float2(1, 1), float2(-1, 1), float2(1, -1), float2(-1, -1)
};

struct SampleData {
	float3 samples[3][3][4];
	float minZ;
	float maxZ;
	float contrastZ;
};

struct ToonData {
    float3 values[3][3];
	
	float3 m() { return values[1][1]; }
	
	float3 n()	{ return values[1][2]; }
	float3 e()	{ return values[2][1]; }
	float3 s()	{ return values[1][0]; }
	float3 w()	{ return values[0][1]; }
	
	float3 ne()	{ return values[2][2]; }
	float3 nw()	{ return values[0][2]; }
	float3 se()	{ return values[2][0]; }
	float3 sw()	{ return values[0][0]; }
};

inline float invLerp(float from, float to, float value)
{
    return saturate((value - from) / (to - from));
}

void SamplePass(out float3 samples[4], inout float minZ, inout float maxZ, float2 uv, float kernelSize)
{
    UNITY_UNROLL
	for (int sampleIndex = 0; sampleIndex < DIRECTIONAL_SAMPLE_COUNT; sampleIndex++)
	{
		const float2 sampleUv = uv + _SampleOffsets[sampleIndex] * kernelSize;
		const float4 sample = _GTToonGrabTexture.Sample(_bilinear_clamp_Sampler, sampleUv);
		const float2 exNormalSample = sample.xy * 2.0 - 1.0;
		samples[sampleIndex].xy = float2(exNormalSample.x, exNormalSample.y);
		samples[sampleIndex].z = DecodeFloatRG(sample.wz);
		
		minZ = min(minZ, samples[sampleIndex].z);
		maxZ = max(maxZ, samples[sampleIndex].z);
	}
}
            
inline SampleData SamplePassKernel(float2 uv, float2 kernelSize)
{
	SampleData sd;
	sd.minZ = 1;
	sd.maxZ = 0;
	
	UNITY_UNROLL
	for (int i = 0; i < KERNEL_SAMPLE_COUNT; ++i)
	{
		SamplePass(sd.samples[_KernelXSteps[i]][_KernelYSteps[i]],
			sd.minZ,
			sd.maxZ,
			uv + _GTToonGrabTexture_TexelSize * _KernelOffsets[i],
			kernelSize);
	}
	
	sd.contrastZ = sd.maxZ - sd.minZ;
	
	return sd;
}

float3 CalcToon(float3 samples[DIRECTIONAL_SAMPLE_COUNT], float minZ, float maxZ) {

	const float3 nNorm = float3(samples[0].xy, 0.5);
	const float3 eNorm = float3(samples[1].xy, 0.5);
	const float3 sNorm = float3(samples[2].xy, 0.5);
	const float3 wNorm = float3(samples[3].xy, 0.5);
	// https://madebyevan.com/shaders/curvature/
    const float normalDifference = (cross(wNorm, eNorm).y - cross(sNorm, nNorm).x);

	const float concavity = saturate(normalDifference * -1); 
	const float convexity = saturate(normalDifference);

	float minDepth = 1;
	float maxDepth = 0;
	float meanDepth = 0;
	for (int i = 0; i < DIRECTIONAL_SAMPLE_COUNT; i++)
	{
		float depth = samples[i].z;
		minDepth = min(minDepth, depth);
		maxDepth = max(maxDepth, depth);
		meanDepth += depth;
	}
		
	maxDepth = smoothstep(minZ, maxZ + _LocalEqualizeThreshold, maxDepth);
	minDepth = smoothstep(minZ, maxZ + _LocalEqualizeThreshold, minDepth);
	float depthContrast = maxDepth - minDepth;
    
	return float3(depthContrast, concavity, convexity);
}

inline ToonData CalcToonKernel(SampleData sd)
{
	ToonData td;

	UNITY_UNROLL
	for (int i = 0; i < KERNEL_SAMPLE_COUNT; ++i)
	{
		td.values[_KernelXSteps[i]][_KernelYSteps[i]] = CalcToon(
			sd.samples[_KernelXSteps[i]][_KernelYSteps[i]],
			sd.minZ,
			sd.maxZ);
	}

	return td;
}

// partly derived from https://catlikecoding.com/unity/tutorials/advanced-rendering/fxaa/
inline float3 DeterminePixelBlendFactor (ToonData td)
{
	float3 filter = 2 * (td.n() + td.e() + td.s() + td.w());
	filter += td.ne() + td.nw() + td.se() + td.sw();
	filter *= 1.0 / 12;
	const float3 blendFactor = smoothstep(0, 1, filter);
	return blendFactor;
}

// tnx https://github.com/cnlohr/shadertrixx
inline bool IsInMirror()
{
    return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
}

inline float SampleToonOutline(float2 uv, float dist)
{
	// this math to equalize against FOV + Screensize is a bit eye-balled...
    const float fov = atan(1.0 / unity_CameraProjection._m11) * 1000;
    const float lineSize = lerp(_LineSizeNear, _LineSize, saturate(dist / _NearLineSizeRange));
    const float2 kernelSizeMultiplier = lineSize * _ScreenParams.xy / fov / dist / (IsInMirror() ? 2.0 : 1.0);

	const float2 texelSize = 1.0 / _GTToonGrabTexture_TexelSize.zw;
    const float2 kernelSize = texelSize * kernelSizeMultiplier;
	
	const SampleData sd = SamplePassKernel(uv, kernelSize);
	const ToonData td = CalcToonKernel(sd);
	const float3 pixelBlend = DeterminePixelBlendFactor(td);
		
	float depth = pixelBlend.x;
	float averageDepth = sd.contrastZ;
	float concavity = pixelBlend.y;
	float convexity = pixelBlend.z;

	// deal with depths
	const float depthMult = lerp(_DepthMult, _FarDepthMult, saturate(dist / _FarDepthSampleDist));
	depth = depth * depthMult;
	depth = pow(depth, _DepthBias);
	depth = saturate(depth);
	const float fDepth = fwidth(depth) * _DepthEdgeSoftness;;
	depth = smoothstep(_DepthGradientMin - fDepth, _DepthGradientMax + fDepth, depth);

	// I am adding contrast sample back over the as it has a wider falloff than pixelblend
	// and can add to the softess/AA of the sillhouette line
	const float contrastDepthMult = lerp(_DepthContrastMult, _FarDepthContrastMult, saturate(dist / _FarDepthSampleDist));
	averageDepth = averageDepth * contrastDepthMult;
	averageDepth = saturate(averageDepth);
	
	depth = max(depth, averageDepth);

	// deal with curvatures
    const float normalMult = lerp(_NormalSampleMult, _FarNormalSampleMult, saturate(dist / _FarNormalSampleDist));
    concavity = concavity * normalMult;
    concavity = pow(concavity, _NormalSampleBias);
    concavity = saturate(concavity);
    
    const float convexMult = lerp(_ConvexSampleMult, _FarConvexSampleMult, saturate(dist / _FarNormalSampleDist));
    convexity = convexity * convexMult;
    convexity = pow(convexity, _ConvexSampleBias);
    convexity = saturate(convexity);

    float curvature = max(concavity, convexity);
	const float fMaxCurve = fwidth(curvature) * _NormalEdgeSoftness;
    curvature = smoothstep(_NormalGradientMin - fMaxCurve, _NormalGradientMax + fMaxCurve, curvature);

	return max(depth, curvature);
}

inline void applyToonOutline(inout float3 col, float2 uv, float dist, float alpha)
{
	const float outline = SampleToonOutline(uv, dist);
	col = lerp(col, _OutlineColor, outline * alpha);
}