/**
 * AS_Noise.1.fxh - Procedural Noise Library for AS StageFX Shader Collection
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * This header file provides procedural noise functions used across the AS StageFX
 * shader collection. It includes various noise algorithms, hash functions, and
 * procedural pattern generators for creating organic textures and effects.
 *
 * FEATURES:
 * - Fast hash functions for consistent pseudo-random number generation
 * - Value noise (2D)
 * - Perlin noise (2D and 3D)
 * - Simplex noise (3D) with FBM wrapper
 * - FBM (Fractal Brownian Motion) using Perlin noise
 *
 * IMPLEMENTATION OVERVIEW:
 * This file is organized in sections:
 * 1. Hash functions for random number generation
 * 2. Basic noise algorithms (Value, Perlin, Simplex)
 * 3. FBM (Fractal Brownian Motion)
 * 4. Utility functions
 *
 * For extended noise functions (voronoi, domain warping, turbulence,
 * ridge noise, patterns, and animated variants), see AS_Noise_Extended.1.fxh
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_Noise_1_fxh
#define __AS_Noise_1_fxh

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// HASH FUNCTIONS
// ============================================================================

// --- Fast Hash Functions ---
// 1D->1D hash. Returns: [0, 1]
float AS_hash11(float p) {
    p = frac(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return frac(p);
}

// 2D->1D hash. Returns: [0, 1]
float AS_hash21(float2 p) {
    float3 p3 = frac(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}

// 1D->2D hash. Returns: [0, 1]
float AS_hash12(float2 p) {
    // Simple dot product version
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// 2D->1D visual noise function - gives more random looking/contrasting results than hash21
// Particularly useful for jittering/dithering type effects. Returns: [0, 1]
float AS_randomNoise21(float2 p) {
    // Using trig functions for more visual randomness
    return frac(dot(sin(p * 752.322 + p.yx * 653.842), float2(254.652, 254.652)));
}

// 2D->2D hash. Returns: [0, 1] per component
float2 AS_hash22(float2 p) {
    float3 p3 = frac(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.xx + p3.yz) * p3.zy);
}

// 3D->3D hash. Returns: [-1, 1] per component
float3 AS_hash33(float3 p3) {
    p3 = frac(p3 * float3(0.1031, 0.11369, 0.13787)); // Magic numbers from Inigo Quilez
    p3 += dot(p3, p3.yxz + 19.19);
    return -1.0 + 2.0 * frac(float3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
}

// --- Shadertoy Compatible Hash Functions ---
// These provide exact compatibility with common Shadertoy implementations

// Shadertoy-style 2D->2D hash (used in QuadtreeTruchet and other ported shaders). Returns: [0, 1] per component
float2 AS_Hash22VariantB(float2 p) {
    float n = sin(dot(p, float2(57, 27)));
    return frac(float2(262144, 32768) * n);
}

// ============================================================================
// VALUE NOISE
// ============================================================================

// --- Value Noise ---
// 2D Value noise (simplified). Returns: [0, 1] (hermite interpolated)
float AS_valueNoise2D(float2 p) {
    float2 i = floor(p);
    float2 f = frac(p);
    
    // Four corners in 2D of a tile
    float a = AS_hash21(i);
    float b = AS_hash21(i + float2(1.0, 0.0));
    float c = AS_hash21(i + float2(0.0, 1.0));
    float d = AS_hash21(i + float2(1.0, 1.0));

    // Cubic Hermine curve for smooth interpolation
    float2 u = f * f * (3.0 - 2.0 * f);
    
    // Mix 4 corners
    return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// ============================================================================
// PERLIN NOISE
// ============================================================================

// --- Perlin Noise ---
// Classic 2D Perlin noise. Returns: approximately [-0.5, 0.5]
float AS_PerlinNoise2D(float2 p) {
    float2 i = floor(p);
    float2 f = frac(p);
    
    // Quintic interpolation curve
    float2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    
    // Get random vectors at the corners
    float2 ga = AS_hash22(i) * 2.0 - 1.0;
    float2 gb = AS_hash22(i + float2(1.0, 0.0)) * 2.0 - 1.0;
    float2 gc = AS_hash22(i + float2(0.0, 1.0)) * 2.0 - 1.0;
    float2 gd = AS_hash22(i + float2(1.0, 1.0)) * 2.0 - 1.0;
    
    // Calculate dot products
    float va = dot(ga, f);
    float vb = dot(gb, f - float2(1.0, 0.0));
    float vc = dot(gc, f - float2(0.0, 1.0));
    float vd = dot(gd, f - float2(1.0, 1.0));
    
    // Interpolate the four corners
    return va + u.x * (vb - va) + u.y * (vc - va) + u.x * u.y * (va - vb - vc + vd);
}

// --- Perlin Noise 3D ---
// Classic 3D Perlin noise implementation. Returns: [0, 1] (remapped from [-1,1])
float AS_PerlinNoise3D(float3 p) {
    float3 i = floor(p);
    float3 f = frac(p);
    
    // Quintic interpolation curve
    float3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    
    // Calculate grid point coordinate hashes
    float n000 = dot(AS_hash33(i), f);
    float n100 = dot(AS_hash33(i + float3(1.0, 0.0, 0.0)), f - float3(1.0, 0.0, 0.0));
    float n010 = dot(AS_hash33(i + float3(0.0, 1.0, 0.0)), f - float3(0.0, 1.0, 0.0));
    float n110 = dot(AS_hash33(i + float3(1.0, 1.0, 0.0)), f - float3(1.0, 1.0, 0.0));
    float n001 = dot(AS_hash33(i + float3(0.0, 0.0, 1.0)), f - float3(0.0, 0.0, 1.0));
    float n101 = dot(AS_hash33(i + float3(1.0, 0.0, 1.0)), f - float3(1.0, 0.0, 1.0));
    float n011 = dot(AS_hash33(i + float3(0.0, 1.0, 1.0)), f - float3(0.0, 1.0, 1.0));
    float n111 = dot(AS_hash33(i + float3(1.0, 1.0, 1.0)), f - float3(1.0, 1.0, 1.0));
    
    // Interpolate along x
    float nx00 = lerp(n000, n100, u.x);
    float nx01 = lerp(n001, n101, u.x);
    float nx10 = lerp(n010, n110, u.x);
    float nx11 = lerp(n011, n111, u.x);
    
    // Interpolate along y
    float nxy0 = lerp(nx00, nx10, u.y);
    float nxy1 = lerp(nx01, nx11, u.y);
    
    // Interpolate along z and normalize output to [-1, 1] range
    return lerp(nxy0, nxy1, u.z) * 0.5 + 0.5;
}

// ============================================================================
// SIMPLEX NOISE 3D (misterprada/celestianmaze compatible variant)
// ============================================================================

// mod helpers to avoid reliance on fmod overloads
float4 AS_snMod289(float4 x) { return x - floor(x * (1.0f/289.0f)) * 289.0f; }
float3 AS_snMod289_3(float3 x) { return x - floor(x * (1.0f/289.0f)) * 289.0f; }

float4 AS_snPerm4(float4 x) { return AS_snMod289(((x * 34.0f) + 1.0f) * x); }
float4 AS_snTaylorInvSqrt4(float4 r) { return 1.79284291400159f - 0.85373472095314f * r; }

// 3D Simplex noise. Returns: approximately [-1, 1]
float AS_SimplexNoise3D(float3 v)
{
    const float2 C = float2(1.0f/6.0f, 1.0f/3.0f);
    const float4 D = float4(0.0f, 0.5f, 1.0f, 2.0f);
    float3 i  = floor(v + dot(v, float3(C.y, C.y, C.y)));
    float3 x0 =    v - i + dot(i, float3(C.x, C.x, C.x));

    float3 g = step(x0.yzx, x0.xyz);
    float3 l = 1.0f - g;
    float3 i1 = min(g.xyz, l.zxy);
    float3 i2 = max(g.xyz, l.zxy);

    float3 x1 = x0 - i1 + float3(C.x, C.x, C.x);
    float3 x2 = x0 - i2 + float3(C.y, C.y, C.y);
    float3 x3 = x0 - 1.0f + float3(0.5f, 0.5f, 0.5f);

    i = AS_snMod289_3(i);
    float4 p = AS_snPerm4(AS_snPerm4(AS_snPerm4( i.z + float4(0.0f, i1.z, i2.z, 1.0f)) + i.y + float4(0.0f, i1.y, i2.y, 1.0f)) + i.x + float4(0.0f, i1.x, i2.x, 1.0f));
    float n_ = 1.0f/7.0f;
    float3 ns = n_ * float3(D.w, D.y, D.z) - float3(D.x, D.z, D.x);
    float4 j = p - 49.0f * floor(p * ns.z * ns.z);
    float4 x_ = floor(j * ns.z);
    float4 y_ = floor(j - 7.0f * x_);
    float4 x = x_ * ns.x + ns.yyyy;
    float4 y = y_ * ns.x + ns.yyyy;
    float4 h = 1.0f - abs(x) - abs(y);

    float4 b0 = float4(x.xy, y.xy);
    float4 b1 = float4(x.zw, y.zw);

    float4 s0 = floor(b0) * 2.0f + 1.0f;
    float4 s1 = floor(b1) * 2.0f + 1.0f;
    float4 sh = -step(h, float4(0.0f, 0.0f, 0.0f, 0.0f));

    float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

    float3 p0 = float3(a0.xy, h.x);
    float3 p1 = float3(a0.zw, h.y);
    float3 p2 = float3(a1.xy, h.z);
    float3 p3 = float3(a1.zw, h.w);

    float4 norm = AS_snTaylorInvSqrt4(float4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
    p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;

    float4 m = max(0.6f - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0f);
    m = m * m;
    return 42.0f * dot(m * m, float4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
}

// FBM using 3D simplex noise. Returns: unbounded (accumulated octaves)
float AS_fbm3D(float3 x, const int it)
{
    float v = 0.0f; float a = 0.5f;
    float3 shift = float3(100.0f, 100.0f, 100.0f);
    [loop]
    for (int i = 0; i < 32; ++i) {
        if (i < it) { v += a * AS_SimplexNoise3D(x); x = x * 2.0f + shift; a *= 0.5f; }
        else { break; }
    }
    return v;
}

// ============================================================================
// FBM (FRACTAL BROWNIAN MOTION)
// ============================================================================

// Default FBM parameters
static const int AS_FBM_DEFAULT_OCTAVES = 5;
static const float AS_FBM_DEFAULT_LACUNARITY = 2.0f;
static const float AS_FBM_DEFAULT_GAIN = 0.5f;

// --- Fractal Brownian Motion ---
// FBM builds on top of Perlin noise to create natural-looking textures.
// Returns: approximately [-1, 1] (depends on octaves and gain)
float AS_Fbm2D(float2 p, int octaves, float lacunarity, float gain) {
    float sum = 0.0;
    float amp = 1.0;
    float freq = 1.0;
    // Prevent zero or negative octaves
    octaves = max(octaves, 1);
    
    for(int i = 0; i < octaves; i++) {
        sum += amp * AS_PerlinNoise2D(p * freq);
        freq *= lacunarity;
        amp *= gain;
    }
    
    return sum;
}

// Simplified FBM with default parameters
float AS_Fbm2D(float2 p) {
    return AS_Fbm2D(p, AS_FBM_DEFAULT_OCTAVES, AS_FBM_DEFAULT_LACUNARITY, AS_FBM_DEFAULT_GAIN);
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

// --- Map noise range ---
// Remap a noise value from [-1,1] to [0,1]. Returns: [0, 1]
float AS_remapNoiseZeroToOne(float noise) {
    return 0.5 + 0.5 * noise;
}

// Additional noise functions (voronoi, domain warping, turbulence, ridge, patterns)
// are available in AS_Noise_Extended.1.fxh

#endif // __AS_Noise_1_fxh

