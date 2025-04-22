/**
 * AS_Utils.fxh - Common Utility Functions for AS Shader Collection
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * This header file provides common utility functions used across the Aquitaine Studio
 * shader collection. It includes blend modes, audio processing, mathematical helpers,
 * and various convenience functions to maintain consistency across shaders.
 *
 * FUNCTIONS:
 * - Blend modes (Normal, Lighter Only, Darker Only, Additive, Multiply, Screen)
 * - Time helpers with Listeningway support
 * - Audio source management and VU meter processing
 * - Hash functions for procedural noise generation
 * - Modulo, aspect ratio, and angle conversion helpers
 * - Color palette interpolation
 * - Screen coordinate transformation
 *
 * ===================================================================================
 */

// --- Blend Helper ---
// Applies various blend modes between original and effect colors
// mode: 0=Normal, 1=Lighter Only, 2=Darker Only, 3=Additive, 4=Multiply, 5=Screen
float3 AS_blendResult(float3 orig, float3 fx, int mode) {
    if (mode == 1) return max(orig, fx); // Lighter Only
    if (mode == 2) return min(orig, fx); // Darker Only
    if (mode == 3) return orig + fx;     // Additive
    if (mode == 4) return orig * fx;     // Multiply
    if (mode == 5) return 1.0 - (1.0 - orig) * (1.0 - fx); // Screen 
    return lerp(orig, fx, 1.0); // Normal (full replace by mask)
}

// --- Time Helper ---
// Returns consistent time value in seconds, using Listeningway if available
// frameCount: Current frame count from ReShade
float AS_getTime(int frameCount) {
#if defined(LISTENINGWAY_INSTALLED)
    return Listeningway_TotalPhases120Hz * 0.016;
#else
    return frameCount * 0.016;
#endif
}

// --- Audio Source Helper ---
// Returns VU meter value from specified source
// source: 0=Volume, 1=Beat, 2=Bass, 3=Mid, 4=Treble
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
// source: 0=Off, 1=Solid, 2=Volume, 3=Beat, 4=Bass, 5=Treble
float AS_getAudioSource(int source) {
#if defined(LISTENINGWAY_INSTALLED)
    if (source == 0) return 0.0; // Off
    if (source == 1) return 1.0; // Solid
    if (source == 2) return Listeningway_Volume;
    if (source == 3) return Listeningway_Beat;
    if (source == 4) return Listeningway_FreqBands[0]; // Bass
    if (source == 5) return Listeningway_FreqBands[7]; // Treble
#endif
    return 0.0;
}

// --- Hash Functions ---
// 1D->1D hash: Returns pseudo-random float from 0-1 based on input float
float AS_hash11(float n) { return frac(sin(n) * 43758.5453); }

// 1D->2D hash: Returns pseudo-random 2D vector with components from 0-1
float2 AS_hash21(float n) { float x = frac(sin(n) * 43758.5453); float y = frac(cos(n) * 12345.6789); return float2(x, y); }

// 2D->2D hash: Returns pseudo-random 2D vector from 2D input
float2 AS_hash21(float2 n) { float x = frac(sin(dot(n, float2(12.9898, 78.233))) * 43758.5453); float y = frac(cos(dot(n, float2(39.3468, 11.1351))) * 24634.6345); return float2(x, y); }

// 3D->3D hash: Returns pseudo-random 3D vector from -1 to 1 from 3D input
float3 AS_hash33(float3 p3) { p3 = frac(p3 * float3(0.1031, 0.11369, 0.13787)); p3 += dot(p3, p3.yxz + 19.19); return -1.0 + 2.0 * frac(float3( (p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x )); }

// --- Modulus Helper ---
// Safe modulo operation ensuring consistent sign behavior across platforms
float AS_mymod(float x, float y) { return x - y * floor(x / y); }

// --- Aspect Ratio Helper ---
// Corrects UV coordinates for non-square aspect ratios
float2 AS_aspectCorrect(float2 uv, float width, float height) { float aspect = width / height; return float2((uv.x - 0.5) * aspect + 0.5, uv.y); }

// --- Radians/Degrees ---
// Converts degrees to radians
float AS_radians(float deg) { return deg * 0.01745329252; }

// Converts radians to degrees
float AS_degrees(float rad) { return rad * 57.2957795131; }

// --- Palette Interpolation Helper ---
// Linearly interpolates between two colors for palette generation
float3 AS_paletteLerp(float3 c0, float3 c1, float t) {
    return lerp(c0, c1, t);
}

// --- Rescale to Screen ---
// Converts normalized UV coordinates to pixel positions
float2 AS_rescaleToScreen(float2 uv) { return uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT); }
