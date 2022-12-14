#ifndef GT_LIT_INCLUDED
#define GT_LIT_INCLUDED

// Purpose of this lighting scheme is to:
// 1. Enable a definition of a "Local" lighting. This is lighting which ignores the world, and is explicitly use defined.
// 2. Blend that Local lighting with a somewhat averaged "World" lighting, so the avatar's lighting is not completely
//    disconnected from the world, but doesn't explicitly obey the lighting of the world.
//
// Currently the 'Local Lighting' is just a matcap and rimlight setting. I do have more ideas for this.
//
// Then the 'World Lighting' is Spherical Harmonics + Single Direct Light combined in such a manner
// that the world lighting will look relatively the same irrelevant of if your in a world with it all
// baked to spherical harmonics or a worl with indirect SH + Direct Realtime Light

#include "UnityCG.cginc"
#include "VRChatCG.cginc"
#include "Lighting.cginc"

Texture2D _LightingColorTex;
float4 _LightingColorTex_TexelSize;
float4 _LightingColor;

Texture2D _MatCapTex;

SamplerState _GTLit_bilinear_clamp_Sampler;

float _MatCapMult;
float _MatCapAdd;
float _MatCapBias;
float _MatCapIntensity;
float _MatCapInset;

float _RimAddGradientMin;
float _RimAddGradientMax;

float _RimMultiplyGradientMin;
float _RimMultiplyGradientMax;
float _RimMultiplyEdgeSoftness;

float _RimAddMult;
float _RimAddBias;
float _RimAddColorBlend;
float4 _RimAddColor;

float _VertexColorBlend;

float _ProbeAverage;

struct LitData
{
    float2 matcapUV;
    float rimScalar;
};

// Calc matcap uvs, then also use this for the rimscalar as its more correct than COMPUTER_VIEW_NORMAL
inline LitData calcLitData(float3 normalizedWorldNormal, float3 worldPosition)
{
    // bgolus matcap https://gist.github.com/bgolus/02e37cd76568520e20219dc51653ceaa
    // yes it be better than others
    const float3 worldSpaceViewDir = normalize(worldPosition - VRC_CENTER_CAMERA_POS);
    float3 up = mul((float3x3)UNITY_MATRIX_I_V, float3(0,1,0));
    const float3 right = normalize(cross(up, worldSpaceViewDir));
    up = cross(worldSpaceViewDir, right);
    const float2 matcap = mul(float3x3(right, up, worldSpaceViewDir), normalizedWorldNormal).xy;

    LitData ld;
    ld.matcapUV = matcap * .5 + .5;
    ld.rimScalar = saturate(length(matcap));
    
    return ld;
}

inline void applyMatcap(inout float3 col, const float2 matcapUV, const float fileAlpha)
{
    const float4 mc = _MatCapTex.Sample(_GTLit_bilinear_clamp_Sampler, float2(lerp(_MatCapInset, 1 - _MatCapInset, matcapUV.x ), lerp(_MatCapInset, 1 - _MatCapInset, matcapUV.y)));
    col.rgb = lerp(col, col * mc, _MatCapMult * fileAlpha);
    // https://photoblogstop.com/photoshop/photoshop-blend-modes-explained
    float3 screenCol = 1 - (1 - mc) * (1 - col); // screen
    // float3 screenCol = col / (1 - mc); // color doge
    col.rgb = saturate(lerp(col, screenCol, _MatCapAdd));
}

inline void applyRimDarken(inout float3 col, float rimScalar)
{
    const float fRimLight = fwidth(rimScalar) * _RimMultiplyEdgeSoftness;
    rimScalar = smoothstep(_RimMultiplyGradientMax + fRimLight, _RimMultiplyGradientMin - fRimLight, rimScalar);
    col *= rimScalar;
}

inline void applyRimLighten(inout float3 col, float rimScalar)
{
    rimScalar = smoothstep(_RimAddGradientMin, _RimAddGradientMax, rimScalar);
    col = lerp(col, col + _RimAddColor, rimScalar * _RimAddColorBlend);
}

inline void applyLocalLighting(inout float3 col, const float3 normalizedWorldNormal, const float3 worldPosition, const float alpha)
{
    const LitData ld = calcLitData(normalizedWorldNormal, worldPosition);
    applyMatcap(col, ld.matcapUV, alpha);
    applyRimLighten(col, ld.rimScalar);
    applyRimDarken(col, ld.rimScalar);
}

float _DirectBlackLevel;
float _DirectWhiteLevel;
float _DirectOutputBlackLevel;
float _DirectOutputWhiteLevel;
float _DirectGamma;

// Adapt photoshop levels math from here https://stackoverflow.com/a/48859502/1580359
inline void applyLevels(inout float3 lightValue, float blackLevel, float whiteLevel, float blackOutputLevel, float whiteOutputLevel, float gammaCorrection)
{
    lightValue = (lightValue - blackLevel) / (whiteLevel - blackLevel);
    lightValue = saturate(lightValue);
    lightValue = pow(lightValue, gammaCorrection);
    lightValue = saturate(lightValue);
    lightValue = lightValue * (whiteOutputLevel - blackOutputLevel) + blackOutputLevel;
    lightValue = saturate(lightValue);
}

inline void applyLevels(inout float3 lightValue)
{
    applyLevels(lightValue, _DirectBlackLevel, _DirectWhiteLevel, _DirectOutputBlackLevel, _DirectOutputWhiteLevel, _DirectGamma);
}

inline float3 calcFinalLight(float3 diffuse, float3 shLight, float3 directLight)
{
    float3 finalLight = 1;
    finalLight.xyz = diffuse;
    finalLight.xyz *= shLight;
    finalLight.xyz += directLight;        
    return saturate(finalLight);
}

/// shEvaluateDiffuseL1Geomerics_local and BetterSH9 methods are MIT Licensed and are derived from:
/// https://github.com/lukis101/VRCUnityStuffs/blob/master/SH/s_SH_Wrapped.shader
///
/// MIT License
///
/// Copyright (c) 2019 Dj Lukis.LT
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE.
float shEvaluateDiffuseL1Geomerics_local(float L0, float3 L1, float3 n)
{
    // average energy
    float R0 = L0;

    // avg direction of incoming light
    float3 R1 = 0.5f * L1;

    // directional brightness
    float lenR1 = length(R1);

    // linear angle between normal and direction 0-1
    float q = dot(normalize(R1), n) * 0.5 + 0.5;
    q = saturate(q); // Silent: Thanks to ScruffyRuffles for the bug identity.

    // power for q
    // lerps from 1 (linear) to 3 (cubic) based on directionality
    float p = 1.0f + 2.0f * lenR1 / R0;

    // dynamic range constant
    // should vary between 4 (highly directional) and 0 (ambient)
    float a = (1.0f - lenR1 / R0) / (1.0f + lenR1 / R0);

    return R0 * (a + (1.0f - a) * (p + 1.0f) * pow(q, p));
}
float3 BetterSH9(float3 normal)
{
    float probeAverage = 101 - _ProbeAverage;
    float4 SHAr = _ProbeAverage < 51 ? unity_SHAr : ((unity_SHAr * probeAverage) + unity_SHAg + unity_SHAb) / (2.0 + probeAverage);
    float4 SHAg = _ProbeAverage < 51 ? unity_SHAg : (unity_SHAr + (unity_SHAg * probeAverage) + unity_SHAb) / (2.0 + probeAverage);
    float4 SHAb = _ProbeAverage < 51 ? unity_SHAb : (unity_SHAr + unity_SHAg + (unity_SHAb * probeAverage)) / (2.0 + probeAverage);
    
    float3 L0 = float3(SHAr.w, SHAg.w, SHAb.w);
    float3 nonLinearSH = float3(0, 0, 0);
    nonLinearSH.r = shEvaluateDiffuseL1Geomerics_local(L0.r, SHAr.xyz, normal);
    nonLinearSH.g = shEvaluateDiffuseL1Geomerics_local(L0.g, SHAg.xyz, normal);
    nonLinearSH.b = shEvaluateDiffuseL1Geomerics_local(L0.b, SHAb.xyz, normal);
    nonLinearSH = max(nonLinearSH, 0);
    return nonLinearSH;
}


// Return Direct + Ambient if all baked in probes, or just ambient if relying on realtime direct light
inline float3 calcSHLighting(float3 normalizedWorldSpaceNormal)
{
    // float3 sh = ShadeSH9(float4(normalizedWorldSpaceNormal, 1));
    float3 sh = BetterSH9(float4(normalizedWorldSpaceNormal, 1));
    return saturate(sh);
}

// Return direct light specifically in a way it will match when baked to probes
inline float3 calcDirectLighting(float3 diffuse, float attenuation, float3 normalizedWorldSpaceNormal)
{
    // apply direct light understand more here https://catlikecoding.com/unity/tutorials/rendering/part-17/
    
    // _worldSpaceLightpos always directional https://forum.unity.com/threads/_worldspacelightpos0-how-it-works.435673/#post-2816927
    const float3 n = normalizedWorldSpaceNormal;
    const float3 l = _WorldSpaceLightPos0.xyz;
    
    // learn about from here https://seblagarde.wordpress.com/2012/01/08/pi-or-not-to-pi-in-game-lighting-equation/
    const float wrap = 1; // wrap of 1 seems to match light probes, which is my intent, so hardcode it.
    float3 ndotl = ( diffuse / (1 + wrap) ) * (dot(n, l) + wrap) / (1 + wrap);
    
    return saturate(ndotl * attenuation * _LightColor0.rgb);
}

inline void applyWorldLighting(inout float3 col, float3 normalizedWorldSpaceNormal, float attenuation)
{
    // technically could just pass diffuse in, but if you apply levels to both
    // shLight and directlight you end up with different result between
    // sh scene and realtime lit scene. So calc all lighting off white diffuse
    // apply levels to that, then multiply on real diffuse.
    float3 diffuseLight = float3(1,1,1);
    float3 shLight = calcSHLighting(normalizedWorldSpaceNormal);
    float3 directLight = calcDirectLighting(diffuseLight, attenuation, normalizedWorldSpaceNormal);                
    float3 finalLight = calcFinalLight(diffuseLight, shLight, directLight);
    applyLevels(finalLight);
    col *= finalLight;  
}

inline void applyAOVertexColors(inout float3 col, float3 vertexColor, float fileAlpha)
{
    vertexColor = saturate(vertexColor);
    col = lerp(col, col * vertexColor, fileAlpha * _VertexColorBlend);
}

// Overload for when cameraPos is supplied
inline void applyLighting(inout float3 col, float2 uv, float attenuation, float3 normalizedWorldSpaceNormal, float3 worldPosition, float3 aoVertColor)
{
    const float4 lightColorSample = _LightingColorTex.Sample(_GTLit_bilinear_clamp_Sampler, uv) * _LightingColor;
    applyAOVertexColors(col, aoVertColor, lightColorSample.a);
    applyLocalLighting(col, normalizedWorldSpaceNormal, worldPosition, lightColorSample.a);
    applyWorldLighting(col, normalizedWorldSpaceNormal, attenuation);
    col += lightColorSample.rgb;
}

#endif