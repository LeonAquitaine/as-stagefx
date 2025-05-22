/**
 * AS_BGX_Wisps.1.fx - 3D Procedural Ethereal Wisps Background
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a 3D ethereal atmosphere with flowing wisps of light moving through a colored
 * background, using raymarching and procedural distance functions to create the effect.
 *
 * FEATURES:
 * - Fully 3D procedural wisps using raymarch techniques
 * - Customizable camera and perspective controls
 * - Adjustable pattern detail and complexity
 * - Comprehensive shape controls for turbulence and reflection
 * - Tonemapping and appearance settings for fine-tuning
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Uses raymarching to traverse a 3D procedural space
 * 2. Calculates distance fields and step sizes for each raymarch step
 * 3. Accumulates wisp density/intensity along the ray path
 * 4. Applies tonemapping and converts to visible form
 * 5. Blends with background gradient using position-based colors
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_Wisps_1_fx
#define __AS_BGX_Wisps_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_getTime() and AS_EPSILON

namespace ASWisps {
// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================

// --- Animation Constants ---
static const float ANIMATION_SPEED_MIN = 0.0;
static const float ANIMATION_SPEED_MAX = 10.0;
static const float ANIMATION_SPEED_DEFAULT = 1.0;
static const float ANIMATION_KEYFRAME_MIN = 0.0;
static const float ANIMATION_KEYFRAME_MAX = 100.0;
static const float ANIMATION_KEYFRAME_DEFAULT = 0.0;

// --- Raymarching Quality Constants ---
static const int RAYMARCH_STEPS_MIN = 30;
static const int RAYMARCH_STEPS_MAX = 200;
static const int RAYMARCH_STEPS_DEFAULT = 100;

static const float FAR_CLIP_MIN = 5.0;
static const float FAR_CLIP_MAX = 100.0;
static const float FAR_CLIP_DEFAULT = 20.0;

// --- Camera Constants ---
static const float FOV_FACTOR_MIN = 0.1;
static const float FOV_FACTOR_MAX = 3.0;
static const float FOV_FACTOR_DEFAULT = 1.0;

// --- Ray Origin Constants ---
static const float RAY_ORIGIN_MIN = -2.0;
static const float RAY_ORIGIN_MAX = 2.0;
static const float RAY_ORIGIN_DEFAULT = 0.5;

// --- Wisp Shape Constants ---
static const float PATTERN_DETAIL_MIN = 0.1;
static const float PATTERN_DETAIL_MAX = 20.0;
static const float PATTERN_DETAIL_DEFAULT = 5.0;

static const float REFLECTION_DAMPENING_MIN = 0.01;
static const float REFLECTION_DAMPENING_MAX = 2.0;
static const float REFLECTION_DAMPENING_DEFAULT = 0.5;

static const float STEP_SIZE_DIVISOR_MIN = 10.0;
static const float STEP_SIZE_DIVISOR_MAX = 500.0;
static const float STEP_SIZE_DIVISOR_DEFAULT = 100.0;

static const int TURBULENCE_ITERATIONS_MIN = 0;
static const int TURBULENCE_ITERATIONS_MAX = 8;
static const int TURBULENCE_ITERATIONS_DEFAULT = 5;

static const float TURBULENCE_DEPTH_INFLUENCE_MIN = 0.0;
static const float TURBULENCE_DEPTH_INFLUENCE_MAX = 1.0;
static const float TURBULENCE_DEPTH_INFLUENCE_DEFAULT = 0.1;

static const float TURBULENCE_STRENGTH_MIN = 0.0;
static const float TURBULENCE_STRENGTH_MAX = 2.0;
static const float TURBULENCE_STRENGTH_DEFAULT = 1.0;

static const float PATTERN_FREQUENCY_MIN = 0.1;
static const float PATTERN_FREQUENCY_MAX = 5.0;
static const float PATTERN_FREQUENCY_DEFAULT = 1.0;

// --- Appearance Constants ---
static const float WISP_INTENSITY_MIN = 0.001;
static const float WISP_INTENSITY_MAX = 1000.0;
static const float WISP_INTENSITY_DEFAULT = 1.0;

static const float TONEMAP_EXPOSURE_MIN = 1.0;
static const float TONEMAP_EXPOSURE_MAX = 10000.0;
static const float TONEMAP_EXPOSURE_DEFAULT = 1000.0;

static const float WISP_BRIGHTNESS_MIN = 0.0;
static const float WISP_BRIGHTNESS_MAX = 5.0;
static const float WISP_BRIGHTNESS_DEFAULT = 1.5;

static const float WISP_MASK_SHARPNESS_MIN = 0.1;
static const float WISP_MASK_SHARPNESS_MAX = 5.0;
static const float WISP_MASK_SHARPNESS_DEFAULT = 1.5;

// --- Background Color Constants ---
static const float BG_INTENSITY_MIN = 0.0;
static const float BG_INTENSITY_MAX = 1.0;
static const float BG_INTENSITY_DEFAULT = 0.4;

static const float BG_ANIM_SPEED_MIN = 0.0;
static const float BG_ANIM_SPEED_MAX = 1.0;
static const float BG_ANIM_SPEED_DEFAULT = 0.1;

static const float BG_SINEW_FREQ_MIN = 0.1;
static const float BG_SINEW_FREQ_MAX = 10.0;
static const float BG_SINEW_FREQ_DEFAULT = 5.0;

// --- Debugging Constants ---
static const int DEBUG_FINAL_OUTPUT = 0;
static const int DEBUG_ACCUMULATED_COLOR = 1;
static const int DEBUG_STEP_COLOR_BASE = 2;
static const int DEBUG_RAYMARCH_STEP = 3;
static const int DEBUG_ACCUMULATED_DEPTH = 4;
static const int DEBUG_REFLECTION_VALUE = 5;
static const int DEBUG_SAMPLE_XY = 6;
static const int DEBUG_SAMPLE_Z = 7;
static const int DEBUG_WISP_MASK = 8;

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Animation Controls ---
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")

// --- Quality Settings ---
uniform int RaymarchSteps < ui_category="Quality";
    ui_type="slider"; ui_min=RAYMARCH_STEPS_MIN; ui_max=RAYMARCH_STEPS_MAX; ui_step=1;
    ui_label="Steps";
    ui_tooltip="Number of steps for raymarching. Higher values for more detail but less performance.";
> = RAYMARCH_STEPS_DEFAULT;

uniform float FarClip < ui_category="Quality";
    ui_type="slider"; ui_min=FAR_CLIP_MIN; ui_max=FAR_CLIP_MAX; ui_step=0.1;
    ui_label="Far Clip";
    ui_tooltip="Maximum distance rays will travel.";
> = FAR_CLIP_DEFAULT;

// --- Position and Scale ---
AS_POSITION_SCALE_UI(Position, Scale)

// --- Stage Depth ---
AS_STAGEDEPTH_UI(StageDepth)

// --- Camera & View ---
uniform float FOVFactor < ui_category="Camera";
    ui_type="slider"; ui_min=FOV_FACTOR_MIN; ui_max=FOV_FACTOR_MAX; ui_step=0.01;
    ui_label="Perspective Factor (FOV)";
    ui_tooltip="Adjusts field of view. Smaller values zoom in (stronger perspective).";
> = FOV_FACTOR_DEFAULT;

uniform float3 RayOriginOffset < ui_category="Camera"; 
    ui_type="slider"; ui_min=RAY_ORIGIN_MIN; ui_max=RAY_ORIGIN_MAX; ui_step=0.01;
    ui_label="Ray Origin Offset";
    ui_tooltip="Offset for the raymarching starting point relative to screen center.";
> = float3(RAY_ORIGIN_DEFAULT, RAY_ORIGIN_DEFAULT, RAY_ORIGIN_DEFAULT);


// --- Wisp Shape & Detail ---
uniform bool EnableYReflection < ui_category="Wisp Shape";
    ui_label="Enable Y-Axis Reflection";
    ui_tooltip="Toggles the Y-axis reflection of the pattern space.";
> = true;

uniform float PatternDetail < ui_category="Wisp Shape";
    ui_type="slider"; ui_min=PATTERN_DETAIL_MIN; ui_max=PATTERN_DETAIL_MAX; ui_step=0.1;
    ui_label="Pattern Detail";
    ui_tooltip="Influences the sin(p.xy) contribution to step distance, affecting wisp complexity.";
> = PATTERN_DETAIL_DEFAULT;

uniform float ReflectionDampening < ui_category="Wisp Shape";
    ui_type="slider"; ui_min=REFLECTION_DAMPENING_MIN; ui_max=REFLECTION_DAMPENING_MAX; ui_step=0.01;
    ui_label="Reflection Dampening";
    ui_tooltip="Dampens the effect of reflected Y on step distance (if Y-reflection is enabled).";
> = REFLECTION_DAMPENING_DEFAULT;

uniform float StepSizeDivisor < ui_category="Wisp Shape";
    ui_type="slider"; ui_min=STEP_SIZE_DIVISOR_MIN; ui_max=STEP_SIZE_DIVISOR_MAX; ui_step=1.0; ui_logarithmic=true;
    ui_label="Step Size Divisor";
    ui_tooltip="Overall divisor for raymarch step size. Smaller values = larger steps, potentially faster but less detail.";
> = STEP_SIZE_DIVISOR_DEFAULT;

uniform int TurbulenceIterations < ui_category="Wisp Shape";
    ui_type="slider"; ui_min=TURBULENCE_ITERATIONS_MIN; ui_max=TURBULENCE_ITERATIONS_MAX; ui_step=1;
    ui_label="Turbulence Iterations";
    ui_tooltip="Number of iterations for fractal turbulence.";
> = TURBULENCE_ITERATIONS_DEFAULT;

uniform float TurbulenceDepthInfluence < ui_category="Wisp Shape";
    ui_type="slider"; ui_min=TURBULENCE_DEPTH_INFLUENCE_MIN; ui_max=TURBULENCE_DEPTH_INFLUENCE_MAX; ui_step=0.01;
    ui_label="Turbulence Depth Influence";
    ui_tooltip="How much ray depth influences turbulence phase.";
> = TURBULENCE_DEPTH_INFLUENCE_DEFAULT;

uniform float TurbulenceStrength < ui_category="Wisp Shape";
    ui_type="slider"; ui_min=TURBULENCE_STRENGTH_MIN; ui_max=TURBULENCE_STRENGTH_MAX; ui_step=0.01;
    ui_label="Turbulence Strength";
    ui_tooltip="General multiplier for turbulence displacement.";
> = TURBULENCE_STRENGTH_DEFAULT;

uniform float PatternFrequency < ui_category="Wisp Shape";
    ui_type="slider"; ui_min=PATTERN_FREQUENCY_MIN; ui_max=PATTERN_FREQUENCY_MAX; ui_step=0.01;
    ui_label="Pattern Frequency";
    ui_tooltip="Frequency of the sin(p.xy) component that shapes wisps. Higher = finer details.";
> = PATTERN_FREQUENCY_DEFAULT;


// --- Wisp Appearance & Tonemapping ---
uniform float WispIntensity < ui_category="Appearance"; 
    ui_type="slider"; ui_min=WISP_INTENSITY_MIN; ui_max=WISP_INTENSITY_MAX; ui_step=0.001; ui_logarithmic=true; 
    ui_label="Intensity / Accumulation"; 
    ui_tooltip="Scales the raw color accumulation per step, affecting wisp brightness/strength.";
> = WISP_INTENSITY_DEFAULT;

uniform float TonemapExposure < ui_category="Appearance"; 
    ui_type="slider"; ui_min=TONEMAP_EXPOSURE_MIN; ui_max=TONEMAP_EXPOSURE_MAX; ui_step=1.0; ui_logarithmic=true;
    ui_label="Tonemap Exposure"; 
    ui_tooltip="Divisor for the accumulated color before tanh tonemapping. Adjusts overall brightness/contrast.";
> = TONEMAP_EXPOSURE_DEFAULT;

uniform float3 WispColor < ui_category="Appearance"; 
    ui_type="color"; ui_label="Wisp Color";
    ui_tooltip="Color tint for the bright wisps when composited against the background.";
> = float3(1.0, 1.0, 1.0);

uniform float WispBrightness < ui_category="Appearance"; 
    ui_type="slider"; ui_min=WISP_BRIGHTNESS_MIN; ui_max=WISP_BRIGHTNESS_MAX; ui_step=0.01;
    ui_label="Wisp Brightness";
    ui_tooltip="How bright the wisps appear against the colorful background.";
> = WISP_BRIGHTNESS_DEFAULT;

uniform float WispMaskSharpness < ui_category="Appearance"; 
    ui_type="slider"; ui_min=WISP_MASK_SHARPNESS_MIN; ui_max=WISP_MASK_SHARPNESS_MAX; ui_step=0.01;
    ui_label="Wisp Mask Sharpness";
    ui_tooltip="Boosts/sharpens the wisp mask created from accumulation. Higher = more defined wisps.";
> = WISP_MASK_SHARPNESS_DEFAULT;

// --- Background Color ---
uniform float BG_Intensity < ui_category="Background Color"; 
    ui_type="slider"; ui_min=BG_INTENSITY_MIN; ui_max=BG_INTENSITY_MAX; ui_step=0.01;
    ui_label="Intensity";
    ui_tooltip="Controls the overall intensity/saturation of the procedural background color.";
> = BG_INTENSITY_DEFAULT;

uniform float BG_AnimSpeed < ui_category="Background Color"; 
    ui_type="slider"; ui_min=BG_ANIM_SPEED_MIN; ui_max=BG_ANIM_SPEED_MAX; ui_step=0.01;
    ui_label="Animation Speed";
    ui_tooltip="Speed for animating the background palette colors.";
> = BG_ANIM_SPEED_DEFAULT;

uniform float3 BG_Base < ui_category="Background Color"; 
    ui_type="color"; ui_label="Base Additive";
    ui_tooltip="Base additive color component.";
> = float3(0.4, 0.4, 0.4);

uniform float3 BG_RayFactor < ui_category="Background Color"; 
    ui_type="color"; ui_label="Ray Direction Factor";
    ui_tooltip="How much ray direction (yzx) influences BG color.";
> = float3(0.3, 0.3, 0.3);

uniform float3 BG_SinewFactor < ui_category="Background Color"; 
    ui_type="color"; ui_label="Sinew Ray Factor";
    ui_tooltip="How much sin(ray direction) (zxy) influences BG color.";
> = float3(0.2, 0.2, 0.2);

uniform float BG_SinewFrequency < ui_category="Background Color"; 
    ui_type="slider"; ui_min=BG_SINEW_FREQ_MIN; ui_max=BG_SINEW_FREQ_MAX; ui_step=0.1;
    ui_label="Sinew Frequency";
    ui_tooltip="Frequency of the sine wave in BG color.";
> = BG_SINEW_FREQ_DEFAULT;


// --- Debugging Uniforms ---
uniform int Debug_OutputSelector < ui_category="Debug";
    ui_type="combo";
    ui_items="0: Final Output\0"
             "1: Accumulated Color (Pre-Tanh)\0"
             "2: Step Color Base\0"
             "3: Raymarch Step (iter 50)\0"
             "4: Accumulated Depth (iter 50)\0"
             "5: Reflection Value (iter 50)\0"
             "6: Sample XY (iter 50)\0"
             "7: Sample Z (iter 50)\0"
             "8: Wisp Mask\0"; 
    ui_label="View"; 
    ui_tooltip="Selects which intermediate value to output for debugging.";
> = 0;

uniform float3 Debug_NaN_Color < ui_category="Debug"; ui_label="NaN/Inf Color"; ui_type="color"; 
    ui_tooltip="Color to display if NaN or Inf values are detected in the output.";
> = float3(1.0, 0.0, 1.0); 

// --- Blend Mode & Amount ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, 5) // Screen blend mode (5)
AS_BLENDAMOUNT_UI(BlendAmount)

//--------------------------------------------------------------------------------------
// PIXEL SHADER
//--------------------------------------------------------------------------------------
float4 PS_Wisps(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float iTime_sec_animated = AS_getTime() * AnimationSpeed; 
    float iTime_sec_raw = AS_getTime(); 
    float keyframeOffset = AnimationKeyframe;

    float2 fragCoord = vpos.xy; 
    float2 R_screen = float2(BUFFER_WIDTH, BUFFER_HEIGHT);

    float z_depth_current = 0.0f; 
    float r_reflect_val_current = 0.0f;         
    float d_step_val_current = 0.0f;            
    float3 p_sample_capture = 0.0f.xxx; 

    float4 OutputColor = float4(0.0f, 0.0f, 0.0f, 0.0f); 
    float3 D_ray = normalize(float3(fragCoord.x * 2.0f - R_screen.x, fragCoord.y * 2.0f - R_screen.y, -R_screen.y * FOVFactor));

    float captured_d_step_val = 0.0f;
    float captured_z_depth = 0.0f;
    float captured_r_reflect_val = 0.0f;

    [loop] 
    for (int i_iter = 0; i_iter < RaymarchSteps; ++i_iter) 
    {        float3 p_sample = z_depth_current * D_ray + RayOriginOffset; 
        p_sample.z -= iTime_sec_animated + keyframeOffset;

        float p_y_before_abs_reflect = p_sample.y;
        if (EnableYReflection) {
            r_reflect_val_current = max(-p_y_before_abs_reflect, 0.0f);
            p_sample.y = abs(p_y_before_abs_reflect); 
        } else {
            r_reflect_val_current = 0.0f; 
        }

        float d_turbulence = 1.0f;
        for (int turb_idx = 0; turb_idx < TurbulenceIterations; ++turb_idx) 
        {
            if (abs(d_turbulence) < AS_EPSILON) d_turbulence = AS_EPSILON; 
            p_sample += cos(p_sample * d_turbulence - z_depth_current * TurbulenceDepthInfluence).yzx / d_turbulence * TurbulenceStrength; // Use TurbulenceStrength
            d_turbulence *= 2.0f; 
        }
        
        if (i_iter == 50) { p_sample_capture = p_sample; }

        float r_denom = ReflectionDampening + r_reflect_val_current + AS_EPSILON;
        d_step_val_current = (r_reflect_val_current + PatternDetail * length(sin(p_sample.xy * PatternFrequency)) / r_denom) / StepSizeDivisor; // Use PatternFrequency, StepSizeDivisor
        d_step_val_current = max(d_step_val_current, AS_EPSILON * 10.0f); 

        if (i_iter == 50) { 
            captured_d_step_val = d_step_val_current;
            captured_z_depth = z_depth_current; 
            captured_r_reflect_val = r_reflect_val_current;
        }
        
        float3 step_color_base = 0.5f + 0.5f * D_ray; 
        float accumulation_denominator = d_step_val_current * (z_depth_current + d_step_val_current) + AS_EPSILON;
      
        if (abs(accumulation_denominator) > AS_EPSILON) {
            OutputColor.rgb -= step_color_base / accumulation_denominator * WispIntensity; 
        }
                                                                                          
        z_depth_current += d_step_val_current; 
        if (z_depth_current > FarClip) break; 
    }

    // --- Final Output Selection based on Debug Mode ---
    float4 debug_final_color = float4(0.0f, 0.0f, 0.0f, 1.0f); 
    float3 tanned_accumulation; 
    float wisp_mask;         

    if (Debug_OutputSelector == 0 || Debug_OutputSelector == 8) { 
        if (any(isnan(OutputColor.rgb)) || any(isinf(OutputColor.rgb))) {
            if (Debug_OutputSelector == 0) debug_final_color.rgb = Debug_NaN_Color; 
            if (Debug_OutputSelector == 8) debug_final_color.rgb = Debug_NaN_Color; 
            tanned_accumulation = float3(0.0,0.0,0.0); 
            wisp_mask = 0.0;
        } else {
            tanned_accumulation = tanh(OutputColor.rgb / TonemapExposure); 
            wisp_mask = saturate(length(-tanned_accumulation * WispMaskSharpness)); 
            wisp_mask = wisp_mask * wisp_mask; 
        }

        if (Debug_OutputSelector == 0) { 
            float3 background_color = (BG_Base + 
                                       BG_RayFactor * D_ray.yzx + 
                                       BG_SinewFactor * sin(D_ray.zxy * BG_SINEW_FREQ_DEFAULT + iTime_sec_raw * BG_AnimSpeed * 0.5f));
            background_color = saturate(background_color * BG_Intensity);
            
            float3 final_wisp_color = WispColor * WispBrightness;
            debug_final_color.rgb = lerp(background_color, final_wisp_color, wisp_mask);
        } else if (Debug_OutputSelector == 8) { 
            debug_final_color.rgb = wisp_mask.xxx;
        }
    } else if (Debug_OutputSelector == 1) { 
        if (any(isnan(OutputColor.rgb)) || any(isinf(OutputColor.rgb))) {
            debug_final_color.rgb = Debug_NaN_Color;
        } else {
            debug_final_color.rgb = saturate(OutputColor.rgb * 0.02f + 0.5f); 
        }
    } else if (Debug_OutputSelector == 2) { 
        debug_final_color.rgb = 0.5f + 0.5f * D_ray;
    } else if (Debug_OutputSelector == 3) { 
        debug_final_color.rgb = saturate(captured_d_step_val * 100.0f).xxx; 
    } else if (Debug_OutputSelector == 4) { 
        debug_final_color.rgb = frac(captured_z_depth * 0.1f).xxx; 
    } else if (Debug_OutputSelector == 5) { 
        debug_final_color.rgb = frac(captured_r_reflect_val * 0.1f).xxx;
    } else if (Debug_OutputSelector == 6) { 
        debug_final_color.rgb = frac((p_sample_capture.xy / R_screen.xy).xyx * 5.0f); 
    } else if (Debug_OutputSelector == 7) { 
        debug_final_color.rgb = frac(p_sample_capture.zzz * 0.1f);
    }    
    debug_final_color.a = 1.0f;
      // Handle debug mode return separately
    if (Debug_OutputSelector > 0) {
        return debug_final_color;
    }
    
    // Apply depth masking using standard AS functions
    float depth = ReShade::GetLinearizedDepth(texcoord);
    // Invert the step function since we want to apply the effect where depth > StageDepth (behind objects)
    float depthMask = step(StageDepth, depth);
    
    // For final output (Debug_OutputSelector == 0), apply blend mode
    float4 originalColor = float4(tex2D(ReShade::BackBuffer, texcoord).rgb, 1.0);
    
    // Apply standard position and scale
    float aspectRatio = BUFFER_WIDTH * BUFFER_RCP_HEIGHT;
    float2 centered = AS_centerCoord(texcoord, aspectRatio);
    float2 transformed = AS_applyPosScale(centered, Position, Scale);
    float distFromCenter = length(transformed);
    
    // Modify alpha based on transformed position and depth mask
    debug_final_color.a = saturate(1.0 - distFromCenter * 0.5) * depthMask;
    
    // Apply standard blend mode
    float4 result = AS_applyBlend(debug_final_color, originalColor, BlendMode, BlendAmount);
    return result;
}

//--------------------------------------------------------------------------------------
// Technique Definition
//--------------------------------------------------------------------------------------
technique AS_BGX_Wisps
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Wisps;    }
}

} // End of namespace ASWisps

#endif