#ifndef GT_TOON_OUTLINE_GRAB_PASS_INCLUDED
#define GT_TOON_OUTLINE_GRAB_PASS_INCLUDED

#include "UnityCG.cginc"
#include "VRChatCG.cginc"

struct grabpass_appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
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
float _DepthOffset;

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

    // float4 centerPos = float4(unity_ObjectToWorld[3].xyz, 1); // gets the object space origin in world space directly from the transform
    const float4 centerPos = mul(unity_ObjectToWorld, float4(0,0,0,1));
    const float centerDis = distance(centerPos, PlayerCenterCamera);
    const float dist = distance(worldPos, PlayerCenterCamera);
    const float depth = linearStep(centerDis - _BoundingExtents, centerDis + _BoundingExtents, dist) + _DepthOffset;
    
    o.normal_depth.xy = COMPUTE_VIEW_NORMAL * 0.5 + 0.5;
    // TF is it wz?! Because all object write 1 into the a/w channel by default and
    // the EncodeFloatRG first R channel encodes a smooth gradient from near to far,
    // the second G channel encode the striping additional data. So by putting the
    // EncodeFloat R channel to the .w of the return col it forces all non-GTAvatoon
    // objects in the grabpass to be as pure white, or the greatest depth, when
    // you do DecodeFloat
    o.normal_depth.wz = EncodeFloatRG(clamp(depth, 0, .99));
    
    return o;
}

float4 grabpass_frag(grabpass_v2f i) : SV_Target
{
    return i.normal_depth;
}

#endif