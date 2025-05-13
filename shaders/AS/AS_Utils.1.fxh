/**
 * AS_Utils.1.fxh - Common Utility Functions for AS StageFX Shader Collection
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * This header file provides common utility functions used across the AS StageFX
 * shader collection. It includes blend modes, audio processing, mathematical helpers,
 * and various convenience functions to maintain consistency across shaders.
 *
 * FEATURES:
 * - Standardized UI controls for consistent user interfaces
 * - Listeningway audio integration with standard sources and controls
 * - Debug visualization tools and helpers
 * - Common blend modes and mixing functions
 * - Mathematical and coordinate transformation helpers
 * - Depth, normal reconstruction, and surface effects functions
 *
 * IMPLEMENTATION OVERVIEW:
 * This file is organized in sections:
 * 1. UI standardization macros for consistent parameter layouts
 * 2. Audio integration and Listeningway support
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

// ============================================================================
// MATH CONSTANTS
// ============================================================================
// --- Math Constants ---
// Standard mathematical constants for consistent use across all shaders
#ifndef __AS_MATH_CONSTANTS
#define __AS_MATH_CONSTANTS
// Core mathematical constants
static const float AS_PI = 3.14159265359;
static const float AS_TWO_PI = 6.28318530718;
static const float AS_HALF_PI = 1.57079632679;
static const float AS_QUARTER_PI = 0.78539816339;
static const float AS_INV_PI = 0.31830988618;
static const float AS_E = 2.71828182846;
static const float AS_GOLDEN_RATIO = 1.61803398875;

// Physics & graphics constants
static const float AS_EPSILON = 1e-6;          // Very small number to avoid division by zero
static const float AS_EPSILON_SAFE = 1e-5;     // Slightly larger epsilon for screen-space operations
static const float AS_DEGREES_TO_RADIANS = AS_PI / 180.0;
static const float AS_RADIANS_TO_DEGREES = 180.0 / AS_PI;

// Common numerical constants
static const float AS_HALF = 0.5;              // 1/2 - useful for centered coordinates
static const float AS_QUARTER = 0.25;          // 1/4
static const float AS_THIRD = 0.3333333333;    // 1/3
static const float AS_TWO_THIRDS = 0.6666666667; // 2/3
static const float AS_SQRT_TWO = 1.4142135623730950; // Square root of 2, useful for diagonal calculations

// Depth testing constants 
static const float AS_DEPTH_EPSILON = 0.0005;  // Standard depth epsilon for z-fighting prevention
static const float AS_EDGE_AA = 0.05;          // Standard anti-aliasing edge size for smoothstep
#endif // __AS_MATH_CONSTANTS

// ============================================================================
// UI STANDARDIZATION & MACROS
// ============================================================================

// --- Listeningway Integration ---
// These macros help with consistent Listeningway integration across all shaders
#ifndef __AS_LISTENINGWAY_INCLUDED
#define __AS_LISTENINGWAY_INCLUDED

// Define a complete fallback implementation for Listeningway
#ifndef __LISTENINGWAY_INSTALLED
    // Since we're not including ListeningwayUniforms.fxh anymore,
    // provide a complete compatible implementation directly here
    #define LISTENINGWAY_NUM_BANDS 32
    #define __LISTENINGWAY_INSTALLED 1

    // Create fallback uniforms with the same interface as the real Listeningway
    uniform float Listeningway_Volume < source = "listeningway_volume"; > = 0.0;
    uniform float Listeningway_FreqBands[LISTENINGWAY_NUM_BANDS] < source = "listeningway_freqbands"; > = {
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
    };
    uniform float Listeningway_Beat < source = "listeningway_beat"; > = 0.0;

    // Time uniforms
    uniform float Listeningway_TimeSeconds < source = "listeningway_timeseconds"; > = 0.0;
    uniform float Listeningway_TimePhase60Hz < source = "listeningway_timephase60hz"; > = 0.0;
    uniform float Listeningway_TimePhase120Hz < source = "listeningway_timephase120hz"; > = 0.0;
    uniform float Listeningway_TotalPhases60Hz < source = "listeningway_totalphases60hz"; > = 0.0;
    uniform float Listeningway_TotalPhases120Hz < source = "listeningway_totalphases120hz"; > = 0.0;
#endif

#ifndef __AS_ANIMATION_CONSTANTS
#define __AS_ANIMATION_CONSTANTS
// Animation timing constants
static const float AS_ANIMATION_SPEED_SLOW = 0.5;       // Slow animation speed multiplier
static const float AS_ANIMATION_SPEED_NORMAL = 1.0;     // Normal animation speed multiplier  
static const float AS_ANIMATION_SPEED_FAST = 2.0;       // Fast animation speed multiplier

// Timing constants
static const float AS_TIME_1_SECOND = 1.0;              // 1 second of animation time
static const float AS_TIME_HALF_SECOND = 0.5;           // 0.5 seconds of animation time
static const float AS_TIME_QUARTER_SECOND = 0.25;       // 0.25 seconds of animation time

// Animation patterns
static const float AS_PATTERN_FREQ_LOW = 2.0;           // Low frequency for animation patterns
static const float AS_PATTERN_FREQ_MED = 5.0;           // Medium frequency for animation patterns
static const float AS_PATTERN_FREQ_HIGH = 10.0;         // High frequency for animation patterns
#endif // __AS_ANIMATION_CONSTANTS

#ifndef __AS_COMMON_UI_RANGES
#define __AS_COMMON_UI_RANGES

// Standard UI ranges for commonly used parameters
static const float AS_RANGE_ZERO_ONE_MIN = 0.0;         // Common minimum for normalized parameters
static const float AS_RANGE_ZERO_ONE_MAX = 1.0;         // Common maximum for normalized parameters

static const float AS_RANGE_NEG_ONE_ONE_MIN = -1.0;     // Common minimum for bipolar normalized parameters
static const float AS_RANGE_NEG_ONE_ONE_MAX = 1.0;      // Common maximum for bipolar normalized parameters

static const float AS_RANGE_OPACITY_MIN = 0.0;          // Minimum for opacity parameters
static const float AS_RANGE_OPACITY_MAX = 1.0;          // Maximum for opacity parameters
static const float AS_RANGE_OPACITY_DEFAULT = 1.0;      // Default for opacity parameters

static const float AS_RANGE_BLEND_MIN = 0.0;            // Minimum for blend amount parameters
static const float AS_RANGE_BLEND_MAX = 1.0;            // Maximum for blend amount parameters
static const float AS_RANGE_BLEND_DEFAULT = 1.0;        // Default for blend amount parameters

static const float AS_RANGE_AUDIO_MULT_MIN = 0.0;       // Minimum for audio multiplier parameters
static const float AS_RANGE_AUDIO_MULT_MAX = 2.0;       // Maximum for audio multiplier parameters
static const float AS_RANGE_AUDIO_MULT_DEFAULT = 1.0;   // Default for audio multiplier parameters

// Scale range constants
static const float AS_RANGE_SCALE_MIN = 0.1;            // Minimum for scale parameters
static const float AS_RANGE_SCALE_MAX = 5.0;            // Maximum for scale parameters
static const float AS_RANGE_SCALE_DEFAULT = 1.0;        // Default for scale parameters

// Speed range constants
static const float AS_RANGE_SPEED_MIN = 0.0;            // Minimum for speed parameters 
static const float AS_RANGE_SPEED_MAX = 5.0;            // Maximum for speed parameters
static const float AS_RANGE_SPEED_DEFAULT = 1.0;        // Default for speed parameters

#endif // __AS_COMMON_UI_RANGES

// Debug mode constants
#ifndef __AS_DEBUG_CONSTANTS
#define __AS_DEBUG_CONSTANTS
static const int AS_DEBUG_OFF = 0;                      // Debug mode off
static const int AS_DEBUG_MASK = 1;                     // Debug mask display
static const int AS_DEBUG_DEPTH = 2;                    // Debug depth display
static const int AS_DEBUG_AUDIO = 3;                    // Debug audio display
static const int AS_DEBUG_PATTERN = 4;                  // Debug pattern display
#endif // __AS_DEBUG_CONSTANTS

// --- Audio Constants ---
#define AS_AUDIO_OFF     0  // Audio source disabled
#define AS_AUDIO_SOLID   1  // Constant value (no audio reactivity)
#define AS_AUDIO_VOLUME  2  // Overall audio volume
#define AS_AUDIO_BEAT    3  // Beat detection

// --- Blend Constants ---
#define AS_BLEND_NORMAL     0 // No blending
#define AS_BLEND_ADDITIVE   1 // Additive blending

// --- Display and Resolution Constants ---
#ifndef __AS_DISPLAY_CONSTANTS
#define __AS_DISPLAY_CONSTANTS
static const float AS_RESOLUTION_BASE_HEIGHT = 1080.0;  // Standard height for scaling calculations
static const float AS_RESOLUTION_BASE_WIDTH = 1920.0;   // Standard width for scaling calculations
static const float AS_STANDARD_ASPECT_RATIO = 16.0/9.0; // Standard aspect ratio for reference

// Common UI mapping constants
static const float AS_UI_POSITION_RANGE = 1.5;  // Standard range for position UI controls (-1.5 to 1.5)
static const float AS_UI_CENTRAL_SQUARE = 1.0;  // Range mapping to central square (-1.0 to 1.0)
static const float AS_UI_POSITION_SCALE = 0.5;  // Position scaling factor for centered coordinates

// Common coordinate system values
static const float AS_SCREEN_CENTER_X = 0.5;    // Screen center X coordinate
static const float AS_SCREEN_CENTER_Y = 0.5;    // Screen center Y coordinate
static const float AS_RESOLUTION_SCALE = 1080.0 / BUFFER_HEIGHT; // Resolution scaling factor
#endif // __AS_DISPLAY_CONSTANTS
#define AS_AUDIO_BASS    4  // Low frequency band
#define AS_AUDIO_TREBLE  5  // High frequency band
#define AS_AUDIO_MID     6  // Mid frequency band

// Default number of frequency bands
#ifndef LISTENINGWAY_NUM_BANDS
    #define LISTENINGWAY_NUM_BANDS 32
#endif
#define AS_DEFAULT_NUM_BANDS LISTENINGWAY_NUM_BANDS

// --- Standard UI Strings ---
#define AS_AUDIO_SOURCE_ITEMS "Off\0Solid\0Volume\0Beat\0Bass\0Treble\0Mid\0"

// --- UI Control Macros ---
// Define standard audio source control (reuse this macro for each audio reactive parameter)
#define AS_AUDIO_SOURCE_UI(name, label, defaultSource, category) \
uniform int name < ui_type = "combo"; ui_label = label; ui_items = AS_AUDIO_SOURCE_ITEMS; ui_category = category; > = defaultSource;

// Define standard multiplier control for audio reactivity
#define AS_AUDIO_MULTIPLIER_UI(name, label, defaultValue, maxValue, category) \
uniform float name < ui_type = "slider"; ui_label = label; ui_tooltip = "Controls how much the selected audio source affects this parameter."; ui_min = 0.0; ui_max = maxValue; ui_step = 0.05; ui_category = category; > = defaultValue;

#endif // __AS_LISTENINGWAY_INCLUDED

// --- Debug Mode Standardization ---
#ifndef __AS_DEBUG_MODE_INCLUDED
#define __AS_DEBUG_MODE_INCLUDED

// --- Debug UI Macro ---
#define AS_DEBUG_MODE_UI(items) \
uniform int DebugMode < ui_type = "combo"; ui_label = "Debug View"; ui_tooltip = "Show various visualization modes for debugging."; ui_items = items; ui_category = "Debug"; > = 0;

// --- Debug Helper Functions ---
bool AS_isDebugMode(int currentMode, int targetMode) {
    return currentMode == targetMode;
}

// Standard "Off" value for debug modes
#define AS_DEBUG_OFF 0

#endif // __AS_DEBUG_MODE_INCLUDED

// --- Sway Animation UI Standardization ---
#ifndef __AS_SWAY_UI_INCLUDED
#define __AS_SWAY_UI_INCLUDED

// --- Sway UI Macros ---
#define AS_SWAYSPEED_UI(name, category) \
uniform float name < ui_type = "slider"; ui_label = "Sway Speed"; ui_tooltip = "Controls the speed of the swaying animation"; ui_min = 0.0; ui_max = 5.0; ui_step = 0.01; ui_category = category; > = 1.0;

#define AS_SWAYANGLE_UI(name, category) \
uniform float name < ui_type = "slider"; ui_label = "Sway Angle"; ui_tooltip = "Maximum angle of the swaying in degrees"; ui_min = 0.0; ui_max = 180.0; ui_step = 1.0; ui_category = category; > = 15.0;

#endif // __AS_SWAY_UI_INCLUDED

// --- Position and Scale UI Standardization ---
#ifndef __AS_POSITION_UI_INCLUDED
#define __AS_POSITION_UI_INCLUDED

// --- Position Constants ---
#define AS_POSITION_MIN -1.5
#define AS_POSITION_MAX 1.5
#define AS_POSITION_STEP 0.01
#define AS_POSITION_DEFAULT 0.0

#define AS_SCALE_MIN 0.1
#define AS_SCALE_MAX 5.0
#define AS_SCALE_STEP 0.01
#define AS_SCALE_DEFAULT 1.0

// --- Position UI Macros ---
// Creates a standardized position control (as float2)
#define AS_POSITION_UI(name) \
uniform float2 name < ui_type = "drag"; ui_label = "Position"; ui_tooltip = "Position of the effect center (X,Y)."; ui_min = AS_POSITION_MIN; ui_max = AS_POSITION_MAX; ui_step = AS_POSITION_STEP; ui_category = "Position"; > = float2(AS_POSITION_DEFAULT, AS_POSITION_DEFAULT);

// Creates a standardized scale control
#define AS_SCALE_UI(name) \
uniform float name < ui_type = "slider"; ui_label = "Scale"; ui_tooltip = "Size of the effect. Higher values zoom out, lower values zoom in."; ui_min = AS_SCALE_MIN; ui_max = AS_SCALE_MAX; ui_step = AS_SCALE_STEP; ui_category = "Position"; > = AS_SCALE_DEFAULT;

// Combined position and scale UI for convenience
#define AS_POSITION_SCALE_UI(posName, scaleName) \
uniform float2 posName < ui_type = "drag"; ui_label = "Position"; ui_tooltip = "Position of the effect center (X,Y)."; ui_min = AS_POSITION_MIN; ui_max = AS_POSITION_MAX; ui_step = AS_POSITION_STEP; ui_category = "Position"; > = float2(AS_POSITION_DEFAULT, AS_POSITION_DEFAULT); \
uniform float scaleName < ui_type = "slider"; ui_label = "Scale"; ui_tooltip = "Size of the effect. Higher values zoom out, lower values zoom in."; ui_min = AS_SCALE_MIN; ui_max = AS_SCALE_MAX; ui_step = AS_SCALE_STEP; ui_category = "Position"; > = AS_SCALE_DEFAULT;

// --- Position Helper Functions ---
// Applies position offset and scaling to centered coordinates
// Parameters:
//   coord: Centered coordinates from texcoord (already corrected for aspect ratio)
//   pos: Position offset as float2(x, y) with range (-1.5 to 1.5)
//   scale: Scaling factor (0.1 to 5.0)
// Returns: Transformed coordinates
float2 AS_applyPositionAndScale(float2 coord, float2 pos, float scale) {
    // Apply position offset (Y is inverted in screen space)
    coord.x -= pos.x;
    coord.y += pos.y;
    
    // Apply scale (higher value = zoomed out)
    return coord / max(scale, 0.001); // Prevent division by zero
}

// Converts normalized texcoord to centered, aspect-corrected coordinates
// Parameters:
//   texcoord: Original normalized texcoord (0-1 range)
//   aspectRatio: Width/height ratio of the screen
// Returns: Centered coordinates corrected for aspect ratio
float2 AS_getCenteredCoord(float2 texcoord, float aspectRatio) {
    float2 centered = texcoord - 0.5;
    
    // Apply aspect ratio correction
    if (aspectRatio >= 1.0) {
        // Landscape or square
        centered.x *= aspectRatio;
    } else {
        // Portrait
        centered.y /= aspectRatio;
    }
    
    return centered;
}

// All-in-one function that handles the common position/scale pattern
// Parameters:
//   texcoord: Original normalized texcoord (0-1 range)
//   pos: Position as float2(x,y) with range (-1.5 to 1.5)
//   scale: Scale factor (0.1 to 5.0)
//   rotation: Rotation in radians
// Returns: Transformed coordinates ready for sampling or calculations
float2 AS_transformCoord(float2 texcoord, float2 pos, float scale, float rotation) {
    // Get aspect ratio
    float aspectRatio = ReShade::AspectRatio;
    
    // Center and apply aspect ratio correction
    float2 centered = AS_getCenteredCoord(texcoord, aspectRatio);
    
    // Apply position and scale
    float2 positioned = AS_applyPositionAndScale(centered, pos, scale);
    
    // Apply rotation if needed
    if (abs(rotation) > 0.0001) {
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

#endif // __AS_POSITION_UI_INCLUDED

// --- Math Helpers ---
// NOTE: AS_mod must be defined before any function that uses it (such as AS_mapAngleToBand)
// to avoid undeclared identifier errors during shader compilation.
//
// Why is this function called AS_mod?
// - The name avoids confusion with built-in mod/fmod, which can behave inconsistently across shader languages/APIs.
// - The AS_ prefix marks it as part of the Aquitaine Studio utility set.
// - This implementation provides consistent, predictable modulo behavior for all AS shaders.
float AS_mod(float x, float y) {
    // Ensure y is not zero to avoid division by zero
    if (abs(y) < 1e-6) return x;
    return x - y * floor(x / y);
}

// ============================================================================
// VISUAL EFFECTS & BLEND MODES
// ============================================================================

// --- Blend Functions ---

// Applies various blend modes between a foreground and background color.
// Parameters:
//   fgColor: The foreground color (float3) - the effect's color.
//   bgColor: The background color (float3) - the original scene color.
//   blendMode: Integer specifying the blend mode:
//              0: Normal (Foreground replaces Background)
//              1: Lighter Only (Lighten)
//              2: Darker Only (Darken)
//              3: Additive
//              4: Multiply
//              5: Screen
// Returns: The blended float3 color.
float3 AS_ApplyBlend(float3 fgColor, float3 bgColor, int blendMode) {
    if (blendMode == 1) return max(bgColor, fgColor);                      // Lighter Only (Lighten)
    if (blendMode == 2) return min(bgColor, fgColor);                      // Darker Only (Darken)
    if (blendMode == 3) return saturate(bgColor + fgColor);                // Additive (saturate to prevent overflow)
    if (blendMode == 4) return saturate(bgColor * fgColor);                // Multiply
    if (blendMode == 5) return saturate(1.0 - (1.0 - bgColor) * (1.0 - fgColor)); // Screen
    
    // Default: Normal blend (mode 0 or any other mode)
    return fgColor; 
}

// Applies various blend modes between a foreground and background color, with opacity.
// Parameters:
//   fgColor: The foreground color (float4) - the effect's color, including its own alpha (fgColor.a).
//   bgColor: The background color (float4) - the original scene color.
//   blendMode: Integer specifying the blend mode:
//              0: Normal (Foreground over Background)
//              1: Lighter Only (Lighten)
//              2: Darker Only (Darken)
//              3: Additive
//              4: Multiply
//              5: Screen
//   blendOpacity: Overall opacity of the foreground effect layer (0.0 to 1.0).
// Returns: The blended float4 color. The alpha channel of the result is taken from bgColor.a.
float4 AS_ApplyBlend(float4 fgColor, float4 bgColor, int blendMode, float blendOpacity) {
    // Call the 3-parameter version for RGB blending
    float3 effect_rgb = AS_ApplyBlend(fgColor.rgb, bgColor.rgb, blendMode);

    // Combine fgColor.a (per-pixel effect alpha) and blendOpacity (overall layer opacity)
    float final_opacity = saturate(fgColor.a * blendOpacity);

    // Lerp between the original background color and the blended effect color
    float3 final_rgb = lerp(bgColor.rgb, effect_rgb, final_opacity);
    
    return float4(final_rgb, bgColor.a); // Preserve original scene alpha
}

// Linearly interpolates between two colors for palette generation
float3 AS_paletteLerp(float3 c0, float3 c1, float t) {
    return lerp(c0, c1, t);
}

// ============================================================================
// AUDIO REACTIVITY FUNCTIONS
// ============================================================================

// --- Time Functions ---
uniform int frameCount < source = "framecount"; >; // Frame count from ReShade

// Returns consistent time value in seconds, using Listeningway if available
// Approximates time based on frame count if Listeningway is not available
float AS_getTime() {
#if defined(__LISTENINGWAY_INSTALLED)
    // Check if Listeningway appears to be actively running by checking if totalphases is non-zero
    if (Listeningway_TotalPhases120Hz > 0.0001) {
        // Use Listeningway's high-precision timer when available and active
        return Listeningway_TotalPhases120Hz * (1.0 / 120.0); // 120Hz phase counter
    }
    else if (Listeningway_TimeSeconds > 0.0001) {
        // Alternative fallback to direct time seconds if available
        return Listeningway_TimeSeconds;
    }
#endif
    // Fallback to frame count approximation (assumes ~60 FPS)
    return float(frameCount) * (1.0 / 60.0);
}

// --- Listeningway Helpers ---
// Returns number of available frequency bands
int AS_getNumFrequencyBands() {
#if defined(__LISTENINGWAY_INSTALLED) && defined(LISTENINGWAY_NUM_BANDS)
    return LISTENINGWAY_NUM_BANDS;
#else
    return AS_DEFAULT_NUM_BANDS;
#endif
}

// Get frequency band value safely with bounds checking
float AS_getFrequencyBand(int index) {
#if defined(__LISTENINGWAY_INSTALLED)
    int numBands = AS_getNumFrequencyBands();
    // Safely clamp the index to valid range
    int safeIndex = clamp(index, 0, numBands - 1);
    return Listeningway_FreqBands[safeIndex];
#else
    return 0.0;
#endif
}

// Map circular angle to frequency band index
int AS_mapAngleToBand(float angleRadians, int repetitions) {
    // Normalize angle to 0-1 range (0 to 2π)
    float normalizedAngle = AS_mod(angleRadians, AS_TWO_PI) / AS_TWO_PI;

    // Scale by number of bands and repetitions
    int numBands = AS_getNumFrequencyBands();
    if (numBands <= 0) return 0; // Avoid division by zero if no bands
    int totalBands = numBands * max(1, repetitions); // Ensure at least 1 repetition

    // Map to band index
    int bandIdx = int(floor(normalizedAngle * totalBands)) % numBands;
    return bandIdx;
}

// Returns VU meter value from specified source
float AS_getVUMeterValue(int source) {
#if defined(__LISTENINGWAY_INSTALLED)
    if (source == 0) return Listeningway_Volume;
    if (source == 1) return Listeningway_Beat;
    // Assuming 32 bands for these indices
    if (source == 2) return Listeningway_FreqBands[min(0, LISTENINGWAY_NUM_BANDS - 1)]; // Bass (first band)
    if (source == 3) return Listeningway_FreqBands[min(14, LISTENINGWAY_NUM_BANDS - 1)]; // Mid (approx middle)
    if (source == 4) return Listeningway_FreqBands[min(28, LISTENINGWAY_NUM_BANDS - 1)]; // Treble (near end)
#endif
    return 0.0;
}

// Returns normalized audio value from specified source
float AS_getAudioSource(int source) {
    if (source == AS_AUDIO_OFF)   return 0.0;                // Off
    if (source == AS_AUDIO_SOLID)  return 1.0;                // Solid
#if defined(__LISTENINGWAY_INSTALLED)
    if (source == AS_AUDIO_VOLUME) return Listeningway_Volume; // Volume
    if (source == AS_AUDIO_BEAT)   return Listeningway_Beat;   // Beat

    int numBands = AS_getNumFrequencyBands();
    if (numBands <= 1) return 0.0; // Safety check

    if (source == AS_AUDIO_BASS) {
        // Bass is the first band
        return Listeningway_FreqBands[0];
    }
    if (source == AS_AUDIO_MID) {
        // Mid is the middle band
        return Listeningway_FreqBands[numBands / 2];
    }
    if (source == AS_AUDIO_TREBLE) {
        // Treble is the last band
        return Listeningway_FreqBands[numBands - 1];
    }
#endif

    return 0.0; // Return 0 if source is invalid or Listeningway unavailable
}

// Applies audio reactivity to a parameter (multiplicative)
// Base value is multiplied by (1.0 + audioLevel * multiplier)
float AS_applyAudioReactivity(float baseValue, int audioSource, float multiplier, bool enableFlag) {
    if (!enableFlag || audioSource == AS_AUDIO_OFF) return baseValue;

    float audioLevel = AS_getAudioSource(audioSource);
    return baseValue * (1.0 + audioLevel * multiplier);
}

// Advanced version that can add or multiply the effect
// mode: 0=Multiplicative, 1=Additive
float AS_applyAudioReactivityEx(float baseValue, int audioSource, float multiplier, bool enableFlag, int mode) {
    if (!enableFlag || audioSource == AS_AUDIO_OFF) return baseValue;

    float audioLevel = AS_getAudioSource(audioSource);

    if (mode == 1) { // Additive mode
        return baseValue + (audioLevel * multiplier);
    } else { // Multiplicative mode (default)
        return baseValue * (1.0 + audioLevel * multiplier);
    }
}

// ============================================================================
// MATH & COORDINATE HELPERS 
// ============================================================================

// --- Rotation UI Standardization ---
#ifndef __AS_ROTATION_UI_INCLUDED
#define __AS_ROTATION_UI_INCLUDED

// --- Rotation UI Macro ---
// Creates a standardized pair of rotation controls (snap + fine) that appear on the same line
#define AS_ROTATION_UI(snapName, fineName) \
uniform int snapName < ui_category = "Stage"; ui_label = "Snap Rotation"; ui_type = "slider"; ui_min = -4; ui_max = 4; ui_step = 1; ui_tooltip = "Snap rotation in 45° steps (-180° to +180°)"; ui_spacing = 0; > = 0; \
uniform float fineName < ui_category = "Stage"; ui_label = "Fine Rotation"; ui_type = "slider"; ui_min = -45.0; ui_max = 45.0; ui_step = 0.1; ui_tooltip = "Fine rotation adjustment in degrees"; ui_same_line = true; > = 0.0;

// --- Rotation Helper Function ---
// Combines snap and fine rotation values and converts to radians
float AS_getRotationRadians(int snapRotation, float fineRotation) {
    float snapAngle = float(snapRotation) * 45.0;
    return (snapAngle + fineRotation) * (AS_PI / 180.0);
}

#endif // __AS_ROTATION_UI_INCLUDED

// --- Animation UI Standardization ---
#ifndef __AS_ANIMATION_UI_INCLUDED
#define __AS_ANIMATION_UI_INCLUDED

// --- Animation Constants ---
#define AS_ANIMATION_SPEED_MIN 0.0
#define AS_ANIMATION_SPEED_MAX 5.0
#define AS_ANIMATION_SPEED_STEP 0.01
#define AS_ANIMATION_SPEED_DEFAULT 1.0

#define AS_ANIMATION_KEYFRAME_MIN 0.0
#define AS_ANIMATION_KEYFRAME_MAX 100.0
#define AS_ANIMATION_KEYFRAME_STEP 0.1
#define AS_ANIMATION_KEYFRAME_DEFAULT 0.0

// --- Animation UI Macros ---
// Creates a standardized animation speed control
#define AS_ANIMATION_SPEED_UI(name, category) \
uniform float name < ui_type = "slider"; ui_label = "Animation Speed"; ui_tooltip = "Controls the overall animation speed of the effect. Set to 0 to pause animation."; ui_min = AS_ANIMATION_SPEED_MIN; ui_max = AS_ANIMATION_SPEED_MAX; ui_step = AS_ANIMATION_SPEED_STEP; ui_category = category; > = AS_ANIMATION_SPEED_DEFAULT;

// Creates a standardized animation keyframe control
#define AS_ANIMATION_KEYFRAME_UI(name, category) \
uniform float name < ui_type = "slider"; ui_label = "Animation Keyframe"; ui_tooltip = "Sets a specific point in time for the animation. Useful for finding and saving specific patterns."; ui_min = AS_ANIMATION_KEYFRAME_MIN; ui_max = AS_ANIMATION_KEYFRAME_MAX; ui_step = AS_ANIMATION_KEYFRAME_STEP; ui_category = category; > = AS_ANIMATION_KEYFRAME_DEFAULT;

// Combined animation UI for convenience (both speed and keyframe)
#define AS_ANIMATION_UI(speedName, keyframeName, category) \
uniform float speedName < ui_type = "slider"; ui_label = "Animation Speed"; ui_tooltip = "Controls the overall animation speed of the effect. Set to 0 to pause animation."; ui_min = AS_ANIMATION_SPEED_MIN; ui_max = AS_ANIMATION_SPEED_MAX; ui_step = AS_ANIMATION_SPEED_STEP; ui_category = category; > = AS_ANIMATION_SPEED_DEFAULT; \
uniform float keyframeName < ui_type = "slider"; ui_label = "Animation Keyframe"; ui_tooltip = "Sets a specific point in time for the animation. Useful for finding and saving specific patterns."; ui_min = AS_ANIMATION_KEYFRAME_MIN; ui_max = AS_ANIMATION_KEYFRAME_MAX; ui_step = AS_ANIMATION_KEYFRAME_STEP; ui_category = category; > = AS_ANIMATION_KEYFRAME_DEFAULT;

// --- Animation Helper Functions ---
// Calculates animation time based on speed, keyframe, and AS_getTime()
// Parameters:
//   speed: Animation speed (0.0 = paused)
//   keyframe: Animation keyframe/starting point
// Returns: Animation time value
float AS_getAnimationTime(float speed, float keyframe) {
    // When animation speed is effectively zero, use keyframe directly
    if (speed <= 0.0001) {
        return keyframe;
    }
    
    // Otherwise use animated time plus keyframe offset
    return (AS_getTime() * speed) + keyframe;
}

#endif // __AS_ANIMATION_UI_INCLUDED

// --- Math Helpers ---
// Corrects UV coordinates for non-square aspect ratios
float2 AS_aspectCorrect(float2 uv, float width, float height) { 
    float aspect = width / height; 
    return float2((uv.x - 0.5) * aspect + 0.5, uv.y); 
}

// Transforms uv so that a distance calculation results in a circle on screen
float2 AS_aspectCorrectUV(float2 uv, float aspectRatio) {
    float2 centered_uv = uv - 0.5;
    centered_uv.x *= aspectRatio;
    return centered_uv + 0.5; // Return corrected UV in 0-1 range
}

// Converts degrees to radians
float AS_radians(float deg) {
    return deg * (AS_PI / 180.0);
}

// Converts radians to degrees
float AS_degrees(float rad) {
    return rad * (180.0 / AS_PI);
}

// Converts normalized UV coordinates to pixel positions
float2 AS_rescaleToScreen(float2 uv) {
    return uv * ReShade::ScreenSize.xy;
}

// ============================================================================
// DEPTH, SURFACE & VISUAL EFFECTS
// ============================================================================

// --- Depth and Surface Functions ---
// Returns a fade mask based on scene depth, near/far planes, and curve
float AS_depthMask(float depth, float nearPlane, float farPlane, float curve) {
    // Ensure nearPlane is less than farPlane to avoid issues
    farPlane = max(nearPlane + 1e-5, farPlane);
    // Calculate mask using smoothstep for range [nearPlane, farPlane]
    float mask = smoothstep(nearPlane, farPlane, depth);
    // Apply curve and invert (1 near, 0 far)
    return 1.0 - pow(mask, max(0.1, curve)); // Ensure curve is positive
}

// Reconstructs normal from depth buffer using screen-space derivatives
// Note: Quality depends heavily on depth buffer precision and linearity.
float3 AS_reconstructNormal(float2 texcoord) {
    // Sample depth in a 2x2 neighborhood for central differencing
    float depth = ReShade::GetLinearizedDepth(texcoord);
    float depthX1 = ReShade::GetLinearizedDepth(texcoord + float2(ReShade::PixelSize.x, 0.0));
    float depthY1 = ReShade::GetLinearizedDepth(texcoord + float2(0.0, ReShade::PixelSize.y));

    // Estimate view-space position derivatives using depth differences
    // This assumes a perspective projection and requires knowledge of projection params for accuracy,
    // but provides a reasonable approximation for screen-space effects.
    float3 dx = float3(ReShade::PixelSize.x, 0.0, depthX1 - depth);
    float3 dy = float3(0.0, ReShade::PixelSize.y, depthY1 - depth);

    // Calculate normal using cross product (ensure correct handedness)
    // Cross product direction depends on coordinate system; assuming standard right-handed view space
    float3 normal = normalize(cross(dy, dx)); // Swapped order might be needed depending on depth direction

    return normal;
}

// Returns fresnel term for a given normal and view direction
// Assumes viewDir points from surface towards camera (e.g., viewDir = normalize(-viewSpacePos))
float AS_fresnel(float3 normal, float3 viewDir, float power) {
    // Ensure vectors are normalized
    normal = normalize(normal);
    viewDir = normalize(viewDir);
    // Calculate Fresnel term: (1 - dot(N, V))^power
    return pow(1.0 - saturate(dot(normal, viewDir)), max(0.1, power)); // Ensure power is positive
}

// --- Safe Hyperbolic Tangent ---
// Provides a safer implementation of hyperbolic tangent that:
// 1. Prevents infinity/NaN for extremely large inputs
// 2. Normalizes output to strict [-1, 1] range
// 3. Maintains the same behavior as regular tanh for normal inputs
// Parameters:
//   x: Input value to compute tanh for
//   safetyThreshold: (Optional) Maximum absolute value to apply standard tanh to (default: 12.0)
float stanh(float x, float safetyThreshold = 12.0) {
    // For regular range inputs, use normal tanh
    if (abs(x) <= safetyThreshold) {
        return tanh(x);
    }
    
    // For extreme values, asymptotically approach +/-1 without risk of precision issues
    // When |x| > threshold, we know tanh(x) is very close to sign(x)
    return sign(x) * (1.0 - exp(-abs(x - sign(x) * safetyThreshold)) * (1.0 - tanh(safetyThreshold * sign(x))));
}

// Vectorized version of stanh (for float2)
float2 stanh(float2 x, float safetyThreshold = 12.0) {
    return float2(
        stanh(x.x, safetyThreshold),
        stanh(x.y, safetyThreshold)
    );
}

// Vectorized version of stanh (for float3)
float3 stanh(float3 x, float safetyThreshold = 12.0) {
    return float3(
        stanh(x.x, safetyThreshold),
        stanh(x.y, safetyThreshold),
        stanh(x.z, safetyThreshold)
    );
}

// Vectorized version of stanh (for float4)
float4 stanh(float4 x, float safetyThreshold = 12.0) {
    return float4(
        stanh(x.x, safetyThreshold),
        stanh(x.y, safetyThreshold),
        stanh(x.z, safetyThreshold),
        stanh(x.w, safetyThreshold)
    );
}

// --- Animation Helpers ---
// Simple fade-in / fade-out function based on a cycle value (0 to 1)
float AS_fadeInOut(float cycle, float fadeInEnd, float fadeOutStart) {
    // Ensure valid ranges
    fadeInEnd = saturate(fadeInEnd);
    fadeOutStart = saturate(fadeOutStart);
    if (fadeInEnd >= fadeOutStart) return (cycle < 0.5) ? smoothstep(0.0, 0.5, cycle) * 2.0 : (1.0 - smoothstep(0.5, 1.0, cycle)) * 2.0; // Simple triangle if invalid

    float brightness = 1.0;
    if (cycle < fadeInEnd) {
        // Fade in from 0 to fadeInEnd
        brightness = smoothstep(0.0, fadeInEnd, cycle);
    } else if (cycle > fadeOutStart) {
        // Fade out from fadeOutStart to 1.0
        brightness = 1.0 - smoothstep(fadeOutStart, 1.0, cycle);
    }
    // else: brightness remains 1.0 between fadeInEnd and fadeOutStart

    return brightness;
}


// --- Sway Animation Helpers ---
// Applies sinusoidal sway effect based on time
// swayAngle: maximum angle of sway in degrees
// swaySpeed: speed of the sway animation
// returns: sway offset in radians
float AS_applySway(float swayAngle, float swaySpeed) {
    float time = AS_getTime();
    float swayPhase = time * swaySpeed;
    return AS_radians(swayAngle) * sin(swayPhase);
}

// Audio-reactive version of sway effect
// swayAngle: maximum angle of sway in degrees
// swaySpeed: speed of the sway animation
// audioSource: audio source to modulate the sway with
// audioMult: audio multiplier
// returns: audio-reactive sway offset in radians
float AS_applyAudioSway(float swayAngle, float swaySpeed, int audioSource, float audioMult) {
    float time = AS_getTime();
    float audioLevel = AS_getAudioSource(audioSource);
    // Modulate the angle based on audio
    float reactiveAngle = swayAngle * (1.0 + audioLevel * audioMult);
    float swayPhase = time * swaySpeed;
    return AS_radians(reactiveAngle) * sin(swayPhase);
}

// --- Visualization Helpers ---
// Returns a debug color based on mode and value (simplified)
float4 AS_debugOutput(int mode, float4 orig, float4 value1, float4 value2, float4 value3) {
    if (mode == 1) return value1; // Show first debug value
    if (mode == 2) return value2; // Show second debug value
    if (mode == 3) return value3; // Show third debug value
    // Add more modes as needed
    return orig; // Default: return original color
}

// Returns a star-shaped mask for sparkle effects
// p: coordinate relative to star center
// size: overall size of the star
// points: number of points on the star
// angle: rotation angle offset
float AS_starMask(float2 p, float size, float points, float angle) {
    float2 uv = p / max(size, 1e-5); // Normalize coords by size
    float a = atan2(uv.y, uv.x) + AS_radians(angle); // Angle + offset
    float r = length(uv); // Distance from center

    // Modulate radius based on angle and number of points
    float f = cos(a * points); // Creates lobes
    f = f * 0.5 + 0.5; // Map from [-1, 1] to [0, 1] range    // Use smoothstep to create the shape based on distance and modulated radius 'f'
    // The inner edge is f, outer edge slightly larger for anti-aliasing
    return 1.0 - smoothstep(f, f + AS_EDGE_AA, r); // Using standard anti-aliasing edge size
}


// ============================================================================
// STAGE DEPTH & BLEND UI HELPERS
// ============================================================================

#ifndef __AS_STAGEDEPTH_UI_INCLUDED
#define __AS_STAGEDEPTH_UI_INCLUDED

#define AS_STAGEDEPTH_UI(name) \
uniform float name < ui_type = "slider"; ui_label = "Effect Depth"; ui_tooltip = "Controls how far back the stage effect appears (Linear Depth 0-1)."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Stage"; > = 0.05;

#endif // __AS_STAGEDEPTH_UI_INCLUDED

// --- Blend Mode UI Standardization ---
#ifndef __AS_BLEND_UI_INCLUDED
#define __AS_BLEND_UI_INCLUDED

// --- Blend Mode UI Macro with default value ---
#define AS_BLENDMODE_UI_DEFAULT(name, defaultMode) \
uniform int name < ui_type = "combo"; ui_label = "Mode"; ui_items = "Normal\0Lighter Only\0Darker Only\0Additive\0Multiply\0Screen\0"; ui_category = "Final Mix"; > = defaultMode;

// --- Blend Mode UI Macro (defaults to Normal) ---
#define AS_BLENDMODE_UI(name) \
    AS_BLENDMODE_UI_DEFAULT(name, 0) // Default to Normal (index 0)

// --- Blend Amount UI Macro ---
#define AS_BLENDAMOUNT_UI(name) \
uniform float name < ui_type = "slider"; ui_label = "Strength"; ui_tooltip = "Controls the overall intensity/opacity of the effect blend."; ui_min = 0.0; ui_max = 1.0; ui_category = "Final Mix"; > = 1.0;

#endif // __AS_BLEND_UI_INCLUDED

#endif // __AS_Utils_1_fxh
