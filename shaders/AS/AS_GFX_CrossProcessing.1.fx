/**
 * AS_GFX_CrossProcessing.1.fx - Film Cross-Processing Color Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Simulates developing film in the wrong chemistry — creates dramatic color shifts
 * characteristic of cross-processed film. E6 slide film in C41 negative chemistry
 * (or vice versa) produces saturated, shifted colors with distinctive tonal curves.
 *
 * FEATURES:
 * - 5 chemistry mismatch presets plus fully custom per-channel control
 * - Per-channel gamma, gain, and offset curves for R, G, B
 * - Adjustable saturation boost for vivid cross-processed look
 * - Audio-reactive effect strength
 * - Depth-aware stage integration
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Sample scene color and apply per-channel power curve remapping.
 * 2. Each preset defines unique gamma/gain/offset per R/G/B channel
 *    to recreate specific chemistry mismatch looks.
 * 3. Boost saturation (cross-processing typically creates vivid colors).
 * 4. Blend processed result with original via effect strength.
 *
 * ===================================================================================
 */

#ifndef __AS_GFX_CrossProcessing_1_fx
#define __AS_GFX_CrossProcessing_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================

static const float STRENGTH_MIN = 0.0;
static const float STRENGTH_MAX = 1.0;
static const float STRENGTH_STEP = 0.01;
static const float STRENGTH_DEFAULT = 0.6;

static const float GAMMA_MIN = 0.5;
static const float GAMMA_MAX = 2.0;
static const float GAMMA_STEP = 0.01;
static const float GAMMA_DEFAULT = 1.0;

static const float GAIN_MIN = 0.5;
static const float GAIN_MAX = 1.5;
static const float GAIN_STEP = 0.01;
static const float GAIN_DEFAULT = 1.0;

static const float OFFSET_MIN = -0.1;
static const float OFFSET_MAX = 0.1;
static const float OFFSET_STEP = 0.001;
static const float OFFSET_DEFAULT = 0.0;

static const float SAT_MIN = 0.8;
static const float SAT_MAX = 2.0;
static const float SAT_STEP = 0.01;
static const float SAT_DEFAULT = 1.3;

// ============================================================================
// SHADER DESCRIPTOR
// ============================================================================

uniform int as_shader_descriptor < ui_type = "radio"; ui_label = " "; ui_text = "\nSimulates cross-processed film with dramatic color shifts from chemistry mismatches.\nChoose from classic presets or dial in custom per-channel curves.\n\nAS StageFX | Cross Processing by Leon Aquitaine\n"; > = 0;

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// -- Chemistry Preset --
uniform int ChemistryPreset < ui_type = "combo"; ui_label = "Chemistry Preset"; ui_tooltip = "Select a cross-processing chemistry mismatch, or Custom for manual control.\nEach preset recreates a specific film processing error look."; ui_items = "Custom\0E6 in C41 (Green Shadows)\0C41 in E6 (Magenta Highlights)\0Slide to Negative (Cyan Shift)\0Negative to Slide (Warm Push)\0Extreme Cross (Wild Colors)\0"; ui_category = AS_CAT_APPEARANCE; > = 1;
uniform float EffectStrength < ui_type = "slider"; ui_label = "Effect Strength"; ui_tooltip = "Overall intensity of the cross-processing effect.\n0.0 = original image, 1.0 = full cross-processed look."; ui_min = STRENGTH_MIN; ui_max = STRENGTH_MAX; ui_step = STRENGTH_STEP; ui_category = AS_CAT_APPEARANCE; > = STRENGTH_DEFAULT;

// -- Custom Channel Controls (Red) --
uniform float RedGamma < ui_type = "slider"; ui_label = "Red Gamma"; ui_tooltip = "Power curve for the red channel. <1 brightens, >1 darkens red tones."; ui_min = GAMMA_MIN; ui_max = GAMMA_MAX; ui_step = GAMMA_STEP; ui_category = "Custom Curves"; > = GAMMA_DEFAULT;
uniform float RedGain < ui_type = "slider"; ui_label = "Red Gain"; ui_tooltip = "Multiplier for the red channel after gamma."; ui_min = GAIN_MIN; ui_max = GAIN_MAX; ui_step = GAIN_STEP; ui_category = "Custom Curves"; > = GAIN_DEFAULT;
uniform float RedOffset < ui_type = "slider"; ui_label = "Red Offset"; ui_tooltip = "Additive offset for the red channel."; ui_min = OFFSET_MIN; ui_max = OFFSET_MAX; ui_step = OFFSET_STEP; ui_category = "Custom Curves"; > = OFFSET_DEFAULT;

// -- Custom Channel Controls (Green) --
uniform float GreenGamma < ui_type = "slider"; ui_label = "Green Gamma"; ui_tooltip = "Power curve for the green channel."; ui_min = GAMMA_MIN; ui_max = GAMMA_MAX; ui_step = GAMMA_STEP; ui_category = "Custom Curves"; > = GAMMA_DEFAULT;
uniform float GreenGain < ui_type = "slider"; ui_label = "Green Gain"; ui_tooltip = "Multiplier for the green channel after gamma."; ui_min = GAIN_MIN; ui_max = GAIN_MAX; ui_step = GAIN_STEP; ui_category = "Custom Curves"; > = GAIN_DEFAULT;
uniform float GreenOffset < ui_type = "slider"; ui_label = "Green Offset"; ui_tooltip = "Additive offset for the green channel."; ui_min = OFFSET_MIN; ui_max = OFFSET_MAX; ui_step = OFFSET_STEP; ui_category = "Custom Curves"; > = OFFSET_DEFAULT;

// -- Custom Channel Controls (Blue) --
uniform float BlueGamma < ui_type = "slider"; ui_label = "Blue Gamma"; ui_tooltip = "Power curve for the blue channel."; ui_min = GAMMA_MIN; ui_max = GAMMA_MAX; ui_step = GAMMA_STEP; ui_category = "Custom Curves"; > = GAMMA_DEFAULT;
uniform float BlueGain < ui_type = "slider"; ui_label = "Blue Gain"; ui_tooltip = "Multiplier for the blue channel after gamma."; ui_min = GAIN_MIN; ui_max = GAIN_MAX; ui_step = GAIN_STEP; ui_category = "Custom Curves"; > = GAIN_DEFAULT;
uniform float BlueOffset < ui_type = "slider"; ui_label = "Blue Offset"; ui_tooltip = "Additive offset for the blue channel."; ui_min = OFFSET_MIN; ui_max = OFFSET_MAX; ui_step = OFFSET_STEP; ui_category = "Custom Curves"; > = OFFSET_DEFAULT;

// -- Saturation --
uniform float SaturationBoost < ui_type = "slider"; ui_label = "Saturation Boost"; ui_tooltip = "Cross-processing typically creates vivid, saturated colors.\nValues above 1.0 boost saturation."; ui_min = SAT_MIN; ui_max = SAT_MAX; ui_step = SAT_STEP; ui_category = "Custom Curves"; > = SAT_DEFAULT;

// -- Audio Reactivity --
AS_AUDIO_UI(CrossProc_AudioSource, "Audio Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(CrossProc_AudioMultiplier, "Audio Intensity", 1.0, 2.0, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(CrossProc_AudioTarget, "None\0Effect Strength\0", 0)

// -- Stage --
AS_STAGEDEPTH_UI(EffectDepth)

// -- Final Mix --
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// -- Debug --
AS_DEBUG_UI("Off\0Processed Only\0Difference\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

void SetPresetParams(out float rGamma, out float rGain, out float rOff,
                     out float gGamma, out float gGain, out float gOff,
                     out float bGamma, out float bGain, out float bOff,
                     out float sat)
{
    // Default to custom slider values
    rGamma = RedGamma; rGain = RedGain; rOff = RedOffset;
    gGamma = GreenGamma; gGain = GreenGain; gOff = GreenOffset;
    bGamma = BlueGamma; bGain = BlueGain; bOff = BlueOffset;
    sat = SaturationBoost;

    switch (ChemistryPreset)
    {
        case 1: // E6 in C41 — green shadows, yellow highlights
            rGamma = 0.9; rGain = 1.1; rOff = 0.0;
            gGamma = 0.8; gGain = 1.15; gOff = 0.02;
            bGamma = 1.2; bGain = 0.85; bOff = -0.03;
            sat = 1.3; break;
        case 2: // C41 in E6 — magenta highlights, cyan shadows
            rGamma = 0.85; rGain = 1.2; rOff = 0.02;
            gGamma = 1.1; gGain = 0.9; gOff = -0.01;
            bGamma = 0.9; bGain = 1.1; bOff = 0.02;
            sat = 1.2; break;
        case 3: // Slide to Negative — cyan overall shift
            rGamma = 1.2; rGain = 0.85; rOff = -0.02;
            gGamma = 0.95; gGain = 1.05; gOff = 0.01;
            bGamma = 0.8; bGain = 1.2; bOff = 0.03;
            sat = 1.4; break;
        case 4: // Negative to Slide — warm push
            rGamma = 0.8; rGain = 1.15; rOff = 0.03;
            gGamma = 0.9; gGain = 1.05; gOff = 0.01;
            bGamma = 1.1; bGain = 0.9; bOff = -0.02;
            sat = 1.25; break;
        case 5: // Extreme — wild colors
            rGamma = 0.7; rGain = 1.3; rOff = 0.05;
            gGamma = 1.3; gGain = 0.8; gOff = -0.03;
            bGamma = 0.75; bGain = 1.25; bOff = 0.04;
            sat = 1.5; break;
    }
}

// ============================================================================
// PIXEL SHADER
// ============================================================================

float4 PS_CrossProcessing(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);

    // Depth check
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth)
    {
        if (DebugMode == 0) return originalColor;
    }

    // Audio reactivity
    float audioMod = AS_audioModulate(1.0, CrossProc_AudioSource, CrossProc_AudioMultiplier, true, 0);
    float strengthFinal = EffectStrength;
    if (CrossProc_AudioTarget == 1) strengthFinal *= audioMod;

    // Get chemistry parameters
    float rGamma, rGain, rOff;
    float gGamma, gGain, gOff;
    float bGamma, bGain, bOff;
    float sat;
    SetPresetParams(rGamma, rGain, rOff, gGamma, gGain, gOff, bGamma, bGain, bOff, sat);

    // Apply per-channel curve remapping
    float3 processed;
    processed.r = pow(max(originalColor.r, AS_EPSILON), rGamma) * rGain + rOff;
    processed.g = pow(max(originalColor.g, AS_EPSILON), gGamma) * gGain + gOff;
    processed.b = pow(max(originalColor.b, AS_EPSILON), bGamma) * bGain + bOff;
    processed = saturate(processed);

    // Boost saturation
    processed = AS_adjustSaturation(processed, sat);

    // Mix processed with original based on effect strength
    float3 mixed = lerp(originalColor.rgb, processed, strengthFinal);

    // Debug views
    if (DebugMode == 1) return float4(processed, 1.0);
    if (DebugMode == 2) return float4(abs(processed - originalColor.rgb), 1.0);

    // Final composite
    float3 result = AS_composite(mixed, originalColor.rgb, BlendMode, BlendAmount);

    return float4(result, originalColor.a);
}

// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_GFX_CrossProcessing
<
    ui_label = "[AS] GFX: Cross Processing";
    ui_tooltip = "Film cross-processing effect with chemistry mismatch presets.\n"
                 "Creates dramatic color shifts from wrong-chemistry film development.\n"
                 "Performance: Light (single-pass color grading)";
>
{
    pass Main
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CrossProcessing;
    }
}

#endif // __AS_GFX_CrossProcessing_1_fx
