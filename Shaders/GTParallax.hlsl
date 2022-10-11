#include "UnityCG.cginc"

//https://gist.github.com/Float3/00b7192b92384532df276cb7e5c7b327
inline bool IsOrthographicCamera()
{
    return unity_OrthoParams.w == 1 || UNITY_MATRIX_P[3][3] == 1;
}

inline float2 calcParallax(in float height, in float3 tangentViewDir)
{
    return ((height * - 1) + 1) * (tangentViewDir.xy / tangentViewDir.z);
}

// from poiyomi which took it from ASE??
// but should I take from bgolus? https://forum.unity.com/threads/achieving-a-parallax-effect.1332780/
inline float3 calcTangentViewDir(float3 worldPosition, float3 worldTangent, float3 worldBinormal, float3 worldNormal)
{
    float3 viewDir = !IsOrthographicCamera()
         ? normalize(_WorldSpaceCameraPos - worldPosition)
         : normalize(UNITY_MATRIX_I_V._m02_m12_m22);
    float3 tanToWorld0 = float3(worldTangent.x, worldBinormal.x, worldNormal.x);
    float3 tanToWorld1 = float3(worldTangent.y, worldBinormal.y, worldNormal.y);
    float3 tanToWorld2 = float3(worldTangent.z, worldBinormal.z, worldNormal.z);
    float3 ase_tanViewDir = tanToWorld0 * viewDir.x + tanToWorld1 * viewDir.y + tanToWorld2 * viewDir.z;
    float3 tangentViewDir = normalize(ase_tanViewDir);

    // this is completely eyeballed, helps prevent distortion at extreme angles of skinned mesh renderer
    tangentViewDir.b = clamp(tangentViewDir.b, .3, 1);

    return tangentViewDir;
}

// this is such a cluster hackey thing right now, not ready for real use
inline void layerParallaxes(inout float3 diffuse, sampler2D sdfTex, float sdfThreshold, float2 uv, float4 color0, float4 color1, float4 color2, float parallaxHeight, float3 tangentViewDir)
{
    const int stepCount = 24;
    for (int step = 0; step < stepCount; ++step)
    {
        float2 stepPos = 0;
        stepPos.x = (1.0 / stepCount) * (step * .8) + .05;
        stepPos.y = step * .1;
        float4 stepColor = lerp(color0, color1, stepPos.x);
        stepColor.a = 1;

        const int layerCount = 1;
        for (int layer = 0; layer < layerCount; ++layer)
        {
            int invLayer = layerCount - layer;
            float2 pos = calcParallax(invLayer * parallaxHeight + 1, tangentViewDir);
            pos.x += stepPos.x;
            pos.y -= stepPos.y;
            const float sdf2 = tex2D(sdfTex, float2(uv.x + pos.x, uv.y + pos.y)).a;
            const float fd2 = fwidth(sdf2) * (invLayer * .8) + .02;
            diffuse = lerp(diffuse, stepColor - (invLayer * 0.2), smoothstep(sdfThreshold - fd2, sdfThreshold + fd2, sdf2) * color2.a);
        }
        float2 finalPos = uv;
        finalPos.x += stepPos.x;
        finalPos.y -= stepPos.y;
        const float finalSdf2 = tex2D(sdfTex, finalPos).a;
        const float finalFd2 = fwidth(finalSdf2) * .75;
        diffuse = lerp(diffuse, stepColor, smoothstep(sdfThreshold - finalFd2, sdfThreshold + finalFd2, finalSdf2) * color2.a);
    }
}