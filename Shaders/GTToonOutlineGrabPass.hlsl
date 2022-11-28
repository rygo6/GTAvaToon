#ifndef GT_TOON_OUTLINE_GRAB_PASS_INCLUDED
#define GT_TOON_OUTLINE_GRAB_PASS_INCLUDED

#include "UnityCG.cginc"
#include "VRChatCG.cginc"

struct grabpass_appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 uv0 : TEXCOORD0;
    float4 color : COLOR;
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
float _DiscardVertexAOThreshold;

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
    
    float3 position = v.color.a < _DiscardVertexAOThreshold ? 0. / 0. : v.vertex;

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

    // If you are wondering wtf am I doing depth like this? The purpose is to compress
    // the relevant depth data to the extents of the avatar so you can fit more
    // depth into the low precision framebuffer. In worlds which do not have HDR
    // enabled, and are using a low precision framebuffer, there is not enough data
    // in the depth to produce outlines without bad artifacting due to the bands
    // If VRC ever FORCES high precision framebuffers this could be changed. But
    // this also evades the issue of needing a light in the world to force camera depth on.
    //
    // Then if your also wondering WTF am I manually inputting the extents instead of calcing
    // it, its because the extents value needs to be the same for all meshes of an avatar
    // otherwise the other depth settings will not be consistent across meshes.
    //
    // Then even further if your wondering WTF am I using a grabpass for depth? Depth is not
    // actually the primary purpose for the grabpass, the normals are. There is no way to calc
    // non-faceted normals off the depth of the framebuffer, and rendering normals in a GrabPass
    // produces normals that respect the mesh smoothing. This is absolutely necessary to use the
    // normals to draw concave/convex outlines off of. But since I only need two channels for
    // normal data I decided to also put depth in here too as then I can use the extents compressing
    // trick to get around issues with low precision framebuffers, then I could also encode in other data
    // like the "DepthID" to let me get even more detail.
    const float4 centerPos = mul(unity_ObjectToWorld, float4(0,0,0,1));
    const float centerDis = distance(centerPos, PlayerCenterCamera);
    const float dist = distance(worldPos, PlayerCenterCamera);
    const float depth = linearStep(centerDis - _BoundingExtents, centerDis + _BoundingExtents, dist);
    
    o.normal_depth.xy = COMPUTE_VIEW_NORMAL * 0.5 + 0.5;
    o.normal_depth.z = depth;
    o.normal_depth.w = _DepthId;
    
    return o;
}

float4 grabpass_frag(grabpass_v2f i, bool IsFacing : SV_IsFrontFace) : SV_Target
{
    return IsFacing ? i.normal_depth : float4(0, 0, 0, 1);
}

#endif