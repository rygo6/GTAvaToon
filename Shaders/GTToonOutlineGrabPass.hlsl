#ifndef GT_TOON_OUTLINE_GRAB_PASS_INCLUDED
#define GT_TOON_OUTLINE_GRAB_PASS_INCLUDED

#include "UnityCG.cginc"
#include "VRChatCG.cginc"

struct grabpass_appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 uv0 : TEXCOORD0;
    #ifdef GT_OutlineGrabPass_APPDATA
        GT_OutlineGrabPass_APPDATA
    #endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct grabpass_v2f
{
    float4 pos : POSITION;
    centroid float4 normal_depth : NORMAL;
    #ifdef GT_OutlineGrabPass_V2F
        GT_OutlineGrabPass_V2F
    #endif
    UNITY_VERTEX_OUTPUT_STEREO
};

float _BoundingExtents;
float _DepthId;

inline float linearStep(float a, float b, float x)
{
    return saturate((x - a)/(b - a));
}

grabpass_v2f grabpass_vert(const grabpass_appdata v)
{
    grabpass_v2f o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(grabpass_v2f, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    const float3 PlayerCenterCamera = VRC_CENTER_CAMERA_POS;

    float3 position = v.vertex;

    // modify vertex positions in object space using this define
    #ifdef GT_OutlineGrabPass_OSVERTEX
        GT_OutlineGrabPass_OSVERTEX
    #endif

    const float3 worldPos = mul(unity_ObjectToWorld, float4(position, 1.0));

    // modify vertex positions in world space using this define
    #ifdef GT_OutlineGrabPass_WSVERTEX
        GT_OutlineGrabPass_WSVERTEX
    #endif

    o.pos = UnityWorldToClipPos(worldPos);
    
    const float4 centerPos = mul(unity_ObjectToWorld, float4(0,0,0,1));
    const float centerDis = distance(centerPos, PlayerCenterCamera);
    const float dist = distance(worldPos, PlayerCenterCamera);
    const float depth = linearStep(centerDis - _BoundingExtents, centerDis + _BoundingExtents, dist);
    
    o.normal_depth.xy = COMPUTE_VIEW_NORMAL * 0.5 + 0.5;
    o.normal_depth.z = depth;
    o.normal_depth.w = _DepthId;
    
    return o;
}

float4 grabpass_frag(grabpass_v2f i) : SV_Target
{
    return i.normal_depth;
}

#endif