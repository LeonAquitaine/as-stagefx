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

uniform float AnimationSpeed <
    ui_type = "slider";
    ui_label = "Animation Speed";
    ui_min = 0.0; ui_max = 3.0;
    ui_tooltip = "Controls the speed of pattern evolution";
    ui_category = "Animation";
> = 1.0;

uniform int Iterations <
    ui_type = "slider";
    ui_label = "Pattern Iterations";
    ui_min = 3; ui_max = 15;
    ui_tooltip = "Number of iterations for pattern complexity";
    ui_category = "Pattern Control";
> = 9;

uniform float PatternScale <
    ui_type = "slider";
    ui_label = "Pattern Scale";
    ui_min = 0.1; ui_max = 3.0;
    ui_tooltip = "Overall scale of the trigonometric pattern";
    ui_category = "Pattern Control";
> = 1.0;

uniform float WaveIntensity <
    ui_type = "slider";
    ui_label = "Wave Intensity";
    ui_min = 0.1; ui_max = 2.0;
    ui_tooltip = "Intensity of the wave calculations";
    ui_category = "Pattern Control";
> = 1.0;

uniform float TimeMultiplier <
    ui_type = "slider";
    ui_label = "Time Multiplier";
    ui_min = 0.1; ui_max = 1.0;
    ui_tooltip = "Base time scaling factor";
    ui_category = "Animation";
> = 0.3;

uniform float ColorIntensity <
    ui_type = "slider";
    ui_label = "Color Intensity";
    ui_min = 0.0; ui_max = 2.0;
    ui_tooltip = "Overall color saturation and intensity";
    ui_category = "Color";
> = 1.0;

uniform float RedChannel <
    ui_type = "slider";
    ui_label = "Red Channel Weight";
    ui_min = 0.0; ui_max = 2.0;
    ui_tooltip = "Weight of the red color channel";
    ui_category = "Color";
> = 0.7;

uniform float GreenChannel <
    ui_type = "slider";
    ui_label = "Green Channel Weight";
    ui_min = 0.0; ui_max = 2.0;
    ui_tooltip = "Weight of the green color channel";
    ui_category = "Color";
> = 0.5;

uniform float BlueChannel <
    ui_type = "slider";
    ui_label = "Blue Channel Weight";
    ui_min = 0.0; ui_max = 2.0;
    ui_tooltip = "Weight of the blue color channel";
    ui_category = "Color";
> = 0.3;

uniform float RedOffset <
    ui_type = "slider";
    ui_label = "Red Offset";
    ui_min = 0.0; ui_max = 1.0;
    ui_tooltip = "Base offset for red channel";
    ui_category = "Color";
> = 0.3;

uniform float GreenOffset <
    ui_type = "slider";
    ui_label = "Green Offset";
    ui_min = 0.0; ui_max = 1.0;
    ui_tooltip = "Base offset for green channel";
    ui_category = "Color";
> = 0.2;

uniform float BlueOffset <
    ui_type = "slider";
    ui_label = "Blue Offset";
    ui_min = 0.0; ui_max = 1.0;
    ui_tooltip = "Base offset for blue channel";
    ui_category = "Color";
> = 0.5;

uniform bool EnableColorGrading <
    ui_label = "Enable Color Grading";
    ui_tooltip = "Apply additional cosine-based color grading";
    ui_category = "Color";
> = true;

uniform float ColorGradingIntensity <
    ui_type = "slider";
    ui_label = "Color Grading Intensity";
    ui_min = 0.0; ui_max = 2.0;
    ui_tooltip = "Intensity of the color grading effect";
    ui_category = "Color";
> = 0.5;

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
    // Apply position and scale transformations
    uv -= EffectCenter;
    uv /= EffectScale;
    
    // Apply rotation if needed
    float rotation = AS_getRotationRadians(SnapRotation, FineRotation);
    if (abs(rotation) > AS_EPSILON) {
        uv = AS_rotate2D(uv, rotation);
    }
    
    // Scale the pattern
    uv *= PatternScale;
    
    // Initialize accumulators - matching original algorithm
    float d = -(time * TimeMultiplier * AnimationSpeed);
    float a = 0.0;
    
    // Apply audio reactivity to initial values
    if (AudioMultiplier > 0.0) {
        d += audioValue * AudioMultiplier * 0.1;
        a += audioValue * AudioMultiplier * 0.05;
    }
    
    // Main trigonometric iteration loop
    for (float i = 0.0; i < Iterations; i += 1.0) {
        a += cos(d + i * uv.x - a) * WaveIntensity;
        d += 0.5 * sin(a + i * uv.y) * WaveIntensity;
    }
    
    // Restore time offset
    d += (time * TimeMultiplier * AnimationSpeed);
    
    // Calculate RGB channels using the accumulated values
    float r = cos(uv.x * a) * RedChannel + RedOffset;
    float g = cos(uv.y * d) * GreenChannel + GreenOffset;
    float b = cos(a + d) * BlueChannel + BlueOffset;
    
    float3 col = float3(r, g, b) * ColorIntensity;
    
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
    float time = AS_getTime();
    
    // Get audio reactivity value
    float audioValue = AS_getAudioSource(AudioSource) * AudioMultiplier;
    
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
    finalColor = AS_applyBlend(float4(col, 1.0), finalColor, BlendMode, BlendAmount);
    
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
