#ifndef GT_TOON_OUTLINE_INCLUDED
#define GT_TOON_OUTLINE_INCLUDED

#include "UnityCG.cginc"

Texture2D _GTToonGrabTexture;
float4 _GTToonGrabTexture_TexelSize;
SamplerState _GTToonOutline_bilinear_clamp_sampler;

// Outline Color
float4 _OutlineColor;
Texture2D _OutlineColorTex;

// Outline Size
float _LineSize;
float _LineSizeNear;
float _NearLineSizeRange;

// Depth Outline
float _LocalEqualizeThreshold;

// Depth Outline Gradient
float _DepthGradientMin;
float _DepthGradientMax;

// Normal Outline Gradient
float _NormalGradientMin;
float _NormalGradientMax;

// Normal Outline Gradient
float _ConvexNormalGradientMin;
float _ConvexNormalGradientMax;

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
		const float4 sample = _GTToonGrabTexture.Sample(_GTToonOutline_bilinear_clamp_sampler, sampleUv);
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
	sd.depthMin = 1;
	sd.depthMax = 0;

	const float2 difference = saturate(texelSize - (kernelSize * 2));
	const float2 adjustedTexelSize = texelSize - difference;
	
	UNITY_UNROLL
	for (int i = 0; i < KERNEL_SAMPLE_COUNT; ++i)
	{
		SamplePass(sd.samples[i],
			sd.depthMin,
			sd.depthMax,
			uv + adjustedTexelSize * _KernelOffsets[i],
			kernelSize);
	}

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

	// if min/max get to close you get artifacts, so force a certain difference
	float2 depthMax = clamp(sd.depthMax, sd.depthMin + .03, 1);

	UNITY_UNROLL
	for (int i = 0; i < KERNEL_SAMPLE_COUNT; ++i)
	{
		td.values[i] = CalcToon(
			sd.samples[i],
			sd.depthMin,
			depthMax);
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

// from the mighty bgolus https://bgolus.medium.com/distinctive-derivative-differences-cce38d36797b
inline float4 FancyFWidth(float4 value)
{
	const float4 dx = ddx_fine(value);
	const float4 dy = ddy_fine(value);
	return max(dot(dx, dx), dot(dy, dy));
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

	depth = smoothstep(
		_DepthGradientMin,
		_DepthGradientMax,
		depth);
	
	// TBH this farDepthDist/farNormalDist lerping and math is kind of eye-balled
	// was once adjustable values but decided on some goods ones and to hardcode them
	// may need to change in the future?
	const float farDepthDist = 4;
	const float idMult = lerp(.4, 1, saturate(dist / farDepthDist));
	id = smoothstep(
		.05,
		idMult,
		id);
	
	depth = max(depth, id);

	// curvatures
	const float farNormalDist = 10;
	const float normalMult = 1;
	const float farNormalMult = 10;
    const float concaveMult = lerp(normalMult, farNormalMult, saturate(dist / farNormalDist));
    concavity = saturate(concavity * concaveMult);
	concavity = smoothstep(
		_NormalGradientMin,
		_NormalGradientMax,
		concavity);
    
    const float convexMult = lerp(normalMult, farNormalMult, saturate(dist / farNormalDist));
    convexity = saturate(convexity * convexMult);
	convexity = smoothstep(
		_ConvexNormalGradientMin,
		_ConvexNormalGradientMax,
		convexity);

	const float curvature = max(concavity, convexity);

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
	const float4 outlineColor = _OutlineColorTex.Sample(_GTToonOutline_bilinear_clamp_sampler, mainUv) * _OutlineColor;
	applyToonOutline(col, screenUv, outlineColor, dist);
}

#endif