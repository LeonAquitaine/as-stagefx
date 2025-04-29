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
 * - Procedural noise generation with various hash functions
 * - Mathematical and coordinate transformation helpers
 * - Depth, normal reconstruction, and surface effects functions
 *
 * IMPLEMENTATION OVERVIEW:
 * This file is organized in sections:
 * 1. UI standardization macros for consistent parameter layouts
 * 2. Audio integration and Listeningway support
 * 3. Visual effect helpers (blend modes, color operations)
 * 4. Mathematical functions (hash, coordinate transforms)
 * 5. Advanced rendering helpers (depth, normals, etc.)
 * 
 * ===================================================================================
 */

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "ReShadeUI.fxh"

// ============================================================================
// UI STANDARDIZATION & MACROS
// ============================================================================

// --- Listeningway Integration ---
// These macros help with consistent Listeningway integration across all shaders

// Use a special naming convention that ReShade doesn't expose in the UI
#ifndef __AS_LISTENINGWAY_INCLUDED
#define __AS_LISTENINGWAY_INCLUDED

// Define a macro to check for Listeningway availability
#ifndef __LISTENINGWAY_AVAILABLE
    #if __RESHADE__ >= 40800 // Version check for ReShade 4.8+
        #define __LISTENINGWAY_AVAILABLE 1
        
        // Try to include Listeningway, but don't error if it's not found
        
        // Check if Listeningway is already defined/installed
        #ifndef LISTENINGWAY_INSTALLED
            // Try to include the file - this will define LISTENINGWAY_INSTALLED if present
             // Make sure this is included first
            
            // Use try/catch equivalent with preprocessor
            #ifndef LISTENINGWAY_INCLUDE_ATTEMPTED
                #define LISTENINGWAY_INCLUDE_ATTEMPTED
                #include "ListeningwayUniforms.fxh" 
            #endif
        #endif
        
        // If Listeningway wasn't found, provide fallback implementations
        #ifndef LISTENINGWAY_INSTALLED
            // Define fallback variables used by the rest of the code
            static const float Listeningway_Volume = 0.0;
            static const float Listeningway_Beat = 0.0;
            static const float Listeningway_FreqBands[8] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
            static const float Listeningway_TotalPhases120Hz = 0.0;
        #else
            // #pragma message "Note: Listeningway found and enabled."
        #endif
    #else
        #pragma message "Note: ReShade version too old for Listeningway, using fallback."
        // Fallbacks for older ReShade versions
        static const float Listeningway_Volume = 0.0;
        static const float Listeningway_Beat = 0.0;
        static const float Listeningway_FreqBands[8] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
        static const float Listeningway_TotalPhases120Hz = 0.0;
    #endif
#endif

// --- Audio Constants ---
#define AS_AUDIO_OFF     0  // Audio source disabled
#define AS_AUDIO_SOLID   1  // Constant value (no audio reactivity)
#define AS_AUDIO_VOLUME  2  // Overall audio volume
#define AS_AUDIO_BEAT    3  // Beat detection
#define AS_AUDIO_BASS    4  // Low frequency band
#define AS_AUDIO_TREBLE  5  // High frequency band
#define AS_AUDIO_MID     6  // Mid frequency band

// Default number of frequency bands (matches Listeningway's default)
#define AS_DEFAULT_NUM_BANDS 8

// --- Standard UI Strings ---
#define AS_AUDIO_SOURCE_ITEMS "Off\0Solid\0Volume\0Beat\0Bass\0Treble\0Mid\0"

// --- UI Control Macros ---
// Define standard audio source control (reuse this macro for each audio reactive parameter)
#define AS_AUDIO_SOURCE_UI(name, label, defaultSource, category) \
uniform int name < \
    ui_type = "combo"; \
    ui_label = label; \
    ui_items = AS_AUDIO_SOURCE_ITEMS; \
    ui_category = category; \
> = defaultSource;

// Define standard multiplier control for audio reactivity
#define AS_AUDIO_MULTIPLIER_UI(name, label, defaultValue, maxValue, category) \
uniform float name < \
    ui_type = "slider"; \
    ui_label = label; \
    ui_tooltip = "Controls how much the selected audio source affects this parameter."; \
    ui_min = 0.0; ui_max = maxValue; ui_step = 0.05; \
    ui_category = category; \
> = defaultValue;

#endif // __AS_LISTENINGWAY_INCLUDED


// --- Debug Mode Standardization ---
#ifndef __AS_DEBUG_MODE_INCLUDED
#define __AS_DEBUG_MODE_INCLUDED

// --- Debug UI Macro ---
#define AS_DEBUG_MODE_UI(items) \
uniform int DebugMode < \
    ui_type = "combo"; \
    ui_label = "Debug View"; \
    ui_tooltip = "Show various visualization modes for debugging."; \
    ui_items = items; \
    ui_category = "Debug"; \
> = 0;

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
uniform float name < \
    ui_type = "slider"; \
    ui_label = "Sway Speed"; \
    ui_tooltip = "Controls the speed of the swaying animation"; \
    ui_min = 0.0; ui_max = 5.0; ui_step = 0.01; \
    ui_category = category; \
> = 1.0;

#define AS_SWAYANGLE_UI(name, category) \
uniform float name < \
    ui_type = "slider"; \
    ui_label = "Sway Angle"; \
    ui_tooltip = "Maximum angle of the swaying in degrees"; \
    ui_min = 0.0; ui_max = 180.0; ui_step = 1.0; \
    ui_category = category; \
> = 15.0;

#endif // __AS_SWAY_UI_INCLUDED

// --- Math Helpers ---
// NOTE: AS_mod must be defined before any function that uses it (such as AS_mapAngleToBand)
// to avoid undeclared identifier errors during shader compilation.
//
// Why is this function called AS_mod?
// - The name avoids confusion with built-in mod/fmod, which can behave inconsistently across shader languages/APIs.
// - The AS_ prefix marks it as part of the Aquitaine Studio utility set.
// - This implementation provides consistent, predictable modulo behavior for all AS shaders.
float AS_mod(float x, float y) { 
    return x - y * floor(x / y); 
}

// ============================================================================
// VISUAL EFFECTS & BLEND MODES
// ============================================================================

// --- Blend Functions ---
// Applies various blend modes between original and effect colors
// mode: 0=Normal, 1=Lighter Only, 2=Darker Only, 3=Additive, 4=Multiply, 5=Screen
float3 AS_blendResult(float3 orig, float3 fx, int mode) {
    if (mode == 1) return max(orig, fx);                      // Lighter Only
    if (mode == 2) return min(orig, fx);                      // Darker Only
    if (mode == 3) return orig + fx;                          // Additive
    if (mode == 4) return orig * fx;                          // Multiply
    if (mode == 5) return 1.0 - (1.0 - orig) * (1.0 - fx);    // Screen 
    return lerp(orig, fx, 1.0);                               // Normal (full replace by mask)
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

float AS_getTime() {
#if defined(LISTENINGWAY_INSTALLED)
    return Listeningway_TotalPhases120Hz * 0.016;
#else
    return frameCount * 0.016;
#endif
}

// --- Listeningway Helpers ---
// Returns number of available frequency bands
int AS_getNumFrequencyBands() {
#if defined(LISTENINGWAY_INSTALLED) && defined(LISTENINGWAY_NUM_BANDS)
    return LISTENINGWAY_NUM_BANDS;
#else
    return AS_DEFAULT_NUM_BANDS;
#endif
}

// Get frequency band value safely with bounds checking
float AS_getFrequencyBand(int index) {
#if defined(LISTENINGWAY_INSTALLED)
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
    float normalizedAngle = AS_mod(angleRadians, 6.2831853) / 6.2831853;
    
    // Scale by number of bands and repetitions
    int numBands = AS_getNumFrequencyBands();
    int totalBands = numBands * repetitions;
    
    // Map to band index
    int bandIdx = int(floor(normalizedAngle * totalBands)) % numBands;
    return bandIdx;
}

// Returns VU meter value from specified source
float AS_getVUMeterValue(int source) {
#if defined(LISTENINGWAY_INSTALLED)
    if (source == 0) return Listeningway_Volume;
    if (source == 1) return Listeningway_Beat;
    if (source == 2) return Listeningway_FreqBands[0]; // Bass
    if (source == 3) return Listeningway_FreqBands[3]; // Mid
    if (source == 4) return Listeningway_FreqBands[7]; // Treble
#endif
    return 0.0;
}

// Returns normalized audio value from specified source
float AS_getAudioSource(int source) {
    if (source == AS_AUDIO_OFF)    return 0.0;                // Off
    if (source == AS_AUDIO_SOLID)  return 1.0;                // Solid
    if (source == AS_AUDIO_VOLUME) return Listeningway_Volume; // Volume
    if (source == AS_AUDIO_BEAT)   return Listeningway_Beat;   // Beat
    
    // Updated frequency band indices to work with the new band size
    int numBands = AS_getNumFrequencyBands();
    if (numBands <= 1) return 0.0; // Safety check
    
    if (source == AS_AUDIO_BASS) {
        // Bass is the first 20% of bands, use first band
        return Listeningway_FreqBands[0]; 
    }
    if (source == AS_AUDIO_MID) {
        // Mid is the middle of the spectrum, use center band
        return Listeningway_FreqBands[numBands / 2]; 
    }
    if (source == AS_AUDIO_TREBLE) {
        // Treble is the last 20% of bands, use last band
        return Listeningway_FreqBands[numBands - 1]; 
    }
    
    return 0.0;
}

// Applies audio reactivity to a parameter (multiplicative)
float AS_applyAudioReactivity(float baseValue, int audioSource, float multiplier, bool enableFlag) {
    if (!enableFlag) return baseValue;
    
    float audioLevel = AS_getAudioSource(audioSource);
    return baseValue * (1.0 + audioLevel * multiplier);
}

// Advanced version that can add or multiply the effect
// mode: 0=Multiplicative, 1=Additive
float AS_applyAudioReactivityEx(float baseValue, int audioSource, float multiplier, bool enableFlag, int mode) {
    if (!enableFlag) return baseValue;
    
    float audioLevel = AS_getAudioSource(audioSource);
    
    if (mode == 1) {
        // Additive mode
        return baseValue + (audioLevel * multiplier);
    } else {
        // Multiplicative mode (default)
        return baseValue * (1.0 + audioLevel * multiplier);
    }
}

// ============================================================================
// MATH & PROCEDURAL GENERATION
// ============================================================================

// --- Math Constants ---
// Standard mathematical constants for consistent use across all shaders
#ifndef __AS_MATH_CONSTANTS
#define __AS_MATH_CONSTANTS
static const float AS_PI = 3.14159265359;
static const float AS_TWO_PI = 6.28318530718;
static const float AS_HALF_PI = 1.57079632679;
static const float AS_QUARTER_PI = 0.78539816339;
static const float AS_INV_PI = 0.31830988618;
static const float AS_E = 2.71828182846;
static const float AS_GOLDEN_RATIO = 1.61803398875;
#endif // __AS_MATH_CONSTANTS

// --- Math Helpers ---
// Corrects UV coordinates for non-square aspect ratios
float2 AS_aspectCorrect(float2 uv, float width, float height) { 
    float aspect = width / height; 
    return float2((uv.x - 0.5) * aspect + 0.5, uv.y); 
}

// Converts degrees to radians
float AS_radians(float deg) { 
    return deg * 0.01745329252; 
}

// Converts radians to degrees
float AS_degrees(float rad) { 
    return rad * 57.2957795131; 
}

// Converts normalized UV coordinates to pixel positions
float2 AS_rescaleToScreen(float2 uv) { 
    return uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT); 
}

// --- Procedural Functions ---
// 1D->1D hash: Returns pseudo-random float from 0-1 based on input float
float AS_hash11(float n) { 
    return frac(sin(n) * 43758.5453); 
}

// 2D->1D hash: Returns pseudo-random float from 0-1 based on 2D input
float AS_hash12(float2 p) {
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// 1D->2D hash: Returns pseudo-random 2D vector with components from 0-1
float2 AS_hash21(float n) { 
    float x = frac(sin(n) * 43758.5453); 
    float y = frac(cos(n) * 12345.6789); 
    return float2(x, y); 
}

// 2D->2D hash: Returns pseudo-random 2D vector from 2D input
float2 AS_hash21(float2 n) { 
    float x = frac(sin(dot(n, float2(12.9898, 78.233))) * 43758.5453); 
    float y = frac(cos(dot(n, float2(39.3468, 11.1351))) * 24634.6345); 
    return float2(x, y); 
}

// 3D->3D hash: Returns pseudo-random 3D vector from -1 to 1 from 3D input
float3 AS_hash33(float3 p3) { 
    p3 = frac(p3 * float3(0.1031, 0.11369, 0.13787)); 
    p3 += dot(p3, p3.yxz + 19.19); 
    return -1.0 + 2.0 * frac(float3(
        (p3.x + p3.y) * p3.z, 
        (p3.x + p3.z) * p3.y, 
        (p3.y + p3.z) * p3.x
    )); 
}

// ============================================================================
// DEPTH, SURFACE & VISUAL EFFECTS
// ============================================================================

// --- Depth and Surface Functions ---
// Returns a fade mask based on scene depth, near/far planes, and curve
float AS_depthMask(float depth, float nearPlane, float farPlane, float curve) {
    float mask = smoothstep(nearPlane, farPlane, depth);
    return 1.0 - pow(mask, curve);
}

// Reconstructs normal from depth buffer using screen-space derivatives
float3 AS_reconstructNormal(float2 texcoord) {
    float3 offset = float3(ReShade::PixelSize.xy, 0.0);
    
    // Sample depth at 5 points (center + cardinal directions)
    float depthCenter = ReShade::GetLinearizedDepth(texcoord);
    float depthLeft = ReShade::GetLinearizedDepth(texcoord - offset.xz * 2.0);
    float depthRight = ReShade::GetLinearizedDepth(texcoord + offset.xz * 2.0);
    float depthTop = ReShade::GetLinearizedDepth(texcoord - offset.zy * 2.0);
    float depthBottom = ReShade::GetLinearizedDepth(texcoord + offset.zy * 2.0);
    
    // Calculate derivatives for cross product
    float3 dx = float3(offset.x * 4.0, 0.0, depthRight - depthLeft);
    float3 dy = float3(0.0, offset.y * 4.0, depthBottom - depthTop);
    
    // Normal is cross product of the derivative vectors
    float3 normal = normalize(cross(dx, dy));
    return normal;
}

// Returns fresnel term for a given normal and view direction
float AS_fresnel(float3 normal, float3 viewDir, float power) {
    return pow(1.0 - saturate(dot(normal, viewDir)), power);
}

// --- Animation Helpers ---
float AS_fadeInOut(float cycle, float fadeInEnd, float fadeOutStart) {
    if (cycle < fadeInEnd)
        return smoothstep(0.0, fadeInEnd, cycle) / fadeInEnd;
    else if (cycle > fadeOutStart)
        return 1.0 - smoothstep(fadeOutStart, 1.0, cycle) / (1.0 - fadeOutStart);
    return 1.0;
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
    float reactiveAngle = swayAngle * (1.0 + audioLevel * audioMult);
    float swayPhase = time * swaySpeed;
    return AS_radians(reactiveAngle) * sin(swayPhase);
 }

// --- Visualization Helpers ---
// Returns a debug color based on mode and value
float4 AS_debugOutput(int mode, float4 orig, float4 mask, float4 audio, float4 effect) {
    if (mode == 1) return mask;
    if (mode == 2) return audio;
    if (mode == 3) return effect;
    return orig;
}

// Returns a star-shaped mask for sparkle effects
float AS_starMask(float2 p, float size, float points, float angle) {
    float2 uv = p;
    float a = atan2(uv.y, uv.x) + angle;
    float r = length(uv);
    float f = cos(a * points) * 0.5 + 0.5;
    return 1.0 - smoothstep(f * size, f * size + 0.01, r);
}

// ============================================================================
// STAGE DEPTH & BLEND UI HELPERS
// ============================================================================

#ifndef __AS_STAGEDEPTH_UI_INCLUDED
#define __AS_STAGEDEPTH_UI_INCLUDED

// --- Stage Depth UI Macro ---
#define AS_STAGEDEPTH_UI(name, label, category) \
uniform float name < \
    ui_type = "slider"; \
    ui_label = label; \
    ui_tooltip = "Controls how far back the stage effect appears."; \
    ui_min = 0.0; \
    ui_max = 1.0; \
    ui_step = 0.01; \
    ui_category = category; \
> = 0.05;

#endif // __AS_STAGEDEPTH_UI_INCLUDED

// --- Blend Mode UI Standardization ---
#ifndef __AS_BLEND_UI_INCLUDED
#define __AS_BLEND_UI_INCLUDED

// --- Blend Mode UI Macro with default value ---
#define AS_BLENDMODE_UI_DEFAULT(name, category, defaultMode) \
uniform int name < \
    ui_type = "combo"; \
    ui_label = "Mode"; \
    ui_items = "Normal\0Lighter Only\0Darker Only\0Additive\0Multiply\0Screen\0"; \
    ui_category = category; \
> = defaultMode;

// --- Blend Mode UI Macro (defaults to Normal) ---
#define AS_BLENDMODE_UI(name, category) \
    AS_BLENDMODE_UI_DEFAULT(name, category, 0)

// --- Blend Amount UI Macro ---
#define AS_BLENDAMOUNT_UI(name, category) \
uniform float name < \
    ui_type = "slider"; \
    ui_label = "Strength"; \
    ui_min = 0.0; \
    ui_max = 1.0; \
    ui_category = category; \
> = 1.0;

#endif // __AS_BLEND_UI_INCLUDED
