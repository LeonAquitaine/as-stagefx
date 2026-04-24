/**
 * AS_GFX_OrtonEffect.1.fx - Dreamy Orton Glow Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Reproduces the Orton Effect — a photographic technique where a sharp image is combined
 * with an overexposed, heavily blurred copy via multiplication. The result has crisp detail
 * visible through a luminous soft glow, creating a dreamy, painterly look popular in
 * portrait and landscape photography.
 *
 * FEATURES:
 * - Adjustable brightness boost and blur radius for the soft layer
 * - Depth-aware mode: apply only to background while keeping the subject sharp
 * - Saturation and contrast compensation controls
 * - Color tint for the glow layer (warm/cool/custom via palette)
 * - Audio-reactive glow intensity
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. (Pass 1) Create an overexposed copy and blur it horizontally.
 * 2. (Pass 2) Blur vertically to complete the soft overexposed layer.
 * 3. (Pass 3) Multiply the sharp original with the soft bright layer, then
 *    composite the result using the user's chosen blend mode and strength.
 *
 * ===================================================================================
 */

#ifndef __AS_GFX_OrtonEffect_1_fx
#define __AS_GFX_OrtonEffect_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================

static const float GLOW_BOOST_MIN = 1.0;
static const float GLOW_BOOST_MAX = 3.0;
static const float GLOW_BOOST_STEP = 0.05;
static const float GLOW_BOOST_DEFAULT = 1.5;

static const float BLUR_RADIUS_MIN = 1.0;
static const float BLUR_RADIUS_MAX = 30.0;
static const float BLUR_RADIUS_STEP = 0.5;
static const float BLUR_RADIUS_DEFAULT = 12.0;

static const float ORTON_STRENGTH_MIN = 0.0;
static const float ORTON_STRENGTH_MAX = 1.0;
static const float ORTON_STRENGTH_STEP = 0.01;
static const float ORTON_STRENGTH_DEFAULT = 0.5;

static const float SATURATION_MIN = 0.0;
static const float SATURATION_MAX = 2.0;
static const float SATURATION_STEP = 0.01;
static const float SATURATION_DEFAULT = 1.2;

static const float CONTRAST_MIN = 0.5;
static const float CONTRAST_MAX = 1.5;
static const float CONTRAST_STEP = 0.01;
static const float CONTRAST_DEFAULT = 1.0;

static const float BLUR_AXIS_SCALE = 2.0;

// ============================================================================
// TEXTURES & SAMPLERS
// ============================================================================

texture OrtonEffect_BlurH { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler OrtonEffect_BlurHSampler { Texture = OrtonEffect_BlurH; };

texture OrtonEffect_SoftLayer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler OrtonEffect_SoftLayerSampler { Texture = OrtonEffect_SoftLayer; };

// ============================================================================
// SHADER DESCRIPTOR
// ============================================================================

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// -- Orton Appearance --

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform float OrtonStrength < ui_type = "slider"; ui_label = "Effect Strength"; ui_tooltip = "How much of the Orton glow is mixed into the image.\n0.0 = no effect, 1.0 = full dreamy glow."; ui_min = ORTON_STRENGTH_MIN; ui_max = ORTON_STRENGTH_MAX; ui_step = ORTON_STRENGTH_STEP; ui_category = "Orton Appearance"; > = ORTON_STRENGTH_DEFAULT;
uniform float GlowBoost < ui_type = "slider"; ui_label = "Glow Brightness"; ui_tooltip = "How much the soft layer is brightened before blending.\nHigher = more luminous, overexposed glow. 1.0 = no boost."; ui_min = GLOW_BOOST_MIN; ui_max = GLOW_BOOST_MAX; ui_step = GLOW_BOOST_STEP; ui_category = "Orton Appearance"; > = GLOW_BOOST_DEFAULT;
uniform float BlurRadius < ui_type = "slider"; ui_label = "Blur Radius"; ui_tooltip = "Size of the soft glow. Higher = dreamier, more diffused.\nLower = subtle glow with more visible detail."; ui_min = BLUR_RADIUS_MIN; ui_max = BLUR_RADIUS_MAX; ui_step = BLUR_RADIUS_STEP; ui_category = "Orton Appearance"; > = BLUR_RADIUS_DEFAULT;
uniform float SaturationBoost < ui_type = "slider"; ui_label = "Saturation"; ui_tooltip = "Adjusts color saturation of the final result.\nValues above 1.0 create richer, more vivid colors typical of Orton photography."; ui_min = SATURATION_MIN; ui_max = SATURATION_MAX; ui_step = SATURATION_STEP; ui_category = "Orton Appearance"; > = SATURATION_DEFAULT;
uniform float ContrastComp < ui_type = "slider"; ui_label = "Contrast Recovery"; ui_tooltip = "Compensates for the contrast loss caused by the glow.\n1.0 = no compensation, higher = recover contrast."; ui_min = CONTRAST_MIN; ui_max = CONTRAST_MAX; ui_step = CONTRAST_STEP; ui_category = "Orton Appearance"; > = CONTRAST_DEFAULT;

// -- Glow Color --
uniform int GlowColorMode < ui_type = "combo"; ui_label = "Glow Tint Mode"; ui_tooltip = "How the glow is tinted.\nNatural: uses the scene's own colors.\nTint Color: applies a fixed warm/cool color.\nPalette: maps glow to selected palette."; ui_items = "Natural\0Tint Color\0Palette\0"; ui_category = "Orton Appearance"; > = 0;
uniform float3 GlowTint < ui_type = "color"; ui_label = "Glow Tint Color"; ui_tooltip = "Color applied to the glow layer when Tint mode is active.\nWarm tones (gold, amber) give a classic Orton look."; ui_category = "Orton Appearance"; > = float3(1.0, 0.95, 0.88);

// -- Depth Control --
uniform bool DepthAware < ui_type = "input"; ui_label = "Depth-Aware Mode"; ui_tooltip = "When enabled, the Orton glow only applies to pixels behind the stage depth.\nKeeps the foreground subject sharp while the background gets dreamy."; ui_category = "Orton Appearance"; > = false;

// -- Palette & Style --
AS_PALETTE_SELECTION_UI(PalettePreset, "Glow Palette", AS_PALETTE_SUNSET, AS_CAT_PALETTE)
AS_DECLARE_CUSTOM_PALETTE(OrtonEffect_, AS_CAT_PALETTE)

// -- Animation --
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, AS_CAT_ANIMATION)

// -- Audio Reactivity --
AS_AUDIO_UI(OrtonEffect_AudioSource, "Audio Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(OrtonEffect_AudioMultiplier, "Audio Intensity", 1.0, 2.0, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(OrtonEffect_AudioTarget, "None\0Glow Brightness\0Effect Strength\0Blur Radius\0", 0)

// -- Stage --
AS_STAGEDEPTH_UI(EffectDepth)

// -- Final Mix --
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// -- Debug --
AS_DEBUG_UI("Off\0Soft Layer\0Orton Result\0Depth Mask\0")

// ============================================================================
// PIXEL SHADERS
// ============================================================================

// Pass 1: Brighten the scene and blur horizontally to create the soft overexposed layer
float4 PS_OrtonEffect_BlurH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float audioMod = AS_audioModulate(1.0, OrtonEffect_AudioSource, OrtonEffect_AudioMultiplier, true, 0);
    float glowBoostFinal = GlowBoost;
    float blurRadiusFinal = BlurRadius;

    if (OrtonEffect_AudioTarget == 1) glowBoostFinal *= audioMod;
    if (OrtonEffect_AudioTarget == 3) blurRadiusFinal *= audioMod;

    int nSteps = max(1, (int)floor(blurRadiusFinal));
    const float expCoeff = -2.0 / (nSteps * nSteps + AS_GAUSS_EXP_EPSILON);
    const float2 blurAxis = float2(ReShade::PixelSize.x, 0.0);

    float3 colorSum = 0.0;
    float weightSum = 0.0;

    for (int i = -nSteps; i <= nSteps; i++)
    {
        float weight = exp((float)(i * i) * expCoeff);
        float offset = BLUR_AXIS_SCALE * (float)i - 0.5;
        float3 samp = tex2Dlod(ReShade::BackBuffer, float4(texcoord + blurAxis * offset, 0, 0)).rgb;

        // Brighten the sample (overexpose) before accumulating
        colorSum += samp * glowBoostFinal * weight;
        weightSum += weight;
    }

    return float4(colorSum / weightSum, 1.0);
}

// Pass 2: Vertical blur to complete the soft overexposed layer
float4 PS_OrtonEffect_BlurV(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float audioMod = AS_audioModulate(1.0, OrtonEffect_AudioSource, OrtonEffect_AudioMultiplier, true, 0);
    float blurRadiusFinal = BlurRadius;
    if (OrtonEffect_AudioTarget == 3) blurRadiusFinal *= audioMod;

    int nSteps = max(1, (int)floor(blurRadiusFinal));
    const float expCoeff = -2.0 / (nSteps * nSteps + AS_GAUSS_EXP_EPSILON);
    const float2 blurAxis = float2(0.0, ReShade::PixelSize.y);

    float3 colorSum = 0.0;
    float weightSum = 0.0;

    for (int i = -nSteps; i <= nSteps; i++)
    {
        float weight = exp((float)(i * i) * expCoeff);
        float offset = BLUR_AXIS_SCALE * (float)i - 0.5;
        float3 samp = tex2Dlod(OrtonEffect_BlurHSampler, float4(texcoord + blurAxis * offset, 0, 0)).rgb;

        colorSum += samp * weight;
        weightSum += weight;
    }

    return float4(colorSum / weightSum, 1.0);
}

// Pass 3: Multiply sharp × soft, apply tint, composite
float4 PS_OrtonEffect_Composite(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float3 softLayer = tex2D(OrtonEffect_SoftLayerSampler, texcoord).rgb;

    // Audio reactivity
    float audioMod = AS_audioModulate(1.0, OrtonEffect_AudioSource, OrtonEffect_AudioMultiplier, true, 0);
    float strengthFinal = OrtonStrength;
    if (OrtonEffect_AudioTarget == 2) strengthFinal *= audioMod;

    // Apply glow tint based on color mode
    if (GlowColorMode == 1) {
        // Tint: multiply soft layer by tint color
        softLayer *= GlowTint;
    } else if (GlowColorMode == 2) {
        // Palette: map soft layer luminance to palette color
        float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);
        float luma = dot(softLayer, AS_LUMA_REC709);
        float t = frac(luma + time * 0.05);
        float3 paletteColor;
        if (PalettePreset == AS_PALETTE_CUSTOM) {
            paletteColor = AS_GET_INTERPOLATED_CUSTOM_COLOR(OrtonEffect_, t);
        } else {
            paletteColor = AS_getInterpolatedColor(PalettePreset, t);
        }
        // Blend palette color with soft layer, preserving luminance structure
        softLayer *= paletteColor;
    }

    // The Orton multiplication: sharp × soft (overexposed)
    // This creates detail visible through glow — the signature Orton look
    float3 ortonResult = originalColor.rgb * softLayer;

    // Apply contrast recovery (Orton multiplication tends to lose contrast)
    float3 midpoint = float3(0.5, 0.5, 0.5);
    ortonResult = midpoint + (ortonResult - midpoint) * ContrastComp;

    // Apply saturation boost
    ortonResult = AS_adjustSaturation(ortonResult, SaturationBoost);

    // Depth-aware mode: only apply to background
    float depthMask = 1.0;
    if (DepthAware) {
        float depth = ReShade::GetLinearizedDepth(texcoord);
        depthMask = (depth >= EffectDepth) ? 1.0 : 0.0;
    }

    // Debug views
    if (DebugMode == 1) return float4(softLayer, 1.0);
    if (DebugMode == 2) return float4(ortonResult, 1.0);
    if (DebugMode == 3) return float4(depthMask.xxx, 1.0);

    // Mix: blend between original and Orton result based on strength and depth
    float3 effectResult = lerp(originalColor.rgb, saturate(ortonResult), strengthFinal * depthMask);

    // User's BlendMode/BlendAmount for final mix
    float3 result = AS_composite(effectResult, originalColor.rgb, BlendMode, BlendAmount);

    return float4(result, originalColor.a);
}

// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_GFX_OrtonEffect
<
    ui_label = "[AS] GFX: Orton Effect";
    ui_tooltip = "Dreamy glow effect — sharp detail through luminous soft overlay.\n"
                 "Classic portrait/landscape photography technique.\n"
                 "Performance: Moderate (3-pass separable blur)";
>
{
    pass BlurH
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_OrtonEffect_BlurH;
        RenderTarget = OrtonEffect_BlurH;
    }
    pass BlurV
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_OrtonEffect_BlurV;
        RenderTarget = OrtonEffect_SoftLayer;
    }
    pass Composite
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_OrtonEffect_Composite;
    }
}

#endif // __AS_GFX_OrtonEffect_1_fx
