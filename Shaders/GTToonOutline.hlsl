#ifndef GT_TOON_OUTLINE_INCLUDED
#define GT_TOON_OUTLINE_INCLUDED

#include "UnityCG.cginc"

Texture2D _GTToonGrabTexture;
float4 _GTToonGrabTexture_TexelSize;
SamplerState _bilinear_clamp_Sampler;

// Outline Color
float4 _OutlineColor;
Texture2D _OutlineColorTex;

// Outline Size
float _LineSize;
float _LineSizeNear;
float _NearLineSizeRange;

// Depth Outline
float _LocalEqualizeThreshold;
float _DepthSilhouetteMultiplier;

// Depth Outline Gradient
float _DepthGradientMin;
float _DepthGradientMax;
float _DepthEdgeSoftness;

// Normal Outline Gradient
float _NormalGradientMin;
float _NormalGradientMax;
float _NormalEdgeSoftness;

// Concave Normal Outline Sampling
float _NormalSampleMult;
float _FarNormalSampleMult;

// Convex Normal Outline Sampling
float _ConvexSampleMult;
float _FarConvexSampleMult;

// Normal Far Distance
float _FarDist;

// N E S W
#define DIRECTIONAL_SAMPLE_COUNT 4
static const float2 _SampleOffsets[DIRECTIONAL_SAMPLE_COUNT] = { float2(0,1), float2(1,0), float2(0,-1), float2(-1,0) };

// This is essentially the quincunx kernel

// I find you can't make the kernel smaller than this and still get good results
// because the distance between the samples is not large enough to produce a
// meaningful min/max values to appropriately compress via _LocalEqualizeThreshold.

// Also the extra smoothness of this kernel is ideal for thresholding min/max settings
// to deal in the detailing of the outline.

// M NE NW SE SW
#define KERNEL_SAMPLE_COUNT 5
static const float2 _KernelOffsets[KERNEL_SAMPLE_COUNT] = {
	float2(0, 0),
	float2(1, 1), float2(-1, 1), float2(1, -1), float2(-1, -1),
};

struct SampleData {
	// xy = normal, z = depth, w = id
	float4 samples[KERNEL_SAMPLE_COUNT][4];
	// x = depth, y = id
	float2 depthMin;
	float2 depthMax;
	float2 depthContrast;
};

struct ToonData {
	float4 values[KERNEL_SAMPLE_COUNT];
	
	float4 m() { return values[0]; }
	
	float4 ne()	{ return values[1]; }
	float4 nw()	{ return values[2]; }
	float4 se()	{ return values[3]; }
	float4 sw()	{ return values[4]; }
};

inline float invLerp(float from, float to, float value)
{
    return saturate((value - from) / (to - from));
}

void SamplePass(out float4 samples[4], inout float2 minZ, inout float2 maxZ, float2 uv, float2 kernelSize)
{
    UNITY_UNROLL
	for (int sampleIndex = 0; sampleIndex < DIRECTIONAL_SAMPLE_COUNT; sampleIndex++)
	{
		const float2 sampleUv = uv + (_SampleOffsets[sampleIndex] * kernelSize);
		const float4 sample = _GTToonGrabTexture.Sample(_bilinear_clamp_Sampler, sampleUv);
		const float2 exNormalSample = sample.xy * 2.0 - 1.0;
		samples[sampleIndex].xy = exNormalSample.xy;
		samples[sampleIndex].zw = sample.zw;
		
		minZ = min(minZ, sample.zw);
		maxZ = max(maxZ, sample.zw);
	}
}
            
inline SampleData SamplePassKernel(float2 uv, float2 texelSize, float2 kernelSize)
{
	SampleData sd;
	sd.depthMin = 10;
	sd.depthMax = -10;

	kernelSize = clamp(kernelSize, texelSize / 8, 100);
	float2 difference = texelSize - (kernelSize * 2);
	difference = difference < 0 ? 0 : difference;
	float2 adjustedTexelSize = texelSize - difference;
	
	UNITY_UNROLL
	for (int i = 0; i < KERNEL_SAMPLE_COUNT; ++i)
	{
		SamplePass(sd.samples[i],
			sd.depthMin,
			sd.depthMax,
			uv + adjustedTexelSize * _KernelOffsets[i],
			kernelSize);
	}
	
	sd.depthContrast = sd.depthMax - sd.depthMin;
	
	return sd;
}

inline float linearStep(float a, float b, float x)
{
	return saturate((x - a)/(b - a));
}

float4 CalcToon(float4 samples[DIRECTIONAL_SAMPLE_COUNT], float2 depthMin, float2 depthMax) {

	const float3 nNorm = float3(samples[0].xy, 0.5);
	const float3 eNorm = float3(samples[1].xy, 0.5);
	const float3 sNorm = float3(samples[2].xy, 0.5);
	const float3 wNorm = float3(samples[3].xy, 0.5);
	// https://madebyevan.com/shaders/curvature/
    const float normalDifference = (cross(wNorm, eNorm).y - cross(sNorm, nNorm).x);

	const float concavity = saturate(normalDifference * -1); 
	const float convexity = saturate(normalDifference);

	float2 minDepthId = 10;
	float2 maxDepthId = -10;
	UNITY_UNROLL
	for (int i = 0; i < DIRECTIONAL_SAMPLE_COUNT; i++)
	{
		const float2 depthId = samples[i].zw;
		minDepthId = min(minDepthId, depthId);
		maxDepthId = max(maxDepthId, depthId);
	}
	
	maxDepthId.x = smoothstep(depthMin.x, depthMax.x + _LocalEqualizeThreshold, maxDepthId.x);
	minDepthId.x = smoothstep(depthMin.x, depthMax.x + _LocalEqualizeThreshold, minDepthId.x);
	maxDepthId.y = smoothstep(depthMin.y, depthMax.y + .01, maxDepthId.y);
	minDepthId.y = smoothstep(depthMin.y, depthMax.y + .01, minDepthId.y);
	const float2 depthIdContrast = maxDepthId - minDepthId;
    
	return float4(concavity, convexity, depthIdContrast.x, depthIdContrast.y);
}

inline ToonData CalcToonKernel(SampleData sd)
{
	ToonData td;

	UNITY_UNROLL
	for (int i = 0; i < KERNEL_SAMPLE_COUNT; ++i)
	{
		td.values[i] = CalcToon(
			sd.samples[i],
			sd.depthMin,
			sd.depthMax);
	}

	return td;
}

// partly derived from https://catlikecoding.com/unity/tutorials/advanced-rendering/fxaa/
inline float4 DeterminePixelBlendFactor(ToonData td)
{
	float4 filter = td.m() * 2;
	filter += td.ne() + td.nw() + td.se() + td.sw();
	filter /= 6.0;	
	const float4 blendFactor = smoothstep(0, 1, filter);
	return blendFactor;
}

inline float SampleToonOutline(float2 uv, float dist)
{
	// this math to equalize against FOV + Screensize is a bit eye-balled...
    const float fov = atan(1.0 / unity_CameraProjection._m11) * 1000;
    const float lineSize = lerp(_LineSizeNear, _LineSize, saturate(dist / _NearLineSizeRange));
    float2 kernelSizeMultiplier = lineSize * _ScreenParams.xy / fov / dist;
	kernelSizeMultiplier.x *= _ScreenParams.y / _ScreenParams.x; // fix ratio!

	// 1.0/zw because y can be flipped! Yes it caused issues.
	// https://forum.unity.com/threads/_maintex_texelsize-whats-the-meaning.110278/#post-1580744
	const float2 texelSize = (1.0 / _GTToonGrabTexture_TexelSize.zw);
	const float2 kernelSize = texelSize * kernelSizeMultiplier;
	
	const SampleData sd = SamplePassKernel(uv, texelSize, kernelSize);
	const ToonData td = CalcToonKernel(sd);
	const float4 pixelBlend = saturate(DeterminePixelBlendFactor(td));

	float concavity = pixelBlend.x;
	float convexity = pixelBlend.y;
	float depth = pixelBlend.z;
	float id = pixelBlend.w;
	
	depth = smoothstep(_DepthGradientMin, _DepthGradientMax, depth);
	
	// TBH this is eyeballed ... maybe it needs to be changed?
	const float idMult = lerp(1, 2, saturate(dist / 2));
	depth = max(depth, id * idMult);

	// curvatures
    const float concaveMult = lerp(_NormalSampleMult, _FarNormalSampleMult, saturate(dist / _FarDist));
    concavity = saturate(concavity * concaveMult);
    
    const float convexMult = lerp(_ConvexSampleMult, _FarConvexSampleMult, saturate(dist / _FarDist));
    convexity = saturate(convexity * convexMult);

    float curvature = max(concavity, convexity);
    curvature = smoothstep(_NormalGradientMin, _NormalGradientMax, curvature);

	return max(depth, curvature);
}

// Alternative overload not used internally for situations where outline color and alpha is supplied not from a texture.
inline void applyToonOutline(inout float3 col, float2 screenUv, float4 outlineColor, float dist)
{
	const float outline = SampleToonOutline(screenUv, dist);
	col = lerp(col, outlineColor.rgb, outline * outlineColor.a);
}

// Standard overload where outline color and alpha is sampled from texture.
inline void applyToonOutline(inout float3 col, float2 screenUv, float2 mainUv, float dist)
{
	const float4 outlineColor = _OutlineColorTex.Sample(_bilinear_clamp_Sampler, mainUv) * _OutlineColor;
	applyToonOutline(col, screenUv, outlineColor, dist);
}

#endif