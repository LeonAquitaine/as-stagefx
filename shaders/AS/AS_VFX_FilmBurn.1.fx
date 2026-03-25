/**
 * AS_VFX_FilmBurn.1.fx - Animated film overexposure effect from frame edges
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Simulates warm film overexposure spreading from frame edges, as if the film
 * stock is overheating. Multiple animated soft gradients drift and pulse from
 * the edges, colored with a warm orange-to-white progression.
 *
 * FEATURES:
 * - Multiple layered burn gradients from frame edges
 * - Configurable edge bias (all edges, top only, top & sides, corners only)
 * - Three color modes: Film Orange, custom tint color, or palette-driven
 * - Adjustable overexposure wash-out at peak intensity
 * - Smooth animated drift and pulsing
 * - Audio-reactive burn intensity for beat-synced flares
 * - Depth-aware masking via stage depth control
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Generates 3 animated soft gradients from frame edges using noise and distance
 * 2. Colors them with warm orange-to-white progression based on intensity
 * 3. Animates drift and pulsing using sine-based time functions
 * 4. Composites additively (burns only ADD light) then applies AS_composite
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_FilmBurn_1_fx
#define __AS_VFX_FilmBurn_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

// ============================================================================
// NAMESPACE
// ============================================================================
namespace AS_FilmBurn {

// ============================================================================
// CONSTANTS
// ============================================================================

// --- Burn Intensity ---
static const float INTENSITY_MIN = 0.0;
static const float INTENSITY_MAX = 1.0;
static const float INTENSITY_DEFAULT = 0.4;

// --- Burn Spread ---
static const float SPREAD_MIN = 0.1;
static const float SPREAD_MAX = 1.0;
static const float SPREAD_DEFAULT = 0.4;

// --- Burn Speed ---
static const float SPEED_MIN = 0.0;
static const float SPEED_MAX = 2.0;
static const float SPEED_DEFAULT = 0.3;

// --- Overexposure ---
static const float OVEREXPOSURE_MIN = 0.0;
static const float OVEREXPOSURE_MAX = 1.0;
static const float OVEREXPOSURE_DEFAULT = 0.5;

// --- Edge Bias ---
static const int EDGE_ALL = 0;
static const int EDGE_TOP_ONLY = 1;
static const int EDGE_TOP_AND_SIDES = 2;
static const int EDGE_CORNERS_ONLY = 3;

// --- Color Mode ---
static const int COLOR_FILM_ORANGE = 0;
static const int COLOR_TINT = 1;
static const int COLOR_PALETTE = 2;

// --- Debug Mode ---
static const int DEBUG_OFF = 0;
static const int DEBUG_BURN_MASK = 1;
static const int DEBUG_BURN_COLOR = 2;

// --- Internal ---
static const float3 FILM_ORANGE = float3(1.0, 0.7, 0.3);
static const float NOISE_SCALE = 3.0;
static const int NUM_LAYERS = 3;

// ============================================================================
// UNIFORMS
// ============================================================================

uniform int as_shader_descriptor <ui_type = "radio"; ui_label = " "; ui_text = "\nAnimated warm overexposure spreading from frame edges.\nSimulates film overheating with drifting burn effects.\n\nAS StageFX | Film Burn by Leon Aquitaine\n"; > = 0;

// --- Effect Controls ---
uniform float BurnIntensity < ui_type = "slider"; ui_label = "Burn Intensity"; ui_tooltip = "Overall brightness of the film burn effect."; ui_min = INTENSITY_MIN; ui_max = INTENSITY_MAX; ui_step = 0.01; ui_category = "Film Burn"; > = INTENSITY_DEFAULT;
uniform float BurnSpread < ui_type = "slider"; ui_label = "Burn Spread"; ui_tooltip = "How far the burns reach from the frame edges toward the center."; ui_min = SPREAD_MIN; ui_max = SPREAD_MAX; ui_step = 0.01; ui_category = "Film Burn"; > = SPREAD_DEFAULT;
uniform float Overexposure < ui_type = "slider"; ui_label = "Overexposure"; ui_tooltip = "How much the burn washes out to white at peak intensity."; ui_min = OVEREXPOSURE_MIN; ui_max = OVEREXPOSURE_MAX; ui_step = 0.01; ui_category = "Film Burn"; > = OVEREXPOSURE_DEFAULT;
uniform int EdgeBias < ui_type = "combo"; ui_label = "Edge Bias"; ui_items = "All Edges\0Top Only\0Top & Sides\0Corners Only\0"; ui_tooltip = "Controls which edges the burn effect emanates from."; ui_category = "Film Burn"; > = EDGE_ALL;

// --- Color ---
uniform int ColorMode < ui_type = "combo"; ui_label = "Color Mode"; ui_items = "Film Orange\0Tint Color\0Palette\0"; ui_tooltip = "Choose how the burn is colored."; ui_category = AS_CAT_COLOR; > = COLOR_FILM_ORANGE;
uniform float3 TintColor < ui_type = "color"; ui_label = "Tint Color"; ui_tooltip = "Custom tint color for the burn (used when Color Mode is Tint Color)."; ui_category = AS_CAT_COLOR; > = float3(1.0, 0.7, 0.3);

// --- Palette ---
AS_PALETTE_SELECTION_UI(PalettePreset, "Burn Palette", AS_PALETTE_FIRE, AS_CAT_PALETTE)
AS_DECLARE_CUSTOM_PALETTE(Burn, AS_CAT_PALETTE)

// --- Animation ---
AS_ANIMATION_UI(AnimSpeed, AnimKeyframe, AS_CAT_ANIMATION)

// --- Audio Reactivity ---
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(AudioMultIntensity, "Burn Intensity", 1.0, 3.0, AS_CAT_AUDIO)

// --- Stage ---
AS_STAGEDEPTH_UI(EffectDepth)

// --- Final Mix ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug ---
AS_DEBUG_UI("Off\0Burn Mask\0Burn Color\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Simple pseudo-noise for animation variation
float burnNoise(float2 uv, float seed) {
    return frac(sin(dot(uv + seed, float2(12.9898, 78.233))) * 43758.5453);
}

// Compute edge distance factor based on edge bias mode
float getEdgeFactor(float2 texcoord, int bias) {
    float distTop = texcoord.y;
    float distBottom = 1.0 - texcoord.y;
    float distLeft = texcoord.x;
    float distRight = 1.0 - texcoord.x;

    float edgeDist = 1.0;

    if (bias == EDGE_ALL) {
        edgeDist = min(min(distTop, distBottom), min(distLeft, distRight));
    }
    else if (bias == EDGE_TOP_ONLY) {
        edgeDist = distTop;
    }
    else if (bias == EDGE_TOP_AND_SIDES) {
        edgeDist = min(distTop, min(distLeft, distRight));
    }
    else if (bias == EDGE_CORNERS_ONLY) {
        float cornerDist = length(float2(min(distLeft, distRight), min(distTop, distBottom)));
        edgeDist = cornerDist;
    }

    return edgeDist;
}

// Get burn color based on intensity and color mode
float3 getBurnColor(float burnAmount) {
    float3 baseColor = FILM_ORANGE;

    if (ColorMode == COLOR_TINT) {
        baseColor = TintColor;
    }
    else if (ColorMode == COLOR_PALETTE) {
        float t = saturate(burnAmount);
        if (PalettePreset == AS_PALETTE_CUSTOM) {
            baseColor = AS_GET_INTERPOLATED_CUSTOM_COLOR(Burn, t);
        } else {
            baseColor = AS_getInterpolatedColor(PalettePreset, t);
        }
    }

    // Wash toward white at high intensity for overexposure
    float3 burnColor = lerp(baseColor, float3(1.0, 1.0, 1.0), burnAmount * Overexposure);
    return burnColor;
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 FilmBurnPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {
    // Depth-aware early return
    AS_DEPTH_EARLY_RETURN(texcoord, EffectDepth)

    float3 originalColor = tex2D(ReShade::BackBuffer, texcoord).rgb;

    float animTime = AS_getAnimationTime(AnimSpeed, AnimKeyframe);

    // Audio-modulated intensity
    float currentIntensity = AS_audioModulate(BurnIntensity, AudioSource, AudioMultIntensity, true, 0);
    currentIntensity = saturate(currentIntensity);

    // Compute edge distance
    float edgeDist = getEdgeFactor(texcoord, EdgeBias);

    // Accumulate burn from multiple layers
    float totalBurn = 0.0;

    // Layer offsets for variation
    static const float2 layerOffsets[NUM_LAYERS] = {
        float2(0.7, 0.3),
        float2(1.3, 0.8),
        float2(0.4, 1.6)
    };
    static const float layerSpeeds[NUM_LAYERS] = { 1.0, 0.7, 1.3 };
    static const float layerWeights[NUM_LAYERS] = { 1.0, 0.7, 0.5 };

    for (int i = 0; i < NUM_LAYERS; i++) {
        // Animated UV offset for drift
        float2 driftUV = texcoord + layerOffsets[i] * 0.1;
        float driftTime = animTime * SPEED_DEFAULT * layerSpeeds[i];

        // Sine-based pulsing
        float pulse = 0.6 + 0.4 * sin(driftTime * AS_TWO_PI * 0.3 + float(i) * 2.1);

        // Noise-based variation
        float2 noiseUV = texcoord * NOISE_SCALE + float2(sin(driftTime * 0.7), cos(driftTime * 0.5)) * 0.2;
        float noise = burnNoise(noiseUV, float(i) * 7.13 + driftTime * 0.1);

        // Edge gradient with noise modulation
        float edgeGradient = 1.0 - saturate(edgeDist / max(BurnSpread, AS_EPSILON));
        edgeGradient = smoothstep(0.0, 1.0, edgeGradient);
        edgeGradient *= pulse * lerp(0.6, 1.0, noise);

        totalBurn += edgeGradient * layerWeights[i];
    }

    // Normalize and apply intensity
    totalBurn = saturate(totalBurn / 2.2) * currentIntensity;

    // Debug views
    if (DebugMode == DEBUG_BURN_MASK) {
        return float4(totalBurn.xxx, 1.0);
    }

    // Get colored burn
    float3 burnColor = getBurnColor(totalBurn);
    float3 effectLight = burnColor * totalBurn;

    if (DebugMode == DEBUG_BURN_COLOR) {
        return float4(effectLight, 1.0);
    }

    // Additive light composite then blend
    float3 effectColor = originalColor + effectLight;

    // Final composite
    float3 result = AS_composite(effectColor, originalColor, BlendMode, BlendAmount);
    return float4(result, 1.0);
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_VFX_FilmBurn < ui_label = "[AS] VFX: Film Burn"; ui_tooltip = "Animated warm overexposure spreading from frame edges, simulating film overheating."; >
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = AS_FilmBurn::FilmBurnPS;
    }
}

} // namespace AS_FilmBurn

#endif // __AS_VFX_FilmBurn_1_fx
