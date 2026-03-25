/**
 * AS_GFX_GradientMap.1.fx - Luminance-based color gradient mapping
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Maps scene luminance to an arbitrary color gradient using the AS palette system.
 * Dark pixels map to palette color 0, bright pixels to palette color 4, with smooth
 * interpolation between all five palette colors for cinematic color grading.
 *
 * FEATURES:
 * - Luminance-to-palette gradient mapping with smooth interpolation
 * - Adjustable contrast and brightness offset for luminance remapping
 * - Preserve Luminance mode to keep original brightness structure
 * - Tint Only mode blends palette hue with original saturation
 * - Full palette system integration with custom palette support
 * - Audio-reactive strength and contrast
 * - Depth-aware grading via stage depth control
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Samples scene color and computes luminance using Rec.709 weights
 * 2. Applies contrast and brightness offset to remap the luminance range
 * 3. Uses remapped luminance as interpolation parameter across the palette
 * 4. Blends gradient-mapped color with original via user-controlled strength
 * 5. Composites with AS_composite for final blend mode control
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_GFX_GradientMap_1_fx
#define __AS_GFX_GradientMap_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

// ============================================================================
// NAMESPACE
// ============================================================================
namespace AS_GradientMap {

// ============================================================================
// CONSTANTS
// ============================================================================

// --- Effect Strength ---
static const float STRENGTH_MIN = 0.0;
static const float STRENGTH_MAX = 1.0;
static const float STRENGTH_DEFAULT = 0.5;

// --- Contrast ---
static const float CONTRAST_MIN = 0.5;
static const float CONTRAST_MAX = 2.0;
static const float CONTRAST_DEFAULT = 1.0;

// --- Brightness Offset ---
static const float BRIGHTNESS_MIN = -0.5;
static const float BRIGHTNESS_MAX = 0.5;
static const float BRIGHTNESS_DEFAULT = 0.0;

// --- Color Mode ---
static const int COLOR_MODE_FULL_REPLACE = 0;
static const int COLOR_MODE_TINT_ONLY = 1;

// --- Debug Mode ---
static const int DEBUG_OFF = 0;
static const int DEBUG_LUMINANCE_MAP = 1;
static const int DEBUG_GRADIENT_RESULT = 2;

// ============================================================================
// UNIFORMS
// ============================================================================

uniform int as_shader_descriptor <ui_type = "radio"; ui_label = " "; ui_text = "\nMaps scene luminance to a color gradient using the palette system.\nCinematic color grading with full palette control.\n\nAS StageFX | Gradient Map by Leon Aquitaine\n"; > = 0;

// --- Effect Controls ---
uniform float EffectStrength < ui_type = "slider"; ui_label = "Effect Strength"; ui_tooltip = "Blend between original scene and gradient-mapped result."; ui_min = STRENGTH_MIN; ui_max = STRENGTH_MAX; ui_step = 0.01; ui_category = "Gradient Map"; > = STRENGTH_DEFAULT;
uniform float Contrast < ui_type = "slider"; ui_label = "Contrast"; ui_tooltip = "Expand or compress the luminance range before mapping to the gradient."; ui_min = CONTRAST_MIN; ui_max = CONTRAST_MAX; ui_step = 0.01; ui_category = "Gradient Map"; > = CONTRAST_DEFAULT;
uniform float BrightnessOffset < ui_type = "slider"; ui_label = "Brightness Offset"; ui_tooltip = "Shift the luminance center point before mapping."; ui_min = BRIGHTNESS_MIN; ui_max = BRIGHTNESS_MAX; ui_step = 0.01; ui_category = "Gradient Map"; > = BRIGHTNESS_DEFAULT;
uniform bool InvertGradient < ui_type = "checkbox"; ui_label = "Invert Gradient"; ui_tooltip = "Flip the gradient direction so dark pixels map to bright palette colors and vice versa."; ui_category = "Gradient Map"; > = false;
uniform bool PreserveLuminance < ui_type = "checkbox"; ui_label = "Preserve Luminance"; ui_tooltip = "Apply palette color but keep the original brightness structure."; ui_category = "Gradient Map"; > = true;
uniform int ColorMode < ui_type = "combo"; ui_label = "Color Mode"; ui_items = "Full Replace\0Tint Only\0"; ui_tooltip = "Full Replace: completely replaces color with palette gradient.\nTint Only: blends palette hue with original saturation for a subtler look."; ui_category = "Gradient Map"; > = COLOR_MODE_FULL_REPLACE;

// --- Palette ---
AS_PALETTE_SELECTION_UI(PalettePreset, "Color Palette", AS_PALETTE_SUNSET, AS_CAT_PALETTE)
AS_DECLARE_CUSTOM_PALETTE(GradMap, AS_CAT_PALETTE)

// --- Audio Reactivity ---
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(AudioMultStrength, "Strength Intensity", 1.0, 2.0, AS_CAT_AUDIO)
AS_AUDIO_UI(AudioSourceContrast, "Contrast Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(AudioMultContrast, "Contrast Intensity", 0.5, 2.0, AS_CAT_AUDIO)

// --- Stage ---
AS_STAGEDEPTH_UI(EffectDepth)

// --- Final Mix ---
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug ---
AS_DEBUG_UI("Off\0Luminance Map\0Gradient Result\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

float3 GetPaletteColorInterpolated(float t) {
    if (PalettePreset == AS_PALETTE_CUSTOM) {
        return AS_GET_INTERPOLATED_CUSTOM_COLOR(GradMap, t);
    }
    return AS_getInterpolatedColor(PalettePreset, t);
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 GradientMapPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {
    // Depth-aware early return
    AS_DEPTH_EARLY_RETURN(texcoord, EffectDepth)

    float3 originalColor = tex2D(ReShade::BackBuffer, texcoord).rgb;

    // Compute luminance
    float luma = dot(originalColor, AS_LUMA_REC709);

    // Apply audio-modulated contrast and brightness
    float currentContrast = AS_audioModulate(Contrast, AudioSourceContrast, AudioMultContrast, true, 0);
    float adjustedLuma = saturate((luma - 0.5) * currentContrast + 0.5 + BrightnessOffset);

    // Invert if requested
    float gradientT = InvertGradient ? (1.0 - adjustedLuma) : adjustedLuma;

    // Get gradient color from palette
    float3 gradientColor = GetPaletteColorInterpolated(gradientT);

    // Apply color mode
    if (ColorMode == COLOR_MODE_TINT_ONLY) {
        // Blend palette hue with original saturation
        float originalLuma = dot(originalColor, AS_LUMA_REC709);
        float gradLuma = dot(gradientColor, AS_LUMA_REC709);
        float3 tinted = gradientColor * (originalLuma / max(gradLuma, AS_EPSILON));
        gradientColor = tinted;
    }

    // Preserve luminance: apply palette color but keep original brightness
    if (PreserveLuminance) {
        float gradLuma = dot(gradientColor, AS_LUMA_REC709);
        if (gradLuma > AS_EPSILON) {
            gradientColor = gradientColor * (luma / gradLuma);
        }
    }

    // Blend with original based on audio-modulated strength
    float currentStrength = AS_audioModulate(EffectStrength, AudioSource, AudioMultStrength, true, 0);
    currentStrength = saturate(currentStrength);
    float3 effectColor = lerp(originalColor, gradientColor, currentStrength);

    // Debug views
    if (DebugMode == DEBUG_LUMINANCE_MAP) {
        return float4(adjustedLuma.xxx, 1.0);
    }
    if (DebugMode == DEBUG_GRADIENT_RESULT) {
        return float4(gradientColor, 1.0);
    }

    // Final composite
    float3 result = AS_composite(effectColor, originalColor, BlendMode, BlendAmount);
    return float4(result, 1.0);
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_GFX_GradientMap < ui_label = "[AS] GFX: Gradient Map"; ui_tooltip = "Maps scene luminance to a color gradient using the palette system for cinematic color grading."; >
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = AS_GradientMap::GradientMapPS;
    }
}

} // namespace AS_GradientMap

#endif // __AS_GFX_GradientMap_1_fx
