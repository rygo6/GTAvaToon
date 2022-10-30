// Third-Party VRChatCG.cginc intended to be a repository of explicitly VRChat specific
// implementations that you can always import into any project.

// Unlicensed: https://unlicense.org/

#ifndef VRCHAT_CG_INCLUDED
#define VRCHAT_CG_INCLUDED

// ## Features
// The following feature already works in the Beta client, and will also work in-editor once we release an SDK update.
//
// - Added 3 shader globals that can be accessed by any avatar or world shader:
//     - `float _VRChatCameraMode`:
//         - `0` - Rendering normally
//         - `1` - Rendering in VR handheld camera
//         - `2` - Rendering in Desktop handheld camera
//         - `3` - Rendering for a screenshot
//     - `float _VRChatMirrorMode`:
//         - `0` - Rendering normally, not in a mirror
//         - `1` - Rendering in a mirror viewed in VR
//         - `2` - Rendering in a mirror viewed in desktop mode
//     - `float3 _VRChatMirrorCameraPos` - World space position of mirror camera (eye independent, "centered" in VR)

float _VRChatCameraMode;
float _VRChatMirrorMode;
float3 _VRChatMirrorCameraPos;

#define VRC_NORMAL_CAMERA_MODE 0;
#define VRC_VR_HANDHELD_CAMERA_MODE 1;
#define VRC_DESKTOP_HANDHELD_CAMERA_MODE 2;
#define VRC_SCREENSHOT_CAMERA_MODE 3;

inline bool VRCCameraModeNormal()
{
    return _VRChatCameraMode == VRC_NORMAL_CAMERA_MODE;
}

inline bool VRCCameraModeVRHandheld()
{
    return _VRChatCameraMode == VRC_VR_HANDHELD_CAMERA_MODE;
}

inline bool VRCCameraModeDesktopHandheld()
{
    return _VRChatCameraMode == VRC_DESKTOP_HANDHELD_CAMERA_MODE;
}

inline bool VRCCameraModeScreenshot()
{
    return _VRChatCameraMode == VRC_DESKTOP_HANDHELD_CAMERA_MODE;
}

#define VRC_NO_MIRROR 0;
#define VRC_IN_VR_MIRROR 1;
#define VRC_IN_DESKTOP_MIRROR 2;

inline bool VRCNoMirror()
{
    return _VRChatMirrorMode == VRC_NO_MIRROR;
}

inline bool VRCInVRMirror()
{
    return _VRChatMirrorMode == VRC_IN_VR_MIRROR;
}

inline bool VRCInDesktopMirror()
{
    return _VRChatMirrorMode == VRC_IN_DESKTOP_MIRROR;
}

// https://github.com/cnlohr/shadertrixx#variants-you-can-ditch-thanks-3
// This technically doesn't work and you must copy it into the base shader, but once VRC
// upgrades to 2020+ can use #include_with_pragmas https://docs.unity3d.com/Manual/shader-include-directives.html
#pragma skip_variants DYNAMICLIGHTMAP_ON LIGHTMAP_ON LIGHTMAP_SHADOW_MIXING DIRLIGHTMAP_COMBINED

// https://github.com/iigomaru/iigo-iigo/blob/e1249f932e0ff01e23300794a63dc0d51e0de840/iigo.cginc#L19
// Use Center Eye Position so there is less disparity between the eyes in stereo rendering.
#if defined(USING_STEREO_MATRICES)
#define VRC_CENTER_CAMERA_POS (_VRChatMirrorMode > 0 ? _VRChatMirrorCameraPos : (unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]) / 2)
#else
#define VRC_CENTER_CAMERA_POS (_VRChatMirrorMode > 0 ? _VRChatMirrorCameraPos : _WorldSpaceCameraPos.xyz)
#endif

#endif