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
 *
 * PARAMETER DETAILS:
 * - Black Point: Lower percentile of luminance to map to black (higher = darker shadows)
 * - White Point: Upper percentile of luminance to map to white (lower = brighter highlights)
 * - Midtone Bias: Controls the curve's gamma for midtone exposure balance
 * - Shadow Lift: Raises the black floor for a filmic/analog look
 * - Soft Clip Amount: Controls highlight compression to avoid harsh clipping
 * - Contrast: Final contrast multiplier applied after remapping
 * - Temporal Smoothing: How quickly adjustment adapts to scene changes
 * - Color Preservation: Color handling during remapping
 *
 * ADVANCED TIPS:
 * - Use lower percentiles (0.1%) for subtle adjustment, higher (5-10%) for dramatic effect
 * - For cinematic look: Increase Shadow Lift (0.05-0.1) and moderate Soft Clip (0.2-0.3)
 * - For technical accuracy: Use minimal Shadow Lift (0) and Soft Clip (0-0.1)
 * - Midtone Bias below 1.0 brightens midtones, above 1.0 darkens them
 * - Turn on heatmap debug view to see where adjustments are most significant
 * - For video, use higher temporal smoothing (0.9+) to avoid flickering
 *
 * FEATURES:
 * - Dynamic percentile-based black and white point detection
 * - Gamma-aware midtone correction with artistic control
 * - Soft shoulder roll-off for highlight preservation
 * - Shadow lifting for filmic/analog aesthetics
 * - Temporal smoothing for stable video application
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
#define HISTOGRAM_BINS      256
#endif
#define HISTOGRAM_TEXSIZE   HISTOGRAM_BINS
#define PERCENTILE_SAMPLES  64

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
texture HistogramTex { Width = HISTOGRAM_TEXSIZE; Height = 1; Format = R32F; };
sampler HistogramSampler { Texture = HistogramTex; };

// Texture to store current frame's histogram (initial gathering)
texture CurrentHistogramTex { Width = HISTOGRAM_TEXSIZE; Height = 1; Format = R32F; };
sampler CurrentHistogramSampler { Texture = CurrentHistogramTex; };

// Texture to use as intermediate buffer for ping-pong rendering (avoids read/write conflict)
texture PrevHistogramTex { Width = HISTOGRAM_TEXSIZE; Height = 1; Format = R32F; };
sampler PrevHistogramSampler { Texture = PrevHistogramTex; };

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// Auto Leveling Controls
uniform float BlackPoint < 
    ui_type = "slider";
    ui_label = "Black Point";
    ui_tooltip = "Lower luminance percentile to anchor shadows";
    ui_category = "Leveling Controls";
    ui_min = 0.01; ui_max = 10.0; ui_step = 0.01;
> = 0.5;

uniform float WhitePoint < 
    ui_type = "slider";
    ui_label = "White Point";
    ui_tooltip = "Upper luminance percentile to anchor highlights";
    ui_category = "Leveling Controls";
    ui_min = 90.0; ui_max = 99.99; ui_step = 0.01;
> = 99.5;

uniform float MidtoneBias < 
    ui_type = "slider";
    ui_label = "Midtone Bias";
    ui_tooltip = "Controls the gamma curve for midtone exposure balance. Values below 1.0 brighten midtones, above 1.0 darken them.";
    ui_category = "Leveling Controls";
    ui_min = 0.1; ui_max = 2.0; ui_step = 0.01;
> = 1.0;

// Artistic Controls
uniform float ShadowLift < 
    ui_type = "slider";
    ui_label = "Shadow Lift";
    ui_tooltip = "Minimum black level for analog look";
    ui_category = "Artistic Controls";
    ui_min = 0.0; ui_max = 0.3; ui_step = 0.01;
> = 0.0;

uniform float SoftClipAmount < 
    ui_type = "slider";
    ui_label = "Soft Clip Amount";
    ui_tooltip = "Controls highlight compression to avoid harsh clipping";
    ui_category = "Artistic Controls";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
> = 0.2;

uniform float ContrastAmount < 
    ui_type = "slider";
    ui_label = "Contrast";
    ui_tooltip = "Contrast multiplier applied after remapping";
    ui_category = "Artistic Controls";
    ui_min = 0.5; ui_max = 2.0; ui_step = 0.01;
> = 1.0;

// Advanced Options
uniform float TemporalSmoothing < 
    ui_type = "slider";
    ui_label = "Temporal Smoothing";
    ui_tooltip = "Controls how quickly the adjustment adapts to scene changes (higher = slower/smoother)";
    ui_category = "Advanced Options";
    ui_category_closed = true;
    ui_min = 0.0; ui_max = 0.99; ui_step = 0.01;
> = 0.8;

uniform int ColorPreservationMode < 
    ui_type = "combo";
    ui_label = "Color Preservation";
    ui_tooltip = "Method used to preserve color information during remapping";
    ui_category = "Advanced Options";
    ui_items = "RGB (Basic)\0YCbCr (Perceptual)\0HSV (Saturation-aware)\0GrayWorld (Auto White Balance)\0";
> = MODE_YCBCR;

uniform int CurveType < 
    ui_type = "combo";
    ui_label = "Contrast Curve Type";
    ui_tooltip = "Type of tone mapping curve to apply";
    ui_category = "Advanced Options";
    ui_items = "Gamma (Standard)\0Filmic S-Curve\0Piecewise Linear\0Power-Log Hybrid\0Analog Film\0";
> = CURVE_GAMMA;

uniform bool UseReferenceLuminance < 
    ui_type = "bool";
    ui_label = "Use Reference Luminance";
    ui_tooltip = "Anchor tone mapping to a reference value";
    ui_category = "Advanced Options";
> = false;

uniform float ReferenceLuminance < 
    ui_type = "slider";
    ui_label = "Reference Gray (%)";
    ui_tooltip = "Reference luminance value (e.g., 18% gray)";
    ui_category = "Advanced Options";
    ui_min = 10.0; ui_max = 50.0; ui_step = 1.0;
> = 18.0;

uniform float WhiteBalanceStrength < 
    ui_type = "slider";
    ui_label = "White Balance Strength";
    ui_tooltip = "Strength of automatic white balance (when Gray World mode is enabled)";
    ui_category = "Advanced Options";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
> = 0.5;

uniform bool AutoLiftShadows < 
    ui_type = "bool";
    ui_label = "Auto Lift Shadows";
    ui_tooltip = "Selectively lift only deep blacks while maintaining hue";
    ui_category = "Artistic Controls";
> = false;

uniform float AutoLiftThreshold < 
    ui_type = "slider";
    ui_label = "Auto Lift Threshold";
    ui_tooltip = "Luminance threshold below which shadow lifting is applied";
    ui_category = "Artistic Controls";
    ui_min = 0.0; ui_max = 0.2; ui_step = 0.01;
> = 0.05;

uniform int HistogramQuality < 
    ui_type = "combo";
    ui_label = "Histogram Quality";
    ui_tooltip = "Number of histogram bins (higher = more precise, but slower)";
    ui_category = "Advanced Options";
    ui_items = "64 bins (Fast)\0" "128 bins\0" "256 bins (Standard)\0" "512 bins (High Detail)\0";
> = 2; // 256 bins by default

// Debug Options
uniform int DebugMode < 
    ui_type = "combo";
    ui_label = "Debug View";
    ui_tooltip = "Visualize adjustment data to fine-tune settings";
    ui_category = "Debug";
    ui_category_closed = true;
    ui_items = "Off\0Histogram\0Heatmap\0Zebra Clipping\0Split Screen\0Zone System\0";
> = DEBUG_OFF;

uniform float DebugOpacity < 
    ui_type = "slider";
    ui_label = "Debug Opacity";
    ui_tooltip = "Opacity of the debug visualization";
    ui_category = "Debug";
    ui_min = 0.1; ui_max = 1.0; ui_step = 0.01;
> = 0.7;

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
    float Cb = 0.5 + (-0.168736 * rgb.r - 0.331264 * rgb.g + 0.5 * rgb.b);
    float Cr = 0.5 + (0.5 * rgb.r - 0.418688 * rgb.g - 0.081312 * rgb.b);
    
    return float3(Y, Cb, Cr);
}

// YCbCr to RGB conversion
float3 YCbCrtoRGB(float3 YCbCr)
{
    float Y = YCbCr.x;
    float Cb = YCbCr.y - 0.5;
    float Cr = YCbCr.z - 0.5;
    
    float r = Y + 1.402 * Cr;
    float g = Y - 0.344136 * Cb - 0.714136 * Cr;
    float b = Y + 1.772 * Cb;
    
    return float3(r, g, b);
}

// RGB to HSV conversion
float3 RGBtoHSV(float3 rgb)
{
    float Cmax = max(max(rgb.r, rgb.g), rgb.b);
    float Cmin = min(min(rgb.r, rgb.g), rgb.b);
    float delta = Cmax - Cmin;
    
    float H = 0;
    if (delta > 0.0)
    {
        if (Cmax == rgb.r)
            H = frac((rgb.g - rgb.b) / delta / 6.0 + 1.0);
        else if (Cmax == rgb.g)
            H = (rgb.b - rgb.r) / delta / 6.0 + 1.0/3.0;
        else
            H = (rgb.r - rgb.g) / delta / 6.0 + 2.0/3.0;
    }
    
    float S = (Cmax > 0.0) ? delta / Cmax : 0.0;
    float V = Cmax;
    
    return float3(H, S, V);
}

// HSV to RGB conversion
float3 HSVtoRGB(float3 hsv)
{
    float H = hsv.x;
    float S = hsv.y;
    float V = hsv.z;
    
    float C = V * S;    float X = C * (1.0 - abs(AS_mod(H * 6.0, 2.0) - 1.0));
    float m = V - C;
    
    float3 rgb;
    if (H < 1.0/6.0)
        rgb = float3(C, X, 0);
    else if (H < 2.0/6.0)
        rgb = float3(X, C, 0);
    else if (H < 3.0/6.0)
        rgb = float3(0, C, X);
    else if (H < 4.0/6.0)
        rgb = float3(0, X, C);
    else if (H < 5.0/6.0)
        rgb = float3(X, 0, C);
    else
        rgb = float3(C, 0, X);
    
    return rgb + m;
}

// Applies a filmic S-curve transformation
float ApplyFilmicSCurve(float x) {
    const float a = 0.1; // Toe strength
    const float b = 0.6; // Linear section length
    const float c = 0.9; // Shoulder strength
    const float d = 0.2; // Black crushing
    const float e = 0.1; // White rolloff
      // Toe section (bottom of S-curve)
    float toe = a * pow(x, 2.0);
    
    // Mid section
    float linearSection = b * x;
    
    // Shoulder section (top of S-curve)
    float shoulder = 1.0 - c * pow(1.0 - x, 2.0);
    
    // Blend between sections based on input value
    float result = 0.0;
    if (x < d) {
        // Black crush and toe region
        result = lerp(0.0, toe, smoothstep(0.0, d, x));
    }
    else if (x < (1.0 - e)) {        // Mid region (blend toe and shoulder)
        float t = smoothstep(d, 1.0 - e, x);
        result = lerp(toe, lerp(linearSection, shoulder, smoothstep(0.3, 0.7, x)), t);
    }
    else {
        // White rolloff region
        result = lerp(shoulder, 1.0, smoothstep(1.0 - e, 1.0, x));
    }
    
    return result;
}

// Applies piecewise linear curve (more precise control)
float ApplyPiecewiseLinear(float x) {
    // Zone anchors (can be expanded for more control points)
    const float anchors[4] = { 0.0, 0.25, 0.7, 1.0 };    // Input values
    const float targets[4] = { 0.0, 0.3, 0.8, 1.0 };     // Output targets
    
    // Find which segment we're in
    int segment = 0;
    for (int i = 0; i < 3; i++) {
        if (x > anchors[i]) segment = i;
    }
    
    // Normalize position within segment
    float t = (x - anchors[segment]) / max(0.001, anchors[segment + 1] - anchors[segment]);
    
    // Linear interpolation within segment
    return lerp(targets[segment], targets[segment + 1], t);
}

// Power-Log hybrid curve (more natural highlight rolloff)
float ApplyPowerLog(float x) {
    const float pivot = 0.5;    // Transition point from power to log
    const float power = 1.5;    // Power curve exponent (lower = brighter mids)
    const float scale = 0.5;    // Log curve scale
    
    float result;
    if (x < pivot) {
        // Power curve for shadows/mids
        result = pow(x / pivot, power) * pivot;
    } else {
        // Log curve for highlights
        result = pivot + scale * log10(1.0 + 10.0 * (x - pivot) / (1.0 - pivot));
    }
    
    return saturate(result);
}

// Analog film curve (Cineon-like)
float ApplyAnalogFilm(float x) {
    // Film response parameters
    const float blackPoint = 0.0;
    const float midPoint = 0.18;    // 18% middle gray
    const float whitePoint = 0.9;   // 90% white
    const float gammaCorr = 2.2;    // Film gamma
    const float contrast = 1.2;     // Film contrast
    
    // Log transform with film-like parameters
    float linearized = pow(max(0.0, x), gammaCorr);
    float mapped = (log10(linearized + 0.00001) - log10(blackPoint + 0.00001)) / 
                  (log10(whitePoint + 0.00001) - log10(blackPoint + 0.00001));
    
    // Apply contrast and remap to output range
    mapped = pow(saturate(mapped), 1.0 / contrast);
    return saturate(mapped);
}

// Apply appropriate tone curve based on selected curve type
float ApplyToneCurve(float value, float blackPoint, float whitePoint, float midtoneBias, 
                     float shadowLift, float softClip, int curveType) {
    // Normalize the value between black and white points
    float normalizedValue = saturate((value - blackPoint) / max(0.001, whitePoint - blackPoint));
    
    // Apply selected curve type
    float midCorrected = 0.0;
    switch (curveType) {
        case CURVE_FILMIC_S:
            midCorrected = ApplyFilmicSCurve(normalizedValue);
            break;
            
        case CURVE_PIECEWISE:
            midCorrected = ApplyPiecewiseLinear(normalizedValue);
            break;
            
        case CURVE_POWERLOG:
            midCorrected = ApplyPowerLog(normalizedValue);
            break;
            
        case CURVE_ANALOG_FILM:
            midCorrected = ApplyAnalogFilm(normalizedValue);
            break;
            
        default: // CURVE_GAMMA (original method)
            // Apply midtone bias (gamma correction)
            midCorrected = pow(normalizedValue, 1.0 / max(0.001, midtoneBias));
            break;
    }
    
    // Apply shadow lift
    float liftedValue = lerp(midCorrected, 1.0, shadowLift);
    
    // Apply soft clipping to highlights using a smooth curve
    float softClipStart = 1.0 - softClip;
    float softClipped = liftedValue;
    if (softClip > 0.0 && liftedValue > softClipStart) {
        float clipAmount = (liftedValue - softClipStart) / max(0.001, softClip);
        float compression = 1.0 - pow(1.0 - clipAmount, 2.0);
        softClipped = softClipStart + clipAmount * (1.0 - compression) * softClip;
    }
    
    return softClipped;
}

// Advanced shadow lifting with color preservation
float3 ApplyShadowLift(float3 color, float threshold, float shadowLift) {
    // Get luminance for this pixel
    float luma = Luminance(color);
    
    // Calculate lift amount that tapers off above the threshold
    // (more lift for darker pixels, no lift above threshold)
    float liftAmount = saturate(1.0 - luma / max(0.001, threshold));
    float finalLift = shadowLift * liftAmount;
    
    // Calculate lift color that maintains original hue
    float3 liftColor;
    if (luma < 0.001) {
        // For very dark pixels, use neutral gray lift
        liftColor = float3(0.5, 0.5, 0.5);
    } else {
        // Otherwise preserve color at reduced saturation
        float3 normalizedColor = color / max(0.001, luma);
        // Reduce saturation for lifted shadows (desaturated shadows look more natural)
        float3 desaturated = lerp(float3(1.0, 1.0, 1.0), normalizedColor, 0.7);
        liftColor = desaturated * finalLift;
    }
    
    // Apply lift to original color
    return color + liftColor * finalLift;
}

// Find the percentile value from a histogram
float FindPercentile(sampler histSampler, float percentile)
{
    float totalSum = 0.0;
    
    // First, get the sum of all histogram values
    for (int i = 0; i < HISTOGRAM_BINS; i++)
    {
        float binValue = tex2Dfetch(histSampler, int2(i, 0)).r;
        totalSum += binValue;
    }
    
    // If the histogram is empty, return default values
    if (totalSum <= 0.0)
    {
        return (percentile < 50.0) ? 0.0 : 1.0;
    }
    
    // Target count for the specified percentile
    float targetCount = totalSum * saturate(percentile / 100.0);
    float currentCount = 0.0;
    
    // Find the bin that hits or exceeds the target count
    for (int i = 0; i < HISTOGRAM_BINS; i++)
    {
        float binValue = tex2Dfetch(histSampler, int2(i, 0)).r;
        currentCount += binValue;
        
        if (currentCount >= targetCount)
        {
            // Convert bin index to luminance value
            return float(i) / float(HISTOGRAM_BINS - 1);
        }
    }
    
    // Default to white if we somehow didn't find it
    return 1.0;
}

// Convert luminance to Zone System zone (0-9)
int LuminanceToZone(float luminance) {
    // Map 0-1 luminance to zones 0-9
    int zone = int(round(luminance * float(ZONE_COUNT - 1)));
    return clamp(zone, 0, ZONE_COUNT - 1);
}

// Get zone color for visualization
float3 GetZoneColor(int zone) {
    // Define zone system colors - Note that we're using 10 zones (0-9)
    const float3 zoneColors[ZONE_COUNT] = {
        float3(0.0, 0.0, 0.0),      // Zone 0 - Pure black
        float3(0.1, 0.1, 0.1),      // Zone 1 - Near black
        float3(0.2, 0.2, 0.25),     // Zone 2 - Very dark
        float3(0.3, 0.3, 0.35),     // Zone 3 - Dark
        float3(0.4, 0.4, 0.45),     // Zone 4 - Dark-mid
        float3(0.5, 0.5, 0.5),      // Zone 5 - Middle gray (18%)
        float3(0.6, 0.6, 0.55),     // Zone 6 - Light-mid
        float3(0.75, 0.75, 0.7),    // Zone 7 - Light
        float3(0.9, 0.9, 0.85),     // Zone 8 - Very light
        float3(1.0, 1.0, 1.0)       // Zone 9 - Pure white
    };
    
    return zoneColors[zone];
}

// Generate debug visualization
float4 GenerateDebugView(float3 originalColor, float3 adjustedColor, float blackPoint, float whitePoint, 
                        float2 texcoord, int mode, float opacity) {
    float3 debugColor = adjustedColor;
    
    switch (mode) {
case DEBUG_HISTOGRAM: {
    if (texcoord.y > 0.7) {
        float histY = (texcoord.y - 0.7) / 0.3;
        int binIndex = int(texcoord.x * (HISTOGRAM_BINS - 1));

        // Compute max bin value to normalize histogram
        float maxBinValue = 0.00001;
        for (int i = 0; i < HISTOGRAM_BINS; ++i) {
            float binVal = tex2Dfetch(HistogramSampler, int2(i, 0)).r;
            maxBinValue = max(maxBinValue, binVal);
        }

        // Fetch current bin value
        float binValue = tex2Dfetch(HistogramSampler, int2(binIndex, 0)).r;
        float normalizedValue = saturate(binValue / maxBinValue);

        float barHeight = normalizedValue * 0.8;
        float barColor = 0.2 + 0.8 * normalizedValue;

        if (histY < barHeight) {
            debugColor = float3(barColor, barColor, barColor);
        } else {
            debugColor = float3(0.05, 0.05, 0.05);
        }

        // Visual overlays
        float bpX = blackPoint;
        float wpX = whitePoint;
        float refX = ReferenceLuminance / 100.0;

        if (abs(texcoord.x - bpX) < 0.002)
            debugColor = float3(0.0, 0.0, 1.0); // Blue for black point
        else if (abs(texcoord.x - wpX) < 0.002)
            debugColor = float3(1.0, 0.0, 0.0); // Red for white point
        else if (UseReferenceLuminance && abs(texcoord.x - refX) < 0.002)
            debugColor = float3(0.0, 1.0, 0.0); // Green for reference point

        return float4(lerp(adjustedColor, debugColor, opacity), 1.0);
    }
    return float4(adjustedColor, 1.0);
}
        
        case DEBUG_HEATMAP: {
            // Create a heatmap showing where adjustments are strongest
            float origLuma = Luminance(originalColor);
            float adjustedLuma = Luminance(adjustedColor);
            float diff = abs(adjustedLuma - origLuma);
            float normalizedDiff = saturate(diff * 5.0); // Scale for visibility
            
            float3 heatColor;
            if (normalizedDiff < 0.2)
                heatColor = lerp(float3(0,0,0), float3(0,0,1), normalizedDiff * 5.0); // Black to Blue
            else if (normalizedDiff < 0.5)
                heatColor = lerp(float3(0,0,1), float3(0,1,0), (normalizedDiff - 0.2) * 3.33); // Blue to Green
            else if (normalizedDiff < 0.8)
                heatColor = lerp(float3(0,1,0), float3(1,1,0), (normalizedDiff - 0.5) * 3.33); // Green to Yellow
            else
                heatColor = lerp(float3(1,1,0), float3(1,0,0), (normalizedDiff - 0.8) * 5.0); // Yellow to Red
                
            return float4(lerp(adjustedColor, heatColor, opacity), 1.0);
        }
        
        case DEBUG_ZEBRA: {
            // Show zebra pattern for values near black or white points
            float adjustedLuma = Luminance(adjustedColor);
            float nearBlack = smoothstep(0.0, 0.05, adjustedLuma) * (1.0 - smoothstep(0.05, 0.1, adjustedLuma));
            float nearWhite = smoothstep(0.9, 0.95, adjustedLuma) * (1.0 - smoothstep(0.95, 1.0, adjustedLuma));
            
            if (nearBlack > 0.1 || nearWhite > 0.1) {
                // Create diagonal stripe pattern
                float diagonal = (texcoord.x + texcoord.y) * 15.0;
                float stripe = (sin(diagonal) > 0.0) ? 1.0 : 0.0;
                if (nearBlack > 0.1)
                    return float4(lerp(adjustedColor, lerp(float3(0,0,0), float3(0,0,0.8), stripe), opacity * nearBlack), 1.0);
                else
                    return float4(lerp(adjustedColor, lerp(float3(1,1,1), float3(1,0,0), stripe), opacity * nearWhite), 1.0);
            }
            return float4(adjustedColor, 1.0);
        }        case DEBUG_SPLIT: {
            // Split screen comparison: original left, adjusted right
            float splitPoint = 0.5;
            float border = 0.002;
            if (texcoord.x < splitPoint - border)
                return float4(originalColor, 1.0); // Left side: original
            else if (texcoord.x > splitPoint + border)
                return float4(adjustedColor, 1.0); // Right side: adjusted
            else
                return float4(1.0, 1.0, 1.0, 1.0); // Border: white
            break;
        }
        
        case DEBUG_ZONES: {
            // Zone system visualization overlay
            float luma = Luminance(adjustedColor);
            int zone = LuminanceToZone(luma);
            
            // Create a tiled pattern to show zones
            float2 tileCoord = frac(texcoord * float2(4.0, 4.0));
            float isTileBorder = step(0.95, max(tileCoord.x, tileCoord.y));
            
            // Get zone color
            float3 zoneColor = GetZoneColor(zone);
            
            // Add zone number as brightness pattern
            // (For actual implementation, this would be better with text rendering)
            if (isTileBorder > 0.0) {
                // Show tile borders
                return float4(lerp(adjustedColor, float3(0.5, 0.5, 0.5), opacity * 0.7), 1.0);
            } else {
                // Show zone color in tiles
                return float4(lerp(adjustedColor, zoneColor, opacity * 0.7), 1.0);
            }
            break; // This break is never reached due to the returns above, but required for compilation
        }
    }
    
    return float4(adjustedColor, 1.0);
}

// ============================================================================
// PIXEL SHADERS
// ============================================================================

// Gray World White Balance Implementation
// Collects global average RGB values for auto white balance
static float3 accumulatedColor = float3(0.0, 0.0, 0.0);
static float accumulatedSamples = 0.0;

// Gray world white balance algorithm
float3 ApplyGrayWorldWhiteBalance(float3 color, float strength) {
    // Safety check for invalid samples
    if (accumulatedSamples <= 0.0) 
        return color;
        
    // Get the average color from accumulated samples
    float3 avgColor = accumulatedColor / accumulatedSamples;
    
    // Calculate scaling factors to normalize
    float avgLuma = Luminance(avgColor);
    if (avgLuma <= 0.001)
        return color;
        
    // Gray world assumption: avg R = avg G = avg B = avg luminance
    float3 colorBalance = avgLuma / max(float3(0.001, 0.001, 0.001), avgColor);
    
    // Apply white balance correction with strength control
    return color * lerp(float3(1.0, 1.0, 1.0), colorBalance, strength);
}

// Calculate the histogram bin count based on the quality setting
int GetHistogramBinCount() {
    switch (HistogramQuality) {
        case 0: return HIST_QUALITY_LOW;   // 64 bins
        case 1: return HIST_QUALITY_MED;   // 128 bins
        case 2: return HIST_QUALITY_STD;   // 256 bins
        case 3: return HIST_QUALITY_HIGH;  // 512 bins
    }
    return HIST_QUALITY_STD; // Default
}

// First pass: Compute histogram for current frame
float4 PS_BuildHistogram(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // Sample the current pixel color and compute luminance
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float luma = saturate(Luminance(color));

    // Convert luminance to histogram bin index
    int binIndex = int(luma * (HISTOGRAM_BINS - 1));

    // Get current pixel's target bin
    if (binIndex == int(vpos.x))
    {
        // Each pixel adds a normalized contribution
        return 1.0;
    }

    return 0.0;
}


// Second pass: Apply temporal smoothing to histogram
float4 PS_SmoothHistogram(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    int binIndex = int(vpos.x);
    
    // Get current frame's histogram value for this bin
    float currentBinValue = tex2Dfetch(CurrentHistogramSampler, int2(binIndex, 0)).r;
    
    // Get previous frame's histogram value for this bin
    float previousBinValue = tex2Dfetch(HistogramSampler, int2(binIndex, 0)).r;
    
    // Apply exponential moving average
    float smoothedValue = lerp(currentBinValue, previousBinValue, TemporalSmoothing);
    
    return smoothedValue;
}

// Third pass: Copy from intermediate to final histogram texture
float4 PS_CopyHistogram(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    int binIndex = int(vpos.x);
    
    // Simply copy from the intermediate texture to the final texture
    float value = tex2Dfetch(PrevHistogramSampler, int2(binIndex, 0)).r;
    
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
    float rawBlack = FindPercentile(HistogramSampler, BlackPoint);
    float rawWhite = FindPercentile(HistogramSampler, WhitePoint);

    // 2. Apply temporal smoothing to percentile values directly
    float blackPoint = lerp(rawBlack, prevBlack, TemporalSmoothing);
    float whitePoint = lerp(rawWhite, prevWhite, TemporalSmoothing);

    // 3. Update smoothed values
    prevBlack = blackPoint;
    prevWhite = whitePoint;

    // 4. Clamp extremes to prevent aggressive stretching
    blackPoint = max(blackPoint, 0.01);
    whitePoint = min(whitePoint, 0.99);
    if (whitePoint - blackPoint < 0.1)
    {
        // Prevent collapse (too narrow range)
        whitePoint = blackPoint + 0.1;
    }

    // 5. Reference luminance anchoring
    if (UseReferenceLuminance) {
        float refGray = ReferenceLuminance / 100.0;
        float currentMid = (blackPoint + whitePoint) * 0.5;
        float scale = refGray / max(0.01, currentMid);

        blackPoint *= scale;
        whitePoint *= scale;

        blackPoint = clamp(blackPoint, 0.0, 0.5);
        whitePoint = clamp(whitePoint, 0.5, 1.0);
    }

    float3 colorToProcess = originalColor;
    if (ColorPreservationMode == MODE_GRAYWORLD) {
        colorToProcess = ApplyGrayWorldWhiteBalance(originalColor, WhiteBalanceStrength);
    }

    float3 adjustedColor;

    switch (ColorPreservationMode)
    {
        case MODE_YCBCR:
        {
            float3 YCbCr = RGBtoYCbCr(colorToProcess);
            float adjustedY = ApplyToneCurve(YCbCr.x, blackPoint, whitePoint, MidtoneBias, ShadowLift, SoftClipAmount, CurveType);
            adjustedY = saturate(((adjustedY - 0.5) * ContrastAmount) + 0.5);
            YCbCr.x = adjustedY;
            adjustedColor = YCbCrtoRGB(YCbCr);
            break;
        }

        case MODE_HSV:
        case MODE_GRAYWORLD:
        {
            float3 HSV = RGBtoHSV(colorToProcess);
            float adjustedV = ApplyToneCurve(HSV.z, blackPoint, whitePoint, MidtoneBias, ShadowLift, SoftClipAmount, CurveType);
            adjustedV = saturate(((adjustedV - 0.5) * ContrastAmount) + 0.5);
            HSV.z = adjustedV;
            adjustedColor = HSVtoRGB(HSV);
            break;
        }

        default: // MODE_RGB
        {
            adjustedColor.r = ApplyToneCurve(colorToProcess.r, blackPoint, whitePoint, MidtoneBias, ShadowLift, SoftClipAmount, CurveType);
            adjustedColor.g = ApplyToneCurve(colorToProcess.g, blackPoint, whitePoint, MidtoneBias, ShadowLift, SoftClipAmount, CurveType);
            adjustedColor.b = ApplyToneCurve(colorToProcess.b, blackPoint, whitePoint, MidtoneBias, ShadowLift, SoftClipAmount, CurveType);
            adjustedColor = saturate(((adjustedColor - 0.5) * ContrastAmount) + 0.5);
            break;
        }
    }

    if (AutoLiftShadows) {
        adjustedColor = ApplyShadowLift(adjustedColor, AutoLiftThreshold, ShadowLift);
    }

    if (DebugMode != DEBUG_OFF) {
        return GenerateDebugView(originalColor, adjustedColor, blackPoint, whitePoint, texcoord, DebugMode, DebugOpacity);
    }

    return float4(adjustedColor, 1.0);
}

// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_GFX_AutoLeveler <
    ui_tooltip = "Dynamic luminance and contrast adjustment via intelligent remapping";
>
{
    pass BuildHistogram
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_BuildHistogram;
        RenderTarget = CurrentHistogramTex;
        ClearRenderTargets = true;

        BlendEnable = true;
        SrcBlend = ONE;
        DestBlend = ONE;
    }
    
    pass SmoothHistogram
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SmoothHistogram;
        RenderTarget = PrevHistogramTex; // Write to intermediate texture
    }
    
    pass CopyToHistogram
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyHistogram; // New shader to copy from prev to final
        RenderTarget = HistogramTex;
    }
    
    pass ApplyLeveling
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_AutoLeveler;
    }
}

#endif // __AS_GFX_AutoLeveler_1_fx
