/**
 * AS_GFX_AutoLeveler.1.fx - Dynamic Luminance & Contrast Adjustment
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * An advanced auto-levels shader that dynamically adjusts image luminance and contrast
 * by remapping the black and white points based on scene content. Implements professional
 * photographer-friendly controls and intelligent remapping for virtual photography.
 *
 * WHEN TO USE:
 * - When working with scenes that have flat, low-contrast lighting (fog, overcast)
 * - For automatic normalization of luminance range across varied scenes
 * - In video sequences requiring consistent contrast without manual adjustment
 * - When processing batches of screenshots that need standardized exposure
 * - To recover detail from scenes with crushed shadows or blown highlights
 * - For creating stylized cinematic or editorial looks with precise contrast control
 * * HOW TO USE:
 * 
 * BASIC WORKFLOW:
 * 1. Enable the shader and select a preset that matches your needs, or leave as "Custom"
 * 2. If using a preset, observe the result and try different presets until you find one
 *    that works well for your scene or game
 * 3. If using "Custom", adjust the percentile thresholds (Black Point and White Point)
 *    to control how aggressively the shader detects and corrects shadows and highlights
 * 4. Fine-tune the Midtone Bias to shift the exposure balance toward shadows or highlights
 * 5. Use Shadow Lift for a filmic raised-black look, and Soft Clip for highlight roll-off
 * 6. Adjust overall Contrast to taste for the final image
 * 7. Use the debug visualization options to identify problem areas
 *
 * PRESET RECOMMENDATIONS:
 * - Standard Photography: For general purpose use with balanced adjustments
 * - Cinematic Look: For a film-like appearance with raised blacks and soft highlights
 * - High Contrast: For dramatic lighting with strong shadows and highlights
 * - Natural Light: For subtle enhancement that maintains the original feel
 * - Technical/Accurate: For minimal processing when accuracy is important
 * - Broadcast Safe: For video content with smooth transitions and safe levels
 * - Gaming: For responsive adjustments during fast-paced gameplay
 * - Vintage Film: For a classic film look with characteristic tonality
 * * PARAMETER DETAILS:
 * - Black Point: Lower percentile of luminance to map to black (higher = darker shadows)
 * - White Point: Upper percentile of luminance to map to white (lower = brighter highlights)
 * - Midtone Bias: Controls the curve's gamma for midtone exposure balance
 * - Shadow Lift: Raises the black floor for a filmic/analog look
 * - Soft Clip Amount: Controls highlight compression to avoid harsh clipping
 * - Contrast: Final contrast multiplier applied after remapping
 * - Temporal Smoothing: How quickly adjustment adapts to scene changes
 * - Color Preservation: Color handling during remapping
 * 
 * TRANSITION STABILITY CONTROLS:
 * - Analysis Frequency: Analyze histogram every N frames (higher = smoother, less responsive)
 * - Max Adjustment Rate: Limits how quickly levels can change per frame
 * - Stability Threshold: Ignores small changes below this threshold
 * - Adaptive Smoothing: Automatically reduces smoothing during dramatic scene changes
 * * ADVANCED TIPS:
 * - Use lower percentiles (0.1%) for subtle adjustment, higher (5-10%) for dramatic effect
 * - For cinematic look: Increase Shadow Lift (0.05-0.1) and moderate Soft Clip (0.2-0.3)
 * - For technical accuracy: Use minimal Shadow Lift (0) and Soft Clip (0-0.1)
 * - Midtone Bias below 1.0 brightens midtones, above 1.0 darkens them
 * - Turn on heatmap debug view to see where adjustments are most significant
 * - For video, use higher temporal smoothing (0.9+) to avoid flickering
 *  * TRANSITION STABILITY TIPS:
 * - For smoother gameplay: Set Analysis Frequency to 10-30 and increase Stability Threshold
 * - For cutscenes/video: Use Max Adjustment Rate 0.001-0.005 for very smooth transitions
 * - For static photography: Keep defaults or lower Stability Threshold to 0 for precise adjustments
 * - When using high Analysis Frequency, lower Max Adjustment Rate to prevent large jumps
 * - Enable Adaptive Smoothing for mixed content with both gradual changes and hard cuts
 * * FEATURES:
 * - Ready-to-use professional presets for different scenarios
 * - Dynamic percentile-based black and white point detection
 * - Gamma-aware midtone correction with artistic control
 * - Soft shoulder roll-off for highlight preservation
 * - Shadow lifting for filmic/analog aesthetics
 * - Advanced transition stability controls for smoother adjustments
 * - Configurable analysis frequency and change rate limiting
 * - Adaptive temporal smoothing with scene change detection
 * - Intelligent color preservation options
 * - Multiple debug visualization modes
 * - Optimized performance for real-time use
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Frame luminance data is collected and analyzed via histogram
 * 2. Black and white points are determined from percentile thresholds
 * 3. Temporal smoothing is applied for stable adjustments over time
 * 4. A tone mapping curve is applied with midtone bias, shadow lift, and soft clipping
 * 5. Contrast normalization is performed on the remapped values
 * 6. Color information is preserved while luminance is adjusted
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_GFX_AutoLeveler_1_fx
#define __AS_GFX_AutoLeveler_1_fx

// Core includes
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// CONSTANTS
// ============================================================================

// ========== Core Constants ==========
#ifndef HISTOGRAM_BINS
#define HISTOGRAM_BINS      256  // Keep this at 256 for compatibility
#endif
#define HISTOGRAM_TEXSIZE   256  // Must match HISTOGRAM_BINS
#define PERCENTILE_SAMPLES  64

// ========== Numerical Safety Constants ==========
#define EPSILON_MULTIPLIER  10.0  // Used to create safe epsilon values
#define MIN_DYNAMIC_RANGE   0.1   // 10% minimum range to prevent collapse
#define SAFE_BLACK_POINT    0.01  // Safe minimum black point (10*epsilon)
#define SAFE_WHITE_POINT    0.99  // Safe maximum white point (1-10*epsilon)

// ========== Stability and Transition Constants ==========
#define MAX_SCENE_DIFF      0.5   // Maximum scene difference before considered a scene change
#define MIN_SMOOTHING       0.5   // Minimum smoothing during scene changes
#define EQUILIBRIUM_RATE    0.01  // Rate at which values drift toward neutral

// ========== Color Preservation Modes ==========
#define MODE_RGB           0
#define MODE_YCBCR         1
#define MODE_HSV           2
#define MODE_GRAYWORLD     3

// ========== Debug Visualization Modes ==========
#define DEBUG_OFF          0
#define DEBUG_HISTOGRAM    1
#define DEBUG_HEATMAP      2
#define DEBUG_ZEBRA        3
#define DEBUG_SPLIT        4
#define DEBUG_ZONES        5

// ========== Contrast Curve Constants ==========
// Curve types
#define CURVE_GAMMA        0  // Original gamma-based curve
#define CURVE_FILMIC_S     1  // Filmic S-curve 
#define CURVE_PIECEWISE    2  // Piecewise Linear
#define CURVE_POWERLOG     3  // Power-Log hybrid
#define CURVE_ANALOG_FILM  4  // Cineon-like film response

// Curve parameter constants
#define CURVE_S_CONTRAST   0.6   // Contrast in filmic S-curve
#define CURVE_S_TOE        0.5   // Toe strength in filmic S-curve
#define CURVE_S_SHOULDER   1.25  // Shoulder strength in filmic S-curve
#define CURVE_POWER_FACTOR 10.0  // Power factor for power-log hybrid curve
#define CURVE_LOG_BASE     11.0  // Log base for power-log hybrid curve
#define CURVE_SHAPE_CTRL   2.0   // Shape control factor for curves
#define CINEON_BLACK       95.0  // Standard Cineon black point (95/1023)
#define CINEON_WHITE       685.0 // Standard Cineon white point (685/1023)
#define CINEON_DIVISOR     1023.0 // Standard Cineon divisor

// ========== Zone System Constants ==========
#define ZONE_COUNT         10  // Number of zones in the traditional zone system 
#define ZONES_BLACK        0   // Black  (zone 0)
#define ZONES_WHITE        9   // White  (zone 9)
#define ZONES_MID_GRAY     5   // Middle gray (zone 5)

// ========== Shadow Recovery Constants ==========
#define SHADOW_LIFT_MAX    0.15
#define SHADOW_RECOVER_MAX 0.35

// ========== Quality Presets for Histogram ==========
#define HIST_QUALITY_LOW   64
#define HIST_QUALITY_MED   128
#define HIST_QUALITY_STD   256
#define HIST_QUALITY_HIGH  512

// ========== Preset Identifiers ==========
#define PRESET_CUSTOM          0
#define PRESET_STANDARD_PHOTO  1
#define PRESET_CINEMATIC       2
#define PRESET_HIGH_CONTRAST   3
#define PRESET_NATURAL_LIGHT   4
#define PRESET_TECHNICAL       5
#define PRESET_BROADCAST       6
#define PRESET_GAMING          7
#define PRESET_VINTAGE_FILM    8
#define NUM_STATIC_PRESETS     8

// ========== Preset Parameter Indexes ==========
#define DEF_BLACK_POINT       0
#define DEF_WHITE_POINT       1
#define DEF_MIDTONE_BIAS      2
#define DEF_SHADOW_LIFT       3
#define DEF_SOFT_CLIP         4
#define DEF_CONTRAST          5
#define DEF_SMOOTHING         6
#define DEF_ANALYSIS_FREQ     7
#define DEF_ADJUST_RATE       8
#define DEF_STABILITY         9
#define DEF_LIFT_THRESHOLD    10
#define DEF_ENABLE_ADAPTIVE   11  // 1.0 = true, 0.0 = false
#define DEF_COLOR_MODE        12  // Store the mode integer directly
#define DEF_CURVE_TYPE        13  // Store the curve type integer directly
#define DEF_AUTO_LIFT_SHADOWS 14  // 1.0 = true, 0.0 = false
#define DEF_STATIC_PARAMETERS 15  // 1.0 = true, 0.0 = false

// ============================================================================
// PARAMETER STRUCT
// ============================================================================

struct LevelerParams {
    float BlackPoint;
    float WhitePoint;
    float MidtoneBias;
    float ShadowLift;
    float SoftClipAmount;
    float ContrastAmount;
    float TemporalSmoothing;
    int AnalysisFrequency;
    float MaxAdjustmentRate;
    float StabilityThreshold;
    bool EnableAdaptiveSmoothing;
    int ColorPreservationMode;
    int CurveType;
    bool AutoLiftShadows;
    float AutoLiftThreshold;
};


// ========== Default Preset Values (Arrays) ==========
static const float STATIC_LEVELER_PRESETS[NUM_STATIC_PRESETS * DEF_STATIC_PARAMETERS] = {    // Index 0: Corresponds to PRESET_CHOICE_STANDARD_PHOTO (value 1 from UI)
    0.5f, 99.0f, 1.0f, 0.03f, 0.15f, 1.1f, 0.8f, (int)5, 0.01f, 0.002f, true, (int)1, (int)0, false, 0.03f,    // Index 1: Corresponds to PRESET_CHOICE_CINEMATIC (value 2 from UI)
    3.5f, 99.0f, 1.25f, 0.06f, 0.2f, 1.15f, 0.7f, (int)2, 0.02f, 0.001f, true, (int)1, (int)1, false, 0.08f,
    // Index 2: Corresponds to PRESET_CHOICE_HIGH_CONTRAST (value 3 from UI)
    3.0f, 98.0f, 1.15f, 0.04f, 0.1f, 1.4f, 0.75f, (int)3, 0.02f, 0.001f, true, (int)2, (int)0, false, 0.04f,
    // Index 3: Corresponds to PRESET_CHOICE_NATURAL_LIGHT (value 4 from UI)
    0.2f, 99.5f, 0.95f, 0.01f, 0.15f, 1.05f, 0.85f, (int)8, 0.008f, 0.003f, true, (int)1, (int)3, false, 0.01f,
    // Index 4: Corresponds to PRESET_CHOICE_TECHNICAL (value 5 from UI)
    0.1f, 99.9f, 1.0f, 0.0f, 0.05f, 1.0f, 0.7f, (int)1, 0.02f, 0.0f, false, (int)1, (int)0, false, 0.0f,
    // Index 5: Corresponds to PRESET_CHOICE_BROADCAST (value 6 from UI)
    1.0f, 99.0f, 1.05f, 0.02f, 0.2f, 1.1f, 0.95f, (int)15, 0.003f, 0.008f, true, (int)1, (int)2, false, 0.02f,
    // Index 6: Corresponds to PRESET_CHOICE_GAMING (value 7 from UI)
    0.8f, 99.2f, 0.9f, 0.03f, 0.1f, 1.2f, 0.6f, (int)2, 0.03f, 0.001f, true, (int)2, (int)0, false, 0.03f,    // Index 7: Corresponds to PRESET_CHOICE_VINTAGE_FILM (value 8 from UI)
    2.0f, 98.0f, 1.2f, 0.1f, 0.3f, 1.15f, 0.85f, (int)6, 0.01f, 0.004f, true, (int)2, (int)4, true, 0.12f,
};

// ============================================================================
// TEXTURES & SAMPLERS
// ============================================================================

// Texture to accumulate histogram data (used for analysis)
texture AutoLeveler_HistogramTex { Width = HISTOGRAM_TEXSIZE; Height = 1; Format = R32F; };
sampler AutoLeveler_HistogramSampler { Texture = AutoLeveler_HistogramTex; };

// Texture to store current frame's histogram (initial gathering)
texture AutoLeveler_CurrentHistogramTex { Width = HISTOGRAM_TEXSIZE; Height = 1; Format = R32F; };
sampler AutoLeveler_CurrentHistogramSampler { Texture = AutoLeveler_CurrentHistogramTex; };

// Texture to use as intermediate buffer for ping-pong rendering (avoids read/write conflict)
texture AutoLeveler_PrevHistogramTex { Width = HISTOGRAM_TEXSIZE; Height = 1; Format = R32F; };
sampler AutoLeveler_PrevHistogramSampler { Texture = AutoLeveler_PrevHistogramTex; };


// ============================================================================
// UI DECLARATIONS
// ============================================================================

// Presets
uniform int Preset < ui_type = "combo"; ui_label = "Preset"; ui_tooltip = "Choose from pre-configured settings or use Custom to manually adjust all parameters"; ui_category = "Presets"; ui_items = "Custom\0Standard Photography\0Cinematic Look\0High Contrast\0Natural Light\0Technical/Accurate\0Broadcast Safe\0Gaming\0Vintage Film\0"; > = PRESET_CUSTOM;

// Auto Leveling Controls
uniform float BlackPoint < ui_type = "slider"; ui_label = "Black Point"; ui_tooltip = "Lower luminance percentile to anchor shadows"; ui_category = "Leveling Controls"; ui_min = 0.01; ui_max = 10.0; ui_step = 0.01; > = AS_HALF;

uniform float WhitePoint < ui_type = "slider"; ui_label = "White Point"; ui_tooltip = "Upper luminance percentile to anchor highlights"; ui_category = "Leveling Controls"; ui_min = 90.0; ui_max = 99.99; ui_step = 0.01; > = 99.5;

uniform float MidtoneBias < ui_type = "slider"; ui_label = "Midtone Bias"; ui_tooltip = "Controls the gamma curve for midtone exposure balance. Values below 1.0 brighten midtones, above 1.0 darken them."; ui_category = "Leveling Controls"; ui_min = 0.1; ui_max = AS_RANGE_SCALE_MAX; ui_step = 0.01; > = AS_RANGE_SCALE_DEFAULT;

// Artistic Controls
uniform float ShadowLift < ui_type = "slider"; ui_label = "Shadow Lift"; ui_tooltip = "Minimum black level for analog look"; ui_category = "Artistic Controls"; ui_min = AS_RANGE_ZERO_ONE_MIN; ui_max = SHADOW_LIFT_MAX; ui_step = 0.01; > = AS_RANGE_ZERO_ONE_MIN;

uniform float SoftClipAmount < ui_type = "slider"; ui_label = "Soft Clip Amount"; ui_tooltip = "Controls highlight compression to avoid harsh clipping"; ui_category = "Artistic Controls"; ui_min = AS_RANGE_ZERO_ONE_MIN; ui_max = AS_RANGE_ZERO_ONE_MAX; ui_step = 0.01; > = 0.2;

uniform float ContrastAmount < ui_type = "slider"; ui_label = "Contrast"; ui_tooltip = "Contrast multiplier applied after remapping"; ui_category = "Artistic Controls"; ui_min = AS_HALF; ui_max = AS_RANGE_SCALE_MAX; ui_step = 0.01; > = AS_RANGE_SCALE_DEFAULT;

// Advanced Options
uniform float TemporalSmoothing < ui_type = "slider"; ui_label = "Temporal Smoothing"; ui_tooltip = "Controls how quickly the adjustment adapts to scene changes (higher = slower/smoother)"; ui_category = "Advanced Options"; ui_category_closed = true; ui_min = AS_RANGE_ZERO_ONE_MIN; ui_max = 0.99; ui_step = 0.01; > = 0.8;

// Transition Stability Controls
uniform int AnalysisFrequency < ui_type = "drag"; ui_label = "Analysis Frequency"; ui_tooltip = "Analyze histogram every N frames (1 = every frame, higher = less frequent updates, smoother transitions)"; ui_category = "Transition Stability"; ui_category_closed = true; ui_min = 1; ui_max = 60; ui_step = 1; > = 1;

uniform float MaxAdjustmentRate < ui_type = "slider"; ui_label = "Max Adjustment Rate"; ui_tooltip = "Restricts how quickly black/white points can change per frame (lower = smoother transitions but slower response)"; ui_category = "Transition Stability"; ui_min = 0.001; ui_max = 0.1; ui_step = 0.001; > = 0.01;

uniform float StabilityThreshold < ui_type = "slider"; ui_label = "Stability Threshold"; ui_tooltip = "Ignore small changes below this threshold (higher = more stable but less responsive)"; ui_category = "Transition Stability"; ui_min = 0.0; ui_max = 0.05; ui_step = 0.001; > = 0.002;

uniform bool EnableAdaptiveSmoothing < ui_type = "bool"; ui_label = "Enable Adaptive Smoothing"; ui_tooltip = "Dynamically adjust smoothing based on scene change magnitude"; ui_category = "Transition Stability"; > = true;

uniform int ColorPreservationMode < ui_type = "combo"; ui_label = "Color Preservation"; ui_tooltip = "Method used to preserve color information during remapping"; ui_category = "Advanced Options"; ui_items = "RGB (Basic)\0YCbCr (Perceptual)\0HSV (Saturation-aware)\0GrayWorld (Auto White Balance)\0"; > = MODE_YCBCR;

uniform int CurveType < ui_type = "combo"; ui_label = "Contrast Curve Type"; ui_tooltip = "Type of tone mapping curve to apply"; ui_category = "Advanced Options"; ui_items = "Gamma (Standard)\0Filmic S-Curve\0Piecewise Linear\0Power-Log Hybrid\0Analog Film\0"; > = CURVE_GAMMA;

uniform bool UseReferenceLuminance < ui_type = "bool"; ui_label = "Use Reference Luminance"; ui_tooltip = "Anchor tone mapping to a reference value"; ui_category = "Advanced Options"; > = false;

uniform float ReferenceLuminance < ui_type = "slider"; ui_label = "Reference Gray (%)"; ui_tooltip = "Reference luminance value (e.g., 18% gray)"; ui_category = "Advanced Options"; ui_min = 10.0; ui_max = 50.0; ui_step = 1.0; > = 18.0;

uniform float WhiteBalanceStrength < ui_type = "slider"; ui_label = "White Balance Strength"; ui_tooltip = "Strength of automatic white balance (when Gray World mode is enabled)"; ui_category = "Advanced Options"; ui_min = AS_RANGE_ZERO_ONE_MIN; ui_max = AS_RANGE_ZERO_ONE_MAX; ui_step = 0.01; > = AS_HALF;

uniform bool AutoLiftShadows < ui_type = "bool"; ui_label = "Auto Lift Shadows"; ui_tooltip = "Selectively lift only deep blacks while maintaining hue"; ui_category = "Artistic Controls"; > = false;

uniform float AutoLiftThreshold < ui_type = "slider"; ui_label = "Auto Lift Threshold"; ui_tooltip = "Luminance threshold below which shadow lifting is applied"; ui_category = "Artistic Controls"; ui_min = AS_RANGE_ZERO_ONE_MIN; ui_max = 0.2; ui_step = 0.01; > = 0.05;

uniform int HistogramQuality < ui_type = "combo"; ui_label = "Histogram Quality"; ui_tooltip = "Number of histogram bins (higher = more precise, but slower)"; ui_category = "Advanced Options"; ui_items = "64 bins (Fast)\0" "128 bins\0" "256 bins (Standard)\0" "512 bins (High Detail)\0"; > = 2; // 256 bins by default

// Debug Options
uniform int DebugMode < ui_type = "combo"; ui_label = "Debug View"; ui_tooltip = "Visualize adjustment data to fine-tune settings"; ui_category = "Debug"; ui_category_closed = true; ui_items = "Off\0Histogram\0Heatmap\0Zebra Clipping\0Split Screen\0Zone System\0"; > = DEBUG_OFF;

uniform float DebugOpacity < ui_type = "slider"; ui_label = "Debug Opacity"; ui_tooltip = "Opacity of the debug visualization"; ui_category = "Debug"; ui_min = 0.1; ui_max = AS_RANGE_OPACITY_MAX; ui_step = 0.01; > = 0.7;

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Get preset parameters based on the selected preset
LevelerParams GetPresetParameters (int activePresetChoiceFromUI)
{
    LevelerParams params; // Struct to be populated and returned

    params.BlackPoint = BlackPoint;
    params.WhitePoint = WhitePoint;
    params.MidtoneBias = MidtoneBias;
    params.ShadowLift = ShadowLift;
    params.SoftClipAmount = SoftClipAmount;
    params.ContrastAmount = ContrastAmount;
    params.TemporalSmoothing = TemporalSmoothing;
    params.AnalysisFrequency = AnalysisFrequency;
    params.MaxAdjustmentRate = MaxAdjustmentRate;
    params.StabilityThreshold = StabilityThreshold;
    params.EnableAdaptiveSmoothing = EnableAdaptiveSmoothing;
    params.ColorPreservationMode = ColorPreservationMode;
    params.CurveType = CurveType;
    params.AutoLiftShadows = AutoLiftShadows;
    params.AutoLiftThreshold = AutoLiftThreshold;

    if (activePresetChoiceFromUI != PRESET_CUSTOM) // This is 0
    {
        int staticPresetArrayIndex = (activePresetChoiceFromUI - 1) * DEF_STATIC_PARAMETERS;

        params.BlackPoint= STATIC_LEVELER_PRESETS[staticPresetArrayIndex + DEF_BLACK_POINT];
        params.WhitePoint= STATIC_LEVELER_PRESETS[staticPresetArrayIndex + DEF_WHITE_POINT];
        params.MidtoneBias= STATIC_LEVELER_PRESETS[staticPresetArrayIndex + DEF_MIDTONE_BIAS];
        params.ShadowLift= STATIC_LEVELER_PRESETS[staticPresetArrayIndex + DEF_SHADOW_LIFT];
        params.SoftClipAmount= STATIC_LEVELER_PRESETS[staticPresetArrayIndex + DEF_SOFT_CLIP];
        params.ContrastAmount= STATIC_LEVELER_PRESETS[staticPresetArrayIndex + DEF_CONTRAST];
        params.TemporalSmoothing= STATIC_LEVELER_PRESETS[staticPresetArrayIndex + DEF_SMOOTHING];
        params.AnalysisFrequency= int(STATIC_LEVELER_PRESETS[staticPresetArrayIndex + DEF_ANALYSIS_FREQ]);
        params.MaxAdjustmentRate= STATIC_LEVELER_PRESETS[staticPresetArrayIndex + DEF_ADJUST_RATE];        params.StabilityThreshold= STATIC_LEVELER_PRESETS[staticPresetArrayIndex + DEF_STABILITY];
        params.EnableAdaptiveSmoothing= (STATIC_LEVELER_PRESETS[staticPresetArrayIndex + DEF_ENABLE_ADAPTIVE] > 0.5);
        params.ColorPreservationMode= int(STATIC_LEVELER_PRESETS[staticPresetArrayIndex + DEF_COLOR_MODE]);
        params.CurveType= int(STATIC_LEVELER_PRESETS[staticPresetArrayIndex + DEF_CURVE_TYPE]);
        params.AutoLiftShadows= (STATIC_LEVELER_PRESETS[staticPresetArrayIndex + DEF_AUTO_LIFT_SHADOWS] > 0.5);
        params.AutoLiftThreshold= STATIC_LEVELER_PRESETS[staticPresetArrayIndex + DEF_LIFT_THRESHOLD];
    }

    return params;
}


// Static variables for frame tracking and transitions - moved here to ensure proper declaration before use
static float s_autoLevelerLastAnalysisTime = 0.0;
static float s_autoLevelerPrevAvgLuma = 0.0;
static float s_autoLevelerSceneDifference = 0.0;
static float s_autoLevelerAdaptiveSmoothing = 0.0;
static bool s_autoLevelerAnalyzeThisFrame = true;
static float prevBlack = 0.0;
static float prevWhite = 1.0;

// RGB to luminance using BT.709 coefficients
float Luminance(float3 color)
{
    return dot(color, float3(0.2126, 0.7152, 0.0722));
}

// Get analysis frequency value based on preset
int GetAnalysisFrequencyForPreset(int presetIndex)
{
    // Use the consolidated function to get all parameters
    LevelerParams params = GetPresetParameters(presetIndex);
    
    // Return the analysis frequency from the struct
    return params.AnalysisFrequency;
}

// Helper function to determine if the current frame should be analyzed
bool ShouldAnalyzeCurrentFrame()
{
    // Get current time and determine if we analyze this frame
    float currentTime = AS_getTime();
    float timeSinceLastAnalysis = currentTime - s_autoLevelerLastAnalysisTime;
    
    // Get analysis frequency from preset using the helper function
    int analysisFreq = GetAnalysisFrequencyForPreset(Preset);
    
    float analysisInterval = float(analysisFreq) / 60.0; // Convert to seconds (assuming default 60 fps)
    
    bool shouldAnalyze = timeSinceLastAnalysis >= analysisInterval;
    
    // Update last analysis time if analyzing this frame
    if (shouldAnalyze) {
        s_autoLevelerLastAnalysisTime = currentTime;
    }
    
    return shouldAnalyze;
}

// RGB to YCbCr conversion using BT.709 coefficients
float3 RGBtoYCbCr(float3 rgb)
{
    // These coefficient values are derived from BT.709 standard
    static const float3 kR = float3(0.2126, 0.0, 0.7152);
    static const float3 kB = float3(0.0722, 0.5, 0.0);
    static const float3 kG = float3(0.7152, -0.168736, -0.418688); // G = 1 - R - B for components
    
    float Y = Luminance(rgb);
    float Cb = AS_HALF + (-0.168736 * rgb.r - 0.331264 * rgb.g + AS_HALF * rgb.b);
    float Cr = AS_HALF + (AS_HALF * rgb.r - 0.418688 * rgb.g - 0.081312 * rgb.b);
    
    return float3(Y, Cb, Cr);
}

// YCbCr to RGB conversion
float3 YCbCrtoRGB(float3 ycbcr)
{
    float Y = ycbcr.x;
    float Cb = ycbcr.y - AS_HALF;
    float Cr = ycbcr.z - AS_HALF;
    
    float r = Y + 1.402 * Cr;
    float g = Y - 0.344136 * Cb - 0.714136 * Cr;
    float b = Y + 1.772 * Cb;
    
    return float3(r, g, b);
}

// RGB to HSV conversion
float3 RGBtoHSV(float3 rgb)
{
    float maxVal = max(max(rgb.r, rgb.g), rgb.b);
    float minVal = min(min(rgb.r, rgb.g), rgb.b);
    float delta = maxVal - minVal;
    
    float hue = 0.0;
    if (delta != 0.0)
    {
        if (maxVal == rgb.r)
        {
            hue = (rgb.g - rgb.b) / delta;
            if (hue < 0.0) hue += 6.0;
        }
        else if (maxVal == rgb.g)
            hue = 2.0 + (rgb.b - rgb.r) / delta;
        else
            hue = 4.0 + (rgb.r - rgb.g) / delta;
        
        hue /= 6.0;
    }
    
    float saturation = (maxVal == 0.0) ? 0.0 : (delta / maxVal);
    
    float value = maxVal;
    
    return float3(hue, saturation, value);
}

// HSV to RGB conversion
float3 HSVtoRGB(float3 hsv)
{
    // Using 6.0 to represent the 6 segments of the color wheel
    // This equals AS_TWO_PI / (AS_PI/3) = 6 segments
    float h = hsv.x * 6.0;
    float s = hsv.y;
    float v = hsv.z;
    
    float c = v * s;
    float x = c * (1.0 - abs(fmod(h, 2.0) - 1.0));
    float m = v - c;
    
    float3 rgb;
    if (h < 1.0)
        rgb = float3(c, x, 0.0);
    else if (h < 2.0)
        rgb = float3(x, c, 0.0);
    else if (h < 3.0)
        rgb = float3(0.0, c, x);
    else if (h < 4.0)
        rgb = float3(0.0, x, c);
    else if (h < 5.0)
        rgb = float3(x, 0.0, c);
    else
        rgb = float3(c, 0.0, x);
    
    return rgb + m;
}

// Get actual histogram bin count based on quality setting
int GetHistogramBinCount()
{
    switch (HistogramQuality)
    {
        case 0: return HIST_QUALITY_LOW;   // 64 bins
        case 1: return HIST_QUALITY_MED;   // 128 bins
        case 3: return HIST_QUALITY_HIGH;  // 512 bins
        default: return HIST_QUALITY_STD;  // 256 bins
    }
}

// Apply different types of contrast curve
float ApplyContrastCurve(float value, int curveType, float midtoneBias)
{
    float result = value;
    
    switch (curveType)
    {
        case CURVE_GAMMA:
            // Basic gamma curve
            result = pow(value, midtoneBias);
            break;        
            
        case CURVE_FILMIC_S:
            // Filmic S-curve
            float a = CURVE_S_CONTRAST; // Contrast 
            float b = CURVE_S_TOE;      // Toe strength
            float c = CURVE_S_SHOULDER; // Shoulder strength
            float d = 0.0; // Shadow offset
            float e = 0.0; // Highlight offset
            
            // Apply midtone bias
            a *= midtoneBias;
            
            // S curve function
            result = ((pow(value, a) * (b * pow(value, a) + c)) / (pow(value, a) * (b * pow(value, a) + 1.0) + d)) - e;
            // Normalize
            result = saturate(result / ((pow(1.0, a) * (b * pow(1.0, a) + c)) / (pow(1.0, a) * (b * pow(1.0, a) + 1.0) + d) - e));
            break;        
            
        case CURVE_PIECEWISE:
            // Piecewise linear curve with adjustable midpoint
            float midpoint = AS_HALF; // Use standard half-value constant
            float midpointValue = pow(midpoint, midtoneBias);
            
            if (value <= midpoint)
            {
                float a = midpointValue / midpoint;
                result = a * value;
            }
            else
            {
                float b = (1.0 - midpointValue) / (1.0 - midpoint);
                result = midpointValue + b * (value - midpoint);
            }
            break;
              
        case CURVE_POWERLOG:
            // Power-log hybrid (combo of power and log)
            float linearSection = midtoneBias * value;
            float logSection = log(1.0 + value * CURVE_POWER_FACTOR) / log(CURVE_LOG_BASE);
            
            // Blend based on input value and midtone bias
            float blendFactor = value * (CURVE_SHAPE_CTRL - midtoneBias);
            result = lerp(linearSection, logSection, saturate(blendFactor));
            break;
            
        case CURVE_ANALOG_FILM:
            // Cineon-like film curve
            float blackPoint = 0.0;
            float whitePoint = 1.0;
            float gamma = midtoneBias;
            
            // Reference white and black
            float refBlack = CINEON_BLACK / CINEON_DIVISOR;   // Standard Cineon black point
            float refWhite = CINEON_WHITE / CINEON_DIVISOR;   // Standard Cineon white point
              
            // Apply film curve
            float filmValue = (log10(max(AS_EPSILON_SAFE, value) / refBlack) / log10(refWhite / refBlack));
            result = pow(saturate(filmValue), 1.0 / gamma);
            break;
    }
    
    // Ensure valid range
    return saturate(result);
}

// Apply shadow lift with color preservation
float3 ApplyShadowLift(float3 color, float threshold, float liftAmount)
{
    // Get original luminance and HSV components
    float luma = Luminance(color);
    float3 hsv = RGBtoHSV(color);
    
    if (luma <= threshold)
    {
        // Apply progressive shadow lift - more effect closer to black
        float liftFactor = 1.0 - (luma / threshold);
        
        // Curve the lift factor to make it more gentle
        liftFactor = pow(liftFactor, 1.2);
        
        // Calculate new luminance with lift
        float newLuma = luma + (liftAmount * liftFactor * threshold);
        
        // Ensure we don't go too bright with the lifting
        newLuma = min(newLuma, threshold * 1.5);
        
        // Preserve color by just adjusting value in HSV
        hsv.z = newLuma / max(AS_EPSILON_SAFE, luma) * hsv.z;
        return HSVtoRGB(hsv);
    }
    
    return color;
}

// Find percentile value in histogram
float FindPercentile(sampler histSampler, float percentile)
{
    float totalPixels = 0.0;
    int binCount = GetHistogramBinCount();

    for (int i = 0; i < binCount; i++)
    {
        totalPixels += tex2Dfetch(histSampler, int2(i, 0)).r;
    }

    if (totalPixels <= 0.0)
        return (percentile < 50.0) ? 0.0 : 1.0;

    float targetCount = totalPixels * (percentile / 100.0);
    float accumulated = 0.0;

    for (int j = 0; j < binCount; j++)
    {
        accumulated += tex2Dfetch(histSampler, int2(j, 0)).r;
        if (accumulated >= targetCount)
            return float(j) / float(binCount - 1);
    }

    return 1.0;
}

// Ensure black and white points maintain proper dynamic range
void EnsureDynamicRange(inout float blackPoint, inout float whitePoint)
{
    // Clamp extremes to prevent aggressive stretching
    blackPoint = max(blackPoint, SAFE_BLACK_POINT);
    whitePoint = min(whitePoint, SAFE_WHITE_POINT);
    
    // Prevent histogram range collapse by ensuring minimum dynamic range
    if (whitePoint - blackPoint < MIN_DYNAMIC_RANGE)
    {
        // Prevent collapse (too narrow range)
        whitePoint = blackPoint + MIN_DYNAMIC_RANGE;
    }
}

// Draw histogram overlay for debug visualization
float3 DrawHistogramOverlay(float2 texcoord, float opacity, float blackP, float whiteP)
{
    float3 result = float3(0, 0, 0);
    
    // Define display area
    float2 histArea = float2(0.8, 0.3); // 80% width, 30% height for histogram area
    float uiPadding = 0.02; // 2% padding from screen edges
    float2 histStart = float2(1.0 - histArea.x - uiPadding, 1.0 - histArea.y - uiPadding);
    float2 histSize = histArea;
    
    // Check if pixel is within histogram area
    if (texcoord.x >= histStart.x && texcoord.x <= histStart.x + histSize.x &&
        texcoord.y >= histStart.y && texcoord.y <= histStart.y + histSize.y)
    {
        // Get relative position in histogram
        float2 relPos = (texcoord - histStart) / histSize;
        
        // Calculate histogram bin at this position
        int binCount = GetHistogramBinCount();
        int bin = int(relPos.x * binCount);
        
        // Get histogram value and normalize it
        float histogramValue = 0.0;
        float maxValue = 0.0001; // Small epsilon to avoid division by zero
        float totalCount = 0.0;
        
        // First find the maximum value for normalization
        for (int i = 0; i < binCount; i++)
        {
            float binValue = tex2Dfetch(AutoLeveler_HistogramSampler, int2(i, 0)).r;
            maxValue = max(maxValue, binValue);
            totalCount += binValue;
        }
        
        // If we have a very low count, boost maxValue for better visualization
        if (totalCount < 100.0)
            maxValue = max(maxValue, 0.01);
        
        // Get the actual value for this bin
        if (bin >= 0 && bin < binCount)
        {
            histogramValue = tex2Dfetch(AutoLeveler_HistogramSampler, int2(bin, 0)).r;
            
            // Normalize and apply gamma for better visualization
            float normalizedHeight = histogramValue / maxValue;
            float histogramGamma = 0.5;  // Compress dynamic range for better visualization
            float histogramScale = 0.95;  // Scale to leave a small margin at the top
            
            float finalHeight = pow(normalizedHeight, histogramGamma) * histogramScale;
            
            // Draw histogram bar - ensure it's visible even with low values
            if (relPos.y > 1.0 - max(finalHeight, 0.02))
            {
                result = float3(0.8, 0.8, 0.8);
            }
            
            // Draw black/white point markers
            int blackBin = int(blackP * binCount);
            int whiteBin = int(whiteP * binCount);
            
            if (abs(bin - blackBin) < 2)
                result = float3(0.0, 0.0, 1.0); // Blue for black point
                
            if (abs(bin - whiteBin) < 2)
                result = float3(1.0, 1.0, 0.0); // Yellow for white point
                
            // Background
            if (result.r == 0 && result.g == 0 && result.b == 0)
                result = float3(0.1, 0.1, 0.1);
        }
        
        // Border
        float borderThickness = 0.005; // 0.5% of histogram area is border
        if (relPos.x < borderThickness || relPos.x > (1.0 - borderThickness) ||
            relPos.y < borderThickness || relPos.y > (1.0 - borderThickness))
        {
            result = float3(AS_HALF, AS_HALF, AS_HALF);
        }
    }
    
    return result;
}

// Apply zebra stripes pattern for highlight/shadow clipping
float3 ApplyZebraPattern(float3 color, float intensity, float2 coords)
{
    // Use normalized screen coordinates for consistent pattern regardless of resolution
    float aspectRatio = float(BUFFER_WIDTH) / float(BUFFER_HEIGHT);
    float2 normalizedCoords = coords * float2(aspectRatio, 1.0);
    
    // Use AS_PI for the pattern frequency scaling
    float pattern = sin(normalizedCoords.x * 30.0 * AS_PI/AS_TWO_PI + normalizedCoords.y * 30.0 * AS_PI/AS_TWO_PI);
    pattern = (pattern > 0.0) ? 1.0 : 0.0;
    
    return lerp(color, pattern.xxx, intensity);
}

// Zone visualization for zone system display
float3 VisualizeZoneSystem(float value)
{
    value = saturate(value);
    int zone = int(value * ZONE_COUNT);
    
    float3 zoneColors[ZONE_COUNT];
    zoneColors[0] = float3(0.0, 0.0, 0.0); // Zone 0 (Black)
    zoneColors[1] = float3(0.1, 0.1, 0.1);
    zoneColors[2] = float3(0.2, 0.2, 0.2);
    zoneColors[3] = float3(0.35, 0.35, 0.35);
    zoneColors[4] = float3(AS_HALF, AS_HALF, AS_HALF);
    zoneColors[5] = float3(0.6, 0.6, 0.6); // Zone 5 (Middle Gray)
    zoneColors[6] = float3(0.7, 0.7, 0.7);
    zoneColors[7] = float3(0.8, 0.8, 0.8);
    zoneColors[8] = float3(0.9, 0.9, 0.9);
    zoneColors[9] = float3(1.0, 1.0, 1.0); // Zone 9 (White)
    
    return zoneColors[zone];
}

// Generate heat map based on adjustment intensity
float3 GenerateHeatmap(float adjustmentIntensity)
{
    // Normalize and enhance for better visibility
    float intensity = saturate(abs(adjustmentIntensity * 2.0));
      // Map to color (blue-cyan-green-yellow-red)
    float3 heatColor;
    
    if (intensity < AS_QUARTER) {
        // Blue to cyan
        float t = intensity / AS_QUARTER;
        float colorIntensity = 0.8; // Color intensity constant (0.8 of full intensity)
        heatColor = lerp(float3(0.0, 0.0, colorIntensity), float3(0.0, colorIntensity, colorIntensity), t);
    }
    else if (intensity < AS_HALF) {
        // Cyan to green
        float t = (intensity - AS_QUARTER) / AS_QUARTER;
        float colorIntensity = 0.8; // Color intensity constant (0.8 of full intensity)
        heatColor = lerp(float3(0.0, colorIntensity, colorIntensity), float3(0.0, colorIntensity, 0.0), t);
    }    else if (intensity < AS_QUARTER * 3.0) { // 0.75 - third quarter point
        // Green to yellow
        float t = (intensity - AS_HALF) / AS_QUARTER;
        float colorIntensity = 0.8; // Color intensity constant (0.8 of full intensity)
        heatColor = lerp(float3(0.0, colorIntensity, 0.0), float3(colorIntensity, colorIntensity, 0.0), t);
    }
    else {
        // Yellow to red
        float t = (intensity - (AS_QUARTER * 3.0)) / AS_QUARTER; // From 0.75 to 1.0
        float colorIntensity = 0.8; // Color intensity constant (0.8 of full intensity)
        heatColor = lerp(float3(colorIntensity, colorIntensity, 0.0), float3(colorIntensity, 0.0, 0.0), t);
    }
    
    return heatColor;
}

// Generate debug view based on selected mode
float3 GenerateDebugView(float3 originalColor, float3 adjustedColor, float blackP, float whiteP, float2 texcoord, int debugMode, float debugOpacity)
{
    float3 debugColor = adjustedColor;
    
    // Get luma values for comparison
    float origLuma = Luminance(originalColor);
    float adjLuma = Luminance(adjustedColor);
    
    // Calculate adjustment intensity (difference from original)
    float adjustmentIntensity = adjLuma - origLuma;
    
    switch(debugMode)
    {
        case DEBUG_HISTOGRAM:
        {
            // Draw histogram overlay
            float3 histogramOverlay = DrawHistogramOverlay(texcoord, debugOpacity, blackP, whiteP);
            if (any(histogramOverlay > 0.0))
            {
                debugColor = lerp(adjustedColor, histogramOverlay, debugOpacity);
            }
            break;
        }
        
        case DEBUG_HEATMAP:
        {
            // Generate heatmap based on adjustment intensity
            float3 heatColor = GenerateHeatmap(adjustmentIntensity);
            debugColor = lerp(adjustedColor, heatColor, debugOpacity * saturate(abs(adjustmentIntensity) * 5.0));
            break;
        }
          case DEBUG_ZEBRA:
        {
            // Apply zebra pattern to clipped areas
            bool isHighlightClipped = any(adjustedColor >= (1.0 - AS_EPSILON_SAFE * 10.0)); // 0.99
            bool isShadowClipped = any(adjustedColor <= (AS_EPSILON_SAFE * 10.0)); // 0.01
            
            if (isHighlightClipped)
            {
                // Red zebra for highlight clipping
                float3 zebraColor = ApplyZebraPattern(float3(1.0, 0.0, 0.0), debugOpacity, texcoord);
                debugColor = lerp(adjustedColor, zebraColor, debugOpacity);
            }
            else if (isShadowClipped)
            {
                // Blue zebra for shadow clipping
                float3 zebraColor = ApplyZebraPattern(float3(0.0, 0.0, 1.0), debugOpacity, texcoord);
                debugColor = lerp(adjustedColor, zebraColor, debugOpacity);
            }
            break;
        }
        
        case DEBUG_SPLIT:
        {
            // Split screen before/after
            if (texcoord.x < 0.5)
            {
                debugColor = originalColor;
                  // Add vertical divider
                float dividerThickness = 0.002; // 0.2% of screen width
                if (abs(texcoord.x - AS_HALF) < dividerThickness)
                {
                    debugColor = float3(1.0, 1.0, 1.0);
                }
            }
            break;
        }
        
        case DEBUG_ZONES:
        {
            // Zone system visualization
            float luma = Luminance(adjustedColor);
            float3 zoneColor = VisualizeZoneSystem(luma);
            
            // Display different zone info based on position
            if (texcoord.x < 0.33)
            {
                // Original
                debugColor = VisualizeZoneSystem(Luminance(originalColor));
                return debugColor; // Early return
            }
            else if (texcoord.x < 0.66)
            {
                // Processed
                debugColor = VisualizeZoneSystem(Luminance(adjustedColor));
                return debugColor; // Early return
            }
            else
            {
                // Normal with zone overlay
                float overlayIntensity = (luma > 0.7 || luma < 0.3) ? 0.7 : 0.4;
                debugColor = lerp(adjustedColor, zoneColor, overlayIntensity * debugOpacity);
                return debugColor; // Early return
            }
            
            // Break statement included for consistent code structure, though it's not reached due to the returns above
            break;
        }
    }
    
    return debugColor;
}

// Get adaptive smoothing configuration for the current preset
void GetAdaptiveSmoothingForPreset(int presetIndex, out bool enableAdaptive, out float smoothingAmount)
{
    // Get all parameters from our new consolidated function
    LevelerParams params = GetPresetParameters(presetIndex);
    
    // Use the values from the struct
    enableAdaptive = params.EnableAdaptiveSmoothing;
    smoothingAmount = params.TemporalSmoothing;
}

// ============================================================================
// PIXEL SHADERS
// ============================================================================

// First pass: Build histogram of current frame
float4 PS_BuildHistogram(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{    
    // Check if we should analyze the current frame using our helper function
    s_autoLevelerAnalyzeThisFrame = ShouldAnalyzeCurrentFrame();
    
    // If not analyzing this frame, return zero (skip histogram building)
    if (!s_autoLevelerAnalyzeThisFrame && GetAnalysisFrequencyForPreset(Preset) > 1)
    {
        return 0.0;
    }
    
    // Sample pixel color from backbuffer
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    
    // Convert to luminance
    float luma = Luminance(color);
    
    // Calculate the bin this pixel belongs to
    int bin = int(luma * (HISTOGRAM_BINS - 1));
    
    // Each pixel contributes to exactly one bin
    // We write to the render target where each x position represents a bin
    // Using EQUAL comparison to ensure exact bin matching
    return (int(vpos.x) == bin) ? 1.0 : 0.0;
}

// Accumulate weighted luminance instead of a single bin sample
float GetWeightedLumaAverage()
{
    float weightedSum = 0.0;
    float totalSum = 0.0;
    int binCount = GetHistogramBinCount();

    for (int i = 0; i < binCount; i++)
    {
        float binValue = tex2Dfetch(AutoLeveler_CurrentHistogramSampler, int2(i, 0)).r;
        float luma = float(i) / float(binCount - 1);
        weightedSum += binValue * luma;
        totalSum += binValue;
    }

    return (totalSum > 0.0) ? weightedSum / totalSum : 0.5;
}

// Second pass: Apply temporal smoothing to histogram
float4 PS_SmoothHistogram(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    int binIndex = int(vpos.x);
    
    // If not analyzing this frame, keep previous value
    if (!s_autoLevelerAnalyzeThisFrame && GetAnalysisFrequencyForPreset(Preset) > 1)
    {
        float previousValue = tex2Dfetch(AutoLeveler_HistogramSampler, int2(binIndex, 0)).r;
        return previousValue;
    }
    
    // Get current and previous histogram values
    float currentValue = tex2Dfetch(AutoLeveler_CurrentHistogramSampler, int2(binIndex, 0)).r;
    float previousValue = tex2Dfetch(AutoLeveler_HistogramSampler, int2(binIndex, 0)).r;
    
    // Calculate scene difference detection once (for middle bin only)
    if (binIndex == GetHistogramBinCount() / 2)
    {
        float currentAvgLuma = GetWeightedLumaAverage();
        s_autoLevelerSceneDifference = abs(currentAvgLuma - s_autoLevelerPrevAvgLuma) /
            max(max(currentAvgLuma, s_autoLevelerPrevAvgLuma), AS_EPSILON_SAFE);
        s_autoLevelerSceneDifference = saturate(s_autoLevelerSceneDifference / MAX_SCENE_DIFF);
        s_autoLevelerPrevAvgLuma = currentAvgLuma;

        bool adaptiveSmooth;
        float temporalSmooth;
        GetAdaptiveSmoothingForPreset(Preset, adaptiveSmooth, temporalSmooth);

        s_autoLevelerAdaptiveSmoothing = adaptiveSmooth
            ? lerp(temporalSmooth, MIN_SMOOTHING, s_autoLevelerSceneDifference)
            : temporalSmooth;
    }
    
    // Apply temporal smoothing using preset-specific settings
    bool useAdaptiveSmoothing;
    float baseSmoothingAmount;
    GetAdaptiveSmoothingForPreset(Preset, useAdaptiveSmoothing, baseSmoothingAmount);
    
    // Use the appropriate smoothing amount (adaptive or fixed)
    float effectiveSmoothing = useAdaptiveSmoothing ? s_autoLevelerAdaptiveSmoothing : baseSmoothingAmount;
    
    return lerp(currentValue, previousValue, effectiveSmoothing);
}

// Third pass: Copy from intermediate to final histogram texture
float4 PS_CopyHistogram(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    int binIndex = int(vpos.x);
    
    // Simply copy from the intermediate texture to the final texture
    float value = tex2Dfetch(AutoLeveler_PrevHistogramSampler, int2(binIndex, 0)).r;
    
    return value;
}

// Apply color transformation based on the selected preservation mode
float3 TransformColorWithPreservation(float3 originalColor, float normalizedLuma, int preservationMode, float whiteBalanceStrength, float2 texcoord)
{
    float3 adjustedColor;
    float luma = Luminance(originalColor);
    float3 colorRatio;
    
    switch(preservationMode)
    {
        case MODE_RGB:
            // Simple RGB ratio method
            colorRatio = (luma > AS_EPSILON_SAFE) ? originalColor / luma : 1.0;
            adjustedColor = normalizedLuma * colorRatio;
            break;
            
        case MODE_YCBCR:
            // YCbCr method (preserve chrominance)
            float3 ycbcr = RGBtoYCbCr(originalColor);
            ycbcr.x = normalizedLuma;
            adjustedColor = YCbCrtoRGB(ycbcr);
            break;
            
        case MODE_HSV:
            // HSV method (preserve hue and saturation)
            float3 hsv = RGBtoHSV(originalColor);
            hsv.z = normalizedLuma;
            adjustedColor = HSVtoRGB(hsv);
            break;
            
        case MODE_GRAYWORLD:
            // Gray world with auto white balance
            float3 avgColor = 0.0;
            
            // Look at nearby pixels for average color (simple 3x3 sampling)
            [unroll]
            for (int y = -1; y <= 1; y++) {
                [unroll]
                for (int x = -1; x <= 1; x++) {
                    float2 sampleCoord = texcoord + float2(x, y) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
                    avgColor += tex2D(ReShade::BackBuffer, sampleCoord).rgb;
                }
            }
            avgColor /= 9.0;
            
            // Calculate white balance correction factors
            float avgLuma = Luminance(avgColor);
            float3 correction = (avgLuma > AS_EPSILON_SAFE) ? avgLuma / max(float3(AS_EPSILON_SAFE, AS_EPSILON_SAFE, AS_EPSILON_SAFE), avgColor) : float3(1.0, 1.0, 1.0);
            
            // Apply white balance with user-controlled strength
            // Using float3(1.0, 1.0, 1.0) as identity vector - no correction
            float3 identityCorrection = float3(1.0, 1.0, 1.0);
            float3 balancedColor = originalColor * lerp(identityCorrection, correction, whiteBalanceStrength);
            
            // Then apply luminance adjustment with RGB ratio method
            luma = Luminance(balancedColor);
            colorRatio = (luma > AS_EPSILON_SAFE) ? balancedColor / luma : 1.0;
            adjustedColor = normalizedLuma * colorRatio;
            break;
    }
    
    return adjustedColor;
}
// Final pass: Apply auto-leveling based on histogram

float4 PS_AutoLeveler(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float3 originalColor = tex2D(ReShade::BackBuffer, texcoord).rgb;
    
    // Get preset parameters based on selected preset - this centralizes all preset handling
    LevelerParams params = GetPresetParameters(Preset);
    
    // 1. Raw black/white point from histogram percentiles
    float rawBlack = FindPercentile(AutoLeveler_HistogramSampler, params.BlackPoint);
    float rawWhite = FindPercentile(AutoLeveler_HistogramSampler, params.WhitePoint);
    
    // 2. Apply stability threshold - ignore small changes
    if (Preset != PRESET_CUSTOM) {
        if (abs(rawBlack - prevBlack) < params.StabilityThreshold)
            rawBlack = prevBlack;

        if (abs(rawWhite - prevWhite) < params.StabilityThreshold)
            rawWhite = prevWhite;
    }

        
    // 3. Apply change rate limiting (max adjustment per frame)
    float blackDiff = rawBlack - prevBlack;
    float whiteDiff = rawWhite - prevWhite;
    
    // Cap the maximum change per frame
    blackDiff = clamp(blackDiff, -params.MaxAdjustmentRate, params.MaxAdjustmentRate);
    whiteDiff = clamp(whiteDiff, -params.MaxAdjustmentRate, params.MaxAdjustmentRate);
    
    // Apply the limited change
    float limitedBlack = prevBlack + blackDiff;
    float limitedWhite = prevWhite + whiteDiff;
      
    // 4. Apply temporal smoothing to the rate-limited values
    float blackPoint;
    float whitePoint;

    float effectiveSmoothing = (Preset != PRESET_CUSTOM && params.EnableAdaptiveSmoothing)
        ? s_autoLevelerAdaptiveSmoothing
        : params.TemporalSmoothing;

    if (Preset == PRESET_CUSTOM) {
        // No smoothing — use limitedBlack/White directly
        blackPoint = limitedBlack;
        whitePoint = limitedWhite;
    } else {
        // Apply smoothing
        blackPoint = lerp(limitedBlack, prevBlack, effectiveSmoothing);
        whitePoint = lerp(limitedWhite, prevWhite, effectiveSmoothing);
    }    
    
    // 5. Update smoothed values for next frame
    prevBlack = blackPoint;
    prevWhite = whitePoint;
    
    // 6. Ensure proper dynamic range using our helper function
    EnsureDynamicRange(blackPoint, whitePoint);

    // 7. Reference luminance anchoring
    if (UseReferenceLuminance) {
        float refGray = ReferenceLuminance / 100.0;
        float currentMid = (blackPoint + whitePoint) * AS_HALF;
        float scale = refGray / max(SAFE_BLACK_POINT, currentMid);
        
        // Adjust black and white while keeping their ratio
        float range = whitePoint - blackPoint;
        blackPoint = refGray - (range * AS_HALF * scale);
        whitePoint = refGray + (range * AS_HALF * scale);
        
        // Re-clamp and ensure proper range again
        blackPoint = saturate(blackPoint);
        whitePoint = saturate(whitePoint);
        EnsureDynamicRange(blackPoint, whitePoint);
    }

    // 8. Process luminance normalization
    float luma = Luminance(originalColor);
      
    // 8a. Normalize luminance
    float normalizedLuma = (luma - blackPoint) / max(AS_EPSILON_SAFE, (whitePoint - blackPoint));
    normalizedLuma = saturate(normalizedLuma);
      
    // 8b. Apply curve and contrast
    normalizedLuma = ApplyContrastCurve(normalizedLuma, params.CurveType, params.MidtoneBias);
    normalizedLuma = saturate(pow(normalizedLuma, 1.0 / params.ContrastAmount));
    
    // 8c. Apply soft clip (highlight compression)
    if (params.SoftClipAmount > 0.0) {
        float softClipThreshold = 1.0 - params.SoftClipAmount;
        if (normalizedLuma > softClipThreshold) {
            float softClipValue = softClipThreshold + (1.0 - softClipThreshold) * 
                               (1.0 - pow(1.0 - ((normalizedLuma - softClipThreshold) / params.SoftClipAmount), 2.0));
            normalizedLuma = softClipValue;
        }
    }
      // Apply shadow lifting - either global or selective based on AutoLiftShadows
    if (!params.AutoLiftShadows) {
        // Apply global shadow lifting to all luminance values
        normalizedLuma = params.ShadowLift + normalizedLuma * (1.0 - params.ShadowLift);
    }
      
    // 9. Apply color preservation using our helper function
    float3 adjustedColor = TransformColorWithPreservation(originalColor, normalizedLuma, params.ColorPreservationMode, WhiteBalanceStrength, texcoord);

    // 10. Apply selective shadow lifting with color preservation if enabled
    if (params.AutoLiftShadows) {
        adjustedColor = ApplyShadowLift(adjustedColor, params.AutoLiftThreshold, params.ShadowLift);
    }
    
    // 11. Apply debug visualization if enabled
    if (DebugMode != DEBUG_OFF) {
        float3 debugResult = GenerateDebugView(originalColor, adjustedColor, blackPoint, whitePoint, texcoord, DebugMode, DebugOpacity);
        return float4(debugResult, 1.0);
    }

    return float4(adjustedColor, 1.0);
}

// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_GFX_AutoLeveler <
    ui_label = "[AS] GFX: Auto Leveler"; // Updated Label
    ui_tooltip = "Dynamic luminance and contrast adjustment via intelligent remapping with ready-to-use presets";
>
{    pass BuildHistogram
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_BuildHistogram;
        RenderTarget = AutoLeveler_CurrentHistogramTex;
        ClearRenderTargets = true;

        BlendEnable = true;
        BlendOp = ADD;         // Critical for histogram accumulation
        SrcBlend = ONE;
        DestBlend = ONE;
    }
    
    pass SmoothHistogram
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SmoothHistogram;
        RenderTarget = AutoLeveler_PrevHistogramTex; // Write to intermediate texture
    }
    
    pass CopyToHistogram
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyHistogram; // New shader to copy from prev to final
        RenderTarget = AutoLeveler_HistogramTex;
    }
    
    pass ApplyLeveling
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_AutoLeveler;
    }
}

#endif // __AS_GFX_AutoLeveler_1_fx
