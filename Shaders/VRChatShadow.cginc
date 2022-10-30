// Add the following pass to the end of your shader for proper shadows.

/*
        Pass {
            Tags {"LightMode" = "ShadowCaster"}
            HLSLPROGRAM
            #pragma vertex shadow_vert
            #pragma fragment shadow_frag
            #pragma multi_compile_shadowcaster
            #include "VRChatShadow.cginc"
            ENDHLSL
        }
*/

// Unlicensed: https://unlicense.org/

#ifndef VRCHAT_SHADOW_INCLUDED
#define VRCHAT_SHADOW_INCLUDED

#include "UnityCG.cginc"

struct shadow_appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct shadow_v2f
{
    float4 pos : SV_POSITION;
    UNITY_VERTEX_OUTPUT_STEREO
};

shadow_v2f shadow_vert(shadow_appdata v)
{
    shadow_v2f o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(shadow_v2f, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
    return o;
}

float4 shadow_frag(shadow_v2f i) : SV_Target
{
    return 0;
}

#endif