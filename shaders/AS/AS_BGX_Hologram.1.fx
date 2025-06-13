/**
 * AS_BGX_Hologram.1.fx - Holographic Plasma Background
 * Author: Leon Aquitaine (Adapted from hypothete)
 * License: Creative Commons Attribution 4.0 International
 * Original Source: "Hologram stars" by hypothete on Shadertoy
 * Source URL: https://www.shadertoy.com/view/NlycDG
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a dynamic, holographic plasma background with shifting rainbow colors
 * and a plasma distortion effect that responds to a user-controlled viewpoint.
 *
 * FEATURES:
 * - Dynamic plasma field with configurable scale and distortion.
 * - Shifting spectral rainbow colors.
 * - User-controlled viewpoint for interactive effects.
 * - Full AS-StageFX integration for positioning, depth masking, and blending.
 *
 * PERFORMANCE OPTIMIZATIONS:
 * - Simplified plasma calculations
 * - No complex star rendering
 * - Efficient spectral color generation
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD
// ============================================================================
#ifndef __AS_BGX_Hologram_1_fx
#define __AS_BGX_Hologram_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Plasma & View ---
AS_POSITION_SCALE_UI(ViewPosition, ViewPosition_Scale) 
static const float HOLO_PLASMA_SCALE_MIN = 0.01;
static const float HOLO_PLASMA_SCALE_MAX = 2.0;
static const float HOLO_PLASMA_SCALE_DEFAULT = 0.3;
uniform float PlasmaScale < ui_type = "slider"; ui_label = "Plasma Scale"; ui_tooltip = "Controls the frequency/tiling of the plasma distortion."; ui_min = HOLO_PLASMA_SCALE_MIN; ui_max = HOLO_PLASMA_SCALE_MAX; ui_category = "Plasma"; > = HOLO_PLASMA_SCALE_DEFAULT;
static const float HOLO_MIN_BRIGHTNESS_MIN = 0.0;
static const float HOLO_MIN_BRIGHTNESS_MAX = 1.0;
static const float HOLO_MIN_BRIGHTNESS_DEFAULT = 0.6;
uniform float MinBrightness < ui_type = "slider"; ui_label = "Minimum Brightness"; ui_tooltip = "Sets a brightness floor to prevent the effect from becoming too dark."; ui_min = HOLO_MIN_BRIGHTNESS_MIN; ui_max = HOLO_MIN_BRIGHTNESS_MAX; ui_category = "Plasma"; > = HOLO_MIN_BRIGHTNESS_DEFAULT;

// --- Animation ---
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")

// --- Stage ---
AS_POSITION_SCALE_UI(EffectPosition, EffectScale)
AS_ROTATION_UI(SnapRotation, FineRotation)
AS_STAGEDEPTH_UI(EffectDepth)

// --- Final Mix ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================
float3 bump3(float3 x) {
    float3 y = 1.0 - x * x;
    return max(y, 0.0);
}

float3 spectral_gems(float w) {
    return bump3(
        float3(
            3.0 * (w - 0.7), // Red
            3.0 * (w - 0.5), // Green
            3.0 * (w - 0.3)  // Blue
        )
    );
}

float get_plasma(in float2 uv, in float offset) {
    return sin(0.015 * (AS_PI * uv.x * uv.y) + offset / 2.0)
         + cos(AS_PI * PlasmaScale * uv.x + offset)
         * sin(AS_PI * PlasmaScale * uv.y + offset / 3.0);
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_BGX_Hologram(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    if(sceneDepth < EffectDepth - AS_DEPTH_EPSILON)
    {
        return originalColor;
    }

    // 1. Set up coordinates
    float rotation = AS_getRotationRadians(SnapRotation, FineRotation);
    float2 uv = AS_transformCoord(texcoord, EffectPosition, EffectScale, rotation);
    float2 centered_uv = (uv - 0.5) * 2.0;
    centered_uv.x *= ReShade::AspectRatio;    // 2. Get animated time
    float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);
    
    // 3. Generate plasma effect
    float2 dUv = centered_uv - ViewPosition;
    float plas = get_plasma(centered_uv, dUv.x * dUv.y);
    float3 rainbow = spectral_gems(frac(plas + time / 30.0));
    float3 finalColor = max(rainbow, MinBrightness);

    // 4. Blend with scene
    return AS_applyBlend(float4(finalColor, 1.0), originalColor, BlendMode, BlendAmount);
}


// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_Hologram <
    ui_label = "[AS] BGX: Hologram";
    ui_tooltip = "Creates a dynamic, holographic plasma background with shifting rainbow colors.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_BGX_Hologram;
    }
}

#endif // __AS_BGX_Hologram_1_fx