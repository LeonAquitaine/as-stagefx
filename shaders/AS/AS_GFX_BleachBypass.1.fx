/**
 * AS_GFX_BleachBypass.1.fx - Bleach Bypass Film Processing Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Simulates the bleach bypass (silver retention) film processing technique —
 * desaturated colors with high contrast and a metallic sheen. The signature look
 * of Saving Private Ryan, Minority Report, and gritty war/noir cinematography.
 *
 * FEATURES:
 * - Adjustable desaturation with retained color undertones
 * - High-contrast boost for the characteristic harsh, punchy look
 * - Black crush for gritty shadow detail
 * - Silver tone cool metallic cast in highlights
 * - Subtle film grain via procedural hash noise
 * - Audio-reactive effect strength or contrast
 * - Depth-aware via stage depth control
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Sample scene color and compute luminance
 * 2. Create desaturated version with partial color retention
 * 3. Apply contrast boost centered at mid-gray
 * 4. Blend contrasted result with original for metallic quality
 * 5. Apply optional silver tone, black crush, and film grain
 * 6. Composite with AS_composite for final blend
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_GFX_BleachBypass_1_fx
#define __AS_GFX_BleachBypass_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Noise.1.fxh"

// ============================================================================
// NAMESPACE
// ============================================================================
namespace AS_BleachBypass {

// ============================================================================
// CONSTANTS
// ============================================================================

// --- Effect Strength ---
static const float STRENGTH_MIN = 0.0;
static const float STRENGTH_MAX = 1.0;
static const float STRENGTH_DEFAULT = 0.6;

// --- Desaturation ---
static const float DESAT_MIN = 0.0;
static const float DESAT_MAX = 1.0;
static const float DESAT_DEFAULT = 0.7;

// --- Contrast Boost ---
static const float CONTRAST_MIN = 1.0;
static const float CONTRAST_MAX = 2.0;
static const float CONTRAST_DEFAULT = 1.4;

// --- Black Crush ---
static const float CRUSH_MIN = 0.0;
static const float CRUSH_MAX = 0.1;
static const float CRUSH_DEFAULT = 0.03;

// --- Silver Tone ---
static const float SILVER_MIN = 0.0;
static const float SILVER_MAX = 0.5;
static const float SILVER_DEFAULT = 0.1;

// --- Grain ---
static const float GRAIN_MIN = 0.0;
static const float GRAIN_MAX = 0.3;
static const float GRAIN_DEFAULT = 0.05;

// --- Debug Mode ---
static const int DEBUG_OFF = 0;
static const int DEBUG_DESATURATED = 1;
static const int DEBUG_CONTRAST = 2;

// ============================================================================
// UNIFORMS
// ============================================================================

uniform int as_shader_descriptor <ui_type = "radio"; ui_label = " "; ui_text = "\nDesaturated high-contrast look with metallic sheen — the bleach bypass film process.\nGritty, punchy cinematography for war, noir, and dramatic scenes.\n\nAS StageFX | Bleach Bypass by Leon Aquitaine\n"; > = 0;

// --- Effect Controls ---
uniform float EffectStrength < ui_type = "slider"; ui_label = "Effect Strength"; ui_tooltip = "Overall blend between original scene and bleach bypass result."; ui_min = STRENGTH_MIN; ui_max = STRENGTH_MAX; ui_step = 0.01; ui_category = "Bleach Bypass"; > = STRENGTH_DEFAULT;
uniform float DesatAmount < ui_type = "slider"; ui_label = "Desaturation"; ui_tooltip = "How much color is removed.\n0.7 = most color gone with some undertones remaining."; ui_min = DESAT_MIN; ui_max = DESAT_MAX; ui_step = 0.01; ui_category = "Bleach Bypass"; > = DESAT_DEFAULT;
uniform float ContrastBoost < ui_type = "slider"; ui_label = "Contrast Boost"; ui_tooltip = "How much contrast is added to the desaturated image.\nHigher values create harsher, punchier contrast."; ui_min = CONTRAST_MIN; ui_max = CONTRAST_MAX; ui_step = 0.01; ui_category = "Bleach Bypass"; > = CONTRAST_DEFAULT;
uniform float BlackCrush < ui_type = "slider"; ui_label = "Black Crush"; ui_tooltip = "Darken shadows further for a gritty, crushed-blacks look.\nSubtle values work best."; ui_min = CRUSH_MIN; ui_max = CRUSH_MAX; ui_step = 0.005; ui_category = "Bleach Bypass"; > = CRUSH_DEFAULT;
uniform float SilverTone < ui_type = "slider"; ui_label = "Silver Tone"; ui_tooltip = "Cool metallic cast applied to highlights.\nSimulates the silver retention in bleach bypass prints."; ui_min = SILVER_MIN; ui_max = SILVER_MAX; ui_step = 0.01; ui_category = "Bleach Bypass"; > = SILVER_DEFAULT;
uniform float GrainAmount < ui_type = "slider"; ui_label = "Grain Amount"; ui_tooltip = "Subtle film grain texture for authenticity.\n0.0 = no grain, higher = more visible noise."; ui_min = GRAIN_MIN; ui_max = GRAIN_MAX; ui_step = 0.01; ui_category = "Bleach Bypass"; > = GRAIN_DEFAULT;

// --- Audio Reactivity ---
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(AudioMultiplier, "Audio Intensity", 1.0, 2.0, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(AudioTarget, "None\0Effect Strength\0Contrast\0", 0)

// --- Stage ---
AS_STAGEDEPTH_UI(EffectDepth)

// --- Final Mix ---
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug ---
AS_DEBUG_UI("Off\0Desaturated\0Contrasted\0")

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 BleachBypassPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {
    // Depth-aware early return
    AS_DEPTH_EARLY_RETURN(texcoord, EffectDepth)

    float3 originalColor = tex2D(ReShade::BackBuffer, texcoord).rgb;

    // Audio modulation
    float strengthFinal = EffectStrength;
    float contrastFinal = ContrastBoost;
    if (AudioTarget == 1) {
        strengthFinal = AS_audioModulate(strengthFinal, AudioSource, AudioMultiplier, true, 0);
    }
    if (AudioTarget == 2) {
        contrastFinal = AS_audioModulate(contrastFinal, AudioSource, AudioMultiplier, true, 0);
    }
    strengthFinal = saturate(strengthFinal);

    // Compute luminance
    float luma = dot(originalColor, AS_LUMA_REC709);

    // Create desaturated version with partial color retention
    float3 desat = lerp(float3(luma, luma, luma), originalColor, 1.0 - DesatAmount);

    // Debug: desaturated view
    if (DebugMode == DEBUG_DESATURATED) {
        return float4(desat, 1.0);
    }

    // Boost contrast centered at mid-gray
    float3 contrasted = saturate(0.5 + (desat - 0.5) * contrastFinal);

    // Debug: contrasted view
    if (DebugMode == DEBUG_CONTRAST) {
        return float4(contrasted, 1.0);
    }

    // Blend contrasted with original for metallic quality
    float3 bleached = lerp(originalColor, contrasted, strengthFinal);

    // Apply black crush — push shadows darker
    bleached = max(bleached - BlackCrush, 0.0);

    // Apply silver tone — cool metallic cast in highlights
    float highlightMask = smoothstep(0.5, 1.0, luma);
    float3 silverShift = float3(-0.02, 0.0, 0.03); // Slight blue-silver shift
    bleached += silverShift * SilverTone * highlightMask;

    // Apply film grain
    if (GrainAmount > AS_EPSILON) {
        float time = AS_timeSeconds();
        float grain = AS_hash21(texcoord * 1000.0 + float2(time * 7.3, time * 11.1));
        grain = (grain - 0.5) * GrainAmount;
        bleached += grain;
    }

    // Clamp to valid range
    bleached = saturate(bleached);

    // Final composite
    float3 result = AS_composite(bleached, originalColor, BlendMode, BlendAmount);
    return float4(result, 1.0);
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_GFX_BleachBypass < ui_label = "[AS] GFX: Bleach Bypass"; ui_tooltip = "Desaturated high-contrast look with metallic sheen — classic bleach bypass film processing."; >
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = AS_BleachBypass::BleachBypassPS;
    }
}

} // namespace AS_BleachBypass

#endif // __AS_GFX_BleachBypass_1_fx
