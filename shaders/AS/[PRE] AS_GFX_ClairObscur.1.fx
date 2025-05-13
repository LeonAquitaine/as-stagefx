/**
 * AS_GFX_ClairObscur.1.fx - Floating Petals Visual Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION: * Creates a beautiful cascade of floating petals with realistic movement and organic animation.
 * This effect simulates petals drifting through the air with natural rotation variation and 
 * elegant entrance/exit effects.
 *
 * FEATURES:
 * - Physically-based petal movement with drift, flutter, and sway behaviors
 * - Multi-layered depth simulation with perspective scaling
 * - Natural rotation variation with independently controlled speed and amplitude
 * - Elegant entrance/exit effects with rotation along configurable axis
 * - Audio reactivity with multiple parameter targeting options
 * - Comprehensive boundary checking to prevent petal cutoff at cell boundaries
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Uses a Voronoi-style cell pattern to place petals efficiently
 * 2. Simulates organic movement through combined noise functions
 * 3. Implements multi-layered rendering for depth perception
 * 4. Features optimized boundary checking to prevent visual artifacts
 * 5. Supports both transparent and opaque rendering modes
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_GFX_ClairObscur_1_fx
#define __AS_GFX_ClairObscur_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_getTime()
#include "AS_Noise.1.fxh" // For noise functions and hash functions

// --- Textures ---
texture PetalFlutter_NoiseSourceTexture < source = "perlin512x8Noise.png"; > { Width = 512; Height = 512; Format = R8; };
sampler PetalFlutter_samplerNoiseSource { Texture = PetalFlutter_NoiseSourceTexture; AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };

texture PetalShape_Texture1 < source = "AS_RedRosePetal1.png"; > { Width = 512; Height = 512; Format = RGBA8; };
sampler PetalShape_Sampler1 { Texture = PetalShape_Texture1; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };

texture PetalShape_Texture2 < source = "AS_RedRosePetal2.png"; > { Width = 512; Height = 512; Format = RGBA8; };
sampler PetalShape_Sampler2 { Texture = PetalShape_Texture2; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };

// --- Constants ---
#define ALPHA_THRESHOLD 0.01      // Minimum alpha value for a petal to be considered visible

// --- UI Uniforms ---

// ---- Stage Controls ----
AS_STAGEDEPTH_UI(ClairObscur_StageDepth)

// ---- Petal Appearance ----
uniform float3 PetalColor < ui_type = "color"; ui_label = "Petal Color"; ui_category = "Petals"; > = float3(1.0, 1.0, 1.0);
uniform float PetalBaseAlpha < ui_type = "slider"; ui_label = "Opacity"; ui_category = "Petals"; ui_min = 0.0; ui_max = 1.0; > = 0.8;
uniform float PetalBaseSize < ui_type = "slider"; ui_label = "Size"; ui_category = "Petals"; ui_min = 0.001; ui_max = 0.5; ui_step=0.001; > = 0.05; 
uniform float PetalSizeVariation < ui_type = "slider"; ui_label = "Size Variation"; ui_category = "Petals"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; > = 0.3;
uniform int PetalShadingMode < ui_type = "combo"; ui_label = "Overlapping Mode"; ui_category = "Petals"; ui_items = "Transparent Blend\0Opaque (Solid)\0"; ui_tooltip = "Choose how petals blend with the scene."; > = 0;

// ---- Layers ----
uniform float GlobalVoronoiDensity < ui_type = "slider"; ui_label = "Density"; ui_category = "Layers"; ui_min = 1.0; ui_max = 30.0; ui_step = 0.5; > = 7.0; 
uniform int NumLayers < ui_type = "slider"; ui_label = "Number of Layers"; ui_category = "Layers"; ui_min = 1; ui_max = 30; > = 15;
uniform float LayerSizeMod < ui_type = "slider"; ui_label = "Layer Size Progression"; ui_category = "Layers"; ui_tooltip = "How much size changes between layers (perspective effect)"; ui_min = 0.8; ui_max = 1.2; ui_step=0.01; > = 1.05;
uniform float LayerAlphaMod < ui_type = "slider"; ui_label = "Layer Opacity Falloff"; ui_category = "Layers"; ui_tooltip = "How quickly opacity decreases with depth"; ui_min = 0.7; ui_max = 1.0; ui_step=0.01; > = 0.85;


// ---- Movement & Animation ----
uniform float SimulationSpeed < ui_type = "slider"; ui_label = "Animation Speed"; ui_category = "Movement"; ui_min = 0.0; ui_max = 2.0; > = 0.5;
uniform float BasePetalSpinSpeed < ui_type = "slider"; ui_label = "Rotation Speed"; ui_category = "Movement"; ui_min = 0.0; ui_max = 10.0; > = 1.5;
uniform float RotationVariationSpeed < ui_type = "slider"; ui_label = "Rotation Variation Speed"; ui_category = "Movement"; ui_tooltip = "Controls the speed of unpredictable rotation with noise-driven patterns"; ui_min = 0.0; ui_max = 2.0; > = 0.5;
uniform float RotationVariationAmplitude < ui_type = "slider"; ui_label = "Rotation Variation Amplitude"; ui_category = "Movement"; ui_tooltip = "Controls the magnitude of rotation variation"; ui_min = 0.0; ui_max = 1.0; > = 0.4;
uniform float BaseDriftSpeed < ui_type = "slider"; ui_label = "Drift Speed"; ui_category = "Movement"; ui_min = 0.0; ui_max = 2.0; ui_step=0.01; > = 0.1;
uniform float2 UserDirection < ui_type = "slider"; ui_label = "Flow Direction"; ui_category = "Movement"; ui_min = -1.0; ui_max = 1.0; > = float2(0.1, -0.3);
uniform float BaseFlutterStrength < ui_type = "slider"; ui_label = "Flutter Intensity"; ui_category = "Movement"; ui_min = 0.0; ui_max = 0.2; ui_step = 0.005; > = 0.02;
uniform float SwayMagnitude < ui_type = "slider"; ui_label = "Sway Amount"; ui_category = "Movement"; ui_min = 0.0; ui_max = 0.05; ui_step = 0.001; > = 0.005;
uniform float Lifetime < ui_type = "slider"; ui_label = "Petal Lifespan"; ui_category = "Movement"; ui_min = 1.0; ui_max = 20.0; > = 10.0;

// ---- Entrance/Exit Effect ----
uniform float FlipScaleMin < ui_type = "slider"; ui_label = "Edge Thinness"; ui_category = "Entrance/Exit Effect"; ui_tooltip = "How thin petals appear when entering/exiting the scene"; ui_min = 0.01; ui_max = 0.5; > = 0.05;
uniform float FlipAxis < ui_type = "slider"; ui_label = "Rotation Axis"; ui_category = "Entrance/Exit Effect"; ui_tooltip = "Direction petals rotate when entering/exiting (0=horizontal, 1=vertical)"; ui_min = 0.0; ui_max = 1.0; > = 0.3;
uniform float FlipLifecycleBias < ui_type = "slider"; ui_label = "Rotation Timing"; ui_category = "Entrance/Exit Effect"; ui_tooltip = "Controls how quickly petals rotate to face the camera"; ui_min = 1.0; ui_max = 5.0; > = 2.0;

// ---- Advanced Settings ----
uniform float DensityThreshold < ui_type = "slider"; ui_label = "Spawn Threshold"; ui_category = "Advanced"; ui_category_closed = true; ui_min = 0.0; ui_max = 1.0; ui_tooltip = "Controls overall petal quantity"; > = 0.4;
uniform float DensityFadeRange < ui_type = "slider"; ui_label = "Spawn Fade Range"; ui_category = "Advanced"; ui_category_closed = true; ui_min = 0.01; ui_max = 0.5; > = 0.15;
uniform float NoiseTexScale < ui_type = "slider"; ui_label = "Density Pattern Scale"; ui_category = "Advanced"; ui_category_closed = true; ui_min = 0.1; ui_max = 10.0; > = 1.0; 
uniform float VoronoiPointSpinSpeed < ui_type = "slider"; ui_label = "Pattern Rotation Speed"; ui_category = "Advanced"; ui_category_closed = true; ui_min = 0.0; ui_max = 5.0; > = 0.3;
uniform float DensityCellRepeatScale < ui_type = "slider"; ui_label = "Density Pattern Repeat"; ui_category = "Advanced"; ui_category_closed = true; ui_min = 1.0; ui_max = 100.0; ui_tooltip="How often the density pattern repeats"; > = 20.0; 
uniform bool EnableBoundaryChecking < ui_label = "Fix Petal Cutoff"; ui_category = "Advanced"; ui_category_closed = true; ui_tooltip="Enable searching adjacent cells to prevent petal cutoff at boundaries"; > = true;
uniform int BoundaryCheckLayers < ui_type = "slider"; ui_label = "Boundary Check Layers"; ui_category = "Advanced"; ui_category_closed = true; ui_min = 0; ui_max = 3; ui_tooltip="Number of neighboring cell layers to check (0=none, 1=immediate neighbors, 2=two layers deep, etc.)"; > = 1;
uniform float BorderCheckMargin < ui_type = "slider"; ui_label = "Boundary Check Margin"; ui_category = "Advanced"; ui_category_closed = true; ui_min = 1.0; ui_max = 5.0; ui_tooltip="Controls how far to check for petals crossing cell boundaries (higher values prevent cutoff but may impact performance)"; > = 1.5;

// ---- Debug Tools ----
uniform int DebugMode <
    ui_type = "combo"; ui_label = "Debug View";
    ui_category = "Debug"; ui_category_closed = true;
    ui_items = "Normal Effect\0"
               "Density Visualization\0" 
               "Cell Structure\0"
               "Single Petal Alpha\0"
               "Flutter Effect\0"
               "Petal Texture Test\0"; 
    ui_tooltip = "Tools for visualizing different aspects of the effect.";
> = 0;


// --- Custom Vector Noise Function Based on AS_Noise Library ---
// 2D->2D vector noise function that produces consistent, smooth 2D vector field
float2 AS_VectorNoise2D(float2 uv) { 
    float2 fract_uv = frac(uv); 
    float2 f = smoothstep(0.0, 1.0, fract_uv); 
    float2 uv00 = floor(uv); 
    float2 v00 = AS_hash22(uv00); 
    float2 v01 = AS_hash22(uv00 + float2(0,1)); 
    float2 v10 = AS_hash22(uv00 + float2(1,0)); 
    float2 v11 = AS_hash22(uv00 + float2(1,1)); 
    float2 v0 = lerp(v00, v01, f.y); 
    float2 v1 = lerp(v10, v11, f.y); 
    return lerp(v0, v1, f.x); 
}

// --- Helper Functions ---
float2 ps_rotate(float2 p_to_rotate, float rad) { float s = sin(rad); float c = cos(rad); return float2(p_to_rotate.x * c - p_to_rotate.y * s, p_to_rotate.x * s + p_to_rotate.y * c); }

// --- Voronoi and Particle Drawing ---
float degToRad(float deg) { return deg * AS_PI / 180.0; }
float calcVoronoiPointRotRad(float2 rootUV, float time) { return time * VoronoiPointSpinSpeed * (AS_hash21(rootUV) - 0.5) * 2.0 * AS_TWO_PI; }
float2 getVoronoiPoint(float2 rootUV, float rad) { float2 calculatedPt = AS_hash22(rootUV) - 0.5; calculatedPt = ps_rotate(calculatedPt, rad) * 0.66; calculatedPt += rootUV + float2(0.5, 0.5); return calculatedPt; }

// currentWindStrength parameter is kept here, but will receive 0.0f due to the #define path
float4 DrawPetalInstance(float2 uvForVoronoiLookup, float2 originalScreenUV, float instanceSeed, float currentTime, 
                         float currentLayerAlphaMod, float2 driftVelocityForSway) 
{ 
    float2 rootUV = floor(uvForVoronoiLookup);

    float2 density_sample_uv = frac(rootUV / DensityCellRepeatScale); 
    float instanceDensityNoise = tex2D(PetalFlutter_samplerNoiseSource, density_sample_uv * NoiseTexScale + currentTime * 0.005).r; 
    float instanceDensityFactor = smoothstep(
        DensityThreshold - DensityFadeRange * 0.5,
        DensityThreshold + DensityFadeRange * 0.5,
        instanceDensityNoise
    );    if (instanceDensityFactor < ALPHA_THRESHOLD) { 
        return float4(0.0, 0.0, 0.0, 0.0); 
    }

    float voronoiPointRotRad = calcVoronoiPointRotRad(rootUV, currentTime);
    float2 petalInstanceCenter_NoSway = getVoronoiPoint(rootUV, voronoiPointRotRad);    float swayTime = currentTime * SimulationSpeed * 0.7 + instanceSeed * 5.0;
    float swayAngle_calc = swayTime * (1.5 + AS_hash21(rootUV + 0.3) * 1.5) + AS_hash21(rootUV + instanceSeed * 0.7) * AS_TWO_PI;
    float2 swayDirVec = float2(driftVelocityForSway.y, -driftVelocityForSway.x); 
    if (length(swayDirVec) < 0.001) swayDirVec = float2(1.0, 0.0); 
    else swayDirVec = normalize(swayDirVec);
    float2 swayOffset = swayDirVec * sin(swayAngle_calc) * SwayMagnitude;
    float2 finalPetalInstanceCenter = petalInstanceCenter_NoSway + swayOffset;    float timeOffset = AS_hash21(rootUV + instanceSeed) * Lifetime;    float instanceTimeRaw = (currentTime * SimulationSpeed + timeOffset);
    float time_val = instanceTimeRaw / Lifetime;
    float normalizedTime = time_val - floor(time_val); 
    
    float petalRandomFactor = AS_hash21(rootUV + instanceSeed * 0.31);

    // Create a smooth bell curve for the lifecycle - for both opacity and edge-on scaling
    // This gives us a more natural appearance where petals gradually turn from edge-on to face-on and back
    float fadeIn = smoothstep(0.0, 0.20, normalizedTime); 
    float fadeOut = smoothstep(1.0, 0.80, normalizedTime); 
    float lifetimeAlpha = fadeIn * fadeOut;    // Apply a subtle, additional oscillation to the rotation during lifecycle
    // Creates a gentle wobbling effect as petals fall, like real petals in air
    float lifetimeOscillation = 0.0;
    if (RotationVariationAmplitude > 0.0) {
        // Create lifecycle-specific texture coordinates for sampling noise
        float2 lifecycleNoiseUV = float2(
            frac(normalizedTime + petalRandomFactor * 3.7),
            frac(petalRandomFactor * 2.9 + instanceTimeRaw * 0.01 * RotationVariationSpeed)
        );
        
        // Sample noise texture for organic variation
        float lifecycleNoise = tex2D(PetalFlutter_samplerNoiseSource, lifecycleNoiseUV).r * 2.0 - 1.0; // -1 to 1
        
        // Create a complex oscillation based on lifecycle phase
        float lifetimeFrequency = 1.0 + petalRandomFactor * 3.0;
        
        // Main cycle - one complete oscillation during lifecycle
        float mainCycle = sin(normalizedTime * AS_TWO_PI * lifetimeFrequency * RotationVariationSpeed);
        
        // Add micro-oscillations that vary in intensity based on lifecycle phase
        // These create subtle "turbulence" effects when petals are most vulnerable (beginning/end)
        float entryPhase = smoothstep(0.0, 0.3, normalizedTime);
        float exitPhase = smoothstep(1.0, 0.7, normalizedTime);
        
        // Calculate vulnerability - highest at beginning and end, lowest in middle
        float vulnerability = 1.0 - (entryPhase * exitPhase * 4.0); // Peaks at 0 and 1, minimum at 0.5
        
        // Modify vulnerability by noise to make transitions less predictable
        vulnerability *= (1.0 + lifecycleNoise * 0.3);
        
        // Create texture-driven micro-turbulence that's strongest at entry/exit
        float microTurbulence = lifecycleNoise * vulnerability * 0.5;
        
        // Add a subtle higher frequency oscillation modulated by noise
        float highFreqComponent = sin(normalizedTime * AS_TWO_PI * lifetimeFrequency * (2.5 + lifecycleNoise) * RotationVariationSpeed) * 0.2;
        
        // Combine oscillations with dynamic weighting based on lifecycle phase
        // Main cycle dominates in middle, turbulence at edges
        lifetimeOscillation = mainCycle * (1.0 - vulnerability * 0.7) + microTurbulence + highFreqComponent;
        
        // Scale by lifecycle phase and add a subtle non-linear response
        // The sqrt makes smaller oscillations more pronounced
        lifetimeOscillation *= lifetimeAlpha * 0.3 * sqrt(RotationVariationAmplitude);
    }
    if (lifetimeAlpha <= ALPHA_THRESHOLD) {
        return float4(0.0, 0.0, 0.0, 0.0);
    }    
    
    // Apply subtle wobble to alpha for more natural appearance
    lifetimeAlpha = max(0.001, lifetimeAlpha * (1.0 + lifetimeOscillation * 0.1));

    float2 petalSpaceUV_raw = uvForVoronoiLookup - finalPetalInstanceCenter;
    
    // Calculate natural, organic rotation with variation
    float effectiveSpinSpeed = BasePetalSpinSpeed;    // Create unique characteristics for each petal's rotation variation
    float baseFrequency = 1.0 + petalRandomFactor * 2.0;
    float phaseOffset = petalRandomFactor * AS_TWO_PI; // Random phase offset for each petal
    
    // Base linear rotation with random initial rotation
    float baseSpinAngle = instanceTimeRaw * effectiveSpinSpeed * (0.75 + petalRandomFactor * 0.5) + petalRandomFactor * AS_TWO_PI;
    
    // Complex multi-frequency system with varied phases and amplitudes
    float timeBase = instanceTimeRaw * baseFrequency * RotationVariationSpeed;
    
    // Sample noise texture for additional organic variation
    // Create unique texture coordinates for each petal based on its random characteristics
    float2 noiseUV1 = float2(
        frac(petalRandomFactor * 7.89 + timeBase * 0.05), 
        frac(petalRandomFactor * 3.21 + timeBase * 0.03)
    );
    float2 noiseUV2 = float2(
        frac(petalRandomFactor * 1.43 + timeBase * 0.07), 
        frac(petalRandomFactor * 9.76 + timeBase * 0.02)
    );
    
    // Sample noise texture at two different locations and times for varied input
    float noise1 = tex2D(PetalFlutter_samplerNoiseSource, noiseUV1).r * 2.0 - 1.0; // -1 to 1 range
    float noise2 = tex2D(PetalFlutter_samplerNoiseSource, noiseUV2).r * 2.0 - 1.0; // -1 to 1 range
    
    // Use noise as multipliers for oscillation frequencies to create unpredictable timing
    float freqModifier1 = 1.0 + noise1 * 0.3;
    float freqModifier2 = 1.0 + noise2 * 0.2;
    
    // Primary slow oscillation with frequency modified by noise
    float oscillation1 = sin(timeBase * 0.23 * freqModifier1 + phaseOffset) * 0.45;
    
    // Secondary medium oscillation with phase shift and frequency modified by noise
    float oscillation2 = sin(timeBase * 0.57 * freqModifier2 + phaseOffset * 1.3) * 0.30;
    
    // Tertiary fast oscillation - creates fine detail
    float oscillation3 = sin(timeBase * 1.38 + phaseOffset * 0.7) * 0.15;
    
    // Quarter-frequency very slow oscillation - adds long-term variation
    float oscillation4 = sin(timeBase * 0.11 + phaseOffset * 1.7) * 0.20;
    
    // Add a chaotic component driven directly by the noise texture
    // This creates non-sinusoidal, unpredictable movements that break the pattern
    float chaosComponent = (noise1 * noise2) * 0.15;
    
    // Create additional complexity with non-harmonic frequencies
    float microVariation = sin(timeBase * 3.14159) * sin(timeBase * 2.71828) * 0.10;
    
    // Combine all oscillations with different weights
    float rawVariation = oscillation1 + oscillation2 + oscillation3 + oscillation4 + microVariation + chaosComponent;
    
    // Apply a non-linear response curve using the noise values to create dynamic acceleration
    float noiseInfluence = lerp(0.8, 1.2, (noise1 + 1.0) * 0.5); // 0.8 to 1.2 range
    float normalizedVariation = rawVariation / (1.2 * noiseInfluence); // Normalize with noise-influenced scaling
    
    // Apply complex non-linear curve - stronger effect when variation is small, gentler when large
    float curvedVariation = normalizedVariation * (1.0 - 0.2 * abs(normalizedVariation)) * (1.0 + noise2 * 0.1);
    
    // Apply the final variation scaled by user control parameter
    float variationAngle = curvedVariation * RotationVariationAmplitude * 0.5;
    
    // Apply the variation by adding to the base angle (not multiplying)
    float spinAngle = baseSpinAngle + variationAngle;
    
    float2 rotatedPetalSpaceUV = ps_rotate(petalSpaceUV_raw, spinAngle);
      // Apply the lifecycle flip effect - scale differently based on normalized time
    // When lifetimeAlpha is 0 (start/end of life) -> scale by FlipScaleMin
    // When lifetimeAlpha is 1 (middle of life) -> scale by 1.0
    // Apply the FlipLifecycleBias to make the transition between edge-on and face-on more controllable
    // Higher bias means petals spend more time in the edge-on state
    float biasedLifetimeAlpha = pow(lifetimeAlpha, 1.0 / FlipLifecycleBias);
    float flipScale = lerp(FlipScaleMin, 1.0, biasedLifetimeAlpha);
    
    // Apply the scale factor along the chosen axis (controlled by FlipAxis)
    // When FlipAxis = 0.0 -> scale horizontally
    // When FlipAxis = 1.0 -> scale vertically 
    float2 flipScaleFactor = lerp(float2(flipScale, 1.0), float2(1.0, flipScale), FlipAxis);
    
    // Apply scaling to UV coordinates correctly to simulate the edge-on effect
    // We need to divide the UVs by the flipScaleFactor to make the petal appear thinner
    // This makes the petal appear compressed along the chosen axis when entering/exiting
    rotatedPetalSpaceUV = rotatedPetalSpaceUV / flipScaleFactor;

    float sizeVariation = (petalRandomFactor - 0.5) * 2.0 * PetalSizeVariation;
    float currentPetalVisualSize = PetalBaseSize * (1.0 + sizeVariation); 
    if (currentPetalVisualSize <= 0.0001) currentPetalVisualSize = 0.0001;
    
    float2 texLookupUV = (rotatedPetalSpaceUV / currentPetalVisualSize) + 0.5;

    float4 petalTextureSample;
    if (petalRandomFactor < 0.5) { 
        petalTextureSample = tex2D(PetalShape_Sampler1, texLookupUV);
    } else {
        petalTextureSample = tex2D(PetalShape_Sampler2, texLookupUV);
    }
    
    float3 colorFromTexture = petalTextureSample.rgb;
    float petalShapeAlpha = petalTextureSample.a;

    float screenFade = 1.0; 

    float finalAlpha = petalShapeAlpha * lifetimeAlpha * PetalBaseAlpha * currentLayerAlphaMod * screenFade * instanceDensityFactor;
    float3 finalPetalRgb = colorFromTexture * PetalColor.rgb;

    return float4(finalPetalRgb, finalAlpha);
}

// RenderPetalLayers now respects the PetalShadingMode for layering behavior
float4 RenderPetalLayers(float2 baseCenteredAspectUV, float2 originalScreenUV, float currentTime) { 
    float4 accumulatedColor = float4(0.0, 0.0, 0.0, 0.0); 
    float currentLayerSizeFactor = 1.0; 
    float currentLayerAlphaFactor = 1.0; 
    float2 layerGlobalOffset = float2(0.0, 0.0);     // No [loop] attribute added here, per user's observation that the base was functional
    for (int i = 0; i < NumLayers; i++) {
        float effectiveFlutterStrength = BaseFlutterStrength ; 
        float2 flutterOffset = (AS_VectorNoise2D(baseCenteredAspectUV * currentLayerSizeFactor * 2.0 + currentTime * 0.2 + float(i)*0.1) - 0.5) * effectiveFlutterStrength * currentLayerSizeFactor;
        
        float2 driftVelocity = UserDirection * BaseDriftSpeed * (1.0 / currentLayerSizeFactor); 

        float2 driftOffset = currentTime * driftVelocity; 
        
        float2 uvForVoronoiLookup = (baseCenteredAspectUV * currentLayerSizeFactor) + driftOffset + layerGlobalOffset + flutterOffset;        // First, render the petal from the primary cell
        float4 petalLayerColor = DrawPetalInstance(uvForVoronoiLookup, originalScreenUV, float(i) * 0.123, currentTime, currentLayerAlphaFactor, driftVelocity);
            // ==========================================================================================
        // BOUNDARY CHECKING SYSTEM - Prevents petal cutoff at cell boundaries
        // ==========================================================================================
        if (EnableBoundaryChecking && BoundaryCheckLayers > 0) {
            // Calculate maximum petal radius (with boundary margin) in grid space
            float maxPetalRadius = PetalBaseSize * (1.0 + PetalSizeVariation) * BorderCheckMargin;
            float gridSpacePetalRadius = maxPetalRadius * currentLayerSizeFactor;
            
            // Determine our position within the current cell
            float2 cellFrac = frac(uvForVoronoiLookup);
            float2 distToEdge = min(cellFrac, 1.0 - cellFrac);
            float minDistToEdge = min(distToEdge.x, distToEdge.y);
            
            // Using a preprocessor macro to avoid code duplication
            #define PROCESS_ADJACENT_PETAL(ox, oy) \
            { \
                float2 adjacentUV = uvForVoronoiLookup + float2(ox, oy); \
                float4 adjacentPetalColor = DrawPetalInstance(adjacentUV, originalScreenUV, float(i) * 0.123, currentTime, currentLayerAlphaFactor, driftVelocity); \
                \
                if (adjacentPetalColor.a > ALPHA_THRESHOLD) { \
                    if (PetalShadingMode == 1) { /* Opaque Mode */ \
                        float occupancyMask = (1.0 - step(ALPHA_THRESHOLD, petalLayerColor.a)); \
                        petalLayerColor.rgb = lerp(petalLayerColor.rgb, adjacentPetalColor.rgb, adjacentPetalColor.a * occupancyMask); \
                        petalLayerColor.a = max(petalLayerColor.a, adjacentPetalColor.a * occupancyMask); \
                    } else { /* Transparent Mode */ \
                        petalLayerColor.rgb = lerp(petalLayerColor.rgb, adjacentPetalColor.rgb, adjacentPetalColor.a * (1.0 - petalLayerColor.a)); \
                        petalLayerColor.a = petalLayerColor.a + adjacentPetalColor.a * (1.0 - petalLayerColor.a); \
                    } \
                } \
            }
            
            // First layer (immediate neighbors) - always check if BoundaryCheckLayers >= 1
            if (BoundaryCheckLayers >= 1) {
                // Only process boundaries if we're close enough to an edge (performance optimization)
                if (minDistToEdge < gridSpacePetalRadius) {
                    // Special handling for diagonal corners - using precise distance calculation
                    bool nearCorner = false;
                    
                    // If close to both x and y edges, check corner proximity using Euclidean distance
                    if (distToEdge.x < gridSpacePetalRadius && distToEdge.y < gridSpacePetalRadius) {                    
                        // Find the closest corner position
                        float2 cornerPos;
                        cornerPos.x = (cellFrac.x < 0.5) ? 0.0 : 1.0;
                        cornerPos.y = (cellFrac.y < 0.5) ? 0.0 : 1.0;
                        
                        // Calculate exact distance to corner
                        float2 cornerOffset = abs(cellFrac - cornerPos);
                        float cornerDist = length(cornerOffset);
                        
                        // Use AS_SQRT_TWO constant for diagonal distance factor
                        nearCorner = (cornerDist < gridSpacePetalRadius * AS_SQRT_TWO);
                    }
                    
                    // Determine which cell boundaries need checking based on our position
                    bool checkLeft = distToEdge.x < gridSpacePetalRadius && cellFrac.x < 0.5;
                    bool checkRight = distToEdge.x < gridSpacePetalRadius && cellFrac.x >= 0.5;
                    bool checkTop = distToEdge.y < gridSpacePetalRadius && cellFrac.y < 0.5;
                    bool checkBottom = distToEdge.y < gridSpacePetalRadius && cellFrac.y >= 0.5;
                    
                    // Determine which diagonal cells to check if we're near a corner
                    bool checkTopLeft = nearCorner && cellFrac.x < 0.5 && cellFrac.y < 0.5;
                    bool checkTopRight = nearCorner && cellFrac.x >= 0.5 && cellFrac.y < 0.5;
                    bool checkBottomLeft = nearCorner && cellFrac.x < 0.5 && cellFrac.y >= 0.5;
                    bool checkBottomRight = nearCorner && cellFrac.x >= 0.5 && cellFrac.y >= 0.5;
                    
                    // Process all required boundaries in a structured way without loops
                    // First check cardinal directions (more likely to have petals crossing)
                    if (checkLeft)        PROCESS_ADJACENT_PETAL(-1,  0);
                    if (checkRight)       PROCESS_ADJACENT_PETAL( 1,  0);
                    if (checkTop)         PROCESS_ADJACENT_PETAL( 0, -1);
                    if (checkBottom)      PROCESS_ADJACENT_PETAL( 0,  1);
                    
                    // Then check diagonal directions (only when near corners)
                    if (checkTopLeft)     PROCESS_ADJACENT_PETAL(-1, -1);
                    if (checkTopRight)    PROCESS_ADJACENT_PETAL( 1, -1);
                    if (checkBottomLeft)  PROCESS_ADJACENT_PETAL(-1,  1);
                    if (checkBottomRight) PROCESS_ADJACENT_PETAL( 1,  1);
                }
            }
              // Second layer of neighbors - only check if BoundaryCheckLayers >= 2
            if (BoundaryCheckLayers >= 2) {
                // Expand our check to second layer
                // Extended offset range for the second layer: -2, -1, 0, 1, 2
                for (int y = -2; y <= 2; y++) {
                    for (int x = -2; x <= 2; x++) {
                        // Skip the cells we've already processed (the first layer and center)
                        if (abs(x) <= 1 && abs(y) <= 1)
                            continue;
                            
                        // For the second layer, we only need to process cells that are within range of our position
                        float2 offset = float2(x, y);
                        float2 cellOffset = cellFrac - 0.5 + offset;
                        float distFromCell = length(cellOffset);
                        
                        // Only process if we're within the maximum petal radius of this cell
                        if (distFromCell < gridSpacePetalRadius * 2.0) {
                            // Process this second-layer cell
                            PROCESS_ADJACENT_PETAL(x, y);
                        }
                    }
                }
            }
            
            // Third layer of neighbors - only check if BoundaryCheckLayers >= 3
            if (BoundaryCheckLayers >= 3) {
                // Expand our check to third layer
                // Extended offset range for the third layer: -3, -2, -1, 0, 1, 2, 3
                for (int y = -3; y <= 3; y++) {
                    for (int x = -3; x <= 3; x++) {
                        // Skip the cells we've already processed (first and second layers and center)
                        if (abs(x) <= 2 && abs(y) <= 2)
                            continue;
                            
                        // For the third layer, we only need to process cells that are within range of our position
                        float2 offset = float2(x, y);
                        float2 cellOffset = cellFrac - 0.5 + offset;
                        float distFromCell = length(cellOffset);
                        
                        // Only process if we're within the maximum petal radius of this cell
                        if (distFromCell < gridSpacePetalRadius * 3.0) {
                            // Process this third-layer cell
                            PROCESS_ADJACENT_PETAL(x, y);
                        }
                    }
                }
            }
            
            // Clean up macro definition to avoid pollution
            #undef PROCESS_ADJACENT_PETAL
        }
        // ==========================================================================================

        // Now blend this layer's combined petals with our accumulated result
        if (PetalShadingMode == 1) // Opaque (Solid) Mode
        {            // Only blend visible pixels where there isn't already a petal
            // This creates the effect where petals in front occlude petals behind them
            float occupancyMask = step(ALPHA_THRESHOLD, petalLayerColor.a) * (1.0 - step(ALPHA_THRESHOLD, accumulatedColor.a));
            
            // Blend only where the mask allows
            accumulatedColor.rgb = lerp(accumulatedColor.rgb, petalLayerColor.rgb, petalLayerColor.a * occupancyMask);
            accumulatedColor.a = max(accumulatedColor.a, petalLayerColor.a * occupancyMask);
        }
        else // Transparent Blend Mode
        {
            // Standard transparent blending
            accumulatedColor.rgb = lerp(accumulatedColor.rgb, petalLayerColor.rgb, petalLayerColor.a);
            accumulatedColor.a = accumulatedColor.a + petalLayerColor.a * (1.0 - accumulatedColor.a);        }

        currentLayerAlphaFactor *= LayerAlphaMod;
        currentLayerSizeFactor *= LayerSizeMod; 
        layerGlobalOffset += AS_hash22(float2(currentLayerAlphaFactor, currentLayerSizeFactor)) * 0.3; 
    }
    
    accumulatedColor.a = clamp(accumulatedColor.a, 0.0, 1.0);
    
    return accumulatedColor;
}

// --- Main Pixel Shader ---
float4 PS_Main(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, uv);
    float currentTime = AS_getTime();    float2 centeredAspectUV = uv - 0.5;
    centeredAspectUV.x *= ReShade::ScreenSize.x / ReShade::ScreenSize.y;
    centeredAspectUV *= GlobalVoronoiDensity;

    // Stage depth check for all rendering paths
    float depthSample = ReShade::GetLinearizedDepth(uv);
    
    switch(DebugMode) {case 1: // Density Visualization
            float2 testRootUV_density = floor(centeredAspectUV); 
            float2 density_tex_uv_debug = frac(testRootUV_density / DensityCellRepeatScale); 
            float instanceDensityNoise_debug = tex2D(PetalFlutter_samplerNoiseSource, density_tex_uv_debug * NoiseTexScale + currentTime * 0.005).r;
            float instanceDensityFactor_debug = smoothstep(
                DensityThreshold - DensityFadeRange * 0.5,
                DensityThreshold + DensityFadeRange * 0.5,
                instanceDensityNoise_debug);
            return float4(instanceDensityFactor_debug.rrr, 1.0);
        case 2: // Cell Structure
            float2 rootVis = floor(centeredAspectUV); 
            float h1 = AS_hash21(rootVis);            float h2 = AS_hash21(rootVis + float2(17.3, 3.7));
            return float4(h1, h2, AS_hash21(rootVis + h1), 1.0);
        case 3: // Single Petal Alpha
            // Pass 0.0f for currentWindStrength argument
            float4 singlePetal = DrawPetalInstance(centeredAspectUV, uv, 0.0, currentTime, 1.0, UserDirection * BaseDriftSpeed); 
            return float4(singlePetal.aaa, 1.0);
        case 4: // Flutter Effect
        {
             float flutterDebugSizeFactor = 1.0; 
             float2 pNoiseOffset = (AS_VectorNoise2D(centeredAspectUV * flutterDebugSizeFactor * 2.0 + currentTime * 0.2) - 0.5) * BaseFlutterStrength * flutterDebugSizeFactor; 
             return float4(pNoiseOffset.x + 0.5, pNoiseOffset.y + 0.5, 0.0, 1.0);
        }
        case 5: // Petal Texture Test
            // Pass 0.0f for currentWindStrength argument
            float4 texPetal = DrawPetalInstance(centeredAspectUV, uv, 0.0, currentTime, 1.0, UserDirection * BaseDriftSpeed); 
            return float4(texPetal.rgb * texPetal.a, texPetal.a);        case 0: // Normal Effect
        default:        // RenderPetalLayers now handles PetalShadingMode internally
            // for layer blending, but we still handle final blending with the scene here
            float4 layeredPetalColor = RenderPetalLayers(centeredAspectUV, uv, currentTime); 
            
            // Stage depth check - don't apply effect on pixels with depth less than our stage depth
            if (depthSample < ClairObscur_StageDepth)
                return originalColor;
                
            if (PetalShadingMode == 1) // Opaque (Solid) Mode
            {
                float petalPresence = (layeredPetalColor.a > ALPHA_THRESHOLD) ? 1.0 : 0.0; 
                float3 finalPetalRgb = layeredPetalColor.rgb * layeredPetalColor.a; 
                originalColor.rgb = lerp(originalColor.rgb, finalPetalRgb, petalPresence); 
            }
            else // Transparent Blend Mode
            {
                originalColor.rgb = lerp(originalColor.rgb, layeredPetalColor.rgb, layeredPetalColor.a);
            }
            return originalColor;
    }
}

// --- Technique Definition ---
technique FlutteringPetals < 
    ui_label="[AS] GFX: Clair Obscur"; 
    ui_tooltip = "Creates a beautiful cascade of floating petals with realistic movement, natural rotation variation, and elegant entrance/exit effects";
> {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_Main;
    }
}

#endif // __AS_GFX_ClairObscur_1_fx