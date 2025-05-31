/**
 * AS_VFX_Fluorescent.1.fx - Raymarched Fluorescent Abstract Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * Original Shader "Fluorescent" by @XorDev: https://x.com/XorDev/status/1928504290290635042
 *
 * DESCRIPTION:
 * This shader renders a raymarched abstract scene with fluorescent, evolving patterns.
 * It creates a sense of depth and complex structures through iterative calculations.
 *
 * FEATURES:
 * - Raymarched volumetric effect.
 * - Animating patterns based on time.
 * - Customizable iteration count, colors, and animation speed.
 * - Standard blending options.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Sets up a ray direction for each pixel.
 * 2. Iteratively marches the ray through a 3D space.
 * 3. At each step, transforms coordinates (rotation, translation) to define shapes.
 * 4. Calculates a distance estimate and advances the ray.
 * 5. Accumulates color based on mathematical formulas involving current position,
 * distance, and time, creating complex visual patterns.
 * 6. Applies a final tone-mapping step (tanh) to the accumulated color.
 */

// ============================================================================
// TECHNIQUE GUARD
// ============================================================================
#ifndef __AS_VFX_XorFluorescent_1_fx
#define __AS_VFX_XorFluorescent_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// TUNABLE CONSTANTS (FOR UI)
// ============================================================================

// --- Iterations & Steps ---
static const int ITERATIONS_MIN = 10;
static const int ITERATIONS_MAX = 120;
static const int ITERATIONS_DEFAULT = 60;

// --- Scene Geometry & Raymarching ---
static const float Z_OFFSET_MIN = 0.0;
static const float Z_OFFSET_MAX = 20.0;
static const float Z_OFFSET_DEFAULT = 8.0;
static const float SHELL_RADIUS_MIN = 0.1;
static const float SHELL_RADIUS_MAX = 5.0;
static const float SHELL_RADIUS_DEFAULT = 1.2;
static const float STEP_BASE_MIN = 0.01;
static const float STEP_BASE_MAX = 0.5;
static const float STEP_BASE_DEFAULT = 0.1;
static const float STEP_SCALE_MIN = 0.01;
static const float STEP_SCALE_MAX = 0.5;
static const float STEP_SCALE_DEFAULT = 0.1;

// --- Color Generation & Effect Trigger ---
static const float EFFECT_POS_MIN = 0.0;
static const float EFFECT_POS_MAX = 10.0;
static const float EFFECT_POS_DEFAULT = 6.0;
static const float EFFECT_SCALE_MIN = 1.0;
static const float EFFECT_SCALE_MAX = 20.0;
static const float EFFECT_SCALE_DEFAULT = 6.0;
static const float COLOR_PHASE_MIN = 0.0;
static const float COLOR_PHASE_MAX = 6.28318; // 2*PI
static const float COLOR_PHASE_R_DEFAULT = 2.0;
static const float COLOR_PHASE_G_DEFAULT = 3.0;
static const float COLOR_PHASE_B_DEFAULT = 4.0;

// --- Pattern Details ---
static const float PATTERN_FREQ_MIN = 0.005;
static const float PATTERN_FREQ_MAX = 0.5;
static const float PATTERN_FREQ1_DEFAULT = 0.1;
static const float PATTERN_FREQ2_DEFAULT = 0.04;
static const float PATTERN_CONTRAST_MIN = 1.0;
static const float PATTERN_CONTRAST_MAX = 10.0;
static const float PATTERN_CONTRAST_DEFAULT = 4.0;

// --- Final Output ---
static const float BRIGHTNESS_SCALE_MIN = 1.0;
static const float BRIGHTNESS_SCALE_MAX = 100.0;
static const float BRIGHTNESS_SCALE_DEFAULT = 20.0;

// ============================================================================
// UI UNIFORMS
// ============================================================================

// --- Category: Raymarching Engine ---
uniform int IterationCount < ui_type = "slider"; ui_label = "Quality vs. Performance"; ui_tooltip = "Number of steps for ray marching. Higher values increase detail and accuracy but reduce performance significantly. Lower for speed, higher for final renders."; ui_min = ITERATIONS_MIN; ui_max = ITERATIONS_MAX; ui_category = "Raymarching Engine"; > = ITERATIONS_DEFAULT;
uniform float StepBase < ui_type = "slider"; ui_label = "Minimum Ray Step Size"; ui_tooltip = "Smallest distance the ray advances in each step. Affects detail in dense areas and performance."; ui_min = STEP_BASE_MIN; ui_max = STEP_BASE_MAX; ui_category = "Raymarching Engine"; > = STEP_BASE_DEFAULT;
uniform float StepScale < ui_type = "slider"; ui_label = "Adaptive Ray Step Scale"; ui_tooltip = "How much the ray step size adapts based on distance to surfaces. Influences detail and marching speed through empty space."; ui_min = STEP_SCALE_MIN; ui_max = STEP_SCALE_MAX; ui_category = "Raymarching Engine"; > = STEP_SCALE_DEFAULT;

// --- Category: Scene Definition ---
uniform float ZSceneOffset < ui_type = "slider"; ui_label = "Scene Depth Offset"; ui_tooltip = "Pushes the entire generated scene further away or brings it closer along the view axis."; ui_min = Z_OFFSET_MIN; ui_max = Z_OFFSET_MAX; ui_category = "Scene Definition"; > = Z_OFFSET_DEFAULT;
uniform float ShellRadius < ui_type = "slider"; ui_label = "Central Shell Radius"; ui_tooltip = "Defines the radius of the primary spherical shell structure that the raymarcher detects."; ui_min = SHELL_RADIUS_MIN; ui_max = SHELL_RADIUS_MAX; ui_category = "Scene Definition"; > = SHELL_RADIUS_DEFAULT;

// --- Category: Visual Style ---
uniform float EffectHighlightPos < ui_type = "slider"; ui_label = "Highlight Trigger Distance"; ui_tooltip = "Distance at which the main color effect begins to activate and intensify."; ui_min = EFFECT_POS_MIN; ui_max = EFFECT_POS_MAX; ui_category = "Visual Style"; > = EFFECT_POS_DEFAULT;
uniform float EffectHighlightScale < ui_type = "slider"; ui_label = "Highlight Intensity Scale"; ui_tooltip = "Controls the strength and abruptness of the highlight trigger effect."; ui_min = EFFECT_SCALE_MIN; ui_max = EFFECT_SCALE_MAX; ui_category = "Visual Style"; > = EFFECT_SCALE_DEFAULT;
uniform float ColorPhaseR < ui_type = "slider"; ui_label = "Color Shift (Red)"; ui_tooltip = "Adjusts the phase for the Red color channel, creating shifting color harmonies."; ui_min = COLOR_PHASE_MIN; ui_max = COLOR_PHASE_MAX; ui_category = "Visual Style"; > = COLOR_PHASE_R_DEFAULT;
uniform float ColorPhaseG < ui_type = "slider"; ui_label = "Color Shift (Green)"; ui_tooltip = "Adjusts the phase for the Green color channel, creating shifting color harmonies."; ui_min = COLOR_PHASE_MIN; ui_max = COLOR_PHASE_MAX; ui_category = "Visual Style"; > = COLOR_PHASE_G_DEFAULT;
uniform float ColorPhaseB < ui_type = "slider"; ui_label = "Color Shift (Blue)"; ui_tooltip = "Adjusts the phase for the Blue color channel, creating shifting color harmonies."; ui_min = COLOR_PHASE_MIN; ui_max = COLOR_PHASE_MAX; ui_category = "Visual Style"; > = COLOR_PHASE_B_DEFAULT;
uniform float FinalBrightnessScale < ui_type = "slider"; ui_label = "Overall Brightness & Saturation"; ui_tooltip = "Controls the final tone mapping. Lower values increase brightness and saturation; higher values are more subdued."; ui_min = BRIGHTNESS_SCALE_MIN; ui_max = BRIGHTNESS_SCALE_MAX; ui_category = "Visual Style"; > = BRIGHTNESS_SCALE_DEFAULT;

// --- Category: Pattern Generation ---
uniform float PatternFreq1 < ui_type = "slider"; ui_label = "Primary Pattern Frequency"; ui_tooltip = "Frequency of the primary cosine component in the generative pattern. Affects pattern scale and detail."; ui_min = PATTERN_FREQ_MIN; ui_max = PATTERN_FREQ_MAX; ui_step = 0.001; ui_category = "Pattern Generation"; > = PATTERN_FREQ1_DEFAULT;
uniform float PatternFreq2 < ui_type = "slider"; ui_label = "Secondary Pattern Frequency"; ui_tooltip = "Frequency of the secondary sine component in the generative pattern. Interacts with Primary Frequency for complexity."; ui_min = PATTERN_FREQ_MIN; ui_max = PATTERN_FREQ_MAX; ui_step = 0.001; ui_category = "Pattern Generation"; > = PATTERN_FREQ2_DEFAULT;
uniform float PatternContrast < ui_type = "slider"; ui_label = "Pattern Sharpness"; ui_tooltip = "Exponent applied to the pattern calculation. Higher values create sharper, more defined patterns."; ui_min = PATTERN_CONTRAST_MIN; ui_max = PATTERN_CONTRAST_MAX; ui_category = "Pattern Generation"; > = PATTERN_CONTRAST_DEFAULT;

// --- Category: Animation ---
AS_ANIMATION_SPEED_UI(AnimationSpeed, "Animation")

// --- Category: Final Mix ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_XorFluorescent(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float4 ps_finalColor = float4(0.0, 0.0, 0.0, 0.0); // Accumulated color
    float fTime = AS_getTime() * AnimationSpeed;
    float z_dist = 0.0; // Accumulated distance for ray marching
    float d_step;       // Step size for each iteration
    float s_len;        // Temporary variable for length/scaling

    float2 Rxy = ReShade::ScreenSize;
    float2 fragCoord = texcoord * Rxy;

    // --- Ray Marching Loop ---
    for (int i = 0; i < IterationCount; i++)
    {
        // --- Ray Direction and Position ---
        // Original ray setup: vec3(2*fragCoord - R.xy, -R.x)
        float3 rd = normalize(float3(2.0 * fragCoord - Rxy, -Rxy.x));
        float3 p = z_dist * rd; // Current point in 3D space along the ray

        // --- Coordinate Transformations (Folding Space / Creating Shapes) ---
        // 1. Rotate y and z coordinates of the point.
        //    Original matrix: 0.1 * mat2(8, -6, 6, 8) which is mat2(0.8, -0.6, 0.6, 0.8)
        float c_rot = 0.8;
        float s_rot = 0.6;
        float2x2 rotationMatrix = float2x2(c_rot, -s_rot, s_rot, c_rot);
        p.yz = mul(rotationMatrix, p.yz);

        // 2. Translate along the z-axis
        p.z += ZSceneOffset;

        // --- Distance Estimation ---
        s_len = length(p);

        // --- Step Size Calculation (Adaptive Step) ---
        d_step = StepBase + StepScale * abs(s_len - ShellRadius);

        // --- Advance Ray ---
        z_dist += d_step;

        // --- Color Accumulation ---
        float f_trigger = tanh(s_len - EffectHighlightPos) * EffectHighlightScale;
        float4 colorPhaseOffsets = float4(ColorPhaseR, ColorPhaseG, ColorPhaseB, 0.0);
        float4 base_col = cos(f_trigger - colorPhaseOffsets) + 1.0; // Ranges 0 to 2

        // The original code uses `++s` (pre-increment) for `s` (here s_len) in divisions.
        float s_len_inc = s_len + 1.0; // Simulating pre-increment for this specific use pattern

        float3 p_div_s_inc_freq1 = p / s_len_inc / PatternFreq1;
        float3 p_div_s_inc_freq2 = p / s_len_inc / PatternFreq2; // Original used s (now s_len_inc) again for second term

        float3 cosTermInput = p_div_s_inc_freq1 - fTime;
        float3 sinTermInput = p_div_s_inc_freq2 + fTime;

        float3 cosValues = cos(cosTermInput);
        float3 sinValuesSwizzled = sin(sinTermInput).yzx; // Swizzle: (sin.y, sin.z, sin.x)

        float f_dot = dot(cosValues, sinValuesSwizzled);
        float f_pattern = pow(abs(f_dot), PatternContrast); // Using abs for stability with pow

        // Add to output color, scaled by pattern and attenuated by distance
        if (z_dist > AS_EPSILON) // Avoid division by zero or very small numbers
        {
            ps_finalColor += base_col * f_pattern / z_dist;
        }
    }

    // --- Final Color Transformation ---
    // Apply a tanh function for tone mapping.
    float4 effect_output = tanh(ps_finalColor / FinalBrightnessScale);
    effect_output.a = 1.0; // Ensure full alpha

    float4 original_color = tex2D(ReShade::BackBuffer, texcoord);
    return AS_applyBlend(effect_output, original_color, BlendMode, BlendAmount);
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_VFX_XorFluorescent < ui_tooltip = "Renders a raymarched abstract scene with fluorescent, evolving patterns. Original by @XorDev."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_XorFluorescent;
    }
}

#endif // __AS_VFX_XorFluorescent_1_fx