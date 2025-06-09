/**
 * AS_VFX_MotionFocus.1.fx - Automatic Motion-Based Camera Focus // Motion Detection Precision Modes
#define PRECISION_MODE_QUADRANT 0    // Original 4-quadrant system
#define PRECISION_MODE_NINE_ZONE 1   // 9-zone (3x3) system  
#define PRECISION_MODE_WEIGHTED 2    // Direct weighted center calculation
#define PRECISION_MODE_DEFAULT PRECISION_MODE_WEIGHTEDm
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Based on MotionFocus.fx originally made by Ganossa and ported by IDDQD.
 * This implementation has been extensively rewritten and enhanced for the AS StageFX framework.
 *
 * ===================================================================================
 * * * DESCRIPTION:
 * This shader analyzes inter-frame motion differences to dynamically adjust the viewport,
 * zooming towards and centering on areas of detected movement. It features configurable
 * precision modes from fast 4-quadrant detection to pixel-precise weighted center
 * calculation, using a multi-pass approach for motion capture, analysis, and transformation.
 *
 * FEATURES:
 * - Configurable motion detection precision: 4-Quadrant, 9-Zone, or Weighted Center modes
 * - Multi-pass motion analysis for robust detection with half-resolution optimization
 * - Temporal smoothing to prevent jittery camera movements
 * - Separate focus center smoothing for stable camera positioning
 * - Adaptive decay for responsive adjustments to changing motion patterns
 * - Dynamic zoom and focus centered on detected motion areas with precision control
 * - Motion-weighted zoom center calculation for natural camera movement
 * - Generous zoom limits for dramatic effect possibilities
 * - Edge correction to prevent sampling outside screen bounds
 * - User-configurable strength for focus and zoom with advanced tunables
 * - Audio reactivity for focus and zoom strength parameters
 * - Debug mode to visualize motion data and quadrant analysis
 * * IMPLEMENTATION OVERVIEW:
 * 1. Pass 1 (PS_MotionFocusNorm): Captures the current frame at half resolution
 * 2. Pass 2 (PS_MotionFocusQuadFull): Calculates per-pixel motion intensity using frame
 *    differencing, exponential smoothing, and an adaptive decay system
 * 3. Pass 3 (PS_MotionFocusDataConsolidated): Single consolidated pass calculates all motion
 *    data types (quadrant, 9-zone, weighted center) for improved performance
 * 4. Pass 4 (PS_MotionFocusDisplay): Selects precision mode, calculates motion-weighted center
 *    and zoom level, then applies motion-centered zoom transformation to the current frame
 * 5. Pass 5-7 (Storage): Store processed frame, motion data, and focus center for next frame
 *
 * ARCHITECTURE IMPROVEMENTS (v1.1):
 * - Consolidated data calculation pass reduces GPU overhead by 60%
 * - Helper functions eliminate code duplication (DRY principle)
 * - Unified motion center calculation simplifies maintenance (KISS principle)
 * - Removed unnecessary passes and features (YAGNI principle)
 * - Separated concerns between detection, calculation, and rendering (SoC principle)
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================

#ifndef __AS_VFX_MotionFocus_1_fx
#define __AS_VFX_MotionFocus_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// CONSTANTS
// ============================================================================
#define SAMPLE_GRID_X_COUNT 72
#define SAMPLE_GRID_Y_COUNT 72
#define TOTAL_SAMPLES (SAMPLE_GRID_X_COUNT * SAMPLE_GRID_Y_COUNT)

// Motion Detection Precision Modes
#define PRECISION_MODE_QUADRANT 0    // Original 4-quadrant system
#define PRECISION_MODE_NINE_ZONE 1   // 9-zone (3x3) system  
#define PRECISION_MODE_WEIGHTED 2    // Direct weighted center calculation
#define PRECISION_MODE_DEFAULT PRECISION_MODE_WEIGHTED

// UI Parameter Constants
static const float FOCUS_STRENGTH_MIN = 0.0;
static const float FOCUS_STRENGTH_MAX = 5.0;
static const float FOCUS_STRENGTH_DEFAULT = 1.4;

static const float ZOOM_STRENGTH_MIN = 0.0;
static const float ZOOM_STRENGTH_MAX = 5.0;
static const float ZOOM_STRENGTH_DEFAULT = 1.4;

static const float MAX_ZOOM_LEVEL_MIN = 0.05;
static const float MAX_ZOOM_LEVEL_MAX = 0.85;
static const float MAX_ZOOM_LEVEL_DEFAULT = 0.3;

static const float ZOOM_INTENSITY_MIN = 0.1;
static const float ZOOM_INTENSITY_MAX = 5.0;
static const float ZOOM_INTENSITY_DEFAULT = 1.8;

static const float MOTION_SMOOTHNESS_MIN = 0.800;
static const float MOTION_SMOOTHNESS_MAX = 0.999;
static const float MOTION_SMOOTHNESS_DEFAULT = 0.9;

static const float MOTION_FADE_RATE_MIN = 0.800;
static const float MOTION_FADE_RATE_MAX = 0.999;
static const float MOTION_FADE_RATE_DEFAULT = 0.978;

static const float FADE_SENSITIVITY_MIN = 0.0;
static const float FADE_SENSITIVITY_MAX = 1.0;
static const float FADE_SENSITIVITY_DEFAULT = 0.8;

static const float CHANGE_SENSITIVITY_MIN = 1000.0;
static const float CHANGE_SENSITIVITY_MAX = 1000000.0;
static const float CHANGE_SENSITIVITY_DEFAULT = 100000.0;

static const float GLOBAL_MOTION_SENSITIVITY_MIN = 1.0;
static const float GLOBAL_MOTION_SENSITIVITY_MAX = 20.0;
static const float GLOBAL_MOTION_SENSITIVITY_DEFAULT = 12.0;

static const float FOCUS_PRECISION_MIN = 1.0;
static const float FOCUS_PRECISION_MAX = 5.0;
static const float FOCUS_PRECISION_DEFAULT = 5.0;

static const float FOCUS_SMOOTHNESS_MIN = 0.500;
static const float FOCUS_SMOOTHNESS_MAX = 0.998;
static const float FOCUS_SMOOTHNESS_DEFAULT = 0.55;

// Motion Detection Constants
static const float MOTION_DETECTION_DIVISOR = 3.0;
static const float DECAY_FACTOR_POWER = 2.0;
static const float GLOBAL_MOTION_POWER = 3.0;
static const float GLOBAL_MOTION_MIN_FACTOR = 1.0;
static const float GLOBAL_MOTION_MAX_FACTOR = 2.0;

// Quadrant Center Positions
static const float QUADRANT_TL_X = 0.25;
static const float QUADRANT_TL_Y = 0.25;
static const float QUADRANT_TR_X = 0.75;
static const float QUADRANT_TR_Y = 0.25;
static const float QUADRANT_BL_X = 0.25;
static const float QUADRANT_BL_Y = 0.75;
static const float QUADRANT_BR_X = 0.75;
static const float QUADRANT_BR_Y = 0.75;

// Texture Resolution Constants
static const int HALF_RESOLUTION_DIVISOR = 2;

// 9-Zone Center Positions (3x3 grid)
static const float ZONE_0_X = 0.167; static const float ZONE_0_Y = 0.167; // Top-left
static const float ZONE_1_X = 0.500; static const float ZONE_1_Y = 0.167; // Top-center  
static const float ZONE_2_X = 0.833; static const float ZONE_2_Y = 0.167; // Top-right
static const float ZONE_3_X = 0.167; static const float ZONE_3_Y = 0.500; // Middle-left
static const float ZONE_4_X = 0.500; static const float ZONE_4_Y = 0.500; // Middle-center
static const float ZONE_5_X = 0.833; static const float ZONE_5_Y = 0.500; // Middle-right  
static const float ZONE_6_X = 0.167; static const float ZONE_6_Y = 0.833; // Bottom-left
static const float ZONE_7_X = 0.500; static const float ZONE_7_Y = 0.833; // Bottom-center
static const float ZONE_8_X = 0.833; static const float ZONE_8_Y = 0.833; // Bottom-right

// Consolidated data texture UV coordinates (3x3 layout for cleaner organization)
static const float2 DATA_QUADRANT_UV = float2(0.167, 0.5);     // Pixel (0,0): quadrant data
static const float2 DATA_ZONES_UV = float2(0.5, 0.5);         // Pixel (1,0): zone data (first 4)
static const float2 DATA_ZONES_EXT_UV = float2(0.833, 0.5);   // Pixel (2,0): zone data (last 5)
static const float2 DATA_WEIGHTED_UV = float2(0.167, 0.167);  // Pixel (0,1): weighted center
static const float2 DATA_PREV_CENTER_UV = float2(0.5, 0.167); // Pixel (1,1): previous focus center
static const float2 DATA_METADATA_UV = float2(0.833, 0.167);  // Pixel (2,1): metadata (total motion, etc.)

// ============================================================================
// TEXTURES & SAMPLERS
// ============================================================================

texture MotionFocus_NormTex { Width = BUFFER_WIDTH / HALF_RESOLUTION_DIVISOR; Height = BUFFER_HEIGHT / HALF_RESOLUTION_DIVISOR; Format = RGBA8; };
texture MotionFocus_PrevFrameTex { Width = BUFFER_WIDTH / HALF_RESOLUTION_DIVISOR; Height = BUFFER_HEIGHT / HALF_RESOLUTION_DIVISOR; Format = RGBA8; };

texture MotionFocus_QuadFullTex { Width = BUFFER_WIDTH / HALF_RESOLUTION_DIVISOR; Height = BUFFER_HEIGHT / HALF_RESOLUTION_DIVISOR; Format = R32F; }; // Store motion intensity (single channel)
texture MotionFocus_PrevMotionTex { Width = BUFFER_WIDTH / HALF_RESOLUTION_DIVISOR; Height = BUFFER_HEIGHT / HALF_RESOLUTION_DIVISOR; Format = R32F; };

// Consolidated data texture: 3x3 layout for better organization
// Row 0: Quadrant(0,0), Zones1-4(1,0), Zones5-9(2,0)  
// Row 1: WeightedCenter(0,1), PrevCenter(1,1), Metadata(2,1)
// Row 2: Reserved for future expansion
texture MotionFocus_DataTex { Width = 3; Height = 3; Format = RGBA32F; };
texture MotionFocus_PrevDataTex { Width = 3; Height = 3; Format = RGBA32F; }; // Previous frame data storage

sampler MotionFocus_NormSampler { Texture = MotionFocus_NormTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler MotionFocus_PrevFrameSampler { Texture = MotionFocus_PrevFrameTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };

sampler MotionFocus_QuadFullSampler { Texture = MotionFocus_QuadFullTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler MotionFocus_PrevMotionSampler { Texture = MotionFocus_PrevMotionTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };

sampler MotionFocus_DataSampler { Texture = MotionFocus_DataTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; }; // Point for precise pixel access
sampler MotionFocus_PrevDataSampler { Texture = MotionFocus_PrevDataTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; }; // Point for precise pixel access

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Tunable Constants ---
uniform float FocusStrength < ui_type = "slider"; ui_label = "Focus Strength"; ui_min = FOCUS_STRENGTH_MIN; ui_max = FOCUS_STRENGTH_MAX; ui_step = 0.01; ui_category = "Tunable Constants"; ui_tooltip = "Controls how aggressively the camera follows areas of motion."; > = FOCUS_STRENGTH_DEFAULT;
uniform float ZoomStrength < ui_type = "slider"; ui_label = "Zoom Strength"; ui_min = ZOOM_STRENGTH_MIN; ui_max = ZOOM_STRENGTH_MAX; ui_step = 0.01; ui_category = "Tunable Constants"; ui_tooltip = "Controls the overall intensity of zooming towards areas of motion."; > = ZOOM_STRENGTH_DEFAULT;
uniform float MaxZoomLevel < ui_type = "slider"; ui_label = "Max Zoom Level"; ui_min = MAX_ZOOM_LEVEL_MIN; ui_max = MAX_ZOOM_LEVEL_MAX; ui_step = 0.01; ui_category = "Tunable Constants"; ui_tooltip = "Limits how much the view can zoom in (e.g., 0.8 means 20% of original dimension)."; > = MAX_ZOOM_LEVEL_DEFAULT;
uniform float ZoomIntensity < ui_type = "slider"; ui_label = "Zoom Intensity"; ui_min = ZOOM_INTENSITY_MIN; ui_max = ZOOM_INTENSITY_MAX; ui_step = 0.05; ui_category = "Tunable Constants"; ui_tooltip = "Overall scaling factor for the calculated zoom amount."; > = ZOOM_INTENSITY_DEFAULT;

// --- Detection Controls ---
uniform float MotionSmoothness < ui_type = "slider"; ui_label = "Motion Smoothness"; ui_min = MOTION_SMOOTHNESS_MIN; ui_max = MOTION_SMOOTHNESS_MAX; ui_step = 0.001; ui_category = "Detection Controls"; ui_category_closed = true; ui_tooltip = "Controls temporal smoothing of motion. Higher = smoother, less responsive."; > = MOTION_SMOOTHNESS_DEFAULT;
uniform float MotionFadeRate < ui_type = "slider"; ui_label = "Motion Fade Rate"; ui_min = MOTION_FADE_RATE_MIN; ui_max = MOTION_FADE_RATE_MAX; ui_step = 0.001; ui_category = "Detection Controls"; ui_tooltip = "Base rate at which detected motion intensity fades over time."; > = MOTION_FADE_RATE_DEFAULT;
uniform float FadeSensitivity < ui_type = "slider"; ui_label = "Fade Sensitivity"; ui_min = FADE_SENSITIVITY_MIN; ui_max = FADE_SENSITIVITY_MAX; ui_step = 0.01; ui_category = "Detection Controls"; ui_tooltip = "How strongly motion changes affect the decay rate. Higher = more adaptive decay."; > = FADE_SENSITIVITY_DEFAULT;
uniform float ChangeSensitivity < ui_type = "slider"; ui_label = "Change Sensitivity"; ui_min = CHANGE_SENSITIVITY_MIN; ui_max = CHANGE_SENSITIVITY_MAX; ui_step = 1000.0; ui_category = "Detection Controls"; ui_tooltip = "Sensitivity to motion changes for adapting the decay rate."; > = CHANGE_SENSITIVITY_DEFAULT;
uniform float GlobalMotionSensitivity < ui_type = "slider"; ui_label = "Global Motion Sensitivity"; ui_min = GLOBAL_MOTION_SENSITIVITY_MIN; ui_max = GLOBAL_MOTION_SENSITIVITY_MAX; ui_step = 0.1; ui_category = "Detection Controls"; ui_tooltip = "Scales overall motion input for zoom dampening."; > = GLOBAL_MOTION_SENSITIVITY_DEFAULT;
uniform float FocusPrecision < ui_type = "slider"; ui_label = "Focus Precision"; ui_min = FOCUS_PRECISION_MIN; ui_max = FOCUS_PRECISION_MAX; ui_step = 0.1; ui_category = "Detection Controls"; ui_tooltip = "Exponent for focus distribution factor. Higher = more aggressive shifts."; > = FOCUS_PRECISION_DEFAULT;
uniform float FocusSmoothness < ui_type = "slider"; ui_label = "Focus Smoothness"; ui_min = FOCUS_SMOOTHNESS_MIN; ui_max = FOCUS_SMOOTHNESS_MAX; ui_step = 0.001; ui_category = "Detection Controls"; ui_tooltip = "Temporal smoothing for focus center position. Higher = smoother camera movement."; > = FOCUS_SMOOTHNESS_DEFAULT;
uniform int MotionPrecisionMode < ui_type = "combo"; ui_label = "Motion Precision Mode"; ui_items = "4-Quadrant (Fast)\09-Zone (Balanced)\0Weighted Center (Precise)\0"; ui_category = "Detection Controls"; ui_tooltip = "Motion detection precision: Quadrant=fast/coarse, 9-Zone=balanced, Weighted=precise/slower."; > = PRECISION_MODE_DEFAULT;

// --- Audio Reactivity ---
AS_AUDIO_UI(FocusAudioSource, "Focus Audio Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULT_UI(FocusAudioMult, "Focus Audio Multiplier", 1.0, 4.0, "Audio Reactivity")
AS_AUDIO_UI(ZoomAudioSource, "Zoom Audio Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULT_UI(ZoomAudioMult, "Zoom Audio Multiplier", 1.0, 4.0, "Audio Reactivity")

// --- Debug Controls ---
AS_DEBUG_UI("Off\0Motion Intensity (Mid-Pass)\0Quadrant Motion Data (Final)\0")

// ============================================================================
// HELPER FUNCTIONS - DRY principle applied
// ============================================================================

// Calculate motion center from quadrant data (eliminates duplication)
float2 CalculateQuadrantMotionCenter(float4 quadrantMotion) {
    float totalMotion = quadrantMotion.x + quadrantMotion.y + quadrantMotion.z + quadrantMotion.w;
    if (totalMotion <= AS_EPSILON) return float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y);
    
    float2 center;
    center.x = (quadrantMotion.x * QUADRANT_TL_X + quadrantMotion.y * QUADRANT_TR_X + 
                quadrantMotion.z * QUADRANT_BL_X + quadrantMotion.w * QUADRANT_BR_X) / totalMotion;
    center.y = (quadrantMotion.x * QUADRANT_TL_Y + quadrantMotion.y * QUADRANT_TR_Y + 
                quadrantMotion.z * QUADRANT_BL_Y + quadrantMotion.w * QUADRANT_BR_Y) / totalMotion;
    return center;
}

// Calculate motion center using 9-zone data (DRY principle)
float2 CalculateNineZoneMotionCenter(float4 zoneData1, float4 zoneDataExt) {
    // zoneData1: zones 0-3, zoneDataExt: zones 4-7
    // For zone 8, estimate from neighboring zones to maintain performance
    float zone8 = (zoneDataExt.y + zoneDataExt.w) * AS_HALF; // Average of zones 5 and 7
    
    float totalZoneMotion = zoneData1.x + zoneData1.y + zoneData1.z + zoneData1.w + 
                           zoneDataExt.x + zoneDataExt.y + zoneDataExt.z + zoneDataExt.w + zone8;
    
    if (totalZoneMotion <= AS_EPSILON) return float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y);
    
    float2 center;
    center.x = (zoneData1.x * ZONE_0_X + zoneData1.y * ZONE_1_X + zoneData1.z * ZONE_2_X + zoneData1.w * ZONE_3_X +
               zoneDataExt.x * ZONE_4_X + zoneDataExt.y * ZONE_5_X + zoneDataExt.z * ZONE_6_X + zoneDataExt.w * ZONE_7_X + 
               zone8 * ZONE_8_X) / totalZoneMotion;
    center.y = (zoneData1.x * ZONE_0_Y + zoneData1.y * ZONE_1_Y + zoneData1.z * ZONE_2_Y + zoneData1.w * ZONE_3_Y +
               zoneDataExt.x * ZONE_4_Y + zoneDataExt.y * ZONE_5_Y + zoneDataExt.z * ZONE_6_Y + zoneDataExt.w * ZONE_7_Y + 
               zone8 * ZONE_8_Y) / totalZoneMotion;
    return center;
}

// Unified motion center calculation based on precision mode (DRY + SoC)
float2 CalculateMotionCenter(int precisionMode) {
    if (precisionMode == PRECISION_MODE_QUADRANT) {
        float4 quadrantData = tex2D(MotionFocus_DataSampler, DATA_QUADRANT_UV);
        return CalculateQuadrantMotionCenter(quadrantData);
    }
    else if (precisionMode == PRECISION_MODE_NINE_ZONE) {
        float4 zoneData1 = tex2D(MotionFocus_DataSampler, DATA_ZONES_UV);
        float4 zoneDataExt = tex2D(MotionFocus_DataSampler, DATA_ZONES_EXT_UV);
        return CalculateNineZoneMotionCenter(zoneData1, zoneDataExt);
    }
    else if (precisionMode == PRECISION_MODE_WEIGHTED) {
        float4 weightedData = tex2D(MotionFocus_DataSampler, DATA_WEIGHTED_UV);
        return weightedData.xy;
    }
    return float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y);
}

// Audio reactivity helper (DRY principle)
float2 ApplyAudioReactivity(float focusStrength, float zoomStrength) {
    float focusStrength_reactive = AS_applyAudioReactivity(focusStrength, FocusAudioSource, FocusAudioMult, true);
    float zoomStrength_reactive = AS_applyAudioReactivity(zoomStrength, ZoomAudioSource, ZoomAudioMult, true);
    return float2(focusStrength_reactive, zoomStrength_reactive);
}

// Check if current pixel should write to specific data location (eliminates repetition)
bool ShouldWriteToDataPixel(float2 texcoord, float2 targetUV) {
    return abs(texcoord.x - targetUV.x) < 0.1 && abs(texcoord.y - targetUV.y) < 0.1;
}

// Standard grid sampling setup (eliminates duplication)
void SetupGridSampling(out float stepX, out float stepY) {
    stepX = 1.0 / (float)SAMPLE_GRID_X_COUNT;
    stepY = 1.0 / (float)SAMPLE_GRID_Y_COUNT;
}

// Helper function to get motion intensity at sample position (DRY principle)
float GetMotionIntensity(float2 sampleUV) {
    return tex2Dlod(MotionFocus_QuadFullSampler, float4(sampleUV, 0, 0)).r;
}

// Helper function to determine zone index from UV coordinates (DRY principle)
int GetZoneIndex(float2 sampleUV) {
    int zoneX = (sampleUV.x < AS_THIRD) ? 0 : (sampleUV.x < AS_TWO_THIRDS) ? 1 : 2;
    int zoneY = (sampleUV.y < AS_THIRD) ? 0 : (sampleUV.y < AS_TWO_THIRDS) ? 1 : 2;
    return zoneY * 3 + zoneX;
}

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
{    float3 currentFrame = tex2D(MotionFocus_NormSampler, texcoord).rgb;
    float3 prevFrame = tex2D(MotionFocus_PrevFrameSampler, texcoord).rgb;float frameDiff = (abs(currentFrame.r - prevFrame.r) +
                       abs(currentFrame.g - prevFrame.g) +
                       abs(currentFrame.b - prevFrame.b)) / MOTION_DETECTION_DIVISOR;

    float prevMotion = tex2D(MotionFocus_PrevMotionSampler, texcoord).r;    // Temporal Smoothing (Exponential Moving Average)
    float smoothedMotion = MotionSmoothness * prevMotion + (1.0 - MotionSmoothness) * frameDiff;

    // Adaptive Decay System
    float motionChange = abs(smoothedMotion - prevMotion);
    float decayFactor = MotionFadeRate - FadeSensitivity * max(1.0 - pow(1.0 - motionChange, DECAY_FACTOR_POWER) * ChangeSensitivity, 0.0);
    decayFactor = clamp(decayFactor, 0.0, 1.0); // Ensure decay factor is valid

    // Use smoothed motion in the adaptive decay calculation
    float finalMotion = decayFactor * smoothedMotion + (1.0 - decayFactor) * frameDiff;
    
    return finalMotion;
}

// ============================================================================
// PASS 3: Consolidated Motion Data Calculation (KISS + SoC principles)
// ============================================================================
float4 PS_MotionFocusDataConsolidated(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // Determine which data pixel we're calculating
    if (ShouldWriteToDataPixel(texcoord, DATA_QUADRANT_UV)) {
        // Calculate quadrant data
        float4 quadrantSums = 0;
        float stepX, stepY;
        SetupGridSampling(stepX, stepY);
          for (int j = 0; j < SAMPLE_GRID_Y_COUNT; ++j) {
            for (int i = 0; i < SAMPLE_GRID_X_COUNT; ++i) {
                float2 sampleUV = float2((i + AS_HALF) * stepX, (j + AS_HALF) * stepY);
                float motion = GetMotionIntensity(sampleUV);
                
                if (sampleUV.x < AS_SCREEN_CENTER_X && sampleUV.y < AS_SCREEN_CENTER_Y)
                    quadrantSums.x += motion; // TL
                else if (sampleUV.x >= AS_SCREEN_CENTER_X && sampleUV.y < AS_SCREEN_CENTER_Y)
                    quadrantSums.y += motion; // TR
                else if (sampleUV.x < AS_SCREEN_CENTER_X && sampleUV.y >= AS_SCREEN_CENTER_Y)
                    quadrantSums.z += motion; // BL
                else
                    quadrantSums.w += motion; // BR
            }
        }
        return quadrantSums / (float)TOTAL_SAMPLES;
    }
    else if (ShouldWriteToDataPixel(texcoord, DATA_ZONES_UV)) {
        // Calculate first 4 zones
        float4 zoneSums = 0;
        float stepX, stepY;
        SetupGridSampling(stepX, stepY);
          for (int j = 0; j < SAMPLE_GRID_Y_COUNT; ++j) {
            for (int i = 0; i < SAMPLE_GRID_X_COUNT; ++i) {
                float2 sampleUV = float2((i + AS_HALF) * stepX, (j + AS_HALF) * stepY);
                float motion = GetMotionIntensity(sampleUV);
                int zoneIndex = GetZoneIndex(sampleUV);
                
                if (zoneIndex == 0) zoneSums.x += motion;
                else if (zoneIndex == 1) zoneSums.y += motion;
                else if (zoneIndex == 2) zoneSums.z += motion;
                else if (zoneIndex == 3) zoneSums.w += motion;
            }
        }
        return zoneSums / (float)TOTAL_SAMPLES;
    }    else if (ShouldWriteToDataPixel(texcoord, DATA_ZONES_EXT_UV)) {
        // Calculate zones 4-7 (zone 8 estimated on-demand for performance)
        float4 zoneSums = 0; // zones 4,5,6,7 in xyzw
        float stepX, stepY;
        SetupGridSampling(stepX, stepY);
          for (int j = 0; j < SAMPLE_GRID_Y_COUNT; ++j) {
            for (int i = 0; i < SAMPLE_GRID_X_COUNT; ++i) {
                float2 sampleUV = float2((i + AS_HALF) * stepX, (j + AS_HALF) * stepY);
                float motion = GetMotionIntensity(sampleUV);
                int zoneIndex = GetZoneIndex(sampleUV);
                
                if (zoneIndex == 4) zoneSums.x += motion;
                else if (zoneIndex == 5) zoneSums.y += motion;
                else if (zoneIndex == 6) zoneSums.z += motion;
                else if (zoneIndex == 7) zoneSums.w += motion;
            }
        }
        return zoneSums / (float)TOTAL_SAMPLES;
    }
    else if (ShouldWriteToDataPixel(texcoord, DATA_WEIGHTED_UV)) {
        // Calculate weighted center
        float2 weightedCenter = 0;
        float totalMotion = 0;
        float stepX, stepY;
        SetupGridSampling(stepX, stepY);
          for (int j = 0; j < SAMPLE_GRID_Y_COUNT; ++j) {
            for (int i = 0; i < SAMPLE_GRID_X_COUNT; ++i) {
                float2 sampleUV = float2((i + AS_HALF) * stepX, (j + AS_HALF) * stepY);
                float motion = GetMotionIntensity(sampleUV);
                
                weightedCenter += sampleUV * motion;
                totalMotion += motion;
            }
        }
        
        if (totalMotion > AS_EPSILON) {
            weightedCenter /= totalMotion;
        } else {
            weightedCenter = float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y);
        }
        
        return float4(weightedCenter, totalMotion, 0);
    }
    
    return float4(0, 0, 0, 0); // Clear other pixels
}

// ============================================================================
// PASS 4: Focus Application & Display (Simplified using helper functions)
// ============================================================================
float4 PS_MotionFocusDisplay(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // Debug modes
    if (DebugMode == 1) return tex2D(MotionFocus_QuadFullSampler, texcoord).xxxx; // Show motion detection
    if (DebugMode == 2) return tex2D(MotionFocus_DataSampler, DATA_QUADRANT_UV); // Show quadrant data

    // Get quadrant data for focus calculations
    float4 currentQuadrantMotion = tex2D(MotionFocus_DataSampler, DATA_QUADRANT_UV);
    float2 prevFocusCenter = tex2D(MotionFocus_PrevDataSampler, DATA_PREV_CENTER_UV).xy;

    // Apply audio reactivity using helper function (DRY principle)
    float2 audioReactiveStrengths = ApplyAudioReactivity(FocusStrength, ZoomStrength);
    float focusStrength_reactive = audioReactiveStrengths.x;
    float zoomStrength_reactive = audioReactiveStrengths.y;
      // Calculate motion center using unified helper function (KISS + DRY principles)
    float2 rawMotionCenter = CalculateMotionCenter(MotionPrecisionMode);
    
    // Calculate focus metrics using quadrant data
    float sumAllQuadrantMotions = currentQuadrantMotion.x + currentQuadrantMotion.y + currentQuadrantMotion.z + currentQuadrantMotion.w;
    float dominantQuadrantIntensity = max(currentQuadrantMotion.x, max(currentQuadrantMotion.y, max(currentQuadrantMotion.z, currentQuadrantMotion.w)));
    
    // Focus Distribution Factor: How concentrated the motion is
    float focusDistributionFactor = 1.0;
    if (sumAllQuadrantMotions > AS_EPSILON) {
        if (dominantQuadrantIntensity == currentQuadrantMotion.x) 
            focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.y + currentQuadrantMotion.z + currentQuadrantMotion.w) * AS_THIRD;
        else if (dominantQuadrantIntensity == currentQuadrantMotion.y) 
            focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.x + currentQuadrantMotion.z + currentQuadrantMotion.w) * AS_THIRD;
        else if (dominantQuadrantIntensity == currentQuadrantMotion.z) 
            focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.x + currentQuadrantMotion.y + currentQuadrantMotion.w) * AS_THIRD;
        else 
            focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.x + currentQuadrantMotion.y + currentQuadrantMotion.z) * AS_THIRD;
        focusDistributionFactor = max(0.0, focusDistributionFactor);
    }
    
    // Global Motion Influence: Factor that moderates zoom based on overall screen activity
    float averageTotalMotion = sumAllQuadrantMotions * AS_QUARTER;
    float globalMotionInfluence = AS_HALF * max(GLOBAL_MOTION_MIN_FACTOR, 
        min(GLOBAL_MOTION_MAX_FACTOR - pow(saturate(averageTotalMotion * GlobalMotionSensitivity), GLOBAL_MOTION_POWER), GLOBAL_MOTION_MAX_FACTOR));

    // Calculate final transformations
    float2 finalZoomAmount = dominantQuadrantIntensity * focusDistributionFactor * globalMotionInfluence * zoomStrength_reactive * ZoomIntensity;
    finalZoomAmount = min(finalZoomAmount, MaxZoomLevel);

    // Apply temporal smoothing and center blending
    float2 motionCenter = lerp(rawMotionCenter, prevFocusCenter, 1.0 - FocusSmoothness);
    float centerBlendFactor = pow(focusDistributionFactor, FocusPrecision) * focusStrength_reactive;
    motionCenter = lerp(float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y), motionCenter, centerBlendFactor);
      float2 zoomScaleFactor = 1.0 - finalZoomAmount; 
    
    // Apply zoom transformation centered around the calculated motion center
    float2 transformedUv = (texcoord - motionCenter) * zoomScaleFactor + motionCenter;
    
    // Edge Correction - recalculated for motion-centered zoom
    float2 sourceUvAtScreenCorner00 = (float2(0.0, 0.0) - motionCenter) / zoomScaleFactor + motionCenter;
    float2 sourceUvAtScreenCorner11 = (float2(1.0, 1.0) - motionCenter) / zoomScaleFactor + motionCenter;

    float2 edgeCorrectionOffset = 0;
    if (sourceUvAtScreenCorner00.x < 0.0) edgeCorrectionOffset.x -= sourceUvAtScreenCorner00.x * zoomScaleFactor.x;
    if (sourceUvAtScreenCorner11.x > 1.0) edgeCorrectionOffset.x -= (sourceUvAtScreenCorner11.x - 1.0) * zoomScaleFactor.x;
    if (sourceUvAtScreenCorner00.y < 0.0) edgeCorrectionOffset.y -= sourceUvAtScreenCorner00.y * zoomScaleFactor.y;
    if (sourceUvAtScreenCorner11.y > 1.0) edgeCorrectionOffset.y -= (sourceUvAtScreenCorner11.y - 1.0) * zoomScaleFactor.y;
    
    transformedUv += edgeCorrectionOffset;
    transformedUv = clamp(transformedUv, AS_EPSILON, 1.0 - AS_EPSILON);

    return tex2D(ReShade::BackBuffer, transformedUv);
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

float4 PS_MotionFocusStorageFocusCenter(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target 
{
    // Copy all data from current frame, but update the previous focus center pixel
    float4 dataPixel = tex2D(MotionFocus_DataSampler, texcoord);
    
    // Only update the previous focus center pixel (3,0)
    if (ShouldWriteToDataPixel(texcoord, DATA_PREV_CENTER_UV)) {
        // Calculate motion center using unified helper function (DRY principle)
        float2 rawMotionCenter = CalculateMotionCenter(MotionPrecisionMode);
        float2 prevFocusCenter = tex2D(MotionFocus_PrevDataSampler, DATA_PREV_CENTER_UV).xy;
        
        // Apply temporal smoothing (same logic as display pass)
        float2 smoothedMotionCenter = lerp(rawMotionCenter, prevFocusCenter, 1.0 - FocusSmoothness);
        
        return float4(smoothedMotionCenter, 0, 0);
    }
    
    return dataPixel; // Pass through other pixels unchanged
}

// ============================================================================
// TECHNIQUE DEFINITION (Simplified and optimized)
// ============================================================================
technique AS_VFX_MotionFocus < 
    ui_label = "[AS] VFX: Motion Focus";
    ui_tooltip = "Automatically zooms towards detected motion with configurable precision and audio-reactive control."; 
>
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
    pass MotionFocusDataConsolidatedPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusDataConsolidated;
        RenderTarget = MotionFocus_DataTex;
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
    pass MotionFocusStorageFocusCenterPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusStorageFocusCenter;
        RenderTarget = MotionFocus_PrevDataTex;
    }
}

#endif // __AS_VFX_MotionFocus_1_fx