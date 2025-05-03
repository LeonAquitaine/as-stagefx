// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_LFX_CandleFlame_1_fx
#define __AS_LFX_CandleFlame_1_fx

/**
 * AS_LFX_CandleFlame.1.fx - Procedural Candle Flame Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Generates an animated procedural candle flame effect, rendered as if existing
 * on a specific depth plane in the scene. Uses trigonometric UV distortion and
 * dynamic shape functions for a realistic fire appearance.
 * 
 * FEATURES:
 * - Procedural shape, color gradient with customizable color palette
 * - Renders at a specific depth layer (occluded by closer objects)
 * - Extensive control over shape, color, animation speed, sway, and flicker
 * - Audio reactivity for dynamic flame intensity and movement
 * - Resolution-independent rendering maintains consistent size across all displays
 * 
 * IMPLEMENTATION OVERVIEW:
 * 1. Calculates distorted UVs using trigonometric functions
 * 2. Generates flame shape using power functions and gradients
 * 3. Applies color mapping based on vertical position
 * 4. Adds noise-based flicker and audio reactivity
 * 5. Renders at specified depth plane with occlusion
 * 
 * ===================================================================================
 */

 // ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh" // Standard ReShade functions and uniforms
#include "AS_Utils.1.fxh"  // Always include for utilities and audio reactivity
#include "AS_Palettes.1.fxh" // For color palette support

// ============================================================================
// POSITION
// ============================================================================
uniform float2 FlameScreenPos < ui_type = "drag"; ui_label = "Flame Position"; ui_tooltip = "Screen position (0-1) for the base of the flame. Drag to position."; ui_category = "Position"; > = float2(0.5, 0.5); // Center of the screen

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
static const float FLAME_HEIGHT_MIN = 0.01;
static const float FLAME_HEIGHT_MAX = 0.5;
static const float FLAME_HEIGHT_DEFAULT = 0.2;

static const float FLAME_WIDTH_MIN = 0.01;
static const float FLAME_WIDTH_MAX = 0.2;
static const float FLAME_WIDTH_DEFAULT = 0.05;

static const float FLAME_CURVE_MIN = 0.1;
static const float FLAME_CURVE_MAX = 4.0;
static const float FLAME_CURVE_DEFAULT = 0.7;

static const float FLAME_SHARPNESS_MIN = 0.5;
static const float FLAME_SHARPNESS_MAX = 5.0;
static const float FLAME_SHARPNESS_DEFAULT = 1.0;

static const float FLAME_POWER_MIN = 0.0;
static const float FLAME_POWER_MAX = 1.0;
static const float FLAME_POWER_DEFAULT = 0.7;

static const float FLAME_BOTTOM_HEIGHT_MIN = 0.0;
static const float FLAME_BOTTOM_HEIGHT_MAX = 1.0;
static const float FLAME_BOTTOM_HEIGHT_DEFAULT = 0.26;

static const float FLAME_GRADIENT_MIN = 0.1;
static const float FLAME_GRADIENT_MAX = 10.0;
static const float FLAME_GRADIENT_DEFAULT = 4.0;

static const float FLAME_RED_BRIGHTNESS_MIN = 0.0;
static const float FLAME_RED_BRIGHTNESS_MAX = 10.0;
static const float FLAME_RED_BRIGHTNESS_DEFAULT = 1.0;

static const float NOISE_SCALE_MIN = 1.0;
static const float NOISE_SCALE_MAX = 50.0;
static const float NOISE_SCALE_DEFAULT = 15.0;

// ============================================================================
// PALETTE & STYLE
// ============================================================================
// Using standardized AS_Utils palette selection
AS_PALETTE_SELECTION_UI(PalettePreset, "Palette", AS_PALETTE_FIRE, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(CandleFlame_, "Palette & Style")

uniform float ColorCycleSpeed < ui_type = "slider"; ui_label = "Color Cycle Speed"; ui_tooltip = "Controls how fast flame colors cycle. 0 = static"; ui_min = -5.0; ui_max = 5.0; ui_step = 0.1; ui_category = "Palette & Style"; > = 0.0;

// ============================================================================
// FLAME APPEARANCE
// ============================================================================
uniform float FlameHeight < ui_type = "slider"; ui_min = FLAME_HEIGHT_MIN; ui_max = FLAME_HEIGHT_MAX; ui_label = "Height"; ui_tooltip = "Overall height scale of the flame."; ui_category = "Flame Appearance"; > = FLAME_HEIGHT_DEFAULT;
uniform float FlameWidth < ui_type = "slider"; ui_min = FLAME_WIDTH_MIN; ui_max = FLAME_WIDTH_MAX; ui_label = "Width"; ui_tooltip = "Overall width scale of the flame."; ui_category = "Flame Appearance"; > = FLAME_WIDTH_DEFAULT;
uniform float FlameCurve < ui_type = "slider"; ui_min = FLAME_CURVE_MIN; ui_max = FLAME_CURVE_MAX; ui_step = 0.05; ui_label = "Tip Shape"; ui_tooltip = "Controls the flame tip shape (0.5=round, >1=pointy)."; ui_category = "Flame Appearance"; > = FLAME_CURVE_DEFAULT;
uniform float FlameSharpness < ui_type = "slider"; ui_min = FLAME_SHARPNESS_MIN; ui_max = FLAME_SHARPNESS_MAX; ui_step = 0.05; ui_label = "Edge Sharpness"; ui_tooltip = "Controls the horizontal edge sharpness/thickness."; ui_category = "Flame Appearance"; > = FLAME_SHARPNESS_DEFAULT;
uniform float FlamePower < ui_type = "slider"; ui_min = FLAME_POWER_MIN; ui_max = FLAME_POWER_MAX; ui_step = 0.01; ui_label = "Brightness"; ui_tooltip = "Overall brightness / intensity multiplier."; ui_category = "Flame Appearance"; > = FLAME_POWER_DEFAULT;
uniform float FlameBottomHeight < ui_type = "slider"; ui_min = FLAME_BOTTOM_HEIGHT_MIN; ui_max = FLAME_BOTTOM_HEIGHT_MAX; ui_step = 0.01; ui_label = "Base Height"; ui_tooltip = "Relative height of flame base. Affects bottom fade."; ui_category = "Flame Appearance"; > = FLAME_BOTTOM_HEIGHT_DEFAULT;
uniform float FlameGradientSteepness < ui_type = "slider"; ui_min = FLAME_GRADIENT_MIN; ui_max = FLAME_GRADIENT_MAX; ui_step = 0.01; ui_label = "Color Transition"; ui_tooltip = "How sharply colors transition along the flame height."; ui_category = "Flame Appearance"; > = FLAME_GRADIENT_DEFAULT;
uniform float FlameRedBrightness < ui_type = "slider"; ui_min = FLAME_RED_BRIGHTNESS_MIN; ui_max = FLAME_RED_BRIGHTNESS_MAX; ui_step = 0.01; ui_label = "Red Glow"; ui_tooltip = "Adds brightness based on red channel (creates bloom effect)."; ui_category = "Flame Appearance"; > = FLAME_RED_BRIGHTNESS_DEFAULT;

// ============================================================================
// ANIMATION
// ============================================================================
AS_SWAYSPEED_UI(SwaySpeed, "Animation")
AS_SWAYANGLE_UI(SwayAngle, "Animation")
uniform float HorizontalSpeed < ui_type = "slider"; ui_min = 0.0; ui_max = 5.0; ui_step = 0.01; ui_label = "Horizontal Noise Speed"; ui_tooltip = "Speed of side-to-side movement."; ui_category = "Animation"; > = 0.1;
uniform float HorizontalSway < ui_type = "slider"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_label = "Horizontal Sway Amount"; ui_tooltip = "Amplitude of side-to-side movement."; ui_category = "Animation"; > = 0.1;
uniform float VerticalSpeed < ui_type = "slider"; ui_min = 0.0; ui_max = 5.0; ui_step = 0.01; ui_label = "Vertical Noise Speed"; ui_tooltip = "Speed of upward 'licking' / vertical distortion."; ui_category = "Animation"; > = 0.4;
uniform float IntensityFlickerSpeed < ui_type = "slider"; ui_min = 0.0; ui_max = 100.0; ui_step = 0.1; ui_label = "Intensity Flicker Speed"; ui_tooltip = "Speed of the brightness flickering effect."; ui_category = "Animation"; > = 60.0;
uniform float NoiseScale < ui_type = "slider"; ui_min = NOISE_SCALE_MIN; ui_max = NOISE_SCALE_MAX; ui_label = "Noise Scale (for Intensity Flicker)"; ui_tooltip = "Spatial frequency of the noise used for intensity flicker."; ui_category = "Animation"; > = NOISE_SCALE_DEFAULT;

// ============================================================================
// AUDIO REACTIVITY
// ============================================================================
AS_AUDIO_SOURCE_UI(Flame_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(Flame_AudioMultiplier, "Intensity", 1.0, 2.0, "Audio Reactivity")

// Audio target selector
uniform int AudioTarget < 
    ui_type = "combo";
    ui_label = "Audio Target Parameter";
    ui_tooltip = "Select which parameter will be affected by audio reactivity";
    ui_items = "Flame Height\0Flame Power\0Sway Angle\0All Parameters\0";
    ui_category = "Audio Reactivity";
> = 0; // Default to Flame Height

// ============================================================================
// STAGE DISTANCE
// ============================================================================
AS_STAGEDEPTH_UI(StageDepth, "Distance", "Stage Distance")

// ============================================================================
// FINAL MIX
// ============================================================================
AS_BLENDMODE_UI_DEFAULT(BlendMode, "Final Mix", 3) // Default to Additive for fire
AS_BLENDAMOUNT_UI(BlendAmount, "Final Mix")

// ============================================================================
// DEBUG
// ============================================================================
AS_DEBUG_MODE_UI("Off\0Shape\0Audio\0Color\0")

// ============================================================================
// NAMESPACE & HELPERS
// ============================================================================
namespace AS_CandleFlame {

// --- Improved Noise Functions ---
// Better hash function for noise
float hash(float2 p) {
    p = 50.0 * frac(p * 0.3183099 + float2(0.71, 0.113));
    return -1.0 + 2.0 * frac(p.x * p.y * (p.x + p.y));
}

// Improved Perlin-like noise
float noise(float2 p) {
    float2 i = floor(p);
    float2 f = frac(p);
    
    // Quintic interpolation
    float2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    
    // Hash values at the corners of the cell
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));
    
    // Blend values using the interpolation factor
    return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
}

// fbm (fractal Brownian motion) for better fire noise
float fbm(float2 p, float time) {
    float f = 0.0;
    float w = 0.5;
    for (int i = 0; i < 5; i++) {
        f += w * noise(p);
        p *= 2.0;
        p += time; // Add time for animation
        w *= 0.5;
    }
    return f;
}

// Get color from the currently selected palette
float3 getCandleFlameColor(float t, float time) {
    // Apply time-based color cycling if enabled
    if (ColorCycleSpeed != 0.0) {
        float cycleRate = ColorCycleSpeed * 0.1;
        t = frac(t + cycleRate * time);
    }
    
    // Return the color from the selected palette
    if (PalettePreset == AS_PALETTE_COUNT) {
        return AS_GET_INTERPOLATED_CUSTOM_COLOR(CandleFlame_, t);
    }
    return AS_getInterpolatedColor(PalettePreset, t);
}

// Distort UVs for flame animation - revised to anchor flame at base
float2 distortUVs(float2 uv, float timer) {
    // Apply audio reactivity for flame movement
    float audioFactor = AS_applyAudioReactivity(1.0, Flame_AudioSource, Flame_AudioMultiplier, true);
    
    // Calculate vertical falloff factor - movement increases away from base (y=0)
    // This creates a more realistic flame movement anchored at the base
    float verticalFalloff = uv.y * uv.y; // Quadratic falloff (more movement at tip)
    
    // Fluctuation factor based on sin/cos waves
    float fluctuation = (sin(timer * HorizontalSpeed - uv.y) + cos((timer * HorizontalSpeed - uv.y) * 0.01));

    // Horizontal distortion (sway), stronger near the tip (uv.y = 1) and minimal at base
    uv.x += sin(timer * HorizontalSpeed) * fluctuation * HorizontalSway * 0.1 * audioFactor * verticalFalloff;

    // Get standard sway animation
    float sway = AS_applySway(SwayAngle, SwaySpeed);
    // Apply sway animation with vertical falloff (minimal at base, maximum at tip)
    // Increase the multiplier from 0.01 to 0.05 to make sway more noticeable
    uv.x += sway * 0.05 * audioFactor * verticalFalloff;

    // Vertical distortion (flicker/jump) using frac(sin()) for sharp changes
    // Also increases from base to tip
    uv.y += frac(sin(timer * IntensityFlickerSpeed)) * VerticalSpeed * 0.1 * audioFactor * verticalFalloff;

    return uv;
}

// Calculate flame shape and color
float4 proceduralFlame(float2 rel_uv, float timer) {
    // Fix for upside-down flame: invert the Y coordinate
    rel_uv.y = 1.0 - rel_uv.y;
    
    // 1. Apply UV Distortion
    float2 distorted_uv = distortUVs(rel_uv, timer);

    // --- 2. Shape Calculation ---
    // Calculate flame width profile based on vertical position
    float width_at_y = pow(saturate(1.0 - distorted_uv.y), FlameCurve);

    // Calculate normalized horizontal distance relative to the width at this height
    float h_dist_norm = abs(distorted_uv.x * 2.0) / (width_at_y + 1e-6);
    float sharp_h_dist_norm = h_dist_norm * FlameSharpness;

    // Create the main shape mask based on sharpened horizontal distance
    float shape_mask = smoothstep(1.0, 0.8, sharp_h_dist_norm);

    // Apply vertical fade near the tip for a softer point
    shape_mask *= smoothstep(1.05, 0.9, distorted_uv.y);

    // Apply fade near the very bottom for a softer/darker base
    float bottom_fade_mask = smoothstep(0.0, FlameBottomHeight * 0.5, distorted_uv.y);
    shape_mask *= bottom_fade_mask;

    // Final mask value after shaping and fading
    float final_mask = shape_mask;

    // Early exit if calculated mask is zero (pixel is outside the flame)
    if (final_mask <= 0.0) return float4(0.0, 0.0, 0.0, 0.0);

    // --- 3. Color Calculation (using distorted UVs) ---
    // Scale vertical coordinate by steepness for gradient calculation
    float gradient_y = distorted_uv.y * FlameGradientSteepness;
    
    // Palette-based color calculation
    // Map vertical position to palette index (0=base, 1=tip)
    float t = 1.0 - saturate(gradient_y / (FlameGradientSteepness * 1.2)); 
    
    // Get base color from palette
    float3 color = getCandleFlameColor(t, timer);
    
    // Add core brightness boost
    float core_boost = smoothstep(0.4 / FlameGradientSteepness, 0.0, abs(distorted_uv.x));
    float3 coreColor = getCandleFlameColor(0.6, timer); // Core is brighter - use part of palette that's typically yellow/white
    color = lerp(color, coreColor * 1.5, core_boost * 0.8);

    // Apply subtle vertical intensity bias (brighter towards tip)
    color *= (0.8 + 0.4 * distorted_uv.y);

    // Apply red channel feedback/bloom effect
    color.rgb += color.r * FlameRedBrightness * 0.5;

    // --- 4. Intensity Flicker (Noise-based brightness variation) ---
    // Use improved noise function for flicker
    float flicker_noise_val = fbm(float2(timer * 0.01, 0.0) * NoiseScale * 0.1, timer * 0.01);
    float intensity_flicker = 1.0 + (flicker_noise_val - 0.5) * 0.4;
    
    // Apply audio reactivity to final intensity
    float audioIntensity = AS_applyAudioReactivity(1.0, Flame_AudioSource, Flame_AudioMultiplier, true);
    color *= intensity_flicker * audioIntensity;

    // --- 5. Apply Overall Power and Final Output ---
    // Apply FlamePower to scale final mask and color intensity
    final_mask *= saturate(FlamePower * 2.0);
    color *= FlamePower * 1.5;

    // Return saturated color and mask
    return float4(saturate(color), saturate(final_mask));
}

// New function to calculate flame appearance with modified parameters
float4 proceduralFlameWithParams(float2 rel_uv, float timer, float modifiedFlamePower, float modifiedSwayAngle) {
    // Fix for upside-down flame: invert the Y coordinate
    rel_uv.y = 1.0 - rel_uv.y;
    
    // 1. Apply UV Distortion
    float2 distorted_uv = distortUVs(rel_uv, timer);

    // --- 2. Shape Calculation ---
    // Calculate flame width profile based on vertical position
    float width_at_y = pow(saturate(1.0 - distorted_uv.y), FlameCurve);

    // Calculate normalized horizontal distance relative to the width at this height
    float h_dist_norm = abs(distorted_uv.x * 2.0) / (width_at_y + 1e-6);
    float sharp_h_dist_norm = h_dist_norm * FlameSharpness;

    // Create the main shape mask based on sharpened horizontal distance
    float shape_mask = smoothstep(1.0, 0.8, sharp_h_dist_norm);

    // Apply vertical fade near the tip for a softer point
    shape_mask *= smoothstep(1.05, 0.9, distorted_uv.y);

    // Apply fade near the very bottom for a softer/darker base
    float bottom_fade_mask = smoothstep(0.0, FlameBottomHeight * 0.5, distorted_uv.y);
    shape_mask *= bottom_fade_mask;

    // Final mask value after shaping and fading
    float final_mask = shape_mask;

    // Early exit if calculated mask is zero (pixel is outside the flame)
    if (final_mask <= 0.0) return float4(0.0, 0.0, 0.0, 0.0);

    // --- 3. Color Calculation (using distorted UVs) ---
    // Scale vertical coordinate by steepness for gradient calculation
    float gradient_y = distorted_uv.y * FlameGradientSteepness;
    
    // Palette-based color calculation
    // Map vertical position to palette index (0=base, 1=tip)
    float t = 1.0 - saturate(gradient_y / (FlameGradientSteepness * 1.2)); 
    
    // Get base color from palette
    float3 color = getCandleFlameColor(t, timer);
    
    // Add core brightness boost
    float core_boost = smoothstep(0.4 / FlameGradientSteepness, 0.0, abs(distorted_uv.x));
    float3 coreColor = getCandleFlameColor(0.6, timer); // Core is brighter - use part of palette that's typically yellow/white
    color = lerp(color, coreColor * 1.5, core_boost * 0.8);

    // Apply subtle vertical intensity bias (brighter towards tip)
    color *= (0.8 + 0.4 * distorted_uv.y);

    // Apply red channel feedback/bloom effect
    color.rgb += color.r * FlameRedBrightness * 0.5;

    // --- 4. Intensity Flicker (Noise-based brightness variation) ---
    // Use improved noise function for flicker
    float flicker_noise_val = fbm(float2(timer * 0.01, 0.0) * NoiseScale * 0.1, timer * 0.01);
    float intensity_flicker = 1.0 + (flicker_noise_val - 0.5) * 0.4;
    
    // Apply audio reactivity to final intensity
    float audioIntensity = AS_applyAudioReactivity(1.0, Flame_AudioSource, Flame_AudioMultiplier, true);
    color *= intensity_flicker * audioIntensity;

    // --- 5. Apply Overall Power and Final Output ---
    // Apply modifiedFlamePower to scale final mask and color intensity
    final_mask *= saturate(modifiedFlamePower * 2.0);
    color *= modifiedFlamePower * 1.5;

    // Return saturated color and mask
    return float4(saturate(color), saturate(final_mask));
}

} // namespace AS_CandleFlame

// ============================================================================
// MAIN PIXEL SHADER
// ============================================================================
float4 PS_ProceduralDepthPlaneFlame(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    // Get original scene color and depth
    float4 orig = tex2D(ReShade::BackBuffer, uv);
    float pixel_scene_depth = ReShade::GetLinearizedDepth(uv);
    
    // --- Depth cutoff (stage depth) ---
    // Skip calculation if the scene depth is closer than the flame plane
    if (pixel_scene_depth < StageDepth)
        return orig;
    
    // Get time for animation
    float timer = AS_getTime();
    
    // Apply audio reactivity based on the selected target parameter
    float audioIntensity = AS_applyAudioReactivity(1.0, Flame_AudioSource, Flame_AudioMultiplier, true);
    
    // Create modified parameters based on audio target selection
    float modifiedFlameHeight = FlameHeight;
    float modifiedFlamePower = FlamePower;
    float modifiedSwayAngle = SwayAngle;
    
    // Apply audio reactivity to the selected parameter(s)
    switch(AudioTarget)
    {
        case 0: // Flame Height
            modifiedFlameHeight *= 1.0 + (audioIntensity - 1.0) * 0.8; // Scale height by audio
            break;
        case 1: // Flame Power
            modifiedFlamePower *= audioIntensity; // Scale power by audio
            break;
        case 2: // Sway Angle
            modifiedSwayAngle *= audioIntensity; // Scale sway angle by audio
            break;
        case 3: // All Parameters
            modifiedFlameHeight *= 1.0 + (audioIntensity - 1.0) * 0.5; // Scale height (less intense)
            modifiedFlamePower *= 1.0 + (audioIntensity - 1.0) * 0.5; // Scale power (less intense)
            modifiedSwayAngle *= 1.0 + (audioIntensity - 1.0) * 1.0; // Scale sway angle (full intensity)
            break;
    }
    
    // Calculate relative UV coordinates for the flame effect
    // Adjust the calculation to scale from the bottom (base) rather than the center
    float2 flame_size_aspect_corrected = float2(FlameWidth / ReShade::AspectRatio, modifiedFlameHeight);

    // Position the flame with its base at FlameScreenPos
    // We need to adjust the Y offset to ensure the flame base stays at the specified position
    // when the height changes
    float2 rel_uv = (uv - FlameScreenPos) / flame_size_aspect_corrected;
    
    // --- Bounding Box Check (Optimization) ---
    if (rel_uv.y >= -0.1 && rel_uv.y < 1.1 && abs(rel_uv.x) < 1.5)
    {
        // --- Calculate Flame Appearance ---
        // We need to pass the modified parameters to the flame calculation function
        // instead of modifying the global uniforms
        float4 flame = AS_CandleFlame::proceduralFlameWithParams(rel_uv, timer, modifiedFlamePower, modifiedSwayAngle);

        // --- Debug Output ---
        float4 shapeMask = float4(flame.aaa, 1.0);
        float4 audioDbg = float4(audioIntensity.xxx, 1.0);
        float4 colorDbg = float4(flame.rgb, 1.0);
        
        if (DebugMode != AS_DEBUG_OFF) {
            return AS_debugOutput(DebugMode, orig, shapeMask, audioDbg, colorDbg);
        }
        
        // --- Apply Effect ---
        if (flame.a > 0.0)
        {
            // Apply the selected blend mode using AS_blendResult
            float3 blended = AS_blendResult(orig.rgb, flame.rgb * flame.a, BlendMode);
            // Apply blend amount for final mix
            return float4(lerp(orig.rgb, blended, BlendAmount), orig.a);
        }
    }

    // Return original scene color if no effect is applied
    return orig;
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_LFX_CandleFlame < ui_label = "[AS] LFX: Candle Flame"; ui_tooltip = "Generates a procedural candle flame at a specific depth plane with extensive controls and audio reactivity."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_ProceduralDepthPlaneFlame;
    }
}

#endif // __AS_LFX_CandleFlame_1_fx