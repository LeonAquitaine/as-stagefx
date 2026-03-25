/**
 * AS_GFX_ColorPop.1.fx - Selective Hue Desaturation (Color Pop)
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Desaturates the entire scene except for a chosen hue range, creating the iconic
 * "only the red dress has color" effect. Isolate any color to make it pop against
 * a monochrome background.
 *
 * FEATURES:
 * - Hue-based color isolation with adjustable target, range, and softness
 * - Full control over desaturation amount for non-selected areas
 * - Saturation boost for the kept hue to make it stand out
 * - Depth-aware mode: desaturate background regardless of hue
 * - Audio-reactive hue range or desaturation amount
 * - Depth-aware via stage depth control
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Sample scene color and extract hue via RGB-to-hue conversion
 * 2. Compute circular hue distance from target hue
 * 3. Build selection mask using smoothstep for soft transitions
 * 4. Desaturate non-selected pixels to grayscale
 * 5. Optionally boost saturation of selected hue
 * 6. Composite with AS_composite for final blend
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_GFX_ColorPop_1_fx
#define __AS_GFX_ColorPop_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// NAMESPACE
// ============================================================================
namespace AS_ColorPop {

// ============================================================================
// CONSTANTS
// ============================================================================

// --- Target Hue ---
static const float HUE_MIN = 0.0;
static const float HUE_MAX = 1.0;
static const float HUE_DEFAULT = 0.0;

// --- Hue Range ---
static const float HUE_RANGE_MIN = 0.01;
static const float HUE_RANGE_MAX = 0.2;
static const float HUE_RANGE_DEFAULT = 0.08;

// --- Hue Softness ---
static const float HUE_SOFT_MIN = 0.0;
static const float HUE_SOFT_MAX = 0.1;
static const float HUE_SOFT_DEFAULT = 0.03;

// --- Desaturation ---
static const float DESAT_MIN = 0.0;
static const float DESAT_MAX = 1.0;
static const float DESAT_DEFAULT = 1.0;

// --- Saturation Boost ---
static const float SAT_BOOST_MIN = 1.0;
static const float SAT_BOOST_MAX = 2.0;
static const float SAT_BOOST_DEFAULT = 1.3;

// --- Debug Mode ---
static const int DEBUG_OFF = 0;
static const int DEBUG_HUE_MASK = 1;
static const int DEBUG_HUE_MAP = 2;

// ============================================================================
// UNIFORMS
// ============================================================================

uniform int as_shader_descriptor <ui_type = "radio"; ui_label = " "; ui_text = "\nDesaturates everything except one hue range for a dramatic color-pop effect.\nIsolate reds, blues, or any color against a monochrome scene.\n\nAS StageFX | Color Pop by Leon Aquitaine\n"; > = 0;

// --- Hue Selection ---
uniform float TargetHue < ui_type = "slider"; ui_label = "Target Hue"; ui_tooltip = "Which hue to keep colorful.\n0.0 = Red, 0.17 = Yellow, 0.33 = Green, 0.5 = Cyan, 0.66 = Blue, 0.83 = Magenta."; ui_min = HUE_MIN; ui_max = HUE_MAX; ui_step = 0.01; ui_category = "Hue Selection"; > = HUE_DEFAULT;
uniform float HueRange < ui_type = "slider"; ui_label = "Hue Range"; ui_tooltip = "Width of the kept hue band.\nSmaller = more selective, larger = wider color range preserved."; ui_min = HUE_RANGE_MIN; ui_max = HUE_RANGE_MAX; ui_step = 0.005; ui_category = "Hue Selection"; > = HUE_RANGE_DEFAULT;
uniform float HueSoftness < ui_type = "slider"; ui_label = "Hue Softness"; ui_tooltip = "Smooth transition at the edges of the hue selection.\nHigher = smoother falloff from color to grayscale."; ui_min = HUE_SOFT_MIN; ui_max = HUE_SOFT_MAX; ui_step = 0.005; ui_category = "Hue Selection"; > = HUE_SOFT_DEFAULT;

// --- Desaturation ---
uniform float Desaturation < ui_type = "slider"; ui_label = "Desaturation"; ui_tooltip = "How much non-selected areas are desaturated.\n1.0 = full grayscale, 0.0 = no effect."; ui_min = DESAT_MIN; ui_max = DESAT_MAX; ui_step = 0.01; ui_category = "Color Pop"; > = DESAT_DEFAULT;
uniform float SatBoost < ui_type = "slider"; ui_label = "Saturation Boost"; ui_tooltip = "Boost the saturation of the selected hue to make it pop more."; ui_min = SAT_BOOST_MIN; ui_max = SAT_BOOST_MAX; ui_step = 0.01; ui_category = "Color Pop"; > = SAT_BOOST_DEFAULT;
uniform bool DepthAware < ui_type = "checkbox"; ui_label = "Depth-Aware Mode"; ui_tooltip = "When enabled, the background is always desaturated regardless of hue.\nOnly foreground pixels (characters) keep their selected color."; ui_category = "Color Pop"; > = false;

// --- Audio Reactivity ---
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(AudioMultiplier, "Audio Intensity", 1.0, 2.0, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(AudioTarget, "None\0Hue Range\0Desaturation\0", 0)

// --- Stage ---
AS_STAGEDEPTH_UI(EffectDepth)

// --- Final Mix ---
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug ---
AS_DEBUG_UI("Off\0Hue Mask\0Hue Map\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Extract hue from RGB (0-1 range, circular)
float extractHue(float3 c) {
    float maxC = max(c.r, max(c.g, c.b));
    float minC = min(c.r, min(c.g, c.b));
    float chroma = maxC - minC;
    if (chroma < AS_EPSILON) return 0.0; // achromatic
    float hue;
    if (maxC == c.r)
        hue = (c.g - c.b) / chroma;
    else if (maxC == c.g)
        hue = 2.0 + (c.b - c.r) / chroma;
    else
        hue = 4.0 + (c.r - c.g) / chroma;
    return frac(hue / 6.0);
}

// Circular hue distance (handles wrap-around at 0/1 boundary)
float hueDistance(float h1, float h2) {
    float d = abs(h1 - h2);
    return min(d, 1.0 - d);
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 ColorPopPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {
    // Depth-aware early return
    AS_DEPTH_EARLY_RETURN(texcoord, EffectDepth)

    float3 originalColor = tex2D(ReShade::BackBuffer, texcoord).rgb;

    // Audio modulation
    float hueRangeFinal = HueRange;
    float desatFinal = Desaturation;
    if (AudioTarget == 1) {
        hueRangeFinal = AS_audioModulate(hueRangeFinal, AudioSource, AudioMultiplier, true, 0);
    }
    if (AudioTarget == 2) {
        desatFinal = AS_audioModulate(desatFinal, AudioSource, AudioMultiplier, true, 0);
    }

    // Extract hue
    float hue = extractHue(originalColor);

    // Compute circular distance from target hue
    float hueDist = hueDistance(hue, TargetHue);

    // Build selection mask: 1.0 for target hue, 0.0 for others
    float mask = smoothstep(hueRangeFinal + HueSoftness, max(hueRangeFinal - HueSoftness, 0.0), hueDist);

    // Depth-aware: force desaturation on background pixels
    if (DepthAware) {
        float depth = ReShade::GetLinearizedDepth(texcoord);
        float depthMask = smoothstep(0.3, 0.5, depth);
        mask *= (1.0 - depthMask);
    }

    // Compute luminance for desaturation
    float luma = dot(originalColor, AS_LUMA_REC709);
    float3 grayColor = float3(luma, luma, luma);

    // Apply selective desaturation: non-selected goes gray, selected stays
    float3 desaturated = lerp(originalColor, grayColor, desatFinal * (1.0 - mask));

    // Boost saturation of selected hue
    float satMult = lerp(1.0, SatBoost, mask);
    float3 effectColor = AS_adjustSaturation(desaturated, satMult);

    // Debug views
    if (DebugMode == DEBUG_HUE_MASK) {
        return float4(mask.xxx, 1.0);
    }
    if (DebugMode == DEBUG_HUE_MAP) {
        // Visualize hue as rainbow gradient
        float3 hueVis = float3(
            saturate(abs(hue * 6.0 - 3.0) - 1.0),
            saturate(2.0 - abs(hue * 6.0 - 2.0)),
            saturate(2.0 - abs(hue * 6.0 - 4.0))
        );
        return float4(hueVis, 1.0);
    }

    // Final composite
    float3 result = AS_composite(effectColor, originalColor, BlendMode, BlendAmount);
    return float4(result, 1.0);
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_GFX_ColorPop < ui_label = "[AS] GFX: Color Pop"; ui_tooltip = "Desaturates everything except a chosen hue range for dramatic color isolation."; >
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = AS_ColorPop::ColorPopPS;
    }
}

} // namespace AS_ColorPop

#endif // __AS_GFX_ColorPop_1_fx
