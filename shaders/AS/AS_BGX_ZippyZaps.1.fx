/**
 * AS_BGX_ZippyZaps.1.fx - Dynamic electricity/lightning-like background effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Based on "Zippy Zaps" by SnoopethDuckDuck
 * Shadertoy: https://www.shadertoy.com/view/XXyGzh
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates dynamic electric arcs and lightning patterns for a striking background effect.
 * This effect generates procedural electric-like patterns that appear behind objects in the scene,
 * creating an energetic, dynamic background with complete control over appearance and animation.
 * 
 * FEATURES:
 * - Animated electric/lightning arcs with procedural generation
 * - Fully customizable colors, intensity, and animation parameters
 * - Resolution-independent rendering maintains consistent look across all displays
 * - Audio reactivity support for dynamic response to music
 * - Depth-aware rendering can be placed behind scene objects
 * - Adjustable rotation and positioning in 3D space
 * 
 * IMPLEMENTATION OVERVIEW:
 * 1. Uses iterative mathematical functions to generate dynamic lightning patterns
 * 2. Applies coordinate transformations to ensure resolution independence
 * 3. Creates electric arcs through trigonometric distortions and iterations * 4. Applies depth testing to integrate with the 3D scene
 * 5. Processes audio input for dynamic response to music
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_ZippyZaps_1_fx
#define __AS_BGX_ZippyZaps_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh" // Color palette support

namespace ASZippyZaps {
// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================

// --- Tunable Constants ---
// Appearance
static const float U_COORD_SCALING_MIN = 0.01;
static const float U_COORD_SCALING_MAX = 20.0;
static const float U_COORD_SCALING_STEP = 0.01;
static const float U_COORD_SCALING_DEFAULT = 1.96;

static const float LOOP_A_INCREMENT_MIN = 0.001;
static const float LOOP_A_INCREMENT_MAX = 0.1;
static const float LOOP_A_INCREMENT_STEP = 0.001;
static const float LOOP_A_INCREMENT_DEFAULT = 0.03;

static const float SIN_ARG_DENOM_OFFSET_MIN = 0.1;
static const float SIN_ARG_DENOM_OFFSET_MAX = 2.0;
static const float SIN_ARG_DENOM_OFFSET_STEP = 0.05;
static const float SIN_ARG_DENOM_OFFSET_DEFAULT = 0.50;

static const float SIN_ARG_U_SCALE_MIN = 0.1;
static const float SIN_ARG_U_SCALE_MAX = 5.0;
static const float SIN_ARG_U_SCALE_STEP = 0.1;
static const float SIN_ARG_U_SCALE_DEFAULT = 1.5;

static const float SIN_ARG_SWIZZLE_FACTOR_MIN = 1.0;
static const float SIN_ARG_SWIZZLE_FACTOR_MAX = 20.0;
static const float SIN_ARG_SWIZZLE_FACTOR_STEP = 0.5;
static const float SIN_ARG_SWIZZLE_FACTOR_DEFAULT = 9.0;

// Animation
static const float ANIMATION_SPEED_MIN = 0.0;
static const float ANIMATION_SPEED_MAX = 5.0;
static const float ANIMATION_SPEED_STEP = 0.01;
static const float ANIMATION_SPEED_DEFAULT = 1.0;

static const float ANIMATION_KEYFRAME_MIN = 0.0;
static const float ANIMATION_KEYFRAME_MAX = 100.0;
static const float ANIMATION_KEYFRAME_STEP = 0.1;
static const float ANIMATION_KEYFRAME_DEFAULT = 0.0;

static const float TANH_ARG_FACTOR_MIN = 5.0;
static const float TANH_ARG_FACTOR_MAX = 100.0;
static const float TANH_ARG_FACTOR_STEP = 1.0;
static const float TANH_ARG_FACTOR_DEFAULT = 40.0;

static const float TANH_DIVISOR_MIN = 50.0;
static const float TANH_DIVISOR_MAX = 500.0;
static const float TANH_DIVISOR_STEP = 10.0;
static const float TANH_DIVISOR_DEFAULT = 200.0;

static const float U_UPDATE_A_MIX_FACTOR_MIN = 0.01;
static const float U_UPDATE_A_MIX_FACTOR_MAX = 1.0;
static const float U_UPDATE_A_MIX_FACTOR_STEP = 0.01;
static const float U_UPDATE_A_MIX_FACTOR_DEFAULT = 0.80;

// Audio
static const int AUDIO_TARGET_DEFAULT = 1;
static const float AUDIO_MULTIPLIER_DEFAULT = 1.0;
static const float AUDIO_MULTIPLIER_MAX = 2.0;

// Final Mix
static const float FINAL_O_MIN_CLAMP_MIN = 1.0;
static const float FINAL_O_MIN_CLAMP_MAX = 50.0; 
static const float FINAL_O_MIN_CLAMP_STEP = 0.5;
static const float FINAL_O_MIN_CLAMP_DEFAULT = 3.5;

static const float FINAL_O_DIV_NUMERATOR_MIN = 50.0;
static const float FINAL_O_DIV_NUMERATOR_MAX = 300.0;
static const float FINAL_O_DIV_NUMERATOR_STEP = 1.0;
static const float FINAL_O_DIV_NUMERATOR_DEFAULT = 54.0;

static const float FINAL_O_MAIN_DIV_NUMERATOR_MIN = 5.0;
static const float FINAL_O_MAIN_DIV_NUMERATOR_MAX = 100.0;
static const float FINAL_O_MAIN_DIV_NUMERATOR_STEP = 0.5;
static const float FINAL_O_MAIN_DIV_NUMERATOR_DEFAULT = 28.0;

static const float FINAL_O_U_DOT_DIVISOR_MIN = 50.0;
static const float FINAL_O_U_DOT_DIVISOR_MAX = 500.0;
static const float FINAL_O_U_DOT_DIVISOR_STEP = 10.0;
static const float FINAL_O_U_DOT_DIVISOR_DEFAULT = 250.0;

// --- Stage ---




uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nBased on 'Zippy Zaps' by SnoopethDuckDuck\nLink: https://www.shadertoy.com/view/XXyGzh\nLicence: CC Share-Alike Non-Commercial\n\n";>;

AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation)
AS_POSITION_SCALE_UI(Position, Scale)

// --- Appearance ---







uniform float U_CoordScalingFactor < ui_type = "slider"; ui_label = "Scaling Factor"; ui_tooltip = "Controls the initial zoom/scale of the effect. Smaller values zoom in (effect appears larger)."; ui_min = U_COORD_SCALING_MIN; ui_max = U_COORD_SCALING_MAX; ui_step = U_COORD_SCALING_STEP; ui_category = "Appearance"; > = U_COORD_SCALING_DEFAULT;
uniform float Loop_A_Increment < ui_type = "slider"; ui_label = "Arc Growth Rate"; ui_tooltip = "Controls the rate of growth for lightning arcs in the effect."; ui_min = LOOP_A_INCREMENT_MIN; ui_max = LOOP_A_INCREMENT_MAX; ui_step = LOOP_A_INCREMENT_STEP; ui_category = "Appearance"; > = LOOP_A_INCREMENT_DEFAULT;
uniform float SinArg_Denom_Offset < ui_type = "slider"; ui_label = "Arc Pattern Density"; ui_tooltip = "Controls the density and pattern of the lightning arcs."; ui_min = SIN_ARG_DENOM_OFFSET_MIN; ui_max = SIN_ARG_DENOM_OFFSET_MAX; ui_step = SIN_ARG_DENOM_OFFSET_STEP; ui_category = "Appearance"; > = SIN_ARG_DENOM_OFFSET_DEFAULT;
uniform float SinArg_U_Scale < ui_type = "slider"; ui_label = "Arc Spread"; ui_tooltip = "Controls how the arcs are distributed across the effect area."; ui_min = SIN_ARG_U_SCALE_MIN; ui_max = SIN_ARG_U_SCALE_MAX; ui_step = SIN_ARG_U_SCALE_STEP; ui_category = "Appearance"; > = SIN_ARG_U_SCALE_DEFAULT;
uniform float SinArg_Swizzle_Factor < ui_type = "slider"; ui_label = "Arc Twisting"; ui_tooltip = "Controls how much the arcs twist and turn."; ui_min = SIN_ARG_SWIZZLE_FACTOR_MIN; ui_max = SIN_ARG_SWIZZLE_FACTOR_MAX; ui_step = SIN_ARG_SWIZZLE_FACTOR_STEP; ui_category = "Appearance"; > = SIN_ARG_SWIZZLE_FACTOR_DEFAULT;

// --- Animation ---
uniform float AnimationKeyframe < ui_type = "slider"; ui_label = "Animation Keyframe"; ui_tooltip = "Sets a specific point in time for the animation. Useful for finding and saving specific patterns."; ui_min = ANIMATION_KEYFRAME_MIN; ui_max = ANIMATION_KEYFRAME_MAX; ui_step = ANIMATION_KEYFRAME_STEP; ui_category = "Animation"; > = ANIMATION_KEYFRAME_DEFAULT;
uniform float AnimationSpeed < ui_type = "slider"; ui_label = "Animation Speed"; ui_tooltip = "Controls the overall animation speed of the effect. Set to 0 to pause animation and use keyframe only."; ui_min = ANIMATION_SPEED_MIN; ui_max = ANIMATION_SPEED_MAX; ui_step = ANIMATION_SPEED_STEP; ui_category = "Animation"; > = ANIMATION_SPEED_DEFAULT;
uniform float Tanh_Arg_Factor < ui_type = "slider"; ui_label = "Arc Sharpness"; ui_tooltip = "Controls the sharpness and definition of individual arcs."; ui_min = TANH_ARG_FACTOR_MIN; ui_max = TANH_ARG_FACTOR_MAX; ui_step = TANH_ARG_FACTOR_STEP; ui_category = "Animation"; > = TANH_ARG_FACTOR_DEFAULT;
uniform float Tanh_Divisor < ui_type = "slider"; ui_label = "Arc Smoothness"; ui_tooltip = "Controls the smoothness of arc transitions."; ui_min = TANH_DIVISOR_MIN; ui_max = TANH_DIVISOR_MAX; ui_step = TANH_DIVISOR_STEP; ui_category = "Animation"; > = TANH_DIVISOR_DEFAULT;
uniform float U_Update_A_Mix_Factor < ui_type = "slider"; ui_label = "Arc Flow Factor"; ui_tooltip = "Controls how the arcs flow and connect with each other. Higher values create more chaotic flow patterns."; ui_min = U_UPDATE_A_MIX_FACTOR_MIN; ui_max = U_UPDATE_A_MIX_FACTOR_MAX; ui_step = U_UPDATE_A_MIX_FACTOR_STEP; ui_category = "Animation"; > = U_UPDATE_A_MIX_FACTOR_DEFAULT;

// --- Audio Reactivity ---
AS_AUDIO_UI(Zippy_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(Zippy_AudioMultiplier, "Audio Intensity", AUDIO_MULTIPLIER_DEFAULT, AUDIO_MULTIPLIER_MAX, "Audio Reactivity")
uniform int Zippy_AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter"; ui_items = "None\0Arc Growth Rate\0Arc Flow Factor\0Main Color Numerator\0"; ui_category = "Audio Reactivity"; > = AUDIO_TARGET_DEFAULT;

// --- Palette & Style ---
uniform float FinalO_MinClamp < ui_type = "slider"; ui_label = "Color Intensity Clamp"; ui_tooltip = "Maximum intensity cap for color calculation."; ui_min = FINAL_O_MIN_CLAMP_MIN; ui_max = FINAL_O_MIN_CLAMP_MAX; ui_step = FINAL_O_MIN_CLAMP_STEP; ui_category = "Palette & Style"; > = FINAL_O_MIN_CLAMP_DEFAULT;
uniform float FinalO_DivNumerator < ui_type = "slider"; ui_label = "Color Division Factor"; ui_tooltip = "Division factor for internal color calculation."; ui_min = FINAL_O_DIV_NUMERATOR_MIN; ui_max = FINAL_O_DIV_NUMERATOR_MAX; ui_step = FINAL_O_DIV_NUMERATOR_STEP; ui_category = "Palette & Style"; > = FINAL_O_DIV_NUMERATOR_DEFAULT;
uniform float FinalO_MainDivNumerator < ui_type = "slider"; ui_label = "Main Color Numerator"; ui_tooltip = "Main factor for color intensity calculation."; ui_min = FINAL_O_MAIN_DIV_NUMERATOR_MIN; ui_max = FINAL_O_MAIN_DIV_NUMERATOR_MAX; ui_step = FINAL_O_MAIN_DIV_NUMERATOR_STEP; ui_category = "Palette & Style"; > = FINAL_O_MAIN_DIV_NUMERATOR_DEFAULT;
uniform float FinalO_UDotDivisor < ui_type = "slider"; ui_label = "Falloff Divisor"; ui_tooltip = "Controls the color intensity falloff from center."; ui_min = FINAL_O_U_DOT_DIVISOR_MIN; ui_max = FINAL_O_U_DOT_DIVISOR_MAX; ui_step = FINAL_O_U_DOT_DIVISOR_STEP; ui_category = "Palette & Style"; > = FINAL_O_U_DOT_DIVISOR_DEFAULT;
uniform bool UseOriginalColors < ui_label = "Use Original Colors"; ui_tooltip = "When enabled, uses the original mathematical color calculation instead of palette-based colors"; ui_category = "Palette & Style"; > = true;
uniform float OriginalColorIntensity < ui_type = "slider"; ui_label = "Original Color Intensity"; ui_tooltip = "Adjusts the intensity of original colors when 'Use Original Colors' is enabled"; ui_min = 0.5; ui_max = 2.0; ui_step = 0.01; ui_category = "Palette & Style"; ui_spacing = 0; > = 1.00;
uniform float OriginalColorSaturation < ui_type = "slider"; ui_label = "Original Color Saturation"; ui_tooltip = "Adjusts the saturation of original colors"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Palette & Style"; > = 1.00;
AS_PALETTE_SELECTION_UI(PalettePreset, "Color Palette", AS_PALETTE_NEON, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(ZippyZaps_, "Palette & Style")
uniform float ColorCycleSpeed < ui_type = "slider"; ui_label = "Color Cycle Speed"; ui_tooltip = "Controls how fast colors cycle. 0 = static"; ui_min = -5.0; ui_max = 5.0; ui_step = 0.1; ui_category = "Palette & Style"; > = 0.0;

// --- Final Mix ---
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

// --- Debug ---
AS_DEBUG_UI("Off\0Show Audio Reactivity\0")

// --- Internal Constants ---
static const float EPSILON = 1e-6f;                // Small value to prevent division by zero
static const float HALF_POINT = 0.5f;              // Half point for coordinate centering
static const float INITIAL_A_LOOP = 0.5f;          // Initial value for a_loop
static const float LOOP_T_INCREMENT = 1.0f;        // Time increment per loop iteration
static const float MAX_LOOP_ITERATIONS = 19.0f;    // Maximum number of iterations
static const float MAX_ITERATIONS_FLOAT = 19.0f;   // Maximum iterations as float value
static const float ROTATION_MATRIX_FACTOR1 = 0.02f;// Factor for rotation matrix calculation
static const float ROTATION_MATRIX_ANGLE1 = 0.0f;  // Angle offset for rotation matrix
static const float ROTATION_MATRIX_ANGLE2 = 11.0f; // Angle offset for rotation matrix
static const float ROTATION_MATRIX_ANGLE3 = 33.0f; // Angle offset for rotation matrix
static const float V_LOOP_FACTOR = 7.0f;           // Factor for v_loop calculation
static const float V_LOOP_OFFSET = 5.0f;           // Offset for v_loop calculation
static const float EXP_ARG_DIVISOR = 1e2f;         // Divisor for exponential argument
static const float COS_ARG_FOR_TANH_FACTOR = 1e2f; // Factor for cosine argument in tanh calculation
static const float COS_TERM_EXP_NUMERATOR = 4.0f;  // Numerator for cosine term
static const float COS_TERM_DIVISOR = 3e2f;        // Divisor for cosine term
static const float INITIAL_COLOR_R = 1.0f;         // Initial color - red component
static const float INITIAL_COLOR_G = 2.0f;         // Initial color - green component
static const float INITIAL_COLOR_B = 3.0f;         // Initial color - blue component
static const float INITIAL_COLOR_A = 0.0f;         // Initial color - alpha component
static const float SIGN_BIAS = 1e-7f;              // Small bias for sign determination

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Get color from the currently selected palette
float3 getZippyZapsColor(float t, float time) {
    if (ColorCycleSpeed != 0.0) {
        float cycleRate = ColorCycleSpeed * 0.1;
        t = frac(t + cycleRate * time);
    }
    t = saturate(t); // Ensure t is within valid range [0, 1]
    
    if (PalettePreset == AS_PALETTE_CUSTOM) { // Use custom palette
        return AS_GET_INTERPOLATED_CUSTOM_COLOR(ZippyZaps_, t);
    }
    return AS_getInterpolatedColor(PalettePreset, t); // Use preset palette
}

// Main Pixel Shader function
float4 ShaderToyPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET {
    // Get original pixel color
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);

    // Apply depth test
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth) {
        return originalColor;
    }

    // Apply audio reactivity to selected parameters
    float animSpeed = AnimationSpeed;
    float tanhArgFactor = Tanh_Arg_Factor;
    float loopAIncrement = Loop_A_Increment;
    float finalOMainDivNumerator = FinalO_MainDivNumerator;
    float flowFactor = U_Update_A_Mix_Factor;
    
    float audioReactivity = AS_applyAudioReactivity(1.0, Zippy_AudioSource, Zippy_AudioMultiplier, true);
    
    if (Zippy_AudioTarget == 1) {
        loopAIncrement *= audioReactivity;
    } else if (Zippy_AudioTarget == 2) {
        // For Arc Flow Factor, we want to increase the actual effect when audio intensity increases
        // Store the original value for later inversion
        flowFactor *= audioReactivity;
    } else if (Zippy_AudioTarget == 3) {
        finalOMainDivNumerator *= audioReactivity;
    }

    float2 iResolution = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float aspectRatio = iResolution.x / iResolution.y;
    
    // Setup time with keyframe handling
    float iTime;
    if (animSpeed <= 0.0001f) {
        // When animation speed is effectively zero, use keyframe directly
        iTime = AnimationKeyframe;
    } else {
        // Otherwise use animated time plus keyframe offset
        iTime = (AS_getTime() * animSpeed) + AnimationKeyframe;
    }

    // Transform to resolution-independent centered coordinates
    float2 centeredCoord;
    if (aspectRatio >= 1.0) {
        centeredCoord.x = (texcoord.x - HALF_POINT) * aspectRatio;
        centeredCoord.y = texcoord.y - HALF_POINT;
    } else {
        centeredCoord.x = texcoord.x - HALF_POINT;
        centeredCoord.y = (texcoord.y - HALF_POINT) / aspectRatio;
    }

    // Apply rotation from standard UI controls
    float rotationRadians = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
    float s = sin(rotationRadians);
    float c = cos(rotationRadians);
    float2 rotatedCoord = float2(
        centeredCoord.x * c - centeredCoord.y * s,
        centeredCoord.x * s + centeredCoord.y * c
    );

    // Initialize vectors for the effect calculation
    float2 u = rotatedCoord / U_CoordScalingFactor;

    float4 o = float4(INITIAL_COLOR_R, INITIAL_COLOR_G, INITIAL_COLOR_B, INITIAL_COLOR_A);
    float4 z = o;

    float a_loop = INITIAL_A_LOOP;
    float t_loop = iTime;
    float2 v_loop_state = float2(1.0, 1.0); // Initialize to unit vector instead of resolution

    float i_loop = 0.0f;
    for (; ++i_loop < MAX_LOOP_ITERATIONS; ) {
        // --- Body of the loop: o accumulation ---
        float S1_len_arg = (1.0f + i_loop * dot(v_loop_state, v_loop_state)); 

        float sin_arg_denom_val = (SinArg_Denom_Offset - dot(u, u)); 
        if (abs(sin_arg_denom_val) < EPSILON) sin_arg_denom_val = sign(sin_arg_denom_val + SIGN_BIAS) * EPSILON; 

        float2 sin_arg_vec = (SinArg_U_Scale * u / sin_arg_denom_val) - (SinArg_Swizzle_Factor * u.yx) + float2(t_loop, t_loop); 
        float2 sin_result_vec = sin(sin_arg_vec); 

        float2 vec_for_length = S1_len_arg * sin_result_vec; 
        
        float denominator = length(vec_for_length); 
        if (denominator < EPSILON) denominator = EPSILON; 

        float4 const_1_vec = float4(1.0f, 1.0f, 1.0f, 1.0f);
        float4 t_loop_vec4 = float4(t_loop, t_loop, t_loop, t_loop);
        float4 numerator_o_add = const_1_vec + cos(z + t_loop_vec4);
        o += numerator_o_add / denominator; 

        // --- Update expressions for the next iteration ---
        t_loop += LOOP_T_INCREMENT; 
        a_loop += loopAIncrement; 

        v_loop_state = cos(float2(t_loop, t_loop) - V_LOOP_FACTOR * u * pow(a_loop, i_loop)) - V_LOOP_OFFSET * u;

        float2 u_before_mat_mult = u; 

        float cos_arg_base = i_loop + ROTATION_MATRIX_FACTOR1 * t_loop; 
        float C0 = cos(cos_arg_base - ROTATION_MATRIX_ANGLE1);
        float C1 = cos(cos_arg_base - ROTATION_MATRIX_ANGLE2);
        float C2 = cos(cos_arg_base - ROTATION_MATRIX_ANGLE3);
        float C3 = cos(cos_arg_base - ROTATION_MATRIX_ANGLE1); 

        float2x2 rotMat = float2x2(C0, C2, C1, C3); 
        float2 u_after_mat_mult = mul(rotMat, u_before_mat_mult);

        float dot_u_u_scalar = dot(u_after_mat_mult, u_after_mat_mult); 

        float2 cos_arg_for_tanh = COS_ARG_FOR_TANH_FACTOR * u_after_mat_mult.yx + float2(t_loop, t_loop);
        float2 cos_res_for_tanh = cos(cos_arg_for_tanh); 

        float2 val_for_tanh_vec = tanhArgFactor * dot_u_u_scalar * cos_res_for_tanh; 
        
        float2 tanh_term_vec = stanh(val_for_tanh_vec) / Tanh_Divisor; 

        // Invert the Arc Flow Factor behavior - higher values now create more chaotic patterns
        // by inverting the mix factor scaling (1.0 - factor)
        float invertedMixFactor = U_UPDATE_A_MIX_FACTOR_MAX - flowFactor + U_UPDATE_A_MIX_FACTOR_MIN;
        float2 term2_vec_u_update = invertedMixFactor * a_loop * u_after_mat_mult; 
        
        float exp_arg = dot(o, o) / EXP_ARG_DIVISOR;
        
        float cos_term_scalar_u_update = cos(COS_TERM_EXP_NUMERATOR / exp(exp_arg) + t_loop) / COS_TERM_DIVISOR;

        u = u_after_mat_mult +
            tanh_term_vec + 
            term2_vec_u_update +
            float2(cos_term_scalar_u_update, cos_term_scalar_u_update); 
    }

    // --- Final o calculation ---
    float4 o_min_13 = min(o, FinalO_MinClamp);
    float4 o_safe_for_div = o;
    o_safe_for_div.x = (abs(o.x) < EPSILON) ? ((o.x >= 0.0f ? 1.0f : -1.0f) * EPSILON) : o.x;
    o_safe_for_div.y = (abs(o.y) < EPSILON) ? ((o.y >= 0.0f ? 1.0f : -1.0f) * EPSILON) : o.y;
    o_safe_for_div.z = (abs(o.z) < EPSILON) ? ((o.z >= 0.0f ? 1.0f : -1.0f) * EPSILON) : o.z;
    o_safe_for_div.w = (abs(o.w) < EPSILON) ? ((o.w >= 0.0f ? 1.0f : -1.0f) * EPSILON) : o.w;

    float4 o_div_term = FinalO_DivNumerator / o_safe_for_div;
    
    float4 final_denom = o_min_13 + o_div_term;
    final_denom.x = (abs(final_denom.x) < EPSILON) ? ((final_denom.x >= 0.0f ? 1.0f : -1.0f) * EPSILON) : final_denom.x;
    final_denom.y = (abs(final_denom.y) < EPSILON) ? ((final_denom.y >= 0.0f ? 1.0f : -1.0f) * EPSILON) : final_denom.y;
    final_denom.z = (abs(final_denom.z) < EPSILON) ? ((final_denom.z >= 0.0f ? 1.0f : -1.0f) * EPSILON) : final_denom.z;
    final_denom.w = (abs(final_denom.w) < EPSILON) ? ((final_denom.w >= 0.0f ? 1.0f : -1.0f) * EPSILON) : final_denom.w;

    float4 const_main_div_num_vec = float4(finalOMainDivNumerator, finalOMainDivNumerator, finalOMainDivNumerator, finalOMainDivNumerator);
    float dot_u_term_scalar = dot(u, u) / FinalO_UDotDivisor; 
    float4 dot_u_term_vec = float4(dot_u_term_scalar, dot_u_term_scalar, dot_u_term_scalar, dot_u_term_scalar);

    // Generate raw color value
    o = (const_main_div_num_vec / final_denom) - dot_u_term_vec;
    
    // Calculate color intensity based on calculation value
    float colorIntensity = (length(o.rgb) / 3.0);
    
    float3 finalRGB;
    if (UseOriginalColors) {
        // Use the original mathematical color calculation
        // Normalize and adjust the raw output to make visually appealing colors
        
        // Normalize o to get nice colors with balanced RGB values
        float3 normalizedO = normalize(o.rgb);
        
        // Apply intensity scaling to make colors visually interesting
        // The original calculation tends to produce colors with intensity patterns
        // but we need to adjust them to look appealing
        float3 originalRGB = normalizedO * colorIntensity;
        
        // Apply user-controlled intensity
        originalRGB = originalRGB * OriginalColorIntensity;
        
        // Apply saturation adjustment (lerp toward gray at lower saturation)
        float3 grayColor = dot(originalRGB, float3(0.299, 0.587, 0.114));
        finalRGB = lerp(grayColor, originalRGB, OriginalColorSaturation);
    } else {
        // Map color using palette
        float3 paletteColor = getZippyZapsColor(colorIntensity, iTime);
        
        // Apply intensity from calculation to palette color
        finalRGB = paletteColor * (colorIntensity * 0.8 + 0.2);
    }
    
    o = float4(finalRGB, 1.0f);

    // Blend with original color using standard blend mode function
    float3 blendedColor = AS_applyBlend(finalRGB, originalColor.rgb, BlendMode);
    float4 finalColor = float4(lerp(originalColor.rgb, blendedColor, BlendStrength), originalColor.a);
    
    // Show debug overlay if enabled
    if (DebugMode != AS_DEBUG_OFF) {
        float4 debugMask = float4(0, 0, 0, 0);
        
        // Audio reactivity visualization
        if (DebugMode == 1) {
            debugMask = float4(audioReactivity, audioReactivity, audioReactivity, 1.0);
        }
        
        // Create a debug overlay region in the top-left
        float2 debugCenter = float2(0.1, 0.1);
        float debugRadius = 0.08;
        float dist = length(texcoord - debugCenter);
        
        if (dist < debugRadius) {
            return debugMask;
        }
    }
    
    return finalColor;
}
} // namespace ASZippyZaps

// ReShade FX Technique
technique AS_BGX_ZippyZaps <ui_label="[AS] BGX: ZippyZaps"; ui_tooltip="Creates dynamic electric arcs and lightning patterns for a striking background effect.";>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = ASZippyZaps::ShaderToyPS;
    }
}

#endif // __AS_BGX_ZippyZaps_1_fx
















