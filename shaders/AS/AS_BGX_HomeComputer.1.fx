/**
 * AS_BGX_HomeComputer.1.fx - Particle-based retro computer visualization effect
 * Author: Leon Aquitaine (based on original by Nimitz)
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a nostalgic homecomputer-style visualization with dynamic particles that
 * move in hypnotic patterns. Features scanlines, subtle vignetting, and audio reactivity
 * for a retro-digital aesthetic suitable for backgrounds and overlays.
 *
 * FEATURES:
 * - Particle-based visualization with configurable density and dynamics
 * - Audio reactivity that affects particle movement and appearance
 * - Customizable color schemes with palette or math-based generation
 * - Scanlines effect with adjustable intensity
 * - Vignette effect for classic CRT appearance
 * - Color inversion cycles for visual variety
 * - Depth-aware rendering for proper scene integration
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Simulates particle physics using a buffer-like approach for positions and velocities
 * 2. Renders particles with sub-step interpolation for smooth movement
 * 3. Applies mathematical patterns to create hypnotic movement paths
 * 4. Integrates audio reactivity to influence particle dynamics
 * 5. Adds post-processing effects (scanlines, vignette) for aesthetic enhancement
 * 
 * Original by Nimitz (2016): https://www.shadertoy.com/view/XtffDS
 * Adapted for ReShade by Leon Aquitaine
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_HomeComputer_1_fx
#define __AS_BGX_HomeComputer_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palettes.1.fxh"

namespace ASHomeComputer {
// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================

// --- Particles ---
static const int NUM_PARTICLES_MIN = 10;
static const int NUM_PARTICLES_MAX = 300;
static const int NUM_PARTICLES_DEFAULT = 100;

static const int STEPS_PER_FRAME_MIN = 1;
static const int STEPS_PER_FRAME_MAX = 20;
static const int STEPS_PER_FRAME_DEFAULT = 9;

static const float PARTICLE_SPEED_MIN = 0.0005;
static const float PARTICLE_SPEED_MAX = 0.01;
static const float PARTICLE_SPEED_STEP = 0.0001;
static const float PARTICLE_SPEED_DEFAULT = 0.002;

static const float PARTICLE_SIZE_MIN = 0.5;
static const float PARTICLE_SIZE_MAX = 5.0;
static const float PARTICLE_SIZE_STEP = 0.1;
static const float PARTICLE_SIZE_DEFAULT = 1.0;

static const float PARTICLE_INTENSITY_MIN = 0.1;
static const float PARTICLE_INTENSITY_MAX = 5.0;
static const float PARTICLE_INTENSITY_STEP = 0.1;
static const float PARTICLE_INTENSITY_DEFAULT = 1.0;

// --- Pattern ---
static const float EPICYCLE_OUTER_RADIUS_MIN = 0.5;
static const float EPICYCLE_OUTER_RADIUS_MAX = 5.0;
static const float EPICYCLE_OUTER_RADIUS_STEP = 0.1;
static const float EPICYCLE_OUTER_RADIUS_DEFAULT = 1.5;

static const float EPICYCLE_INNER_RADIUS_MIN = 0.1;
static const float EPICYCLE_INNER_RADIUS_MAX = 2.0;
static const float EPICYCLE_INNER_RADIUS_STEP = 0.1;
static const float EPICYCLE_INNER_RADIUS_DEFAULT = 0.5;

static const float EPICYCLE_DISTANCE_MIN = 1.0;
static const float EPICYCLE_DISTANCE_MAX = 10.0;
static const float EPICYCLE_DISTANCE_STEP = 0.5;
static const float EPICYCLE_DISTANCE_DEFAULT = 5.0;

static const float PATTERN_FREQUENCY_MIN = 0.0;
static const float PATTERN_FREQUENCY_MAX = 5.0;
static const float PATTERN_FREQUENCY_STEP = 0.1;
static const float PATTERN_FREQUENCY_DEFAULT = 1.0;

static const float RANDOM_FACTOR_MIN = 0.0;
static const float RANDOM_FACTOR_MAX = 10.0;
static const float RANDOM_FACTOR_STEP = 0.5;
static const float RANDOM_FACTOR_DEFAULT = 7.0;

// --- Post Effects ---
static const float SCANLINE_INTENSITY_MIN = 0.0;
static const float SCANLINE_INTENSITY_MAX = 0.5;
static const float SCANLINE_INTENSITY_STEP = 0.01;
static const float SCANLINE_INTENSITY_DEFAULT = 0.04;

static const float SCANLINE_FREQUENCY_MIN = 50.0;
static const float SCANLINE_FREQUENCY_MAX = 1000.0;
static const float SCANLINE_FREQUENCY_STEP = 50.0;
static const float SCANLINE_FREQUENCY_DEFAULT = 350.0;

static const float VIGNETTE_INTENSITY_MIN = 0.0;
static const float VIGNETTE_INTENSITY_MAX = 1.0;
static const float VIGNETTE_INTENSITY_STEP = 0.05;
static const float VIGNETTE_INTENSITY_DEFAULT = 0.35;

static const float VIGNETTE_POWER_MIN = 0.05;
static const float VIGNETTE_POWER_MAX = 1.0;
static const float VIGNETTE_POWER_STEP = 0.05;
static const float VIGNETTE_POWER_DEFAULT = 0.1;

static const float COLOR_INVERSION_CYCLE_MIN = 0.0;
static const float COLOR_INVERSION_CYCLE_MAX = 100.0;
static const float COLOR_INVERSION_CYCLE_STEP = 1.0;
static const float COLOR_INVERSION_CYCLE_DEFAULT = 28.0;

// --- Audio Reactivity Constants ---
static const float AUDIO_MULTIPLIER_DEFAULT = 1.0;
static const float AUDIO_MULTIPLIER_MAX = 5.0;

// --- Animation Constants ---
static const float ANIMATION_SPEED_MIN = 0.0;
static const float ANIMATION_SPEED_MAX = 5.0;
static const float ANIMATION_SPEED_STEP = 0.1;
static const float ANIMATION_SPEED_DEFAULT = 1.0;

// --- UI Elements ---

// --- Stage ---
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation)
AS_POSITION_SCALE_UI(Position, Scale)

// --- Particles ---
uniform int NumParticles < ui_type = "slider"; ui_label = "Number of Particles"; ui_tooltip = "Controls the number of particles in the effect. Higher values increase density but may impact performance."; ui_min = NUM_PARTICLES_MIN; ui_max = NUM_PARTICLES_MAX; ui_category = "Particles"; > = NUM_PARTICLES_DEFAULT;

uniform int StepsPerFrame < ui_type = "slider"; ui_label = "Steps Per Frame"; ui_tooltip = "Number of sub-steps per frame for each particle. Higher values create smoother trails but impact performance."; ui_min = STEPS_PER_FRAME_MIN; ui_max = STEPS_PER_FRAME_MAX; ui_category = "Particles"; > = STEPS_PER_FRAME_DEFAULT;

uniform float ParticleSpeed < ui_type = "slider"; ui_label = "Particle Speed"; ui_tooltip = "Controls how fast particles move through space."; ui_min = PARTICLE_SPEED_MIN; ui_max = PARTICLE_SPEED_MAX; ui_step = PARTICLE_SPEED_STEP; ui_category = "Particles"; > = PARTICLE_SPEED_DEFAULT;

uniform float ParticleSize < ui_type = "slider"; ui_label = "Particle Size"; ui_tooltip = "Controls the size of individual particles."; ui_min = PARTICLE_SIZE_MIN; ui_max = PARTICLE_SIZE_MAX; ui_step = PARTICLE_SIZE_STEP; ui_category = "Particles"; > = PARTICLE_SIZE_DEFAULT;

uniform float ParticleIntensity < ui_type = "slider"; ui_label = "Particle Intensity"; ui_tooltip = "Controls the brightness/intensity of particles."; ui_min = PARTICLE_INTENSITY_MIN; ui_max = PARTICLE_INTENSITY_MAX; ui_step = PARTICLE_INTENSITY_STEP; ui_category = "Particles"; > = PARTICLE_INTENSITY_DEFAULT;

// --- Pattern ---
uniform float EpicycleOuterRadius < ui_type = "slider"; ui_label = "Outer Radius"; ui_tooltip = "Controls the outer radius of the epicyclic pattern."; ui_min = EPICYCLE_OUTER_RADIUS_MIN; ui_max = EPICYCLE_OUTER_RADIUS_MAX; ui_step = EPICYCLE_OUTER_RADIUS_STEP; ui_category = "Pattern"; > = EPICYCLE_OUTER_RADIUS_DEFAULT;

uniform float EpicycleInnerRadius < ui_type = "slider"; ui_label = "Inner Radius"; ui_tooltip = "Controls the inner radius of the epicyclic pattern."; ui_min = EPICYCLE_INNER_RADIUS_MIN; ui_max = EPICYCLE_INNER_RADIUS_MAX; ui_step = EPICYCLE_INNER_RADIUS_STEP; ui_category = "Pattern"; > = EPICYCLE_INNER_RADIUS_DEFAULT;

uniform float EpicycleDistance < ui_type = "slider"; ui_label = "Pattern Distance"; ui_tooltip = "Controls the distance parameter in the epicyclic pattern equation."; ui_min = EPICYCLE_DISTANCE_MIN; ui_max = EPICYCLE_DISTANCE_MAX; ui_step = EPICYCLE_DISTANCE_STEP; ui_category = "Pattern"; > = EPICYCLE_DISTANCE_DEFAULT;

uniform float PatternFrequency < ui_type = "slider"; ui_label = "Pattern Frequency"; ui_tooltip = "Controls the base frequency of the epicyclic pattern."; ui_min = PATTERN_FREQUENCY_MIN; ui_max = PATTERN_FREQUENCY_MAX; ui_step = PATTERN_FREQUENCY_STEP; ui_category = "Pattern"; > = PATTERN_FREQUENCY_DEFAULT;

uniform float RandomFactor < ui_type = "slider"; ui_label = "Randomness"; ui_tooltip = "Controls the amount of randomness added to the particle movement."; ui_min = RANDOM_FACTOR_MIN; ui_max = RANDOM_FACTOR_MAX; ui_step = RANDOM_FACTOR_STEP; ui_category = "Pattern"; > = RANDOM_FACTOR_DEFAULT;

// --- Post Effects ---
uniform float ScanlineIntensity < ui_type = "slider"; ui_label = "Scanline Intensity"; ui_tooltip = "Controls the intensity of the scanline effect."; ui_min = SCANLINE_INTENSITY_MIN; ui_max = SCANLINE_INTENSITY_MAX; ui_step = SCANLINE_INTENSITY_STEP; ui_category = "Post Effects"; > = SCANLINE_INTENSITY_DEFAULT;

uniform float ScanlineFrequency < ui_type = "slider"; ui_label = "Scanline Frequency"; ui_tooltip = "Controls the frequency/density of scanlines."; ui_min = SCANLINE_FREQUENCY_MIN; ui_max = SCANLINE_FREQUENCY_MAX; ui_step = SCANLINE_FREQUENCY_STEP; ui_category = "Post Effects"; > = SCANLINE_FREQUENCY_DEFAULT;

uniform float VignetteIntensity < ui_type = "slider"; ui_label = "Vignette Intensity"; ui_tooltip = "Controls the intensity of the vignette (darkening at corners) effect."; ui_min = VIGNETTE_INTENSITY_MIN; ui_max = VIGNETTE_INTENSITY_MAX; ui_step = VIGNETTE_INTENSITY_STEP; ui_category = "Post Effects"; > = VIGNETTE_INTENSITY_DEFAULT;

uniform float VignettePower < ui_type = "slider"; ui_label = "Vignette Power"; ui_tooltip = "Controls the power/curve of the vignette effect."; ui_min = VIGNETTE_POWER_MIN; ui_max = VIGNETTE_POWER_MAX; ui_step = VIGNETTE_POWER_STEP; ui_category = "Post Effects"; > = VIGNETTE_POWER_DEFAULT;

uniform float ColorInversionCycle < ui_type = "slider"; ui_label = "Color Inversion Cycle"; ui_tooltip = "Controls the cycle time for color inversion. 0 = disabled."; ui_min = COLOR_INVERSION_CYCLE_MIN; ui_max = COLOR_INVERSION_CYCLE_MAX; ui_step = COLOR_INVERSION_CYCLE_STEP; ui_category = "Post Effects"; > = COLOR_INVERSION_CYCLE_DEFAULT;

// --- Palette & Style ---
uniform bool UseOriginalColors < ui_label = "Use Original Colors"; ui_tooltip = "When enabled, uses mathematically generated colors instead of palette colors."; ui_category = "Palette & Style"; > = true;

uniform float OriginalColorIntensity < ui_type = "slider"; ui_label = "Original Color Intensity"; ui_tooltip = "Adjusts the intensity of colors when 'Use Original Colors' is enabled."; ui_min = 0.1; ui_max = 3.0; ui_step = 0.1; ui_category = "Palette & Style"; ui_spacing = 0; > = 1.0;

AS_PALETTE_SELECTION_UI(PalettePreset, "Color Palette", AS_PALETTE_NEON, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(HomeComputer_, "Palette & Style")
uniform float ColorCycleSpeed < ui_type = "slider"; ui_label = "Color Cycle Speed"; ui_tooltip = "Controls how fast palette colors cycle. 0 = static."; ui_min = -2.0; ui_max = 2.0; ui_step = 0.1; ui_category = "Palette & Style"; > = 0.1;

// --- Animation ---
uniform float AnimationSpeed < ui_type = "slider"; ui_label = "Animation Speed"; ui_tooltip = "Controls the overall animation speed. 0 = paused."; ui_min = ANIMATION_SPEED_MIN; ui_max = ANIMATION_SPEED_MAX; ui_step = ANIMATION_SPEED_STEP; ui_category = "Animation"; > = ANIMATION_SPEED_DEFAULT;

uniform float AnimationKeyframe < ui_type = "slider"; ui_label = "Animation Keyframe"; ui_tooltip = "Sets a specific keyframe for the animation when Animation Speed is 0."; ui_min = 0.0; ui_max = 100.0; ui_step = 0.1; ui_category = "Animation"; > = 0.0;

// --- Audio Reactivity ---
AS_AUDIO_SOURCE_UI(HomeComputer_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(HomeComputer_AudioMultiplier, "Audio Intensity", AUDIO_MULTIPLIER_DEFAULT, AUDIO_MULTIPLIER_MAX, "Audio Reactivity")
uniform int HomeComputer_AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter"; ui_items = "None\0Particle Speed\0Particle Size\0Pattern Frequency\0Randomness\0"; ui_category = "Audio Reactivity"; > = 1;

// --- Final Mix ---
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

// --- Debug ---
AS_DEBUG_MODE_UI("Off\0Show Audio Reactivity\0")

// --- Internal Constants ---
static const float EPSILON = 1e-6;
static const float HALF_POINT = 0.5f;
static const int MAX_PARTICLES = 300; // Absolute max regardless of UI setting

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Hash function to generate pseudo-random values from a 3D vector
float3 hash3(float3 p)
{
    p = frac(p * float3(443.8975, 397.2973, 491.1871));
    p += dot(p.zxy, p.yxz + 19.1);
    return frac(float3(p.x * p.y, p.z * p.x, p.y * p.z)) - 0.5;
}

// Get color from the currently selected palette
float3 getHomeComputerColor(float t, float time) {
    if (ColorCycleSpeed != 0.0) {
        float cycleRate = ColorCycleSpeed * 0.1;
        t = frac(t + cycleRate * time);
    }
    t = saturate(t);
    
    if (PalettePreset == AS_PALETTE_COUNT) { // Use custom palette
        return AS_GET_INTERPOLATED_CUSTOM_COLOR(HomeComputer_, t);
    }
    return AS_getInterpolatedColor(PalettePreset, t); // Use preset palette
}

// Creates a 2D rotation matrix
float2x2 rot2D(float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float2x2(c, s, -s, c);
}

// Particle position calculation
float3 calcParticlePos(float id, float iTime, float3 baseVel, float audioReactivity)
{
    // Epicyclic motion parameters with audio reactivity
    float R = EpicycleOuterRadius;
    float r = EpicycleInnerRadius;
    float d = EpicycleDistance;
    
    // Apply audio reactivity to pattern frequency if selected
    float patternFreq = PatternFrequency;
    float randomFactor = RandomFactor;
    
    if (HomeComputer_AudioTarget == 3) {
        patternFreq *= audioReactivity;
    }
    else if (HomeComputer_AudioTarget == 4) {
        randomFactor *= audioReactivity;
    }
    
    // Time value used for animation
    float t = iTime * 2.0 + id * 8.0;
    
    // Epicyclic motion calculation
    float x = ((R - r) * cos(t - iTime * 0.1) + d * cos((R - r) / r * t));
    float y = ((R - r) * sin(t) - d * sin((R - r) / r * t));
    
    // Add Z component with audio-reactive oscillation
    float z = sin(iTime * 12.6 + id * 50.0) * 7.0;
    
    // Create base velocity
    float3 epicyclicVel = float3(x * 1.2, y, z) * 5.0;
    
    // Add randomness
    float3 randComponent = hash3(baseVel * 10.0 + iTime * 0.2) * randomFactor;
    
    // Mix base velocity with new velocity and add randomness
    float3 newVel = epicyclicVel + randComponent;
    float3 vel = lerp(baseVel, newVel, 0.1); // Smooth transition for velocity
    
    // Calculate position based on velocity
    float3 pos = baseVel * 1.0; // Use velocity as a base for position
    
    return pos;
}

// Calculate particle positions and render them
float4 renderParticles(float3 ro, float3 rd, float2 texcoord, float iTime, float audioReactivity)
{
    float4 result = float4(0, 0, 0, 0);
    
    // Apply audio reactivity to particle parameters
    float particleSpeed = ParticleSpeed;
    float particleSize = ParticleSize;
    
    if (HomeComputer_AudioTarget == 1) {
        particleSpeed *= audioReactivity;
    }
    else if (HomeComputer_AudioTarget == 2) {
        particleSize *= audioReactivity;
    }
    
    // Render particles
    float aspectRatio = ReShade::AspectRatio;
    
    for (int i = 0; i < NumParticles; i++)
    {
        // Use hash to generate consistent initial positions and velocities
        float id = float(i) / float(NumParticles);
        float3 seed = float3(id, id * 2.13, id * 4.89);
        
        float3 vel = hash3(seed) * 2.0; // Base velocity
        float3 pos = calcParticlePos(id, iTime, vel, audioReactivity);
        
        float sinTime = sin(iTime * 0.6);
        
        for (int j = 0; j < StepsPerFrame; j++)
        {
            // Calculate distance from ray origin to particle
            float3 toParticle = pos - ro;
            float projDist = dot(toParticle, rd);
            float3 closestPoint = ro + rd * projDist;
            float d = dot(closestPoint - pos, closestPoint - pos); // Distance squared
            
            // Apply distance-based intensity falloff
            d *= 1000.0 * (1.0 / particleSize); // Scale by inverse of particle size
            float intensity = 2.0 / (pow(d, 1.0 + sin(iTime * 0.6) * 0.15) + 1.5);
            intensity *= (sinTime + 4.0) * 0.8;
            
            // Calculate particle color
            float colorSeed = id * 0.015 + iTime * 0.3;
            float3 particleColor;
            
            if (UseOriginalColors) {
                // Original mathematical color calculation
                particleColor = (sin(float3(0.7, 2.0, 2.5) + colorSeed + float3(5, 1, 6)) * 0.45 + 0.55) * OriginalColorIntensity;
            } else {
                // Palette-based color
                particleColor = getHomeComputerColor(id + colorSeed, iTime);
            }
            
            // Add this particle's contribution to the final color
            result.rgb += intensity * particleColor * 0.005 * ParticleIntensity;
            
            // Update position for next step
            pos += vel * particleSpeed * 1.5;
        }
    }
    
    return result;
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_HomeComputer(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET {
    // Get original pixel color and depth
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);

    // Apply depth test
    if (depth < EffectDepth) {
        return originalColor;
    }

    // Get time and apply animation controls
    float iTime;
    if (AnimationSpeed <= 0.001) {
        iTime = AnimationKeyframe; // Use keyframe directly when animation is stopped
    } else {
        iTime = AS_getTime() * AnimationSpeed + AnimationKeyframe;
    }
    
    // Process audio reactivity
    float audioReactivity = AS_applyAudioReactivity(1.0, HomeComputer_AudioSource, HomeComputer_AudioMultiplier, true);
    
    // Setup centered, aspect-corrected coordinates for rotation
    float aspectRatio = ReShade::AspectRatio;
    float2 centeredCoord = AS_getCenteredCoord(texcoord, aspectRatio);
    float rotationRadians = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
    float s = sin(rotationRadians);
    float c = cos(rotationRadians);
    float2 rotatedCoord = float2(
        centeredCoord.x * c - centeredCoord.y * s,
        centeredCoord.x * s + centeredCoord.y * c
    );

    // Setup ray for particle rendering
    float3 ro = float3(0.0, 0.0, 2.7); // Ray origin (camera position)
    float3 rd = normalize(float3(rotatedCoord, -0.5)); // Ray direction
    
    // Render particles
    float4 particleColor = renderParticles(ro, rd, texcoord, iTime, audioReactivity) * 10.0;
    
    // Apply color inversion cycle
    if (ColorInversionCycle > 0 && AS_mod(iTime + texcoord.x * 0.15 + texcoord.y * 0.15, ColorInversionCycle) < ColorInversionCycle * 0.5) {
        particleColor = float4(0.9, 0.95, 1.0, 1.0) - particleColor * 0.9;
    }
    
    // Create a background movement effect
    float2 moveVec = float2(pow(audioReactivity - 1.0, 2.0) * 0.05, (audioReactivity - 1.0) * 0.95);
    moveVec = mul(rot2D(iTime), moveVec);
    
    // Blend particle effect with background
    float4 finalColor = particleColor;
    
    // Apply scanlines effect - Using vpos (SV_POSITION) instead of gl_FragCoord
    float scanlineX = sin(vpos.y * ScanlineFrequency + iTime) * ScanlineIntensity + 1.0;
    float scanlineY = sin(vpos.x * ScanlineFrequency + iTime) * ScanlineIntensity + 1.0;
    finalColor.rgb *= scanlineX * scanlineY;
    
    // Apply vignette effect
    float vignetteAmount = pow(16.0 * texcoord.x * texcoord.y * (1.0 - texcoord.x) * (1.0 - texcoord.y), VignettePower) * VignetteIntensity + (1.0 - VignetteIntensity);
    finalColor.rgb *= vignetteAmount;
    
    // Ensure alpha is 1.0
    finalColor.a = 1.0;
    
    // Apply standard blending
    float3 blendedColor = AS_blendResult(originalColor.rgb, finalColor.rgb, BlendMode);
    float4 result = float4(blendedColor, 1.0);
    result = lerp(originalColor, result, BlendStrength);
    
    // Debug visualization
    if (DebugMode == 1) { // Show Audio Reactivity
        float2 debugCenter = float2(0.1f, 0.1f);
        float debugRadius = 0.08f;
        if (length(texcoord - debugCenter) < debugRadius) {
            return float4(audioReactivity, audioReactivity, audioReactivity, 1.0);
        }
    }
    
    return result;
}
} // namespace ASHomeComputer

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_HomeComputer <ui_label="[AS] BGX: HomeComputer"; ui_tooltip="Creates a nostalgic homecomputer-style visualization with dynamic particles that move in hypnotic patterns.";>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = ASHomeComputer::PS_HomeComputer;
    }
}

#endif // __AS_BGX_HomeComputer_1_fx