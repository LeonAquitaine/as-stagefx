/**
 * AS_VFX_SnapshotFrame.1.fx - Composite a transformed snapshot onto the scene
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International (CC BY 4.0)
 *
 * Reads the persistent texture written by AS_VFX_Snapshot and composites a
 * cropped, 3D-transformed copy of it onto the current scene — for "photo
 * within a scene", "viewfinder", "phone screen showing earlier frame", and
 * similar effects.
 *
 * All length values (border, shadow offsets, blur radius, photo size) are in
 * percent of the central square (vmin %), so the composition stays consistent
 * across resolutions and aspect ratios. See docs/ImplementationGuide.md
 * "Length Units" for the full convention.
 *
 * Pair: requires AS_VFX_Snapshot to be active and ordered earlier in the
 * technique list (otherwise the snapshot in Current mode folds the consumer's
 * own output back into itself).
 */

#ifndef __AS_VFX_SnapshotFrame_1_fx
#define __AS_VFX_SnapshotFrame_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Snapshot.1.fxh"

namespace AS_SnapshotFrame {

// ============================================================================
// CONSTANTS
// ============================================================================

static const int CROP_NATIVE   = 0;
static const int CROP_SQUARE   = 1;
static const int CROP_4_5      = 2;
static const int CROP_9_16     = 3;
static const int CROP_2_3      = 4;
static const int CROP_3_2      = 5;
static const int CROP_4_3      = 6;
static const int CROP_16_9     = 7;
static const int CROP_21_9     = 8;
static const int CROP_CUSTOM   = 9;

static const int FILTER_NONE      = 0;
static const int FILTER_MONO      = 1;
static const int FILTER_SEPIA     = 2;
static const int FILTER_COOL      = 3;
static const int FILTER_WARM      = 4;
static const int FILTER_BLUR      = 5;
static const int FILTER_PIXELATE  = 6;
static const int FILTER_VIGNETTE  = 7;

// ============================================================================
// UI
// ============================================================================

// --- Crop ---
uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform int CropFormat <
    ui_type = "combo";
    ui_label = "Crop Format";
    ui_tooltip = "Output aspect ratio. Native preserves the snapshot's own aspect.";
    ui_items = "Native\0Square (1:1)\0Portrait 4:5\0Portrait 9:16\0Portrait 2:3\0"
               "Landscape 3:2\0Landscape 4:3\0Landscape 16:9\0Cinematic 21:9\0Custom\0";
    ui_category = "Crop";
> = CROP_NATIVE;

uniform float CropAspectCustom <
    ui_type = "slider";
    ui_label = "Custom Aspect Ratio";
    ui_tooltip = "Width / height. Active only when Crop Format is Custom.";
    ui_min = 0.25; ui_max = 4.0; ui_step = 0.01;
    ui_category = "Crop";
> = 1.0;

uniform float CropBiasX <
    ui_type = "slider";
    ui_label = "Crop Bias X";
    ui_tooltip = "Horizontal pan within the cropped window (-1 = left edge, +1 = right edge). "
                 "Has no effect at Zoom=1 when the crop axis matches the source aspect (no horizontal cropping happens).";
    ui_min = -1.0; ui_max = 1.0; ui_step = 0.01;
    ui_category = "Crop";
> = 0.0;

uniform float CropBiasY <
    ui_type = "slider";
    ui_label = "Crop Bias Y";
    ui_tooltip = "Vertical pan within the cropped window (-1 = top, +1 = bottom).";
    ui_min = -1.0; ui_max = 1.0; ui_step = 0.01;
    ui_category = "Crop";
> = 0.0;

uniform float CropZoom <
    ui_type = "slider";
    ui_label = "Zoom";
    ui_tooltip = "In-picture magnification (1 = native crop, 3 = 3x zoom). At zoom > 1 both bias sliders pan the magnified region.";
    ui_min = 1.0; ui_max = 3.0; ui_step = 0.01;
    ui_category = "Crop";
> = 1.0;

// --- Transform ---
uniform float2 PhotoPosition <
    ui_type = "drag";
    ui_label = "Position";
    ui_tooltip = "Photo center on screen. (0,0) = screen centre, +-1 = central-square edge.";
    ui_min = -1.5; ui_max = 1.5; ui_step = 0.001;
    ui_category = "Transform";
> = float2(0.0, 0.0);

uniform float PhotoSize <
    ui_type = "slider";
    ui_label = "Photo Size";
    ui_tooltip = "Longest edge of the cropped photo, in percent of the central square.";
    ui_min = 5.0; ui_max = 150.0; ui_step = 0.5;
    ui_category = "Transform";
> = 35.0;

uniform float PhotoDistance <
    ui_type = "slider";
    ui_label = "Distance (Z)";
    ui_tooltip = "Z-axis offset (vmin %). Negative pulls the photo closer to the viewer (larger), positive pushes it away (smaller).";
    ui_min = -50.0; ui_max = 50.0; ui_step = 0.1;
    ui_category = "Transform";
> = 0.0;

uniform float RotateX <
    ui_type = "slider";
    ui_label = "Rotate X (Pitch)";
    ui_min = -360.0; ui_max = 360.0; ui_step = 0.1;
    ui_category = "Transform";
> = 0.0;

uniform float RotateY <
    ui_type = "slider";
    ui_label = "Rotate Y (Yaw)";
    ui_min = -360.0; ui_max = 360.0; ui_step = 0.1;
    ui_category = "Transform";
> = 0.0;

uniform float RotateZ <
    ui_type = "slider";
    ui_label = "Rotate Z (Roll)";
    ui_min = -360.0; ui_max = 360.0; ui_step = 0.1;
    ui_category = "Transform";
> = 0.0;

uniform float PerspectiveFOV <
    ui_type = "slider";
    ui_label = "Perspective FOV";
    ui_tooltip = "Camera field-of-view in degrees. Lower = more orthographic (subtle tilt), higher = strong perspective foreshortening.";
    ui_min = 10.0; ui_max = 90.0; ui_step = 1.0;
    ui_category = "Transform";
> = 40.0;

// --- Frame ---
uniform float BorderThickness <
    ui_type = "slider";
    ui_label = "Border Thickness";
    ui_tooltip = "Border width in percent of the central square. 0 disables.";
    ui_min = 0.0; ui_max = 20.0; ui_step = 0.1;
    ui_category = "Frame";
> = 0.0;

uniform float3 BorderColor <
    ui_type = "color";
    ui_label = "Border Color";
    ui_category = "Frame";
> = float3(1.0, 1.0, 1.0);

uniform float CornerRadius <
    ui_type = "slider";
    ui_label = "Corner Radius";
    ui_tooltip = "Rounded corner radius in percent of the central square. 0 = sharp corners.";
    ui_min = 0.0; ui_max = 20.0; ui_step = 0.1;
    ui_category = "Frame";
> = 0.0;

uniform float EdgeFeather <
    ui_type = "slider";
    ui_label = "Edge Feather";
    ui_tooltip = "Soft alpha falloff at the photo edge, vmin %. 0 = sharp edge.";
    ui_min = 0.0; ui_max = 10.0; ui_step = 0.1;
    ui_category = "Frame";
> = 0.0;

// --- Shadow ---
uniform float ShadowOpacity <
    ui_type = "slider";
    ui_label = "Shadow Opacity";
    ui_tooltip = "0 disables the shadow entirely.";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_category = "Shadow";
> = 0.0;

uniform float3 ShadowColor <
    ui_type = "color";
    ui_label = "Shadow Color";
    ui_category = "Shadow";
> = float3(0.0, 0.0, 0.0);

uniform float ShadowOffsetX <
    ui_type = "slider";
    ui_label = "Shadow Offset X";
    ui_tooltip = "Horizontal shadow offset from the photo, vmin %.";
    ui_min = -25.0; ui_max = 25.0; ui_step = 0.1;
    ui_category = "Shadow";
> = 1.5;

uniform float ShadowOffsetY <
    ui_type = "slider";
    ui_label = "Shadow Offset Y";
    ui_tooltip = "Vertical shadow offset from the photo, vmin %.";
    ui_min = -25.0; ui_max = 25.0; ui_step = 0.1;
    ui_category = "Shadow";
> = 1.5;

uniform float ShadowDistance <
    ui_type = "slider";
    ui_label = "Shadow Distance";
    ui_tooltip = "Z-depth offset of the shadow plane behind the photo, vmin %. Larger values pair with larger blur for softer drops.";
    ui_min = 0.0; ui_max = 20.0; ui_step = 0.1;
    ui_category = "Shadow";
> = 1.0;

uniform float ShadowBlur <
    ui_type = "slider";
    ui_label = "Shadow Blur";
    ui_tooltip = "Shadow softening radius, vmin %. Implemented as edge feather on the shadow plane (cheap and rotation-correct).";
    ui_min = 0.0; ui_max = 15.0; ui_step = 0.1;
    ui_category = "Shadow";
> = 2.0;

// --- Filter ---
uniform int ShotFilter <
    ui_type = "combo";
    ui_label = "Shot Filter";
    ui_tooltip = "A single colour or treatment applied to the inserted photo (composes with the live scene).";
    ui_items = "None\0Monochrome\0Sepia\0Cool tone\0Warm tone\0Gaussian blur\0Pixelate\0Vignette\0";
    ui_category = "Filter";
> = FILTER_NONE;

uniform float FilterStrength <
    ui_type = "slider";
    ui_label = "Filter Strength";
    ui_tooltip = "Per-filter intensity. Maps to mix amount, blur radius, pixel block size, vignette darkness, etc.";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_category = "Filter";
> = 0.5;

// --- Stage / Final ---
AS_STAGEDEPTH_UI(EffectDepth)
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// ============================================================================
// HELPERS
// ============================================================================

float ResolveCropAspect(float sourceAspect) {
    if (CropFormat == CROP_NATIVE)  return sourceAspect;
    if (CropFormat == CROP_SQUARE)  return 1.0;
    if (CropFormat == CROP_4_5)     return 4.0 / 5.0;
    if (CropFormat == CROP_9_16)    return 9.0 / 16.0;
    if (CropFormat == CROP_2_3)     return 2.0 / 3.0;
    if (CropFormat == CROP_3_2)     return 3.0 / 2.0;
    if (CropFormat == CROP_4_3)     return 4.0 / 3.0;
    if (CropFormat == CROP_16_9)    return 16.0 / 9.0;
    if (CropFormat == CROP_21_9)    return 21.0 / 9.0;
    return CropAspectCustom;
}

// Returns float4 = (u0, v0, viewWidth, viewHeight) of the source-snapshot
// rectangle to sample, in UV space.
float4 ComputeSourceRect(float sourceAspect, float targetAspect) {
    float zoom = max(CropZoom, 1.0);
    float viewW, viewH;
    if (targetAspect >= sourceAspect) {
        // Target is wider than source -> vertical crop only at zoom=1.
        viewW = 1.0 / zoom;
        viewH = (sourceAspect / targetAspect) / zoom;
    } else {
        // Target is taller than source -> horizontal crop only at zoom=1.
        viewW = (targetAspect / sourceAspect) / zoom;
        viewH = 1.0 / zoom;
    }
    float cu = 0.5 + CropBiasX * (1.0 - viewW) * 0.5;
    float cv = 0.5 + CropBiasY * (1.0 - viewH) * 0.5;
    return float4(cu - viewW * 0.5, cv - viewH * 0.5, viewW, viewH);
}

// Standard XYZ Euler rotation matrix: R = R_z * R_y * R_x.
// Apply order is X first, then Y, then Z.
float3x3 BuildRotation(float rx, float ry, float rz) {
    float cx = cos(rx), sx = sin(rx);
    float cy = cos(ry), sy = sin(ry);
    float cz = cos(rz), sz = sin(rz);
    return float3x3(
        cz*cy,  cz*sy*sx - sz*cx,  cz*sy*cx + sz*sx,
        sz*cy,  sz*sy*sx + cz*cx,  sz*sy*cx - cz*sx,
         -sy,             cy*sx,             cy*cx
    );
}

// Ray vs photo plane intersection. Output is the local-space hit position
// (xy on the photo's plane, in pixel units). hitOk is set false if the ray
// missed the plane (parallel or facing away from camera).
//   rayOrigin, rayDir : world-space ray (camera at origin, +Z forward)
//   center            : world-space photo center
//   R                 : photo rotation (world = R * local; quad sits on local XY)
float2 IntersectPhoto(float3 rayOrigin, float3 rayDir, float3 center, float3x3 R, out bool hitOk) {
    // Photo at rest faces -Z toward the camera. After rotation its normal is R*(0,0,-1).
    float3 normal = -float3(R._13, R._23, R._33);
    float denom = dot(rayDir, normal);
    hitOk = false;
    if (denom > -1e-4) return float2(0.0, 0.0); // facing away or parallel
    float t = dot(center - rayOrigin, normal) / denom;
    if (t <= 0.0) return float2(0.0, 0.0);
    float3 hitWorld = rayOrigin + t * rayDir;
    float3 hitLocal = mul(transpose(R), hitWorld - center);
    hitOk = true;
    return hitLocal.xy;
}

// Signed distance from local-space hit point to the rounded-rect outline of
// the photo. Negative inside, 0 on edge, positive outside. cornerPx is the
// rounded-corner radius in pixels.
float SignedRoundedRectDist(float2 hitLocal, float halfW, float halfH, float cornerPx) {
    float2 q = abs(hitLocal) - float2(halfW, halfH) + cornerPx;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - cornerPx;
}

// Smooth alpha (1 inside, 0 outside) with optional feather over featherPx pixels.
float RoundedRectAlpha(float2 hitLocal, float halfW, float halfH, float cornerPx, float featherPx) {
    float dist = SignedRoundedRectDist(hitLocal, halfW, halfH, cornerPx);
    if (featherPx <= 0.0) return dist < 0.0 ? 1.0 : 0.0;
    return saturate(0.5 - dist / featherPx);
}

// --- Shot filters ---
float3 ApplyMonochrome(float3 c, float strength) {
    float gray = dot(c, float3(0.299, 0.587, 0.114));
    return lerp(c, float3(gray, gray, gray), strength);
}
float3 ApplySepia(float3 c, float strength) {
    float3 sepia = saturate(float3(
        dot(c, float3(0.393, 0.769, 0.189)),
        dot(c, float3(0.349, 0.686, 0.168)),
        dot(c, float3(0.272, 0.534, 0.131))
    ));
    return lerp(c, sepia, strength);
}
float3 ApplyCool(float3 c, float strength) {
    return lerp(c, saturate(c * float3(0.85, 0.95, 1.15)), strength);
}
float3 ApplyWarm(float3 c, float strength) {
    return lerp(c, saturate(c * float3(1.15, 1.0, 0.85)), strength);
}
float3 ApplyVignette(float3 c, float2 localNorm, float strength) {
    float d = length(localNorm);
    float vig = 1.0 - saturate((d - 0.4) / 0.6) * strength;
    return c * vig;
}

// 8-tap Poisson disc; used for the Gaussian-blur shot filter.
static const float2 POISSON8_0 = float2(-0.6195, -0.6378);
static const float2 POISSON8_1 = float2( 0.7405, -0.5523);
static const float2 POISSON8_2 = float2(-0.0838,  0.8916);
static const float2 POISSON8_3 = float2( 0.4878,  0.2769);
static const float2 POISSON8_4 = float2(-0.7855,  0.1428);
static const float2 POISSON8_5 = float2( 0.2354, -0.7820);
static const float2 POISSON8_6 = float2( 0.8741,  0.4283);
static const float2 POISSON8_7 = float2(-0.4131, -0.0734);

float3 SampleSnapshotBlurred(float2 uv, float radiusUVx, float radiusUVy) {
    float2 r = float2(radiusUVx, radiusUVy);
    float3 acc = tex2D(AS_StageFX_SnapshotSampler, uv).rgb;
    acc += tex2D(AS_StageFX_SnapshotSampler, uv + POISSON8_0 * r).rgb;
    acc += tex2D(AS_StageFX_SnapshotSampler, uv + POISSON8_1 * r).rgb;
    acc += tex2D(AS_StageFX_SnapshotSampler, uv + POISSON8_2 * r).rgb;
    acc += tex2D(AS_StageFX_SnapshotSampler, uv + POISSON8_3 * r).rgb;
    acc += tex2D(AS_StageFX_SnapshotSampler, uv + POISSON8_4 * r).rgb;
    acc += tex2D(AS_StageFX_SnapshotSampler, uv + POISSON8_5 * r).rgb;
    acc += tex2D(AS_StageFX_SnapshotSampler, uv + POISSON8_6 * r).rgb;
    acc += tex2D(AS_StageFX_SnapshotSampler, uv + POISSON8_7 * r).rgb;
    return acc * (1.0 / 9.0);
}

// Sample the snapshot at the cropped UV with any active filter applied.
// localNorm is the photo-plane position in -1..+1 (used by the vignette filter).
float3 SampleSnapshotWithFilter(float2 uv, float2 localNorm) {
    if (ShotFilter == FILTER_PIXELATE) {
        float blockSizePct = lerp(0.1, 10.0, FilterStrength);
        float2 blockUV = AS_PCT_TO_UV(blockSizePct);
        uv = (floor(uv / blockUV) + 0.5) * blockUV;
    }
    float3 c;
    if (ShotFilter == FILTER_BLUR) {
        float radiusPct = lerp(0.1, 5.0, FilterStrength);
        c = SampleSnapshotBlurred(uv, AS_PCT_TO_UV_X(radiusPct), AS_PCT_TO_UV_Y(radiusPct));
    } else {
        c = tex2D(AS_StageFX_SnapshotSampler, uv).rgb;
    }
    if (ShotFilter == FILTER_MONO)     c = ApplyMonochrome(c, FilterStrength);
    if (ShotFilter == FILTER_SEPIA)    c = ApplySepia(c, FilterStrength);
    if (ShotFilter == FILTER_COOL)     c = ApplyCool(c, FilterStrength);
    if (ShotFilter == FILTER_WARM)     c = ApplyWarm(c, FilterStrength);
    if (ShotFilter == FILTER_VIGNETTE) c = ApplyVignette(c, localNorm, FilterStrength);
    return c;
}

// ============================================================================
// PIXEL SHADER
// ============================================================================

float4 PS_SnapshotFrame(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    AS_DEPTH_EARLY_RETURN(texcoord, EffectDepth)

    // --- Photo dimensions (pixels) ---
    float sourceAspect = (float)BUFFER_WIDTH / (float)BUFFER_HEIGHT;
    float targetAspect = ResolveCropAspect(sourceAspect);
    float longSidePx   = AS_PCT_TO_PX(PhotoSize);
    float photoW, photoH;
    if (targetAspect >= 1.0) {
        photoW = longSidePx;
        photoH = longSidePx / targetAspect;
    } else {
        photoH = longSidePx;
        photoW = longSidePx * targetAspect;
    }
    float halfW = photoW * 0.5;
    float halfH = photoH * 0.5;

    // --- Camera & ray setup (camera at origin, +Z into screen) ---
    float fovRad   = radians(PerspectiveFOV);
    float focalPx  = (AS_REF_DIM * 0.5) / tan(fovRad * 0.5);
    float screenW  = (float)BUFFER_WIDTH;
    float screenH  = (float)BUFFER_HEIGHT;

    // Photo center on screen + relative pixel offset for this fragment.
    float2 photoCenterScreen = float2(screenW, screenH) * 0.5
                             + PhotoPosition * (AS_REF_DIM * 0.5);
    float2 pixelInScreen     = (texcoord - 0.5) * float2(screenW, screenH);
    float2 pxFromCenter      = pixelInScreen - (photoCenterScreen - float2(screenW, screenH) * 0.5);

    float photoZ = focalPx + AS_PCT_TO_PX(PhotoDistance);
    float3 photoCenter = float3(0.0, 0.0, photoZ);
    float3 rayOrigin   = float3(0.0, 0.0, 0.0);
    float3 rayDir      = normalize(float3(pxFromCenter, focalPx));

    float3x3 R = BuildRotation(radians(RotateX), radians(RotateY), radians(RotateZ));

    // --- Photo intersection ---
    bool   photoHit;
    float2 photoLocal = IntersectPhoto(rayOrigin, rayDir, photoCenter, R, photoHit);

    // --- Shadow intersection (offset photo plane, same orientation) ---
    float shadowAlpha = 0.0;
    if (ShadowOpacity > 0.001) {
        float3 shadowCenter = photoCenter + float3(
            AS_PCT_TO_PX(ShadowOffsetX),
            AS_PCT_TO_PX(ShadowOffsetY),
            AS_PCT_TO_PX(ShadowDistance)
        );
        bool   hitShadow;
        float2 shadowLocal = IntersectPhoto(rayOrigin, rayDir, shadowCenter, R, hitShadow);
        if (hitShadow) {
            float blurPx = max(AS_PCT_TO_PX(ShadowBlur), 0.5);
            float a = RoundedRectAlpha(shadowLocal, halfW, halfH,
                                       AS_PCT_TO_PX(CornerRadius), blurPx * 2.0);
            shadowAlpha = a * ShadowOpacity;
        }
    }

    // --- Resolve photo alpha + color ---
    float  photoAlpha = 0.0;
    float3 photoRGB   = float3(0.0, 0.0, 0.0);

    if (photoHit) {
        float borderPx  = AS_PCT_TO_PX(BorderThickness);
        float cornerPx  = AS_PCT_TO_PX(CornerRadius);
        float featherPx = max(AS_PCT_TO_PX(EdgeFeather), 0.5);
        float halfWOuter = halfW + borderPx;
        float halfHOuter = halfH + borderPx;

        float outerA = RoundedRectAlpha(photoLocal, halfWOuter, halfHOuter,
                                        cornerPx + borderPx, featherPx);
        float innerA = (borderPx > 0.001)
                     ? RoundedRectAlpha(photoLocal, halfW, halfH, cornerPx, featherPx)
                     : outerA;

        float4 srcRect    = ComputeSourceRect(sourceAspect, targetAspect);
        float2 photoNorm  = float2(photoLocal.x / max(halfW, 1.0),
                                   photoLocal.y / max(halfH, 1.0)) * 0.5 + 0.5;
        float2 sampleUV   = srcRect.xy + saturate(photoNorm) * srcRect.zw;
        float2 localNorm  = float2(photoLocal.x / max(halfW, 1.0),
                                   photoLocal.y / max(halfH, 1.0));
        float3 sampled    = SampleSnapshotWithFilter(sampleUV, localNorm);

        float borderA = saturate(outerA - innerA);
        photoRGB   = sampled * innerA + BorderColor * borderA;
        photoAlpha = saturate(outerA);
    }

    // --- Composite: shadow under photo, then photo over scene, then user blend ---
    float3 underShadow = lerp(_as_originalColor.rgb, ShadowColor, shadowAlpha);
    float3 layered     = lerp(underShadow, photoRGB, photoAlpha);
    float3 finalRGB    = AS_composite(layered, _as_originalColor.rgb, BlendMode, BlendAmount);
    return float4(finalRGB, _as_originalColor.a);
}

} // namespace AS_SnapshotFrame

technique AS_VFX_SnapshotFrame <
    ui_label   = "[AS] VFX: Snapshot Frame";
    ui_tooltip = "Composes a cropped, 3D-transformed view of the snapshot texture (written by AS_VFX_Snapshot) "
                 "onto the scene. Use to fake a printed photo, viewfinder, or phone screen showing an earlier moment.";
> {
    pass {
        VertexShader = PostProcessVS;
        PixelShader  = AS_SnapshotFrame::PS_SnapshotFrame;
    }
}

#endif // __AS_VFX_SnapshotFrame_1_fx
