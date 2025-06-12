/**
 * AS_BGX_BlueCorona.1.fx - Blue Corona Background Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *  * CREDITS:
 * Based on "Blue Corona [256 Chars]" by SnoopethDuckDuck
 * Shadertoy: https://www.shadertoy.com/view/XfKGWV
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a vibrant, abstract blue corona effect with fluid, dynamic motion.
 * The effect generates hypnotic patterns through iterative mathematical transformations,
 * resulting in organic, plasma-like visuals with a predominantly blue color scheme.
 *
 * FEATURES:
 * - Abstract, organic blue corona patterns
 * - Smooth fluid-like animation
 * - Customizable iteration count and pattern scale
 * - Animation speed and flow controls
 * - Intuitive color controls (higher values = stronger colors)
 * - Customizable background color
 * - Audio reactivity with multiple target parameters
 * - Depth-aware rendering
 * - Standard position, rotation, scale, and blend options
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Uses iterative matrix transformations and trigonometric functions
 * 2. Builds up a complex vector field through multiple passes
 * 3. Applies exponential transformations to create the final colors
 * 4. Colors controlled through weighted channel components
 * 5. Integrates with standard AS features for positioning and animation
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_BlueCorona_1_fx
#define __AS_BGX_BlueCorona_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"     
#include "AS_Palette.1.fxh"  

namespace ASBlueCorona {

// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================

// --- Pattern Parameters ---
static const float PATTERN_SCALE_MIN = 5.0;
static const float PATTERN_SCALE_MAX = 15.0;
static const float PATTERN_SCALE_STEP = 0.1;
static const float PATTERN_SCALE_DEFAULT = 9.0;

static const float PATTERN_OFFSET_MIN = 0.0;
static const float PATTERN_OFFSET_MAX = 30.0;
static const float PATTERN_OFFSET_STEP = 0.1;
static const float PATTERN_OFFSET_DEFAULT = 10.0;

static const int ITERATION_COUNT_MIN = 5;
static const int ITERATION_COUNT_MAX = 15;
static const int ITERATION_COUNT_DEFAULT = 9;

static const float FLOW_MULTIPLIER_MIN = 0.1;
static const float FLOW_MULTIPLIER_MAX = 1.0;
static const float FLOW_MULTIPLIER_STEP = 0.01;
static const float FLOW_MULTIPLIER_DEFAULT = 0.3;

// --- Color Tuning ---
static const float RED_WEIGHT_MIN = 0.1;
static const float RED_WEIGHT_MAX = 10.0;
static const float RED_WEIGHT_STEP = 0.1;
static const float RED_WEIGHT_DEFAULT = 2.0;

static const float GREEN_WEIGHT_MIN = 0.1;
static const float GREEN_WEIGHT_MAX = 10.0;
static const float GREEN_WEIGHT_STEP = 0.1;
static const float GREEN_WEIGHT_DEFAULT = 4.0;

static const float BLUE_WEIGHT_MIN = 0.1;
static const float BLUE_WEIGHT_MAX = 10.0;
static const float BLUE_WEIGHT_STEP = 0.1;
static const float BLUE_WEIGHT_DEFAULT = 9.0;

// Background color default - dark gray
static const float3 BACKGROUND_COLOR_DEFAULT = float3(0.05, 0.05, 0.05);

// --- Animation ---
static const float ANIMATION_SPEED_MIN = 0.0;
static const float ANIMATION_SPEED_MAX = 5.0;
static const float ANIMATION_SPEED_STEP = 0.01;
static const float ANIMATION_SPEED_DEFAULT = 0.25;

static const float ANIMATION_KEYFRAME_MIN = 0.0;
static const float ANIMATION_KEYFRAME_MAX = 100.0;
static const float ANIMATION_KEYFRAME_STEP = 0.1;
static const float ANIMATION_KEYFRAME_DEFAULT = 0.0;

// --- Audio ---
static const int AUDIO_TARGET_DEFAULT = 0;
static const float AUDIO_MULTIPLIER_DEFAULT = 1.0;
static const float AUDIO_MULTIPLIER_MAX = 2.0;

// --- Internal Constants ---
static const float ROTATION_ANGLE_OFFSET_1 = 11.0;
static const float ROTATION_ANGLE_OFFSET_2 = 33.0;
static const float CORONA_FINAL_OFFSET = 2.0;
static const float COLOR_FACTOR = 0.001;

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Pattern Parameters ---











uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nBased on 'Blue Corona [256 Chars]' by SnoopethDuckDuck\nLink: https://www.shadertoy.com/view/XfKGWV\nLicence: CC Share-Alike Non-Commercial\n\n";>;

uniform float PatternScale < ui_type = "slider"; ui_label = "Pattern Scale"; ui_tooltip = "Controls the overall scale of the corona pattern."; ui_min = PATTERN_SCALE_MIN; ui_max = PATTERN_SCALE_MAX; ui_step = PATTERN_SCALE_STEP; ui_category = "Pattern"; > = PATTERN_SCALE_DEFAULT;
uniform float PatternOffset < ui_type = "slider"; ui_label = "Pattern Offset"; ui_tooltip = "Adjusts the offset/threshold of the pattern."; ui_min = PATTERN_OFFSET_MIN; ui_max = PATTERN_OFFSET_MAX; ui_step = PATTERN_OFFSET_STEP; ui_category = "Pattern"; > = PATTERN_OFFSET_DEFAULT;
uniform int IterationCount < ui_type = "slider"; ui_label = "Iteration Count"; ui_tooltip = "Number of calculation iterations. Higher values create more complex patterns but may reduce performance."; ui_min = ITERATION_COUNT_MIN; ui_max = ITERATION_COUNT_MAX; ui_category = "Pattern"; > = ITERATION_COUNT_DEFAULT;
uniform float FlowMultiplier < ui_type = "slider"; ui_label = "Flow Multiplier"; ui_tooltip = "Controls how much the pattern flows and distorts."; ui_min = FLOW_MULTIPLIER_MIN; ui_max = FLOW_MULTIPLIER_MAX; ui_step = FLOW_MULTIPLIER_STEP; ui_category = "Pattern"; > = FLOW_MULTIPLIER_DEFAULT;

// --- Color Tuning ---
uniform float RedWeight < ui_type = "slider"; ui_label = "Red Channel Weight"; ui_tooltip = "Weight applied to the red channel. Higher values produce stronger red color."; ui_min = RED_WEIGHT_MIN; ui_max = RED_WEIGHT_MAX; ui_step = RED_WEIGHT_STEP; ui_category = "Color"; > = RED_WEIGHT_DEFAULT;
uniform float GreenWeight < ui_type = "slider"; ui_label = "Green Channel Weight"; ui_tooltip = "Weight applied to the green channel. Higher values produce stronger green color."; ui_min = GREEN_WEIGHT_MIN; ui_max = GREEN_WEIGHT_MAX; ui_step = GREEN_WEIGHT_STEP; ui_category = "Color"; > = GREEN_WEIGHT_DEFAULT;
uniform float BlueWeight < ui_type = "slider"; ui_label = "Blue Channel Weight"; ui_tooltip = "Weight applied to the blue channel. Higher values produce stronger blue color."; ui_min = BLUE_WEIGHT_MIN; ui_max = BLUE_WEIGHT_MAX; ui_step = BLUE_WEIGHT_STEP; ui_category = "Color"; > = BLUE_WEIGHT_DEFAULT;
uniform float3 BackgroundColor < ui_type = "color"; ui_label = "Background Color"; ui_tooltip = "Base color for the background of the effect."; ui_category = "Color"; > = BACKGROUND_COLOR_DEFAULT;

// --- Audio Reactivity ---
AS_AUDIO_UI(BlueCorona_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(BlueCorona_AudioMultiplier, "Audio Intensity", AUDIO_MULTIPLIER_DEFAULT, AUDIO_MULTIPLIER_MAX, "Audio Reactivity")
uniform int BlueCorona_AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter"; ui_items = "None\0Animation Speed\0Pattern Scale\0Flow Multiplier\0Red Weight\0Green Weight\0Blue Weight\0Background Brightness\0Iteration Count (Inverse)\0"; ui_category = "Audio Reactivity"; > = AUDIO_TARGET_DEFAULT;

// --- Animation ---
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")

// --- Stage/Position ---
AS_POSITION_SCALE_UI(Position, Scale)
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation)

// --- Final Mix ---
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

// --- Debug ---
AS_DEBUG_UI("Off\0Show Audio Reactivity\0")

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 BlueCoronaPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD) : SV_TARGET {
    // Get original pixel color and depth
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);
    
    // Apply depth test
    if (depth < EffectDepth) {
        return originalColor;
    }
      // Apply audio reactivity to selected parameters
    float animSpeed = AnimationSpeed/4.0; // Normalize speed for better control
    float patternScl = PatternScale;
    float flowMult = FlowMultiplier;
    float redWt = RedWeight;
    float greenWt = GreenWeight;
    float blueWt = BlueWeight;
    float3 bgColor = BackgroundColor;
    int iterCount = IterationCount;
    
    float audioReactivity = AS_applyAudioReactivity(1.0, BlueCorona_AudioSource, BlueCorona_AudioMultiplier, true);
    
    // Map audio target combo index to parameter adjustment
    if (BlueCorona_AudioTarget == 1) animSpeed *= audioReactivity;
    else if (BlueCorona_AudioTarget == 2) patternScl *= audioReactivity;
    else if (BlueCorona_AudioTarget == 3) flowMult *= audioReactivity;
    else if (BlueCorona_AudioTarget == 4) redWt *= audioReactivity;
    else if (BlueCorona_AudioTarget == 5) greenWt *= audioReactivity;
    else if (BlueCorona_AudioTarget == 6) blueWt *= audioReactivity;
    else if (BlueCorona_AudioTarget == 7) bgColor *= audioReactivity; // Adjust background brightness with audio
    else if (BlueCorona_AudioTarget == 8) {
        // Inverse effect for iteration count - higher audio means lower iteration count
        // Ensure it never goes below the minimum value
        float inverseAudioEffect = 2.0 - audioReactivity; // Transform from [1,2] to [1,0]
        inverseAudioEffect = max(inverseAudioEffect, 0.33); // Limit the reduction to avoid going too low
        iterCount = max(ITERATION_COUNT_MIN, int(iterCount * inverseAudioEffect));
    }

    // Calculate animation time with the standardized helper function
    float time = AS_getAnimationTime(animSpeed, AnimationKeyframe);
      // Get rotation in radians from snap and fine controls
    float rotationRadians = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
    
    // --- POSITION HANDLING ---
    // Step 1: Center and correct for aspect ratio
    float2 p_centered = (texcoord - AS_HALF) * 2.0;          // Center coordinates (-1 to 1)
    p_centered.x *= ReShade::AspectRatio;                // Correct for aspect ratio
    
    // Step 2: Apply rotation around center (negative rotation for clockwise)
    float sinRot, cosRot;
    sincos(-rotationRadians, sinRot, cosRot);
    float2 p_rotated = float2(
        p_centered.x * cosRot - p_centered.y * sinRot,
        p_centered.x * sinRot + p_centered.y * cosRot
    );
      
    // Step 3: Apply position and scale
    float2 coordsAdjusted = p_rotated / Scale - Position;
    
    // Generate normalized coordinates for the algorithm
    // Important: We need to preserve aspect ratio correction here
    float2 aspectCorrectedCoords = coordsAdjusted;
    aspectCorrectedCoords.y *= ReShade::AspectRatio / BUFFER_WIDTH * BUFFER_HEIGHT;
    
    // Scale to screen space but maintain aspect ratio
    float2 f_loop_var = float2(1.0, 1.0);  // Use normalized coordinates instead of screen resolution
    float2 u_loop = aspectCorrectedCoords + AS_HALF; // Shift from [-0.5,0.5] to [0,1] range
    
    // Initialize the output vector and working variables
    float4 o;    // Initial transformation and initialization - using normalized coordinates
    u_loop = patternScl * (2.0 * u_loop - f_loop_var) / 1.0; // Divide by 1.0 instead of screen height
    float initial_o_scalar = length(u_loop) - PatternOffset;
    o = float4(initial_o_scalar, initial_o_scalar, initial_o_scalar, initial_o_scalar);
      // Animation time scaled for pattern movement
    float t = 0.1 * time * flowMult;

    // Iterative computation of the pattern
    for (int i = 1; i <= iterCount; i++)
    {
        // Calculate rotation matrix
        float angle_common_part = t * cos(i) + i;
        float4 angle_components = angle_common_part + float4(0.0, ROTATION_ANGLE_OFFSET_1, ROTATION_ANGLE_OFFSET_2, 0.0);
        float4 cos_of_angles = cos(angle_components);
        float2x2 rot_matrix = float2x2(cos_of_angles.x, cos_of_angles.z, cos_of_angles.y, cos_of_angles.w);
        
        // Apply rotation to coordinates
        u_loop = mul(rot_matrix, u_loop);
        
        // Update pattern variables with normalized approach
        float2 cos_f_prev = cos(f_loop_var);
        f_loop_var = cos(u_loop.yx - cos_f_prev);
        u_loop += (0.5 * f_loop_var) + t;
          // Update output vector
        float o_update_scalar_term = 0.5 * abs(f_loop_var.x + f_loop_var.y) * o.x;
        o += o_update_scalar_term;
    }
    
    // Apply final color transformation with user-defined weights
    // Fix for inverted color weight behavior - higher values should produce stronger colors now
    float4 o_squared = o * o;
    
    // Invert weights to fix the inverted behavior
    // We're using 1/weight to make higher weight values increase color intensity
    float4 term_multiplier = float4(1.0/redWt, 1.0/greenWt, 1.0/blueWt, 0.0);
    float4 term_vector = COLOR_FACTOR * o_squared * term_multiplier;
    
    float4 exp_of_term = exp(term_vector);    float4 div_term = CORONA_FINAL_OFFSET / exp_of_term;
    o = exp(div_term - CORONA_FINAL_OFFSET);
    
    // Create the effect color by combining the pattern with the background color
    float3 patternColor = o.rgb;
    float3 effectColorRGB = lerp(bgColor, patternColor, patternColor);
    float4 effectColor = float4(effectColorRGB, 1.0);
    
    // --- Final Blending & Debug ---
    float4 finalColor = float4(AS_applyBlend(effectColor.rgb,originalColor.rgb, BlendMode), 1.0);
    finalColor = lerp(originalColor, finalColor, BlendStrength);
    
    // Show debug overlay if enabled
    if (DebugMode != AS_DEBUG_OFF) {
        float4 debugMask = float4(0, 0, 0, 0);
        if (DebugMode == 1) { // Show Audio Reactivity
             debugMask = float4(audioReactivity, audioReactivity, audioReactivity, 1.0);
        }
        
        float2 debugCenter = float2(0.1, 0.1); // Example position
        float debugRadius = 0.08;
        if (length(texcoord - debugCenter) < debugRadius) {
            return debugMask;
        }
    }
    
    return finalColor;
}

} // namespace ASBlueCorona

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_BlueCorona < ui_label="[AS] BGX: Blue Corona"; ui_tooltip="Creates a dynamic blue corona effect with fluid animation and organic patterns."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = ASBlueCorona::BlueCoronaPS;
    }
}

#endif // __AS_BGX_BlueCorona_1_fx















