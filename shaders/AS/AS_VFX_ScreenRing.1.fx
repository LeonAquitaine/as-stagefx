/**
 * AS_VFX_ScreenRing.1.fx - Screen-space textured ring with depth occlusion
 * Author: Leon Aquitaine
 * Date: 2025-05-05
 * License: Creative Commons Attribution 4.0 International
 *
 * DESCRIPTION:
 * Draws a textured ring/band on the screen at a specified screen position and depth.
 * The ring is occluded by scene geometry closer than the specified depth.
 *
 * FEATURES:
 * - Textured ring rendering in screen space.
 * - User-defined target position (Screen XY) and depth (Z).
 * - User-defined radius and thickness.
 * - Texture mapping around the ring circumference.
 * - Depth buffer occlusion.
 * - Blending modes and intensity control.
 * - Debug visualization modes.
 */

#ifndef __AS_VFX_ScreenRing_1_fx
#define __AS_VFX_ScreenRing_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // Includes ReShadeUI.fxh, provides UI macros, helpers

// ============================================================================
// TEXTURES
// ============================================================================
#ifndef RING_TEXTURE_PATH
#define RING_TEXTURE_PATH "Copyright4kH.png" // Default texture path
#endif

#include "ReShadeUI.fxh" // Needed for texture UI element

texture RingTexture < source = RING_TEXTURE_PATH; ui_label="Ring Texture"; ui_tooltip="Wide, short texture (e.g., 2048x60) to wrap around the ring."; > { Width=1450; Height=100; Format=RGBA8; };
sampler RingSampler { Texture = RingTexture; AddressU = WRAP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR; };

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
// Target Position Z (Depth) Range
static const float TARGET_DEPTH_MIN = 0.0; // Closest possible depth
static const float TARGET_DEPTH_MAX = 1.0; // Farthest possible depth (assuming linearized 0-1)
static const float TARGET_DEPTH_DEFAULT = 0.1; // Default relatively close

// Ring Geometry Range
static const float RING_RADIUS_MIN = 0.001; // 0.1% of screen height
static const float RING_RADIUS_MAX = 0.5;   // 50% of screen height
static const float RING_RADIUS_DEFAULT = 0.1;  // 10% of screen height

static const float RING_THICKNESS_MIN = 0.0;   // 0% of radius (invisible)
static const float RING_THICKNESS_MAX = 1.0;   // 100% of radius (filled circle)
static const float RING_THICKNESS_DEFAULT = 0.2;  // 20% of radius

// ============================================================================
// EFFECT-SPECIFIC PARAMETERS
// ============================================================================
// --- Target ---
uniform float3 TargetPosition < // XY = Screen Coord (0-1), Z = Linear Depth (0-1)
    ui_type = "drag"; ui_label = "Target Position (XY) & Depth (Z)";
    ui_tooltip = "Drag XY handles for Screen Position.\nUse Z slider for Depth (0=Near, 1=Far).";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_category = "Target";
> = float3(0.5, 0.5, TARGET_DEPTH_DEFAULT);

// --- Ring Appearance ---
uniform float RingRadius < ui_type = "slider"; ui_label = "Ring Radius"; ui_tooltip = "Radius as percentage of screen height."; ui_min = RING_RADIUS_MIN; ui_max = RING_RADIUS_MAX; ui_step = 0.001; ui_category = "Ring Appearance"; > = RING_RADIUS_DEFAULT;
uniform float RingThickness < ui_type = "slider"; ui_label = "Ring Thickness"; ui_tooltip = "Thickness as percentage of Radius (0=thin, 1=filled)."; ui_min = RING_THICKNESS_MIN; ui_max = RING_THICKNESS_MAX; ui_step = 0.01; ui_category = "Ring Appearance"; > = RING_THICKNESS_DEFAULT;
uniform float4 RingColor < ui_type = "color"; ui_label = "Ring Tint & Intensity"; ui_tooltip = "RGB: Color Tint.\nA: Intensity Multiplier."; ui_category = "Ring Appearance"; > = float4(1.0, 1.0, 1.0, 1.0);

// ============================================================================
// ANIMATION CONTROLS
// ============================================================================
uniform float RotationSpeed < ui_type = "slider"; ui_label = "Rotation Speed"; ui_tooltip = "Speed and direction of texture rotation (-10 to +10)."; ui_min = -10.0; ui_max = 10.0; ui_step = 0.1; ui_category = "Animation Controls"; > = 0.0;

// ============================================================================
// AUDIO REACTIVITY (Example Setup)
// ============================================================================
AS_AUDIO_SOURCE_UI(Ring_AudioSource, "Audio Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(Ring_AudioMultiplier, "Intensity", 1.0, 2.0, "Audio Reactivity")
uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter"; ui_tooltip = "Select parameter affected by audio"; ui_items = "None\0Radius\0Thickness\0Color Intensity\0"; ui_category = "Audio Reactivity"; > = 0;

// ============================================================================
// FINAL MIX
// ============================================================================
AS_BLENDMODE_UI(BlendMode, "Final Mix")
AS_BLENDAMOUNT_UI(BlendAmount, "Final Mix")

// ============================================================================
// DEBUG
// ============================================================================
AS_DEBUG_MODE_UI("Normal\0Screen Distance\0Angle\0Texture UVs\0Depth Check\0Ring Alpha\0")

// ============================================================================
// MAIN PIXEL SHADER
// ============================================================================
float4 PS_ScreenRing(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // --- Initial Setup ---
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    float aspectRatio = ReShade::AspectRatio;
    // Use AS_getTime() from AS_Utils.1.fxh for consistent animation timing
    float timer = AS_getTime();

    // --- Get Target Info & Apply Audio Reactivity ---
    float radiusInput = RingRadius;
    float thicknessInput = RingThickness;
    float4 ringColorInput = RingColor;

    if (AudioTarget > 0) {
        float audioLevel = AS_getAudioSource(Ring_AudioSource);
        float multiplier = Ring_AudioMultiplier;
        float audioFactor = (1.0 + audioLevel * multiplier);

        if      (AudioTarget == 1) radiusInput *= audioFactor;
        else if (AudioTarget == 2) thicknessInput = saturate(thicknessInput * audioFactor); // Clamp thickness
        else if (AudioTarget == 3) ringColorInput.a *= audioFactor; // Modify intensity (alpha channel)
        radiusInput = max(radiusInput, RING_RADIUS_MIN);
    }

    float targetDepthZ = TargetPosition.z;
    float2 targetScreenXY = TargetPosition.xy;

    // --- Calculate Screen Geometry ---
    float2 screenVec = texcoord - targetScreenXY;
    screenVec.x *= aspectRatio;
    float screenDistNorm = length(screenVec);
    float baseAngle = atan2(screenVec.y, screenVec.x); // Base angle from center

    // --- Apply Animation ---
    // Use AS_getTime directly (already in seconds)
    // Negate RotationSpeed to invert direction (positive = right/clockwise)
    float rotationOffset = timer * (-RotationSpeed) * 0.1; // Scale speed for reasonable rotation
    float angle = baseAngle + rotationOffset;

    // --- Apply Radius/Thickness ---
    float radiusNorm = radiusInput;
    float thicknessNorm = radiusNorm * saturate(thicknessInput);

    float effectiveRadiusNorm = max(0.0001, radiusNorm);
    float effectiveThicknessNorm = max(0.0001, thicknessNorm);

    // --- Check if Pixel is on the Ring ---
    float distDelta = abs(screenDistNorm - effectiveRadiusNorm);
    float halfThicknessNorm = effectiveThicknessNorm * 0.5;

    float aa = ReShade::PixelSize.y;

    float ringFactor = smoothstep(halfThicknessNorm + aa, halfThicknessNorm - aa, distDelta);

    float4 finalResult = orig;

    if (ringFactor > 0.0)
    {
        bool visible = targetDepthZ <= sceneDepth + 0.0001;

        if (visible)
        {
            // --- Texture Mapping ---
            // Map angle (-PI to PI) to texture U coord (0 to 1)
            // Use the animated angle
            float texU = frac(angle / AS_TWO_PI + 0.5);
            float texV = 1.0 - saturate(0.5 + (screenDistNorm - effectiveRadiusNorm) / (effectiveThicknessNorm + 0.0001));

            float4 texColor = tex2D(RingSampler, float2(texU, texV));
            float3 ringColor = texColor.rgb * ringColorInput.rgb * ringColorInput.a;

            float finalAlpha = ringFactor * BlendAmount;

            float3 blendedColor = AS_blendResult(orig.rgb, ringColor, BlendMode);

            finalResult = float4(lerp(orig.rgb, blendedColor, finalAlpha), orig.a);
        }
    }

    if (DebugMode > 0) {
        if (DebugMode == 1) return float4(screenDistNorm.xxx * 2.0, 1.0);
        if (DebugMode == 2) { // Angle (now includes rotation)
             // Use inverted rotation for debug
             float rotationOffset = timer * (-RotationSpeed) * 0.1;
             float angle = baseAngle + rotationOffset; // Recalculate for debug
             return float4(frac(angle/AS_TWO_PI + 0.5).xxx, 1.0);
        }
        if (DebugMode == 3) { // Texture UVs
             // Use inverted rotation for debug
             float rotationOffset = timer * (-RotationSpeed) * 0.1;
             float angle = baseAngle + rotationOffset; // Recalculate for debug
             float texU = frac(angle / AS_TWO_PI + 0.5);
             float texV = 1.0 - saturate(0.5 + (screenDistNorm - effectiveRadiusNorm) / (effectiveThicknessNorm + 0.0001));
             return float4(texU, texV, 0.0, 1.0);
        }
        if (DebugMode == 4) {
             bool visible = targetDepthZ <= sceneDepth + 0.0001;
             float debugVal = visible ? 1.0 : 0.0;
             return float4(debugVal, debugVal, debugVal, 1.0);
        }
         if (DebugMode == 5) {
             float finalAlpha = ringFactor * BlendAmount;
             return float4(finalAlpha.xxx, 1.0);
         }
    }

    return finalResult;
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_VFX_ScreenRing < ui_label = "[AS] VFX: Screen Ring"; ui_tooltip = "Draws a textured ring in screen space with depth occlusion and artistic controls."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_ScreenRing;
    }
}

#endif // __AS_VFX_ScreenRing_1_fx