/**
 * AS_BGX_Fluorescent.1.fx - Neon Fluorescent Background Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * Original Shader "Fluorescent" by @XorDev: https://x.com/XorDev/status/1928504290290635042
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a vibrant neon fluorescent background effect that simulates the glow and intensity of fluorescent lighting.
 * Perfect for creating retro, cyberpunk, or futuristic atmospheres with customizable colors and intensity.
 *
 * FEATURES:
 * - Raymarched volumetric fluorescent effect with depth
 * - Dynamic color shifting with RGB phase controls
 * - Animated pulsing and flowing patterns
 * - Audio reactivity for rhythm-synchronized lighting
 * - Standard stage controls for positioning and depth
 * - Customizable iteration count for quality vs performance balance
 * - Blend mode controls for integration with existing scenes
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Sets up a ray direction for each pixel using screen coordinates
 * 2. Iteratively marches the ray through 3D space with adaptive step sizing
 * 3. Applies coordinate transformations and rotations to create complex shapes
 * 4. Calculates distance estimates and accumulates color at each step
 * 5. Uses trigonometric functions with time animation for dynamic patterns
 * 6. Applies final tone-mapping and blending for integration
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_Fluorescent_1_fx
#define __AS_BGX_Fluorescent_1_fx

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
static const int ITERATIONS_DEFAULT = 68; // Updated based on UI optimization

// --- Scene Geometry & Raymarching ---
static const float Z_OFFSET_MIN = 0.0;
static const float Z_OFFSET_MAX = 20.0;
static const float Z_OFFSET_DEFAULT = 7.156; // Updated based on UI optimization
static const float SHELL_RADIUS_MIN = 0.1;
static const float SHELL_RADIUS_MAX = 5.0;
static const float SHELL_RADIUS_DEFAULT = 2.354; // Updated based on UI optimization
static const float STEP_BASE_MIN = 0.01;
static const float STEP_BASE_MAX = 0.5;
static const float STEP_BASE_DEFAULT = 0.253; // Updated based on UI optimization
static const float STEP_SCALE_MIN = 0.01;
static const float STEP_SCALE_MAX = 0.5;
static const float STEP_SCALE_DEFAULT = 0.038; // Updated based on UI optimization

// --- Color Generation & Effect Trigger ---
static const float EFFECT_POS_MIN = 0.0;
static const float EFFECT_POS_MAX = 10.0;
static const float EFFECT_POS_DEFAULT = 6.0; // Kept at same value as seen in the image
static const float EFFECT_SCALE_MIN = 1.0;
static const float EFFECT_SCALE_MAX = 20.0;
static const float EFFECT_SCALE_DEFAULT = 12.053; // Updated based on UI optimization
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

// --- Rotation Constants ---
static const float ROTATION_COS = 0.8;  // Cosine component of rotation matrix
static const float ROTATION_SIN = 0.6;  // Sine component of rotation matrix

// --- Color Constants ---
static const float COLOR_BASE_OFFSET = 1.0;  // Base offset for color calculations
static const float COORD_SCALE = 2.0;        // Coordinate scaling factor for ray direction
static const float STEP_INCREMENT = 1.0;     // Step increment for pre-increment simulation

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
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")

// --- Category: Stage Controls ---
AS_STAGEDEPTH_UI(StageDepth)
AS_POSITION_SCALE_UI(Position, Scale)
AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation)

// --- Category: Final Mix ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_Fluorescent(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    // Apply stage depth test
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < StageDepth) {
        return tex2D(ReShade::BackBuffer, texcoord);
    }
    
    // Apply coordinate transformations: center → rotate → position/scale
    float aspectRatio = ReShade::AspectRatio;
    float2 centeredCoord = AS_centerCoord(texcoord, aspectRatio);
    
    // Apply rotation
    float rotation = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
    float2 rotatedCoord = AS_applyRotation(centeredCoord, rotation);
    
    // Apply position and scale
    float2 transformedCoord = AS_applyPosScale(rotatedCoord, Position, Scale);
    
    float4 finalColor = float4(0.0, 0.0, 0.0, 0.0); // Accumulated color
    float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);
    float rayDistance = 0.0; // Accumulated distance for ray marching
    float stepSize;         // Step size for each iteration
    float surfaceLength;    // Temporary variable for length/scaling

    // Convert transformed coordinates back to a coordinate system suitable for raymarching
    // The original algorithm expects coordinates in a specific range
    float2 rayCoord = transformedCoord;

    // Calculate constants outside the loop to improve performance
    // Ray Direction is constant for each pixel
    float3 rayDirection = normalize(float3(rayCoord, -1.0));
    
    // Rotation matrix is constant for the entire frame
    float2x2 rotationMatrix = float2x2(ROTATION_COS, -ROTATION_SIN, ROTATION_SIN, ROTATION_COS);

    // Ray Marching Loop
    for (int i = 0; i < IterationCount; i++)
    {
        // Current point in 3D space along the ray (using precalculated direction)
        float3 position = rayDistance * rayDirection;

        // Coordinate Transformations (Folding Space / Creating Shapes)
        // 1. Rotate y and z coordinates of the position using the precalculated matrix
        position.yz = mul(rotationMatrix, position.yz);
        // 2. Translate along the z-axis
        position.z += ZSceneOffset;

        // Distance Estimation
        surfaceLength = length(position);

        // Step Size Calculation (Adaptive Step)
        stepSize = StepBase + StepScale * abs(surfaceLength - ShellRadius);

        // Advance Ray
        rayDistance += stepSize;

        // Color Accumulation
        float effectTrigger = tanh(surfaceLength - EffectHighlightPos) * EffectHighlightScale;
        float4 colorPhaseOffsets = float4(ColorPhaseR, ColorPhaseG, ColorPhaseB, 0.0);
        float4 baseColor = cos(effectTrigger - colorPhaseOffsets) + COLOR_BASE_OFFSET; // Ranges 0 to 2

        // The original code uses ++s (pre-increment) for s (here surfaceLength) in divisions.
        float surfaceLengthIncremented = surfaceLength + STEP_INCREMENT; // Simulating pre-increment for this specific use pattern

        float3 positionDivFreq1 = position / surfaceLengthIncremented / PatternFreq1;
        float3 positionDivFreq2 = position / surfaceLengthIncremented / PatternFreq2; // Original used s (now surfaceLengthIncremented) again for second term

        float3 cosTermInput = positionDivFreq1 - time;
        float3 sinTermInput = positionDivFreq2 + time;

        float3 cosValues = cos(cosTermInput);
        float3 sinValuesSwizzled = sin(sinTermInput).yzx; // Swizzle: (sin.y, sin.z, sin.x)

        float dotProduct = dot(cosValues, sinValuesSwizzled);
        float pattern = pow(abs(dotProduct), PatternContrast); // Using abs for stability with pow

        // Add to output color, scaled by pattern and attenuated by distance
        if (rayDistance > AS_EPSILON) // Avoid division by zero or very small numbers
        {
            finalColor += baseColor * pattern / rayDistance;
        }    }    // Final Color Transformation
    // Apply a tanh function for tone mapping.
    float4 effectOutput = tanh(finalColor / FinalBrightnessScale);
    effectOutput.a = 1.0; // Ensure full alpha for the effect
    
    // For background effects, we want to blend the effect with the original background
    // When BlendAmount = 0, show original background
    // When BlendAmount = 1, show effect blended according to BlendMode
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    
    // Apply the blend mode between effect and original background
    float3 blendedColor = AS_applyBlend(effectOutput.rgb, originalColor.rgb, BlendMode);
    
    // Mix between original and blended result based on BlendAmount
    float3 finalResult = lerp(originalColor.rgb, blendedColor, BlendAmount);
    
    return float4(finalResult, originalColor.a);
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_BGX_Fluorescent < ui_label = "[AS] BGX: Fluorescent"; ui_tooltip = "Creates a vibrant neon fluorescent background effect with raymarched volumetric patterns. Perfect for retro, cyberpunk, or futuristic atmospheres. Original algorithm by @XorDev."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Fluorescent;
    }
}

#endif // __AS_BGX_Fluorescent_1_fx