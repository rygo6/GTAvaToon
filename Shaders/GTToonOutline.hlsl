#include "UnityCG.cginc"

#define RAD2DEG (180.0 / UNITY_PI);

Texture2D _GTToonGrabTexture;
float4 _GTToonGrabTexture_TexelSize;
SamplerState _bilinear_clamp_Sampler;

Texture2D _OutlineColorTex;
float4 _OutlineColor;

float _NormalSampleMult;
float _NormalSampleBias;
float _FarNormalSampleMult;

float _ConvexSampleMult;
float _ConvexSampleBias;
float _FarConvexSampleMult;

float _FarDist;

float _DepthSilhouetteMultiplier;
float _LocalEqualizeThreshold;
float _DepthGradientMin;
float _DepthGradientMax;
float _DepthEdgeSoftness;

float _LineSizeNear;
float _LineSize;
float _NearLineSizeRange;

float _NormalEdgeSoftness;
float _NormalGradientMin;
float _NormalGradientMax;

// N E S W
#define DIRECTIONAL_SAMPLE_COUNT 4
static const float2 _SampleOffsets[DIRECTIONAL_SAMPLE_COUNT] = { float2(0,1), float2(1,0), float2(0,-1), float2(-1,0) };

// #define NINE_KERNEL
#define FIVE_KERNEL

#ifdef NINE_KERNEL
// M N E S W NE NW SE SW
#define KERNEL_SAMPLE_COUNT 9
static const float2 _KernelOffsets[KERNEL_SAMPLE_COUNT] = {
	float2(0, 0),
	float2(1, 1), float2(-1, 1), float2(1, -1), float2(-1, -1),
	float2(0, 1), float2(1, 0), float2(0, -1), float2(-1, 0),
};
#endif

#ifdef FIVE_KERNEL
// M NE NW SE SW
#define KERNEL_SAMPLE_COUNT 5
static const float2 _KernelOffsets[KERNEL_SAMPLE_COUNT] = {
	float2(0, 0),
	float2(1, 1), float2(-1, 1), float2(1, -1), float2(-1, -1),
};
#endif

struct SampleData {
	float3 samples[KERNEL_SAMPLE_COUNT][4];
	float minZ;
	float maxZ;
	float contrastZ;
};

struct ToonData {
	float3 values[KERNEL_SAMPLE_COUNT];
	
	float3 m() { return values[0]; }
	
	float3 ne()	{ return values[1]; }
	float3 nw()	{ return values[2]; }
	float3 se()	{ return values[3]; }
	float3 sw()	{ return values[4]; }

#ifdef NINE_KERNEL
	float3 n()	{ return values[5]; }
	float3 e()	{ return values[6]; }
	float3 s()	{ return values[7]; }
	float3 w()	{ return values[8]; }
#endif
};

inline float invLerp(float from, float to, float value)
{
    return saturate((value - from) / (to - from));
}

void SamplePass(out float3 samples[4], inout float minZ, inout float maxZ, float2 uv, float2 kernelSize)
{
    UNITY_UNROLL
	for (int sampleIndex = 0; sampleIndex < DIRECTIONAL_SAMPLE_COUNT; sampleIndex++)
	{
		const float2 sampleUv = uv + (_SampleOffsets[sampleIndex] * kernelSize);
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
		SamplePass(sd.samples[i],
			sd.minZ,
			sd.maxZ,
			uv + _GTToonGrabTexture_TexelSize * _KernelOffsets[i],
			kernelSize);
	}
	
	sd.contrastZ = sd.maxZ - sd.minZ;
	
	return sd;
}

inline float linearStep(float a, float b, float x)
{
	return saturate((x - a)/(b - a));
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
	UNITY_UNROLL
	for (int i = 0; i < DIRECTIONAL_SAMPLE_COUNT; i++)
	{
		float depth = samples[i].z;
		minDepth = min(minDepth, depth);
		maxDepth = max(maxDepth, depth);
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
		td.values[i] = CalcToon(
			sd.samples[i],
			sd.minZ,
			sd.maxZ);
	}

	return td;
}

// partly derived from https://catlikecoding.com/unity/tutorials/advanced-rendering/fxaa/
inline float3 DeterminePixelBlendFactor (ToonData td)
{
#ifdef NINE_KERNEL
	float3 filter = 2 * (td.n() + td.e() + td.s() + td.w());
	filter += td.m();
	filter += td.ne() + td.nw() + td.se() + td.sw();
	filter *= 1.0 / 13;
#endif

#ifdef FIVE_KERNEL
	float3 filter = td.m() * 2;
	filter += td.ne() + td.nw() + td.se() + td.sw();
	filter /= 6.0;
#endif
	
	const float3 blendFactor = smoothstep(0, 1, filter);
	return blendFactor;
}

// tnx https://github.com/cnlohr/shadertrixx
inline bool IsVR() {
	// USING_STEREO_MATRICES
#if UNITY_SINGLE_PASS_STEREO
	return true;
#else
	return false;
#endif
}

inline bool IsInMirror()
{
    return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
}

inline bool IsInMirrorInVR()
{
	return IsVR() && IsInMirror();
}

inline float SampleToonOutline(float2 uv, float dist)
{
	// this math to equalize against FOV + Screensize is a bit eye-balled...
    const float fov = atan(1.0 / unity_CameraProjection._m11) * 1000;
    const float lineSize = lerp(_LineSizeNear, _LineSize, saturate(dist / _NearLineSizeRange));
    float2 kernelSizeMultiplier = lineSize * _ScreenParams.xy / fov / dist / (IsInMirrorInVR() ? 2.0 : 1.0);
	kernelSizeMultiplier.x *= _ScreenParams.y / _ScreenParams.x; // fix ratio!

	// 1.0/zw because y can be flipped! Yes it caused issues.
	// https://forum.unity.com/threads/_maintex_texelsize-whats-the-meaning.110278/#post-1580744
	const float2 kernelSize = (1.0 / _GTToonGrabTexture_TexelSize.zw) * kernelSizeMultiplier;
	
	const SampleData sd = SamplePassKernel(uv, kernelSize);
	const ToonData td = CalcToonKernel(sd);
	const float3 pixelBlend = DeterminePixelBlendFactor(td);
			
	float depth = pixelBlend.x;
	float averageDepth = sd.contrastZ;
	float concavity = pixelBlend.y;
	float convexity = pixelBlend.z;

	const float fDepth = fwidth(depth) * _DepthEdgeSoftness;
	depth = smoothstep(_DepthGradientMin - fDepth, _DepthGradientMax + fDepth, depth);
	
	// I am adding contrast sample back over the as it has a wider falloff than pixelblend
	// and can add to the softess/AA of the silhouette line.
	// Also keeps silhouette better at a distance as the local equalized depth can produce
	// an odd artifact at the edge.
	// lerp 2 to 1 based on distance as up close it can create a kind 'halo' light grey around
	// the main line.	
	const float averageDepthMult = lerp(2, 1, saturate(dist / _FarDist));
	averageDepth = saturate(averageDepth * averageDepthMult * _DepthSilhouetteMultiplier);
	
	depth = max(depth, averageDepth);

	// curvatures
    const float concaveMult = lerp(_NormalSampleMult, _FarNormalSampleMult, saturate(dist / _FarDist));
    concavity = saturate(concavity * concaveMult);
    
    const float convexMult = lerp(_ConvexSampleMult, _FarConvexSampleMult, saturate(dist / _FarDist));
    convexity = saturate(convexity * convexMult);

    float curvature = max(concavity, convexity);
	const float fMaxCurve = fwidth(curvature) * _NormalEdgeSoftness;
    curvature = smoothstep(_NormalGradientMin - fMaxCurve, _NormalGradientMax + fMaxCurve, curvature);

	return max(depth, curvature);
}

inline void applyToonOutline(inout float3 col, float2 screenUv, float2 mainUv, float dist)
{
	const float4 colorTex = _OutlineColorTex.Sample(_bilinear_clamp_Sampler, mainUv);
	const float outline = SampleToonOutline(screenUv, dist);
	col = lerp(col, _OutlineColor * colorTex.rgb, outline * colorTex.a);
}

inline void applyToonOutline(inout float3 col, float2 uv, float dist, float alpha, float3 outlineColor)
{
	const float outline = SampleToonOutline(uv, dist);
	col = lerp(col, outlineColor, outline * alpha);
}