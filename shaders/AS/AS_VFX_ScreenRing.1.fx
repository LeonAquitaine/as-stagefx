/**
 * AS_VFX_WaterSurface.1.fx - Screen-space water surface with adjustable horizon and perspective reflection
 * Author: Leon Aquitaine (Refined based on user request, Gemini assistance)
 * Date: 2025-05-05
 * License: Creative Commons Attribution 4.0 International
 * Version: 1.7.5 (Clamped reflection sample UV to prevent sampling below horizon)
 *
 * DESCRIPTION:
 * Simulates a water surface below a defined horizon line. Reflections are mirrored
 * across the horizon. The vertical stretch/position of the reflection is adjusted
 * based on the depth of the reflected object, influenced by 'DepthInfluence' and
 * scaled by the 'WaterLevel' parameter. Ensures reflections only sample above horizon.
 *
 * FEATURES:
 * - Configurable Horizon line position.
 * - Configurable Water Level parameter influencing reflection perspective strength.
 * - Perspective-approximated reflections based on reflected object depth.
 * - Texture-based wave animation and reflection distortion.
 * - Configurable water color and reflection intensity.
 */

#ifndef __AS_VFX_WaterSurface_1_fx
#define __AS_VFX_WaterSurface_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// TEXTURES AND SAMPLERS
// ============================================================================
#ifndef WAVE_TEXTURE
#define WAVE_TEXTURE "perlin512x8Noise.png"
#endif

texture WaveTexture < source = WAVE_TEXTURE; > { Width = 512; Height = 512; Format = RGBA8; };
sampler WaveSampler { Texture = WaveTexture; AddressU = WRAP; AddressV = WRAP; MipFilter = LINEAR; MinFilter = LINEAR; MagFilter = LINEAR; };

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
static const float HORIZON_Y_MIN = 0.0; // Screen Y position
static const float HORIZON_Y_MAX = 1.0;
static const float HORIZON_Y_DEFAULT = 0.5; // Mid-screen horizon

static const float WATER_LEVEL_MIN = 0.0; // 0 = Simple Mirror, 1 = Full Perspective Effect
static const float WATER_LEVEL_MAX = 1.0;
static const float WATER_LEVEL_DEFAULT = 1.0; // Default: Full perspective effect

static const float EDGE_TRANSITION_MIN = 0.0001; // Width of smooth edge transition
static const float EDGE_TRANSITION_MAX = 0.05;
static const float EDGE_TRANSITION_DEFAULT = 0.001;

static const float WAVE_SPEED_MIN = 0.01;
static const float WAVE_SPEED_MAX = 1.0;
static const float WAVE_SPEED_DEFAULT = 0.1;

static const float WAVE_SCALE_MIN = 1.0;
static const float WAVE_SCALE_MAX = 50.0;
static const float WAVE_SCALE_DEFAULT = 10.0;

static const float DISTORTION_MIN = 0.0;
static const float DISTORTION_MAX = 0.1;
static const float DISTORTION_DEFAULT = 0.02;

static const float DEPTH_INFLUENCE_MIN = 0.0;
static const float DEPTH_INFLUENCE_MAX = 2.0; // Allow > 1 for stronger effect
static const float DEPTH_INFLUENCE_DEFAULT = 1.0; // Default to linear influence

// Removed DepthFalloff constant
// static const float DEPTH_FALLOFF_MIN = 0.1;
// static const float DEPTH_FALLOFF_MAX = 10.0;
// static const float DEPTH_FALLOFF_DEFAULT = 1.0;

// ============================================================================
// EFFECT-SPECIFIC PARAMETERS
// ============================================================================
// --- Water Properties ---
uniform float3 WaterColor < ui_type = "color"; ui_label = "Water Color"; ui_tooltip = "Base color blended with reflections."; ui_category = "Water Properties"; > = float3(0.1, 0.35, 0.5);
uniform float ReflectionIntensity < ui_type = "slider"; ui_label = "Reflection Intensity"; ui_tooltip = "Strength of the reflection effect."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Water Properties"; > = 0.8;

// --- Water Position & Perspective ---
uniform float HorizonY < ui_type = "slider"; ui_label = "Horizon Line Position"; ui_tooltip = "Visual water line Y position (0=Top, 1=Bottom)."; ui_min = HORIZON_Y_MIN; ui_max = HORIZON_Y_MAX; ui_step = 0.001; ui_category = "Water Position"; > = HORIZON_Y_DEFAULT;
uniform float WaterLevel < ui_type = "slider"; ui_label = "Perspective Amount"; ui_tooltip = "Controls how much perspective affects reflections (0=Simple Mirror, 1=Full Effect)."; ui_min = WATER_LEVEL_MIN; ui_max = WATER_LEVEL_MAX; ui_step = 0.01; ui_category = "Water Position"; > = WATER_LEVEL_DEFAULT; // Renamed tooltip
uniform float EdgeTransition < ui_type = "slider"; ui_label = "Edge Transition Width"; ui_tooltip = "Width of the smooth transition at the Horizon line."; ui_min = EDGE_TRANSITION_MIN; ui_max = EDGE_TRANSITION_MAX; ui_step = 0.0001; ui_category = "Water Position"; > = EDGE_TRANSITION_DEFAULT;

// --- Depth Settings ---
uniform float DepthInfluence < ui_type = "slider"; ui_label = "Depth Influence"; ui_tooltip = "Strength of depth effect on perspective (Higher = more stretch for close objects)."; ui_min = DEPTH_INFLUENCE_MIN; ui_max = DEPTH_INFLUENCE_MAX; ui_step = 0.01; ui_category = "Depth Settings"; > = DEPTH_INFLUENCE_DEFAULT;
// Removed DepthFalloff parameter
uniform bool FlipDepthMode < ui_type = "checkbox"; ui_label = "Flip Depth Influence"; ui_tooltip = "Invert the depth influence behavior (close objects reflect near horizon)."; ui_category = "Depth Settings"; > = false;

// --- Wave Settings ---
uniform float2 WaveDirection < ui_type = "slider"; ui_label = "Wave Direction"; ui_tooltip = "Direction of wave movement."; ui_min = -1.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Wave Settings"; > = float2(1.0, 0.0);
uniform float WaveSpeed < ui_type = "slider"; ui_label = "Wave Speed"; ui_tooltip = "Speed of wave animation."; ui_min = WAVE_SPEED_MIN; ui_max = WAVE_SPEED_MAX; ui_step = 0.01; ui_category = "Wave Settings"; > = WAVE_SPEED_DEFAULT;
uniform float WaveScale < ui_type = "slider"; ui_label = "Wave Scale"; ui_tooltip = "Scale of wave pattern."; ui_min = WAVE_SCALE_MIN; ui_max = WAVE_SCALE_MAX; ui_step = 0.1; ui_category = "Wave Settings"; > = WAVE_SCALE_DEFAULT;
uniform float WaveDistortion < ui_type = "slider"; ui_label = "Wave Distortion"; ui_tooltip = "Amount of distortion applied to reflection."; ui_min = DISTORTION_MIN; ui_max = DISTORTION_MAX; ui_step = 0.001; ui_category = "Wave Settings"; > = DISTORTION_DEFAULT;

// --- Final Mix ---
AS_BLENDMODE_UI(BlendMode, "Final Mix")
AS_BLENDAMOUNT_UI(BlendAmount, "Final Mix")

// --- Debug ---
AS_DEBUG_MODE_UI("Normal\0Wave Distortion\0Reflected Obj Depth\0Depth Offset Factor\0Final Reflection UVs\0Water Mask\0Perspective Shift\0Clamped Reflection UVs\0") // Added Debug Mode

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================
// Calculate distortion based on wave texture
float2 GetWaveDistortion(float2 texcoord, float time)
{
    float2 waveUV = texcoord * WaveScale + (normalize(WaveDirection + float2(0.001, 0.001)) * time * WaveSpeed);
    float2 waveValue = tex2D(WaveSampler, waveUV).rg;
    waveValue = waveValue * 2.0 - 1.0;
    return waveValue * WaveDistortion;
}

// Calculate depth-based vertical offset scaling factor (0 to DepthInfluence range) - Simplified
float GetDepthBasedOffsetFactor(float reflectedObjectDepth)
{
    // Use linear depth directly (0=near, 1=far)
    float normalizedDepth = saturate(reflectedObjectDepth);
    // Calculate offset factor: If not flipped, close objects (depth=0 -> factor=1), far objects (depth=1 -> factor=0)
    // This factor represents the *potential strength* of the perspective shift.
    float offsetFactor = FlipDepthMode ? normalizedDepth : (1.0 - normalizedDepth);
    // Scale by influence parameter
    return offsetFactor * DepthInfluence; // Range [0, DepthInfluence]
}

// ============================================================================
// MAIN PIXEL SHADER
// ============================================================================
float4 PS_WaterSurface(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // --- Initial Setup ---
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float time = AS_getTime();
    float horizonYFinal = saturate(HorizonY);
    float waterLevelFinal = saturate(WaterLevel); // How much perspective effect to apply (0 to 1)

    // --- Water Surface Mask ---
    // Effect applies below the horizon line
    float waterMask = smoothstep(horizonYFinal - EdgeTransition, horizonYFinal + EdgeTransition, texcoord.y);

    // If pixel is fully above the water line, return original color
    if (waterMask < 0.01 && DebugMode == 0) {
        return originalColor;
    }

    // --- Calculate Reflection Coordinates ---
    // 1. Calculate distance below horizon for the current pixel
    float distBelowHorizon = texcoord.y - horizonYFinal;

    // 2. Calculate the basic mirrored Y position above the horizon
    float baseReflectionY = horizonYFinal - distBelowHorizon;
    float2 baseReflectionCoord = float2(texcoord.x, baseReflectionY);

    // 3. Sample the depth of the object at the base mirror position (saturate UVs for safety here)
    float reflectedObjectDepth = ReShade::GetLinearizedDepth(saturate(baseReflectionCoord));

    // 4. Calculate the perspective offset factor based on reflected depth
    // This determines the *maximum potential* perspective shift (range 0 to DepthInfluence)
    float depthOffsetFactor = GetDepthBasedOffsetFactor(reflectedObjectDepth);

    // 5. Calculate the actual perspective shift amount to apply based on WaterLevel
    // This scales how much the reflection is stretched vertically based on depth.
    // perspectiveShift = 0 when WaterLevel=0 (no effect), perspectiveShift = depthOffsetFactor when WaterLevel=1
    float perspectiveShift = depthOffsetFactor * waterLevelFinal;

    // 6. Calculate the final reflection Y coordinate
    // Start at the horizon and move upwards by the base distance scaled by (1 + perspective shift)
    // Multiplying by (1 + perspectiveShift) stretches the reflection downwards for closer objects (when perspectiveShift > 0)
    float finalDistAboveHorizon = distBelowHorizon * (1.0 + perspectiveShift);
    float adjustedReflectionY = horizonYFinal - finalDistAboveHorizon; // Corrected calculation

    float2 reflectionCoord = float2(texcoord.x, adjustedReflectionY);


    // --- Apply Wave Distortion ---
    float2 distortion = GetWaveDistortion(texcoord, time);
    float2 distortedReflectionCoord = reflectionCoord + distortion;

    // --- Sample Reflection & Combine ---
    // Clamp the Y coordinate to prevent sampling below the horizon line
    // Add a tiny epsilon to avoid sampling exactly ON the line if precision issues occur
    distortedReflectionCoord.y = min(distortedReflectionCoord.y, horizonYFinal - 0.0001);
    // Use saturate on the X coordinate and the now-clamped Y coordinate
    float2 finalSampleCoord = saturate(distortedReflectionCoord);

    float3 reflectionColor = tex2D(ReShade::BackBuffer, finalSampleCoord).rgb;

    // Blend reflection with water color based on intensity
    float3 waterWithReflection = lerp(WaterColor.rgb, reflectionColor, ReflectionIntensity); // Use WaterColor as base

    // --- Final Blend ---
    // Blend the water effect onto the original pixel based on the water line transition (edgeFade)
    float3 blendedColor = AS_blendResult(originalColor.rgb, waterWithReflection, BlendMode);
    float3 result = lerp(originalColor.rgb, blendedColor, waterMask * BlendAmount);

    // --- Debug Modes ---
    if (DebugMode > 0) {
        if (DebugMode == 1) return float4(distortion * 0.5 + 0.5, 0.0, 1.0); // Wave Distortion
        if (DebugMode == 2) return float4(reflectedObjectDepth.xxx, 1.0); // Reflected Object Depth
        if (DebugMode == 3) return float4(saturate(depthOffsetFactor / max(DepthInfluence, 0.01)).xxx, 1.0); // Depth Offset Factor (normalized)
        if (DebugMode == 4) return float4(saturate(reflectionCoord), 0.0, 1.0); // Reflection UVs (Before Distortion, Before Clamp)
        if (DebugMode == 5) return float4(waterMask.xxx, 1.0); // Water Mask
        if (DebugMode == 6) return float4(saturate(perspectiveShift).xxx, 1.0); // Perspective Shift amount applied
        if (DebugMode == 7) return float4(finalSampleCoord, 0.0, 1.0); // Final Clamped Reflection UVs (R=U, G=V)
        return float4(1.0, 0.0, 1.0, 1.0); // Magenta error
    }

    // --- Final Output ---
    return float4(result, originalColor.a);
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_VFX_WaterSurface < ui_label = "[AS] VFX: Water Surface (Horizon/Level)"; ui_tooltip = "Water surface with separate horizon line and water level controls for reflection."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_WaterSurface;
    }
}

#endif // __AS_VFX_WaterSurface_1_fx
