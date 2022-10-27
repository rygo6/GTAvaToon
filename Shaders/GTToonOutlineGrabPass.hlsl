#include "UnityCG.cginc"

struct grabpass_appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    #ifdef GT_OutlineGrabPass_APPDATA
        GT_OutlineGrabPass_APPDATA
    #endif
};

struct grabpass_v2f
{
    float4 pos : POSITION;
    // float3 wrldPosition : POSITION1;
    // centroid float3 wrldNormal : NORMAL0;
    // centroid float3 viewNormal : NORMAL1; 
    // float depth: DEPTH;
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

// tnx https://github.com/cnlohr/shadertrixx
//bool IsInMirror()
//{
//    return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
//}
            
grabpass_v2f grabpass_vert(const grabpass_appdata v)
{
    grabpass_v2f o;
    UNITY_INITIALIZE_OUTPUT(grabpass_v2f, o);
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    #if defined(USING_STEREO_MATRICES)
        float3 PlayerCenterCamera = ( unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1] ) / 2;
    #else
        float3 PlayerCenterCamera = _WorldSpaceCameraPos.xyz;
    #endif

    if (_VRChatMirrorMode > 0)
    {
        PlayerCenterCamera = _VRChatMirrorCameraPos;
    }

    float3 position = v.vertex;

    #ifdef GT_OutlineGrabPass_OSVERTEX
        GT_OutlineGrabPass_OSVERTEX
    #endif
    
    o.pos = UnityObjectToClipPos(float4(position, 1.0));
    
    const float3 worldPos = mul(unity_ObjectToWorld, float4(position, 1.0));
    const float4 centerPos = mul(unity_ObjectToWorld, float4(0,0,0,1));
    const float centerDis = distance(centerPos, PlayerCenterCamera);
    const float dist = distance(worldPos, PlayerCenterCamera);
    const float depth = linearStep(centerDis - _BoundingExtents, centerDis + _BoundingExtents, dist) + _DepthOffset;

    // o.depth = depth;

    // o.wrldPosition = mul(unity_ObjectToWorld, v.vertex);
    // o.wrldNormal = UnityObjectToWorldNormal(v.normal);

    // o.viewNormal = COMPUTE_VIEW_NORMAL;

    o.normal_depth.xy = COMPUTE_VIEW_NORMAL * 0.5 + 0.5;
    o.normal_depth.wz = EncodeFloatRG(clamp(depth, 0, .99));
    
    return o;
}

float4 grabpass_frag(grabpass_v2f i) : SV_Target
{
    float4 col = 0;
    // TF is it wz?! Because all object write 1 into the a/w channel by default and
    // the EncodeFloatRG first R channel encodes a smooth gradient from near to far,
    // the second G channel encode the striping additional data. So by putting the
    // EncodeFloat R channel to the .w of the return col it forces all non-GTAvatoon
    // objects in the grabpass to be as pure white, or the greatest depth, when
    // you do DecodeFloat
    // col.wz = EncodeFloatRG(clamp(i.depth, 0, .99));;

    // bgolus matcap, https://gist.github.com/bgolus/02e37cd76568520e20219dc51653ceaa
    // yes it produced better results in frag
    // const float3 worldSpaceNormal = normalize(i.wrldNormal);
    // const float3 worldSpaceViewDir = normalize(i.wrldPosition - _WorldSpaceCameraPos.xyz);
    // float3 up = mul((float3x3)UNITY_MATRIX_I_V, float3(0,1,0));
    // const float3 right = normalize(cross(up, worldSpaceViewDir));
    // up = cross(worldSpaceViewDir, right);
    // const float2 normal = mul(float3x3(right, up, worldSpaceViewDir), worldSpaceNormal).xy;
    // col.xy = normal * 0.5 + 0.5;
    // col.x = IsInMirror() ? 1 - col.x : col.x;
    // Ok yes the bgolus math seems to produce better normals for the outline, but is the extra math work the supposed improvement over COMPUTE_VIEW_NORMAL?
    // col.xy = i.viewNormal.xy;
    
    // return col;
    return i.normal_depth;
}