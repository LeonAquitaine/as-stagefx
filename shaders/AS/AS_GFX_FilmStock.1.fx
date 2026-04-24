/**
 * AS_GFX_FilmStock.1.fx - Film Stock Emulation
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Emulates the color science, grain, and tonal characteristics of classic analog
 * film stocks. Each preset reproduces the distinctive look of a real-world film,
 * from the warm golden tones of Kodak Gold to the punchy contrast of Tri-X.
 *
 * FEATURES:
 * - 8 film stock presets plus Custom mode with full manual control
 * - Authentic film grain using procedural noise
 * - Split toning with independent shadow and highlight tints
 * - Contrast, saturation, black lift, and highlight warmth controls
 * - Built-in vignette per film stock
 * - Audio-reactive grain intensity
 * - Stage depth masking
 *
 * IMPLEMENTATION OVERVIEW:
 * Single-pass: apply contrast, split toning, saturation, black lift,
 * highlight warmth, film grain, and vignette in sequence.
 *
 * ===================================================================================
 */

#ifndef __AS_GFX_FilmStock_1_fx
#define __AS_GFX_FilmStock_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Noise.1.fxh"

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
static const float GRAIN_MIN = 0.0;
static const float GRAIN_MAX = 1.0;
static const float GRAIN_DEFAULT = 0.25;
static const float GRAIN_STEP = 0.01;

static const float CONTRAST_MIN = 0.5;
static const float CONTRAST_MAX = 2.0;
static const float CONTRAST_DEFAULT = 1.1;
static const float CONTRAST_STEP = 0.01;

static const float SATURATION_MIN = 0.0;
static const float SATURATION_MAX = 2.0;
static const float SATURATION_DEFAULT = 1.0;
static const float SATURATION_STEP = 0.01;

static const float BLACK_LIFT_MIN = 0.0;
static const float BLACK_LIFT_MAX = 0.15;
static const float BLACK_LIFT_DEFAULT = 0.03;
static const float BLACK_LIFT_STEP = 0.005;

static const float HIGHLIGHT_WARMTH_MIN = 0.0;
static const float HIGHLIGHT_WARMTH_MAX = 1.0;
static const float HIGHLIGHT_WARMTH_DEFAULT = 0.2;
static const float HIGHLIGHT_WARMTH_STEP = 0.01;

static const float VIGNETTE_MIN = 0.0;
static const float VIGNETTE_MAX = 0.5;
static const float VIGNETTE_DEFAULT = 0.15;
static const float VIGNETTE_STEP = 0.01;

static const int FILM_CUSTOM = 0;
static const int FILM_KODAK_GOLD_200 = 1;
static const int FILM_KODAK_PORTRA_400 = 2;
static const int FILM_FUJI_SUPERIA_400 = 3;
static const int FILM_FUJI_VELVIA_50 = 4;
static const int FILM_ILFORD_HP5 = 5;
static const int FILM_KODAK_TRIX = 6;
static const int FILM_KODAK_EKTAR_100 = 7;
static const int FILM_CINESTILL_800T = 8;

// ============================================================================
// SHADER DESCRIPTOR
// ============================================================================

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// -- Film Stock --

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform int FilmPreset < ui_type = "combo"; ui_label = "Film Stock"; ui_tooltip = "Select a film stock preset or Custom for manual control.\nEach preset emulates the color science of a real-world film."; ui_items = "Custom\0Kodak Gold 200\0Kodak Portra 400\0Fuji Superia 400\0Fuji Velvia 50\0Ilford HP5 (B&W)\0Kodak Tri-X (B&W)\0Kodak Ektar 100\0CineStill 800T\0"; ui_category = "Film Stock"; > = FILM_KODAK_GOLD_200;

// -- Custom Controls (used when Film Stock is Custom) --
uniform float GrainIntensity < ui_type = "slider"; ui_label = "Grain Intensity"; ui_tooltip = "Amount of film grain noise.\nOnly used in Custom mode; presets override this."; ui_min = GRAIN_MIN; ui_max = GRAIN_MAX; ui_step = GRAIN_STEP; ui_category = "Custom Controls"; > = GRAIN_DEFAULT;
uniform float Contrast < ui_type = "slider"; ui_label = "Contrast"; ui_tooltip = "Film contrast curve strength.\n1.0 = neutral. Higher values increase contrast."; ui_min = CONTRAST_MIN; ui_max = CONTRAST_MAX; ui_step = CONTRAST_STEP; ui_category = "Custom Controls"; > = CONTRAST_DEFAULT;
uniform float Saturation < ui_type = "slider"; ui_label = "Saturation"; ui_tooltip = "Color saturation. 0.0 = black and white, 1.0 = neutral, higher = vivid."; ui_min = SATURATION_MIN; ui_max = SATURATION_MAX; ui_step = SATURATION_STEP; ui_category = "Custom Controls"; > = SATURATION_DEFAULT;
uniform float BlackLift < ui_type = "slider"; ui_label = "Black Lift"; ui_tooltip = "Lifts the deepest shadows to simulate film base fog.\nHigher values create a faded, vintage look."; ui_min = BLACK_LIFT_MIN; ui_max = BLACK_LIFT_MAX; ui_step = BLACK_LIFT_STEP; ui_category = "Custom Controls"; > = BLACK_LIFT_DEFAULT;
uniform float HighlightWarmth < ui_type = "slider"; ui_label = "Highlight Warmth"; ui_tooltip = "Adds warm tones to bright areas.\n0.0 = neutral highlights, 1.0 = warm golden highlights."; ui_min = HIGHLIGHT_WARMTH_MIN; ui_max = HIGHLIGHT_WARMTH_MAX; ui_step = HIGHLIGHT_WARMTH_STEP; ui_category = "Custom Controls"; > = HIGHLIGHT_WARMTH_DEFAULT;
uniform float3 ShadowTint < ui_type = "color"; ui_label = "Shadow Tint"; ui_tooltip = "Color multiplier applied to shadow areas."; ui_category = "Custom Controls"; > = float3(1.0, 0.98, 0.85);
uniform float3 HighlightTint < ui_type = "color"; ui_label = "Highlight Tint"; ui_tooltip = "Color multiplier applied to highlight areas."; ui_category = "Custom Controls"; > = float3(1.1, 1.0, 0.85);
uniform float VignetteStrength < ui_type = "slider"; ui_label = "Vignette Strength"; ui_tooltip = "Darkens the edges of the frame.\n0.0 = no vignette, higher = stronger darkening."; ui_min = VIGNETTE_MIN; ui_max = VIGNETTE_MAX; ui_step = VIGNETTE_STEP; ui_category = "Custom Controls"; > = VIGNETTE_DEFAULT;

// -- Animation --
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, AS_CAT_ANIMATION)

// -- Audio Reactivity --
AS_AUDIO_UI(Film_AudioSource, "Audio Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(Film_AudioMultiplier, "Audio Intensity", 1.0, 2.0, AS_CAT_AUDIO)

// -- Stage --
AS_STAGEDEPTH_UI(EffectDepth)

// -- Final Mix --
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// -- Debug --
AS_DEBUG_UI("Off\0Grain Only\0Split Tone\0Vignette Mask\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

namespace AS_FilmStock {

    struct FilmParams {
        float grain;
        float blackLift;
        float highlightWarmth;
        float3 shadowTint;
        float3 highlightTint;
        float saturation;
        float contrast;
        float vignette;
    };

    FilmParams getPreset(int preset) {
        FilmParams p;
        if (preset == FILM_KODAK_GOLD_200) {
            p.grain = 0.25; p.blackLift = 0.04; p.highlightWarmth = 0.5;
            p.shadowTint = float3(1.0, 0.98, 0.85); p.highlightTint = float3(1.1, 1.0, 0.85);
            p.saturation = 1.3; p.contrast = 1.1; p.vignette = 0.15;
        } else if (preset == FILM_KODAK_PORTRA_400) {
            p.grain = 0.15; p.blackLift = 0.03; p.highlightWarmth = 0.2;
            p.shadowTint = float3(1.0, 1.0, 0.95); p.highlightTint = float3(1.05, 1.0, 0.95);
            p.saturation = 0.95; p.contrast = 0.95; p.vignette = 0.1;
        } else if (preset == FILM_FUJI_SUPERIA_400) {
            p.grain = 0.2; p.blackLift = 0.03; p.highlightWarmth = 0.0;
            p.shadowTint = float3(0.9, 1.0, 1.05); p.highlightTint = float3(1.0, 1.02, 0.98);
            p.saturation = 1.2; p.contrast = 1.1; p.vignette = 0.12;
        } else if (preset == FILM_FUJI_VELVIA_50) {
            p.grain = 0.1; p.blackLift = 0.02; p.highlightWarmth = 0.1;
            p.shadowTint = float3(0.95, 0.95, 1.05); p.highlightTint = float3(1.0, 1.0, 0.95);
            p.saturation = 1.5; p.contrast = 1.2; p.vignette = 0.15;
        } else if (preset == FILM_ILFORD_HP5) {
            p.grain = 0.35; p.blackLift = 0.05; p.highlightWarmth = 0.0;
            p.shadowTint = float3(1.0, 1.0, 1.0); p.highlightTint = float3(1.0, 1.0, 1.0);
            p.saturation = 0.0; p.contrast = 1.1; p.vignette = 0.2;
        } else if (preset == FILM_KODAK_TRIX) {
            p.grain = 0.3; p.blackLift = 0.03; p.highlightWarmth = 0.0;
            p.shadowTint = float3(1.0, 1.0, 1.0); p.highlightTint = float3(1.0, 1.0, 1.0);
            p.saturation = 0.0; p.contrast = 1.3; p.vignette = 0.15;
        } else if (preset == FILM_KODAK_EKTAR_100) {
            p.grain = 0.08; p.blackLift = 0.02; p.highlightWarmth = 0.05;
            p.shadowTint = float3(1.0, 0.98, 1.0); p.highlightTint = float3(1.0, 1.0, 1.0);
            p.saturation = 1.4; p.contrast = 1.15; p.vignette = 0.1;
        } else if (preset == FILM_CINESTILL_800T) {
            p.grain = 0.2; p.blackLift = 0.04; p.highlightWarmth = 0.0;
            p.shadowTint = float3(0.85, 0.95, 1.1); p.highlightTint = float3(1.0, 0.95, 0.9);
            p.saturation = 1.0; p.contrast = 1.05; p.vignette = 0.12;
        } else {
            // Custom — use uniform values
            p.grain = GrainIntensity; p.blackLift = BlackLift; p.highlightWarmth = HighlightWarmth;
            p.shadowTint = ShadowTint; p.highlightTint = HighlightTint;
            p.saturation = Saturation; p.contrast = Contrast; p.vignette = VignetteStrength;
        }
        return p;
    }

} // namespace AS_FilmStock

// ============================================================================
// PIXEL SHADER
// ============================================================================

float4 PS_FilmStock(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float3 color = originalColor.rgb;

    // Depth check
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth && DebugMode == 0) return originalColor;

    // Get film parameters
    AS_FilmStock::FilmParams fp = AS_FilmStock::getPreset(FilmPreset);

    // Audio reactivity — modulate grain intensity
    float audioMod = AS_audioModulate(1.0, Film_AudioSource, Film_AudioMultiplier, true, 0);
    float grainFinal = fp.grain * audioMod;

    float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);

    // 1. Apply contrast
    color = 0.5 + (color - 0.5) * fp.contrast;
    color = saturate(color);

    // 2. Split toning: shadows get shadowTint, highlights get highlightTint
    float luma = dot(color, AS_LUMA_REC709);
    color = lerp(color * fp.shadowTint, color * fp.highlightTint, saturate(luma));

    // 3. Apply saturation
    color = AS_adjustSaturation(color, fp.saturation);

    // 4. Lift blacks
    color = color * (1.0 - fp.blackLift) + fp.blackLift;

    // 5. Highlight warmth
    float highlights = saturate(luma * 2.0 - 1.0);
    color += float3(fp.highlightWarmth * 0.1, fp.highlightWarmth * 0.05, 0.0) * highlights;

    // 6. Film grain
    float noise = AS_hash21(texcoord * 800.0 + frac(time * 100.0)) * 2.0 - 1.0;
    float grainMask = grainFinal * (1.0 - luma * 0.5);
    color += noise * grainMask * 0.15;

    // 7. Vignette
    float2 centered = texcoord - 0.5;
    centered.x *= ReShade::AspectRatio;
    float vignette = 1.0 - dot(centered, centered) * fp.vignette * 4.0;
    vignette = saturate(vignette);
    color *= vignette;

    color = saturate(color);

    // Debug views
    if (DebugMode == 1) {
        float grainVis = noise * grainMask * 0.15 + 0.5;
        return float4(grainVis, grainVis, grainVis, 1.0);
    }
    if (DebugMode == 2) {
        float3 splitVis = lerp(fp.shadowTint, fp.highlightTint, saturate(luma));
        return float4(splitVis, 1.0);
    }
    if (DebugMode == 3) {
        return float4(vignette, vignette, vignette, 1.0);
    }

    // Final composite
    float3 result = AS_composite(color, originalColor.rgb, BlendMode, BlendAmount);

    return float4(result, originalColor.a);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_GFX_FilmStock
<
    ui_label = "[AS] GFX: Film Stock";
    ui_tooltip = "Emulates classic analog film stocks with grain, color science,\n"
                 "and tonal characteristics. 8 presets plus custom mode.\n"
                 "Performance: Light (single-pass)";
>
{
    pass Main
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_FilmStock;
    }
}

#endif // __AS_GFX_FilmStock_1_fx
