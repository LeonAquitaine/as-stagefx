/**
 * AS_Palettes.1.fxh - Palette Definitions for AS StageFX Shader Collection
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 */

#ifndef __AS_PALETTES_INCLUDED
#define __AS_PALETTES_INCLUDED

// --- Palette Constants ---
// Standard palette size
#define AS_PALETTE_COLORS 5

// Define palette modes for all shaders
#define AS_PALETTE_CLASSIC_VU    0
#define AS_PALETTE_BLUE          1
#define AS_PALETTE_SUNSET        2
#define AS_PALETTE_NEON          3
#define AS_PALETTE_RETRO         4
#define AS_PALETTE_BLUEWAVE      5
#define AS_PALETTE_BRIGHT_LIGHTS 6
#define AS_PALETTE_DISCO         7
#define AS_PALETTE_ELECTRONICA   8
#define AS_PALETTE_INDUSTRIAL    9
#define AS_PALETTE_METAL        10
#define AS_PALETTE_MONOTONE     11
#define AS_PALETTE_PASTEL_POP   12
#define AS_PALETTE_REDLINE      13
#define AS_PALETTE_RAINBOW      14
#define AS_PALETTE_FIRE         15
#define AS_PALETTE_AQUA         16
#define AS_PALETTE_VIRIDIS      17
#define AS_PALETTE_DEEP_PURPLE  18
#define AS_PALETTE_GROOVY       19  // New from PlasmaFlow (60s Groovy)
#define AS_PALETTE_VAPORWAVE    20  // New from PlasmaFlow
#define AS_PALETTE_AURORA       21  // New from PlasmaFlow
#define AS_PALETTE_ELECTRIC     22  // New from PlasmaFlow (Electric Storm)
#define AS_PALETTE_MYSTIC_NIGHT 23  // New from PlasmaFlow
#define AS_PALETTE_CUSTOM       99

// Total number of built-in palettes
#define AS_PALETTE_COUNT 24

// Default custom palette colors (will be overridden by AS_CUSTOM_PALETTE_UI macro when used)
// These defaults ensure the variables exist even if the macro isn't used
static const float3 CustomPaletteColor0 = float3(1.0, 0.0, 0.0); // Red
static const float3 CustomPaletteColor1 = float3(1.0, 1.0, 0.0); // Yellow
static const float3 CustomPaletteColor2 = float3(0.0, 1.0, 0.0); // Green
static const float3 CustomPaletteColor3 = float3(0.0, 0.0, 1.0); // Blue
static const float3 CustomPaletteColor4 = float3(1.0, 0.0, 1.0); // Magenta

// --- Standard Palette Arrays ---
// All palettes standardized to 5 colors for consistent interface
// HLSL doesn't support true multidimensional arrays, so we use a flattened array
static const float3 AS_PALETTES[AS_PALETTE_COUNT * AS_PALETTE_COLORS] = {
    // Classic VU (green -> yellow -> red)
    float3(0.0, 1.0, 0.0),   // Green
    float3(0.7, 1.0, 0.0),   // Yellow-Green
    float3(1.0, 1.0, 0.0),   // Yellow
    float3(1.0, 0.5, 0.0),   // Orange
    float3(1.0, 0.0, 0.0),   // Red
    
    // Blue
    float3(0.2, 0.6, 1.0),
    float3(0.3, 0.8, 1.0),
    float3(0.5, 1.0, 1.0),
    float3(0.7, 0.9, 1.0),
    float3(1.0, 1.0, 1.0),
    
    // Sunset
    float3(1.0, 0.4, 0.0),
    float3(1.0, 0.7, 0.0),
    float3(1.0, 1.0, 0.0),
    float3(1.0, 0.0, 0.5),
    float3(0.5, 0.0, 1.0),
    
    // Neon
    float3(0.0, 1.0, 1.0),
    float3(0.0, 0.5, 1.0),
    float3(0.5, 0.0, 1.0),
    float3(1.0, 0.0, 1.0),
    float3(1.0, 0.0, 0.5),
    
    // Retro
    float3(1.0, 0.0, 0.5),
    float3(1.0, 0.5, 0.0),
    float3(1.0, 1.0, 0.0),
    float3(0.0, 1.0, 0.5),
    float3(0.0, 0.5, 1.0),
    
    // Bluewave
    float3(0.2, 0.6, 1.0),
    float3(0.4, 0.8, 1.0),
    float3(0.6, 0.9, 1.0),
    float3(0.8, 1.0, 1.0),
    float3(0.0, 0.4, 1.0),
    
    // Bright Lights
    float3(1.0, 1.0, 0.6),
    float3(0.6, 1.0, 1.0),
    float3(1.0, 0.6, 1.0),
    float3(1.0, 0.8, 0.6),
    float3(0.6, 0.8, 1.0),
    
    // Disco
    float3(1.0, 0.2, 0.6),
    float3(1.0, 0.8, 0.2),
    float3(0.2, 1.0, 0.8),
    float3(0.8, 0.2, 1.0),
    float3(0.2, 0.8, 1.0),
    
    // Electronica
    float3(0.0, 1.0, 0.7),
    float3(0.2, 0.6, 1.0),
    float3(0.7, 0.0, 1.0),
    float3(1.0, 0.2, 0.6),
    float3(0.0, 1.0, 0.3),
    
    // Industrial
    float3(0.8, 0.8, 0.7),
    float3(0.5, 0.5, 0.5),
    float3(1.0, 0.6, 0.1),
    float3(0.2, 0.2, 0.2),
    float3(0.9, 0.7, 0.2),
    
    // Metal
    float3(0.7, 0.7, 0.7),
    float3(0.2, 0.2, 0.2),
    float3(1.0, 0.2, 0.2),
    float3(0.7, 0.5, 0.2),
    float3(0.3, 0.3, 0.3),
    
    // Monotone
    float3(0.9, 0.9, 0.9),
    float3(0.7, 0.7, 0.7),
    float3(0.5, 0.5, 0.5),
    float3(0.3, 0.3, 0.3),
    float3(0.1, 0.1, 0.1),
    
    // Pastel Pop
    float3(0.98, 0.80, 0.89),
    float3(0.80, 0.93, 0.98),
    float3(0.98, 0.96, 0.80),
    float3(0.80, 0.98, 0.87),
    float3(0.93, 0.80, 0.98),
    
    // Redline
    float3(1.0, 0.2, 0.2),
    float3(1.0, 0.4, 0.4),
    float3(1.0, 0.6, 0.6),
    float3(1.0, 0.8, 0.8),
    float3(1.0, 0.0, 0.0),
    
    // Rainbow
    float3(0.2, 0.4, 1.0),   // Blue
    float3(0.0, 1.0, 0.4),   // Green
    float3(1.0, 1.0, 0.0),   // Yellow
    float3(1.0, 0.6, 0.0),   // Orange
    float3(1.0, 0.0, 0.0),   // Red
    
    // Fire
    float3(0.2, 0.0, 0.0),   // Dark red
    float3(0.8, 0.2, 0.0),   // Bright red
    float3(1.0, 0.6, 0.0),   // Orange
    float3(1.0, 1.0, 0.2),   // Yellow
    float3(1.0, 1.0, 1.0),   // White
    
    // Aqua
    float3(0.0, 0.2, 0.4),   // Deep blue
    float3(0.0, 0.8, 1.0),   // Cyan
    float3(0.2, 1.0, 0.8),   // Aqua
    float3(0.6, 1.0, 1.0),   // Light cyan
    float3(1.0, 1.0, 1.0),   // White
    
    // Viridis
    float3(0.2, 0.2, 0.4),   // Dark blue
    float3(0.1, 0.4, 0.4),   // Dark teal
    float3(0.2, 0.8, 0.4),   // Green
    float3(0.6, 0.9, 0.2),   // Light green
    float3(0.9, 0.9, 0.2),   // Yellow
    
    // Deep Purple
    float3(0.10, 0.02, 0.25), // Deep purple
    float3(0.18, 0.04, 0.45), // Indigo
    float3(0.25, 0.05, 0.65), // Medium purple
    float3(0.45, 0.05, 0.85), // Bright purple
    float3(0.85, 0.12, 0.95),  // Magenta
    
    // Groovy (from PlasmaFlow's \ 60s Groovy\) - NEW
    float3(0.98, 0.62, 0.11), // Orange
    float3(0.98, 0.11, 0.36), // Pink-Red
    float3(0.36, 0.11, 0.98), // Purple
    float3(0.11, 0.98, 0.62), // Turquoise 
    float3(0.98, 0.89, 0.11), // Yellow
    
    // Vaporwave (from PlasmaFlow) - NEW
    float3(0.58, 0.36, 0.98), // Purple
    float3(0.98, 0.36, 0.82), // Pink
    float3(0.36, 0.98, 0.98), // Cyan
    float3(0.98, 0.82, 0.36), // Gold
    float3(0.36, 0.58, 0.98), // Blue
    
    // Aurora (from PlasmaFlow) - NEW
    float3(0.11, 0.98, 0.62), // Turquoise
    float3(0.11, 0.62, 0.98), // Blue
    float3(0.36, 0.98, 0.36), // Green
    float3(0.62, 0.11, 0.98), // Purple
    float3(0.11, 0.98, 0.98), // Cyan
    
    // Electric (from PlasmaFlow's \Electric Storm\) - NEW
    float3(0.98, 0.98, 0.36), // Yellow
    float3(0.36, 0.98, 0.98), // Cyan
    float3(0.36, 0.36, 0.98), // Blue
    float3(0.98, 0.36, 0.98), // Magenta
    float3(0.98, 0.36, 0.36), // Red
    
    // Mystic Night (from PlasmaFlow) - NEW
    float3(0.11, 0.11, 0.36), // Dark Blue
    float3(0.36, 0.11, 0.36), // Dark Purple
    float3(0.11, 0.36, 0.36), // Dark Teal
    float3(0.36, 0.36, 0.11), // Dark Yellow/Brown
    float3(0.11, 0.11, 0.11)  // Near Black
};



// Get palette color by index from the array
float3 AS_getPaletteColor(int paletteIdx, int colorIdx) {
    // Clamp palette and color indices to valid ranges
    paletteIdx = clamp(paletteIdx, 0, AS_PALETTE_COUNT - 1);
    colorIdx = clamp(colorIdx, 0, AS_PALETTE_COLORS - 1);
    
    // Handle custom palette as a special case
    if (paletteIdx == AS_PALETTE_CUSTOM) {
        if (colorIdx == 0) return CustomPaletteColor0;
        if (colorIdx == 1) return CustomPaletteColor1;
        if (colorIdx == 2) return CustomPaletteColor2;
        if (colorIdx == 3) return CustomPaletteColor3;
        return CustomPaletteColor4;
    }
    
    // Calculate index into the flattened array
    int idx = paletteIdx * AS_PALETTE_COLORS + colorIdx;
    return AS_PALETTES[idx];
}

// Interpolate color between palette colors
float3 AS_getInterpolatedColor(int paletteIdx, float t) {
    // Clamp the parameter to [0, 1]
    t = saturate(t);
    
    // Normalize to [0, number of segments]
    float segments = AS_PALETTE_COLORS - 1;
    float scaledT = t * segments;
    
    // Find indices for the two colors to interpolate between
    int colorIdx1 = floor(scaledT);
    int colorIdx2 = min(colorIdx1 + 1, AS_PALETTE_COLORS - 1);
    
    // Get the fractional part for interpolation
    float mix = frac(scaledT);
    
    // Get the two colors and interpolate
    float3 color1 = AS_getPaletteColor(paletteIdx, colorIdx1);
    float3 color2 = AS_getPaletteColor(paletteIdx, colorIdx2);
    
    return lerp(color1, color2, mix);
}

// Standard palette UI strings
#define AS_PALETTE_ITEMS "Classic VU\0Blue\0Sunset\0Neon\0Retro\0Bluewave\0Bright Lights\0Disco\0Electronica\0Industrial\0Metal\0Monotone\0Pastel Pop\0Redline\0Rainbow\0Fire\0Aqua\0Viridis\0Deep Purple\0Groovy\0Vaporwave\0Aurora\0Electric\0Mystic Night\0Custom\0"

// Standard palette selection UI
#define AS_PALETTE_SELECTION_UI(name, label, defaultPalette, category) \
uniform int name < \
    ui_type = "combo"; \
    ui_label = label; \
    ui_items = AS_PALETTE_ITEMS; \
    ui_category = category; \
> = defaultPalette;

// Macro to declare custom palette uniforms with a unique prefix
#define AS_DECLARE_CUSTOM_PALETTE(prefix, category) \
    uniform float3 prefix##CustomPaletteColor0 < ui_type = "color"; ui_label = "Custom Color 1"; ui_category = category; > = float3(1.0, 0.0, 0.0); \
    uniform float3 prefix##CustomPaletteColor1 < ui_type = "color"; ui_label = "Custom Color 2"; ui_category = category; > = float3(1.0, 1.0, 0.0); \
    uniform float3 prefix##CustomPaletteColor2 < ui_type = "color"; ui_label = "Custom Color 3"; ui_category = category; > = float3(0.0, 1.0, 0.0); \
    uniform float3 prefix##CustomPaletteColor3 < ui_type = "color"; ui_label = "Custom Color 4"; ui_category = category; > = float3(0.0, 0.0, 1.0); \
    uniform float3 prefix##CustomPaletteColor4 < ui_type = "color"; ui_label = "Custom Color 5"; ui_category = category; > = float3(1.0, 0.0, 1.0);

// Macro to fetch a custom palette color by prefix and index
#define AS_GET_CUSTOM_PALETTE_COLOR(prefix, idx) \
    ((idx) == 0 ? prefix##CustomPaletteColor0 : \
    (idx) == 1 ? prefix##CustomPaletteColor1 : \
    (idx) == 2 ? prefix##CustomPaletteColor2 : \
    (idx) == 3 ? prefix##CustomPaletteColor3 : prefix##CustomPaletteColor4)

// Interpolate color between custom palette colors (by prefix)
#define AS_GET_INTERPOLATED_CUSTOM_COLOR(prefix, t) \
    lerp( \
        AS_GET_CUSTOM_PALETTE_COLOR(prefix, (int)floor(saturate(t)*(AS_PALETTE_COLORS-1))), \
        AS_GET_CUSTOM_PALETTE_COLOR(prefix, min((int)floor(saturate(t)*(AS_PALETTE_COLORS-1))+1, AS_PALETTE_COLORS-1)), \
        frac(saturate(t)*(AS_PALETTE_COLORS-1)) \
    )

#endif // __AS_PALETTES_INCLUDED
