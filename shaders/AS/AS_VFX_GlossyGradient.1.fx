/**
 * AS_VFX_GlossyGradient.1.fx - Glossy Gradient Visual Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a mesmerizing glossy gradient effect using iterative trigonometric functions.
 * The pattern generates flowing, wave-like colors that continuously evolve and morph,
 * creating hypnotic mathematical beauty through sine and cosine operations.
 *
 * FEATURES:
 * - Mathematical pattern generation using nested trigonometric loops
 * - Smooth color transitions with customizable intensity and saturation
 * - Real-time animation with controllable speed and direction
 * - Multiple iteration controls for pattern complexity
 * - Color channel manipulation for artistic variations
 * - Audio reactivity for dynamic visual responses
 * - Performance optimized with early loop termination options
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Uses an iterative loop to build up trigonometric wave patterns
 * 2. Each iteration modifies accumulator variables using sine and cosine functions
 * 3. UV coordinates are transformed through the mathematical operations
 * 4. Final color is computed using the accumulated values across RGB channels
 * 5. Additional color processing applies cosine-based color grading
 * 6. Animation is driven by time-based parameter evolution
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD
// ============================================================================
#ifndef __AS_VFX_GlossyGradient_1_fx
#define __AS_VFX_GlossyGradient_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Pattern Parameters ---

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform int Iterations < ui_type = "slider"; ui_label = "Pattern Iterations"; ui_min = 3; ui_max = 15; ui_tooltip = "Number of iterations for pattern complexity"; ui_category = AS_CAT_PATTERN; > = 9;

uniform float PatternScale < ui_type = "slider"; ui_label = "Pattern Scale"; ui_min = 0.1; ui_max = 3.0; ui_tooltip = "Overall scale of the gradient pattern"; ui_category = AS_CAT_PATTERN; > = 1.0;

uniform float WaveIntensity < ui_type = "slider"; ui_label = "Wave Intensity"; ui_min = 0.1; ui_max = 2.0; ui_tooltip = "Intensity of the wave calculations"; ui_category = AS_CAT_PATTERN; > = 1.0;

// --- Color Controls ---
uniform float ColorIntensity < ui_type = "slider"; ui_label = "Color Intensity"; ui_min = 0.0; ui_max = 2.0; ui_tooltip = "Overall color saturation and intensity"; ui_category = AS_CAT_COLOR; > = 1.0;

uniform float3 ChannelWeights < ui_type = "slider"; ui_label = "Channel Weights"; ui_min = 0.0; ui_max = 2.0; ui_tooltip = "RGB channel weight distribution"; ui_category = AS_CAT_COLOR; > = float3(0.7, 0.5, 0.3);

uniform float3 ChannelOffsets < ui_type = "slider"; ui_label = "Channel Offsets"; ui_min = 0.0; ui_max = 1.0; ui_tooltip = "Base offset for each RGB channel"; ui_category = AS_CAT_COLOR; > = float3(0.3, 0.2, 0.5);

uniform bool EnableColorGrading < ui_label = "Enable Color Grading"; ui_tooltip = "Apply additional cosine-based color grading"; ui_category = AS_CAT_COLOR; > = true;

uniform float ColorGradingIntensity < ui_type = "slider"; ui_label = "Color Grading Intensity"; ui_min = 0.0; ui_max = 2.0; ui_tooltip = "Intensity of the color grading effect"; ui_category = AS_CAT_COLOR; > = 0.5;

// --- Standard AS Controls ---
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")

AS_AUDIO_TARGET_UI(AudioTarget, "None\0Animation Speed\0Pattern Scale\0Wave Intensity\0Color Intensity\0", 0)

AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_VOLUME, "Audio Reactivity")
AS_AUDIO_MULT_UI(AudioMultiplier, "Audio Multiplier", AS_RANGE_AUDIO_MULT_DEFAULT, 5.0, "Audio Reactivity")

AS_POS_UI(EffectCenter)
AS_SCALE_UI(EffectScale)
AS_ROTATION_UI(SnapRotation, FineRotation)
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_NORMAL)
AS_BLENDAMOUNT_UI(BlendAmount)
AS_DEBUG_UI("Off\0Pattern Values\0Accumulator A\0Accumulator D\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

float3 calculateGlossyGradientPattern(float2 uv, float time, float audioValue) {
    // Center UV coordinates for proper rotation around center
    uv -= 0.5;
    
    // Apply rotation around center if needed
    float rotation = AS_getRotationRadians(SnapRotation, FineRotation);
    if (abs(rotation) > AS_EPSILON) {
        uv = AS_rotate2D(uv, rotation);
    }
    
    // Apply position and scale transformations
    uv -= EffectCenter;
    uv /= EffectScale;
    
    // Apply audio reactivity to selected parameters
    float animSpeed_final = AnimationSpeed;
    float patternScale_final = PatternScale;
    float waveIntensity_final = WaveIntensity;
    float colorIntensity_final = ColorIntensity;
    
    if (AudioTarget > 0 && AudioMultiplier > 0.0) {
        float audioMod = audioValue * AudioMultiplier;
        if (AudioTarget == 1) { // Animation Speed
            animSpeed_final = AnimationSpeed + (AnimationSpeed * audioMod * 0.5);
        } else if (AudioTarget == 2) { // Pattern Scale
            patternScale_final = PatternScale + (PatternScale * audioMod * 0.3);
        } else if (AudioTarget == 3) { // Wave Intensity
            waveIntensity_final = WaveIntensity + (WaveIntensity * audioMod * 0.4);
        } else if (AudioTarget == 4) { // Color Intensity
            colorIntensity_final = ColorIntensity + (ColorIntensity * audioMod * 0.6);
        }
    }
    
    // Scale the pattern
    uv *= patternScale_final;
    
    // Initialize accumulators - matching original algorithm
    float d = -(time * 0.3); // Using fixed time multiplier for consistency
    float a = 0.0;
    
    // Main trigonometric iteration loop
    for (float i = 0.0; i < Iterations; i += 1.0) {
        a += cos(d + i * uv.x - a) * waveIntensity_final;
        d += 0.5 * sin(a + i * uv.y) * waveIntensity_final;
    }
    
    // Restore time offset
    d += (time * 0.3);
    
    // Calculate RGB channels using the accumulated values and consolidated parameters
    float r = cos(uv.x * a) * ChannelWeights.r + ChannelOffsets.r;
    float g = cos(uv.y * d) * ChannelWeights.g + ChannelOffsets.g;
    float b = cos(a + d) * ChannelWeights.b + ChannelOffsets.b;
    
    float3 col = float3(r, g, b) * colorIntensity_final;
    
    // Apply color grading if enabled
    if (EnableColorGrading) {
        col = cos(col * cos(float3(d, a, 2.5)) * ColorGradingIntensity + 0.5);
    }
    
    return saturate(col);
}

// ============================================================================
// PIXEL SHADER
// ============================================================================

float4 PS_GlossyGradient(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float4 finalColor = tex2D(ReShade::BackBuffer, texcoord);
    float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);
    
    // Get audio reactivity value
    float audioValue = AS_audioLevelFromSource(AudioSource) * AudioMultiplier;
    
    // Calculate the glossy gradient pattern
    float3 col = calculateGlossyGradientPattern(texcoord, time, audioValue);
    
    // Debug modes
    if (DebugMode == 1) {
        // Show combined pattern values
        float avgCol = (col.r + col.g + col.b) / 3.0;
        return float4(avgCol, avgCol, avgCol, 1.0);
    } else if (DebugMode == 2) {
        // Show red channel (accumulator A influence)
        return float4(col.r, 0.0, 0.0, 1.0);
    } else if (DebugMode == 3) {
        // Show green channel (accumulator D influence)
        return float4(0.0, col.g, 0.0, 1.0);
    }
    
    // Apply blend mode
    finalColor = AS_blendRGBA(float4(col, 1.0), finalColor, BlendMode, BlendAmount);
    
    return finalColor;
}

// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_VFX_GlossyGradient <
    ui_label = "[AS] VFX: Glossy Gradient";
    ui_tooltip = "Glossy gradient pattern generator using mathematical functions";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_GlossyGradient;
    }
}

#endif // __AS_VFX_GlossyGradient_1_fx
