/**
 * AS_GFX_AnamorphicFlare.1.fx - Anamorphic Lens Flare Streaks
 * Author: Leon Aquitaine
 * License: CC BY 4.0
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates horizontal streak flares from bright light sources, simulating the
 * characteristic look of anamorphic cinema lenses. Bright areas in the scene
 * are isolated, then stretched into wide horizontal streaks with optional
 * color tinting.
 *
 * FEATURES:
 * - Threshold-based bright pixel isolation with soft knee.
 * - Heavy horizontal Gaussian blur for signature anamorphic streaks.
 * - Multiple streak color presets (Anamorphic Blue, Warm Amber, etc.).
 * - Palette and custom tint support.
 * - Audio-reactive streak intensity.
 * - Animation support for threshold variation.
 * - Stage depth masking.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. (Pass 1) Isolate bright pixels above threshold using smoothstep with knee.
 * 2. (Pass 2) Apply heavy horizontal-only Gaussian blur to create streaks.
 * 3. (Pass 3) Composite streaks additively onto the original scene.
 *
 * ===================================================================================
 */

#ifndef __AS_GFX_AnamorphicFlare_1_fx
#define __AS_GFX_AnamorphicFlare_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

uniform int as_shader_descriptor <ui_type = "radio"; ui_label = " "; ui_text = "\nHorizontal anamorphic streak flares from bright areas.\nSimulates the look of anamorphic cinema lenses.\n\nAS StageFX | Anamorphic Flare by Leon Aquitaine\n"; > = 0;

// ============================================================================
// TEXTURES & SAMPLERS
// ============================================================================
texture AnamorphicFlare_ThresholdBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
texture AnamorphicFlare_StreakBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };

sampler AnamorphicFlare_ThresholdSampler { Texture = AnamorphicFlare_ThresholdBuffer; AddressU = CLAMP; AddressV = CLAMP; };
sampler AnamorphicFlare_StreakSampler { Texture = AnamorphicFlare_StreakBuffer; AddressU = CLAMP; AddressV = CLAMP; };

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
static const float BLUR_AXIS_SCALE = 2.0;
static const int MAX_STREAK_STEPS = 100;

static const float THRESHOLD_MIN = 0.0;
static const float THRESHOLD_MAX = 1.0;
static const float THRESHOLD_DEFAULT = 0.7;

static const float KNEE_MIN = 0.01;
static const float KNEE_MAX = 0.5;
static const float KNEE_DEFAULT = 0.15;

static const int STREAKLEN_MIN = 10;
static const int STREAKLEN_MAX = 200;
static const int STREAKLEN_DEFAULT = 80;

static const float INTENSITY_MIN = 0.0;
static const float INTENSITY_MAX = 2.0;
static const float INTENSITY_DEFAULT = 0.6;

// ============================================================================
// EFFECT-SPECIFIC PARAMETERS
// ============================================================================

// --- Threshold ---
uniform float BrightnessThreshold < ui_type = "slider"; ui_label = "Brightness Threshold"; ui_tooltip = "Minimum brightness to generate a streak."; ui_min = THRESHOLD_MIN; ui_max = THRESHOLD_MAX; ui_step = 0.01; ui_category = "Threshold"; > = THRESHOLD_DEFAULT;
uniform float ThresholdKnee < ui_type = "slider"; ui_label = "Threshold Knee"; ui_tooltip = "Soft transition width into the streak region."; ui_min = KNEE_MIN; ui_max = KNEE_MAX; ui_step = 0.01; ui_category = "Threshold"; > = KNEE_DEFAULT;

// --- Streak ---
uniform int StreakLength < ui_type = "slider"; ui_label = "Streak Length"; ui_tooltip = "Horizontal blur radius controlling how long the streaks extend."; ui_min = STREAKLEN_MIN; ui_max = STREAKLEN_MAX; ui_step = 1; ui_category = "Streak"; > = STREAKLEN_DEFAULT;
uniform float StreakIntensity < ui_type = "slider"; ui_label = "Streak Intensity"; ui_tooltip = "Brightness of the anamorphic streaks."; ui_min = INTENSITY_MIN; ui_max = INTENSITY_MAX; ui_step = 0.01; ui_category = "Streak"; > = INTENSITY_DEFAULT;
uniform int StreakColorMode < ui_type = "combo"; ui_label = "Streak Color"; ui_tooltip = "Select the color style for the streaks."; ui_items = "Anamorphic Blue\0Warm Amber\0Cool Cyan\0Tint Color\0Palette\0"; ui_category = "Streak"; > = 0;
uniform float3 TintColor < ui_type = "color"; ui_label = "Tint Color"; ui_tooltip = "Custom tint color for the streaks (used when Streak Color is set to Tint Color)."; ui_category = "Streak"; > = float3(0.4, 0.6, 1.0);

// ============================================================================
// PALETTE & STYLE
// ============================================================================
AS_PALETTE_SELECTION_UI(PalettePreset, "Palette", AS_PALETTE_BLUE, AS_CAT_PALETTE)
AS_DECLARE_CUSTOM_PALETTE(Flare_, AS_CAT_PALETTE)

// ============================================================================
// ANIMATION
// ============================================================================
AS_ANIMATION_UI(AnimSpeed, AnimKeyframe, AS_CAT_ANIMATION)

// ============================================================================
// AUDIO REACTIVITY
// ============================================================================
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_BEAT, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(AudioMultiplier, "Intensity", 0.5, 2.0, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(AudioTarget, "None\0Streak Intensity\0", 0)

// ============================================================================
// STAGE & DEPTH
// ============================================================================
AS_STAGEDEPTH_UI(EffectDepth)

// ============================================================================
// FINAL MIX
// ============================================================================
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_LIGHTEN)
AS_BLENDAMOUNT_UI(BlendStrength)

// ============================================================================
// DEBUG
// ============================================================================
AS_DEBUG_UI("Off\0Threshold Mask\0Streak Only\0Before-After\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

float3 GetStreakColor(float t)
{
    if (StreakColorMode == 0) return float3(0.4, 0.6, 1.0);       // Anamorphic Blue
    if (StreakColorMode == 1) return float3(1.0, 0.75, 0.3);      // Warm Amber
    if (StreakColorMode == 2) return float3(0.3, 0.85, 1.0);      // Cool Cyan
    if (StreakColorMode == 3) return TintColor;                     // Custom Tint
    // Palette mode
    if (PalettePreset == AS_PALETTE_CUSTOM)
        return AS_GET_CUSTOM_PALETTE_COLOR(Flare_, 0);
    return AS_getPaletteColor(PalettePreset, (int)(t * (AS_PALETTE_COLORS - 1)));
}

// ============================================================================
// PIXEL SHADERS
// ============================================================================

// Pass 1: Isolate bright pixels
void PS_IsolateHighlights(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 outColor : SV_Target)
{
    float animTime = AS_getAnimationTime(AnimSpeed, AnimKeyframe);
    float thresholdVar = BrightnessThreshold + sin(animTime * 0.5) * 0.02;

    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float luma = dot(color, AS_LUMA_REC709);
    float mask = smoothstep(thresholdVar - ThresholdKnee, thresholdVar + ThresholdKnee, luma);
    outColor = float4(color * mask, mask);
}

// Pass 2: Heavy horizontal Gaussian blur for streaks
void PS_HorizontalStreak(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 outColor : SV_Target)
{
    int nSteps = max(1, (int)floor((float)StreakLength));

    float3 colorSum = 0.0;
    float weightSum = 0.0;

    float expCoeff = -2.0 / (nSteps * nSteps + AS_GAUSS_EXP_EPSILON);
    float2 blurAxis = float2(ReShade::PixelSize.x, 0.0);

    for (int i = -MAX_STREAK_STEPS; i <= MAX_STREAK_STEPS; i++)
    {
        if (i < -nSteps || i > nSteps) continue;

        float weight = exp((float)(i * i) * expCoeff);
        float offset = BLUR_AXIS_SCALE * (float)i - 0.5;

        float3 samp = tex2Dlod(AnamorphicFlare_ThresholdSampler, float4(texcoord + blurAxis * offset, 0, 0)).rgb;
        colorSum += samp * weight;
        weightSum += weight;
    }

    float3 streakColor = colorSum / weightSum;

    // Apply streak color tint
    float t = saturate(texcoord.x);
    float3 tint = GetStreakColor(t);
    streakColor *= tint;

    outColor = float4(streakColor, 1.0);
}

// Pass 3: Composite streaks onto original scene
void PS_Composite(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 outColor : SV_Target)
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float3 streak = tex2D(AnamorphicFlare_StreakSampler, texcoord).rgb;

    // Audio-reactive intensity
    float intensity = StreakIntensity;
    if (AudioTarget == 1)
    {
        float audioMod = AS_audioModulate(1.0, AudioSource, AudioMultiplier, true, 0);
        intensity = StreakIntensity * audioMod;
    }

    streak *= intensity;

    // Stage depth masking
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    float depthMask = sceneDepth >= EffectDepth ? 1.0 : 0.0;

    // Debug modes
    if (DebugMode == 1)
    {
        float3 threshold = tex2D(AnamorphicFlare_ThresholdSampler, texcoord).rgb;
        outColor = float4(threshold, 1.0);
        return;
    }
    if (DebugMode == 2)
    {
        outColor = float4(streak, 1.0);
        return;
    }
    if (DebugMode == 3)
    {
        if (texcoord.x < 0.5)
        {
            outColor = originalColor;
            return;
        }
    }

    // Additive light composite
    float3 effectColor = originalColor.rgb + streak;
    float3 result = AS_composite(effectColor, originalColor.rgb, BlendMode, BlendStrength * depthMask);
    outColor = float4(result, originalColor.a);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_GFX_AnamorphicFlare
<
    ui_label = "[AS] GFX: Anamorphic Flare";
    ui_tooltip = "Horizontal anamorphic streak flares from bright light sources.\n"
                 "Simulates the look of anamorphic cinema lenses.";
>
{
    pass IsolateHighlights
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_IsolateHighlights;
        RenderTarget = AnamorphicFlare_ThresholdBuffer;
    }
    pass HorizontalStreak
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_HorizontalStreak;
        RenderTarget = AnamorphicFlare_StreakBuffer;
    }
    pass Composite
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Composite;
    }
}

#endif // __AS_GFX_AnamorphicFlare_1_fx
