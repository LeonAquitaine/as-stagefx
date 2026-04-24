/**
 * AS_GFX_Halation.1.fx - Film Halation Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Simulates film halation — a warm red/orange bloom that spreads wider than normal
 * white bloom, characteristic of analog film stocks. Light passes through the film
 * emulsion, reflects off the backing plate, and re-exposes the film from behind,
 * creating a distinctive warm glow around bright areas.
 *
 * FEATURES:
 * - Red-biased threshold for authentic halation isolation
 * - Warm red-orange Gaussian bloom (separate H/V passes for quality)
 * - Film stock presets: Kodak Vision, Kodak Gold, CineStill 800T, Custom
 * - Adjustable halation spread, intensity, and color
 * - Audio-reactive halation intensity
 * - Stage depth masking
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. (Pass 1) Isolate bright areas with red channel bias, multiply by halation color.
 * 2. (Pass 2) Horizontal Gaussian blur of the halation buffer.
 * 3. (Pass 3) Vertical Gaussian blur, then additive composite onto the scene.
 *
 * ===================================================================================
 */

#ifndef __AS_GFX_Halation_1_fx
#define __AS_GFX_Halation_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// TEXTURES & SAMPLERS
// ============================================================================
texture Halation_ThresholdBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
texture Halation_HalationBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };

sampler Halation_ThresholdSampler { Texture = Halation_ThresholdBuffer; AddressU = CLAMP; AddressV = CLAMP; };
sampler Halation_HalationSampler { Texture = Halation_HalationBuffer; AddressU = CLAMP; AddressV = CLAMP; };

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
static const float BLUR_AXIS_SCALE = 2.0;

static const float THRESHOLD_MIN = 0.0;
static const float THRESHOLD_MAX = 1.0;
static const float THRESHOLD_DEFAULT = 0.6;
static const float THRESHOLD_STEP = 0.01;

static const float KNEE_MIN = 0.01;
static const float KNEE_MAX = 0.5;
static const float KNEE_DEFAULT = 0.2;
static const float KNEE_STEP = 0.01;

static const int SPREAD_MIN = 5;
static const int SPREAD_MAX = 50;
static const int SPREAD_DEFAULT = 20;

static const float INTENSITY_MIN = 0.0;
static const float INTENSITY_MAX = 1.5;
static const float INTENSITY_DEFAULT = 0.4;
static const float INTENSITY_STEP = 0.01;

static const float RED_BIAS_MIN = 0.0;
static const float RED_BIAS_MAX = 1.0;
static const float RED_BIAS_DEFAULT = 0.6;
static const float RED_BIAS_STEP = 0.01;

static const int FILM_CUSTOM = 0;
static const int FILM_KODAK_VISION = 1;
static const int FILM_KODAK_GOLD = 2;
static const int FILM_CINESTILL_800T = 3;

static const int BLUR_STEPS_MAX = 50;

// ============================================================================
// SHADER DESCRIPTOR
// ============================================================================

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// -- Film Stock --

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform int FilmStock < ui_type = "combo"; ui_label = "Film Stock"; ui_tooltip = "Select a film stock preset or Custom for manual control.\nEach stock has its own halation color and spread."; ui_items = "Custom\0Kodak Vision\0Kodak Gold\0CineStill 800T\0"; ui_category = "Film Stock"; > = FILM_KODAK_VISION;

// -- Halation --
uniform float BrightnessThreshold < ui_type = "slider"; ui_label = "Brightness Threshold"; ui_tooltip = "Minimum brightness for halation to appear.\nLower values create halation on dimmer areas."; ui_min = THRESHOLD_MIN; ui_max = THRESHOLD_MAX; ui_step = THRESHOLD_STEP; ui_category = "Halation"; > = THRESHOLD_DEFAULT;
uniform float ThresholdKnee < ui_type = "slider"; ui_label = "Threshold Knee"; ui_tooltip = "Soft transition width around the brightness threshold."; ui_min = KNEE_MIN; ui_max = KNEE_MAX; ui_step = KNEE_STEP; ui_category = "Halation"; > = KNEE_DEFAULT;
uniform int HalationSpread < ui_type = "slider"; ui_label = "Halation Spread"; ui_tooltip = "How far the halation bloom extends, in pixels.\nOnly used in Custom mode; presets override this."; ui_min = SPREAD_MIN; ui_max = SPREAD_MAX; ui_step = 1; ui_category = "Halation"; > = SPREAD_DEFAULT;
uniform float HalationIntensity < ui_type = "slider"; ui_label = "Halation Intensity"; ui_tooltip = "Brightness of the halation glow."; ui_min = INTENSITY_MIN; ui_max = INTENSITY_MAX; ui_step = INTENSITY_STEP; ui_category = "Halation"; > = INTENSITY_DEFAULT;
uniform float3 HalationColor < ui_type = "color"; ui_label = "Halation Color"; ui_tooltip = "Color of the halation glow.\nOnly used in Custom mode; presets override this."; ui_category = "Halation"; > = float3(1.0, 0.4, 0.15);
uniform float RedBias < ui_type = "slider"; ui_label = "Red Bias"; ui_tooltip = "How much the red channel is favored when detecting bright areas.\nHigher values make halation more sensitive to warm/red highlights."; ui_min = RED_BIAS_MIN; ui_max = RED_BIAS_MAX; ui_step = RED_BIAS_STEP; ui_category = "Halation"; > = RED_BIAS_DEFAULT;

// -- Animation --
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, AS_CAT_ANIMATION)

// -- Audio Reactivity --
AS_AUDIO_UI(Halation_AudioSource, "Audio Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(Halation_AudioMultiplier, "Audio Intensity", 1.0, 2.0, AS_CAT_AUDIO)

// -- Stage --
AS_STAGEDEPTH_UI(EffectDepth)

// -- Final Mix --
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// -- Debug --
AS_DEBUG_UI("Off\0Threshold Mask\0Halation Only\0Before-After\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

namespace AS_Halation {

    // Returns halation color and spread based on film stock preset
    void getFilmPreset(int preset, out float3 color, out int spread) {
        if (preset == FILM_KODAK_VISION) {
            color = float3(1.0, 0.35, 0.12);
            spread = 22;
        } else if (preset == FILM_KODAK_GOLD) {
            color = float3(1.0, 0.5, 0.2);
            spread = 18;
        } else if (preset == FILM_CINESTILL_800T) {
            color = float3(1.0, 0.15, 0.05);
            spread = 35;
        } else {
            color = HalationColor;
            spread = HalationSpread;
        }
    }

} // namespace AS_Halation

// ============================================================================
// PIXEL SHADERS
// ============================================================================

// Pass 1: Isolate bright pixels with red bias, apply halation color
void PS_IsolateHighlights(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 outColor : SV_Target)
{
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float luma = dot(color, AS_LUMA_REC709);
    float redBiased = max(color.r * (1.0 + RedBias), luma);
    float mask = smoothstep(BrightnessThreshold - ThresholdKnee, BrightnessThreshold + ThresholdKnee, redBiased);

    float3 halColor;
    int halSpread;
    AS_Halation::getFilmPreset(FilmStock, halColor, halSpread);

    outColor = float4(color * mask * halColor, mask);
}

// Pass 2: Horizontal Gaussian blur
void PS_BlurHorizontal(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 outColor : SV_Target)
{
    float3 halColor;
    int halSpread;
    AS_Halation::getFilmPreset(FilmStock, halColor, halSpread);

    int nSteps = max(1, halSpread);
    float expCoeff = -2.0 / (nSteps * nSteps + AS_GAUSS_EXP_EPSILON);
    float2 blurAxis = float2(ReShade::PixelSize.x, 0.0);

    float3 colorSum = float3(0.0, 0.0, 0.0);
    float weightSum = 0.0;

    for (int i = -BLUR_STEPS_MAX; i <= BLUR_STEPS_MAX; i++)
    {
        if (i < -nSteps || i > nSteps) continue;
        float weight = exp((float)(i * i) * expCoeff);
        float offset = BLUR_AXIS_SCALE * (float)i - 0.5;
        float3 samp = tex2Dlod(Halation_ThresholdSampler, float4(texcoord + blurAxis * offset, 0, 0)).rgb;
        colorSum += samp * weight;
        weightSum += weight;
    }

    outColor = float4(colorSum / max(weightSum, AS_EPSILON), 1.0);
}

// Pass 3: Vertical Gaussian blur and composite
float4 PS_BlurVerticalAndComposite(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);

    float3 halColor;
    int halSpread;
    AS_Halation::getFilmPreset(FilmStock, halColor, halSpread);

    int nSteps = max(1, halSpread);
    float expCoeff = -2.0 / (nSteps * nSteps + AS_GAUSS_EXP_EPSILON);
    float2 blurAxis = float2(0.0, ReShade::PixelSize.y);

    float3 colorSum = float3(0.0, 0.0, 0.0);
    float weightSum = 0.0;

    for (int i = -BLUR_STEPS_MAX; i <= BLUR_STEPS_MAX; i++)
    {
        if (i < -nSteps || i > nSteps) continue;
        float weight = exp((float)(i * i) * expCoeff);
        float offset = BLUR_AXIS_SCALE * (float)i - 0.5;
        float3 samp = tex2Dlod(Halation_HalationSampler, float4(texcoord + blurAxis * offset, 0, 0)).rgb;
        colorSum += samp * weight;
        weightSum += weight;
    }

    float3 halation = colorSum / max(weightSum, AS_EPSILON);

    // Audio reactivity
    float audioMod = AS_audioModulate(1.0, Halation_AudioSource, Halation_AudioMultiplier, true, 0);
    halation *= HalationIntensity * audioMod;

    // Stage depth masking
    float depth = ReShade::GetLinearizedDepth(texcoord);
    float depthMask = depth >= EffectDepth ? 1.0 : 0.0;
    halation *= depthMask;

    // Debug views
    if (DebugMode == 1) {
        float3 threshold = tex2D(Halation_ThresholdSampler, texcoord).rgb;
        return float4(threshold, 1.0);
    }
    if (DebugMode == 2) return float4(halation, 1.0);
    if (DebugMode == 3) {
        if (texcoord.x < 0.5) return originalColor;
    }

    // Additive light
    float3 halatedScene = originalColor.rgb + halation;
    float3 result = AS_composite(halatedScene, originalColor.rgb, BlendMode, BlendAmount);

    return float4(result, originalColor.a);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_GFX_Halation
<
    ui_label = "[AS] GFX: Halation";
    ui_tooltip = "Film halation — warm red/orange bloom from bright areas.\n"
                 "Characteristic of analog film stocks like CineStill 800T.\n"
                 "Performance: Medium (3-pass Gaussian blur)";
>
{
    pass IsolateHighlights
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_IsolateHighlights;
        RenderTarget = Halation_ThresholdBuffer;
    }
    pass BlurHorizontal
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_BlurHorizontal;
        RenderTarget = Halation_HalationBuffer;
    }
    pass BlurVerticalComposite
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_BlurVerticalAndComposite;
    }
}

#endif // __AS_GFX_Halation_1_fx
