/**
 * AS_VFX_PixelSort.1.fx - Glitch Art Pixel Sorting Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Simulates the pixel sorting glitch art technique — pixels above or below a
 * luminance/hue threshold are "sorted" along rows or columns, creating dramatic
 * streaking distortion. A staple of glitch art, music videos, and editorial
 * photography.
 *
 * FEATURES:
 * - Sort by luminance, hue, or saturation
 * - Horizontal, vertical, or diagonal sorting direction
 * - Adjustable threshold controls which pixels get sorted
 * - Sort length controls how far the streaks extend
 * - Audio-reactive threshold and sort length
 * - Depth-aware: only sort background or foreground
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. For each pixel, determine if it meets the sort threshold (luminance/hue/sat).
 * 2. If above threshold, sample along the sort direction to find the "sorted" color —
 *    walk along the row/column and pick the brightest/darkest value within sort length.
 * 3. Blend the sorted result with the original based on effect strength.
 * Note: True pixel sorting requires compute shaders. This simulates the visual effect
 * by directional smearing of threshold-passing pixels, producing a convincing result.
 *
 * ===================================================================================
 */

#ifndef __AS_VFX_PixelSort_1_fx
#define __AS_VFX_PixelSort_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================

static const float THRESHOLD_MIN = 0.0;
static const float THRESHOLD_MAX = 1.0;
static const float THRESHOLD_STEP = 0.01;
static const float THRESHOLD_DEFAULT = 0.5;

static const float SORT_LENGTH_MIN = 1.0;
static const float SORT_LENGTH_MAX = 200.0;
static const float SORT_LENGTH_STEP = 1.0;
static const float SORT_LENGTH_DEFAULT = 60.0;

static const float SORT_STRENGTH_MIN = 0.0;
static const float SORT_STRENGTH_MAX = 1.0;
static const float SORT_STRENGTH_STEP = 0.01;
static const float SORT_STRENGTH_DEFAULT = 0.7;

static const float THRESHOLD_RANGE_MIN = 0.0;
static const float THRESHOLD_RANGE_MAX = 0.5;
static const float THRESHOLD_RANGE_STEP = 0.01;
static const float THRESHOLD_RANGE_DEFAULT = 0.1;

static const int SORT_MODE_LUMINANCE = 0;
static const int SORT_MODE_HUE = 1;
static const int SORT_MODE_SATURATION = 2;

static const int SORT_DIR_HORIZONTAL = 0;
static const int SORT_DIR_VERTICAL = 1;
static const int SORT_DIR_DIAGONAL_DOWN = 2;
static const int SORT_DIR_DIAGONAL_UP = 3;

static const int SORT_ORDER_BRIGHT_FIRST = 0;
static const int SORT_ORDER_DARK_FIRST = 1;

// Max samples per pixel for the sort sweep
static const int MAX_SORT_SAMPLES = 64;

// ============================================================================
// SHADER DESCRIPTOR
// ============================================================================

uniform int as_shader_descriptor < ui_type = "radio"; ui_label = " "; ui_text = "\nGlitch art pixel sorting — streaks pixels along rows or columns by brightness.\nCreates dramatic, stylized distortions for music videos and editorial photography.\n\nAS StageFX | Pixel Sort by Leon Aquitaine\n"; > = 0;

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// -- Sort Parameters --
uniform int SortMode < ui_type = "combo"; ui_label = "Sort By"; ui_tooltip = "What property determines which pixels get sorted.\nLuminance: sort by brightness.\nHue: sort by color.\nSaturation: sort by color intensity."; ui_items = "Luminance\0Hue\0Saturation\0"; ui_category = "Sort Parameters"; > = SORT_MODE_LUMINANCE;
uniform int SortDirection < ui_type = "combo"; ui_label = "Direction"; ui_tooltip = "Which direction pixels streak.\nHorizontal: left/right streaks.\nVertical: up/down streaks.\nDiagonal: angled streaks."; ui_items = "Horizontal\0Vertical\0Diagonal Down\0Diagonal Up\0"; ui_category = "Sort Parameters"; > = SORT_DIR_VERTICAL;
uniform int SortOrder < ui_type = "combo"; ui_label = "Sort Order"; ui_tooltip = "Whether bright or dark pixels lead the streak.\nBright First: bright pixels streak outward.\nDark First: dark pixels streak outward."; ui_items = "Bright First\0Dark First\0"; ui_category = "Sort Parameters"; > = SORT_ORDER_BRIGHT_FIRST;

// -- Threshold --
uniform float SortThreshold < ui_type = "slider"; ui_label = "Threshold"; ui_tooltip = "Pixels above this value get sorted (streaked).\nLower = more pixels affected, higher = only bright areas."; ui_min = THRESHOLD_MIN; ui_max = THRESHOLD_MAX; ui_step = THRESHOLD_STEP; ui_category = "Sort Parameters"; > = THRESHOLD_DEFAULT;
uniform float ThresholdRange < ui_type = "slider"; ui_label = "Threshold Softness"; ui_tooltip = "Smooth transition zone around the threshold.\n0 = hard cutoff, higher = gradual onset."; ui_min = THRESHOLD_RANGE_MIN; ui_max = THRESHOLD_RANGE_MAX; ui_step = THRESHOLD_RANGE_STEP; ui_category = "Sort Parameters"; > = THRESHOLD_RANGE_DEFAULT;

// -- Sort Appearance --
uniform float SortLength < ui_type = "slider"; ui_label = "Streak Length"; ui_tooltip = "Maximum length of the sorted streaks in pixels.\nHigher = longer, more dramatic streaks."; ui_min = SORT_LENGTH_MIN; ui_max = SORT_LENGTH_MAX; ui_step = SORT_LENGTH_STEP; ui_category = "Sort Appearance"; > = SORT_LENGTH_DEFAULT;
uniform float SortStrength < ui_type = "slider"; ui_label = "Effect Strength"; ui_tooltip = "How visible the sorting effect is.\n0 = no effect, 1 = full glitch streaks."; ui_min = SORT_STRENGTH_MIN; ui_max = SORT_STRENGTH_MAX; ui_step = SORT_STRENGTH_STEP; ui_category = "Sort Appearance"; > = SORT_STRENGTH_DEFAULT;

// -- Animation --
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, AS_CAT_ANIMATION)

// -- Audio Reactivity --
AS_AUDIO_UI(PixelSort_AudioSource, "Audio Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(PixelSort_AudioMultiplier, "Audio Intensity", 1.0, 2.0, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(PixelSort_AudioTarget, "None\0Threshold\0Streak Length\0Strength\0All\0", 0)

// -- Stage --
AS_STAGEDEPTH_UI(EffectDepth)

// -- Final Mix --
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// -- Debug --
AS_DEBUG_UI("Off\0Threshold Mask\0Sort Value\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

namespace AS_PixelSort {

    // Extract the sorting metric from a color
    float getSortValue(float3 color, int mode) {
        if (mode == SORT_MODE_HUE) {
            // Simple hue extraction via atan2 on the chrominance
            float3 d = color - dot(color, AS_LUMA_REC709);
            return frac(atan2(d.g - d.b, d.r - dot(color, AS_LUMA_REC709)) / AS_TWO_PI + 0.5);
        }
        if (mode == SORT_MODE_SATURATION) {
            float maxC = max(color.r, max(color.g, color.b));
            float minC = min(color.r, min(color.g, color.b));
            return (maxC > AS_EPSILON) ? (maxC - minC) / maxC : 0.0;
        }
        // Default: luminance
        return dot(color, AS_LUMA_REC709);
    }

    // Get the sort direction vector in UV space
    float2 getSortDir(int direction) {
        if (direction == SORT_DIR_HORIZONTAL) return float2(1.0, 0.0);
        if (direction == SORT_DIR_VERTICAL) return float2(0.0, 1.0);
        if (direction == SORT_DIR_DIAGONAL_DOWN) return normalize(float2(1.0, 1.0));
        return normalize(float2(1.0, -1.0)); // DIAGONAL_UP
    }

} // namespace AS_PixelSort

// ============================================================================
// PIXEL SHADER
// ============================================================================

float4 PS_PixelSort(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);

    // Depth check
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth && DebugMode == 0) {
        return originalColor;
    }

    // Audio reactivity
    float audioMod = AS_audioModulate(1.0, PixelSort_AudioSource, PixelSort_AudioMultiplier, true, 0);
    float thresholdFinal = SortThreshold;
    float sortLengthFinal = SortLength;
    float strengthFinal = SortStrength;

    if (PixelSort_AudioTarget == 1 || PixelSort_AudioTarget == 4) thresholdFinal *= audioMod;
    if (PixelSort_AudioTarget == 2 || PixelSort_AudioTarget == 4) sortLengthFinal *= audioMod;
    if (PixelSort_AudioTarget == 3 || PixelSort_AudioTarget == 4) strengthFinal *= audioMod;

    float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);

    // Get the sort value of the current pixel
    float currentValue = AS_PixelSort::getSortValue(originalColor.rgb, SortMode);

    // Threshold mask: does this pixel participate in sorting?
    float sortMask = smoothstep(thresholdFinal - ThresholdRange, thresholdFinal + ThresholdRange, currentValue);

    // Debug views
    if (DebugMode == 1) return float4(sortMask.xxx, 1.0);
    if (DebugMode == 2) return float4(currentValue.xxx, 1.0);

    // If below threshold, this pixel is not sorted
    if (sortMask < 0.01) {
        return originalColor;
    }

    // Sort direction in pixel space
    float2 sortDir = AS_PixelSort::getSortDir(SortDirection) * ReShade::PixelSize;

    // Add subtle time-based variation to sort length (animated glitchiness)
    float lengthMod = 1.0 + sin(time * 2.0 + texcoord.y * 30.0) * 0.2;
    int maxSteps = min(MAX_SORT_SAMPLES, max(1, (int)(sortLengthFinal * lengthMod)));

    // Walk along the sort direction, tracking the extremal (brightest or darkest) color
    float3 sortedColor = originalColor.rgb;
    float extremalValue = currentValue;

    for (int i = 1; i <= maxSteps; i++)
    {
        float2 sampleUV = texcoord - sortDir * (float)i;

        // Stop at screen edges
        if (sampleUV.x < 0.0 || sampleUV.x > 1.0 || sampleUV.y < 0.0 || sampleUV.y > 1.0)
            break;

        float3 sampleColor = tex2Dlod(ReShade::BackBuffer, float4(sampleUV, 0, 0)).rgb;
        float sampleValue = AS_PixelSort::getSortValue(sampleColor, SortMode);

        // Check if this sample is above threshold (part of the sorted run)
        float sampleMask = smoothstep(thresholdFinal - ThresholdRange, thresholdFinal + ThresholdRange, sampleValue);
        if (sampleMask < 0.01) break; // Hit the edge of the sorted region

        // Track the extremal value based on sort order
        bool isMoreExtremal = (SortOrder == SORT_ORDER_BRIGHT_FIRST)
            ? (sampleValue > extremalValue)
            : (sampleValue < extremalValue);

        if (isMoreExtremal) {
            extremalValue = sampleValue;
            sortedColor = sampleColor;
        }
    }

    // Blend between original and sorted based on strength and threshold mask
    float3 result = lerp(originalColor.rgb, sortedColor, strengthFinal * sortMask);

    // User's BlendMode/BlendAmount for final mix
    float3 finalResult = AS_composite(result, originalColor.rgb, BlendMode, BlendAmount);

    return float4(finalResult, originalColor.a);
}

// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_VFX_PixelSort
<
    ui_label = "[AS] VFX: Pixel Sort";
    ui_tooltip = "Glitch art pixel sorting — streaks pixels by brightness along rows/columns.\n"
                 "Creates dramatic distortions for music videos and editorial photography.\n"
                 "Performance: Moderate (per-pixel directional sweep)";
>
{
    pass Main
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_PixelSort;
    }
}

#endif // __AS_VFX_PixelSort_1_fx
