/**
 * AS_FGX_HighlightRoller.1.fx - Advanced Highlight Roll-off and Shoulder Compression
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * A feature-rich highlight roll-off shader designed for virtual photography professionals.
 * Implements advanced highlight shoulder compression with filmic tone mapping behaviors and
 * color saturation management in bright areas.
 *
 * WHEN TO USE:
 * - When bright highlights (sun, reflections, lighting) are blown out and losing detail
 * - For achieving a cinematic "film-like" look with gentle highlight transitions
 * - In high-contrast scenes where you want to preserve both highlight and shadow detail
 * - When shooting scenes with bright skies, reflective surfaces, or direct light sources
 * - For portraits where you want soft, pleasing specular highlights on skin or features
 * - During post-processing to recover details from slightly overexposed shots
 * - When preparing images for HDR to SDR conversion while preserving highlight texture
 * - For creating artistic "analog film" looks with characteristic shoulder roll-off
 *
 * FEATURES:
 * - Multiple tone mapping curve models (Reinhard, Hable/Uncharted 2, ACES Fitted, Custom S-curve)
 * - Highlight masking with customizable threshold and knee softness
 * - Saturation roll-off to prevent color channel clipping in highlights
 * - Debugging visualizations (Highlight mask, Heat map, Zebra stripes, False color zones)
 * - Various output gamma modes (Linear, sRGB, PQ/HDR)
 * - Professional presets for different shooting situations (Cinematic, Natural, Studio, etc.)
 * - Optional highlight clamping for output compatibility
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Input pixel luminance is evaluated against a highlight threshold
 * 2. Selected tone mapping curve is applied to compress highlights without losing detail
 * 3. Saturation roll-off is gradually applied above the threshold to prevent color clipping
 * 4. Optional visualization modes help identify highlight issues and clipped areas
 * 5. Output gamma correction is applied based on selected mode
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_FGX_HighlightRoller_1_fx
#define __AS_FGX_HighlightRoller_1_fx

// Core includes
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// CONSTANTS
// ============================================================================
#define CURVE_REINHARD      0
#define CURVE_HABLE         1
#define CURVE_ACES          2
#define CURVE_CUSTOM        3

#define OUTPUT_LINEAR       0
#define OUTPUT_SRGB         1
#define OUTPUT_PQ           2

#define DEBUG_OFF           0
#define DEBUG_MASK          1
#define DEBUG_HEATMAP       2
#define DEBUG_ZEBRA         3
#define DEBUG_FALSECOLOR    4

#define PRESET_CUSTOM       0
#define PRESET_CINEMATIC    1
#define PRESET_NATURAL      2
#define PRESET_STUDIO       3
#define PRESET_ANALOG       4
#define PRESET_HDR          5
#define PRESET_FLAT         6

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// Preset Selection
uniform int PresetSelect < 
    ui_type = "combo";
    ui_label = "Preset";
    ui_tooltip = "Select a preset configuration or choose Custom to manually adjust settings";
    ui_category = "Preset";
    ui_items = "Custom\0Cinematic Gold\0Natural Skyhold\0Studio Glow\0Analog Film Scan\0HDR Ready\0Flat Recovery Pass\0";
> = 0;

// Tone Mapping Curve
uniform int CurveType < 
    ui_type = "combo";
    ui_label = "Tone Mapping Curve";
    ui_tooltip = "Select the tone mapping curve to use for highlight compression";
    ui_category = "Curve Model";
    ui_items = "Reinhard\0Hable (Uncharted 2)\0ACES Fitted\0Custom S-Curve\0";
> = 0;

// Highlight Control
uniform float HighlightStart < 
    ui_type = "slider";
    ui_label = "Highlight Start";
    ui_tooltip = "Luminance threshold where highlight compression begins";
    ui_category = "Highlight Control";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
> = 0.75;

uniform float KneeSoftness < 
    ui_type = "slider";
    ui_label = "Knee Softness";
    ui_tooltip = "Controls how smooth the transition into highlight compression is";
    ui_category = "Highlight Control";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
> = 0.3;

// Curve Parameters (for Custom S-Curve)
uniform float CurveGamma < 
    ui_type = "slider";
    ui_label = "Curve Gamma";
    ui_tooltip = "Controls the overall shape of the custom S-curve";
    ui_category = "Custom Curve";
    ui_category_closed = true;
    ui_min = 0.1; ui_max = 5.0; ui_step = 0.05;
> = 1.0;

uniform float CurveSteepness < 
    ui_type = "slider";
    ui_label = "Curve Steepness";
    ui_tooltip = "Controls how steep the transition is in the custom S-curve";
    ui_category = "Custom Curve";
    ui_min = 0.1; ui_max = 5.0; ui_step = 0.05;
> = 1.0;

// Saturation Management
uniform float SaturationFalloff < 
    ui_type = "slider";
    ui_label = "Saturation Falloff";
    ui_tooltip = "Controls how much saturation is reduced in highlights";
    ui_category = "Saturation Management";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
> = 0.5;

uniform float ColorRollStrength < 
    ui_type = "slider";
    ui_label = "Color Roll Strength";
    ui_tooltip = "Strength of desaturation in clipped highlight areas";
    ui_category = "Saturation Management";
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.01;
> = 1.0;

// Output Settings
uniform int OutputGamma < 
    ui_type = "combo";
    ui_label = "Output Gamma";
    ui_tooltip = "Gamma correction mode for the final output";
    ui_category = "Output";
    ui_items = "Linear\0sRGB\0PQ (HDR Preview)\0";
> = 1;

uniform bool ClampHighlights < 
    ui_type = "bool";
    ui_label = "Clamp Highlights";
    ui_tooltip = "Prevent RGB values from exceeding 1.0 for compatibility";
    ui_category = "Output";
> = true;

// Debug Visualization
uniform int DebugMode < 
    ui_type = "combo";
    ui_label = "Debug Visualization";
    ui_tooltip = "Display various debug visualizations to help identify issues";
    ui_category = "Debug";
    ui_category_closed = true;
    ui_items = "Off\0Highlight Mask\0Heat Map\0Zebra Stripes\0False Color Zones\0";
> = 0;

uniform float DebugIntensity < 
    ui_type = "slider";
    ui_label = "Debug Overlay Intensity";
    ui_tooltip = "Controls the opacity of debugging visualizations";
    ui_category = "Debug";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
> = 0.5;

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// RGB to luminance conversion
float Luminance(float3 color) {
    return dot(color, float3(0.2126, 0.7152, 0.0722));
}

// RGB to YCbCr conversion (preserves luma and chroma)
float3 RGBtoYCbCr(float3 rgb) {
    float y = Luminance(rgb);
    float cb = 0.5 + (-0.168736 * rgb.r - 0.331264 * rgb.g + 0.5 * rgb.b);
    float cr = 0.5 + (0.5 * rgb.r - 0.418688 * rgb.g - 0.081312 * rgb.b);
    return float3(y, cb, cr);
}

// YCbCr to RGB conversion
float3 YCbCrtoRGB(float3 ycbcr) {
    float y = ycbcr.x;
    float cb = ycbcr.y - 0.5;
    float cr = ycbcr.z - 0.5;
    
    float r = y + 1.402 * cr;
    float g = y - 0.344136 * cb - 0.714136 * cr;
    float b = y + 1.772 * cb;
    
    return float3(r, g, b);
}

// Apply selected tone mapping curve to value
float ApplyToneMappingCurve(float value, int curveType) {
    // Value should already be above highlight threshold when calling this
    float result = value;
    
    switch(curveType) {
        case CURVE_REINHARD:
            // Simple Reinhard curve: x/(1+x)
            result = value / (1.0 + value);
            break;
            
        case CURVE_HABLE:
            // Uncharted 2 tone mapping (John Hable)
            // Note: expecting input in [0, ~8] range for proper shoulder compression
            float A = 0.15;
            float B = 0.50;
            float C = 0.10;
            float D = 0.20;
            float E = 0.02;
            float F = 0.30;
            
            // Extended value for proper highlight handling
            float extendedValue = value * 2.0; // Scale value for better visual results
            result = ((extendedValue * (A * extendedValue + C * B) + D * E) / 
                      (extendedValue * (A * extendedValue + B) + D * F)) - E / F;
                      
            // Apply white point correction
            float W = 11.2;
            float whiteScale = ((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F;
            result /= whiteScale;
            break;
            
        case CURVE_ACES:
            // ACES fitted curve approximation
            float a = 2.51;
            float b = 0.03;
            float c = 2.43;
            float d = 0.59;
            float e = 0.14;
            
            // Scale value for proper highlight handling
            float acesValue = value * 0.9; // Adjusted for visual preference
            result = (acesValue * (a * acesValue + b)) / (acesValue * (c * acesValue + d) + e);
            break;        case CURVE_CUSTOM:
            // Custom parametric S-curve with edge case handling
            float x = pow(value, 1.0 / max(0.1, CurveGamma));
            // Add epsilon to avoid division by zero when CurveSteepness is close to 1.0
            float epsilon = 0.001;
            float denominator = x * (CurveSteepness - 1.0 + epsilon) + 1.0;
            result = pow((x * (CurveSteepness + x)) / denominator, CurveGamma);
            break;
    }
    
    // Ensure result is in valid range
    return saturate(result);
}

// Apply gamma correction
float3 ApplyOutputGamma(float3 color, int gammaMode) {
    switch(gammaMode) {
        case OUTPUT_LINEAR:
            return color; // No correction
        
        case OUTPUT_SRGB:
            // sRGB transfer function
            float3 linearMask = step(0.0031308, color);
            float3 srgbLow = 12.92 * color;
            float3 srgbHigh = 1.055 * pow(abs(color), 1.0 / 2.4) - 0.055;
            return lerp(srgbLow, srgbHigh, linearMask);        case OUTPUT_PQ:
            // PQ (ST.2084) transfer function
            // Simplified version for preview only
            
            // Clamp to a reasonable HDR range (0-1000 nits equivalent)
            // 1.0 in SDR is approximately 80-100 nits, so we scale up to simulate HDR range
            float3 hdrColor = min(color * 10.0, 10.0); // Clamp to 0-1000 nit range equivalent
            
            float m1 = 0.1593017578125;
            float m2 = 78.84375;
            float c1 = 0.8359375;
            float c2 = 18.8515625;
            float c3 = 18.6875;
            
            float3 yPow = pow(max(hdrColor, 1e-10), m1);
            float3 num = c1 + c2 * yPow;
            float3 den = 1.0 + c3 * yPow;
            
            // Prevent potential NaN/Inf issues
            return pow(clamp(num / den, 0.0, 1.0), m2);
    }
    
    return color; // Default fallback
}

// Generate debug visualization
float3 GenerateDebugView(float3 color, float luminance, float highlightMask, int debugMode, float debugIntensity, float2 screenPos) {
    float3 debugColor = color;
    
    switch(debugMode) {
        case DEBUG_MASK:
            // Simple white highlight mask
            debugColor = lerp(color, float3(1.0, 1.0, 1.0) * highlightMask, debugIntensity);
            break;
            
        case DEBUG_HEATMAP:
            // Heat map of highlight intensities
            float3 heatColor;
            
            if (highlightMask <= 0.0) {
                heatColor = float3(0.0, 0.0, 0.0); // Black for unaffected areas
            }
            else if (highlightMask < 0.25) {
                float t = highlightMask / 0.25;
                heatColor = float3(0.0, 0.0, t); // Blue to aqua
            }
            else if (highlightMask < 0.5) {
                float t = (highlightMask - 0.25) / 0.25;
                heatColor = float3(0.0, t, 1.0); // Aqua to green
            }
            else if (highlightMask < 0.75) {
                float t = (highlightMask - 0.5) / 0.25;
                heatColor = float3(t, 1.0, 1.0 - t); // Green to yellow
            }
            else {
                float t = (highlightMask - 0.75) / 0.25;
                heatColor = float3(1.0, 1.0 - t, 0.0); // Yellow to red
            }
            
            debugColor = lerp(color, heatColor, debugIntensity);
            break;
            
        case DEBUG_ZEBRA:
            // Zebra striping for clipped areas using screen coordinates for consistent spacing
            if (highlightMask > 0.0) {
                // Use screen coordinates for consistent stripe pattern
                float stripeFreq = 10.0; // Adjust for desired stripe width
                float diagonalPos = (screenPos.x + screenPos.y) / stripeFreq;
                
                // Create binary zebra pattern
                float zebra = (sin(diagonalPos * AS_PI) > 0.0) ? 1.0 : 0.0;
                zebra *= highlightMask;
                
                debugColor = lerp(color, (zebra > 0.5) ? float3(1.0, 1.0, 1.0) : float3(0.0, 0.0, 0.0), debugIntensity * zebra);
            }
            break;
              case DEBUG_FALSECOLOR:
            // IRE-style false color zones
            float3 zoneColor = color;
            
            // Zone 7-10 IRE style bands
            if (luminance > 0.7 && luminance <= 0.8) {
                zoneColor = float3(0.0, 1.0, 1.0); // Cyan (Zone 7)
            }
            else if (luminance > 0.8 && luminance <= 0.9) {
                zoneColor = float3(1.0, 1.0, 0.0); // Yellow (Zone 8)
            }
            else if (luminance > 0.9 && luminance <= 0.97) {
                zoneColor = float3(1.0, 0.5, 0.0); // Orange (Zone 9)
            }
            else if (luminance > 0.97) {
                zoneColor = float3(1.0, 0.0, 0.0); // Red (Zone 10)
            }
            
            debugColor = lerp(color, zoneColor, debugIntensity * step(0.7, luminance));
            break;
    }
    
    return debugColor;
}

// Apply presets
void ApplyPreset(int preset, out int curve, out float start, out float knee, 
                out float sat, out float roll, out int output, out int debug, out bool clamp) {
    // Default values (Custom preset or fallback)
    curve = CurveType;
    start = HighlightStart;
    knee = KneeSoftness;
    sat = SaturationFalloff;
    roll = ColorRollStrength;
    output = OutputGamma;
    debug = DebugMode;
    clamp = ClampHighlights;
    
    switch(preset) {
        case PRESET_CINEMATIC:
            curve = CURVE_HABLE;
            start = 0.65;
            knee = 0.4;
            sat = 0.7;
            roll = 1.5;
            output = OUTPUT_SRGB;
            debug = DEBUG_OFF;
            clamp = true;
            break;
            
        case PRESET_NATURAL:
            curve = CURVE_ACES;
            start = 0.78;
            knee = 0.25;
            sat = 0.3;
            roll = 0.8;
            output = OUTPUT_SRGB;
            debug = DEBUG_OFF;
            clamp = true;
            break;
            
        case PRESET_STUDIO:
            curve = CURVE_REINHARD;
            start = 0.82;
            knee = 0.2;
            sat = 0.4;
            roll = 1.0;
            output = OUTPUT_SRGB;
            debug = DEBUG_OFF;
            clamp = true;
            break;
            
        case PRESET_ANALOG:
            curve = CURVE_CUSTOM;
            start = 0.7;
            knee = 0.5;
            sat = 0.6;
            roll = 1.2;
            output = OUTPUT_SRGB;
            debug = DEBUG_OFF;
            clamp = true;
            break;
            
        case PRESET_HDR:
            curve = CURVE_HABLE;
            start = 0.85;
            knee = 0.15;
            sat = 0.2;
            roll = 0.5;
            output = OUTPUT_PQ;
            debug = DEBUG_OFF;
            clamp = false;
            break;
            
        case PRESET_FLAT:
            curve = CURVE_REINHARD;
            start = 0.9;
            knee = 0.1;
            sat = 0.1;
            roll = 0.3;
            output = OUTPUT_LINEAR;
            debug = DEBUG_MASK;
            clamp = false;
            break;
    }
}

// ============================================================================
// PIXEL SHADER
// ============================================================================

float3 PS_HighlightRoller(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Get original color from the back buffer
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    
    // Apply preset if selected
    int effectiveCurve = CurveType;
    float effectiveHighlightStart = HighlightStart;
    float effectiveKneeSoftness = KneeSoftness;
    float effectiveSatFalloff = SaturationFalloff;
    float effectiveColorRoll = ColorRollStrength;
    int effectiveOutput = OutputGamma;
    int effectiveDebug = DebugMode;
    bool effectiveClamp = ClampHighlights;
    
    if (PresetSelect != PRESET_CUSTOM) {
        ApplyPreset(PresetSelect, effectiveCurve, effectiveHighlightStart, effectiveKneeSoftness,
                   effectiveSatFalloff, effectiveColorRoll, effectiveOutput, effectiveDebug, effectiveClamp);
    }
    
    // Calculate initial luminance
    float luma = Luminance(color);
    
    // Calculate highlight mask with soft knee
    float threshold = effectiveHighlightStart;
    float knee = max(0.001, effectiveKneeSoftness);
    float softKneeStart = max(0.0, threshold - knee);
    float softKneeEnd = min(1.0, threshold + knee);
    
    float highlightMask = 0.0;
    if (luma >= softKneeEnd) {
        highlightMask = 1.0;
    }
    else if (luma > softKneeStart) {
        highlightMask = smoothstep(softKneeStart, softKneeEnd, luma);
    }    // Process highlights if needed
    if (highlightMask > 0.0) {
        // Calculate compression amount (how much to compress, based on how far above threshold)
        float compressionAmount = (luma - threshold) / max(0.001, 1.0 - threshold);
        compressionAmount = saturate(compressionAmount);
        
        // Scale luminance for tone mapping (to ensure proper curve appearance)
        float scaledLuma = luma * (1.0 + compressionAmount);
        
        // Apply selected tone mapping curve to luminance
        float mappedLuma = ApplyToneMappingCurve(scaledLuma, effectiveCurve);
        mappedLuma = max(threshold, mappedLuma); // Ensure we don't go below threshold
        
        // Calculate saturation adjustment based on highlight intensity
        float saturationFactor = 1.0 - (compressionAmount * effectiveSatFalloff * effectiveColorRoll);
        saturationFactor = max(0.0, saturationFactor);
        
        // Use YCbCr for proper tone mapping while preserving chroma
        float3 ycbcr = RGBtoYCbCr(color);
        float origY = ycbcr.x;
        
        // Only modify the Y (luminance) component
        float luminanceRatio = mappedLuma / max(0.001, origY);
        ycbcr.x = mappedLuma;
        
        // Convert back to RGB while preserving the chroma
        float3 toneMappedColor = YCbCrtoRGB(ycbcr);
        
        // Apply saturation adjustment
        // Calculate chrominance components
        float3 luminanceVector = float3(1.0, 1.0, 1.0) * origY;
        float3 chrominanceVector = color - luminanceVector;
        
        // Apply saturation factor to chrominance
        float3 adjustedChrominance = chrominanceVector * saturationFactor;
        
        // Combine adjusted luminance with adjusted chrominance
        float3 adjustedColor = float3(mappedLuma, mappedLuma, mappedLuma) + adjustedChrominance * luminanceRatio;
        
        // Safety check for NaN/Inf values
        if (any(isnan(adjustedColor)) || any(isinf(adjustedColor))) {
            adjustedColor = toneMappedColor; // Fallback to simpler tone mapping
        }
        
        // Apply highlight mask for smooth blending
        color = lerp(tex2D(ReShade::BackBuffer, texcoord).rgb, adjustedColor, highlightMask);
    }    // Apply debug visualization if enabled
    if (effectiveDebug != DEBUG_OFF) {
        color = GenerateDebugView(color, luma, highlightMask, effectiveDebug, DebugIntensity, vpos.xy);
    }
    
    // Apply output gamma correction
    color = ApplyOutputGamma(color, effectiveOutput);
    
    // Optional clamping for compatibility
    if (effectiveClamp) {
        color = saturate(color);
    }
    
    return color;
}

// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_FGX_HighlightRoller <
    ui_tooltip = "Advanced highlight roll-off and shoulder compression for virtual photography";
> {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_HighlightRoller;
    }
}

#endif // __AS_FGX_HighlightRoller_1_fx
