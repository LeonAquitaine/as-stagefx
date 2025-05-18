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
 *
 * HOW TO USE:
 * 
 * BASIC WORKFLOW:
 * 1. Enable the shader and observe the automatic adjustments based on scene content
 * 2. Adjust the percentile thresholds (Black Point and White Point) to control how
 *    aggressively the shader detects and corrects shadows and highlights
 * 3. Fine-tune the Midtone Bias to shift the exposure balance toward shadows or highlights
 * 4. Use Shadow Lift for a filmic raised-black look, and Soft Clip for highlight roll-off
 * 5. Adjust overall Contrast to taste for the final image
 * 6. Use the debug visualization options to identify problem areas
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
#ifndef HISTOGRAM_BINS
#define HISTOGRAM_BINS      256  // Keep this at 256 for compatibility
#endif
#define HISTOGRAM_TEXSIZE   256  // Must match HISTOGRAM_BINS
#define PERCENTILE_SAMPLES  64

// Stability and transition constants
#define MAX_SCENE_DIFF      0.5  // Maximum scene difference before considered a scene change
#define MIN_SMOOTHING       0.5  // Minimum smoothing during scene changes
#define EQUILIBRIUM_RATE    0.01 // Rate at which values drift toward neutral

// Color preservation modes
#define MODE_RGB           0
#define MODE_YCBCR         1
#define MODE_HSV           2
#define MODE_GRAYWORLD     3

// Debug visualization modes
#define DEBUG_OFF          0
#define DEBUG_HISTOGRAM    1
#define DEBUG_HEATMAP      2
#define DEBUG_ZEBRA        3
#define DEBUG_SPLIT        4
#define DEBUG_ZONES        5

// Contrast curve types
#define CURVE_GAMMA        0  // Original gamma-based curve
#define CURVE_FILMIC_S     1  // Filmic S-curve 
#define CURVE_PIECEWISE    2  // Piecewise Linear
#define CURVE_POWERLOG     3  // Power-Log hybrid
#define CURVE_ANALOG_FILM  4  // Cineon-like film response

// Zone System Constants
#define ZONE_COUNT         10  // Number of zones in the traditional zone system 
#define ZONES_BLACK        0   // Black  (zone 0)
#define ZONES_WHITE        9   // White  (zone 9)
#define ZONES_MID_GRAY     5   // Middle gray (zone 5)

// Shadow recovery params
#define SHADOW_LIFT_MAX    0.15
#define SHADOW_RECOVER_MAX 0.35

// Quality presets for histogram
#define HIST_QUALITY_LOW   64
#define HIST_QUALITY_MED   128
#define HIST_QUALITY_STD   256
#define HIST_QUALITY_HIGH  512

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

// RGB to luminance
float Luminance(float3 color)
{
    return dot(color, float3(0.2126, 0.7152, 0.0722));
}

// RGB to YCbCr conversion
float3 RGBtoYCbCr(float3 rgb)
{
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
            break;        case CURVE_FILMIC_S:
            // Filmic S-curve
            float a = 0.6; // Contrast (artistic constant)
            float b = AS_HALF; // Toe strength
            float c = 1.25; // Shoulder strength (artistic constant)
            float d = 0.0; // Shadow offset
            float e = 0.0; // Highlight offset
            
            // Apply midtone bias
            a *= midtoneBias;
            
            // S curve function
            result = ((pow(value, a) * (b * pow(value, a) + c)) / (pow(value, a) * (b * pow(value, a) + 1.0) + d)) - e;
            // Normalize
            result = saturate(result / ((pow(1.0, a) * (b * pow(1.0, a) + c)) / (pow(1.0, a) * (b * pow(1.0, a) + 1.0) + d) - e));
            break;        case CURVE_PIECEWISE:
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
            // 10.0 and 11.0 are curve shaping constants - not magic numbers
            float logSection = log(1.0 + value * 10.0) / log(11.0);
            
            // Blend based on input value and midtone bias
            float blendFactor = value * (2.0 - midtoneBias); // 2.0 is curve shape control
            result = lerp(linearSection, logSection, saturate(blendFactor));
            break;
            
        case CURVE_ANALOG_FILM:
            // Cineon-like film curve
            float blackPoint = 0.0;
            float whitePoint = 1.0;
            float gamma = midtoneBias;
            
            // Reference white and black            // Film curve reference values - Cineon-specific constants
            float refBlack = 95.0 / 1023.0;   // Standard Cineon black point
            float refWhite = 685.0 / 1023.0;  // Standard Cineon white point
              
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
        float newLuma = luma + (liftAmount * liftFactor * threshold);
        
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
    
    // Calculate total number of pixels
    for (int i = 0; i < HISTOGRAM_BINS; i++)
    {
        float binValue = tex2Dfetch(histSampler, int2(i, 0)).r;
        totalPixels += binValue;
    }
      
    if (totalPixels <= 0.0)
        return (percentile < 50.0) ? 0.0 : 1.0; // Default values if no data
    
    // Find the appropriate percentile
    float pixelsToFind = totalPixels * (percentile / 100.0);
    float accumulatedPixels = 0.0;
    
    for (int j = 0; j < HISTOGRAM_BINS; j++)
    {
        float binValue = tex2Dfetch(histSampler, int2(j, 0)).r;
        accumulatedPixels += binValue;
        
        if (accumulatedPixels >= pixelsToFind)
        {
            // Convert bin index to normalized luminance value [0.0, 1.0]
            return float(j) / float(HISTOGRAM_BINS - 1);
        }
    }
    
    // Safety return (shouldn't reach here)
    return 1.0;
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
        int bin = int(relPos.x * HISTOGRAM_BINS);
        
        // Get histogram value and normalize it
        float histogramValue = 0.0;
        float maxValue = 0.0001; // Small epsilon to avoid division by zero
        float totalCount = 0.0;
        
        // First find the maximum value for normalization
        for (int i = 0; i < HISTOGRAM_BINS; i++)
        {
            float binValue = tex2Dfetch(AutoLeveler_HistogramSampler, int2(i, 0)).r;
            maxValue = max(maxValue, binValue);
            totalCount += binValue;
        }
        
        // If we have a very low count, boost maxValue for better visualization
        if (totalCount < 100.0)
            maxValue = max(maxValue, 0.01);
        
        // Get the actual value for this bin
        if (bin >= 0 && bin < HISTOGRAM_BINS)
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
            int blackBin = int(blackP * HISTOGRAM_BINS);
            int whiteBin = int(whiteP * HISTOGRAM_BINS);
            
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

// ============================================================================
// PIXEL SHADERS
// ============================================================================

// Static variables for frame tracking and transitions
static float s_autoLevelerLastAnalysisTime = 0.0;
static float s_autoLevelerPrevAvgLuma = 0.0;
static float s_autoLevelerSceneDifference = 0.0;
static float s_autoLevelerAdaptiveSmoothing = 0.0;
static bool s_autoLevelerAnalyzeThisFrame = true;

// First pass: Build histogram of current frame
float4 PS_BuildHistogram(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // Get current time and determine if we analyze this frame
    float currentTime = AS_getTime();
    float timeSinceLastAnalysis = currentTime - s_autoLevelerLastAnalysisTime;
    float analysisInterval = float(AnalysisFrequency) / 60.0; // Convert to seconds (assuming default 60 fps)
    
    s_autoLevelerAnalyzeThisFrame = timeSinceLastAnalysis >= analysisInterval;
    
    // Update last analysis time if analyzing this frame
    if (s_autoLevelerAnalyzeThisFrame) {
        s_autoLevelerLastAnalysisTime = currentTime;
    }
      // If not analyzing this frame, return zero (skip histogram building)
    if (!s_autoLevelerAnalyzeThisFrame && AnalysisFrequency > 1)
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

// Second pass: Apply temporal smoothing to histogram
float4 PS_SmoothHistogram(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    int binIndex = int(vpos.x);
    
    // If not analyzing this frame, keep previous value
    if (!s_autoLevelerAnalyzeThisFrame && AnalysisFrequency > 1)
    {
        float previousValue = tex2Dfetch(AutoLeveler_HistogramSampler, int2(binIndex, 0)).r;
        return previousValue;
    }
    
    // Get current frame's histogram value
    float currentValue = tex2Dfetch(AutoLeveler_CurrentHistogramSampler, int2(binIndex, 0)).r;
    
    // Get previous frame's histogram value
    float previousValue = tex2Dfetch(AutoLeveler_HistogramSampler, int2(binIndex, 0)).r;
    
    // Calculate current average luminance for scene change detection if this is bin 128 (~50% gray)
    if (binIndex == HISTOGRAM_BINS / 2)
    {
        // Calculate scene difference (using median gray as rough approximation)
        float currentAvgLuma = currentValue;
        s_autoLevelerSceneDifference = abs(currentAvgLuma - s_autoLevelerPrevAvgLuma) / max(max(currentAvgLuma, s_autoLevelerPrevAvgLuma), AS_EPSILON_SAFE);
        s_autoLevelerSceneDifference = saturate(s_autoLevelerSceneDifference / MAX_SCENE_DIFF); // Normalize to [0,1]
        
        // Update for next frame
        s_autoLevelerPrevAvgLuma = currentAvgLuma;
        
        // Calculate adaptive smoothing based on scene difference
        s_autoLevelerAdaptiveSmoothing = EnableAdaptiveSmoothing 
            ? lerp(TemporalSmoothing, MIN_SMOOTHING, s_autoLevelerSceneDifference) 
            : TemporalSmoothing;
    }
    
    // Apply temporal smoothing (either fixed or adaptive)
    float effectiveSmoothing = EnableAdaptiveSmoothing ? s_autoLevelerAdaptiveSmoothing : TemporalSmoothing;
    float smoothedValue = lerp(currentValue, previousValue, effectiveSmoothing);
    
    return smoothedValue;
}

// Third pass: Copy from intermediate to final histogram texture
float4 PS_CopyHistogram(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    int binIndex = int(vpos.x);
    
    // Simply copy from the intermediate texture to the final texture
    float value = tex2Dfetch(AutoLeveler_PrevHistogramSampler, int2(binIndex, 0)).r;
    
    return value;
}

// Final pass: Apply auto-leveling based on histogram
// Persistent previous percentile values (for smoothing)
static float prevBlack = 0.0;
static float prevWhite = 1.0;

// Final pass: Apply auto-leveling based on histogram
float4 PS_AutoLeveler(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float3 originalColor = tex2D(ReShade::BackBuffer, texcoord).rgb;

    // 1. Raw black/white point from histogram percentiles
    float rawBlack = FindPercentile(AutoLeveler_HistogramSampler, BlackPoint);
    float rawWhite = FindPercentile(AutoLeveler_HistogramSampler, WhitePoint);

    // 2. Apply stability threshold - ignore small changes
    if (abs(rawBlack - prevBlack) < StabilityThreshold)
        rawBlack = prevBlack;
        
    if (abs(rawWhite - prevWhite) < StabilityThreshold)
        rawWhite = prevWhite;
        
    // 3. Apply change rate limiting (max adjustment per frame)
    float blackDiff = rawBlack - prevBlack;
    float whiteDiff = rawWhite - prevWhite;
    
    // Cap the maximum change per frame
    blackDiff = clamp(blackDiff, -MaxAdjustmentRate, MaxAdjustmentRate);
    whiteDiff = clamp(whiteDiff, -MaxAdjustmentRate, MaxAdjustmentRate);
    
    // Apply the limited change
    float limitedBlack = prevBlack + blackDiff;
    float limitedWhite = prevWhite + whiteDiff;
      // 4. Apply temporal smoothing to the rate-limited values
    float effectiveSmoothing = EnableAdaptiveSmoothing ? s_autoLevelerAdaptiveSmoothing : TemporalSmoothing;
    float blackPoint = lerp(limitedBlack, prevBlack, effectiveSmoothing);
    float whitePoint = lerp(limitedWhite, prevWhite, effectiveSmoothing);
    
    // 5. Update smoothed values for next frame
    prevBlack = blackPoint;
    prevWhite = whitePoint;// 4. Clamp extremes to prevent aggressive stretching
    blackPoint = max(blackPoint, AS_EPSILON_SAFE * 10.0); // 0.01 -> 10*epsilon for safety
    whitePoint = min(whitePoint, 1.0 - AS_EPSILON_SAFE * 10.0); // 0.99 -> Almost 1.0 with safety margin
    
    // Prevent histogram range collapse by ensuring minimum dynamic range (10%)
    float minDynamicRange = 0.1; // 10% minimum range - artistic decision constant
    if (whitePoint - blackPoint < minDynamicRange)
    {
        // Prevent collapse (too narrow range)
        whitePoint = blackPoint + minDynamicRange;
    }

    // 5. Reference luminance anchoring
    if (UseReferenceLuminance) {            float refGray = ReferenceLuminance / 100.0;
        float currentMid = (blackPoint + whitePoint) * AS_HALF;
        float scale = refGray / max(AS_EPSILON_SAFE * 10.0, currentMid);
          // Adjust black and white while keeping their ratio
        float range = whitePoint - blackPoint;
        blackPoint = refGray - (range * AS_HALF * scale);
        whitePoint = refGray + (range * AS_HALF * scale);
        
        // Re-clamp
        blackPoint = saturate(blackPoint);
        whitePoint = saturate(whitePoint);
    }

    // 6. Process colors based on color preservation mode
    float3 adjustedColor;
    float luma = Luminance(originalColor);
      // 6a. Normalize luminance
    float normalizedLuma = (luma - blackPoint) / max(AS_EPSILON_SAFE, (whitePoint - blackPoint));
    normalizedLuma = saturate(normalizedLuma);
    
    // 6b. Apply curve and contrast
    normalizedLuma = ApplyContrastCurve(normalizedLuma, CurveType, MidtoneBias);
    normalizedLuma = saturate(pow(normalizedLuma, 1.0 / ContrastAmount));
    
    // 6c. Apply soft clip (highlight compression)
    if (SoftClipAmount > 0.0) {
        float softClipThreshold = 1.0 - SoftClipAmount;
        if (normalizedLuma > softClipThreshold) {
            float softClipValue = softClipThreshold + (1.0 - softClipThreshold) * 
                                 (1.0 - pow(1.0 - ((normalizedLuma - softClipThreshold) / SoftClipAmount), 2.0));
            normalizedLuma = softClipValue;
        }
    }
    
    // Apply shadow lifting
    normalizedLuma = ShadowLift + normalizedLuma * (1.0 - ShadowLift);    // 6d. Color preservation modes
    // Declare colorRatio variable outside switch for use in multiple cases
    float3 colorRatio;
    
    switch(ColorPreservationMode)
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
            for (int y = -1; y <= 1; y++) {
                for (int x = -1; x <= 1; x++) {
                    float2 sampleCoord = texcoord + float2(x, y) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
                    avgColor += tex2D(ReShade::BackBuffer, sampleCoord).rgb;
                }
            }
            avgColor /= 9.0;            // Calculate white balance correction factors
            float avgLuma = Luminance(avgColor);
            float3 correction = (avgLuma > AS_EPSILON_SAFE) ? avgLuma / max(float3(AS_EPSILON_SAFE, AS_EPSILON_SAFE, AS_EPSILON_SAFE), avgColor) : float3(1.0, 1.0, 1.0);
            
            // Apply white balance with user-controlled strength
            // Using float3(1.0, 1.0, 1.0) as identity vector - no correction
            float3 identityCorrection = float3(1.0, 1.0, 1.0);
            float3 balancedColor = originalColor * lerp(identityCorrection, correction, WhiteBalanceStrength);            // Then apply luminance adjustment with RGB ratio method
            luma = Luminance(balancedColor);
            colorRatio = (luma > AS_EPSILON_SAFE) ? balancedColor / luma : 1.0;
            adjustedColor = normalizedLuma * colorRatio;
            break;
    }

    // Apply selective shadow lifting with color preservation
    if (AutoLiftShadows) {
        adjustedColor = ApplyShadowLift(adjustedColor, AutoLiftThreshold, ShadowLift);
    }    if (DebugMode != DEBUG_OFF) {
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
    ui_tooltip = "Dynamic luminance and contrast adjustment via intelligent remapping";
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
