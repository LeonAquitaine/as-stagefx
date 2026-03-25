/**
 * AS_Utils.1.fxh - Common Utility Functions for AS StageFX Shader Collection
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 * * DESCRIPTION:
 * This header file provides common utility functions used across the AS StageFX
 * shader collection. It includes blend modes, audio processing, mathematical helpers,
 * and various convenience functions to maintain consistency across shaders.
 *
 * FEATURES:
 * - Standardized UI controls for consistent user interfaces
 * - Listeningway audio integration with standard sources and stereo controls
 * - Stereo audio spatialization and multi-channel format detection
 * - Debug visualization tools and helpers
 * - Common blend modes and mixing functions
 * - Mathematical and coordinate transformation helpers
 * - Depth, normal reconstruction, and surface effects functions
 * * IMPLEMENTATION OVERVIEW:
 * This file is organized in sections:
 * 1. UI standardization macros for consistent parameter layouts
 * 2. Audio integration and Listeningway support with stereo capabilities
 * 3. Visual effect helpers (blend modes, color operations)
 * 4. Mathematical functions (coordinate transforms)
 * 5. Advanced rendering helpers (depth, normals, etc.)
 *
 * Note: For procedural noise functions, see AS_Noise.1.fxh
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_Utils_1_fxh
#define __AS_Utils_1_fxh

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "Blending.fxh" // Make sure Blending.fxh from ReShade's common headers is available

// ============================================================================
// MATH CONSTANTS
// ============================================================================
// --- Math Constants ---
// Standard mathematical constants for consistent use across all shaders
// Core mathematical constants
static const float AS_PI = 3.1415926535897932384626433832795f;
static const float AS_TWO_PI = 6.2831853071795864769252867665590f;
static const float AS_HALF_PI = 1.5707963267948966192313216916398f;
static const float AS_QUARTER_PI = 0.7853981633974483096156608458199f;
static const float AS_INV_PI = 0.3183098861837906715377675267450f;
static const float AS_E = 2.7182818284590452353602874713527f;
static const float AS_GOLDEN_RATIO = 1.6180339887498948482045868343656f;
static const float AS_ONE = 1.0f;                        // Unity value
static const float AS_ZERO = 0.0f;                       // Zero value

// Physics & graphics constants
static const float AS_EPSILON = 1e-6f;          // Very small number to avoid division by zero
static const float AS_EPS_SAFE = 1e-5f;      // Slightly larger epsilon for screen-space operations
static const float AS_DEGREES_TO_RADIANS = AS_PI / 180.0f;
static const float AS_RADIANS_TO_DEGREES = 180.0f / AS_PI;
static const float AS_INV_255 = 0.0039215686274509803921568627451f; // 1/255 for color normalization
static const float AS_GAMMA_SRGB = 2.2f;         // Standard sRGB gamma exponent
static const float3 AS_LUMA_REC709 = float3(0.2126f, 0.7152f, 0.0722f); // Rec.709 luminance weights

// Common numerical constants
static const float AS_HALF = 0.5f;                          // 1/2 - useful for centered coordinates
static const float AS_QUARTER = 0.25f;                        // 1/4
static const float AS_THIRD = 0.3333333333333333333333333333333f;    // 1/3
static const float AS_TWO_THIRDS = 0.6666666666666666666666666666667f; // 2/3
static const float AS_SQRT_TWO = 1.4142135623730950488016887242097f; // Square root of 2, useful for diagonal calculations
static const float AS_INV_SQRT_TWO = 0.70710678118654752440084436210485f; // 1/sqrt(2), diagonal normalization
static const float AS_SQRT_TWO_THIRD = AS_SQRT_TWO / 3.0f; // sqrt(2)/3, used by some simplex formulations
static const float AS_MIN_NORM = 0.0001f;        // Small minimum for normalized radii/thickness to avoid collapse
static const float AS_NORMAL_EPSILON = 1e-3f;    // Epsilon for finite difference normal estimation in SDF/raymarching
// Friendly alias for 2π
#define AS_TAU AS_TWO_PI

// Depth testing constants 
static const float AS_DEPTH_EPSILON = 0.0005f;  // Standard depth epsilon for z-fighting prevention
static const float AS_EDGE_AA = 0.05f;        // Standard anti-aliasing edge size for smoothstep

// Additional stability/epsilon constants used across effects (centralized to avoid magic numbers)
static const float AS_DEPTH_EPSILON_SMALL = 0.0001f; // Tighter depth epsilon for precise comparisons
static const float AS_STABILITY_EPSILON = 1e-6f;     // Generic small epsilon for denominators/weights
static const float AS_ALPHA_EPSILON = 1e-5f;         // Minimum alpha threshold for masking/visibility
static const float AS_GAUSS_EXP_EPSILON = 1e-5f;     // Gaussian exponent denominator stability constant
static const float AS_MIN_STROKE_THICKNESS = 0.0005f; // Min line/stroke thickness in normalized screen units
static const float AS_OPAQUE_ALPHA = 1.0f;           // Opaque alpha value (semantic alias)

// ============================================================================
// COORDINATE NAMING CONVENTION
// ============================================================================
// Use these names consistently across all shaders:
//   texcoord      - Raw input UV from vertex shader, range [0, 1]
//   uvCentered    - Centered coordinates, (0,0) = screen center
//   uvAspect      - Centered + aspect-ratio corrected (circles are circular)
//   uvTransformed - After position, scale, and/or rotation applied
//   uvPolar       - Polar coordinates: .x = angle (radians), .y = radius

// ============================================================================
// STANDARD UI CATEGORY NAMES
// ============================================================================
// Use these constants in ui_category to ensure consistent naming and ordering.
// Canonical ordering (top to bottom in ReShade panel):
//   1. Effect-specific categories (use descriptive names, e.g., "Pattern", "Fractal")
//   2. AS_CAT_PALETTE       - Color palette and style controls
//   3. AS_CAT_APPEARANCE    - Visual appearance tuning
//   4. AS_CAT_ANIMATION     - Animation speed, keyframe, sway
//   5. AS_CAT_AUDIO         - Audio reactivity source and intensity
//   6. AS_CAT_STAGE         - Stage depth, position, rotation, scale
//   7. AS_CAT_PERFORMANCE   - Quality, iteration count, resolution
//   8. AS_CAT_FINAL         - Blend mode and blend strength
//   9. AS_CAT_DEBUG         - Debug visualization modes
#define AS_CAT_PALETTE      "Palette & Style"
#define AS_CAT_APPEARANCE   "Appearance"
#define AS_CAT_PATTERN      "Pattern"
#define AS_CAT_LIGHTING     "Lighting"
#define AS_CAT_COLOR        "Color"
#define AS_CAT_ANIMATION    "Animation"
#define AS_CAT_AUDIO        "Audio Reactivity"
#define AS_CAT_STAGE        "Stage"
#define AS_CAT_PERFORMANCE  "Performance"
#define AS_CAT_FINAL        "Final Mix"
#define AS_CAT_DEBUG        "Debug"

// ============================================================================
// UI STANDARDIZATION & MACROS
// ============================================================================

// --- Listeningway Integration ---
// These macros help with consistent Listeningway integration across all shaders
// Define a complete fallback implementation for Listeningway
#ifndef __LISTENINGWAY_INSTALLED
    // Since we're not including ListeningwayUniforms.fxh anymore,
    // provide a complete compatible implementation directly here
    #define LISTENINGWAY_NUM_BANDS 64
    #define __LISTENINGWAY_INSTALLED 1

    // Create fallback uniforms with the same interface as the real Listeningway
    uniform float Listeningway_Volume < source = "listeningway_volume"; > = 0.0f;
    uniform float Listeningway_FreqBands[LISTENINGWAY_NUM_BANDS] < source = "listeningway_freqbands"; > = {
        0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f
    };
    uniform float Listeningway_Beat < source = "listeningway_beat"; > = 0.0f;

    // Time uniforms
    uniform float Listeningway_TimeSeconds < source = "listeningway_timeseconds"; > = 0.0f;
    uniform float Listeningway_TimePhase60Hz < source = "listeningway_timephase60hz"; > = 0.0f;
    uniform float Listeningway_TimePhase120Hz < source = "listeningway_timephase120hz"; > = 0.0f;
    uniform float Listeningway_TotalPhases60Hz < source = "listeningway_totalphases60hz"; > = 0.0f;
    uniform float Listeningway_TotalPhases120Hz < source = "listeningway_totalphases120hz"; > = 0.0f;

    // Stereo spatialization uniforms
    uniform float Listeningway_VolumeLeft < source = "listeningway_volumeleft"; > = 0.0f;
    uniform float Listeningway_VolumeRight < source = "listeningway_volumeright"; > = 0.0f;
    uniform float Listeningway_AudioPan < source = "listeningway_audiopan"; > = 0.0f;

    // Audio format uniform (0=none, 1=mono, 2=stereo, 6=5.1, 8=7.1)
    uniform float Listeningway_AudioFormat < source = "listeningway_audioformat"; > = 0.0f;
#endif

// Animation timing constants
static const float AS_ANIM_SLOW = 0.5f;      // Slow animation speed multiplier
static const float AS_ANIM_NORMAL = 1.0f;      // Normal animation speed multiplier  
static const float AS_ANIM_FAST = 2.0f;      // Fast animation speed multiplier

// Timing constants
static const float AS_TIME_1_SECOND = 1.0f;              // 1 second of animation time
static const float AS_TIME_HALF_SECOND = 0.5f;          // 0.5 seconds of animation time
static const float AS_TIME_QUARTER_SECOND = 0.25f;      // 0.25 seconds of animation time

// Animation patterns
static const float AS_PATTERN_FREQ_LOW = 2.0f;          // Low frequency for animation patterns
static const float AS_PATTERN_FREQ_MED = 5.0f;          // Medium frequency for animation patterns
static const float AS_PATTERN_FREQ_HIGH = 10.0f;         // High frequency for animation patterns

// Standard UI ranges for commonly used parameters
static const float AS_RANGE_ZERO_ONE_MIN = 0.0f;        // Common minimum for normalized parameters
static const float AS_RANGE_ZERO_ONE_MAX = 1.0f;        // Common maximum for normalized parameters

static const float AS_RANGE_NEG_ONE_ONE_MIN = -1.0f;    // Common minimum for bipolar normalized parameters
static const float AS_RANGE_NEG_ONE_ONE_MAX = 1.0f;      // Common maximum for bipolar normalized parameters

static const float AS_OP_MIN = 0.0f;          // Minimum for opacity parameters
static const float AS_OP_MAX = 1.0f;          // Maximum for opacity parameters
static const float AS_OP_DEFAULT = 1.0f;      // Default for opacity parameters

static const float AS_RANGE_BLEND_MIN = 0.0f;          // Minimum for blend amount parameters
static const float AS_RANGE_BLEND_MAX = 1.0f;          // Maximum for blend amount parameters
static const float AS_RANGE_BLEND_DEFAULT = 1.0f;      // Default for blend amount parameters

static const float AS_RANGE_AUDIO_MULT_MIN = 0.0f;      // Minimum for audio multiplier parameters
static const float AS_RANGE_AUDIO_MULT_MAX = 2.0f;      // Maximum for audio multiplier parameters
static const float AS_RANGE_AUDIO_MULT_DEFAULT = 1.0f;  // Default for audio multiplier parameters

// Scale range constants
static const float AS_RANGE_SCALE_MIN = 0.1f;          // Minimum for scale parameters
static const float AS_RANGE_SCALE_MAX = 5.0f;          // Maximum for scale parameters
static const float AS_RANGE_SCALE_DEFAULT = 1.0f;      // Default for scale parameters

// Speed range constants
static const float AS_RANGE_SPEED_MIN = 0.0f;          // Minimum for speed parameters 
static const float AS_RANGE_SPEED_MAX = 5.0f;          // Maximum for speed parameters
static const float AS_RANGE_SPEED_DEFAULT = 1.0f;      // Default for speed parameters

// Debug mode constants
static const int AS_DEBUG_OFF = 0;                // Debug mode off
static const int AS_DEBUG_MASK = 1;               // Debug mask display
static const int AS_DEBUG_DEPTH = 2;              // Debug depth display
static const int AS_DEBUG_AUDIO = 3;              // Debug audio display
static const int AS_DEBUG_PATTERN = 4;            // Debug pattern display

// --- Audio Constants ---
#define AS_AUDIO_OFF          0  // Audio source disabled
#define AS_AUDIO_SOLID        1  // Constant value (no audio reactivity)
#define AS_AUDIO_VOLUME       2  // Overall audio volume
#define AS_AUDIO_BEAT         3  // Beat detection
#define AS_AUDIO_BASS         4  // Low frequency band
#define AS_AUDIO_TREBLE       5  // High frequency band
#define AS_AUDIO_MID          6  // Mid frequency band
#define AS_AUDIO_VOLUME_LEFT  7  // Left channel volume
#define AS_AUDIO_VOLUME_RIGHT 8  // Right channel volume
#define AS_AUDIO_PAN          9  // Audio pan (-1 to 1)

// --- Blend Constants ---
#define AS_BLEND_NORMAL     0 // No blending
#define AS_BLEND_OPAQUE     0 // Opaque blending (same as normal for RGB, alpha handled separately)
#define AS_BLEND_LIGHTEN    5 // Lighter only (matches ComHeaders::Blending::Blend_Lighten_Only)

// --- Display and Resolution Constants ---
static const float AS_RESOLUTION_BASE_HEIGHT = 1080.0f;  // Standard height for scaling calculations
static const float AS_RESOLUTION_BASE_WIDTH = 1920.0f;   // Standard width for scaling calculations
static const float AS_STANDARD_ASPECT_RATIO = 16.0f/9.0f; // Standard aspect ratio for reference

// Common UI mapping constants
static const float AS_UI_POSITION_RANGE = 1.5f;  // Standard range for position UI controls (-1.5 to 1.5)
static const float AS_UI_CENTRAL_SQUARE = 1.0f;  // Range mapping to central square (-1.0 to 1.0)
static const float AS_UI_POSITION_SCALE = 0.5f;  // Position scaling factor for centered coordinates

// Common coordinate system values
static const float AS_SCREEN_CENTER_X = 0.5f;    // Screen center X coordinate
static const float AS_SCREEN_CENTER_Y = 0.5f;    // Screen center Y coordinate
// AS_RESOLUTION_SCALE is defined here, but it's better to calculate it dynamically if needed,
// as BUFFER_HEIGHT might not be known at compile time for all contexts.
// If used, ensure it's in a context where BUFFER_HEIGHT is defined.
// static const float AS_RESOLUTION_SCALE = 1080.0f / BUFFER_HEIGHT; // Resolution scaling factor

// Default number of frequency bands
#ifndef LISTENINGWAY_NUM_BANDS
    #define LISTENINGWAY_NUM_BANDS 64
#endif
#define AS_DEFAULT_NUM_BANDS LISTENINGWAY_NUM_BANDS

// --- Standard UI Strings ---
#define AS_AUDIO_SOURCE_ITEMS "Off\0Solid\0Volume\0Beat\0Bass\0Treble\0Mid\0Volume Left\0Volume Right\0Pan\0"

// --- UI Control Macros ---
// Define standard audio source control (reuse this macro for each audio reactive parameter)
#define AS_AUDIO_UI(name, label, defaultSource, category) \
uniform int name < ui_type = "combo"; ui_label = label; ui_tooltip = "Select the audio frequency band that drives this effect."; ui_items = AS_AUDIO_SOURCE_ITEMS; ui_category = category; > = defaultSource;

// Define standard multiplier control for audio reactivity
#define AS_AUDIO_MULT_UI(name, label, defaultValue, maxValue, category) \
uniform float name < ui_type = "slider"; ui_label = label; ui_tooltip = "Controls how much the selected audio source affects this parameter."; ui_min = 0.0; ui_max = maxValue; ui_step = 0.05; ui_category = category; > = defaultValue;

// Standard audio target selector (combo for choosing which parameter responds to audio)
#define AS_AUDIO_TARGET_UI(name, items, defaultTarget) \
uniform int name < ui_type = "combo"; ui_label = "Audio Target"; ui_tooltip = "Select which parameter responds to audio input."; ui_items = items; ui_category = AS_CAT_AUDIO; > = defaultTarget;

// Per-parameter audio gain slider (how much audio affects a specific parameter)
#define AS_AUDIO_GAIN_UI(name, label, maxValue, defaultValue) \
uniform float name < ui_type = "slider"; ui_label = label; ui_tooltip = "How much audio affects " label "."; ui_min = 0.0; ui_max = maxValue; ui_step = 0.01; ui_category = AS_CAT_AUDIO; > = defaultValue;

// --- Background Color ---
// Standard background color picker for effects that replace the scene
#define AS_BACKGROUND_COLOR_UI(name, defaultColor, category) \
uniform float3 name < ui_type = "color"; ui_label = "Background Color"; ui_tooltip = "Base background color when the effect does not fully cover the screen."; ui_category = category; > = defaultColor;

// --- Palette Color Mode & Cycling ---
// Toggle between mathematical coloring and palette coloring
#define AS_USE_PALETTE_UI(name, category) \
uniform bool name < ui_label = "Use Palette Coloring"; ui_tooltip = "When enabled, uses palette colors instead of mathematical coloring."; ui_category = category; > = false;

// Standard color cycle speed slider for palette-based effects
#define AS_COLOR_CYCLE_UI(name, category) \
uniform float name < ui_type = "slider"; ui_label = "Color Cycle Speed"; ui_tooltip = "Speed of palette color cycling. Negative reverses direction. 0 = static."; ui_min = -2.0; ui_max = 2.0; ui_step = 0.1; ui_category = category; > = 0.0;

// --- Debug Mode Standardization ---
// --- Debug UI Macro ---
#define AS_DEBUG_UI(items) \
uniform int DebugMode < ui_type = "combo"; ui_label = "Debug View"; ui_tooltip = "Show various visualization modes for debugging."; ui_items = items; ui_category = AS_CAT_DEBUG; > = 0;

// --- Debug Helper Functions ---
bool AS_isDebugMode(int currentMode, int targetMode) {
    return currentMode == targetMode;
}

// Standard "Off" value for debug modes (already defined as const int AS_DEBUG_OFF)
// #define AS_DEBUG_OFF 0 // This is redundant

// --- Sway Animation UI Standardization ---
// --- Sway UI Macros ---
#define AS_SWAYSPEED_UI(name, category) \
uniform float name < ui_type = "slider"; ui_label = "Sway Speed"; ui_tooltip = "Controls the speed of the swaying animation"; ui_min = 0.0; ui_max = 5.0; ui_step = 0.01; ui_category = category; > = 1.0;

#define AS_SWAYANGLE_UI(name, category) \
uniform float name < ui_type = "slider"; ui_label = "Sway Angle"; ui_tooltip = "Maximum angle of the swaying in degrees"; ui_min = 0.0; ui_max = 180.0; ui_step = 1.0; ui_category = category; > = 15.0;

// --- Position and Scale UI Standardization ---
// --- Position Constants ---
#define AS_POSITION_MIN -1.5f
#define AS_POSITION_MAX 1.5f
#define AS_POSITION_STEP 0.01f
#define AS_POSITION_DEFAULT 0.0f

#define AS_SCALE_MIN 0.1f
#define AS_SCALE_MAX 5.0f
#define AS_SCALE_STEP 0.01f
#define AS_SCALE_DEFAULT 1.0f

// --- Position UI Macros ---
// Creates a standardized position control (as float2)
#define AS_POS_UI(name) \
uniform float2 name < ui_type = "drag"; ui_label = "Position"; ui_tooltip = "Position of the effect center (X,Y)."; ui_min = AS_POSITION_MIN; ui_max = AS_POSITION_MAX; ui_step = AS_POSITION_STEP; ui_category = AS_CAT_STAGE; > = float2(AS_POSITION_DEFAULT, AS_POSITION_DEFAULT);

// Creates a standardized scale control
#define AS_SCALE_UI(name) \
uniform float name < ui_type = "slider"; ui_label = "Scale"; ui_tooltip = "Size of the effect. Higher values zoom out, lower values zoom in."; ui_min = AS_SCALE_MIN; ui_max = AS_SCALE_MAX; ui_step = AS_SCALE_STEP; ui_category = AS_CAT_STAGE; > = AS_SCALE_DEFAULT;

// Combined position and scale UI for convenience
#define AS_POSITION_SCALE_UI(posName, scaleName) \
uniform float2 posName < ui_type = "drag"; ui_label = "Position"; ui_tooltip = "Position of the effect center (X,Y)."; ui_min = AS_POSITION_MIN; ui_max = AS_POSITION_MAX; ui_step = AS_POSITION_STEP; ui_category = AS_CAT_STAGE; > = float2(AS_POSITION_DEFAULT, AS_POSITION_DEFAULT); \
uniform float scaleName < ui_type = "slider"; ui_label = "Scale"; ui_tooltip = "Size of the effect. Higher values zoom out, lower values zoom in."; ui_min = AS_SCALE_MIN; ui_max = AS_SCALE_MAX; ui_step = AS_SCALE_STEP; ui_category = AS_CAT_STAGE; > = AS_SCALE_DEFAULT;

// --- Position Helper Functions ---
/**
 * Applies position offset and scale to centered coordinates.
 * coord: Centered coordinate (0,0 = screen center).
 * pos: Position offset. X moves right, Y moves UP (inverted from screen space).
 * scale: Zoom factor. Values > 1.0 zoom out, < 1.0 zoom in. Clamped to AS_EPSILON minimum.
 * Returns the transformed coordinate.
 */
float2 AS_applyPositionAndScale(float2 coord, float2 pos, float scale) {
    coord.x -= pos.x;
    coord.y += pos.y; 
    return coord / max(scale, AS_EPSILON); 
}

/**
 * Converts normalized UV coordinates [0,1] to centered coordinates with aspect ratio correction.
 * texcoord: Input UV in [0,1] range.
 * aspectRatio: Screen aspect ratio (width/height). Use ReShade::AspectRatio.
 * Returns centered coordinates where (0,0) is screen center, corrected so circles remain circular.
 */
float2 AS_centeredUVWithAspect(float2 texcoord, float aspectRatio) {
    float2 centered = texcoord - 0.5;
    if (aspectRatio >= 1.0) {
        centered.x *= aspectRatio;
    } else {
        centered.y /= aspectRatio;
    }
    return centered;
}

// All-in-one UV transform: center + position/scale + optional rotation (radians)
float2 AS_transformUVCentered(float2 texcoord, float2 pos, float scale, float rotation) {
    float aspectRatio = ReShade::AspectRatio;
    float2 centered = AS_centeredUVWithAspect(texcoord, aspectRatio);
    float2 positioned = AS_applyPositionAndScale(centered, pos, scale);
    if (abs(rotation) > AS_EPSILON) {
        float s = sin(rotation);
        float c = cos(rotation);
        positioned = float2(
            positioned.x * c - positioned.y * s,
            positioned.x * s + positioned.y * c
        );
    }
    return positioned;
}

/**
 * Rotates a 2D point around the origin.
 * p: The float2 point to rotate.
 * a: The angle of rotation in radians.
 * Returns the rotated float2 point.
 */
float2 AS_rotate2D(float2 p, float a)
{
    float s = sin(a);
    float c = cos(a);
    return float2(
        p.x * c - p.y * s,
        p.x * s + p.y * c
    );
}

// DEPRECATED: Use AS_rotate2D() directly. Will be removed in v2.0.
float2 AS_applyRotation(float2 coord, float rotation)
{ return AS_rotate2D(coord, rotation);}

// Build a 2x2 rotation matrix (radians)
float2x2 AS_rot2x2(float radians)
{
    float s = sin(radians);
    float c = cos(radians);
    return float2x2(c, s, -s, c);
}

// Compute polar angle (atan2) and radius from texcoord using aspect-corrected centered space
// Returns float2(angleRadians, radius)
float2 AS_polarAngleRadius(float2 texcoord, float aspectRatio)
{
    float2 p = AS_centeredUVWithAspect(texcoord, aspectRatio);
    return float2(atan2(p.y, p.x), length(p));
}

// Apply simple screen-space dithering using a hash pattern; strength is in [0,2] approx.
float3 AS_applyDither(float3 rgb, float2 texcoord, float strength)
{
    if (strength <= AS_EPSILON) return rgb;
    // Local lightweight hash to avoid cross-header dependency
    float2 p = texcoord * ReShade::ScreenSize.xy * 0.25f;
    float n = frac(sin(dot(p, float2(12.9898f, 78.233f))) * 43758.5453f);
    float adj = (n - 0.5f) * (strength * AS_INV_255);
    return saturate(rgb + adj);
}

/**
 * Generates a radial spotlight falloff mask.
 * centeredAspectUV: Aspect-corrected centered coordinates (from AS_centeredUVWithAspect).
 * intensity: Peak brightness at center. Higher values = brighter, wider coverage.
 * radius: Falloff rate. Higher values = tighter, more focused spot.
 * Returns a value >= 0 representing light intensity (can exceed 1.0 for HDR).
 */
float AS_spotlightMask(float2 centeredAspectUV, float intensity, float radius)
{
    return max(intensity - length(centeredAspectUV) * max(radius, AS_EPSILON), 0.0);
}

// Simple radial vignette mask in [0,1], power controls hardness
float AS_vignetteMask(float2 texcoord, float power)
{
    float2 p = texcoord - 0.5;
    float r = length(p) / AS_INV_SQRT_TWO; // normalize to roughly [0,1] at corners
    return pow(saturate(1.0 - r), max(0.1f, power));
}

// Depth check helper: returns true if the scene is behind the effect plane
bool AS_isSceneBehind(float2 texcoord, float effectDepth)
{
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    return sceneDepth >= effectDepth - AS_DEPTH_EPSILON;
}

/**
 * Returns true if the scene pixel is IN FRONT of the effect's stage depth plane.
 * When true, the effect should be skipped (early return the original color).
 * Usage: if (AS_isInFrontOfStage(texcoord, StageDepth)) return originalColor;
 */
bool AS_isInFrontOfStage(float2 texcoord, float stageDepth)
{
    return ReShade::GetLinearizedDepth(texcoord) < stageDepth - AS_DEPTH_EPSILON;
}

// Signed distance to axis-aligned box of half-size s at origin
float AS_sdfBox(float3 p, float3 s)
{
    p = abs(p) - s;
    return max(p.x, max(p.y, p.z));
}

// --- Math Helpers ---
/**
 * Safe modulo that handles negative values correctly (always returns positive result).
 * Unlike HLSL fmod() which preserves the sign of x, this always wraps into [0, y).
 * Returns x if y is near zero (division-by-zero safe).
 */
float AS_mod(float x, float y) {
    if (abs(y) < AS_EPSILON) return x;
    return x - y * floor(x / y);
}

// Avoid shadowing HLSL's fmod intrinsic — prefer AS_mod directly

/**
 * Creates a depth-based mask that fades from 1.0 (near) to 0.0 (far).
 * depth: Linearized scene depth at current pixel.
 * nearPlane: Depth where mask starts (full intensity = 1.0).
 * farPlane: Depth where mask ends (zero intensity = 0.0).
 * curve: Falloff curve exponent. >1.0 = sharper falloff, <1.0 = softer falloff.
 * Returns mask value in [0, 1].
 */
float AS_depthMask(float depth, float nearPlane, float farPlane, float curve)
{
    float d = saturate((depth - nearPlane) / max(farPlane - nearPlane, AS_EPSILON));
    d = pow(d, max(curve, 0.0001f));
    return 1.0f - d;
}

// ============================================================================
// VISUAL EFFECTS & BLEND MODES
// ============================================================================

// --- Blend Functions ---
// Blend helpers — explicit foreground-over-background naming to avoid confusion
// Foreground-over-background RGB blend (no opacity handling)
float3 AS_blendRgbFgOverBg(float3 fgColor, float3 bgColor, int blendMode) {
    // Assuming ComHeaders::Blending::Blend is available from Blending.fxh
    // The Blend function in Blending.fxh is:
    // float3 Blend(const int type, const float3 backdrop, const float3 source, const float opacity = 1.0)
    return ComHeaders::Blending::Blend(blendMode, bgColor, fgColor, 1.0).rgb; 
}

// Foreground-over-background RGBA blend (with opacity)
float4 AS_blendFgOverBg(float4 fgColor, float4 bgColor, int blendMode, float blendOpacity) {
    float3 effect_rgb = AS_blendRgbFgOverBg(fgColor.rgb, bgColor.rgb, blendMode);
    float final_opacity = saturate(fgColor.a * blendOpacity);
    float3 final_rgb = lerp(bgColor.rgb, effect_rgb, final_opacity);
    return float4(final_rgb, bgColor.a); 
}

// Semantic aliases (clear entry points)
float3 AS_blendRGB(float3 fgRgb, float3 bgRgb, int mode) { return AS_blendRgbFgOverBg(fgRgb, bgRgb, mode); }
float4 AS_blendRGBA(float4 fgRgba, float4 bgRgba, int mode, float opacity) { return AS_blendFgOverBg(fgRgba, bgRgba, mode, opacity); }

// Back-compat shim for existing call sites that use AS_applyBlend in both RGB and RGBA forms
// (Deprecated) AS_applyBlend shims removed after migration to AS_blendRGB / AS_blendRGBA

// --- Composite Helpers ---
/**
 * Blends effect color over background using the specified blend mode and strength.
 * Combines AS_blendRGB + lerp in a single call.
 * effectRgb: Foreground effect color.
 * bgRgb: Background scene color.
 * blendMode: Blend mode index (see AS_BLEND_* constants).
 * blendAmount: Mix strength in [0, 1]. 0.0 = no effect, 1.0 = full effect.
 * Returns the composited RGB color.
 */
float3 AS_composite(float3 effectRgb, float3 bgRgb, int blendMode, float blendAmount) {
    float3 blended = AS_blendRGB(effectRgb, bgRgb, blendMode);
    return lerp(bgRgb, blended, blendAmount);
}

/** RGBA variant of AS_composite. Preserves background alpha. */
float4 AS_compositeRGBA(float3 effectRgb, float4 bgRgba, int blendMode, float blendAmount) {
    return float4(AS_composite(effectRgb, bgRgba.rgb, blendMode, blendAmount), bgRgba.a);
}

// ============================================================================
// COLOR ADJUSTMENT HELPERS
// ============================================================================

/**
 * Adjusts color saturation using Rec.709 luminance weights.
 * saturation: 0.0 = grayscale, 1.0 = original, >1.0 = oversaturated.
 */
float3 AS_adjustSaturation(float3 color, float saturation) {
    float luma = dot(color, AS_LUMA_REC709);
    return lerp(float3(luma, luma, luma), color, saturation);
}

/** Converts sRGB color to linear space. */
float3 AS_srgbToLinear(float3 c) { return pow(abs(c), AS_GAMMA_SRGB); }

/** Converts linear color to sRGB space. */
float3 AS_linearToSrgb(float3 c) { return pow(abs(c), 1.0 / AS_GAMMA_SRGB); }

// ============================================================================
// ANTI-ALIASED EDGE HELPERS
// ============================================================================

/**
 * Smooth anti-aliased edge transition.
 * Returns 1.0 when dist < edge-aa, 0.0 when dist > edge+aa, smooth transition between.
 * dist: Distance value to test.
 * edge: Edge position (threshold).
 * aa: Anti-aliasing width (half-width of the transition zone).
 */
float AS_smoothEdge(float dist, float edge, float aa) {
    return smoothstep(edge + aa, edge - aa, dist);
}

// ============================================================================
// DEPTH EARLY-RETURN MACRO
// ============================================================================
// Reads the back buffer and returns early if the pixel is in front of the stage depth.
// Usage: Place at the top of your pixel shader. After this macro, _as_originalColor
// is available as a float4 containing the original scene color.
//
//   AS_DEPTH_EARLY_RETURN(texcoord, EffectDepth)
//   // ... rest of pixel shader can use _as_originalColor ...
//
#define AS_DEPTH_EARLY_RETURN(tc, depthUniform) \
    float4 _as_originalColor = tex2D(ReShade::BackBuffer, tc); \
    if (AS_isInFrontOfStage(tc, depthUniform)) return _as_originalColor;

// ============================================================================
// PALETTE COLOR FETCH MACRO
// ============================================================================
// Fetches an interpolated color from either the custom palette or a preset palette.
// Eliminates the repeated if (palette == AS_PALETTE_CUSTOM) pattern.
//   prefix: Shader-specific prefix for custom palette uniforms (e.g., BlueCorona_)
//   paletteUniform: The int uniform holding the palette selection
//   t: Interpolation parameter [0, 1]
//
#define AS_GET_PALETTE_COLOR(prefix, paletteUniform, t) \
    ((paletteUniform == AS_PALETTE_CUSTOM) \
        ? AS_GET_INTERPOLATED_CUSTOM_COLOR(prefix, t) \
        : AS_getInterpolatedColor(paletteUniform, t))

float3 AS_paletteLerp(float3 c0, float3 c1, float t) {
    return lerp(c0, c1, t);
}

// ============================================================================
// MATRIX & VECTOR MULTIPLICATION HELPERS (Use if intrinsic 'mul' causes issues)
// ============================================================================
float2 AS_mul_float2x2_float2(float2x2 M, float2 v)
{
    return float2( M[0][0] * v.x + M[1][0] * v.y, M[0][1] * v.x + M[1][1] * v.y );
}

float2 AS_mul_float2_float2x2(float2 v, float2x2 M)
{
    return float2( v.x * M[0][0] + v.y * M[0][1], v.x * M[1][0] + v.y * M[1][1] );
}

float2x2 AS_mul_float2x2_float2x2(float2x2 A, float2x2 B)
{
    float2x2 C;
    C[0][0] = A[0][0] * B[0][0] + A[1][0] * B[0][1];
    C[0][1] = A[0][1] * B[0][0] + A[1][1] * B[0][1];
    C[1][0] = A[0][0] * B[1][0] + A[1][0] * B[1][1];
    C[1][1] = A[0][1] * B[1][0] + A[1][1] * B[1][1];
    return C;
}

// ============================================================================
// AUDIO REACTIVITY FUNCTIONS
// ============================================================================

// --- Time Functions ---
uniform int frameCount < source = "framecount"; >; 

// Returns elapsed time in seconds, preferring Listeningway clocks when available
float AS_timeSeconds() {
#if defined(__LISTENINGWAY_INSTALLED)
    if (Listeningway_TotalPhases120Hz > AS_EPSILON) {
        return Listeningway_TotalPhases120Hz * (1.0f / 120.0f); 
    }
    else if (Listeningway_TimeSeconds > AS_EPSILON) {
        return Listeningway_TimeSeconds;
    }
#endif
    return float(frameCount) * (1.0f / 60.0f);
}

// DEPRECATED: Use AS_timeSeconds() directly. Will be removed in v2.0.
float AS_getTime() { return AS_timeSeconds(); }

// --- Listeningway Helpers ---
int AS_getFreqBands() {
#if defined(__LISTENINGWAY_INSTALLED) && defined(LISTENINGWAY_NUM_BANDS)
    return LISTENINGWAY_NUM_BANDS;
#else
    return AS_DEFAULT_NUM_BANDS;
#endif
}

float AS_getFreq(int index) {
#if defined(__LISTENINGWAY_INSTALLED)
    int numBands = AS_getFreqBands();
    int safeIndex = clamp(index, 0, numBands - 1);
    return Listeningway_FreqBands[safeIndex];
#else
    return 0.0;
#endif
}

int AS_mapAngleToBand(float angleRadians, int repetitions) {
    float normalizedAngle = AS_mod(angleRadians, AS_TWO_PI) / AS_TWO_PI;
    int numBands = AS_getFreqBands();
    if (numBands <= 0) return 0; 
    int totalBands = numBands * max(1, repetitions); 
    int bandIdx = int(floor(normalizedAngle * totalBands)) % numBands;
    return bandIdx;
}

float AS_getVU(int source) {
#if defined(__LISTENINGWAY_INSTALLED)
    if (source == 0) return Listeningway_Volume;
    if (source == 1) return Listeningway_Beat;
    if (source == 2) return Listeningway_FreqBands[0]; // Bass - first band
    if (source == 3) return Listeningway_FreqBands[min(LISTENINGWAY_NUM_BANDS / 3, LISTENINGWAY_NUM_BANDS - 1)]; // Mid-bass - 1/3 through spectrum
    if (source == 4) return Listeningway_FreqBands[min((LISTENINGWAY_NUM_BANDS * 7) / 8, LISTENINGWAY_NUM_BANDS - 1)]; // Treble - 7/8 through spectrum
#endif
    return 0.0;
}

// Returns a normalized audio level for the given abstracted source
float AS_audioLevelFromSource(int source) {
    if (source == AS_AUDIO_OFF)   return 0.0;         
    if (source == AS_AUDIO_SOLID)  return 1.0;         
#if defined(__LISTENINGWAY_INSTALLED)
    if (source == AS_AUDIO_VOLUME) return Listeningway_Volume; 
    if (source == AS_AUDIO_BEAT)   return Listeningway_Beat;   

    int numBands = AS_getFreqBands();
    if (numBands <= 1 && (source == AS_AUDIO_BASS || source == AS_AUDIO_MID || source == AS_AUDIO_TREBLE)) return 0.0;

    if (source == AS_AUDIO_BASS)   return Listeningway_FreqBands[0];
    if (source == AS_AUDIO_MID)    return Listeningway_FreqBands[numBands / 2];
    if (source == AS_AUDIO_TREBLE) return Listeningway_FreqBands[numBands - 1];
    
    if (source == AS_AUDIO_VOLUME_LEFT) return Listeningway_VolumeLeft; 
    if (source == AS_AUDIO_VOLUME_RIGHT) return Listeningway_VolumeRight;
    if (source == AS_AUDIO_PAN) return (Listeningway_AudioPan + 1.0) * 0.5;
#endif
    return 0.0; 
}

// Multiplies baseValue by (1 + audioLevel * multiplier) when enabled
float AS_audioModulateMul(float baseValue, int audioSource, float multiplier, bool enableFlag) {
    if (!enableFlag || audioSource == AS_AUDIO_OFF) return baseValue;
    float audioLevel = AS_audioLevelFromSource(audioSource);
    return baseValue * (1.0 + audioLevel * multiplier);
}

// mode 0 = multiplicative (default), mode 1 = additive
float AS_audioModulate(float baseValue, int audioSource, float multiplier, bool enableFlag, int mode) {
    if (!enableFlag || audioSource == AS_AUDIO_OFF) return baseValue;
    float audioLevel = AS_audioLevelFromSource(audioSource);
    if (mode == 1) { // Additive mode
        return baseValue + (audioLevel * multiplier);
    } else { // Multiplicative mode (default)
        return baseValue * (1.0 + audioLevel * multiplier);
    }
}


// ============================================================================
// STEREO AUDIO HELPER FUNCTIONS
// ============================================================================
int AS_getAudioFormat() {
#if defined(__LISTENINGWAY_INSTALLED)
    return int(Listeningway_AudioFormat);
#else
    return 0; 
#endif
}

bool AS_isStereoAvailable() {
    return AS_getAudioFormat() >= 2;
}

bool AS_isSurroundAvailable() {
    return AS_getAudioFormat() >= 6;
}

float2 AS_getStereoBalance() {
#if defined(__LISTENINGWAY_INSTALLED)
    if (!AS_isStereoAvailable()) {
        return float2(0.5, 0.5);
    }
    float pan = Listeningway_AudioPan; 
    float leftFactor = saturate(0.5 - pan * 0.5);  
    float rightFactor = saturate(0.5 + pan * 0.5); 
    return float2(leftFactor, rightFactor);
#else
    return float2(0.5, 0.5);
#endif
}

float AS_getStereoAudioReactivity(float position, int audioSource) {
    if (audioSource == AS_AUDIO_OFF) return 0.0;
    if (!AS_isStereoAvailable()) {
        return AS_audioLevelFromSource(audioSource);
    }
#if defined(__LISTENINGWAY_INSTALLED)
    float2 stereoBalance = AS_getStereoBalance(); // This uses Listeningway_AudioPan
    float leftWeight = saturate(0.5 - position * 0.5);  
    float rightWeight = saturate(0.5 + position * 0.5); 
    
    if (audioSource == AS_AUDIO_VOLUME) 
        return Listeningway_VolumeLeft * leftWeight + Listeningway_VolumeRight * rightWeight;
    if (audioSource == AS_AUDIO_VOLUME_LEFT) 
        return Listeningway_VolumeLeft * leftWeight; 
    if (audioSource == AS_AUDIO_VOLUME_RIGHT) 
        return Listeningway_VolumeRight * rightWeight; 

    float generalAudioValue = AS_audioLevelFromSource(audioSource);

    if (audioSource == AS_AUDIO_BASS || audioSource == AS_AUDIO_MID || audioSource == AS_AUDIO_TREBLE || audioSource == AS_AUDIO_BEAT) {
         float panEffect = (position < 0) ? stereoBalance.x : stereoBalance.y; 
         if (abs(position) < AS_EPSILON) panEffect = (stereoBalance.x + stereoBalance.y) * 0.5; 
         return generalAudioValue * panEffect;
    }
    if (audioSource == AS_AUDIO_PAN) { 
         return (Listeningway_AudioPan * position + 1.0) * 0.5; 
    }
    
    return generalAudioValue; 
#else     
    return AS_audioLevelFromSource(audioSource);
#endif
}

/**
 * Converts the Listeningway audio pan value to a direction in radians.
 * -1.0 pan (full left) maps to -PI/2 radians (-90 degrees).
 * 0.0 pan (center) maps to 0 radians (0 degrees).
 * +1.0 pan (full right) maps to +PI/2 radians (+90 degrees).
 * Returns the audio direction in radians.
 */
float AS_getAudioDirectionRadians() {
#if defined(__LISTENINGWAY_INSTALLED)
    // Listeningway_AudioPan ranges from -1.0 (left) to +1.0 (right)
    // Multiplying by AS_HALF_PI maps this to -PI/2 to +PI/2
    return Listeningway_AudioPan * AS_HALF_PI;
#else
    // If Listeningway is not installed, the fallback definition for Listeningway_AudioPan is 0.0f.
    // So, 0.0 * AS_HALF_PI = 0.0, which is correct for no pan information.
    return 0.0f; 
#endif
}

// ============================================================================
// STEREO UI STANDARDIZATION
// ============================================================================
#define AS_AUDIO_STEREO_UI(name, label, defaultSource, category) \
uniform int name < ui_type = "combo"; ui_label = label; ui_items = AS_AUDIO_SOURCE_ITEMS; ui_tooltip = "Audio source for reactivity. Stereo options available when stereo audio detected."; ui_category = category; > = defaultSource;

#define AS_STEREO_POSITION_UI(name, category) \
uniform float name < ui_type = "slider"; ui_label = "Stereo Position"; ui_tooltip = "Stereo position for audio reactivity (-1.0 = left, 0.0 = center, 1.0 = right). Only effective with stereo audio."; ui_min = -1.0; ui_max = 1.0; ui_step = 0.01; ui_category = category; > = 0.0;

#define AS_AUDIO_STEREO_FULL_UI(sourceName, posName, multName, label, defaultSource, category) \
uniform int sourceName < ui_type = "combo"; ui_label = label " Source"; ui_items = AS_AUDIO_SOURCE_ITEMS; ui_tooltip = "Audio source for reactivity. Stereo options available when stereo audio detected."; ui_category = category; > = defaultSource; \
uniform float posName < ui_type = "slider"; ui_label = label " Stereo Position"; ui_tooltip = "Stereo position for audio reactivity (-1.0 = left, 0.0 = center, 1.0 = right). Only effective with stereo audio."; ui_min = -1.0; ui_max = 1.0; ui_step = 0.01; ui_category = category; > = 0.0; \
uniform float multName < ui_type = "slider"; ui_label = label " Multiplier"; ui_tooltip = "Controls how much the selected audio source affects this parameter."; ui_min = 0.0; ui_max = 2.0; ui_step = 0.05; ui_category = category; > = 1.0;

// ============================================================================
// ENHANCED AUDIO HELPER FUNCTIONS
// ============================================================================
float AS_audioModulateMulStereo(float baseValue, int audioSource, float multiplier, float stereoPosition, bool enableFlag) {
    if (!enableFlag || audioSource == AS_AUDIO_OFF) return baseValue;
    float audioLevel = AS_getStereoAudioReactivity(stereoPosition, audioSource);
    return baseValue * (1.0 + audioLevel * multiplier);
}

float AS_getAudioSourceSafe(int source, float fallbackValue = 0.0) {
#if defined(__LISTENINGWAY_INSTALLED)
    if (Listeningway_TotalPhases120Hz > AS_EPSILON || Listeningway_Volume > AS_EPSILON || Listeningway_AudioFormat > 0) { 
    return AS_audioLevelFromSource(source);
    }
#endif
    return (source == AS_AUDIO_SOLID) ? 1.0 : fallbackValue;
}

// DEPRECATED: AS_getSmoothedAudio - Removed due to static variable causing crashes
// Static variables in shaders can cause race conditions and crashes when accessed by multiple pixels
// Use external smoothing or implement per-frame smoothing outside of pixel shaders instead
// 
// float AS_getSmoothedAudio(int source, float smoothing = 0.1) {
//     // DO NOT USE: static variables are unsafe in pixel shaders
//     return AS_getAudioSourceSafe(source); 
// }

float AS_getFreqByPercent(float percent) {
#if defined(__LISTENINGWAY_INSTALLED)
    int numBands = AS_getFreqBands();
    if (numBands <= 1) return 0.0;
    int bandIndex = int(saturate(percent) * (numBands - 1));
    return Listeningway_FreqBands[bandIndex];
#else
    return 0.0;
#endif
}


// ============================================================================
// AUDIO DEBUG HELPERS
// ============================================================================
float4 AS_debugAudio(float2 texcoord, int debugMode) {
    if (debugMode != AS_DEBUG_AUDIO) return float4(0, 0, 0, 0); 
#if defined(__LISTENINGWAY_INSTALLED)
    float3 debugColor = float3(0, 0, 0);
    if (texcoord.x < 0.2 && texcoord.y < 0.1) {
        int format = AS_getAudioFormat();
        if (format == 0) debugColor = float3(1, 0, 0);      
        else if (format == 1) debugColor = float3(1, 1, 0); 
        else if (format == 2) debugColor = float3(0, 1, 0); 
        else debugColor = float3(0, 0, 1);                  
    }
    
    int numBands = AS_getFreqBands();
    if (numBands > 0 && texcoord.y > 0.2 && texcoord.y < 0.8) { 
        float bandWidth = 1.0 / numBands;
        int currentBand = int(texcoord.x / bandWidth);
        if (currentBand < numBands) {
            float bandValue = Listeningway_FreqBands[currentBand];
            if ((1.0 - texcoord.y) < bandValue * 0.6 + 0.2) { 
                 float hue = float(currentBand) / max(1,numBands-1); 
                 if (hue < 0.333) debugColor = float3(1.0 - hue * 3.0, hue * 3.0, 0);
                 else if (hue < 0.666) debugColor = float3(0, 1.0 - (hue - 0.333) * 3.0, (hue - 0.333) * 3.0);
                 else debugColor = float3((hue - 0.666) * 3.0, 0, 1.0 - (hue - 0.666) * 3.0);
            }
        }
    }
    
    if (AS_isStereoAvailable() && texcoord.y > 0.85) {
        float2 stereoBalance = AS_getStereoBalance();
        if (texcoord.x < 0.45) { 
            debugColor = float3(stereoBalance.x, stereoBalance.x * 0.5, 0); 
        } else if (texcoord.x > 0.55) { 
            debugColor = float3(0, stereoBalance.y * 0.5, stereoBalance.y); 
        } else { 
            float panNorm = (Listeningway_AudioPan + 1.0) * 0.5; 
            debugColor = float3(panNorm, panNorm, panNorm); 
        }
    }
    return float4(debugColor, 1.0);
#else
    if (texcoord.x > 0.4 && texcoord.x < 0.6 && texcoord.y > 0.4 && texcoord.y < 0.6)
      return float4(0.5, 0.2, 0.2, 1.0); 
    return float4(0.0, 0.0, 0.0, 0.0); 
#endif
}


// ============================================================================
// MATH & COORDINATE HELPERS (Continued from above, standard ones)
// ============================================================================

// --- Rotation UI Standardization ---
#define AS_ROTATION_UI(snapName, fineName) \
uniform int snapName < ui_category = AS_CAT_STAGE; ui_label = "Snap Rotation"; ui_type = "slider"; ui_min = -4; ui_max = 4; ui_step = 1; ui_tooltip = "Snap rotation in 45° steps (-180° to +180°)"; ui_spacing = 0; > = 0; \
uniform float fineName < ui_category = AS_CAT_STAGE; ui_label = "Fine Rotation"; ui_type = "slider"; ui_min = -45.0; ui_max = 45.0; ui_step = 0.1; ui_tooltip = "Fine rotation adjustment in degrees"; ui_same_line = true; > = 0.0;

static const float AS_SNAP_ROTATION_DEGREES = 45.0f; // Degrees per snap rotation step

float AS_getRotationRadians(int snapRotation, float fineRotation) {
    float snapAngle = float(snapRotation) * AS_SNAP_ROTATION_DEGREES;
    return (snapAngle + fineRotation) * AS_DEGREES_TO_RADIANS;
}

// --- Animation UI Standardization ---
#define AS_ANIMATION_SPEED_MIN 0.0
#define AS_ANIMATION_SPEED_MAX 5.0
#define AS_ANIMATION_SPEED_STEP 0.01
#define AS_ANIMATION_SPEED_DEFAULT 1.0

#define AS_ANIMATION_KEYFRAME_MIN 0.0
#define AS_ANIMATION_KEYFRAME_MAX 100.0 
#define AS_ANIMATION_KEYFRAME_STEP 0.1
#define AS_ANIMATION_KEYFRAME_DEFAULT 0.0

#define AS_ANIMATION_SPEED_UI(name, category) \
uniform float name < ui_type = "slider"; ui_label = "Animation Speed"; ui_tooltip = "Controls the overall animation speed of the effect. Set to 0 to pause animation."; ui_min = AS_ANIMATION_SPEED_MIN; ui_max = AS_ANIMATION_SPEED_MAX; ui_step = AS_ANIMATION_SPEED_STEP; ui_category = category; > = AS_ANIMATION_SPEED_DEFAULT;

#define AS_ANIMATION_KEYFRAME_UI(name, category) \
uniform float name < ui_type = "slider"; ui_label = "Animation Keyframe"; ui_tooltip = "Sets a specific point in time for the animation. Useful for finding and saving specific patterns."; ui_min = AS_ANIMATION_KEYFRAME_MIN; ui_max = AS_ANIMATION_KEYFRAME_MAX; ui_step = AS_ANIMATION_KEYFRAME_STEP; ui_category = category; > = AS_ANIMATION_KEYFRAME_DEFAULT;

#define AS_ANIMATION_UI(speedName, keyframeName, category) \
uniform float speedName < ui_type = "slider"; ui_label = "Animation Speed"; ui_tooltip = "Controls the overall animation speed of the effect. Set to 0 to pause animation."; ui_min = AS_ANIMATION_SPEED_MIN; ui_max = AS_ANIMATION_SPEED_MAX; ui_step = AS_ANIMATION_SPEED_STEP; ui_category = category; > = AS_ANIMATION_SPEED_DEFAULT; \
uniform float keyframeName < ui_type = "slider"; ui_label = "Animation Keyframe"; ui_tooltip = "Sets a specific point in time for the animation. Useful for finding and saving specific patterns."; ui_min = AS_ANIMATION_KEYFRAME_MIN; ui_max = AS_ANIMATION_KEYFRAME_MAX; ui_step = AS_ANIMATION_KEYFRAME_STEP; ui_category = category; > = AS_ANIMATION_KEYFRAME_DEFAULT;

float AS_getAnimationTime(float speed, float keyframe) {
    if (abs(speed) < AS_EPSILON) { 
        return keyframe;
    }
    return (AS_timeSeconds() * speed) + keyframe;
}

float2 AS_aspectCorrect(float2 uv, float width, float height) { // Corrected parameter name
    if (abs(height) < AS_EPSILON) return uv; 
    float aspect = width / height; 
    return float2((uv.x - 0.5) * aspect + 0.5, uv.y); 
}

float2 AS_aspectCorrectUV(float2 uv, float aspectRatio) {
    float2 centered_uv = uv - 0.5;
    centered_uv.x *= aspectRatio;
    return centered_uv + 0.5; 
}

float AS_radians(float deg) {
    return deg * AS_DEGREES_TO_RADIANS;
}

float AS_degrees(float rad) {
    return rad * AS_RADIANS_TO_DEGREES;
}

float2 AS_rescaleToScreen(float2 uv) {
    return uv * ReShade::ScreenSize.xy;
}

// ============================================================================
// BACK-COMPAT SHIMS (Legacy function aliases)
// ----------------------------------------------------------------------------
// Many existing shaders refer to legacy helper names. These aliases map them to
// the newer centralized implementations to preserve backward compatibility.
// ============================================================================

// DEPRECATED: Use AS_audioModulate() directly. Will be removed in v2.0.
float AS_applyAudioReactivity(float baseValue, int audioSource, float multiplier, bool enableFlag)
{
    return AS_audioModulate(baseValue, audioSource, multiplier, enableFlag, 0);
}

// DEPRECATED: Use AS_audioModulate() directly. Will be removed in v2.0.
float AS_applyAudioReactivityEx(float baseValue, int audioSource, float multiplier, bool enableFlag, int mode)
{
    return AS_audioModulate(baseValue, audioSource, multiplier, enableFlag, mode);
}

// DEPRECATED: Use AS_audioLevelFromSource() directly. Will be removed in v2.0.
float AS_getAudioSource(int source)
{
    return AS_audioLevelFromSource(source);
}

// DEPRECATED: Use AS_transformUVCentered() directly. Will be removed in v2.0.
float2 AS_transformCoord(float2 texcoord, float2 pos, float scale, float rotation)
{
    return AS_transformUVCentered(texcoord, pos, scale, rotation);
}

// DEPRECATED: Use AS_applyPositionAndScale() directly. Will be removed in v2.0.
float2 AS_applyPosScale(float2 coord, float2 pos, float scale)
{
    return AS_applyPositionAndScale(coord, pos, scale);
}

// (Removed) Legacy EPSILON macro alias and legacy rot_hlsl/box_hlsl helpers

// ============================================================================
// DEPTH, SURFACE & VISUAL EFFECTS
// ============================================================================
float AS_depthFalloffMask(float depth, float nearPlane, float farPlane, float curve) {
    farPlane = max(nearPlane + AS_EPS_SAFE, farPlane); 
    float mask = smoothstep(nearPlane, farPlane, depth);
    return 1.0 - pow(mask, max(0.1f, curve)); 
}

float3 AS_normalFromDepth(float2 texcoord) {
    float depth = ReShade::GetLinearizedDepth(texcoord);
    float px = max(abs(ReShade::PixelSize.x), AS_EPSILON);
    float py = max(abs(ReShade::PixelSize.y), AS_EPSILON);

    float depthX1 = ReShade::GetLinearizedDepth(texcoord + float2(px, 0.0));
    float depthY1 = ReShade::GetLinearizedDepth(texcoord + float2(0.0, py));
    
    float3 dx = float3(px, 0.0, depthX1 - depth);
    float3 dy = float3(0.0, py, depthY1 - depth);
    return normalize(cross(dy, dx)); 
}

float AS_fresnelTerm(float3 normal, float3 viewDir, float power) {
    normal = normalize(normal); 
    viewDir = normalize(viewDir);
    return pow(1.0 - saturate(dot(normal, viewDir)), max(0.1f, power)); 
}

float AS_safeTanh(float x, float safetyThreshold = 12.0) {
    if (abs(x) <= safetyThreshold) {
        return tanh(x);
    }
    return sign(x) * (1.0f - exp(-abs(x - sign(x) * safetyThreshold)) * (1.0f - tanh(safetyThreshold * sign(x))));
}

float2 AS_safeTanh(float2 x, float safetyThreshold = 12.0) { return float2(AS_safeTanh(x.x, safetyThreshold), AS_safeTanh(x.y, safetyThreshold)); }
float3 AS_safeTanh(float3 x, float safetyThreshold = 12.0) { return float3(AS_safeTanh(x.x, safetyThreshold), AS_safeTanh(x.y, safetyThreshold), AS_safeTanh(x.z, safetyThreshold)); }
float4 AS_safeTanh(float4 x, float safetyThreshold = 12.0) { return float4(AS_safeTanh(x.x, safetyThreshold), AS_safeTanh(x.y, safetyThreshold), AS_safeTanh(x.z, safetyThreshold), AS_safeTanh(x.w, safetyThreshold)); }

float AS_fadeInOut(float cycle, float fadeInEnd, float fadeOutStart) {
    fadeInEnd = saturate(fadeInEnd);
    fadeOutStart = saturate(fadeOutStart);
    if (fadeInEnd >= fadeOutStart) return (cycle < 0.5) ? smoothstep(0.0, 0.5, cycle) * 2.0 : (1.0 - smoothstep(0.5, 1.0, cycle)) * 2.0;

    float brightness = 1.0;
    if (cycle < fadeInEnd) {
        brightness = smoothstep(0.0, fadeInEnd, cycle);
    } else if (cycle > fadeOutStart) {
        brightness = 1.0 - smoothstep(fadeOutStart, 1.0, cycle);
    }
    return brightness;
}

float AS_applySway(float swayAngle, float swaySpeed) {
    float time = AS_timeSeconds();
    float swayPhase = time * swaySpeed;
    return AS_radians(swayAngle) * sin(swayPhase);
}

float AS_applyAudioSway(float swayAngle, float swaySpeed, int audioSource, float audioMult) {
    float time = AS_timeSeconds();
    float audioLevel = AS_getAudioSourceSafe(audioSource); 
    float reactiveAngle = swayAngle * (1.0 + audioLevel * audioMult);
    float swayPhase = time * swaySpeed;
    return AS_radians(reactiveAngle) * sin(swayPhase);
}

float4 AS_debugOutput(int mode, float4 orig, float4 value1, float4 value2, float4 value3) {
    if (mode == 1) return value1; 
    if (mode == 2) return value2; 
    if (mode == 3) return value3; 
    return orig; 
}

float AS_starShapeMask(float2 p, float size, float points, float angle) {
    float2 uv = p / max(size, AS_EPS_SAFE); 
    float a = atan2(uv.y, uv.x) + AS_radians(angle); 
    float r = length(uv); 
    float f = cos(a * points) * 0.5 + 0.5; 
    return 1.0 - smoothstep(f, f + AS_EDGE_AA, r); 
}

// ============================================================================
// STAGE DEPTH & BLEND UI HELPERS
// ============================================================================
#define AS_STAGEDEPTH_UI(name) \
uniform float name < ui_type = "slider"; ui_label = "Effect Depth"; ui_tooltip = "Controls how far back the stage effect appears (Linear Depth 0-1)."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = AS_CAT_STAGE; > = 0.05;

#define AS_BLENDMODE_UI_DEFAULT(name, defaultMode) \
BLENDING_COMBO(name, "Mode", "Select how the effect will mix with the background.", AS_CAT_FINAL, false, 0, defaultMode)

#define AS_BLENDMODE_UI(name) \
    AS_BLENDMODE_UI_DEFAULT(name, 0)

#define AS_BLENDAMOUNT_UI(name) \
uniform float name < ui_type = "slider"; ui_label = "Strength"; ui_tooltip = "Controls the overall intensity/opacity of the effect blend."; ui_min = 0.0; ui_max = 1.0; ui_category = AS_CAT_FINAL; > = 1.0;

// ============================================================================
// TEXTURE & SAMPLER CREATION
// ============================================================================
#define AS_CREATE_TEXTURE(TEXTURE_NAME, SIZE_XY, FORMAT_TYPE, MIP_LEVELS) \
    texture2D TEXTURE_NAME { Width = SIZE_XY.x; Height = SIZE_XY.y; Format = FORMAT_TYPE; MipLevels = MIP_LEVELS; };

#define AS_CREATE_SAMPLER(SAMPLER_NAME, TEXTURE_RESOURCE, FILTER_TYPE, ADDRESS_MODE) \
    sampler2D SAMPLER_NAME { Texture = TEXTURE_RESOURCE; MagFilter = FILTER_TYPE; MinFilter = FILTER_TYPE; MipFilter = FILTER_TYPE; AddressU = ADDRESS_MODE; AddressV = ADDRESS_MODE; };

#define AS_CREATE_TEX_SAMPLER(TEXTURE_NAME, SAMPLER_NAME, SIZE_XY, FORMAT_TYPE, MIP_LEVELS, FILTER_TYPE, ADDRESS_MODE) \
    texture2D TEXTURE_NAME { Width = SIZE_XY.x; Height = SIZE_XY.y; Format = FORMAT_TYPE; MipLevels = MIP_LEVELS; }; \
    sampler2D SAMPLER_NAME { Texture = TEXTURE_NAME; MagFilter = FILTER_TYPE; MinFilter = FILTER_TYPE; MipFilter = FILTER_TYPE; AddressU = ADDRESS_MODE; AddressV = ADDRESS_MODE; };

#endif // __AS_Utils_1_fxh