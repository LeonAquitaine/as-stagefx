/**
 * AS_GFX_FadedBlacks.1.fx - Vintage Faded Blacks / Lifted Shadows
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Lifts pure black shadows to a milky gray, brown, or blue tone — the signature
 * look of Instagram vintage filters and analog film prints with raised black point.
 *
 * FEATURES:
 * - Smoothstep-based shadow lifting with adjustable fade range
 * - Custom fade color or palette-driven gradient for shadow tones
 * - Highlight preservation to keep bright areas unaffected
 * - Post-fade saturation control for authentic vintage desaturation
 * - Audio-reactive effect strength
 * - Depth-aware via stage depth control
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Sample scene color and compute luminance
 * 2. Compute fade amount via smoothstep over the luminance range
 * 3. Lerp from fade color toward original based on fade amount
 * 4. Apply optional saturation adjustment for vintage feel
 * 5. Blend with original via effect strength and AS_composite
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_GFX_FadedBlacks_1_fx
#define __AS_GFX_FadedBlacks_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

// ============================================================================
// NAMESPACE
// ============================================================================
namespace AS_FadedBlacks {

// ============================================================================
// CONSTANTS
// ============================================================================

// --- Effect Strength ---
static const float STRENGTH_MIN = 0.0;
static const float STRENGTH_MAX = 1.0;
static const float STRENGTH_DEFAULT = 0.5;

// --- Fade Range ---
static const float FADE_RANGE_MIN = 0.05;
static const float FADE_RANGE_MAX = 0.5;
static const float FADE_RANGE_DEFAULT = 0.15;

// --- Saturation ---
static const float SATURATION_MIN = 0.5;
static const float SATURATION_MAX = 1.5;
static const float SATURATION_DEFAULT = 0.9;

// --- Highlight Preservation ---
static const float HIGHLIGHT_PRES_MIN = 0.0;
static const float HIGHLIGHT_PRES_MAX = 1.0;
static const float HIGHLIGHT_PRES_DEFAULT = 0.8;

// --- Color Mode ---
static const int COLOR_MODE_CUSTOM = 0;
static const int COLOR_MODE_PALETTE = 1;

// --- Debug Mode ---
static const int DEBUG_OFF = 0;
static const int DEBUG_FADE_MASK = 1;
static const int DEBUG_FADE_COLOR = 2;

// ============================================================================
// UNIFORMS
// ============================================================================

// --- Effect Controls ---

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform float EffectStrength < ui_type = "slider"; ui_label = "Effect Strength"; ui_tooltip = "How much of the faded look is applied vs the original scene."; ui_min = STRENGTH_MIN; ui_max = STRENGTH_MAX; ui_step = 0.01; ui_category = "Faded Blacks"; > = STRENGTH_DEFAULT;
uniform float FadeRange < ui_type = "slider"; ui_label = "Fade Range"; ui_tooltip = "How far up the luminance range the fade reaches.\nLow = only deepest shadows. High = reaches into midtones."; ui_min = FADE_RANGE_MIN; ui_max = FADE_RANGE_MAX; ui_step = 0.01; ui_category = "Faded Blacks"; > = FADE_RANGE_DEFAULT;
uniform float3 FadeColor < ui_type = "color"; ui_label = "Fade Color"; ui_tooltip = "The color that shadows are lifted toward.\nWarm gray gives a vintage film feel."; ui_category = "Faded Blacks"; > = float3(0.25, 0.22, 0.20);
uniform float Saturation < ui_type = "slider"; ui_label = "Saturation"; ui_tooltip = "Overall saturation after fading.\nVintage looks tend to be slightly desaturated."; ui_min = SATURATION_MIN; ui_max = SATURATION_MAX; ui_step = 0.01; ui_category = "Faded Blacks"; > = SATURATION_DEFAULT;
uniform float HighlightPreservation < ui_type = "slider"; ui_label = "Highlight Preservation"; ui_tooltip = "How much highlights remain unaffected by the fade.\nHigher values keep bright areas crisp."; ui_min = HIGHLIGHT_PRES_MIN; ui_max = HIGHLIGHT_PRES_MAX; ui_step = 0.01; ui_category = "Faded Blacks"; > = HIGHLIGHT_PRES_DEFAULT;
uniform int ColorMode < ui_type = "combo"; ui_label = "Color Mode"; ui_items = "Custom Color\0Palette\0"; ui_tooltip = "Custom Color: use the Fade Color picker.\nPalette: maps the fade gradient from the selected palette."; ui_category = "Faded Blacks"; > = COLOR_MODE_CUSTOM;

// --- Palette ---
AS_PALETTE_SELECTION_UI(PalettePreset, "Fade Palette", AS_PALETTE_SUNSET, AS_CAT_PALETTE)
AS_DECLARE_CUSTOM_PALETTE(FadedBlk_, AS_CAT_PALETTE)

// --- Audio Reactivity ---
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(AudioMultStrength, "Strength Intensity", 1.0, 2.0, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(AudioTarget, "None\0Effect Strength\0", 0)

// --- Stage ---
AS_STAGEDEPTH_UI(EffectDepth)

// --- Final Mix ---
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug ---
AS_DEBUG_UI("Off\0Fade Mask\0Fade Color\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

float3 GetFadeColor(float t) {
    if (ColorMode == COLOR_MODE_PALETTE) {
        if (PalettePreset == AS_PALETTE_CUSTOM) {
            return AS_GET_INTERPOLATED_CUSTOM_COLOR(FadedBlk_, t);
        }
        return AS_getInterpolatedColor(PalettePreset, t);
    }
    return FadeColor;
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 FadedBlacksPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {
    // Depth-aware early return
    AS_DEPTH_EARLY_RETURN(texcoord, EffectDepth)

    float3 originalColor = tex2D(ReShade::BackBuffer, texcoord).rgb;

    // Compute luminance
    float luma = dot(originalColor, AS_LUMA_REC709);

    // Compute fade amount: 0 at black, 1 at FadeRange and above
    float fadeAmount = smoothstep(0.0, FadeRange, luma);

    // Get the target fade color
    // For palette mode, use luminance as palette position for gradient mapping
    float3 fadeCol = GetFadeColor(saturate(luma / max(FadeRange, AS_EPSILON)));

    // Lerp from fade color toward original based on fadeAmount
    // Shadows (fadeAmount near 0) become FadeColor, mids/highlights stay original
    float3 fadedColor = lerp(fadeCol, originalColor, fadeAmount);

    // Apply highlight preservation — blend back toward original for bright pixels
    float highlightMask = smoothstep(FadeRange, FadeRange + 0.3, luma);
    fadedColor = lerp(fadedColor, originalColor, highlightMask * HighlightPreservation);

    // Apply saturation adjustment
    fadedColor = AS_adjustSaturation(fadedColor, Saturation);

    // Audio-modulated effect strength
    float strength = EffectStrength;
    if (AudioTarget == 1) {
        strength = AS_audioModulate(strength, AudioSource, AudioMultStrength, true, 0);
    }
    strength = saturate(strength);

    // Blend faded result with original
    float3 effectColor = lerp(originalColor, fadedColor, strength);

    // Debug views
    if (DebugMode == DEBUG_FADE_MASK) {
        return float4(fadeAmount.xxx, 1.0);
    }
    if (DebugMode == DEBUG_FADE_COLOR) {
        return float4(fadedColor, 1.0);
    }

    // Final composite
    float3 result = AS_composite(effectColor, originalColor, BlendMode, BlendAmount);
    return float4(result, 1.0);
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_GFX_FadedBlacks < ui_label = "[AS] GFX: Faded Blacks"; ui_tooltip = "Lifts black shadows to milky vintage tones for a faded film look."; >
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = AS_FadedBlacks::FadedBlacksPS;
    }
}

} // namespace AS_FadedBlacks

#endif // __AS_GFX_FadedBlacks_1_fx
