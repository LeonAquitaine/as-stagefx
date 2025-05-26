/**
 * AS_LFX_CandleFlame.1.fx - Procedural Candle Flame Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Based on "Godot 4: Candle flame shader (tutorial)" by FencerDevLog
 * YouTube: https://www.youtube.com/watch?v=6ZZVwbzE8cw
 * FencerDevLog's Patreon: https://www.patreon.com/c/FencerDevLog/posts
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
 * - Base-anchored coordinate system for consistent calculations
 * 
 * IMPLEMENTATION OVERVIEW:
 * 1. Calculates relative UVs where y=0 is the base, y increases upwards towards the tip
 * 2. Calculates distorted UVs using trigonometric functions, anchored at the base
 * 3. Generates flame shape using power functions and gradients based on distorted UVs
 * 4. Applies color mapping based on vertical position (y=0 -> palette start, y=1 -> palette end)
 * 5. Adds noise-based flicker and audio reactivity
 * 6. Renders at specified depth plane with occlusion
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD
// ============================================================================
#ifndef __AS_LFX_CandleFlame_1_fx
#define __AS_LFX_CandleFlame_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh" // Standard ReShade functions and uniforms
#include "AS_Utils.1.fxh"  // Utilities and audio reactivity
#include "AS_Palette.1.fxh" // Color palette support

// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================
// --- Global Constants ---
static const int FLAME_COUNT = 4;  // Number of flame instances supported

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

static const float FLAME_ZOOM_MIN = 0.1;
static const float FLAME_ZOOM_MAX = 5.0;
static const float FLAME_ZOOM_DEFAULT = 1.0;

// ============================================================================
// FLAME UI MACRO
// ============================================================================

// Define a macro for the UI controls of each flame to avoid repetition
#define FLAME_UI(index, defaultEnable, defaultPosition, defaultZoom, \
                defaultHeight, defaultWidth, defaultCurve, defaultPower, defaultDepth) \
uniform bool Flame##index##_Enable < ui_label = "Enable Flame " #index; ui_tooltip = "Toggle this flame on or off."; ui_category = "Flame " #index; ui_category_closed = index > 1; > = defaultEnable; \
uniform float2 Flame##index##_Position < ui_type = "slider"; ui_label = "Position (X, Y)"; ui_tooltip = "Screen position for the flame base. (0,0) is center, [-1, 1] covers the central square."; ui_min = -1.5; ui_max = 1.5; ui_step = 0.01; ui_category = "Flame " #index; > = defaultPosition; \
uniform float Flame##index##_Zoom < ui_type = "slider"; ui_min = FLAME_ZOOM_MIN; ui_max = FLAME_ZOOM_MAX; ui_step = 0.05; ui_label = "Zoom"; ui_tooltip = "Overall zoom factor for the flame."; ui_category = "Flame " #index; > = defaultZoom; \
uniform float Flame##index##_Height < ui_type = "slider"; ui_min = FLAME_HEIGHT_MIN; ui_max = FLAME_HEIGHT_MAX; ui_step = 0.01; ui_label = "Height"; ui_tooltip = "Overall height scale of the flame."; ui_category = "Flame " #index; > = defaultHeight; \
uniform float Flame##index##_Width < ui_type = "slider"; ui_min = FLAME_WIDTH_MIN; ui_max = FLAME_WIDTH_MAX; ui_step = 0.01; ui_label = "Width"; ui_tooltip = "Overall width scale of the flame."; ui_category = "Flame " #index; > = defaultWidth; \
uniform float Flame##index##_Curve < ui_type = "slider"; ui_min = FLAME_CURVE_MIN; ui_max = FLAME_CURVE_MAX; ui_step = 0.05; ui_label = "Tip Shape"; ui_tooltip = "Controls the flame tip shape (0.5=round, >1=pointy)."; ui_category = "Flame " #index; > = defaultCurve; \
uniform float Flame##index##_Power < ui_type = "slider"; ui_min = FLAME_POWER_MIN; ui_max = FLAME_POWER_MAX; ui_step = 0.01; ui_label = "Brightness"; ui_tooltip = "Overall brightness / intensity multiplier."; ui_category = "Flame " #index; > = defaultPower; \
uniform float Flame##index##_StageDepth < ui_type = "slider"; ui_label = "Depth"; ui_tooltip = "Depth plane for this flame (0.0-1.0). Lower values are closer to the camera."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Flame " #index; > = defaultDepth;

// ============================================================================
// FLAME CONTROLS (Using the macro)
// ============================================================================

// Flame 1 controls (enabled by default, centered)
FLAME_UI(1, true, float2(0.0, 0.0), FLAME_ZOOM_DEFAULT, 
        FLAME_HEIGHT_DEFAULT, FLAME_WIDTH_DEFAULT, FLAME_CURVE_DEFAULT, FLAME_POWER_DEFAULT, 0.05)

// Flame 2 controls (disabled by default, slightly offset)
FLAME_UI(2, false, float2(-0.2, -0.2), 0.9, 
        FLAME_HEIGHT_DEFAULT * 0.8, FLAME_WIDTH_DEFAULT * 0.8, FLAME_CURVE_DEFAULT, FLAME_POWER_DEFAULT, 0.1)

// Flame 3 controls (disabled by default, slightly offset)
FLAME_UI(3, false, float2(0.2, -0.2), 1.1, 
        FLAME_HEIGHT_DEFAULT * 0.7, FLAME_WIDTH_DEFAULT * 0.9, FLAME_CURVE_DEFAULT * 1.2, FLAME_POWER_DEFAULT, 0.15)

// Flame 4 controls (disabled by default, slightly offset)
FLAME_UI(4, false, float2(0.0, -0.4), 0.8, 
        FLAME_HEIGHT_DEFAULT * 0.5, FLAME_WIDTH_DEFAULT * 0.6, FLAME_CURVE_DEFAULT * 1.5, FLAME_POWER_DEFAULT, 0.2)

// ============================================================================
// PALETTE & STYLE
// ============================================================================
AS_PALETTE_SELECTION_UI(PalettePreset, "Palette", AS_PALETTE_FIRE, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(CandleFlame_, "Palette & Style")

uniform float ColorCycleSpeed < ui_type = "slider"; ui_label = "Color Cycle Speed"; ui_tooltip = "Controls how fast flame colors cycle. 0 = static"; ui_min = -5.0; ui_max = 5.0; ui_step = 0.1; ui_category = "Palette & Style"; > = 0.0;

// ============================================================================
// FLAME APPEARANCE
// ============================================================================
uniform float FlameCurve < ui_type = "slider"; ui_min = FLAME_CURVE_MIN; ui_max = FLAME_CURVE_MAX; ui_step = 0.05; ui_label = "Tip Shape"; ui_tooltip = "Controls the flame tip shape (0.5=round, >1=pointy)."; ui_category = "Flame Appearance"; > = FLAME_CURVE_DEFAULT;
uniform float FlameSharpness < ui_type = "slider"; ui_min = FLAME_SHARPNESS_MIN; ui_max = FLAME_SHARPNESS_MAX; ui_step = 0.05; ui_label = "Edge Sharpness"; ui_tooltip = "Controls the horizontal edge sharpness/thickness."; ui_category = "Flame Appearance"; > = FLAME_SHARPNESS_DEFAULT;
uniform float FlameBottomHeight < ui_type = "slider"; ui_min = FLAME_BOTTOM_HEIGHT_MIN; ui_max = FLAME_BOTTOM_HEIGHT_MAX; ui_step = 0.01; ui_label = "Base Height"; ui_tooltip = "Relative height of flame base color transition. Affects bottom fade."; ui_category = "Flame Appearance"; > = FLAME_BOTTOM_HEIGHT_DEFAULT;
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
AS_AUDIO_UI(Flame_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(Flame_AudioMultiplier, "Intensity", 1.0, 2.0, "Audio Reactivity")

uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter"; ui_tooltip = "Select which parameter will be affected by audio reactivity"; ui_items = "Flame Height\0Flame Power\0Sway Angle\0All Parameters\0"; ui_category = "Audio Reactivity"; > = 0; // Default to Flame Height

// ============================================================================
// STAGE
// ============================================================================
AS_ROTATION_UI(FlameSnapRotation, FlameFineRotation)

// ============================================================================
// FINAL MIX
// ============================================================================
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_LIGHTEN)
AS_BLENDAMOUNT_UI(BlendAmount)

// ============================================================================
// DEBUG
// ============================================================================
AS_DEBUG_UI("Off\0Shape\0Audio\0Color\0")

// ============================================================================
// NAMESPACE & HELPERS
// ============================================================================
namespace AS_CandleFlame {

// Structure to hold flame parameters
struct FlameParams {
    bool enable;
    float2 position;
    float zoom;
    float height;
    float width;
    float curve;
    float power;
    float stageDepth; // Added for individual flame depth
    // Global parameters shared by all flames
    float sharpness;
    float bottomHeight;
    float gradientSteepness;
    float redBrightness;
};

// Helper function to get flame parameters for a given index
FlameParams GetFlameParams(int flameIndex) {
    FlameParams params;
    
    // Set shared parameters first
    params.sharpness = FlameSharpness;
    params.bottomHeight = FlameBottomHeight;
    params.gradientSteepness = FlameGradientSteepness;
    params.redBrightness = FlameRedBrightness;
    
    // Set flame-specific parameters based on index
    if (flameIndex == 0) {
        params.enable = Flame1_Enable;
        params.position = Flame1_Position;
        params.zoom = Flame1_Zoom;
        params.height = Flame1_Height;
        params.width = Flame1_Width;
        params.curve = Flame1_Curve;
        params.power = Flame1_Power;
        params.stageDepth = Flame1_StageDepth;
    }
    else if (flameIndex == 1) {
        params.enable = Flame2_Enable;
        params.position = Flame2_Position;
        params.zoom = Flame2_Zoom;
        params.height = Flame2_Height;
        params.width = Flame2_Width;
        params.curve = Flame2_Curve;
        params.power = Flame2_Power;
        params.stageDepth = Flame2_StageDepth;
    }
    else if (flameIndex == 2) {
        params.enable = Flame3_Enable;
        params.position = Flame3_Position;
        params.zoom = Flame3_Zoom;
        params.height = Flame3_Height;
        params.width = Flame3_Width;
        params.curve = Flame3_Curve;
        params.power = Flame3_Power;
        params.stageDepth = Flame3_StageDepth;
    }
    else { // flameIndex == 3
        params.enable = Flame4_Enable;
        params.position = Flame4_Position;
        params.zoom = Flame4_Zoom;
        params.height = Flame4_Height;
        params.width = Flame4_Width;
        params.curve = Flame4_Curve;
        params.power = Flame4_Power;
        params.stageDepth = Flame4_StageDepth;
    }
    
    return params;
}

// --- Improved Noise Functions (Perlin-like) ---
// (Using provided improved noise functions)
float hash(float2 p) {
    p = 50.0 * frac(p * AS_INV_PI + float2(0.71, 0.113));
    return -1.0 + 2.0 * frac(p.x * p.y * (p.x + p.y));
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = frac(p);
    float2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0); // Quintic interpolation
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));
    return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
}

float fbm(float2 p, float time) {
    float f = 0.0;
    float w = 0.5;
    for (int i = 0; i < 5; i++) { // 5 octaves
        f += w * noise(p);
        p *= 2.0; // Increase frequency
        p += time * 0.5; // Add time offset for animation
        w *= 0.5; // Decrease amplitude
    }
    return f;
}

// Get color from the currently selected palette
float3 getCandleFlameColor(float t, float time) {
    if (ColorCycleSpeed != 0.0) {
        float cycleRate = ColorCycleSpeed * 0.1;
        t = frac(t + cycleRate * time);
    }    t = saturate(t); // Ensure t is within valid range [0, 1]
    
    if (PalettePreset == AS_PALETTE_CUSTOM) { // Use custom palette
        return AS_GET_INTERPOLATED_CUSTOM_COLOR(CandleFlame_, t);
    }
    return AS_getInterpolatedColor(PalettePreset, t); // Use preset palette
}

/**
 * Distorts UV coordinates based on time and parameters for flame animation.
 * Assumes uv.y = 0 is the flame base and uv.y = 1 is the tip (increasing upwards).
 * Applies more distortion towards the tip.
 */
float2 distortUVs(float2 uv, float timer, float audioFactor, float currentSwayAngle) {
    float verticalFalloff = uv.y * uv.y; // Quadratic falloff (more movement at tip)
    float fluctuation = (sin(timer * HorizontalSpeed - uv.y) + cos((timer * HorizontalSpeed - uv.y) * 0.01));

    // Horizontal distortion (sway from noise)
    uv.x += sin(timer * HorizontalSpeed) * fluctuation * HorizontalSway * 0.1 * audioFactor * verticalFalloff;

    // Apply standard sway animation
    float sway = AS_applySway(currentSwayAngle, SwaySpeed);
    uv.x += sway * 0.05 * audioFactor * verticalFalloff;

    // Vertical distortion (flicker/jump)
    uv.y += frac(sin(timer * IntensityFlickerSpeed * AS_TWO_PI)) * VerticalSpeed * 0.1 * audioFactor * verticalFalloff;

    return uv;
}

/**
 * Calculates the flame color and mask for a given relative UV coordinate.
 * Assumes rel_uv.y = 0 is the base, rel_uv.y = 1 is the tip (increasing upwards).
 * Takes potentially audio-modified parameters as input.
 */
float4 proceduralFlame(
    float2 rel_uv, 
    float timer, 
    float currentFlamePower, 
    float currentSwayAngle, 
    float audioIntensity // Pass audio intensity for flicker/brightness modulation
) {
    // --- 1. Apply UV Distortion ---
    float2 distorted_uv = distortUVs(rel_uv, timer, audioIntensity, currentSwayAngle);

    // --- 2. Shape Calculation ---
    // Width shrinks towards the tip (y=1) based on FlameCurve.
    float width_at_y = pow(saturate(1.0 - distorted_uv.y), FlameCurve);

    // Normalized horizontal distance relative to width, applying sharpness.
    float h_dist_norm = abs(distorted_uv.x * 2.0) / (width_at_y + 1e-6);
    float sharp_h_dist_norm = h_dist_norm * FlameSharpness;

    // Main shape mask based on horizontal distance.
    float shape_mask = smoothstep(1.0, 0.8, sharp_h_dist_norm);

    // Apply vertical fade near the tip (y=1).
    shape_mask *= smoothstep(1.05, 0.9, distorted_uv.y);

    // Apply fade near the very bottom (y=0).
    float bottom_fade_mask = smoothstep(0.0, FlameBottomHeight * 0.5, distorted_uv.y);
    shape_mask *= bottom_fade_mask;

    // Final mask value.
    float final_mask = shape_mask;

    // Early exit if outside flame.
    if (final_mask <= 0.0) return float4(0.0, 0.0, 0.0, 0.0);

    // --- 3. Color Calculation (using distorted UVs, y=0 is base) ---
    float gradient_y = distorted_uv.y * FlameGradientSteepness;
    
    // Map vertical position to palette index (t=0 at base, t=1 near tip).
    float t = saturate(gradient_y / (FlameGradientSteepness * 1.0)); 

    // Get base color from palette.
    float3 color = getCandleFlameColor(t, timer);
    
    // Add core brightness boost.
    float core_boost = smoothstep(0.4 / FlameGradientSteepness, 0.0, abs(distorted_uv.x));
    float3 coreColor = getCandleFlameColor(saturate(t + 0.2), timer); // Sample slightly higher in palette for core
    color = lerp(color, coreColor * 1.5, core_boost * 0.8); // Blend towards brighter core

    // Apply subtle vertical intensity bias (brighter towards tip, y=1).
    color *= (0.8 + 0.4 * distorted_uv.y);

    // Apply red channel feedback/bloom effect.
    color.rgb += color.r * FlameRedBrightness * 0.5;

    // --- 4. Intensity Flicker ---
    float flicker_noise_val = fbm(distorted_uv * NoiseScale * 0.1, timer * IntensityFlickerSpeed * 0.01);
    float intensity_flicker = 1.0 + flicker_noise_val * 0.4;
    
    // Apply audio reactivity directly to the flicker intensity
    color *= intensity_flicker * audioIntensity;

    // --- 5. Apply Overall Power ---
    // Apply currentFlamePower (potentially audio-modified).
    final_mask *= saturate(currentFlamePower * 2.0);
    color *= currentFlamePower * 1.5;

    // Return saturated color and mask.
    return float4(saturate(color), saturate(final_mask));
}

} // namespace AS_CandleFlame

// ============================================================================
// MAIN PIXEL SHADER
// ============================================================================
float4 PS_ProceduralDepthPlaneFlame(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float4 orig = tex2D(ReShade::BackBuffer, uv);
    float pixel_scene_depth = ReShade::GetLinearizedDepth(uv);

    float timer = AS_getTime();
    float audioIntensity = AS_applyAudioReactivity(1.0, Flame_AudioSource, Flame_AudioMultiplier, true);

    // Get audio-modified global parameters
    float currentSwayAngle = SwayAngle;
    const float audioResponseFactor = 0.5;

    if (AudioTarget == 2 || AudioTarget == 3) {
        currentSwayAngle = lerp(SwayAngle, SwayAngle * audioIntensity, audioResponseFactor);
    }

    // --- Coordinate System Setup ---
    float aspectRatio = ReShade::AspectRatio; // BUFFER_WIDTH / BUFFER_HEIGHT
    float2 screen_coords; // Centered coords, shortest dimension spans [-0.5, 0.5]

    if (aspectRatio >= 1.0) { // Wider than tall, or square
        screen_coords.x = (uv.x - 0.5) * aspectRatio; // Spans [-0.5*AR, 0.5*AR]
        screen_coords.y = uv.y - 0.5;                 // Spans [-0.5, 0.5] (Shortest)
    } else { // Taller than wide
        screen_coords.x = uv.x - 0.5;                 // Spans [-0.5, 0.5] (Shortest)
        screen_coords.y = (uv.y - 0.5) / aspectRatio; // Spans [-0.5/AR, 0.5/AR]
    }
    // Note: Y still increases downwards here.

    // 2. Apply inverse global rotation
    float globalRotation = AS_getRotationRadians(FlameSnapRotation, FlameFineRotation);
    float sinRot = sin(-globalRotation); // Inverse rotation
    float cosRot = cos(-globalRotation);
    float2 rotated_screen_coords;
    rotated_screen_coords.x = screen_coords.x * cosRot - screen_coords.y * sinRot;
    rotated_screen_coords.y = screen_coords.x * sinRot + screen_coords.y * cosRot;

    // Initialize output color
    float4 finalResult = orig;
    float4 debugResult = float4(0, 0, 0, 0);
    bool hasDebugData = false;

    // Process each flame
    for (int i = 0; i < FLAME_COUNT; i++) {
        AS_CandleFlame::FlameParams params = AS_CandleFlame::GetFlameParams(i);

        if (!params.enable) continue;
        if (pixel_scene_depth < params.stageDepth) continue; // Per-flame depth test

        // Apply audio reactivity to flame parameters
        float currentFlamePower = params.power;
        float effectiveHeight = params.height;
        if (AudioTarget == 0 || AudioTarget == 3) {
            effectiveHeight = lerp(params.height, params.height * (1.0 + (audioIntensity - 1.0) * 0.8), audioResponseFactor);
            effectiveHeight = max(FLAME_HEIGHT_MIN, effectiveHeight);
        }
        if (AudioTarget == 1 || AudioTarget == 3) {
            currentFlamePower = lerp(params.power, params.power * audioIntensity, audioResponseFactor);
            currentFlamePower = max(0.0, currentFlamePower);
        }

        // 3. Calculate flame base position in the *same* centered coordinate system
        //    params.position is in [-1.5, 1.5]. Map [-1, 1] to the central square's [-0.5, 0.5] range.
        float2 flame_screen_coords = params.position * 0.5;

        // 4. Calculate pixel's position relative to the flame base in the rotated system
        float2 diff = rotated_screen_coords - flame_screen_coords;

        // 5. Normalize the relative position using flame dimensions expressed in screen_coords units
        float normWidth = params.width * params.zoom; // Relative to screen height
        float normHeight = effectiveHeight * params.zoom; // Relative to screen height

        float2 flameDimInScreenCoords;
        if (aspectRatio >= 1.0) { // Wide
            flameDimInScreenCoords.x = normWidth * aspectRatio; // Width relative to Y span=1.0
            flameDimInScreenCoords.y = normHeight;             // Height relative to Y span=1.0
        } else { // Tall
            flameDimInScreenCoords.x = normWidth;             // Width relative to X span=1.0
            flameDimInScreenCoords.y = normHeight / aspectRatio; // Height relative to X span=1.0
        }

        float2 rel_uv;
        // Avoid division by zero
        rel_uv.x = (flameDimInScreenCoords.x > 1e-5) ? diff.x / flameDimInScreenCoords.x : 0.0;
        // Negate diff.y because screen_coords.y increases downwards, but rel_uv.y increases upwards
        rel_uv.y = (flameDimInScreenCoords.y > 1e-5) ? -diff.y / flameDimInScreenCoords.y : 0.0;

        // --- Bounding Box Check --- Keep bounds slightly generous
        if (rel_uv.y >= -0.1 && rel_uv.y < 1.1 && abs(rel_uv.x) < 1.5) {
            // --- Calculate Flame Appearance ---
            float4 flame = AS_CandleFlame::proceduralFlame(
                rel_uv, timer, currentFlamePower, currentSwayAngle, audioIntensity
            );

            // --- Debug Output ---
            if (DebugMode != AS_DEBUG_OFF && !hasDebugData && flame.a > 0.0) {
                debugResult = flame;
                hasDebugData = true;
            }

            // --- Apply Effect ---
            if (flame.a > 0.0) {
                float3 blended = AS_applyBlend(flame.rgb * flame.a, finalResult.rgb, BlendMode);
                finalResult = float4(lerp(finalResult.rgb, blended, BlendAmount), orig.a);
            }
        }
    }

    // Handle debug mode
    if (DebugMode != AS_DEBUG_OFF && hasDebugData) {
        float4 shapeMask = float4(debugResult.aaa, 1.0);
        float4 audioDbg = float4(audioIntensity.xxx, 1.0);
        float4 colorDbg = float4(debugResult.rgb, 1.0);
        return AS_debugOutput(DebugMode, orig, shapeMask, audioDbg, colorDbg);
    }

    return finalResult;
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_LFX_CandleFlame < ui_label = "[AS] LFX: Candle Flame"; ui_tooltip = "Generates a procedural candle flame at a specific depth plane with extensive controls and audio reactivity. Base-anchored & upward pointing."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_ProceduralDepthPlaneFlame;
    }
}

#endif // __AS_LFX_CandleFlame_1_fx

