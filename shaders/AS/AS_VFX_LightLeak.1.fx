/**
 * AS_VFX_LightLeak.1.fx - Procedural Film Light Leak Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Simulates light leaking into a film camera body — organic, warm blobs of light
 * that drift slowly across the frame. Creates the accidental beauty of analog
 * photography where light seeps through gaps in the camera housing.
 *
 * FEATURES:
 * - Multiple layered light leak blobs with independent drift and scale
 * - Color via palette system, tint, or warm analog film defaults
 * - Adjustable leak intensity, size, softness, and coverage
 * - Animated drift with controllable speed and direction
 * - Audio-reactive intensity and movement
 * - Depth-aware: optionally only affects background
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Generate 3 independent smooth gradient blobs using layered cosine waves
 *    with offset phases to create organic, non-repeating shapes.
 * 2. Position each blob with animated drift using sine-based movement paths.
 * 3. Color each blob from the palette/tint system.
 * 4. Composite all blobs additively onto the scene (light only adds, never darkens).
 *
 * ===================================================================================
 */

#ifndef __AS_VFX_LightLeak_1_fx
#define __AS_VFX_LightLeak_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================

static const float LEAK_INTENSITY_MIN = 0.0;
static const float LEAK_INTENSITY_MAX = 1.0;
static const float LEAK_INTENSITY_STEP = 0.01;
static const float LEAK_INTENSITY_DEFAULT = 0.35;

static const float LEAK_SIZE_MIN = 0.1;
static const float LEAK_SIZE_MAX = 2.0;
static const float LEAK_SIZE_STEP = 0.01;
static const float LEAK_SIZE_DEFAULT = 0.8;

static const float LEAK_SOFTNESS_MIN = 0.1;
static const float LEAK_SOFTNESS_MAX = 3.0;
static const float LEAK_SOFTNESS_STEP = 0.05;
static const float LEAK_SOFTNESS_DEFAULT = 1.5;

static const float DRIFT_SPEED_MIN = 0.0;
static const float DRIFT_SPEED_MAX = 2.0;
static const float DRIFT_SPEED_STEP = 0.01;
static const float DRIFT_SPEED_DEFAULT = 0.3;

static const float COVERAGE_MIN = 0.0;
static const float COVERAGE_MAX = 1.0;
static const float COVERAGE_STEP = 0.01;
static const float COVERAGE_DEFAULT = 0.5;

static const float WARMTH_MIN = 0.0;
static const float WARMTH_MAX = 1.0;
static const float WARMTH_STEP = 0.01;
static const float WARMTH_DEFAULT = 0.6;

static const int COLOR_MODE_WARM_FILM = 0;
static const int COLOR_MODE_TINT = 1;
static const int COLOR_MODE_PALETTE = 2;

// Blob generation constants
static const int NUM_LEAK_BLOBS = 3;
static const float BLOB_PHASE_OFFSET = 2.094395; // 2*PI/3 — evenly spaced phases

// ============================================================================
// SHADER DESCRIPTOR
// ============================================================================

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// -- Leak Appearance --

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform float LeakIntensity < ui_type = "slider"; ui_label = "Intensity"; ui_tooltip = "Overall brightness of the light leaks.\nHigher values create more prominent, visible leaks."; ui_min = LEAK_INTENSITY_MIN; ui_max = LEAK_INTENSITY_MAX; ui_step = LEAK_INTENSITY_STEP; ui_category = "Leak Appearance"; > = LEAK_INTENSITY_DEFAULT;
uniform float LeakSize < ui_type = "slider"; ui_label = "Size"; ui_tooltip = "Scale of the light leak blobs.\nLarger values create broad, sweeping leaks. Smaller values create tighter spots."; ui_min = LEAK_SIZE_MIN; ui_max = LEAK_SIZE_MAX; ui_step = LEAK_SIZE_STEP; ui_category = "Leak Appearance"; > = LEAK_SIZE_DEFAULT;
uniform float LeakSoftness < ui_type = "slider"; ui_label = "Softness"; ui_tooltip = "How soft and diffused the leak edges are.\nHigher = dreamy, hazy blobs. Lower = more defined shapes."; ui_min = LEAK_SOFTNESS_MIN; ui_max = LEAK_SOFTNESS_MAX; ui_step = LEAK_SOFTNESS_STEP; ui_category = "Leak Appearance"; > = LEAK_SOFTNESS_DEFAULT;
uniform float LeakCoverage < ui_type = "slider"; ui_label = "Coverage"; ui_tooltip = "How much of the frame the leaks cover.\n0.0 = leaks barely visible, 1.0 = leaks fill most of the frame."; ui_min = COVERAGE_MIN; ui_max = COVERAGE_MAX; ui_step = COVERAGE_STEP; ui_category = "Leak Appearance"; > = COVERAGE_DEFAULT;

// -- Leak Color --
uniform int LeakColorMode < ui_type = "combo"; ui_label = "Color Mode"; ui_tooltip = "How leak color is determined.\nWarm Film: classic amber/orange/red analog leak.\nTint: fixed color you choose.\nPalette: maps leak color from the selected palette."; ui_items = "Warm Film\0Tint Color\0Palette\0"; ui_category = "Leak Appearance"; > = COLOR_MODE_WARM_FILM;
uniform float3 LeakTintColor < ui_type = "color"; ui_label = "Tint Color"; ui_tooltip = "Fixed leak color when Tint mode is active."; ui_category = "Leak Appearance"; > = float3(1.0, 0.6, 0.2);
uniform float LeakWarmth < ui_type = "slider"; ui_label = "Film Warmth"; ui_tooltip = "Color temperature of the Warm Film mode.\n0.0 = pale yellow, 0.5 = warm orange, 1.0 = deep red."; ui_min = WARMTH_MIN; ui_max = WARMTH_MAX; ui_step = WARMTH_STEP; ui_category = "Leak Appearance"; > = WARMTH_DEFAULT;

// -- Palette & Style --
AS_PALETTE_SELECTION_UI(PalettePreset, "Leak Palette", AS_PALETTE_FIRE, AS_CAT_PALETTE)
AS_DECLARE_CUSTOM_PALETTE(LightLeak_, AS_CAT_PALETTE)

// -- Animation --
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, AS_CAT_ANIMATION)
uniform float DriftSpeed < ui_type = "slider"; ui_label = "Drift Speed"; ui_tooltip = "How fast the light leaks drift across the frame.\n0.0 = static leaks, higher = faster movement."; ui_min = DRIFT_SPEED_MIN; ui_max = DRIFT_SPEED_MAX; ui_step = DRIFT_SPEED_STEP; ui_category = AS_CAT_ANIMATION; > = DRIFT_SPEED_DEFAULT;

// -- Audio Reactivity --
AS_AUDIO_UI(LightLeak_AudioSource, "Audio Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(LightLeak_AudioMultiplier, "Audio Intensity", 1.0, 2.0, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(LightLeak_AudioTarget, "None\0Intensity\0Drift Speed\0Size\0All\0", 0)

// -- Stage --
AS_STAGEDEPTH_UI(EffectDepth)

// -- Final Mix --
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// -- Debug --
AS_DEBUG_UI("Off\0Leak Mask\0Leak Color\0Individual Blobs\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

namespace AS_LightLeak {

    // Warm film color based on warmth parameter (0=pale yellow, 0.5=orange, 1=deep red)
    float3 getWarmFilmColor(float warmth, float blobPhase) {
        // Each blob gets a slightly different warmth for natural variation
        float w = saturate(warmth + sin(blobPhase * 3.7) * 0.15);
        float3 pale = float3(1.0, 0.95, 0.7);    // Pale warm yellow
        float3 amber = float3(1.0, 0.55, 0.15);   // Warm amber/orange
        float3 deep = float3(0.9, 0.2, 0.05);     // Deep red
        // Two-stage interpolation: pale→amber→deep
        if (w < 0.5) {
            return lerp(pale, amber, w * 2.0);
        }
        return lerp(amber, deep, (w - 0.5) * 2.0);
    }

    // Generate a single organic blob mask
    // Uses layered cosine waves for smooth, non-circular organic shapes
    float generateBlob(float2 uv, float2 center, float size, float softness, float time, float phase) {
        float2 offset = uv - center;
        // Aspect-correct so blobs are circular, not stretched
        offset.x *= ReShade::AspectRatio;

        float dist = length(offset);

        // Organic shape distortion: layer cosine waves at different frequencies
        float angle = atan2(offset.y, offset.x);
        float shapeWarp = 0.0;
        shapeWarp += 0.15 * cos(angle * 2.0 + time * 0.7 + phase);
        shapeWarp += 0.10 * cos(angle * 3.0 - time * 0.5 + phase * 1.3);
        shapeWarp += 0.05 * cos(angle * 5.0 + time * 0.3 + phase * 2.1);

        // Apply shape distortion to the distance
        float warpedDist = dist - shapeWarp * size * 0.3;

        // Smooth falloff from center
        float blob = 1.0 - smoothstep(0.0, size * softness, warpedDist);

        // Apply a soft power curve for more natural fade
        return blob * blob;
    }

    // Animated drift position for a blob
    float2 getDriftPosition(float time, float phase, float speed) {
        // Lissajous-like drift path — each blob follows a different curved path
        float2 drift;
        drift.x = sin(time * speed * 0.41 + phase * 2.1) * 0.4
                + sin(time * speed * 0.67 + phase * 0.8) * 0.2;
        drift.y = cos(time * speed * 0.53 + phase * 1.5) * 0.3
                + cos(time * speed * 0.31 + phase * 2.7) * 0.15;
        return drift;
    }

} // namespace AS_LightLeak

// ============================================================================
// PIXEL SHADER
// ============================================================================

float4 PS_LightLeak(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);

    // Depth check
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth) {
        if (DebugMode == 0) return originalColor;
    }

    // Audio reactivity
    float audioMod = AS_audioModulate(1.0, LightLeak_AudioSource, LightLeak_AudioMultiplier, true, 0);
    float intensityFinal = LeakIntensity;
    float driftSpeedFinal = DriftSpeed;
    float sizeFinal = LeakSize;

    if (LightLeak_AudioTarget == 1 || LightLeak_AudioTarget == 4) intensityFinal *= audioMod;
    if (LightLeak_AudioTarget == 2 || LightLeak_AudioTarget == 4) driftSpeedFinal *= audioMod;
    if (LightLeak_AudioTarget == 3 || LightLeak_AudioTarget == 4) sizeFinal *= audioMod;

    float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);

    // Generate and accumulate leak blobs
    float totalMask = 0.0;
    float3 totalColor = float3(0.0, 0.0, 0.0);

    for (int i = 0; i < NUM_LEAK_BLOBS; i++)
    {
        float phase = (float)i * BLOB_PHASE_OFFSET;

        // Each blob drifts along its own Lissajous path
        float2 blobCenter = float2(0.5, 0.5) + AS_LightLeak::getDriftPosition(time, phase, driftSpeedFinal);

        // Coverage shifts the blob centers outward (low coverage = edge leaks, high = center leaks)
        float2 edgeBias = float2(
            sign(blobCenter.x - 0.5) * (1.0 - LeakCoverage) * 0.3,
            sign(blobCenter.y - 0.5) * (1.0 - LeakCoverage) * 0.2
        );
        blobCenter += edgeBias;

        // Generate the organic blob shape
        float blobMask = AS_LightLeak::generateBlob(texcoord, blobCenter, sizeFinal, LeakSoftness, time, phase);

        // Get color for this blob
        float3 blobColor;
        if (LeakColorMode == COLOR_MODE_TINT) {
            blobColor = LeakTintColor;
        } else if (LeakColorMode == COLOR_MODE_PALETTE) {
            // Map each blob to a different position in the palette
            float t = frac((float)i / (float)NUM_LEAK_BLOBS + time * 0.03);
            if (PalettePreset == AS_PALETTE_CUSTOM) {
                blobColor = AS_GET_INTERPOLATED_CUSTOM_COLOR(LightLeak_, t);
            } else {
                blobColor = AS_getInterpolatedColor(PalettePreset, t);
            }
        } else {
            // Warm Film: each blob gets a slightly different warm tone
            blobColor = AS_LightLeak::getWarmFilmColor(LeakWarmth, phase);
        }

        totalMask += blobMask;
        totalColor += blobColor * blobMask;
    }

    // Normalize color by total mask (where blobs overlap, blend colors)
    float3 leakColor = totalColor / max(totalMask, AS_EPSILON);
    float leakMask = saturate(totalMask);

    // Debug views
    if (DebugMode == 1) return float4(leakMask.xxx, 1.0);
    if (DebugMode == 2) return float4(leakColor * leakMask, 1.0);
    if (DebugMode == 3) {
        // Show individual blobs in R, G, B channels
        float r = AS_LightLeak::generateBlob(texcoord,
            float2(0.5, 0.5) + AS_LightLeak::getDriftPosition(time, 0.0, driftSpeedFinal),
            sizeFinal, LeakSoftness, time, 0.0);
        float g = AS_LightLeak::generateBlob(texcoord,
            float2(0.5, 0.5) + AS_LightLeak::getDriftPosition(time, BLOB_PHASE_OFFSET, driftSpeedFinal),
            sizeFinal, LeakSoftness, time, BLOB_PHASE_OFFSET);
        float b = AS_LightLeak::generateBlob(texcoord,
            float2(0.5, 0.5) + AS_LightLeak::getDriftPosition(time, BLOB_PHASE_OFFSET * 2.0, driftSpeedFinal),
            sizeFinal, LeakSoftness, time, BLOB_PHASE_OFFSET * 2.0);
        return float4(r, g, b, 1.0);
    }

    // Additive light: leaks only ADD brightness, never darken
    float3 leakLight = leakColor * leakMask * intensityFinal;
    float3 leakedScene = originalColor.rgb + leakLight;

    // User's BlendMode/BlendAmount for final mix
    float3 result = AS_composite(leakedScene, originalColor.rgb, BlendMode, BlendAmount);

    return float4(result, originalColor.a);
}

// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_VFX_LightLeak
<
    ui_label = "[AS] VFX: Light Leak";
    ui_tooltip = "Organic warm light blobs drifting across the frame.\n"
                 "Simulates light leaking into an analog film camera.\n"
                 "Performance: Light (single-pass procedural)";
>
{
    pass Main
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_LightLeak;
    }
}

#endif // __AS_VFX_LightLeak_1_fx
