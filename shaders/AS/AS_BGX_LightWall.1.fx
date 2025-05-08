/**
 * AS_BGX_LightWall.1.fx - Light Wall Grid Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader renders a seamless, soft, overlapping grid of light panels with various
 * built-in patterns. Perfect for creating dance club and concert backdrops with fully
 * customizable colors, patterns, and audio reactivity.
 *
 * FEATURES:
 * - 14 built-in patterns including Heart, Empty Heart, Diamond, and Beat Meter
 * - Audio-reactive panels that pulse to music via AS_Utils audio integration
 * - Customizable color palettes with 9 presets and custom options
 * - Light burst effects and cross beams for dramatic highlighting
 * - 3D perspective with tilt, pitch, and roll controls
 * - Multiple blend modes for seamless scene integration
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. The shader creates a grid of cells based on the screen resolution and user-defined spacing
 * 2. Each cell's visibility is controlled by pattern templates (8x8 matrices) with support for audio-reactive patterns
 * 3. Cells feature soft vignette edges, bright central spots, and optional cross beams
 * 4. Color selection uses palette interpolation for smooth transitions between colors
 * 5. A 3D perspective transformation creates a sense of depth and tilt
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_LightWall_1_fx
#define __AS_BGX_LightWall_1_fx

#include "AS_Utils.1.fxh"
#include "AS_Palettes.1.fxh"

// --- Tunable Constants ---
static const float MIN_MARGIN = 0.10; // Minimum margin as a fraction of cell size (10%)
static const float DEFAULT_BLOB_RADIUS_FACTOR = 0.8;
static const float DEFAULT_BRIGHT_SPOT_SIZE = 12.0;
static const float DEFAULT_SPECULAR_BLEND = 0.7;
static const float PALETTE_WAVE_X = 0.7; // Wave X frequency for Wave mode
static const float PALETTE_WAVE_Y = 1.3; // Wave Y frequency for Wave mode
static const float PALETTE_ANIM_SPEED = 0.2; // Animation speed for Light Panel
static const float PALETTE_ANIM_OFFSET = 0.13; // Offset for brightColor palette
static const float PALETTE_VU_ANIM = 0.15; // Animation amplitude for VU Meter
static const float PALETTE_VU_FREQ = 1.0; // Animation frequency for VU Meter
static const float GRIDLINE_MASK_SOFTSTART = 0.01; // Soft edge start for grid mask
static const float GRIDLINE_MASK_SOFTEND = 0.15; // Soft edge end for grid mask
static const float CELL_GAP_FACTOR = 0.5; // Factor for cell gap (GridLineThickness * CELL_GAP_FACTOR)
static const int PALETTE_COUNT = 9; // Number of built-in palettes (excluding Custom)
static const int PALETTE_COLORS = 5;

// --- Tunable Constants ---
static const float GRIDSPACING_MIN = 0.05;
static const float GRIDSPACING_MAX = 0.5;
static const float GRIDSPACING_DEFAULT = 0.063;
static const float GRIDGLOW_MIN = 0.001;
static const float GRIDGLOW_MAX = 0.1;
static const float GRIDGLOW_DEFAULT = 0.041;
static const float GRIDSTRENGTH_MIN = 0.0;
static const float GRIDSTRENGTH_MAX = 2.0;
static const float GRIDSTRENGTH_DEFAULT = 0.615;
static const float GRIDLINETHICKNESS_MIN = 0.001;
static const float GRIDLINETHICKNESS_MAX = 0.08;
static const float GRIDLINETHICKNESS_DEFAULT = 0.08;
static const float GRIDSHIFTY_MIN = -8.0;
static const float GRIDSHIFTY_MAX = 8.0;
static const float GRIDSHIFTY_DEFAULT = 0.0;
static const float TILTX_MIN = -30.0;
static const float TILTX_MAX = 30.0;
static const float TILTX_DEFAULT = 9.1;
static const float TILTY_MIN = -30.0;
static const float TILTY_MAX = 30.0;
static const float TILTY_DEFAULT = 15.5;
static const float PARALLAXSCROLL_MIN = -10.0;
static const float PARALLAXSCROLL_MAX = 10.0;
static const float PARALLAXSCROLL_DEFAULT = 3.0;
static const float SWAYINCLINATION_MIN = -30.0;
static const float SWAYINCLINATION_MAX = 30.0;
static const float SWAYINCLINATION_DEFAULT = 0.0;
static const float SWAYANGLE_MIN = 0.0;
static const float SWAYANGLE_MAX = 30.0;
static const float SWAYANGLE_DEFAULT = 0.0;
static const float SWAYSPEED_MIN = 0.0;
static const float SWAYSPEED_MAX = 2.0;
static const float SWAYSPEED_DEFAULT = 0.0;
static const float HOTSPOTPOS_MIN = -0.5;
static const float HOTSPOTPOS_MAX = 0.5;
static const float HOTSPOTPOS_DEFAULT_X = -0.469;
static const float HOTSPOTPOS_DEFAULT_Y = 0.471;
static const float BEAMLENGTH_MIN = 0.0;
static const float BEAMLENGTH_MAX = 1.0;
static const float BEAMLENGTH_DEFAULT_X = 0.804;
static const float BEAMLENGTH_DEFAULT_Y = 0.502;
static const float SPECULARSIZE_MIN = 0.01;
static const float SPECULARSIZE_MAX = 0.5;
static const float SPECULARSIZE_DEFAULT = 0.101;
static const float SPECULARBLUR_MIN = 1.0;
static const float SPECULARBLUR_MAX = 32.0;
static const float SPECULARBLUR_DEFAULT = 32.0;
static const float SPECULARBRIGHTNESS_MIN = 0.0;
static const float SPECULARBRIGHTNESS_MAX = 3.0;
static const float SPECULARBRIGHTNESS_DEFAULT = 3.0;
static const float SPECULARSTRENGTH_MIN = 0.0;
static const float SPECULARSTRENGTH_MAX = 2.0;
static const float SPECULARSTRENGTH_DEFAULT = 0.199;
static const float VIGNETTEROUNDNESS_MIN = 0.0;
static const float VIGNETTEROUNDNESS_MAX = 1.0;
static const float VIGNETTEROUNDNESS_DEFAULT = 1.0;
static const float GLOWSHAPE_MIN = 0.0;
static const float GLOWSHAPE_MAX = 1.0;
static const float GLOWSHAPE_DEFAULT = 0.381;
static const float MARGINGRADIENTSTRENGTH_MIN = 0.1;
static const float MARGINGRADIENTSTRENGTH_MAX = 3.0;
static const float MARGINGRADIENTSTRENGTH_DEFAULT = 0.100;
static const float VUBARLOGMULTIPLIER_MIN = 1.0;
static const float VUBARLOGMULTIPLIER_MAX = 8.0;
static const float VUBARLOGMULTIPLIER_DEFAULT = 4.54;
static const float STAGEDEPTH_MIN = 0.0;
static const float STAGEDEPTH_MAX = 1.0;
static const float STAGEDEPTH_DEFAULT = 0.05;
static const float BLENDAMOUNT_MIN = 0.0;
static const float BLENDAMOUNT_MAX = 1.0;
static const float BLENDAMOUNT_DEFAULT = 1.0;

// --- Controls ---
// --- Light Boxes ---
uniform float GridSpacing < ui_type = "slider"; ui_label = "Size"; ui_min = GRIDSPACING_MIN; ui_max = GRIDSPACING_MAX; ui_category = "Light Boxes"; > = GRIDSPACING_DEFAULT;
uniform float GridGlow < ui_type = "slider"; ui_label = "Glow Diffusion"; ui_min = GRIDGLOW_MIN; ui_max = GRIDGLOW_MAX; ui_category = "Light Boxes"; > = GRIDGLOW_DEFAULT;
uniform float GridStrength < ui_type = "slider"; ui_label = "Light Intensity"; ui_min = GRIDSTRENGTH_MIN; ui_max = GRIDSTRENGTH_MAX; ui_category = "Light Boxes"; > = GRIDSTRENGTH_DEFAULT;
uniform float GridLineThickness < ui_type = "slider"; ui_label = "Divider Size"; ui_min = GRIDLINETHICKNESS_MIN; ui_max = GRIDLINETHICKNESS_MAX; ui_category = "Light Boxes"; > = GRIDLINETHICKNESS_DEFAULT;

// --- Vertical Grid Shift ---
uniform float GridShiftY < ui_type = "slider"; ui_label = "Elevation"; ui_tooltip = "Adjust the vertical position of the light boxes (-8 to +8 boxes)."; ui_min = GRIDSHIFTY_MIN; ui_max = GRIDSHIFTY_MAX; ui_step = 0.01; ui_category = "Light Boxes"; > = GRIDSHIFTY_DEFAULT;

// --- Tilt Controls ---
uniform float TiltX < ui_type = "slider"; ui_label = "Pitch"; ui_tooltip = "Tilt the light boxes forward or back."; ui_min = TILTX_MIN; ui_max = TILTX_MAX; ui_step = 0.1; ui_category = "Light Boxes"; > = TILTX_DEFAULT;
uniform float TiltY < ui_type = "slider"; ui_label = "Roll"; ui_tooltip = "Tilt the light boxes left or right."; ui_min = TILTY_MIN; ui_max = TILTY_MAX; ui_step = 0.1; ui_category = "Light Boxes"; > = TILTY_DEFAULT;

// --- Pattern Selection ---
uniform int PatternPreset < ui_type = "combo"; ui_label = "Pattern"; ui_items = "Full Stage\0Heart\0Empty Heart\0Diamond\0Checker\0Stripes\0Circle\0X-Cross\0Pac-Man\0Bunny\0Star\0Smile\0Space Invader\0Beat Meter\0"; ui_category = "Light Boxes"; > = 2;

// --- Parallax Scroll ---
uniform float ParallaxScroll < ui_type = "slider"; ui_label = "Runway Scroll"; ui_tooltip = "Animates the pattern horizontally. Negative = left, positive = right. Higher magnitude = faster."; ui_min = PARALLAXSCROLL_MIN; ui_max = PARALLAXSCROLL_MAX; ui_step = 1; ui_category = "Performance"; > = PARALLAXSCROLL_DEFAULT;

// --- Sway ---
uniform float SwayInclination < ui_type = "slider"; ui_label = "Crowd Angle"; ui_min = SWAYINCLINATION_MIN; ui_max = SWAYINCLINATION_MAX; ui_category = "Performance"; > = SWAYINCLINATION_DEFAULT;
uniform float SwayAngle < ui_type = "slider"; ui_label = "Intensity"; ui_min = SWAYANGLE_MIN; ui_max = SWAYANGLE_MAX; ui_category = "Performance"; > = SWAYANGLE_DEFAULT;
uniform float SwaySpeed < ui_type = "slider"; ui_label = "Tempo"; ui_min = SWAYSPEED_MIN; ui_max = SWAYSPEED_MAX; ui_category = "Performance"; > = SWAYSPEED_DEFAULT;

// --- Hotspots ---
uniform float2 HotspotPos < ui_type = "drag"; ui_label = "Position"; ui_min = HOTSPOTPOS_MIN; ui_max = HOTSPOTPOS_MAX; ui_category = "Spotlights"; > = float2(HOTSPOTPOS_DEFAULT_X, HOTSPOTPOS_DEFAULT_Y);
uniform float2 BeamLength < ui_type = "drag"; ui_label = "Beam Length"; ui_tooltip = "Controls the length of light beams (X = Horizontal, Y = Vertical)"; ui_min = BEAMLENGTH_MIN; ui_max = BEAMLENGTH_MAX; ui_category = "Spotlights"; > = float2(BEAMLENGTH_DEFAULT_X, BEAMLENGTH_DEFAULT_Y);
// Specular
uniform float SpecularSize < ui_type = "slider"; ui_label = "Burst Size"; ui_min = SPECULARSIZE_MIN; ui_max = SPECULARSIZE_MAX; ui_category = "Spotlights"; > = SPECULARSIZE_DEFAULT;
uniform float SpecularBlur < ui_type = "slider"; ui_label = "Burst Softness"; ui_min = SPECULARBLUR_MIN; ui_max = SPECULARBLUR_MAX; ui_category = "Spotlights"; > = SPECULARBLUR_DEFAULT;
uniform float SpecularBrightness < ui_type = "slider"; ui_label = "Burst Intensity"; ui_min = SPECULARBRIGHTNESS_MIN; ui_max = SPECULARBRIGHTNESS_MAX; ui_category = "Spotlights"; > = SPECULARBRIGHTNESS_DEFAULT;
uniform float SpecularStrength < ui_type = "slider"; ui_label = "Burst Power"; ui_min = SPECULARSTRENGTH_MIN; ui_max = SPECULARSTRENGTH_MAX; ui_category = "Spotlights"; > = SPECULARSTRENGTH_DEFAULT;

// --- Appearance ---
uniform float VignetteRoundness < ui_type = "slider"; ui_label = "Shape"; ui_tooltip = "0 = square blocks, 1 = round blocks"; ui_min = VIGNETTEROUNDNESS_MIN; ui_max = VIGNETTEROUNDNESS_MAX; ui_category = "Stage Effects"; > = VIGNETTEROUNDNESS_DEFAULT;
uniform float GlowShape < ui_type = "slider"; ui_label = "Glow Pattern"; ui_tooltip = "0 = circular glow, 1 = square glow"; ui_min = GLOWSHAPE_MIN; ui_max = GLOWSHAPE_MAX; ui_category = "Stage Effects"; > = GLOWSHAPE_DEFAULT;
uniform float MarginGradientStrength < ui_type = "slider"; ui_label = "Edge Darkness"; ui_min = MARGINGRADIENTSTRENGTH_MIN; ui_max = MARGINGRADIENTSTRENGTH_MAX; ui_category = "Stage Effects"; > = MARGINGRADIENTSTRENGTH_DEFAULT;

// --- Color ---
// Use the AS_Utils palette selection UI macro for the LightWall shader
AS_PALETTE_SELECTION_UI(PalettePreset, "Theme", AS_PALETTE_REDLINE, "Lighting")
AS_DECLARE_CUSTOM_PALETTE(LightWall_, "Lighting")

// --- Color Visualization ---
uniform int VisualizationMode < ui_type = "combo"; ui_label = "Color Mode"; ui_items = "Light Panel\0Wave\0VU Meter\0VU Wave\0"; ui_tooltip = "How colors are distributed across the light panels"; ui_category = "Lighting"; > = 0;

// --- Listeningway Integration ---
uniform int VUMeterSource < ui_type = "combo"; ui_label = "Source"; ui_items = "Volume\0Beat\0Bass\0Mid\0Treble\0"; ui_category = "Audio Reactivity"; > = 1;
uniform float VUBarLogMultiplier < ui_type = "slider"; ui_label = "Frequency Boost"; ui_tooltip = "Boosts higher frequency bars logarithmically. 1.0 = no boost, higher = more boost."; ui_min = VUBARLOGMULTIPLIER_MIN; ui_max = VUBARLOGMULTIPLIER_MAX; ui_step = 0.01; ui_category = "Audio Reactivity"; > = VUBARLOGMULTIPLIER_DEFAULT;

// --- Stage Depth ---
uniform float StageDepth < ui_type = "slider"; ui_label = "Distance"; ui_tooltip = "Controls how far back the stage effect appears (lower = closer, higher = further)."; ui_min = STAGEDEPTH_MIN; ui_max = STAGEDEPTH_MAX; ui_step = 0.01; ui_category = "Stage Distance"; > = STAGEDEPTH_DEFAULT;

// --- Blend ---
uniform int BlendMode < ui_type = "combo"; ui_label = "Mode"; ui_items = "Normal\0Lighter Only\0Darker Only\0Additive\0Multiply\0Screen\0"; ui_category = "Final Mix"; > = 0;
uniform float BlendAmount < ui_type = "slider"; ui_label = "Strength"; ui_min = BLENDAMOUNT_MIN; ui_max = BLENDAMOUNT_MAX; ui_category = "Final Mix"; > = BLENDAMOUNT_DEFAULT;

// --- Debug ---
uniform int DebugMode < ui_type = "combo"; ui_label = "View"; ui_items = "Off\0Block Glow\0Light Bursts\0Block Outlines\0"; ui_category = "Debug"; > = 0;

// 8x8 patterns
static const int PATTERN_SIZE = 8;
static const int PATTERN_FULL[PATTERN_SIZE * PATTERN_SIZE] = {
    1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1
};
static const int PATTERN_HEART[PATTERN_SIZE * PATTERN_SIZE] = {
    0,1,1,0,1,1,0,0,
    1,1,1,1,1,1,1,0,
    1,1,1,1,1,1,1,0,
    0,1,1,1,1,1,0,0,
    0,0,1,1,1,0,0,0,
    0,0,0,1,0,0,0,0,
    0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0
};
static const int PATTERN_EMPTYHEART[PATTERN_SIZE * PATTERN_SIZE] = {
    0,1,1,0,1,1,0,0,
    1,0,0,1,0,0,1,0,
    1,0,0,0,0,0,1,0,
    0,1,0,0,0,1,0,0,
    0,0,1,0,1,0,0,0,
    0,0,0,1,0,0,0,0,
    0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0
};
static const int PATTERN_DIAMOND[PATTERN_SIZE * PATTERN_SIZE] = {
    0,0,0,1,0,0,0,0,
    0,0,1,1,1,0,0,0,
    0,1,1,1,1,1,0,0,
    1,1,1,1,1,1,1,0,
    0,1,1,1,1,1,0,0,
    0,0,1,1,1,0,0,0,
    0,0,0,1,0,0,0,0,
    0,0,0,0,0,0,0,0
};
static const int PATTERN_CHECKER[PATTERN_SIZE * PATTERN_SIZE] = {
    1,0,1,0,1,0,1,0,
    0,1,0,1,0,1,0,1,
    1,0,1,0,1,0,1,0,
    0,1,0,1,0,1,0,1,
    1,0,1,0,1,0,1,0,
    0,1,0,1,0,1,0,1,
    1,0,1,0,1,0,1,0,
    0,1,0,1,0,1,0,1
};
static const int PATTERN_STRIPES[PATTERN_SIZE * PATTERN_SIZE] = {
    1,1,0,0,1,1,0,0,
    1,1,0,0,1,1,0,0,
    1,1,0,0,1,1,0,0,
    1,1,0,0,1,1,0,0,
    1,1,0,0,1,1,0,0,
    1,1,0,0,1,1,0,0,
    1,1,0,0,1,1,0,0,
    1,1,0,0,1,1,0,0
};
static const int PATTERN_CIRCLE[PATTERN_SIZE * PATTERN_SIZE] = {
    0,0,1,1,1,0,0,0,
    0,1,1,1,1,1,0,0,
    1,1,1,1,1,1,1,0,
    1,1,1,1,1,1,1,0,
    1,1,1,1,1,1,1,0,
    0,1,1,1,1,1,0,0,
    0,0,1,1,1,0,0,0,
    0,0,0,0,0,0,0,0
};
static const int PATTERN_X[PATTERN_SIZE * PATTERN_SIZE] = {
    1,0,0,0,0,0,0,1,
    0,1,0,0,0,0,1,0,
    0,0,1,0,0,1,0,0,
    0,0,0,1,1,0,0,0,
    0,0,0,1,1,0,0,0,
    0,0,1,0,0,1,0,0,
    0,1,0,0,0,0,1,0,
    1,0,0,0,0,0,0,1
};

// New iconic patterns
static const int PATTERN_PACMAN[PATTERN_SIZE * PATTERN_SIZE] = {
    0,0,1,1,1,1,0,0,
    0,1,1,0,1,1,1,0,
    1,1,1,1,1,1,0,0,
    1,1,1,1,1,0,0,0,
    1,1,1,1,1,1,0,0,
    0,1,1,1,1,1,1,0,
    0,0,1,1,1,1,0,0,
    0,0,0,0,0,0,0,0
};
static const int PATTERN_BUNNY[PATTERN_SIZE * PATTERN_SIZE] = {
    0,1,0,0,0,1,0,0,
    1,0,1,0,1,0,1,0,
    1,0,1,1,1,0,1,0,
    1,0,0,0,0,0,1,0,
    1,0,1,0,1,0,1,0,
    1,0,0,0,0,0,1,0,
    0,1,1,1,1,1,0,0,
    0,0,0,0,0,0,0,0
};
static const int PATTERN_STAR[PATTERN_SIZE * PATTERN_SIZE] = {
    0,0,0,1,0,0,0,0,
    0,1,0,1,0,1,0,0,
    0,0,1,1,1,0,0,0,
    1,1,1,1,1,1,1,0,
    0,0,1,1,1,0,0,0,
    0,1,0,1,0,1,0,0,
    0,0,0,1,0,0,0,0,
    0,0,0,0,0,0,0,0
};
static const int PATTERN_SMILE[PATTERN_SIZE * PATTERN_SIZE] = {
    0,0,0,0,0,0,0,0,
    0,0,1,0,1,0,0,0,
    0,0,1,0,1,0,0,0,
    0,0,0,0,0,0,0,0,
    0,1,0,0,0,1,0,0,
    0,0,1,1,1,0,0,0,
    0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0
};
static const int PATTERN_ARROWLEFT[PATTERN_SIZE * PATTERN_SIZE] = {
    0,0,0,0,0,1,1,1,
    0,0,0,0,1,1,1,0,
    0,0,0,1,1,1,0,0,
    0,0,1,1,1,0,0,0,
    0,0,0,1,1,1,0,0,
    0,0,0,0,1,1,1,0,
    0,0,0,0,0,1,1,1,
    0,0,0,0,0,0,0,0
};

int getPatternValue(int x, int y) {
    float time = AS_getTime();
    int shift = (int)floor(ParallaxScroll * time * 0.2);
    int fineY = (int)round(GridShiftY);
    int px = ((x + shift) % PATTERN_SIZE + PATTERN_SIZE) % PATTERN_SIZE;
    int py = ((y + fineY) % PATTERN_SIZE + PATTERN_SIZE) % PATTERN_SIZE;
    if (py < 0 || py >= PATTERN_SIZE) return 0;
    if (PatternPreset == 0) return PATTERN_FULL[py * PATTERN_SIZE + px];
    if (PatternPreset == 1) return PATTERN_HEART[py * PATTERN_SIZE + px];
    if (PatternPreset == 2) return PATTERN_EMPTYHEART[py * PATTERN_SIZE + px];
    if (PatternPreset == 3) return PATTERN_DIAMOND[py * PATTERN_SIZE + px];
    if (PatternPreset == 4) return PATTERN_CHECKER[py * PATTERN_SIZE + px];
    if (PatternPreset == 5) return PATTERN_STRIPES[py * PATTERN_SIZE + px];
    if (PatternPreset == 6) return PATTERN_CIRCLE[py * PATTERN_SIZE + px];
    if (PatternPreset == 7) return PATTERN_X[py * PATTERN_SIZE + px];
    if (PatternPreset == 8) return PATTERN_PACMAN[py * PATTERN_SIZE + px];
    if (PatternPreset == 9) return PATTERN_BUNNY[py * PATTERN_SIZE + px];
    if (PatternPreset == 10) return PATTERN_STAR[py * PATTERN_SIZE + px];
    if (PatternPreset == 11) return PATTERN_SMILE[py * PATTERN_SIZE + px];
    if (PatternPreset == 12) return PATTERN_ARROWLEFT[py * PATTERN_SIZE + px];
    // Dynamic: VU Meter pattern (now at position 13)
    if (PatternPreset == 13) {
        // Use AS_getFrequencyBand from AS_Utils which handles fallbacks
        float band = saturate(AS_getFrequencyBand(px) * pow(VUBarLogMultiplier, px)); // Logarithmic boost
        int bandHeight = (int)round(band * (PATTERN_SIZE));
        if ((PATTERN_SIZE - 1 - py) < bandHeight) return 1;
        else return 0;
    }
    return 1;
}

float3 getCustomPaletteColor(int idx) {
    // Use the CustomPaletteColor variables defined by the AS_CUSTOM_PALETTE_UI macro
    if (idx == 0) return CustomPaletteColor0;
    if (idx == 1) return CustomPaletteColor1;
    if (idx == 2) return CustomPaletteColor2;
    if (idx == 3) return CustomPaletteColor3;
    if (idx == 4) return CustomPaletteColor4;
    return float3(1.0, 1.0, 1.0);
}

float3 LightWall_getPaletteColor(float t) {
    if (PalettePreset == AS_PALETTE_COUNT) {
        return AS_GET_INTERPOLATED_CUSTOM_COLOR(LightWall_, t);
    }
    return AS_getInterpolatedColor(PalettePreset, t);
}

float glowFalloff(float2 local, float shape) {
    // shape: 0 = circular, 1 = square
    float circ = dot(local, local);
    float square = max(abs(local.x), abs(local.y));
    return lerp(circ, square * square, shape);
}

float vignetteMask(float2 local, float roundness) {
    // roundness: 0 = square, 1 = circle
    float2 v = abs(local);
    float circ = dot(v, v);
    float square = max(v.x, v.y);
    float mask = lerp(1.0 - square, 1.0 - sqrt(circ), roundness);
    return saturate(mask);
}

float marginFalloff(float2 local) {
    // Always keep a minimum margin (now 10% of the cell size)
    float margin = 0.5 - max(abs(local.x), abs(local.y));
    margin = max(margin, MIN_MARGIN);
    margin = pow(saturate(margin / 0.5), MarginGradientStrength);
    return margin;
}

float2 apply3DTilt(float2 uv) {
    // Centered at (0.5,0.5), map to [-1,1]
    float2 p = (uv - 0.5) * 2.0;
    float tiltX = radians(TiltX);
    float tiltY = radians(TiltY);
    // 3D position (x, y, z)
    float3 pos = float3(p.x, p.y, 1.0);
    // Rotate around X (vertical tilt)
    float cx = cos(tiltX), sx = sin(tiltX);
    float3 posX = float3(pos.x, cx * pos.y - sx * pos.z, sx * pos.y + cx * pos.z);
    // Rotate around Y (horizontal tilt)
    float cy = cos(tiltY), sy = sin(tiltY);
    float3 posXY = float3(cy * posX.x + sy * posX.z, posX.y, -sy * posX.x + cy * posX.z);
    // Perspective projection (simple, focal length = 1)
    float persp = 1.0 / max(0.5, posXY.z); // Prevent division by zero/negative
    float2 proj = posXY.xy * persp;
    // Map back to [0,1]
    return proj * 0.5 + 0.5;
}

float2 swayRotate(float2 uv, float time) {
    // Apply 3D tilt first
    uv = apply3DTilt(uv);
    float2 center = float2(0.5, 0.5);
    float2 screen_uv = (uv - center) * float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    // Apply tilt: rotate around X (vertical) and Y (horizontal) axes
    float tiltX = radians(TiltX);
    float tiltY = radians(TiltY);
    float csX = cos(tiltX), snX = sin(tiltX);
    float csY = cos(tiltY), snY = sin(tiltY);
    // First, rotate around Y (horizontal tilt)
    float2 rotY = float2(csY * screen_uv.x - snY * screen_uv.y, snY * screen_uv.x + csY * screen_uv.y);
    // Then, rotate around X (vertical tilt)
    float2 rotXY = float2(rotY.x, csX * rotY.y - snX * 0.0); // No Z, so just scale Y
    // Add sway as before
    float sway = radians(SwayInclination + SwayAngle * sin(time * SwaySpeed));
    float cs = cos(sway);
    float sn = sin(sway);
    float2 rot = float2(cs * rotXY.x - sn * rotXY.y, sn * rotXY.x + cs * rotXY.y);
    float2 uv_rot = rot / float2(BUFFER_WIDTH, BUFFER_HEIGHT) + center;
    return uv_rot;
}

float cruxRayV(float2 local) {
    // Vertical ray: thin line, from hotspot to cell edge, gradient from hotspot to edge, brightness set by BeamLength.y, length modulated by VU
    float thickness = 0.012;
    float v = 1.0 - smoothstep(0.0, thickness, abs(local.x));
    float vu = AS_getVUMeterValue(VUMeterSource);
    float rayLen = saturate(BeamLength.y * vu) * 0.5; // 0 = no ray, 1 = full cell height
    float distFromHotspot = abs(local.y);
    float grad = (rayLen > 0.0 && distFromHotspot <= rayLen) ? 1.0 - (distFromHotspot / rayLen) : 0.0;
    return v * grad;
}

float cruxRayH(float2 local) {
    // Horizontal ray: thin line, from hotspot to cell edge, gradient from hotspot to edge, brightness set by BeamLength.x, length modulated by VU
    float thickness = 0.012;
    float h = 1.0 - smoothstep(0.0, thickness, abs(local.y));
    float vu = AS_getVUMeterValue(VUMeterSource);
    float rayLen = saturate(BeamLength.x * vu) * 0.5; // 0 = no ray, 1 = full cell width
    float distFromHotspot = abs(local.x);
    float grad = (rayLen > 0.0 && distFromHotspot <= rayLen) ? 1.0 - (distFromHotspot / rayLen) : 0.0;
    return h * grad;
}

float3 renderLavaLampGrid(float2 uv) {
    float time = AS_getTime();
    // Remove full-effect parallax: do NOT offset uv by ParallaxScroll
    float2 uv_sway = swayRotate(uv, time);
    float2 grid_size = float2(GridSpacing * BUFFER_HEIGHT / BUFFER_WIDTH, GridSpacing);
    float2 cell_idx = floor(uv_sway / grid_size);
    float2 cell_center = cell_idx * grid_size + grid_size * 0.5;
    float2 hotspot_offset = HotspotPos;
    float2 hotspot = cell_center + hotspot_offset * grid_size;
    float2 local = (uv_sway - hotspot) / grid_size;
    float t;
    if (VisualizationMode == 0) {
        // Light Panel: random color per cell, animated
        t = AS_hash12(cell_idx);
        t = frac(t + PALETTE_ANIM_SPEED * sin(time + t * AS_TWO_PI));
    } else if (VisualizationMode == 1) {
        // Wave: color changes in a wave pattern across the grid
        float wave = 0.5 + 0.5 * sin(time + cell_idx.x * PALETTE_WAVE_X + cell_idx.y * PALETTE_WAVE_Y);
        t = wave;
    } else if (VisualizationMode == 2) {
        // VU Meter: color changes according to Listeningway data
        float vu = AS_getVUMeterValue(VUMeterSource);
        t = saturate(vu + PALETTE_VU_ANIM * sin(cell_idx.x + cell_idx.y + time * PALETTE_VU_FREQ));
    } else {
        // VU Wave: color waves per cell, radiating from grid center, modulated by Listeningway
        float2 grid_center = float2(0.5, 0.5) / grid_size;
        float2 cell_rel = cell_idx - grid_center;
        float dist = length(cell_rel);
        float angle = atan2(cell_rel.y, cell_rel.x);
        float vu = AS_getVUMeterValue(VUMeterSource);
        float wave = 0.5 + 0.5 * sin(dist * 2.5 + angle * 2.0 - time * 1.5 + vu * 4.0);
        t = wave;
    }
    float3 color = LightWall_getPaletteColor(t);
    float blobRadius = 1.0 - saturate(min(GridLineThickness, 0.5 * GridSpacing) / (GridSpacing * DEFAULT_BLOB_RADIUS_FACTOR));
    float base = 1.0;
    float margin = marginFalloff(local);
    float cellMask = base * margin;
    float specular = pow(saturate(1.0 - glowFalloff(local, GlowShape) / SpecularSize), SpecularBlur) * SpecularBrightness;
    float3 specColor = lerp(color, float3(1.0, 1.0, 1.0), DEFAULT_SPECULAR_BLEND);
    // Crux glare (vertical and horizontal rays)
    float cruxV = cruxRayV(local);
    float cruxH = cruxRayH(local);
    float crux = max(cruxV, cruxH);
    float3 cruxColor = float3(1.0, 1.0, 1.0) * crux; // Only brightness from sliders
    float bright = exp(-glowFalloff(local, GlowShape) * DEFAULT_BRIGHT_SPOT_SIZE / blobRadius);
    float3 brightColor = LightWall_getPaletteColor(frac(t + PALETTE_ANIM_OFFSET));
    float2 grid = frac(uv_sway / grid_size);
    float2 dist = min(grid, 1.0 - grid);
    float gridLine = exp(-dot(dist, dist) / (min(GridLineThickness, 0.5 * GridSpacing) * min(GridLineThickness, 0.5 * GridSpacing)));
    float mask = smoothstep(GRIDLINE_MASK_SOFTSTART, GRIDLINE_MASK_SOFTEND, blobRadius) * (1.0 - gridLine);
    float2 cell_uv = (uv_sway - cell_center) / grid_size;
    float minDistToEdge = 0.5 - max(abs(cell_uv.x), abs(cell_uv.y));
    float gap = min(GridLineThickness, 0.5 * GridSpacing) * CELL_GAP_FACTOR;

    // --- Pattern Mask ---
    int px = (int)cell_idx.x % PATTERN_SIZE;
    int py = (int)cell_idx.y % PATTERN_SIZE;
    int patternVisible = getPatternValue(px, py);

    float cellVisible = step(gap, minDistToEdge) * patternVisible;
    float vignette = vignetteMask(local, VignetteRoundness);

    // --- Debug Output Selection ---
    if (DebugMode == 1) {
        // Cell Glow only
        return color * cellMask * GridStrength * vignette;
    } else if (DebugMode == 2) {
        // Dots only (bright spot)
        return brightColor * bright * (GridStrength * 1.2) * vignette;
    } else if (DebugMode == 3) {
        // Grid Lines only
        return float3(gridLine, gridLine, gridLine) * vignette;
    }
    // Normal effect
    float3 result = color * cellMask * GridStrength + brightColor * bright * (GridStrength * 1.2) + specColor * specular * GridStrength * SpecularStrength + cruxColor;
    result *= mask;
    result *= cellVisible;
    result *= vignette;
    return result;
}

// --- Main Effect ---
float4 PS_StageGrid(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float2 uv = texcoord;
    float3 fx = renderLavaLampGrid(uv);
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    if (sceneDepth < StageDepth - 0.0005)
        return orig;
    fx = saturate(fx);
    float3 blended = AS_blendResult(orig.rgb, fx, BlendMode);
    float3 result = lerp(orig.rgb, blended, BlendAmount);
    return float4(result, orig.a);
}

technique AS_LightWall < ui_label = "[AS] BGX: Light Wall"; ui_tooltip = "Soft glowing multicolor grid."; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_StageGrid;
    }
}

#endif // __AS_BGX_LightWall_1_fx
