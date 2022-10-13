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
#include "Lighting.cginc"

sampler2D _MatCap;
float _Matcap;
float _MatCapMult;
float _MatCapAdd;
float _MatCapBias;
float _MatCapIntensity;
float _MatCapInset;

float _RimMultiplyGradientMin;
float _RimMultiplyGradientMax;
float _RimMultiplyEdgeSoftness;

float _RimAddMult;
float _RimAddBias;
float _RimAddColorBlend;
float4 _RimAddColor;

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
    const float3 worldSpaceViewDir = normalize(worldPosition - _WorldSpaceCameraPos.xyz);
    float3 up = mul((float3x3)UNITY_MATRIX_I_V, float3(0,1,0));
    const float3 right = normalize(cross(up, worldSpaceViewDir));
    up = cross(worldSpaceViewDir, right);
    const float2 matcap = mul(float3x3(right, up, worldSpaceViewDir), normalizedWorldNormal).xy;

    LitData ld;
    ld.matcapUV = matcap * .5 + .5;
    ld.rimScalar = saturate(length(matcap));
    
    return ld;
}

inline void applyMatcap(inout float3 col, float2 matcapUV)
{
    float3 mc = tex2D(_MatCap, float2(lerp(_MatCapInset, 1 - _MatCapInset, matcapUV.x ), lerp(_MatCapInset, 1 - _MatCapInset, matcapUV.y)));
    col.rgb = lerp(col, col * mc, _MatCapMult);
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
    rimScalar *= _RimAddMult;
    rimScalar = pow(rimScalar, _RimAddBias);
    col = lerp(col, col + _RimAddColor, rimScalar * _RimAddColorBlend);
}

inline void applyLocalLighting(inout float3 col, const float3 normalizedWorldNormal, const float3 worldPosition)
{
    const LitData ld = calcLitData(normalizedWorldNormal, worldPosition);
    applyMatcap(col, ld.matcapUV);
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

//https://github.com/lukis101/VRCUnityStuffs/blob/master/SH/s_SH_Wrapped.shader
// http://www.geomerics.com/wp-content/uploads/2015/08/CEDEC_Geomerics_ReconstructingDiffuseLighting1.pdf
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
    float3 L0 = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
    float3 nonLinearSH = float3(0, 0, 0);
    nonLinearSH.r = shEvaluateDiffuseL1Geomerics_local(L0.r, unity_SHAr.xyz, normal);
    nonLinearSH.g = shEvaluateDiffuseL1Geomerics_local(L0.g, unity_SHAg.xyz, normal);
    nonLinearSH.b = shEvaluateDiffuseL1Geomerics_local(L0.b, unity_SHAb.xyz, normal);
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

float _VertexColorBlend;
float _VertexColorBias;

inline void applyVertexColors(inout float3 col, float3 vertexColor, float alpha)
{
    vertexColor = saturate(vertexColor);
    vertexColor = pow(vertexColor, _VertexColorBias);
    col = lerp(col, col * vertexColor, _VertexColorBlend * alpha);
}