/**
 * AS_GFX_Y2KDigicam.1.fx - Early 2000s Digital Camera Simulation
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Simulates the look of early 2000s point-and-shoot digital cameras. Combines
 * multiple characteristic artifacts into a single compound effect: flash wash,
 * color cast, lifted blacks, highlight compression, sensor grain, chromatic
 * aberration, and vignetting.
 *
 * FEATURES:
 * - Adjustable flash wash with position control and warm falloff.
 * - Warm/cool/neutral color cast modes.
 * - Lifted blacks and subtle highlight compression for that digital look.
 * - Luminance-weighted film grain using procedural noise.
 * - Radial chromatic aberration at screen edges.
 * - Soft corner vignetting.
 * - Audio-reactive flash intensity or grain amount.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Apply warm flash wash based on distance from configurable flash position.
 * 2. Apply color cast (warm, cool green, or neutral) via channel multiplication.
 * 3. Lift black levels and compress highlights for reduced dynamic range.
 * 4. Add luminance-weighted procedural grain (shadows get more noise).
 * 5. Apply radial chromatic aberration at screen edges.
 * 6. Darken corners with distance-based vignette.
 * 7. Blend final result with configurable strength.
 *
 * ===================================================================================
 */

#ifndef __AS_GFX_Y2KDigicam_1_fx
#define __AS_GFX_Y2KDigicam_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Noise.1.fxh"

// ============================================================================
// NAMESPACE
// ============================================================================
namespace AS_Y2KDigicam {

// ============================================================================
// CONSTANTS
// ============================================================================
static const float STRENGTH_MIN = 0.0;
static const float STRENGTH_MAX = 1.0;
static const float STRENGTH_DEFAULT = 0.7;

static const float FLASH_MIN = 0.0;
static const float FLASH_MAX = 1.0;
static const float FLASH_DEFAULT = 0.3;

static const float GRAIN_MIN = 0.0;
static const float GRAIN_MAX = 0.5;
static const float GRAIN_DEFAULT = 0.15;

static const float BLACKLIFT_MIN = 0.0;
static const float BLACKLIFT_MAX = 0.15;
static const float BLACKLIFT_DEFAULT = 0.05;

static const float CHROMATIC_MIN = 0.0;
static const float CHROMATIC_MAX = 0.005;
static const float CHROMATIC_DEFAULT = 0.002;

static const float VIGNETTE_MIN = 0.0;
static const float VIGNETTE_MAX = 1.0;
static const float VIGNETTE_DEFAULT = 0.3;

static const float FLASH_RADIUS_MIN = 0.1;
static const float FLASH_RADIUS_MAX = 1.5;
static const float FLASH_RADIUS_DEFAULT = 0.6;

static const float3 FLASH_WARM_TINT = float3(1.0, 0.95, 0.85);
static const float3 CAST_WARM = float3(1.05, 1.0, 0.9);
static const float3 CAST_COOL = float3(0.9, 1.02, 1.0);
static const float HIGHLIGHT_COMPRESS_EXP = 1.1;

static const int CAST_MODE_WARM = 0;
static const int CAST_MODE_COOL = 1;
static const int CAST_MODE_NEUTRAL = 2;

// ============================================================================
// UNIFORMS
// ============================================================================

// --- Effect Strength ---

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform float EffectStrength < ui_type = "slider"; ui_label = "Effect Strength"; ui_tooltip = "Overall strength of the digicam effect."; ui_min = STRENGTH_MIN; ui_max = STRENGTH_MAX; ui_step = 0.01; ui_category = "Effect"; > = STRENGTH_DEFAULT;

// --- Flash ---
uniform float FlashIntensity < ui_type = "slider"; ui_label = "Flash Intensity"; ui_tooltip = "Brightness of the simulated camera flash wash."; ui_min = FLASH_MIN; ui_max = FLASH_MAX; ui_step = 0.01; ui_category = "Flash"; > = FLASH_DEFAULT;
uniform float2 FlashPosition < ui_type = "drag"; ui_label = "Flash Position"; ui_tooltip = "Screen position of the flash center (X, Y)."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Flash"; > = float2(0.5, 0.35);
uniform float FlashRadius < ui_type = "slider"; ui_label = "Flash Radius"; ui_tooltip = "How wide the flash wash extends."; ui_min = FLASH_RADIUS_MIN; ui_max = FLASH_RADIUS_MAX; ui_step = 0.01; ui_category = "Flash"; > = FLASH_RADIUS_DEFAULT;

// --- Color Cast ---
uniform int CastMode < ui_type = "combo"; ui_label = "Color Cast"; ui_tooltip = "Simulated white balance error from early digital sensors."; ui_items = "Warm\0Cool Green\0Neutral\0"; ui_category = "Color"; > = CAST_MODE_WARM;

// --- Grain ---
uniform float GrainAmount < ui_type = "slider"; ui_label = "Grain Amount"; ui_tooltip = "Amount of sensor grain. More visible in dark areas."; ui_min = GRAIN_MIN; ui_max = GRAIN_MAX; ui_step = 0.01; ui_category = "Grain"; > = GRAIN_DEFAULT;

// --- Black Lift ---
uniform float BlackLift < ui_type = "slider"; ui_label = "Black Lift"; ui_tooltip = "Raises the minimum brightness, simulating poor contrast of early sensors."; ui_min = BLACKLIFT_MIN; ui_max = BLACKLIFT_MAX; ui_step = 0.005; ui_category = "Tone"; > = BLACKLIFT_DEFAULT;

// --- Chromatic Aberration ---
uniform float ChromaticShift < ui_type = "slider"; ui_label = "Chromatic Shift"; ui_tooltip = "Amount of color fringing at the screen edges."; ui_min = CHROMATIC_MIN; ui_max = CHROMATIC_MAX; ui_step = 0.0001; ui_category = "Lens"; > = CHROMATIC_DEFAULT;

// --- Vignette ---
uniform float VignetteStrength < ui_type = "slider"; ui_label = "Vignette Strength"; ui_tooltip = "Darkening at screen corners."; ui_min = VIGNETTE_MIN; ui_max = VIGNETTE_MAX; ui_step = 0.01; ui_category = "Lens"; > = VIGNETTE_DEFAULT;

// ============================================================================
// AUDIO REACTIVITY
// ============================================================================
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_BEAT, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(AudioMultiplier, "Audio Intensity", 0.5, 2.0, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(AudioTarget, "None\0Flash Intensity\0Grain Amount\0", 0)

// ============================================================================
// FINAL MIX
// ============================================================================
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// ============================================================================
// DEBUG
// ============================================================================
AS_DEBUG_UI("Off\0Flash Mask\0Grain Only\0Before-After\0")

// ============================================================================
// PIXEL SHADER
// ============================================================================

float4 Y2KDigicamPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float3 originalColor = tex2D(ReShade::BackBuffer, texcoord).rgb;

    // --- Audio modulation ---
    float flashMod = FlashIntensity;
    float grainMod = GrainAmount;
    if (AudioTarget == 1)
    {
        flashMod = AS_audioModulate(FlashIntensity, AudioSource, AudioMultiplier, true, 0);
    }
    else if (AudioTarget == 2)
    {
        grainMod = AS_audioModulate(GrainAmount, AudioSource, AudioMultiplier, true, 0);
    }

    float3 color = originalColor;

    // --- 1. Flash wash ---
    float2 flashDelta = texcoord - FlashPosition;
    flashDelta.x *= ReShade::AspectRatio;
    float dist = length(flashDelta);
    float flashContrib = smoothstep(FlashRadius, 0.0, dist) * flashMod;
    color += flashContrib * FLASH_WARM_TINT;

    // Debug: flash mask
    if (DebugMode == 1) return float4(flashContrib.xxx, 1.0);

    // --- 2. Color cast ---
    if (CastMode == CAST_MODE_WARM)
    {
        color *= CAST_WARM;
    }
    else if (CastMode == CAST_MODE_COOL)
    {
        color *= CAST_COOL;
    }
    // Neutral: no modification

    // --- 3. Lift blacks ---
    color = color * (1.0 - BlackLift) + BlackLift;

    // --- 4. Compress highlights ---
    color = 1.0 - pow(1.0 - saturate(color), HIGHLIGHT_COMPRESS_EXP);

    // --- 5. Grain ---
    float time = AS_timeSeconds();
    float noise = AS_hash21(texcoord * 1000.0 + frac(time));
    float luminance = dot(color, AS_LUMA_REC709);
    float grainWeight = (1.0 - luminance);
    float grain = (noise - 0.5) * grainMod * grainWeight;
    color += grain;

    // Debug: grain only
    if (DebugMode == 2) return float4((grain + 0.5).xxx, 1.0);

    // --- 6. Chromatic aberration ---
    if (ChromaticShift > AS_EPSILON)
    {
        float2 dir = texcoord - 0.5;
        float edgeDist = length(dir);
        float2 shift = normalize(dir + AS_EPSILON) * ChromaticShift * edgeDist;
        color.r = tex2D(ReShade::BackBuffer, texcoord + shift).r;
        color.b = tex2D(ReShade::BackBuffer, texcoord - shift).b;
        // Re-apply flash, cast, lift, compress, grain to R and B channels
        // For performance, only apply the flash and cast approximation
        float flashR = smoothstep(FlashRadius, 0.0, length((texcoord + shift - FlashPosition) * float2(ReShade::AspectRatio, 1.0))) * flashMod;
        float flashB = smoothstep(FlashRadius, 0.0, length((texcoord - shift - FlashPosition) * float2(ReShade::AspectRatio, 1.0))) * flashMod;
        color.r += flashR * FLASH_WARM_TINT.r;
        color.b += flashB * FLASH_WARM_TINT.b;
        if (CastMode == CAST_MODE_WARM)
        {
            color.r *= CAST_WARM.r;
            color.b *= CAST_WARM.b;
        }
        else if (CastMode == CAST_MODE_COOL)
        {
            color.r *= CAST_COOL.r;
            color.b *= CAST_COOL.b;
        }
        color.r = color.r * (1.0 - BlackLift) + BlackLift;
        color.b = color.b * (1.0 - BlackLift) + BlackLift;
        color.r = 1.0 - pow(1.0 - saturate(color.r), HIGHLIGHT_COMPRESS_EXP);
        color.b = 1.0 - pow(1.0 - saturate(color.b), HIGHLIGHT_COMPRESS_EXP);
    }

    // --- 7. Vignette ---
    float2 vigUV = texcoord - 0.5;
    float vigDist = dot(vigUV, vigUV);
    float vignette = 1.0 - vigDist * VignetteStrength * 2.0;
    color *= saturate(vignette);

    color = saturate(color);

    // Debug: before-after split
    if (DebugMode == 3 && texcoord.x < 0.5) return float4(originalColor, 1.0);

    // --- Final blend with effect strength ---
    float3 result = lerp(originalColor, color, EffectStrength);
    result = AS_composite(result, originalColor, BlendMode, BlendAmount);

    return float4(result, 1.0);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
} // namespace AS_Y2KDigicam

technique AS_GFX_Y2KDigicam <
    ui_label = "[AS] GFX: Y2K Digicam";
    ui_tooltip = "Early 2000s point-and-shoot digital camera simulation.\n"
                 "Flash wash, color cast, grain, chromatic aberration, and vignette.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = AS_Y2KDigicam::Y2KDigicamPS;
    }
}

#endif // __AS_GFX_Y2KDigicam_1_fx
