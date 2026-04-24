/**
 * AS_VFX_CrossScreenStars.1.fx - Cross-Screen Star Diffraction Filter
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Adds 4/6/8-point star diffraction spikes on bright highlights, simulating a
 * cross-screen (star) filter placed in front of a camera lens. Bright areas in
 * the scene sprout luminous spikes that radiate outward with controllable length,
 * rotation, and falloff.
 *
 * FEATURES:
 * - Configurable 4, 6, or 8-point star patterns
 * - Adjustable spike length, intensity, rotation, and falloff
 * - Brightness threshold with soft knee for natural highlight isolation
 * - Color modes: White, Tint, or Palette coloring
 * - Audio-reactive spike intensity or length
 * - Stage depth masking
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. (Pass 1) Isolate bright pixels above threshold using smoothstep with knee.
 * 2. (Pass 2) For each pixel, sample along multiple diagonal directions to
 *    accumulate star spike brightness with exponential distance falloff.
 *    Add the star pattern additively to the original scene.
 *
 * ===================================================================================
 */

#ifndef __AS_VFX_CrossScreenStars_1_fx
#define __AS_VFX_CrossScreenStars_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

// ============================================================================
// TEXTURES & SAMPLERS
// ============================================================================
texture CrossScreenStars_ThresholdBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler CrossScreenStars_ThresholdSampler { Texture = CrossScreenStars_ThresholdBuffer; AddressU = CLAMP; AddressV = CLAMP; };

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
static const float THRESHOLD_MIN = 0.0;
static const float THRESHOLD_MAX = 1.0;
static const float THRESHOLD_DEFAULT = 0.75;
static const float THRESHOLD_STEP = 0.01;

static const float KNEE_MIN = 0.01;
static const float KNEE_MAX = 0.3;
static const float KNEE_DEFAULT = 0.1;
static const float KNEE_STEP = 0.01;

static const int SPIKE_LENGTH_MIN = 5;
static const int SPIKE_LENGTH_MAX = 100;
static const int SPIKE_LENGTH_DEFAULT = 30;

static const float SPIKE_INTENSITY_MIN = 0.0;
static const float SPIKE_INTENSITY_MAX = 2.0;
static const float SPIKE_INTENSITY_DEFAULT = 0.5;
static const float SPIKE_INTENSITY_STEP = 0.01;

static const float STAR_ROTATION_MIN = 0.0;
static const float STAR_ROTATION_MAX = 90.0;
static const float STAR_ROTATION_DEFAULT = 45.0;
static const float STAR_ROTATION_STEP = 0.5;

static const float SPIKE_FALLOFF_MIN = 1.0;
static const float SPIKE_FALLOFF_MAX = 4.0;
static const float SPIKE_FALLOFF_DEFAULT = 2.0;
static const float SPIKE_FALLOFF_STEP = 0.05;

static const int COLOR_MODE_WHITE = 0;
static const int COLOR_MODE_TINT = 1;
static const int COLOR_MODE_PALETTE = 2;

static const int MAX_SPIKE_SAMPLES = 64;

// ============================================================================
// SHADER DESCRIPTOR
// ============================================================================

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// -- Threshold --

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform float BrightnessThreshold < ui_type = "slider"; ui_label = "Brightness Threshold"; ui_tooltip = "Minimum brightness for a pixel to generate star spikes.\nLower values create stars on dimmer areas."; ui_min = THRESHOLD_MIN; ui_max = THRESHOLD_MAX; ui_step = THRESHOLD_STEP; ui_category = "Threshold"; > = THRESHOLD_DEFAULT;
uniform float ThresholdKnee < ui_type = "slider"; ui_label = "Threshold Knee"; ui_tooltip = "Soft transition width around the threshold.\nLarger values create a gentler fade-in."; ui_min = KNEE_MIN; ui_max = KNEE_MAX; ui_step = KNEE_STEP; ui_category = "Threshold"; > = KNEE_DEFAULT;

// -- Star Shape --
uniform int StarPoints < ui_type = "combo"; ui_label = "Star Points"; ui_tooltip = "Number of points in the star pattern.\n4-Point: classic cross. 6-Point: asterisk. 8-Point: dense star."; ui_items = "4-Point\06-Point\08-Point\0"; ui_category = "Star Shape"; > = 0;
uniform int SpikeLength < ui_type = "slider"; ui_label = "Spike Length"; ui_tooltip = "How far the spikes extend from each bright point, in pixels."; ui_min = SPIKE_LENGTH_MIN; ui_max = SPIKE_LENGTH_MAX; ui_step = 1; ui_category = "Star Shape"; > = SPIKE_LENGTH_DEFAULT;
uniform float SpikeIntensity < ui_type = "slider"; ui_label = "Spike Intensity"; ui_tooltip = "Brightness of the star spikes."; ui_min = SPIKE_INTENSITY_MIN; ui_max = SPIKE_INTENSITY_MAX; ui_step = SPIKE_INTENSITY_STEP; ui_category = "Star Shape"; > = SPIKE_INTENSITY_DEFAULT;
uniform float StarRotation < ui_type = "slider"; ui_label = "Star Rotation"; ui_tooltip = "Rotation angle of the star pattern in degrees."; ui_min = STAR_ROTATION_MIN; ui_max = STAR_ROTATION_MAX; ui_step = STAR_ROTATION_STEP; ui_category = "Star Shape"; > = STAR_ROTATION_DEFAULT;
uniform float SpikeFalloff < ui_type = "slider"; ui_label = "Spike Falloff"; ui_tooltip = "How quickly the spikes fade with distance.\nHigher values produce shorter, sharper spikes."; ui_min = SPIKE_FALLOFF_MIN; ui_max = SPIKE_FALLOFF_MAX; ui_step = SPIKE_FALLOFF_STEP; ui_category = "Star Shape"; > = SPIKE_FALLOFF_DEFAULT;

// -- Color --
uniform int ColorMode < ui_type = "combo"; ui_label = "Color Mode"; ui_tooltip = "How the star spikes are colored.\nWhite: pure white glow.\nTint: custom color.\nPalette: from selected palette."; ui_items = "White\0Tint Color\0Palette\0"; ui_category = "Star Shape"; > = COLOR_MODE_WHITE;
uniform float3 TintColor < ui_type = "color"; ui_label = "Tint Color"; ui_tooltip = "Color of the star spikes when using Tint mode."; ui_category = "Star Shape"; > = float3(1.0, 0.95, 0.9);

// -- Palette & Style --
AS_PALETTE_SELECTION_UI(PalettePreset, "Star Palette", AS_PALETTE_RAINBOW, AS_CAT_PALETTE)
AS_DECLARE_CUSTOM_PALETTE(CrossStar_, AS_CAT_PALETTE)

// -- Animation --
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, AS_CAT_ANIMATION)

// -- Audio Reactivity --
AS_AUDIO_UI(CrossStar_AudioSource, "Audio Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(CrossStar_AudioMultiplier, "Audio Intensity", 1.0, 2.0, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(CrossStar_AudioTarget, "None\0Spike Intensity\0Spike Length\0Both\0", 0)

// -- Stage --
AS_STAGEDEPTH_UI(EffectDepth)

// -- Final Mix --
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// -- Debug --
AS_DEBUG_UI("Off\0Threshold Mask\0Spikes Only\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

namespace AS_CrossScreenStars {

    int getArmCount() {
        if (StarPoints == 0) return 2;
        if (StarPoints == 1) return 3;
        return 4;
    }

} // namespace AS_CrossScreenStars

// ============================================================================
// PIXEL SHADERS
// ============================================================================

// Pass 1: Isolate bright pixels
void PS_Threshold(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 outColor : SV_Target)
{
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float luma = dot(color, AS_LUMA_REC709);
    float mask = smoothstep(BrightnessThreshold - ThresholdKnee, BrightnessThreshold + ThresholdKnee, luma);
    outColor = float4(color * mask, mask);
}

// Pass 2: Accumulate star spikes and composite
float4 PS_StarSpikes(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);

    // Depth check
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth && DebugMode == 0) return originalColor;

    // Audio reactivity
    float audioMod = AS_audioModulate(1.0, CrossStar_AudioSource, CrossStar_AudioMultiplier, true, 0);
    float intensityFinal = SpikeIntensity;
    float lengthFinal = (float)SpikeLength;

    if (CrossStar_AudioTarget == 1 || CrossStar_AudioTarget == 3) intensityFinal *= audioMod;
    if (CrossStar_AudioTarget == 2 || CrossStar_AudioTarget == 3) lengthFinal *= audioMod;

    int armCount = AS_CrossScreenStars::getArmCount();
    float baseAngle = StarRotation * AS_DEGREES_TO_RADIANS;
    int nSteps = max(1, (int)floor(lengthFinal));

    float3 spikeAccum = float3(0.0, 0.0, 0.0);

    // For each arm direction, walk outward in both positive and negative directions
    for (int arm = 0; arm < 4; arm++)
    {
        if (arm >= armCount) break;

        float armAngle = baseAngle + AS_PI * (float)arm / (float)armCount;
        float2 direction = float2(cos(armAngle), sin(armAngle));
        float2 pixelDir = direction * ReShade::PixelSize;

        // Walk in positive direction
        for (int s = 1; s < MAX_SPIKE_SAMPLES; s++)
        {
            if (s > nSteps) break;
            float dist = (float)s / max(lengthFinal, 1.0);
            float weight = exp(-dist * SpikeFalloff * 3.0);
            float2 sampleUV = texcoord + pixelDir * (float)s * 2.0;
            float3 samp = tex2Dlod(CrossScreenStars_ThresholdSampler, float4(sampleUV, 0, 0)).rgb;
            spikeAccum += samp * weight;
        }

        // Walk in negative direction
        for (int sn = 1; sn < MAX_SPIKE_SAMPLES; sn++)
        {
            if (sn > nSteps) break;
            float dist = (float)sn / max(lengthFinal, 1.0);
            float weight = exp(-dist * SpikeFalloff * 3.0);
            float2 sampleUV = texcoord - pixelDir * (float)sn * 2.0;
            float3 samp = tex2Dlod(CrossScreenStars_ThresholdSampler, float4(sampleUV, 0, 0)).rgb;
            spikeAccum += samp * weight;
        }
    }

    // Normalize by arm count
    spikeAccum /= max((float)armCount * 2.0, 1.0);

    // Apply color mode
    float3 spikeColor;
    if (ColorMode == COLOR_MODE_TINT) {
        spikeColor = spikeAccum * TintColor;
    } else if (ColorMode == COLOR_MODE_PALETTE) {
        float t = saturate(dot(spikeAccum, AS_LUMA_REC709));
        float3 palColor;
        if (PalettePreset == AS_PALETTE_CUSTOM) {
            palColor = AS_GET_INTERPOLATED_CUSTOM_COLOR(CrossStar_, t);
        } else {
            palColor = AS_getInterpolatedColor(PalettePreset, t);
        }
        spikeColor = spikeAccum * palColor;
    } else {
        spikeColor = spikeAccum;
    }

    spikeColor *= intensityFinal;

    // Debug views
    if (DebugMode == 1) {
        float3 threshold = tex2D(CrossScreenStars_ThresholdSampler, texcoord).rgb;
        return float4(threshold, 1.0);
    }
    if (DebugMode == 2) return float4(spikeColor, 1.0);

    // Additive light
    float3 starScene = originalColor.rgb + spikeColor;
    float3 result = AS_composite(starScene, originalColor.rgb, BlendMode, BlendAmount);

    return float4(result, originalColor.a);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_VFX_CrossScreenStars
<
    ui_label = "[AS] VFX: Cross-Screen Stars";
    ui_tooltip = "Star-shaped diffraction spikes on bright highlights.\n"
                 "Simulates a cross-screen (star) camera filter.\n"
                 "Performance: Medium (2-pass, directional sampling)";
>
{
    pass Threshold
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Threshold;
        RenderTarget = CrossScreenStars_ThresholdBuffer;
    }
    pass StarSpikes
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_StarSpikes;
    }
}

#endif // __AS_VFX_CrossScreenStars_1_fx
