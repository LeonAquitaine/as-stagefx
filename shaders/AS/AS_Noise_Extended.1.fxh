/**
 * AS_Noise_Extended.1.fxh - Extended Procedural Noise Library for AS StageFX
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * This header file provides extended procedural noise functions that complement the
 * core noise library in AS_Noise.1.fxh. These are less commonly used but available
 * for shaders that need specialized noise patterns.
 *
 * FEATURES:
 * - Animated variants of value noise, Perlin noise, and FBM
 * - Domain warping techniques for complex fluid-like patterns
 * - Voronoi/cellular noise for cell-like patterns
 * - Turbulence and ridge noise for sharp, layered effects
 * - Specialized procedural patterns (wood, wave, cloud, marble)
 * - Noise utility functions for octave mixing
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_Noise_Extended_1_fxh
#define __AS_Noise_Extended_1_fxh

// ============================================================================
// INCLUDES
// ============================================================================
#include "AS_Noise.1.fxh"

// ============================================================================
// VALUE NOISE (ANIMATED)
// ============================================================================

// Animatable version of Value noise. Returns: [0, 1]
float AS_valueNoise2DA(float2 p, float time) {
    return AS_valueNoise2D(p + time);
}

// ============================================================================
// PERLIN NOISE (ANIMATED)
// ============================================================================

// Animatable version of Perlin noise. Returns: approximately [-0.5, 0.5]
float AS_PerlinNoise2DA(float2 p, float time) {
    return AS_PerlinNoise2D(p + time);
}

// Animatable version of 3D Perlin noise. Returns: [0, 1]
float AS_PerlinNoise3DA(float3 p, float time) {
    // Add time to z-coordinate for smooth animation
    return AS_PerlinNoise3D(p + float3(0.0, 0.0, time));
}

// ============================================================================
// FBM (ANIMATED)
// ============================================================================

// Animated version of FBM. Returns: approximately [-1, 1]
float AS_Fbm2DA(float2 p, float time, int octaves, float lacunarity, float gain) {
    float sum = 0.0;
    float amp = 1.0;
    float freq = 1.0;
    // Prevent zero or negative octaves
    octaves = max(octaves, 1);

    for(int i = 0; i < octaves; i++) {
        // Add time-based motion with different speeds per octave for more organic movement
        float2 offset = float2(time * 0.4 * (1.0 - 0.2 * i), time * 0.3 * (1.0 - 0.2 * i));
        sum += amp * AS_PerlinNoise2D((p + offset) * freq);
        freq *= lacunarity;
        amp *= gain;
    }

    return sum;
}

// Simplified animated FBM with default parameters
float AS_Fbm2DA(float2 p, float time) {
    return AS_Fbm2DA(p, time, AS_FBM_DEFAULT_OCTAVES, AS_FBM_DEFAULT_LACUNARITY, AS_FBM_DEFAULT_GAIN);
}

// ============================================================================
// DOMAIN WARPING
// ============================================================================

// --- Domain Warping ---
// Domain warping creates complex fluid-like patterns by deforming the coordinate space
float2 AS_DomainWarp2D(float2 p, float intensity, float scale) {
    // First layer of deformation
    float2 offset1 = float2(
        AS_PerlinNoise2D(p * scale),
        AS_PerlinNoise2D(p * scale + float2(5.2, 1.3))
    );

    // Second layer using deformed coordinates for more complexity
    float2 offset2 = float2(
        AS_PerlinNoise2D((p + offset1 * intensity * 0.5) * scale * 2.0),
        AS_PerlinNoise2D((p + offset1 * intensity * 0.5) * scale * 2.0 + float2(9.8, 3.7))
    );

    // Return warped coordinates
    return p + offset2 * intensity;
}

// Sample Perlin noise with domain warping applied. Returns: approximately [-0.5, 0.5]
float AS_DomainWarpedNoise2D(float2 p, float intensity, float scale) {
    float2 warped = AS_DomainWarp2D(p, intensity, scale);
    return AS_PerlinNoise2D(warped);
}

// Animated domain warping
float2 AS_DomainWarp2DA(float2 p, float time, float intensity, float scale) {
    // First layer of deformation with time
    float2 offset1 = float2(
        AS_PerlinNoise2DA(p * scale, time * 0.3),
        AS_PerlinNoise2DA(p * scale + float2(5.2, 1.3), time * 0.4)
    );

    // Second layer using deformed coordinates for more complexity
    float2 offset2 = float2(
        AS_PerlinNoise2DA((p + offset1 * intensity * 0.5) * scale * 2.0, time * 0.5),
        AS_PerlinNoise2DA((p + offset1 * intensity * 0.5) * scale * 2.0 + float2(9.8, 3.7), time * 0.6)
    );

    // Return warped coordinates
    return p + offset2 * intensity;
}

// Sample Perlin noise with animated domain warping applied. Returns: approximately [-0.5, 0.5]
float AS_DomainWarpedNoise2DA(float2 p, float time, float intensity, float scale) {
    float2 warped = AS_DomainWarp2DA(p, time, intensity, scale);
    return AS_PerlinNoise2D(warped);
}

// ============================================================================
// VORONOI / CELLULAR NOISE
// ============================================================================

// --- Voronoi Noise ---
// Cellular/Voronoi noise creates cell-like patterns. Returns: [0, ~1] (distance to nearest cell)
float AS_voronoiNoise2D(float2 p, out float2 cellPoint) {
    float2 i = floor(p);
    float2 f = frac(p);

    float minDist = 8.0; // Initialize with a large distance
    cellPoint = float2(0, 0);

    // Search in 3x3 neighborhood for the closest feature point
    for(int y = -1; y <= 1; y++) {
        for(int x = -1; x <= 1; x++) {
            float2 neighbor = float2(x, y);
            float2 point1 = AS_hash22(i + neighbor);

            // Randomize position within the cell
            float2 diff = neighbor + point1 - f;
            float dist = length(diff);

            if(dist < minDist) {
                minDist = dist;
                cellPoint = point1;
            }
        }
    }

    return minDist;
}

// Simplified version without returning cell point
float AS_voronoiNoise2D(float2 p) {
    float2 cellPoint;
    return AS_voronoiNoise2D(p, cellPoint);
}

// Advanced Voronoi with distance and cell color
float4 AS_voronoiNoise2D_Detailed(float2 p) {
    float2 i = floor(p);
    float2 f = frac(p);

    float minDist = 8.0;  // Distance to closest point
    float2 minPoint = float2(0, 0);  // Closest point
    float minPointID = 0.0;  // Identifier for closest point (for coloring)

    // Search in 3x3 neighborhood for the closest feature point
    for(int y = -1; y <= 1; y++) {
        for(int x = -1; x <= 1; x++) {
            float2 neighbor = float2(x, y);
            float2 point = AS_hash22(i + neighbor);

            // Randomize position within the cell
            float2 diff = neighbor + point - f;
            float dist = length(diff);

            if(dist < minDist) {
                minDist = dist;
                minPoint = point;
                // Use a hash of the cell coordinates as a unique cell identifier
                minPointID = AS_hash21(i + neighbor);
            }
        }
    }

    // Return distance, cell point, and cell ID
    return float4(minDist, minPoint, minPointID);
}

// Animated Voronoi. Returns: [0, ~1] (distance to nearest cell)
float AS_VoronoiNoise2DA(float2 p, float time) {
    // Add a time-based offset to the points within cells
    float2 i = floor(p);
    float2 f = frac(p);

    float minDist = 8.0;

    for(int y = -1; y <= 1; y++) {
        for(int x = -1; x <= 1; x++) {
            float2 neighbor = float2(x, y);

            // Get the base point
            float2 point = AS_hash22(i + neighbor);

            // Add time animation (circular motion within cells)
            float angle = time * AS_TWO_PI * (0.5 + 0.5 * AS_hash21(i + neighbor));
            float radius = 0.3 * AS_hash21(i + neighbor + 5.33);
            point += radius * float2(cos(angle), sin(angle));

            // Calculate distance
            float2 diff = neighbor + point - f;
            float dist = length(diff);

            if(dist < minDist) {
                minDist = dist;
            }
        }
    }

    return minDist;
}

// ============================================================================
// TURBULENCE & PATTERN VARIATIONS
// ============================================================================

// --- Turbulence ---
// Absolute value of Perlin noise creates ridge-like patterns.
// Returns: [0, unbounded) (absolute value accumulation)
float AS_TurbulenceNoise2D(float2 p, int octaves, float lacunarity, float gain) {
    float sum = 0.0;
    float amp = 1.0;
    float freq = 1.0;
    octaves = max(octaves, 1);

    for(int i = 0; i < octaves; i++) {
        sum += amp * abs(AS_PerlinNoise2D(p * freq) * 2.0 - 1.0);
        freq *= lacunarity;
        amp *= gain;
    }

    return sum;
}

// Simplified turbulence with default parameters
float AS_TurbulenceNoise2D(float2 p) {
    return AS_TurbulenceNoise2D(p, 5, 2.0, 0.5);
}

// --- Ridge Noise ---
// A variant of turbulence that creates sharp ridges. Returns: approximately [0, 1]
float AS_RidgeNoise2D(float2 p, int octaves, float lacunarity, float gain, float offset) {
    float sum = 0.0;
    float amp = 1.0;
    float freq = 1.0;
    float prev = 1.0;
    octaves = max(octaves, 1);

    for(int i = 0; i < octaves; i++) {
        float n = 1.0 - abs(AS_PerlinNoise2D(p * freq) * 2.0 - 1.0);
        n = n * n; // Sharpen the ridges
        sum += amp * n * prev;
        prev = n;
        freq *= lacunarity;
        amp *= gain;
    }

    return sum;
}

// Simplified ridge noise with default parameters
float AS_RidgeNoise2D(float2 p) {
    return AS_RidgeNoise2D(p, 5, 2.0, 0.5, 1.0);
}

// ============================================================================
// SPECIALIZED PATTERNS
// ============================================================================

// --- Wood Grain Pattern ---
// Returns: [0, 1] (frac-based, may slightly exceed with turbulence)
float AS_WoodPattern(float2 p, float rings, float turbulence) {
    // Create base ring pattern
    float distFromCenter = length(p);
    float basePattern = frac(distFromCenter * rings);

    // Add turbulence if requested
    if (turbulence > 0.0) {
        basePattern += turbulence * AS_PerlinNoise2D(p * 3.0) * 0.1;
    }

    // Create wood grain effect
    return basePattern;
}

// --- Wave Pattern ---
// Returns: [-amplitude, amplitude] (sinusoidal)
float AS_WavePattern(float2 p, float frequency, float amplitude, float phase) {
    return sin(dot(p, float2(0.0, 1.0)) * frequency + phase) * amplitude;
}

// --- Cloud Pattern ---
// Returns: [0, 1] (saturated)
float AS_CloudPattern(float2 p, float coverage, float sharpness) {
    // Use FBM for cloud shapes
    float n = AS_Fbm2D(p);

    // Apply sharpness and coverage control
    return saturate(pow(n + coverage, sharpness));
}

// Animated cloud pattern. Returns: [0, 1] (saturated)
float AS_CloudPatternA(float2 p, float time, float coverage, float sharpness) {
    // Use animated FBM for moving clouds
    float n = AS_Fbm2DA(p, time);

    // Apply sharpness and coverage control
    return saturate(pow(n + coverage, sharpness));
}

// --- Marble Pattern ---
// Returns: [0, 1] (saturated)
float AS_MarblePattern(float2 p, float scale, float sharpness) {
    float n = AS_PerlinNoise2D(p) * scale;
    return saturate(pow(0.5 + 0.5 * sin(p.x + n), sharpness));
}

// Animated marble pattern. Returns: [0, 1] (saturated)
float AS_MarblePatternA(float2 p, float time, float scale, float sharpness) {
    // Add time-based movement
    p.y += time * 0.1;
    float n = AS_PerlinNoise2D(p) * scale;
    return saturate(pow(0.5 + 0.5 * sin(p.x + n), sharpness));
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

// --- Octave noise mixer ---
// Mix different octaves of noise with weights
float AS_MixNoiseOctaves(float2 p, float weight1, float weight2, float weight3, float weight4) {
    // Normalize weights
    float totalWeight = weight1 + weight2 + weight3 + weight4;
    if (totalWeight < 0.001) return 0.0;
    float invTotalWeight = 1.0 / totalWeight;

    // Mix octaves
    return (
        weight1 * AS_PerlinNoise2D(p) +
        weight2 * AS_PerlinNoise2D(p * 2.0) +
        weight3 * AS_PerlinNoise2D(p * 4.0) +
        weight4 * AS_PerlinNoise2D(p * 8.0)
    ) * invTotalWeight;
}

// --- Noise octave selector ---
// Select a specific octave of Perlin noise
float AS_NoiseOctave(float2 p, int octave) {
    float freq = pow(2.0, float(octave));
    return AS_PerlinNoise2D(p * freq);
}

#endif // __AS_Noise_Extended_1_fxh
