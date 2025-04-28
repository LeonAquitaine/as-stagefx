/*
 * AS_VFX_VUMeter.1.fx - Audio-reactive VU Meter Background Shader
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Visualizes Listeningway_FreqBands as a VU meter background with zoom, pan, palette, smoothing, and glow controls.
 * Multiple presentation modes: vertical/horizontal bars, mirrored, line, dots, and classic VU.
 *
 * FEATURES:
 * - Visualizes all Listeningway_FreqBands (32 bands)
 * - Multiple presentation modes (bars, line, dots, mirrored, classic VU)
 * - Palette support (classic, blue, neon, retro, sunset, custom)
 * - Adjustable bar width, spacing, roundness
 * - Optional glow/bloom effect
 * - Optional smoothing/interpolation between bands
 * - Zoom and pan controls
 * - Sensibility (audio multiplier)
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. User selects mode, palette, and appearance controls
 * 2. Listeningway_FreqBands are sampled, optionally smoothed and scaled
 * 3. Bars/lines/dots are drawn using palette color by value
 * 4. Optional glow and smoothing are applied
 * 5. Effect is zoomed/panned as needed
 *
 * ===================================================================================
 */



#include "AS_Utils.1.fxh"

// --- Tunable Constants ---
static const float ZOOM_MIN = 0.5;
static const float ZOOM_MAX = 2.0;
static const float ZOOM_DEFAULT = 0.5;
static const float2 PAN_MIN = float2(-1.0, -1.0);
static const float2 PAN_MAX = float2(1.0, 1.0);
static const float2 PAN_DEFAULT = float2(0.0, -0.29);
static const float BARWIDTH_MIN = 0.005;
static const float BARWIDTH_MAX = 0.08;
static const float BARWIDTH_DEFAULT = 0.005;
static const float BARGAP_MIN = 0.0;
static const float BARGAP_MAX = 0.05;
static const float BARGAP_DEFAULT = 0.034;
static const float BARROUND_MIN = 0.0;
static const float BARROUND_MAX = 0.5;
static const float BARROUND_DEFAULT = 0.5;
static const float DOT_RADIUS = 0.015;
static const float LINE_THICKNESS_DEFAULT = 0.012;
static const float SENSIBILITY_MIN = 0.5;
static const float SENSIBILITY_MAX = 2.0;
static const float SENSIBILITY_DEFAULT = 0.94;
static const int PALETTE_DEFAULT = 3; // Neon
static const int PALETTE_COUNT = 6;
static const int PALETTE_COLORS = 5;
static const float BLENDAMOUNT_MIN = 0.0;
static const float BLENDAMOUNT_MAX = 1.0;
static const float BLENDAMOUNT_DEFAULT = 1.0;

// Usual VU palettes
static const float3 PALETTE_CLASSIC[5] = {
    float3(0.0, 1.0, 0.0), // Green
    float3(0.7, 1.0, 0.0), // Yellow-Green
    float3(1.0, 1.0, 0.0), // Yellow
    float3(1.0, 0.5, 0.0), // Orange
    float3(1.0, 0.0, 0.0)  // Red
};
static const float3 PALETTE_BLUE[5] = {
    float3(0.2, 0.6, 1.0), float3(0.3, 0.8, 1.0), float3(0.5, 1.0, 1.0), float3(0.7, 0.9, 1.0), float3(1.0, 1.0, 1.0)
};
// Music video palettes
static const float3 PALETTE_SUNSET[5] = {
    float3(1.0, 0.4, 0.0), float3(1.0, 0.7, 0.0), float3(1.0, 1.0, 0.0), float3(1.0, 0.0, 0.5), float3(0.5, 0.0, 1.0)
};
static const float3 PALETTE_NEON[5] = {
    float3(0.0, 1.0, 1.0), float3(0.0, 0.5, 1.0), float3(0.5, 0.0, 1.0), float3(1.0, 0.0, 1.0), float3(1.0, 0.0, 0.5)
};
static const float3 PALETTE_RETRO[5] = {
    float3(1.0, 0.0, 0.5), float3(1.0, 0.5, 0.0), float3(1.0, 1.0, 0.0), float3(0.0, 1.0, 0.5), float3(0.0, 0.5, 1.0)
};
// Custom palette (user-defined)
uniform float3 CustomPalette[5] < ui_type = "color"; ui_label = "Custom Palette Colors"; ui_category = "Appearance"; > = {
    float3(1.0, 1.0, 1.0), float3(1.0, 1.0, 1.0), float3(1.0, 1.0, 1.0), float3(1.0, 1.0, 1.0), float3(1.0, 1.0, 1.0)
};

// --- UI Controls ---
uniform float Zoom < ui_type = "slider"; ui_label = "Zoom"; ui_min = ZOOM_MIN; ui_max = ZOOM_MAX; ui_step = 0.01; ui_category = "Transform"; > = ZOOM_DEFAULT;
uniform float2 Pan < ui_type = "slider"; ui_label = "Position"; ui_min = PAN_MIN; ui_max = PAN_MAX; ui_step = 0.01; ui_category = "Transform"; > = PAN_DEFAULT;

// --- Appearance ---
uniform bool MirrorBars < ui_type = "checkbox"; ui_label = "Mirrored"; ui_category = "Appearance"; > = false;
uniform int PresentationMode < ui_type = "combo"; ui_label = "Mode"; ui_items = "Bars Vertical\0Bars Horizontal\0Line\0Dots\0Simple VU (Bottom)\0"; ui_category = "Appearance"; > = 0;
uniform float BackgroundAlpha < ui_type = "slider"; ui_label = "Background Alpha"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Appearance"; > = 0.5;

// --- Bar/Line Shape Controls ---
uniform float BarWidth < ui_type = "slider"; ui_label = "Bar Width"; ui_min = BARWIDTH_MIN; ui_max = BARWIDTH_MAX; ui_step = 0.001; ui_category = "Appearance"; > = BARWIDTH_DEFAULT;
uniform float BarGap < ui_type = "slider"; ui_label = "Bar Spacing"; ui_min = BARGAP_MIN; ui_max = BARGAP_MAX; ui_step = 0.001; ui_category = "Appearance"; > = BARGAP_DEFAULT;
uniform float BarRoundness < ui_type = "slider"; ui_label = "Bar Roundness"; ui_min = BARROUND_MIN; ui_max = BARROUND_MAX; ui_step = 0.01; ui_category = "Appearance"; > = BARROUND_DEFAULT;
uniform float DotRadius < ui_type = "slider"; ui_label = "Dot Radius"; ui_min = 0.005; ui_max = 0.05; ui_step = 0.001; ui_category = "Appearance"; > = DOT_RADIUS;
uniform float LineThickness < ui_type = "slider"; ui_label = "Line Thickness"; ui_min = 0.005; ui_max = 0.05; ui_step = 0.001; ui_category = "Appearance"; > = LINE_THICKNESS_DEFAULT;

// --- Audio Reactivity ---
uniform float Sensibility < ui_type = "slider"; ui_label = "Sensibility"; ui_min = SENSIBILITY_MIN; ui_max = SENSIBILITY_MAX; ui_step = 0.01; ui_category = "Audio Reactivity"; > = SENSIBILITY_DEFAULT;

// --- Palette & Style ---
uniform int PaletteMode < ui_type = "combo"; ui_label = "Palette"; ui_items = "Classic VU\0Blue\0Sunset\0Neon\0Retro\0Custom\0"; ui_category = "Appearance"; > = PALETTE_DEFAULT;

// --- Stage Depth Controls ---
AS_STAGEDEPTH_UI(StageDepth, "Stage Depth", "Stage")

// --- Final Mix ---
uniform int BlendMode < ui_type = "combo"; ui_label = "Mode"; ui_items = "Normal\0Lighter Only\0Darker Only\0Additive\0Multiply\0Screen\0"; ui_category = "Final Mix"; > = 0;
uniform float BlendAmount < ui_type = "slider"; ui_label = "Strength"; ui_tooltip = "How strongly the VU meter is blended with the scene."; ui_min = BLENDAMOUNT_MIN; ui_max = BLENDAMOUNT_MAX; ui_step = 0.01; ui_category = "Final Mix"; > = BLENDAMOUNT_DEFAULT;

// --- Helper Functions ---
namespace AS_VUMeterBG {
    float getSmoothedBand(int i, int bands) {
        // Use the standardized band access function that handles different band sizes
        return saturate(AS_getFrequencyBand(i)) * Sensibility;
    }
    float3 getPaletteColorByValue(float value) {
        float3 c0, c1, c2, c3, c4;
        if (PaletteMode == 0) { c0 = PALETTE_CLASSIC[0]; c1 = PALETTE_CLASSIC[1]; c2 = PALETTE_CLASSIC[2]; c3 = PALETTE_CLASSIC[3]; c4 = PALETTE_CLASSIC[4]; }
        else if (PaletteMode == 1) { c0 = PALETTE_BLUE[0]; c1 = PALETTE_BLUE[1]; c2 = PALETTE_BLUE[2]; c3 = PALETTE_BLUE[3]; c4 = PALETTE_BLUE[4]; }
        else if (PaletteMode == 2) { c0 = PALETTE_SUNSET[0]; c1 = PALETTE_SUNSET[1]; c2 = PALETTE_SUNSET[2]; c3 = PALETTE_SUNSET[3]; c4 = PALETTE_SUNSET[4]; }
        else if (PaletteMode == 3) { c0 = PALETTE_NEON[0]; c1 = PALETTE_NEON[1]; c2 = PALETTE_NEON[2]; c3 = PALETTE_NEON[3]; c4 = PALETTE_NEON[4]; }
        else if (PaletteMode == 4) { c0 = PALETTE_RETRO[0]; c1 = PALETTE_RETRO[1]; c2 = PALETTE_RETRO[2]; c3 = PALETTE_RETRO[3]; c4 = PALETTE_RETRO[4]; }
        else { c0 = CustomPalette[0]; c1 = CustomPalette[1]; c2 = CustomPalette[2]; c3 = CustomPalette[3]; c4 = CustomPalette[4]; }
        if (value <= 0.0) return c0;
        if (value >= 1.0) return c4;
        float seg = value * 4.0;
        if (seg < 1.0) return lerp(c0, c1, seg);
        if (seg < 2.0) return lerp(c1, c2, seg - 1.0);
        if (seg < 3.0) return lerp(c2, c3, seg - 2.0);
        return lerp(c3, c4, seg - 3.0);
    }
}

// --- Main Pixel Shader ---
float4 PS_VUMeterBG(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Stage depth cutoff
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    if (sceneDepth < StageDepth - 0.0005) {
        return tex2D(ReShade::BackBuffer, texcoord);
    }

    // Apply zoom and pan only (removed snap rotation)
    float2 center = float2(0.5, 0.5);
    float2 uv = (texcoord - center) / Zoom + center + Pan;

    float4 bg = float4(0, 0, 0, BackgroundAlpha);
    int bands = 32; // Listeningway_FreqBands[0..31]
    float barGap = BarGap;
    float barWidth = BarWidth;
    float roundness = BarRoundness;
    // Remove the background fill, so the effect is only drawn where bars/lines/dots are present
    float4 effectColor = float4(0, 0, 0, 0);

    if (PresentationMode == 0) { // Bars Vertical
        float totalWidth = bands * barWidth + (bands + 1) * barGap;
        float xStart = 0.5 - totalWidth * 0.5;
        float yBase = MirrorBars ? 0.25 : 0.0;
        for (int i = 0; i < bands; ++i) {
            float x0 = xStart + i * (barWidth + barGap) + barGap;
            float x1 = x0 + barWidth;
            float bandVal = AS_VUMeterBG::getSmoothedBand(i, bands) * (MirrorBars ? 0.5 : 1.0);
            float3 barColor = AS_VUMeterBG::getPaletteColorByValue(bandVal / (MirrorBars ? 0.5 : 1.0));
            // Main bar: x in [x0, x1], y in [yBase, yBase + bandVal] (from bottom up)
            float y0 = yBase;
            float y1 = yBase + bandVal;
            if (!MirrorBars) {
                // Flip so bars grow from bottom (y=0) up
                y0 = 1.0 - y1;
                y1 = 1.0 - yBase;
            }
            bool inBar = uv.x >= x0 && uv.x < x1 && uv.y >= y0 && uv.y <= y1;
            // Mirrored bar: x in [x0, x1], y in [yBase, yBase - bandVal]
            bool inMirrorBar = MirrorBars && uv.x >= x0 && uv.x < x1 && uv.y <= yBase && uv.y >= yBase - bandVal;
            if (inBar || inMirrorBar) {
                effectColor = float4(barColor, 1.0);
                break;
            }
        }
    } else if (PresentationMode == 1) { // Bars Horizontal
        float totalHeight = bands * barWidth + (bands + 1) * barGap;
        float yStart = 0.5 - totalHeight * 0.5;
        float xBase = MirrorBars ? 0.25 : 0.0;
        float xMax = MirrorBars ? 0.75 : 1.0;
        for (int i = 0; i < bands; ++i) {
            float y0 = yStart + i * (barWidth + barGap) + barGap;
            float y1 = y0 + barWidth;
            float bandVal = AS_VUMeterBG::getSmoothedBand(i, bands) * (MirrorBars ? 0.5 : 1.0);
            float3 barColor = AS_VUMeterBG::getPaletteColorByValue(bandVal / (MirrorBars ? 0.5 : 1.0));
            // Main bar: y in [y0, y1], x in [xBase, xBase + bandVal]
            bool inBar = uv.y >= y0 && uv.y < y1 && uv.x >= xBase && uv.x <= xBase + bandVal;
            // Mirrored bar: y in [y0, y1], x in [xBase, xBase - bandVal]
            bool inMirrorBar = MirrorBars && uv.y >= y0 && uv.y < y1 && uv.x <= xBase && uv.x >= xBase - bandVal;
            if (inBar || inMirrorBar) {
                effectColor = float4(barColor, 1.0);
                break;
            }
        }
    } else if (PresentationMode == 2) { // Line
        float yBase = MirrorBars ? 0.5 : 0.0;
        float yMax = MirrorBars ? 0.5 : 1.0;
        float prevX = barGap + 0.5 * barWidth;
        float prevY = yBase + (AS_VUMeterBG::getSmoothedBand(0, bands) * (MirrorBars ? 0.5 : 1.0));
        float thickness = LineThickness; // Use tunable for line thickness
        for (int i = 1; i < bands; ++i) {
            float x = barGap + i * (barWidth + barGap) + 0.5 * barWidth;
            float y = yBase + (AS_VUMeterBG::getSmoothedBand(i, bands) * (MirrorBars ? 0.5 : 1.0));
            // Flip Y for non-mirrored mode so line grows from bottom
            if (!MirrorBars) {
                prevY = 1.0 - prevY;
                y = 1.0 - y;
            }
            float2 a = float2(prevX, prevY);
            float2 b = float2(x, y);
            float2 ab = b - a;
            float2 ap = float2(uv.x, uv.y) - a;
            float t = saturate(dot(ap, ab) / dot(ab, ab));
            float2 closest = a + t * ab;
            float2 delta = float2(uv.x, uv.y) - closest;
            float3 lineColor = lerp(AS_VUMeterBG::getPaletteColorByValue(AS_VUMeterBG::getSmoothedBand(i-1, bands)), AS_VUMeterBG::getPaletteColorByValue(AS_VUMeterBG::getSmoothedBand(i, bands)), t);
            float aspect = lerp(1.0, ReShade::ScreenSize.x / ReShade::ScreenSize.y, BarRoundness);
            float2 adjDelta = float2(delta.x * aspect, delta.y);
            float dist = lerp(max(abs(adjDelta.x), abs(adjDelta.y)), length(adjDelta), BarRoundness);
            bool inLine = dist < thickness;
            // Mirrored line: reflect across yBase
            float yMirrorA = yBase - (prevY - yBase);
            float yMirrorB = yBase - (y - yBase);
            float2 aM = float2(prevX, yMirrorA);
            float2 bM = float2(x, yMirrorB);
            float2 abM = bM - aM;
            float2 apM = float2(uv.x, uv.y) - aM;
            float tM = saturate(dot(apM, abM) / dot(abM, abM));
            float2 closestM = aM + tM * abM;
            float2 deltaM = float2(uv.x, uv.y) - closestM;
            float distM = lerp(max(abs(deltaM.x), abs(deltaM.y)), length(deltaM), BarRoundness);
            bool inMirrorLine = MirrorBars && distM < thickness;
            if (inLine || inMirrorLine) {
                effectColor = float4(lineColor, 1.0);
                break;
            }
            prevX = x;
            prevY = MirrorBars ? y : 1.0 - y;
        }
    } else if (PresentationMode == 4) { // Dots
        float yBase = MirrorBars ? 0.5 : 0.0;
        float yMax = MirrorBars ? 0.5 : 1.0;
        float2 aspect = float2(ReShade::ScreenSize.x / ReShade::ScreenSize.y, 1.0);
        for (int i = 0; i < bands; ++i) {
            float x = barGap + i * (barWidth + barGap) + 0.5 * barWidth;
            float y = yBase + (AS_VUMeterBG::getSmoothedBand(i, bands) * (MirrorBars ? 0.5 : 1.0));
            // Flip Y for non-mirrored mode so dots grow from bottom
            if (!MirrorBars) {
                y = 1.0 - y;
            }
            float2 p = float2(uv.x, uv.y);
            float3 dotColor = AS_VUMeterBG::getPaletteColorByValue(AS_VUMeterBG::getSmoothedBand(i, bands) / (MirrorBars ? 0.5 : 1.0));
            float2 delta = (p - float2(x, y)) * aspect;
            float dist = lerp(max(abs(delta.x), abs(delta.y)), length(delta), BarRoundness);
            bool inDot = dist < DotRadius;
            // Mirrored dot: reflect across yBase
            float yMirror = yBase - (y - yBase);
            float2 deltaM = (p - float2(x, yMirror)) * aspect;
            float distM = lerp(max(abs(deltaM.x), abs(deltaM.y)), length(deltaM), BarRoundness);
            bool inMirrorDot = MirrorBars && distM < DotRadius;
            if (inDot || inMirrorDot) {
                effectColor = float4(dotColor, 1.0);
                break;
            }
        }
    }
    // At the end, blend with the original scene
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    float3 blended = AS_blendResult(orig.rgb, effectColor.rgb, BlendMode);
    float3 result = lerp(orig.rgb, blended, BlendAmount * effectColor.a);
    return float4(result, orig.a);
}

technique AS_VUMeterBG < ui_label = "[AS] VFX: VU Meter"; ui_tooltip = "Audio-reactive VU meter background using Listeningway."; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_VUMeterBG;
    }
}
