/**
 * AS_VFX_MultiLayerHalftone.1.fx - Flexible multi-layer halftone effect shader
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a highly customizable multi-layer halftone effect with support for up to four 
 * independent layers. Each layer can use different pattern types, isolation methods, 
 * colors, and thresholds.
 *
 * FEATURES:
 * - Four independently configurable halftone layers
 * - Multiple pattern types (dots, lines, crosshatch)
 * - Various isolation methods (brightness, RGB, hue)
 * - Customizable colors, densities, scales, and angles
 * - Layer blending with transparency support
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Each layer isolates pixel regions based on brightness, RGB intensity, or hue
 * 2. Procedural pattern generation creates dots, lines, or crosshatch effects
 * 3. Pattern colors are applied to the isolated regions
 * 4. Layers are blended sequentially based on their background transparency
 * 
 * ===================================================================================
 */

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// HELPER MACROS & CONSTANTS
// ============================================================================

#define PATTERN_DOT_ROUND  0
#define PATTERN_DOT_SQUARE 1
#define PATTERN_LINE       2
#define PATTERN_CROSSHATCH 3

#define ISOLATE_BRIGHTNESS 0
#define ISOLATE_RGB        1
#define ISOLATE_HUE         2
#define ISOLATE_DEPTH       3

// ============================================================================
// LAYER 1 CONTROLS
// ============================================================================

uniform bool Layer1_Enable <
    ui_label = "Enable Layer 1";
    ui_tooltip = "Toggle this entire halftone layer on or off.";
    ui_category = "Layer 1 Settings";
> = true;

// Isolation Method & Thresholds
uniform int Layer1_IsolationMethod <
    ui_type = "combo";
    ui_label = "Isolation Method";
    ui_tooltip = "Choose metric to isolate pixels (Brightness, RGB intensity, Hue, or Depth).";
    ui_items = "Brightness\0Composite RGB\0Hue\0Depth\0";
    ui_category = "Layer 1 Settings";
> = 0;

uniform float Layer1_ThresholdMin <
    ui_type = "slider"; 
    ui_min = 1.0; 
    ui_max = 100.0; 
    ui_step = 1.0;
    ui_label = "Range Min (1-100)";
    ui_tooltip = "Start of selection range (1-100). Mapped to 0-1 or 0-360 based on Method. Swapped internally with Max if needed.";
    ui_category = "Layer 1 Settings";
> = 1.0;

uniform float Layer1_ThresholdMax <
    ui_type = "slider"; 
    ui_min = 1.0; 
    ui_max = 100.0; 
    ui_step = 1.0;
    ui_label = "Range Max (1-100)";
    ui_tooltip = "End of selection range (1-100). Mapped to 0-1 or 0-360 based on Method. Swapped internally with Min if needed.";
    ui_category = "Layer 1 Settings";
> = 50.0;

uniform bool Layer1_InvertRange <
    ui_label = "Invert Selection Range";
    ui_tooltip = "Check to apply pattern OUTSIDE the defined Min/Max range.";
    ui_category = "Layer 1 Settings";
> = false;

// Pattern Type & Parameters
uniform int Layer1_PatternType <
    ui_type = "combo";
    ui_label = "Pattern Type";
    ui_tooltip = "Select the halftone pattern shape/style.";
    ui_items = "Dots (Round)\0Dots (Square)\0Lines\0Crosshatch\0";
    ui_category = "Layer 1 Settings";
> = 0;

uniform float Layer1_PatternScale <
    ui_type = "slider"; 
    ui_min = 1.0; 
    ui_max = 200.0;
    ui_label = "Pattern Scale/Size";
    ui_tooltip = "Controls the size of dots or thickness/frequency of lines.";
    ui_category = "Layer 1 Settings";
> = 50.0;

uniform float Layer1_PatternDensity <
    ui_type = "slider"; 
    ui_min = 0.1; 
    ui_max = 10.0;
    ui_label = "Pattern Density/Spacing";
    ui_tooltip = "Controls the spacing or coverage of the pattern elements.";
    ui_category = "Layer 1 Settings";
> = 1.0;

uniform float Layer1_PatternAngle <
    ui_type = "drag"; 
    ui_min = 0.0; 
    ui_max = 360.0;
    ui_label = "Pattern Angle";
    ui_tooltip = "Rotation angle for Lines, Crosshatch, or potentially other patterns.";
    ui_category = "Layer 1 Settings";
> = 45.0;

// Color Parameters
uniform float4 Layer1_PatternColor <
    ui_type = "color";
    ui_label = "Pattern Color (RGBA)";
    ui_tooltip = "The color of the dots or lines themselves.";
    ui_category = "Layer 1 Settings";
> = float4(0.0, 0.0, 0.0, 1.0);

uniform float4 Layer1_BackgroundColor <
    ui_type = "color";
    ui_label = "Background Color (RGBA)";
    ui_tooltip = "Color between pattern elements in the isolated area. Alpha=0 means transparent (shows layers below), Alpha=1 means opaque.";
    ui_category = "Layer 1 Settings";
> = float4(1.0, 1.0, 1.0, 0.0);

// ============================================================================
// LAYER 2 CONTROLS
// ============================================================================

uniform bool Layer2_Enable <
    ui_label = "Enable Layer 2";
    ui_tooltip = "Toggle this entire halftone layer on or off.";
    ui_category = "Layer 2 Settings";
> = false;

// Isolation Method & Thresholds
uniform int Layer2_IsolationMethod <
    ui_type = "combo";
    ui_label = "Isolation Method";
    ui_tooltip = "Choose metric to isolate pixels (Brightness, RGB intensity, Hue, or Depth).";
    ui_items = "Brightness\0Composite RGB\0Hue\0Depth\0";
    ui_category = "Layer 2 Settings";
> = 0;

uniform float Layer2_ThresholdMin <
    ui_type = "slider"; 
    ui_min = 1.0; 
    ui_max = 100.0; 
    ui_step = 1.0;
    ui_label = "Range Min (1-100)";
    ui_tooltip = "Start of selection range (1-100). Mapped to 0-1 or 0-360 based on Method. Swapped internally with Max if needed.";
    ui_category = "Layer 2 Settings";
> = 50.0;

uniform float Layer2_ThresholdMax <
    ui_type = "slider"; 
    ui_min = 1.0; 
    ui_max = 100.0; 
    ui_step = 1.0;
    ui_label = "Range Max (1-100)";
    ui_tooltip = "End of selection range (1-100). Mapped to 0-1 or 0-360 based on Method. Swapped internally with Min if needed.";
    ui_category = "Layer 2 Settings";
> = 75.0;

uniform bool Layer2_InvertRange <
    ui_label = "Invert Selection Range";
    ui_tooltip = "Check to apply pattern OUTSIDE the defined Min/Max range.";
    ui_category = "Layer 2 Settings";
> = false;

// Pattern Type & Parameters
uniform int Layer2_PatternType <
    ui_type = "combo";
    ui_label = "Pattern Type";
    ui_tooltip = "Select the halftone pattern shape/style.";
    ui_items = "Dots (Round)\0Dots (Square)\0Lines\0Crosshatch\0";
    ui_category = "Layer 2 Settings";
> = 2;

uniform float Layer2_PatternScale <
    ui_type = "slider"; 
    ui_min = 1.0; 
    ui_max = 200.0;
    ui_label = "Pattern Scale/Size";
    ui_tooltip = "Controls the size of dots or thickness/frequency of lines.";
    ui_category = "Layer 2 Settings";
> = 60.0;

uniform float Layer2_PatternDensity <
    ui_type = "slider"; 
    ui_min = 0.1; 
    ui_max = 10.0;
    ui_label = "Pattern Density/Spacing";
    ui_tooltip = "Controls the spacing or coverage of the pattern elements.";
    ui_category = "Layer 2 Settings";
> = 1.0;

uniform float Layer2_PatternAngle <
    ui_type = "drag"; 
    ui_min = 0.0; 
    ui_max = 360.0;
    ui_label = "Pattern Angle";
    ui_tooltip = "Rotation angle for Lines, Crosshatch, or potentially other patterns.";
    ui_category = "Layer 2 Settings";
> = 90.0;

// Color Parameters
uniform float4 Layer2_PatternColor <
    ui_type = "color";
    ui_label = "Pattern Color (RGBA)";
    ui_tooltip = "The color of the dots or lines themselves.";
    ui_category = "Layer 2 Settings";
> = float4(0.0, 0.0, 0.0, 1.0);

uniform float4 Layer2_BackgroundColor <
    ui_type = "color";
    ui_label = "Background Color (RGBA)";
    ui_tooltip = "Color between pattern elements in the isolated area. Alpha=0 means transparent (shows layers below), Alpha=1 means opaque.";
    ui_category = "Layer 2 Settings";
> = float4(1.0, 1.0, 1.0, 0.0);

// ============================================================================
// LAYER 3 CONTROLS
// ============================================================================

uniform bool Layer3_Enable <
    ui_label = "Enable Layer 3";
    ui_tooltip = "Toggle this entire halftone layer on or off.";
    ui_category = "Layer 3 Settings";
> = false;

// Isolation Method & Thresholds
uniform int Layer3_IsolationMethod <
    ui_type = "combo";
    ui_label = "Isolation Method";
    ui_tooltip = "Choose metric to isolate pixels (Brightness, RGB intensity, Hue, or Depth).";
    ui_items = "Brightness\0Composite RGB\0Hue\0Depth\0";
    ui_category = "Layer 3 Settings";
> = 2;

uniform float Layer3_ThresholdMin <
    ui_type = "slider"; 
    ui_min = 1.0; 
    ui_max = 100.0; 
    ui_step = 1.0;
    ui_label = "Range Min (1-100)";
    ui_tooltip = "Start of selection range (1-100). Mapped to 0-1 or 0-360 based on Method. Swapped internally with Min if needed.";
    ui_category = "Layer 3 Settings";
> = 10.0;

uniform float Layer3_ThresholdMax <
    ui_type = "slider"; 
    ui_min = 1.0; 
    ui_max = 100.0; 
    ui_step = 1.0;
    ui_label = "Range Max (1-100)";
    ui_tooltip = "End of selection range (1-100). Mapped to 0-1 or 0-360 based on Method. Swapped internally with Max if needed.";
    ui_category = "Layer 3 Settings";
> = 40.0;

uniform bool Layer3_InvertRange <
    ui_label = "Invert Selection Range";
    ui_tooltip = "Check to apply pattern OUTSIDE the defined Min/Max range.";
    ui_category = "Layer 3 Settings";
> = false;

// Pattern Type & Parameters
uniform int Layer3_PatternType <
    ui_type = "combo";
    ui_label = "Pattern Type";
    ui_tooltip = "Select the halftone pattern shape/style.";
    ui_items = "Dots (Round)\0Dots (Square)\0Lines\0Crosshatch\0";
    ui_category = "Layer 3 Settings";
> = 3;

uniform float Layer3_PatternScale <
    ui_type = "slider"; 
    ui_min = 1.0; 
    ui_max = 200.0;
    ui_label = "Pattern Scale/Size";
    ui_tooltip = "Controls the size of dots or thickness/frequency of lines.";
    ui_category = "Layer 3 Settings";
> = 40.0;

uniform float Layer3_PatternDensity <
    ui_type = "slider"; 
    ui_min = 0.1; 
    ui_max = 10.0;
    ui_label = "Pattern Density/Spacing";
    ui_tooltip = "Controls the spacing or coverage of the pattern elements.";
    ui_category = "Layer 3 Settings";
> = 1.0;

uniform float Layer3_PatternAngle <
    ui_type = "drag"; 
    ui_min = 0.0; 
    ui_max = 360.0;
    ui_label = "Pattern Angle";
    ui_tooltip = "Rotation angle for Lines, Crosshatch, or potentially other patterns.";
    ui_category = "Layer 3 Settings";
> = 30.0;

// Color Parameters
uniform float4 Layer3_PatternColor <
    ui_type = "color";
    ui_label = "Pattern Color (RGBA)";
    ui_tooltip = "The color of the dots or lines themselves.";
    ui_category = "Layer 3 Settings";
> = float4(0.0, 0.0, 0.0, 1.0);

uniform float4 Layer3_BackgroundColor <
    ui_type = "color";
    ui_label = "Background Color (RGBA)";
    ui_tooltip = "Color between pattern elements in the isolated area. Alpha=0 means transparent (shows layers below), Alpha=1 means opaque.";
    ui_category = "Layer 3 Settings";
> = float4(1.0, 1.0, 1.0, 0.0);

// ============================================================================
// LAYER 4 CONTROLS
// ============================================================================

uniform bool Layer4_Enable <
    ui_label = "Enable Layer 4";
    ui_tooltip = "Toggle this entire halftone layer on or off.";
    ui_category = "Layer 4 Settings";
> = false;

// Isolation Method & Thresholds
uniform int Layer4_IsolationMethod <
    ui_type = "combo";
    ui_label = "Isolation Method";
    ui_tooltip = "Choose metric to isolate pixels (Brightness, RGB intensity, Hue, or Depth).";
    ui_items = "Brightness\0Composite RGB\0Hue\0Depth\0";
    ui_category = "Layer 4 Settings";
> = 0;

uniform float Layer4_ThresholdMin <
    ui_type = "slider"; 
    ui_min = 1.0; 
    ui_max = 100.0; 
    ui_step = 1.0;
    ui_label = "Range Min (1-100)";
    ui_tooltip = "Start of selection range (1-100). Mapped to 0-1 or 0-360 based on Method. Swapped internally with Min if needed.";
    ui_category = "Layer 4 Settings";
> = 75.0;

uniform float Layer4_ThresholdMax <
    ui_type = "slider"; 
    ui_min = 1.0; 
    ui_max = 100.0; 
    ui_step = 1.0;
    ui_label = "Range Max (1-100)";
    ui_tooltip = "End of selection range (1-100). Mapped to 0-1 or 0-360 based on Method. Swapped internally with Max if needed.";
    ui_category = "Layer 4 Settings";
> = 100.0;

uniform bool Layer4_InvertRange <
    ui_label = "Invert Selection Range";
    ui_tooltip = "Check to apply pattern OUTSIDE the defined Min/Max range.";
    ui_category = "Layer 4 Settings";
> = false;

// Pattern Type & Parameters
uniform int Layer4_PatternType <
    ui_type = "combo";
    ui_label = "Pattern Type";
    ui_tooltip = "Select the halftone pattern shape/style.";
    ui_items = "Dots (Round)\0Dots (Square)\0Lines\0Crosshatch\0";
    ui_category = "Layer 4 Settings";
> = 1;

uniform float Layer4_PatternScale <
    ui_type = "slider"; 
    ui_min = 1.0; 
    ui_max = 200.0;
    ui_label = "Pattern Scale/Size";
    ui_tooltip = "Controls the size of dots or thickness/frequency of lines.";
    ui_category = "Layer 4 Settings";
> = 30.0;

uniform float Layer4_PatternDensity <
    ui_type = "slider"; 
    ui_min = 0.1; 
    ui_max = 10.0;
    ui_label = "Pattern Density/Spacing";
    ui_tooltip = "Controls the spacing or coverage of the pattern elements.";
    ui_category = "Layer 4 Settings";
> = 1.0;

uniform float Layer4_PatternAngle <
    ui_type = "drag"; 
    ui_min = 0.0; 
    ui_max = 360.0;
    ui_label = "Pattern Angle";
    ui_tooltip = "Rotation angle for Lines, Crosshatch, or potentially other patterns.";
    ui_category = "Layer 4 Settings";
> = 60.0;

// Color Parameters
uniform float4 Layer4_PatternColor <
    ui_type = "color";
    ui_label = "Pattern Color (RGBA)";
    ui_tooltip = "The color of the dots or lines themselves.";
    ui_category = "Layer 4 Settings";
> = float4(0.0, 0.0, 0.0, 1.0);

uniform float4 Layer4_BackgroundColor <
    ui_type = "color";
    ui_label = "Background Color (RGBA)";
    ui_tooltip = "Color between pattern elements in the isolated area. Alpha=0 means transparent (shows layers below), Alpha=1 means opaque.";
    ui_category = "Layer 4 Settings";
> = float4(1.0, 1.0, 1.0, 0.0);

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Get luminance/brightness of a color
float GetLuminance(float3 color) {
    return dot(color, float3(0.299, 0.587, 0.114));
}

// Get average RGB intensity
float GetRGBIntensity(float3 color) {
    return (color.r + color.g + color.b) / 3.0;
}

// Convert RGB to Hue (0-360)
float RGBtoHue(float3 color) {
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(color.bg, K.wz), float4(color.gb, K.xy), step(color.b, color.g));
    float4 q = lerp(float4(p.xyw, color.r), float4(color.r, p.yzx), step(p.x, color.r));
    
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10; // Small epsilon to prevent division by zero
    float h = abs(q.z + (q.w - q.y) / (6.0 * d + e));
    
    // Convert to 0-360 range and handle edge cases
    h = (d < e) ? 0.0 : (h * 360.0);
    return h;
}

// Apply rotation to coordinates
float2 RotatePoint(float2 p, float angle, float2 center) {
    // Translate to origin
    float2 translated = p - center;
    
    // Rotate
    float s = sin(angle * (AS_PI / 180.0));
    float c = cos(angle * (AS_PI / 180.0));
    float2 rotated = float2(
        translated.x * c - translated.y * s,
        translated.x * s + translated.y * c
    );
    
    // Translate back
    return rotated + center;
}

// Generate pattern value based on pattern type and parameters
float GeneratePattern(float2 uv, int patternType, float scale, float density, float angle) {
    // Scale factor (larger number = smaller pattern)
    float scaleFactor = scale * 0.01;
    
    // Screen center in normalized coordinates
    float2 screenCenter = float2(0.5, 0.5);
    
    // Pattern value
    float pattern = 0.0;
    
    if (patternType == PATTERN_DOT_ROUND || patternType == PATTERN_DOT_SQUARE) {
        // For dot patterns, we need a completely different approach to rotation
        // First convert angle to radians
        float angleRad = angle * (AS_PI / 180.0);
        
        // Create rotation matrix
        float2x2 rotMatrix = float2x2(
            cos(angleRad), -sin(angleRad),
            sin(angleRad), cos(angleRad)
        );
        
        // Scale coordinates by screen size to maintain aspect ratio
        float2 scaledCoord = uv * ReShade::ScreenSize * scaleFactor;
        
        // Rotate the grid coordinates (not the dots themselves)
        float2 rotatedCoord = mul(rotMatrix, scaledCoord);
        
        // Get cell position and local position within cell
        float2 cell = floor(rotatedCoord);
        float2 localPos = rotatedCoord - cell - 0.5; // Center within cell
        
        // Generate pattern based on type
        if (patternType == PATTERN_DOT_ROUND) {
            // Use distance from center for round dots
            float dist = length(localPos);
            pattern = step(dist, 0.5 * density);
        }
        else { // PATTERN_DOT_SQUARE
            // Use max component distance for square dots
            float dist = max(abs(localPos.x), abs(localPos.y));
            pattern = step(dist, 0.5 * density);
        }
    }
    else if (patternType == PATTERN_LINE) {
        // For lines, rotation works well with UV rotation
        float2 rotatedUV = RotatePoint(uv, angle, screenCenter);
        float2 scaledUV = rotatedUV * ReShade::ScreenSize * scaleFactor;
        
        // Lines pattern
        float lineValue = frac(scaledUV.y);
        pattern = step(lineValue, density * 0.5);
    }
    else if (patternType == PATTERN_CROSSHATCH) {
        // For crosshatch, use two rotated line patterns
        // Primary lines
        float2 rotatedUV1 = RotatePoint(uv, angle, screenCenter);
        float2 scaledUV1 = rotatedUV1 * ReShade::ScreenSize * scaleFactor;
        float lineValue1 = frac(scaledUV1.y);
        float pattern1 = step(lineValue1, density * 0.5);
        
        // Secondary lines (90 degrees to primary)
        float2 rotatedUV2 = RotatePoint(uv, angle + 90.0, screenCenter);
        float2 scaledUV2 = rotatedUV2 * ReShade::ScreenSize * scaleFactor;
        float lineValue2 = frac(scaledUV2.y);
        float pattern2 = step(lineValue2, density * 0.5);
        
        // Combine patterns
        pattern = max(pattern1, pattern2);
    }
    
    return pattern;
}

// Process a single halftone layer
float4 ProcessLayer(float4 currentColor, float2 texcoord, 
                    bool enable, int isolationMethod, 
                    float thresholdMin, float thresholdMax, bool invertRange,
                    int patternType, float patternScale, float patternDensity, float patternAngle,
                    float4 patternColor, float4 backgroundColor) {
    
    // Return current color if layer is disabled
    if (!enable) return currentColor;
    
    // Ensure proper min/max order
    float actualMin = min(thresholdMin, thresholdMax);
    float actualMax = max(thresholdMin, thresholdMax);
    
    // Map thresholds based on isolation method
    float mappedMin, mappedMax;
    if (isolationMethod == ISOLATE_HUE) {
        // Map to 0-360 range for hue
        mappedMin = actualMin * 3.6;
        mappedMax = actualMax * 3.6;
    } else {
        // Map to 0-1 range for brightness and RGB
        mappedMin = actualMin * 0.01;
        mappedMax = actualMax * 0.01;
    }
    
    // Calculate pixel metric based on isolation method
    float pixelMetric;
    if (isolationMethod == ISOLATE_BRIGHTNESS) {
        pixelMetric = GetLuminance(currentColor.rgb);
    } else if (isolationMethod == ISOLATE_RGB) {
        pixelMetric = GetRGBIntensity(currentColor.rgb);
    } else if (isolationMethod == ISOLATE_HUE) {
        pixelMetric = RGBtoHue(currentColor.rgb);
    } else if (isolationMethod == ISOLATE_DEPTH) {
        // Get linearized depth from depth buffer
        pixelMetric = ReShade::GetLinearizedDepth(texcoord);
    }
    
    // Check if pixel is in range
    bool isInRange;
    if (isolationMethod == ISOLATE_HUE) {
        // Special handling for hue which is circular (0-360)
        if (mappedMin <= mappedMax) {
            isInRange = (pixelMetric >= mappedMin && pixelMetric <= mappedMax);
        } else {
            // Handle wrap-around case (e.g., 330° to 30°)
            isInRange = (pixelMetric >= mappedMin || pixelMetric <= mappedMax);
        }
    } else {
        // Standard range check for brightness and RGB
        isInRange = (pixelMetric >= mappedMin && pixelMetric <= mappedMax);
    }
    
    // Apply inversion if requested
    bool applyPattern = (isInRange != invertRange);
    
    // If we should apply the pattern to this pixel
    if (applyPattern) {
        // Generate pattern value at this pixel
        float patternValue = GeneratePattern(texcoord, patternType, patternScale, patternDensity, patternAngle);
        
        // Select color based on pattern value
        float4 layerColor = (patternValue > 0.5) ? patternColor : backgroundColor;
        
        // Blend with current color using the layer's alpha
        return float4(
            lerp(currentColor.rgb, layerColor.rgb, layerColor.a),
            currentColor.a
        );
    }
    
    // If pattern doesn't apply, return current color unchanged
    return currentColor;
}

// ============================================================================
// MAIN SHADER FUNCTIONS
// ============================================================================

float4 PS_MultiLayerHalftone(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Sample input texture
    float4 finalColor = tex2D(ReShade::BackBuffer, texcoord);
    
    // Process each layer sequentially
    finalColor = ProcessLayer(
        finalColor, texcoord,
        Layer1_Enable, Layer1_IsolationMethod,
        Layer1_ThresholdMin, Layer1_ThresholdMax, Layer1_InvertRange,
        Layer1_PatternType, Layer1_PatternScale, Layer1_PatternDensity, Layer1_PatternAngle,
        Layer1_PatternColor, Layer1_BackgroundColor
    );
    
    finalColor = ProcessLayer(
        finalColor, texcoord,
        Layer2_Enable, Layer2_IsolationMethod,
        Layer2_ThresholdMin, Layer2_ThresholdMax, Layer2_InvertRange,
        Layer2_PatternType, Layer2_PatternScale, Layer2_PatternDensity, Layer2_PatternAngle,
        Layer2_PatternColor, Layer2_BackgroundColor
    );
    
    finalColor = ProcessLayer(
        finalColor, texcoord,
        Layer3_Enable, Layer3_IsolationMethod,
        Layer3_ThresholdMin, Layer3_ThresholdMax, Layer3_InvertRange,
        Layer3_PatternType, Layer3_PatternScale, Layer3_PatternDensity, Layer3_PatternAngle,
        Layer3_PatternColor, Layer3_BackgroundColor
    );
    
    finalColor = ProcessLayer(
        finalColor, texcoord,
        Layer4_Enable, Layer4_IsolationMethod,
        Layer4_ThresholdMin, Layer4_ThresholdMax, Layer4_InvertRange,
        Layer4_PatternType, Layer4_PatternScale, Layer4_PatternDensity, Layer4_PatternAngle,
        Layer4_PatternColor, Layer4_BackgroundColor
    );
    
    return finalColor;
}

// Technique definition
technique AS_MultiLayerHalftone <
    ui_label = "[AS] VFX: Multi-Layer Halftone";
    ui_tooltip = "Apply up to four customizable halftone pattern layers with various isolation methods and pattern types.";
> {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_MultiLayerHalftone;
    }
}