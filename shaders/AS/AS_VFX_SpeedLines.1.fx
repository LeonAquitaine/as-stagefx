/**
 * AS_VFX_SpeedLines.1.fx - Radial zoom blur for motion/speed/impact effects
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Radial zoom blur emanating from a configurable center point, simulating
 * motion, speed, or impact. The center area stays sharp while edges blur
 * outward, creating a dramatic focus effect.
 *
 * FEATURES:
 * - Configurable center point with drag control
 * - Adjustable inner radius for a sharp safe zone
 * - Distance-based falloff for natural blur graduation
 * - Tunable sample count for quality vs performance tradeoff
 * - Audio-reactive blur strength for beat-synced zoom effects
 * - Depth-aware masking via stage depth control
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Computes direction vector from each pixel to the center point
 * 2. Samples along the radial direction with configurable tap count
 * 3. Accumulates samples with distance-based weight falloff
 * 4. Mixes blurred result with original based on distance from center
 * 5. Composites with AS_composite for final blend mode control
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_SpeedLines_1_fx
#define __AS_VFX_SpeedLines_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// NAMESPACE
// ============================================================================
namespace AS_SpeedLines {

// ============================================================================
// CONSTANTS
// ============================================================================

// --- Blur Strength ---
static const float BLUR_STRENGTH_MIN = 0.0;
static const float BLUR_STRENGTH_MAX = 1.0;
static const float BLUR_STRENGTH_DEFAULT = 0.3;

// --- Inner Radius ---
static const float INNER_RADIUS_MIN = 0.0;
static const float INNER_RADIUS_MAX = 0.5;
static const float INNER_RADIUS_DEFAULT = 0.1;

// --- Sample Count ---
static const int SAMPLE_COUNT_MIN = 8;
static const int SAMPLE_COUNT_MAX = 32;
static const int SAMPLE_COUNT_DEFAULT = 16;

// --- Falloff ---
static const float FALLOFF_MIN = 0.5;
static const float FALLOFF_MAX = 3.0;
static const float FALLOFF_DEFAULT = 1.0;

// --- Max blur offset scale ---
static const float MAX_BLUR_OFFSET = 0.15;

// --- Debug Mode ---
static const int DEBUG_OFF = 0;
static const int DEBUG_BLUR_MASK = 1;
static const int DEBUG_DIRECTION_MAP = 2;

// ============================================================================
// UNIFORMS
// ============================================================================

// --- Effect Controls ---

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform float BlurStrength < ui_type = "slider"; ui_label = "Blur Strength"; ui_tooltip = "Controls the intensity of the radial zoom blur."; ui_min = BLUR_STRENGTH_MIN; ui_max = BLUR_STRENGTH_MAX; ui_step = 0.01; ui_category = "Speed Lines"; > = BLUR_STRENGTH_DEFAULT;
uniform float2 CenterPosition < ui_type = "drag"; ui_label = "Center Position"; ui_tooltip = "Screen position where the zoom emanates from. (0,0) = top-left, (1,1) = bottom-right."; ui_min = 0.0; ui_max = 1.0; ui_speed = 0.01; ui_category = "Speed Lines"; > = float2(0.5, 0.5);
uniform float InnerRadius < ui_type = "slider"; ui_label = "Inner Radius"; ui_tooltip = "Sharp zone around center with no blur applied."; ui_min = INNER_RADIUS_MIN; ui_max = INNER_RADIUS_MAX; ui_step = 0.01; ui_category = "Speed Lines"; > = INNER_RADIUS_DEFAULT;
uniform int SampleCount < ui_type = "slider"; ui_label = "Sample Count"; ui_tooltip = "Number of radial samples. Higher values produce smoother blur at a performance cost."; ui_min = SAMPLE_COUNT_MIN; ui_max = SAMPLE_COUNT_MAX; ui_step = 1; ui_category = "Speed Lines"; > = SAMPLE_COUNT_DEFAULT;
uniform float Falloff < ui_type = "slider"; ui_label = "Falloff"; ui_tooltip = "Controls how quickly the blur increases from center to edge."; ui_min = FALLOFF_MIN; ui_max = FALLOFF_MAX; ui_step = 0.05; ui_category = "Speed Lines"; > = FALLOFF_DEFAULT;

// --- Animation ---
AS_ANIMATION_UI(AnimSpeed, AnimKeyframe, AS_CAT_ANIMATION)

// --- Audio Reactivity ---
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(AudioMultBlur, "Blur Intensity", 1.0, 3.0, AS_CAT_AUDIO)

// --- Stage ---
AS_STAGEDEPTH_UI(EffectDepth)

// --- Final Mix ---
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug ---
AS_DEBUG_UI("Off\0Blur Mask\0Direction Map\0")

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 SpeedLinesPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {
    // Depth-aware early return
    AS_DEPTH_EARLY_RETURN(texcoord, EffectDepth)

    float3 originalColor = tex2D(ReShade::BackBuffer, texcoord).rgb;

    // Compute aspect-corrected distance from center
    float2 delta = texcoord - CenterPosition;
    float2 deltaAspect = float2(delta.x * ReShade::AspectRatio, delta.y);
    float dist = length(deltaAspect);

    // Compute blur mask: zero inside inner radius, increasing outward
    float blurMask = saturate((dist - InnerRadius) / max(0.5 - InnerRadius, AS_EPSILON));
    blurMask = pow(blurMask, Falloff);

    // Audio-modulated blur strength with animation pulse
    float animTime = AS_getAnimationTime(AnimSpeed, AnimKeyframe);
    float animPulse = 0.5 + 0.5 * sin(animTime * AS_TWO_PI * 0.5);
    float currentBlur = AS_audioModulate(BlurStrength, AudioSource, AudioMultBlur, true, 0);
    float effectiveBlur = currentBlur * blurMask;

    // Add subtle animation pulse when animation speed > 0
    if (abs(AnimSpeed) > AS_EPSILON) {
        effectiveBlur *= lerp(0.7, 1.0, animPulse);
    }

    // Debug views
    if (DebugMode == DEBUG_BLUR_MASK) {
        return float4(blurMask.xxx, 1.0);
    }
    if (DebugMode == DEBUG_DIRECTION_MAP) {
        float2 dir = (dist > AS_EPSILON) ? normalize(delta) : float2(0.0, 0.0);
        return float4(dir * 0.5 + 0.5, 0.0, 1.0);
    }

    // Radial blur sampling
    float2 blurDir = delta * (effectiveBlur * MAX_BLUR_OFFSET / max(dist, AS_EPSILON));
    float3 accumulated = float3(0.0, 0.0, 0.0);
    float totalWeight = 0.0;

    for (int i = 0; i < SAMPLE_COUNT_MAX; i++) {
        if (i >= SampleCount) break;
        float t = (float(i) / float(SampleCount - 1)) - 0.5;
        float weight = 1.0 - abs(t) * 0.5;
        float2 sampleUV = texcoord + blurDir * t;
        accumulated += tex2Dlod(ReShade::BackBuffer, float4(sampleUV, 0, 0)).rgb * weight;
        totalWeight += weight;
    }

    float3 blurredColor = accumulated / max(totalWeight, AS_EPSILON);

    // Blend blurred with original based on blur mask
    float3 effectColor = lerp(originalColor, blurredColor, effectiveBlur);

    // Final composite
    float3 result = AS_composite(effectColor, originalColor, BlendMode, BlendAmount);
    return float4(result, 1.0);
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_VFX_SpeedLines < ui_label = "[AS] VFX: Speed Lines"; ui_tooltip = "Radial zoom blur from a configurable center point for motion and impact effects."; >
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = AS_SpeedLines::SpeedLinesPS;
    }
}

} // namespace AS_SpeedLines

#endif // __AS_VFX_SpeedLines_1_fx
