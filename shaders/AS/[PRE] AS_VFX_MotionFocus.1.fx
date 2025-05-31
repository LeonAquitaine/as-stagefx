/**
 * AS_VFX_MotionFocus.1.fx - Automatic Motion-Based Camera Focus & Zoom
 * Author: Leon Aquitaine
 * License: CC BY 4.0
 *
 * DESCRIPTION:
 * This shader analyzes inter-frame motion differences to dynamically adjust the viewport,
 * following and zooming towards areas of detected movement. It uses a multi-pass
 * approach to capture frames, detect motion, analyze motion distribution in quadrants,
 * and apply a corresponding camera transformation.
 *
 * FEATURES:
 * - Multi-pass motion analysis for robust detection.
 * - Half-resolution processing for performance.
 * - Temporal smoothing to prevent jittery camera movements.
 * - Adaptive decay for responsive adjustments to changing motion patterns.
 * - Quadrant-based motion aggregation to determine the center of activity.
 * - Dynamic zoom and focus based on motion intensity and distribution.
 * - Edge correction to prevent sampling outside screen bounds.
 * - User-configurable strength for focus and zoom, plus many advanced tunables.
 * - Debug mode to visualize motion data.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Pass 1 (PS_MotionFocusNorm): Captures the current frame at half resolution.
 * 2. Pass 2 (PS_MotionFocusQuadFull): Calculates per-pixel motion intensity using frame
 * differencing, exponential smoothing, and an adaptive decay system. All key parameters
 * of this stage are tunable via the UI.
 * 3. Pass 3 (PS_MotionFocus): Aggregates motion data from Pass 2 into four screen
 * quadrants by sampling on a grid.
 * 4. Pass 4 (PS_MotionFocusDisplay): Calculates the focus point and zoom level based
 * on quadrant motion data and applies the transformation to the current frame. All key
 * parameters of this stage (panning limits, zoom dynamics, response factors) are tunable.
 * 5. Pass 5 (PS_MotionFocusStorage): Stores the processed current frame and motion data
 * from Pass 1 and Pass 2 for use in the next frame's analysis.
 */

#ifndef __AS_VFX_MotionFocus_1_fx
#define __AS_VFX_MotionFocus_1_fx

#include "ReShade.fxh"

// ============================================================================
// TEXTURES & SAMPLERS
// ============================================================================

texture MotionFocus_NormTex { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA8; };
texture MotionFocus_PrevFrameTex { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA8; };

texture MotionFocus_QuadFullTex { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = R32F; }; // Store motion intensity (single channel)
texture MotionFocus_PrevMotionTex { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = R32F; };

texture MotionFocus_FocusTex { Width = 1; Height = 1; Format = RGBA32F; }; // Stores float4 quadrant motion intensity sums

sampler MotionFocus_NormSampler { Texture = MotionFocus_NormTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler MotionFocus_PrevFrameSampler { Texture = MotionFocus_PrevFrameTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };

sampler MotionFocus_QuadFullSampler { Texture = MotionFocus_QuadFullTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler MotionFocus_PrevMotionSampler { Texture = MotionFocus_PrevMotionTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };

sampler MotionFocus_FocusSampler { Texture = MotionFocus_FocusTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; }; // Point for 1x1

// ============================================================================
// UI UNIFORMS
// ============================================================================

// Category: Motion Focus - Main Controls
// Basic strength controls for the overall effect.
static const float MF_STRENGTH_MIN = 0.0; static const float MF_STRENGTH_MAX = 1.0; static const float MF_STRENGTH_DEFAULT = 0.5; static const float MF_STRENGTH_STEP = 0.01;
uniform float mfFocusStrength < ui_type = "slider"; ui_label = "Overall Focus Strength"; ui_tooltip = "Controls how aggressively the camera follows areas of motion."; ui_min = MF_STRENGTH_MIN; ui_max = MF_STRENGTH_MAX; ui_step = MF_STRENGTH_STEP; ui_category = "Motion Focus - Main Controls"; > = MF_STRENGTH_DEFAULT;
uniform float mfZoomStrength < ui_type = "slider"; ui_label = "Overall Zoom Strength"; ui_tooltip = "Controls the overall intensity of zooming towards areas of motion."; ui_min = MF_STRENGTH_MIN; ui_max = MF_STRENGTH_MAX; ui_step = MF_STRENGTH_STEP; ui_category = "Motion Focus - Main Controls"; > = MF_STRENGTH_DEFAULT;

// Category: Motion Focus - Detection Tuning
// Fine-tune the sensitivity and responsiveness of the motion detection algorithm.
static const float MF_SMOOTHING_MIN = 0.800; static const float MF_SMOOTHING_MAX = 0.999; static const float MF_SMOOTHING_DEFAULT = 0.968; static const float MF_SMOOTHING_STEP = 0.001;
uniform float mfMotionSmoothingFactor < ui_type = "slider"; ui_label = "Detection: Motion Smoothing"; ui_tooltip = "Controls temporal smoothing of motion. Higher = smoother, less responsive (more history). Lower = more responsive, potentially jittery."; ui_min = MF_SMOOTHING_MIN; ui_max = MF_SMOOTHING_MAX; ui_step = MF_SMOOTHING_STEP; ui_category = "Motion Focus - Detection Tuning"; > = MF_SMOOTHING_DEFAULT;

static const float MF_ADECAY_RATE_MIN = 0.800; static const float MF_ADECAY_RATE_MAX = 0.999; static const float MF_ADECAY_RATE_DEFAULT = 0.978; static const float MF_ADECAY_RATE_STEP = 0.001;
uniform float mfAdaptiveDecayBaseRate < ui_type = "slider"; ui_label = "Detection: Adaptive Decay Base Rate"; ui_tooltip = "Base rate at which detected motion intensity fades over time."; ui_min = MF_ADECAY_RATE_MIN; ui_max = MF_ADECAY_RATE_MAX; ui_step = MF_ADECAY_RATE_STEP; ui_category = "Motion Focus - Detection Tuning"; > = MF_ADECAY_RATE_DEFAULT;

static const float MF_ADECAY_STR_MIN = 0.0; static const float MF_ADECAY_STR_MAX = 1.0; static const float MF_ADECAY_STR_DEFAULT = 0.2; static const float MF_ADECAY_STR_STEP = 0.01;
uniform float mfAdaptiveDecayStrength < ui_type = "slider"; ui_label = "Detection: Adaptive Decay Strength"; ui_tooltip = "How strongly motion changes affect the decay rate. Higher = more adaptive decay."; ui_min = MF_ADECAY_STR_MIN; ui_max = MF_ADECAY_STR_MAX; ui_step = MF_ADECAY_STR_STEP; ui_category = "Motion Focus - Detection Tuning"; > = MF_ADECAY_STR_DEFAULT;

static const float MF_ADECAY_SENS_MIN = 1000.0; static const float MF_ADECAY_SENS_MAX = 1000000.0; static const float MF_ADECAY_SENS_DEFAULT = 100000.0; static const float MF_ADECAY_SENS_STEP = 1000.0;
uniform float mfAdaptiveDecaySensitivity < ui_type = "slider"; ui_label = "Detection: Adaptive Decay Sensitivity"; ui_tooltip = "Sensitivity to motion changes for adapting the decay rate. Higher = adapts to smaller changes."; ui_min = MF_ADECAY_SENS_MIN; ui_max = MF_ADECAY_SENS_MAX; ui_step = MF_ADECAY_SENS_STEP; ui_category = "Motion Focus - Detection Tuning"; > = MF_ADECAY_SENS_DEFAULT;

// Category: Motion Focus - Zoom Dynamics
// Control the behavior and limits of the zooming function.
static const float MF_MAX_ZOOM_CAP_MIN = 0.05; static const float MF_MAX_ZOOM_CAP_MAX = 0.49; static const float MF_MAX_ZOOM_CAP_DEFAULT = 0.45; static const float MF_MAX_ZOOM_CAP_STEP = 0.01;
uniform float mfMaxZoomCap < ui_type = "slider"; ui_label = "Zoom: Maximum Cap"; ui_tooltip = "Limits how much the view can zoom in (e.g., 0.45 means the content will fill at least 1-0.45 = 55% of its original dimension)."; ui_min = MF_MAX_ZOOM_CAP_MIN; ui_max = MF_MAX_ZOOM_CAP_MAX; ui_step = MF_MAX_ZOOM_CAP_STEP; ui_category = "Motion Focus - Zoom Dynamics"; > = MF_MAX_ZOOM_CAP_DEFAULT;

static const float MF_BASE_ZOOM_MULT_MIN = 0.1; static const float MF_BASE_ZOOM_MULT_MAX = 2.0; static const float MF_BASE_ZOOM_MULT_DEFAULT = 0.5; static const float MF_BASE_ZOOM_MULT_STEP = 0.05;
uniform float mfBaseZoomMultiplier < ui_type = "slider"; ui_label = "Zoom: Base Multiplier"; ui_tooltip = "Overall scaling factor for the calculated zoom amount, applied before strength and cap."; ui_min = MF_BASE_ZOOM_MULT_MIN; ui_max = MF_BASE_ZOOM_MULT_MAX; ui_step = MF_BASE_ZOOM_MULT_STEP; ui_category = "Motion Focus - Zoom Dynamics"; > = MF_BASE_ZOOM_MULT_DEFAULT;

// Category: Motion Focus - Panning Limits
// Define the maximum range the camera will pan to follow motion.
static const float MF_PAN_X_OFFSET_MIN_VAL = -2.0; static const float MF_PAN_X_OFFSET_MAX_VAL = 0.0; static const float MF_PAN_X_OFFSET_DEFAULT_MIN = -1.0;
static const float MF_PAN_X_OFFSET_P_MAX_VAL = 2.0; static const float MF_PAN_X_OFFSET_P_MIN_VAL = 0.0; static const float MF_PAN_X_OFFSET_DEFAULT_MAX = 0.5;
static const float MF_PAN_Y_OFFSET_MIN_VAL = -2.0; static const float MF_PAN_Y_OFFSET_MAX_VAL = 0.0; static const float MF_PAN_Y_OFFSET_DEFAULT_MIN = -0.5;
static const float MF_PAN_Y_OFFSET_P_MAX_VAL = 2.0; static const float MF_PAN_Y_OFFSET_P_MIN_VAL = 0.0; static const float MF_PAN_Y_OFFSET_DEFAULT_MAX = 0.5;
static const float MF_PAN_LIMIT_STEP = 0.05;

uniform float mfFocusPanXMin < ui_type = "slider"; ui_label = "Panning: X Min Offset"; ui_tooltip = "Maximum offset the camera will pan towards the left (negative values)."; ui_min = MF_PAN_X_OFFSET_MIN_VAL; ui_max = MF_PAN_X_OFFSET_MAX_VAL; ui_step = MF_PAN_LIMIT_STEP; ui_category = "Motion Focus - Panning Limits"; > = MF_PAN_X_OFFSET_DEFAULT_MIN;
uniform float mfFocusPanXMax < ui_type = "slider"; ui_label = "Panning: X Max Offset"; ui_tooltip = "Maximum offset the camera will pan towards the right (positive values)."; ui_min = MF_PAN_X_OFFSET_P_MIN_VAL; ui_max = MF_PAN_X_OFFSET_P_MAX_VAL; ui_step = MF_PAN_LIMIT_STEP; ui_category = "Motion Focus - Panning Limits"; > = MF_PAN_X_OFFSET_DEFAULT_MAX;
uniform float mfFocusPanYMin < ui_type = "slider"; ui_label = "Panning: Y Min Offset"; ui_tooltip = "Maximum offset the camera will pan upwards (negative values)."; ui_min = MF_PAN_Y_OFFSET_MIN_VAL; ui_max = MF_PAN_Y_OFFSET_MAX_VAL; ui_step = MF_PAN_LIMIT_STEP; ui_category = "Motion Focus - Panning Limits"; > = MF_PAN_Y_OFFSET_DEFAULT_MIN;
uniform float mfFocusPanYMax < ui_type = "slider"; ui_label = "Panning: Y Max Offset"; ui_tooltip = "Maximum offset the camera will pan downwards (positive values)."; ui_min = MF_PAN_Y_OFFSET_P_MIN_VAL; ui_max = MF_PAN_Y_OFFSET_P_MAX_VAL; ui_step = MF_PAN_LIMIT_STEP; ui_category = "Motion Focus - Panning Limits"; > = MF_PAN_Y_OFFSET_DEFAULT_MAX;

// Category: Motion Focus - Response & Shift Tuning
// Adjust how the camera responds to global motion and motion distribution, and fine-tune focus shifting.
static const float MF_GLOBAL_RESP_SCALE_MIN = 1.0; static const float MF_GLOBAL_RESP_SCALE_MAX = 20.0; static const float MF_GLOBAL_RESP_SCALE_DEFAULT = 5.0; static const float MF_GLOBAL_RESP_SCALE_STEP = 0.1;
uniform float mfGlobalMotionResponseScale < ui_type = "slider"; ui_label = "Response: Global Motion Scale"; ui_tooltip = "Scales overall motion input for zoom dampening. Higher = more sensitive to global motion for reducing zoom."; ui_min = MF_GLOBAL_RESP_SCALE_MIN; ui_max = MF_GLOBAL_RESP_SCALE_MAX; ui_step = MF_GLOBAL_RESP_SCALE_STEP; ui_category = "Motion Focus - Response & Shift Tuning"; > = MF_GLOBAL_RESP_SCALE_DEFAULT;

static const float MF_DISTRIB_EXP_MIN = 1.0; static const float MF_DISTRIB_EXP_MAX = 5.0; static const float MF_DISTRIB_EXP_DEFAULT = 3.0; static const float MF_DISTRIB_EXP_STEP = 0.1;
uniform float mfDistributionFocusExponent < ui_type = "slider"; ui_label = "Response: Focus Distribution Exponent"; ui_tooltip = "Exponent for the focus distribution factor. Higher = camera shifts more aggressively towards concentrated motion."; ui_min = MF_DISTRIB_EXP_MIN; ui_max = MF_DISTRIB_EXP_MAX; ui_step = MF_DISTRIB_EXP_STEP; ui_category = "Motion Focus - Response & Shift Tuning"; > = MF_DISTRIB_EXP_DEFAULT;

static const float MF_SHIFT_CAP_MIN = 0.1; static const float MF_SHIFT_CAP_MAX = 1.0; static const float MF_SHIFT_CAP_DEFAULT = 0.55; static const float MF_SHIFT_CAP_STEP = 0.01;
uniform float mfFocusShiftCap < ui_type = "slider"; ui_label = "Shift: Max Scale Factor"; ui_tooltip = "Caps the scaling factor applied to the calculated focus shift amount."; ui_min = MF_SHIFT_CAP_MIN; ui_max = MF_SHIFT_CAP_MAX; ui_step = MF_SHIFT_CAP_STEP; ui_category = "Motion Focus - Response & Shift Tuning"; > = MF_SHIFT_CAP_DEFAULT;

static const float MF_SHIFT_SCALE_MIN = 0.1; static const float MF_SHIFT_SCALE_MAX = 2.0; static const float MF_SHIFT_SCALE_DEFAULT = 0.6; static const float MF_SHIFT_SCALE_STEP = 0.05;
uniform float mfFocusShiftBaseScale < ui_type = "slider"; ui_label = "Shift: Base Scale Factor"; ui_tooltip = "Base scaling factor for focus shift, interacts with Overall Zoom Strength."; ui_min = MF_SHIFT_SCALE_MIN; ui_max = MF_SHIFT_SCALE_MAX; ui_step = MF_SHIFT_SCALE_STEP; ui_category = "Motion Focus - Response & Shift Tuning"; > = MF_SHIFT_SCALE_DEFAULT;

// Category: Motion Focus - Debug
// Developer options for visualizing intermediate shader passes.
uniform int mfDebugMode < ui_type = "combo"; ui_label = "Debug Visualization"; ui_items = "Off\0Motion Intensity (Mid-Pass)\0Quadrant Motion Data (Final)\0"; ui_tooltip = "Shows intermediate calculation data for tuning. Select Off for normal operation."; ui_category = "Motion Focus - Debug"; > = 0;

// ============================================================================
// PASS 1: Frame Capture (Half Resolution)
// ============================================================================
float4 PS_MotionFocusNorm(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    return tex2D(ReShade::BackBuffer, texcoord);
}

// ============================================================================
// PASS 2: Motion Detection (Temporal Smoothing & Adaptive Decay)
// ============================================================================
float PS_MotionFocusQuadFull(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float3 current_frame_rgb = tex2D(MotionFocus_NormSampler, texcoord).rgb;
    float3 prev_frame_rgb = tex2D(MotionFocus_PrevFrameSampler, texcoord).rgb;

    float diff_from_prev_frame = (abs(current_frame_rgb.r - prev_frame_rgb.r) +
                                  abs(current_frame_rgb.g - prev_frame_rgb.g) +
                                  abs(current_frame_rgb.b - prev_frame_rgb.b)) / 3.0;

    float previous_pass_motion_value = tex2D(MotionFocus_PrevMotionSampler, texcoord).r;

    // Temporal Smoothing (Exponential Moving Average)
    float smoothed_motion = mfMotionSmoothingFactor * previous_pass_motion_value + (1.0 - mfMotionSmoothingFactor) * diff_from_prev_frame;

    // Adaptive Decay System
    float motion_value_change = abs(smoothed_motion - previous_pass_motion_value);
    float adaptive_decay_factor = mfAdaptiveDecayBaseRate - mfAdaptiveDecayStrength * max(1.0 - pow(1.0 - motion_value_change, 2.0) * mfAdaptiveDecaySensitivity, 0.0);
    adaptive_decay_factor = clamp(adaptive_decay_factor, 0.0, 1.0); // Ensure decay factor is valid

    float final_motion_intensity = adaptive_decay_factor * previous_pass_motion_value + (1.0 - adaptive_decay_factor) * diff_from_prev_frame;
    
    return final_motion_intensity;
}

// ============================================================================
// PASS 3: Quadrant Analysis
// ============================================================================
#define SAMPLE_GRID_X_COUNT 72
#define SAMPLE_GRID_Y_COUNT 72
#define TOTAL_SAMPLES (SAMPLE_GRID_X_COUNT * SAMPLE_GRID_Y_COUNT)

float4 PS_MotionFocus(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target // Only runs for the first pixel (1x1 texture)
{
    // quadrantMotionIntensitySums: x=top-left, y=top-right, z=bottom-left, w=bottom-right
    float4 quadrantMotionIntensitySums = 0; 

    float uv_center_x = 0.5;
    float uv_center_y = 0.5;

    float uv_step_x = 1.0 / SAMPLE_GRID_X_COUNT;
    float uv_step_y = 1.0 / SAMPLE_GRID_Y_COUNT;

    for (int j = 0; j < SAMPLE_GRID_Y_COUNT; ++j)
    {
        for (int i = 0; i < SAMPLE_GRID_X_COUNT; ++i)
        {
            float2 sample_uv = float2((i + 0.5) * uv_step_x, (j + 0.5) * uv_step_y);
            float current_sample_motion_intensity = tex2Dlod(MotionFocus_QuadFullSampler, float4(sample_uv, 0, 0)).r;

            if (sample_uv.x < uv_center_x && sample_uv.y < uv_center_y)
                quadrantMotionIntensitySums.x += current_sample_motion_intensity; // Top-left
            else if (sample_uv.x >= uv_center_x && sample_uv.y < uv_center_y)
                quadrantMotionIntensitySums.y += current_sample_motion_intensity; // Top-right
            else if (sample_uv.x < uv_center_x && sample_uv.y >= uv_center_y)
                quadrantMotionIntensitySums.z += current_sample_motion_intensity; // Bottom-left
            else
                quadrantMotionIntensitySums.w += current_sample_motion_intensity; // Bottom-right
        }
    }

    quadrantMotionIntensitySums /= (float)TOTAL_SAMPLES; // Normalize by total samples

    return quadrantMotionIntensitySums;
}

// ============================================================================
// PASS 4: Focus Application & Display
// ============================================================================
float4 PS_MotionFocusDisplay(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 original_color = tex2D(ReShade::BackBuffer, texcoord);
    // currentQuadrantMotion: .x=TL, .y=TR, .z=BL, .w=BR normalized motion intensity
    float4 currentQuadrantMotion = tex2D(MotionFocus_FocusSampler, float2(0.5,0.5)); 

    if (mfDebugMode == 1) return tex2D(MotionFocus_QuadFullSampler, texcoord).xxxx; // Show full motion detection pass
    if (mfDebugMode == 2) return currentQuadrantMotion; // Show the RGBA values representing quadrant motions

    // Calculate 2D focus offset based on quadrant motion differences
    float2 raw_focus_offset; // Represents tendency: positive X for right, positive Y for bottom
    raw_focus_offset.x = (currentQuadrantMotion.y + currentQuadrantMotion.w - currentQuadrantMotion.x - currentQuadrantMotion.z) / 2.0; // (Right Sum - Left Sum) / 2
    raw_focus_offset.y = (currentQuadrantMotion.z + currentQuadrantMotion.w - currentQuadrantMotion.x - currentQuadrantMotion.y) / 2.0; // (Bottom Sum - Top Sum) / 2

    // Clamp the raw offset values
    float2 clamped_focus_offset;
    clamped_focus_offset.x = clamp(raw_focus_offset.x, mfFocusPanXMin, mfFocusPanXMax);
    clamped_focus_offset.y = clamp(raw_focus_offset.y, mfFocusPanYMin, mfFocusPanYMax);

    // Dominant Quadrant Intensity: The motion intensity of the most active quadrant.
    float dominantQuadrantIntensity = max(currentQuadrantMotion.x, max(currentQuadrantMotion.y, max(currentQuadrantMotion.z, currentQuadrantMotion.w)));

    // Focus Distribution Factor: How much the dominant quadrant stands out from the others. Higher if motion is concentrated.
    float focusDistributionFactor = 1.0;
    float sum_all_quadrant_motions = currentQuadrantMotion.x + currentQuadrantMotion.y + currentQuadrantMotion.z + currentQuadrantMotion.w;
    if (sum_all_quadrant_motions > 0.001) 
    {
        if (dominantQuadrantIntensity == currentQuadrantMotion.x) focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.y + currentQuadrantMotion.z + currentQuadrantMotion.w) / 3.0;
        else if (dominantQuadrantIntensity == currentQuadrantMotion.y) focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.x + currentQuadrantMotion.z + currentQuadrantMotion.w) / 3.0;
        else if (dominantQuadrantIntensity == currentQuadrantMotion.z) focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.x + currentQuadrantMotion.y + currentQuadrantMotion.w) / 3.0;
        else focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.x + currentQuadrantMotion.y + currentQuadrantMotion.z) / 3.0;
        focusDistributionFactor = max(0.0, focusDistributionFactor); 
    }

    // Global Motion Influence: Factor that moderates zoom based on overall screen activity.
    float average_total_motion = sum_all_quadrant_motions / 4.0;
    float globalMotionInfluence = 0.5 * max(1.0, min(2.0 - pow(saturate(average_total_motion * mfGlobalMotionResponseScale), 3.0), 2.0)); 

    // Final Transformation Calculation
    float2 finalZoomAmount = dominantQuadrantIntensity * focusDistributionFactor * globalMotionInfluence * mfZoomStrength * mfBaseZoomMultiplier; 
    finalZoomAmount = min(finalZoomAmount, mfMaxZoomCap); 

    float2 finalFocusShift = -clamped_focus_offset * dominantQuadrantIntensity * pow(focusDistributionFactor, mfDistributionFocusExponent) * globalMotionInfluence * mfFocusStrength;
    finalFocusShift *= min(mfFocusShiftCap, mfFocusShiftBaseScale * mfZoomStrength); 

    float2 zoom_scale_factor = 1.0 - finalZoomAmount; 
    
    float2 transformed_uv = (texcoord - 0.5) * zoom_scale_factor + 0.5 + finalFocusShift;
    
    // Edge Correction
    float2 source_uv_at_screen_corner00 = (float2(0.0, 0.0) - 0.5 - finalFocusShift) / zoom_scale_factor + 0.5;
    float2 source_uv_at_screen_corner11 = (float2(1.0, 1.0) - 0.5 - finalFocusShift) / zoom_scale_factor + 0.5;

    float2 edge_correction_offset = 0;
    if (source_uv_at_screen_corner00.x < 0.0) edge_correction_offset.x -= source_uv_at_screen_corner00.x * zoom_scale_factor.x;
    if (source_uv_at_screen_corner11.x > 1.0) edge_correction_offset.x -= (source_uv_at_screen_corner11.x - 1.0) * zoom_scale_factor.x;
    if (source_uv_at_screen_corner00.y < 0.0) edge_correction_offset.y -= source_uv_at_screen_corner00.y * zoom_scale_factor.y;
    if (source_uv_at_screen_corner11.y > 1.0) edge_correction_offset.y -= (source_uv_at_screen_corner11.y - 1.0) * zoom_scale_factor.y;
    
    transformed_uv += edge_correction_offset;
    transformed_uv = clamp(transformed_uv, 0.0001, 0.9999); 

    return tex2D(ReShade::BackBuffer, transformed_uv);
}

// ============================================================================
// PASS 5: Data Storage
// ============================================================================
float4 PS_MotionFocusStorageNorm(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target 
{
    return tex2D(MotionFocus_NormSampler, texcoord);
}

float PS_MotionFocusStorageMotion(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target 
{
    return tex2D(MotionFocus_QuadFullSampler, texcoord).r;
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_VFX_MotionFocus < ui_tooltip = "Dynamically focuses and zooms the camera based on detected motion.\nRequires multiple frames to initialize.\nExposes advanced tuning parameters for fine control."; >
{
    pass MotionFocusNormPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusNorm;
        RenderTarget = MotionFocus_NormTex;
    }
    pass MotionFocusQuadFullPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusQuadFull;
        RenderTarget = MotionFocus_QuadFullTex;
    }
    pass MotionFocusCalcPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocus;
        RenderTarget = MotionFocus_FocusTex;
    }
    pass MotionFocusDisplayPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusDisplay;
    }
    pass MotionFocusStorageNormPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusStorageNorm;
        RenderTarget = MotionFocus_PrevFrameTex;
    }
    pass MotionFocusStorageMotionPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusStorageMotion;
        RenderTarget = MotionFocus_PrevMotionTex;
    }
}

#endif // __AS_VFX_MotionFocus_1_fx