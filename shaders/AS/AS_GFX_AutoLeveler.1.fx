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
#define HISTOGRAM_BINS      256
#define HISTOGRAM_TEXSIZE   256
#define PERCENTILE_SAMPLES  64

// Color preservation modes
#define MODE_RGB           0
#define MODE_YCBCR         1
#define MODE_HSV           2

// Debug visualization modes
#define DEBUG_OFF          0
#define DEBUG_HISTOGRAM    1
#define DEBUG_HEATMAP      2
#define DEBUG_ZEBRA        3
#define DEBUG_SPLIT        4

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
    ui_items = "RGB (Basic)\0YCbCr (Perceptual)\0HSV (Saturation-aware)\0";
> = MODE_YCBCR;

// Debug Options
uniform int DebugMode < 
    ui_type = "combo";
    ui_label = "Debug View";
    ui_tooltip = "Visualize adjustment data to fine-tune settings";
    ui_category = "Debug";
    ui_category_closed = true;
    ui_items = "Off\0Histogram\0Heatmap\0Zebra Clipping\0Split Screen\0";
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

// Apply S-curve tone mapping with midtone bias
float ApplyToneCurve(float value, float blackPoint, float whitePoint, float midtoneBias, float shadowLift, float softClip)
{
    // Normalize the value between black and white points
    float normalizedValue = saturate((value - blackPoint) / max(0.001, whitePoint - blackPoint));
    
    // Apply midtone bias (gamma correction)
    float midCorrected = pow(normalizedValue, 1.0 / max(0.001, midtoneBias));
      // Apply shadow lift
    float liftedValue = lerp(midCorrected, 1.0, shadowLift);
    
    // Apply soft clipping to highlights using a smooth curve
    float softClipStart = 1.0 - softClip;
    float softClipped = liftedValue;
    if (softClip > 0.0 && liftedValue > softClipStart)
    {
        float clipAmount = (liftedValue - softClipStart) / max(0.001, softClip);
        float compression = 1.0 - pow(1.0 - clipAmount, 2.0);
        softClipped = softClipStart + clipAmount * (1.0 - compression) * softClip;
    }
    
    return softClipped;
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

// Generate debug visualization
float4 GenerateDebugView(float3 originalColor, float3 adjustedColor, float blackPoint, float whitePoint, float2 texcoord, int mode, float opacity)
{
    float3 debugColor = adjustedColor;
    
    switch (mode)
    {
        case DEBUG_HISTOGRAM:
        {
            // Draw histogram visualization in the lower third of the screen
            if (texcoord.y > 0.7)
            {
                float histY = (texcoord.y - 0.7) / 0.3;
                int binIndex = int(texcoord.x * (HISTOGRAM_BINS - 1));
                
                // Get histogram value and normalize for display
                float binValue = tex2Dfetch(HistogramSampler, int2(binIndex, 0)).r;
                float normalizedValue = saturate(binValue / 0.01); // Adjust 0.01 for scaling
                
                // Draw histogram bars
                float barHeight = normalizedValue * 0.8;
                float barColor = 1.0 - abs((texcoord.x - 0.5) * 2.0);
                
                if (histY < barHeight)
                {
                    // Histogram bar
                    debugColor = float3(barColor, barColor, barColor);
                }
                else
                {
                    // Background
                    debugColor = float3(0.1, 0.1, 0.1);
                }
                
                // Mark black and white points
                float bpX = blackPoint;
                float wpX = whitePoint;
                
                if (abs(texcoord.x - bpX) < 0.002)
                    debugColor = float3(0.0, 0.0, 1.0);
                if (abs(texcoord.x - wpX) < 0.002)                    debugColor = float3(1.0, 0.0, 0.0);
                    
                return float4(lerp(adjustedColor, debugColor, opacity), 1.0);
            }
            return float4(adjustedColor, 1.0);
        }
        
        case DEBUG_HEATMAP:
        {
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
            else                heatColor = lerp(float3(1,1,0), float3(1,0,0), (normalizedDiff - 0.8) * 5.0); // Yellow to Red
                
            return float4(lerp(adjustedColor, heatColor, opacity), 1.0);
        }
        
        case DEBUG_ZEBRA:
        {
            // Show zebra pattern for values near black or white points
            float adjustedLuma = Luminance(adjustedColor);
            float nearBlack = smoothstep(0.0, 0.05, adjustedLuma) * (1.0 - smoothstep(0.05, 0.1, adjustedLuma));
            float nearWhite = smoothstep(0.9, 0.95, adjustedLuma) * (1.0 - smoothstep(0.95, 1.0, adjustedLuma));
            
            if (nearBlack > 0.1 || nearWhite > 0.1)
            {
                // Create diagonal stripe pattern
                float diagonal = (texcoord.x + texcoord.y) * 15.0;
                float stripe = (sin(diagonal) > 0.0) ? 1.0 : 0.0;
                  if (nearBlack > 0.1)
                    return float4(lerp(adjustedColor, lerp(float3(0,0,0), float3(0,0,0.8), stripe), opacity * nearBlack), 1.0);
                else
                    return float4(lerp(adjustedColor, lerp(float3(1,1,1), float3(1,0,0), stripe), opacity * nearWhite), 1.0);
            }
            return float4(adjustedColor, 1.0);
        }
        
        case DEBUG_SPLIT:
        {
            // Split screen comparison: original left, adjusted right
            float splitPoint = 0.5;
            float border = 0.002;              if (texcoord.x < splitPoint - border)
                return float4(originalColor, 1.0); // Left side: original
            else if (texcoord.x > splitPoint + border)
                return float4(adjustedColor, 1.0); // Right side: adjusted
            else
                return float4(1.0, 1.0, 1.0, 1.0); // Border: white
            break;        }
    }
    
    return float4(adjustedColor, 1.0);
}

// ============================================================================
// PIXEL SHADERS
// ============================================================================

// First pass: Compute histogram for current frame
float4 PS_BuildHistogram(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // Initialize histogram bins to zero
    float histValue = 0.0;

    // Only process pixels in a grid for performance
    if ((int(vpos.x) % PERCENTILE_SAMPLES == 0) && (int(vpos.y) % PERCENTILE_SAMPLES == 0))
    {
        // Sample pixel and get luminance
        float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
        float luma = Luminance(color);
        
        // Determine which bin this pixel falls into
        int binIndex = int(saturate(luma) * (HISTOGRAM_BINS - 1));
        
        // If this pixel position matches the current bin, add to the histogram
        if (binIndex == int(vpos.x))
        {
            // Weight by the subsampling factor
            histValue = float(PERCENTILE_SAMPLES * PERCENTILE_SAMPLES);
        }
    }
    
    return histValue;
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
float4 PS_AutoLeveler(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // Get original color
    float3 originalColor = tex2D(ReShade::BackBuffer, texcoord).rgb;
    
    // Find black and white points from histogram percentiles
    float blackPoint = FindPercentile(HistogramSampler, BlackPoint);
    float whitePoint = FindPercentile(HistogramSampler, WhitePoint);
    
    // Ensure sensible values
    blackPoint = min(blackPoint, 0.4);
    whitePoint = max(whitePoint, 0.6);
    
    // Process image based on color mode
    float3 adjustedColor;
    
    switch (ColorPreservationMode)
    {
        case MODE_YCBCR:
        {
            // Convert to YCbCr
            float3 YCbCr = RGBtoYCbCr(originalColor);
            
            // Apply tone curve to Y channel
            float adjustedY = ApplyToneCurve(YCbCr.x, blackPoint, whitePoint, MidtoneBias, ShadowLift, SoftClipAmount);
            
            // Apply contrast adjustment
            adjustedY = saturate(((adjustedY - 0.5) * ContrastAmount) + 0.5);
            
            // Reconstruct with original chroma
            YCbCr.x = adjustedY;
            adjustedColor = YCbCrtoRGB(YCbCr);
            break;
        }
        
        case MODE_HSV:
        {
            // Convert to HSV
            float3 HSV = RGBtoHSV(originalColor);
            
            // Apply tone curve to V channel
            float adjustedV = ApplyToneCurve(HSV.z, blackPoint, whitePoint, MidtoneBias, ShadowLift, SoftClipAmount);
            
            // Apply contrast adjustment
            adjustedV = saturate(((adjustedV - 0.5) * ContrastAmount) + 0.5);
            
            // Reconstruct with original hue/saturation
            HSV.z = adjustedV;
            adjustedColor = HSVtoRGB(HSV);
            break;
        }
        
        default: // MODE_RGB
        {
            // Apply tone curve to each RGB channel independently
            adjustedColor.r = ApplyToneCurve(originalColor.r, blackPoint, whitePoint, MidtoneBias, ShadowLift, SoftClipAmount);
            adjustedColor.g = ApplyToneCurve(originalColor.g, blackPoint, whitePoint, MidtoneBias, ShadowLift, SoftClipAmount);
            adjustedColor.b = ApplyToneCurve(originalColor.b, blackPoint, whitePoint, MidtoneBias, ShadowLift, SoftClipAmount);
            
            // Apply contrast adjustment
            adjustedColor = saturate(((adjustedColor - 0.5) * ContrastAmount) + 0.5);
            break;
        }
    }
    
    // Apply debug visualization if enabled
    if (DebugMode != DEBUG_OFF)
    {
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
