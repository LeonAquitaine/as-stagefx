/**
 * AS_BGX_VinylDisc.1.fx - Vinyl Record with Iridescent Grooves and Animated Backgrounds
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Renders a spinning vinyl record with realistic concentric grooves and thin-film
 * iridescence (oily rainbow reflections). Multiple background styles create a
 * complete music visualization scene.
 *
 * FEATURES:
 * - Realistic vinyl disc with concentric groove lines
 * - Thin-film iridescence (oil-slick rainbow reflections on grooves)
 * - Configurable LP color (black, pearl, red, blue, green, gold, silver, picture disc)
 * - Configurable label area with color and size controls
 * - 5 background styles: None, Neon Rings, Neon Burst, Geometric Pop, Waveform
 * - Counter-rotating neon elements in background
 * - Audio-reactive iridescence, spin speed, and background intensity
 * - Full position/scale/rotation controls
 * - Palette-based coloring for background elements
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Compute centered UV with aspect correction, apply position/scale/rotation
 * 2. Render background layer based on selected style (rings, burst, particles, waveform)
 * 3. Render vinyl disc: outer ring SDF, groove lines via sin(distance), center hole
 * 4. Apply thin-film iridescence based on groove angle + virtual light position
 * 5. Render label area as solid color circle
 * 6. Composite disc over background, then blend with scene
 *
 * ===================================================================================
 */

#ifndef __AS_BGX_VinylDisc_1_fx
#define __AS_BGX_VinylDisc_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"
#include "AS_Noise.1.fxh"

// ============================================================================
// LABEL TEXTURE (customizable via preprocessor)
// ============================================================================
// To use a custom label image, add to your PreprocessorDefinitions:
//   #define VinylDisc_LabelFileName "path/to/your/label.png"
//   #define VinylDisc_LabelWidth 512
//   #define VinylDisc_LabelHeight 512
#ifndef VinylDisc_LabelFileName
    #define VinylDisc_LabelFileName "LayerStage.png"
#endif
#ifndef VinylDisc_LabelWidth
    #define VinylDisc_LabelWidth 512
#endif
#ifndef VinylDisc_LabelHeight
    #define VinylDisc_LabelHeight 512
#endif

texture VinylDisc_LabelTexture <source=VinylDisc_LabelFileName;> { Width = VinylDisc_LabelWidth; Height = VinylDisc_LabelHeight; Format=RGBA8; };
sampler VinylDisc_LabelSampler { Texture = VinylDisc_LabelTexture; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };

namespace AS_VinylDisc {

// ============================================================================
// CONSTANTS
// ============================================================================

// --- Disc Geometry ---
static const float DISC_RADIUS = 0.42;
static const float DISC_EDGE_SOFTNESS_BASE = 0.003;
static const float CENTER_HOLE_RADIUS = 0.018;
static const float LABEL_RADIUS_DEFAULT = 0.13;
static const float GROOVE_START_OFFSET = 0.01; // gap between label and first groove
static const float EDGE_SHARPNESS_DEFAULT = 0.5; // 0 = sharp pixel edges, 1 = soft/fuzzy

// --- Track Rendering ---
static const int TRACK_COUNT_MIN = 1;
static const int TRACK_COUNT_MAX = 16;
static const int TRACK_COUNT_DEFAULT = 8;
static const float TRACK_GAP = 0.15; // fraction of track width used as gap between tracks
static const int GROOVE_LINES_MIN = 0;
static const int GROOVE_LINES_MAX = 20;
static const int GROOVE_LINES_DEFAULT = 12;
static const float GROOVE_DEPTH_DEFAULT = 0.25;
static const float GROOVE_HIGHLIGHT_DEFAULT = 0.10;

// --- Iridescence ---
static const float IRIDESCENCE_MIN = 0.0;
static const float IRIDESCENCE_MAX = 1.0;
static const float IRIDESCENCE_DEFAULT = 0.5;
static const float IRIDESCENCE_SPEED_MIN = -3.0;
static const float IRIDESCENCE_SPEED_MAX = 3.0;
static const float IRIDESCENCE_SPEED_DEFAULT = 0.5;
static const float PICTURE_SPIN_SPEED_MIN = -3.0;
static const float PICTURE_SPIN_SPEED_MAX = 3.0;
static const float PICTURE_SPIN_SPEED_DEFAULT = 0.3;
static const float IRID_WEDGE_WIDTH_MIN = 0.1;
static const float IRID_WEDGE_WIDTH_MAX = 1.0;
static const float IRID_WEDGE_WIDTH_DEFAULT = 0.4; // fraction of disc covered by reflection wedge
static const float IRID_LIGHT_ANGLE_DEFAULT = 0.75; // default light source angle (0-1 maps to 0-2pi)

// --- LP Color Presets ---
static const int LP_BLACK = 0;
static const int LP_PEARL = 1;
static const int LP_RED = 2;
static const int LP_BLUE = 3;
static const int LP_GREEN = 4;
static const int LP_GOLD = 5;
static const int LP_SILVER = 6;
static const int LP_PICTURE = 7;
static const int LP_CUSTOM = 8;

// --- Background Styles ---
static const int BG_NONE = 0;
static const int BG_NEON_RINGS = 1;
static const int BG_NEON_BURST = 2;
static const int BG_GEOMETRIC_POP = 3;
static const int BG_WAVEFORM = 4;

// --- Background Parameters ---
static const float BG_INTENSITY_MIN = 0.0;
static const float BG_INTENSITY_MAX = 2.0;
static const float BG_INTENSITY_DEFAULT = 0.7;
static const float RING_SPEED_MIN = 0.0;
static const float RING_SPEED_MAX = 3.0;
static const float RING_SPEED_DEFAULT = 0.5;
static const int PARTICLE_COUNT_MAX = 24;
static const int PARTICLE_COUNT_DEFAULT = 12;
static const float NEON_RING_COUNT = 6.0;
static const float NEON_RING_THICKNESS = 0.008;
static const float BURST_RAY_COUNT = 24.0;

// --- Spin ---
static const float SPIN_SPEED_DEFAULT = 0.3;

// ============================================================================
// UNIFORMS
// ============================================================================

// --- Disc Appearance ---

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform int LPColorPreset < ui_type = "combo"; ui_label = "LP Color"; ui_tooltip = "Vinyl color preset. Picture Disc shows the game scene through the record."; ui_items = "Classic Black\0Pearl White\0Transparent Red\0Transparent Blue\0Transparent Green\0Gold\0Silver\0Picture Disc\0Custom\0"; ui_category = "Vinyl Disc"; > = LP_BLACK;
uniform float3 CustomLPColor < ui_type = "color"; ui_label = "Custom LP Color"; ui_tooltip = "Base color when LP Color is set to Custom."; ui_category = "Vinyl Disc"; > = float3(0.05, 0.05, 0.05);
uniform int TrackCount < ui_type = "slider"; ui_label = "Track Count"; ui_tooltip = "Number of distinct concentric track bands on the record."; ui_min = TRACK_COUNT_MIN; ui_max = TRACK_COUNT_MAX; ui_step = 1; ui_category = "Vinyl Disc"; > = TRACK_COUNT_DEFAULT;
uniform int GrooveLinesPerTrack < ui_type = "slider"; ui_label = "Groove Lines per Track"; ui_tooltip = "Number of fine groove lines within each track band. 0 = smooth tracks (CD look)."; ui_min = GROOVE_LINES_MIN; ui_max = GROOVE_LINES_MAX; ui_step = 1; ui_category = "Vinyl Disc"; > = GROOVE_LINES_DEFAULT;
uniform float GrooveDepth < ui_type = "slider"; ui_label = "Groove Depth"; ui_tooltip = "How deep/dark the groove lines appear. Higher = more contrast between grooves and ridges."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Vinyl Disc"; > = GROOVE_DEPTH_DEFAULT;
uniform float GrooveGlow < ui_type = "slider"; ui_label = "Groove Glow"; ui_tooltip = "Specular highlight on groove ridges. Simulates light catching the top of each groove."; ui_min = 0.0; ui_max = 0.5; ui_step = 0.01; ui_category = "Vinyl Disc"; > = GROOVE_HIGHLIGHT_DEFAULT;
uniform float IridescenceStrength < ui_type = "slider"; ui_label = "Iridescence Intensity"; ui_tooltip = "Rainbow oil-slick reflection intensity on the grooves. 0 = matte vinyl."; ui_min = IRIDESCENCE_MIN; ui_max = IRIDESCENCE_MAX; ui_step = 0.01; ui_category = "Vinyl Disc"; > = IRIDESCENCE_DEFAULT;
uniform float IridescenceBoost < ui_type = "slider"; ui_label = "Iridescence Boost"; ui_tooltip = "Multiplier for iridescence color brightness. Increase to push colors to full saturation."; ui_min = 1.0; ui_max = 5.0; ui_step = 0.1; ui_category = "Vinyl Disc"; > = 2.0;
uniform float IridescenceSpeed < ui_type = "slider"; ui_label = "Iridescence Shift Speed"; ui_tooltip = "How fast the rainbow reflection wedge rotates around the disc."; ui_min = IRIDESCENCE_SPEED_MIN; ui_max = IRIDESCENCE_SPEED_MAX; ui_step = 0.01; ui_category = "Vinyl Disc"; > = IRIDESCENCE_SPEED_DEFAULT;
uniform float IridWedgeWidth < ui_type = "slider"; ui_label = "Reflection Spread"; ui_tooltip = "Angular width of the iridescent reflection wedge. Smaller = tighter spotlight, larger = wider fan."; ui_min = IRID_WEDGE_WIDTH_MIN; ui_max = IRID_WEDGE_WIDTH_MAX; ui_step = 0.01; ui_category = "Vinyl Disc"; > = IRID_WEDGE_WIDTH_DEFAULT;
uniform float IridLightAngle < ui_type = "slider"; ui_label = "Light Source Angle"; ui_tooltip = "Direction of the virtual light source creating the reflection. 0-1 maps around the disc."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Vinyl Disc"; > = IRID_LIGHT_ANGLE_DEFAULT;
uniform float LabelRadius < ui_type = "slider"; ui_label = "Label Size"; ui_tooltip = "Radius of the center label area."; ui_min = 0.05; ui_max = 0.25; ui_step = 0.005; ui_category = "Vinyl Disc"; > = LABEL_RADIUS_DEFAULT;
uniform bool UseLabelTexture < ui_label = "Use Label Texture"; ui_tooltip = "Use a custom texture for the label area instead of a solid color.\nSet texture via preprocessor: VinylDisc_LabelFileName"; ui_category = "Vinyl Disc"; > = false;
uniform float3 LabelColor < ui_type = "color"; ui_label = "Label Color"; ui_tooltip = "Color of the center label area (when not using texture)."; ui_category = "Vinyl Disc"; > = float3(0.15, 0.08, 0.08);
uniform float PictureSpinSpeed < ui_type = "slider"; ui_label = "Picture Disc Spin Speed"; ui_tooltip = "Rotation speed of the scene image on Picture Disc mode. Negative = reverse."; ui_min = PICTURE_SPIN_SPEED_MIN; ui_max = PICTURE_SPIN_SPEED_MAX; ui_step = 0.01; ui_category = "Vinyl Disc"; > = PICTURE_SPIN_SPEED_DEFAULT;
uniform float EdgeSoftness < ui_type = "slider"; ui_label = "Edge Softness"; ui_tooltip = "Controls the sharpness of disc edges, grooves, and track boundaries. 0 = razor sharp, 1 = soft/fuzzy."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Vinyl Disc"; > = EDGE_SHARPNESS_DEFAULT;

// --- Background ---
uniform int BackgroundStyle < ui_type = "combo"; ui_label = "Background Style"; ui_tooltip = "Visual style behind the vinyl disc."; ui_items = "None (Transparent)\0Neon Rings\0Neon Burst\0Geometric Pop\0Waveform\0"; ui_category = "Background"; > = BG_NEON_RINGS;
uniform float BackgroundIntensity < ui_type = "slider"; ui_label = "Background Brightness"; ui_tooltip = "Glow brightness of background elements."; ui_min = BG_INTENSITY_MIN; ui_max = BG_INTENSITY_MAX; ui_step = 0.01; ui_category = "Background"; > = BG_INTENSITY_DEFAULT;
uniform float RingSpeed < ui_type = "slider"; ui_label = "Ring / Burst Rotation Speed"; ui_tooltip = "Rotation speed for neon rings and burst rays."; ui_min = RING_SPEED_MIN; ui_max = RING_SPEED_MAX; ui_step = 0.01; ui_category = "Background"; > = RING_SPEED_DEFAULT;
uniform int ParticleCount < ui_type = "slider"; ui_label = "Particle Count"; ui_tooltip = "Number of geometric particles (Geometric Pop mode)."; ui_min = 4; ui_max = PARTICLE_COUNT_MAX; ui_step = 1; ui_category = "Background"; > = PARTICLE_COUNT_DEFAULT;

// --- Palette (iridescence + background) ---
AS_PALETTE_SELECTION_UI(BgPalette, "Color Palette", AS_PALETTE_NEON, AS_CAT_PALETTE)
AS_DECLARE_CUSTOM_PALETTE(VinylDisc_, AS_CAT_PALETTE)
uniform bool InvertPalette < ui_label = "Invert Palette"; ui_tooltip = "Reverses the palette color order in the iridescence wedge."; ui_category = AS_CAT_PALETTE; > = false;
uniform bool UseRainbowIridescence < ui_label = "Rainbow Iridescence"; ui_tooltip = "Use physics-based thin-film interference (oily rainbow) instead of palette colors for the iridescence."; ui_category = AS_CAT_PALETTE; > = false;

// --- Position & Transform ---
AS_POSITION_SCALE_UI(EffectCenter, EffectScale)
AS_ROTATION_UI(SnapRotation, FineRotation)

// --- Animation ---
AS_ANIMATION_UI(AnimSpeed, AnimKeyframe, AS_CAT_ANIMATION)

// --- Audio Reactivity ---
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_BEAT, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(AudioMult, "Audio Multiplier", 1.0, 3.0, AS_CAT_AUDIO)
uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target"; ui_tooltip = "Which parameter responds to audio input."; ui_items = "None\0Iridescence Intensity\0Reflection Spread\0Spin Speed\0Background Intensity\0All\0"; ui_category = AS_CAT_AUDIO; > = 4;

// --- Stage ---
AS_STAGEDEPTH_UI(EffectDepth)

// --- Final Mix ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug ---
AS_DEBUG_UI("Off\0Disc Mask\0Groove Pattern\0Iridescence Only\0Background Only\0Normals\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Get LP base color from preset
float3 getLPBaseColor(int preset, float3 customColor) {
    if (preset == LP_BLACK)  return float3(0.02, 0.02, 0.025);
    if (preset == LP_PEARL)  return float3(0.85, 0.85, 0.88);
    if (preset == LP_RED)    return float3(0.45, 0.02, 0.02);
    if (preset == LP_BLUE)   return float3(0.02, 0.05, 0.45);
    if (preset == LP_GREEN)  return float3(0.02, 0.35, 0.05);
    if (preset == LP_GOLD)   return float3(0.75, 0.65, 0.25);
    if (preset == LP_SILVER) return float3(0.7, 0.7, 0.72);
    if (preset == LP_CUSTOM) return customColor;
    return float3(0.02, 0.02, 0.025); // fallback (also LP_PICTURE base)
}

// Iridescence color from palette: maps angular phase to palette index 0→1→0
// At wedge center (phase=0) = palette index 0, at wedge edges (phase=±1) = palette max, back to 0
float3 iridescenceColor(float normalizedPhase) {
    float t = saturate(abs(normalizedPhase));

    if (UseRainbowIridescence) {
        // Physics-based thin-film interference (oily rainbow)
        float phase = normalizedPhase * 6.5;
        float3 rainbow = float3(
            cos(phase),
            cos(phase + 2.094), // +2pi/3
            cos(phase + 4.189)  // +4pi/3
        );
        return saturate((rainbow * 0.5 + 0.5) * IridescenceBoost);
    }

    // Palette-based: palette[0] at center, palette[max] at edges
    if (InvertPalette) t = 1.0 - t;
    float3 color = AS_GET_PALETTE_COLOR(VinylDisc_, BgPalette, t);
    return saturate(color * IridescenceBoost);
}

// Calculate the angular mask for the reflection wedge
// Returns 0 outside the wedge, 1 at the center of the wedge, smooth falloff
float iridescenceWedgeMask(float angle, float lightAngle, float wedgeWidth) {
    // Angular distance between pixel and light source direction
    float angleDiff = angle - lightAngle;
    // Wrap to [-PI, PI]
    angleDiff = angleDiff - AS_TWO_PI * floor((angleDiff + AS_PI) / AS_TWO_PI);
    // Map wedge width: 0.1-1.0 → narrow to wide angular coverage
    float halfWedge = wedgeWidth * AS_PI; // max = full PI = half the disc
    // Smooth falloff from center of wedge to edges
    float mask = 1.0 - smoothstep(0.0, halfWedge, abs(angleDiff));
    // Sharpen the falloff slightly for a more realistic light reflection
    return mask * mask;
}

// Render neon rings background
float3 renderNeonRings(float2 uv, float dist, float angle, float time, float intensity) {
    float3 bgColor = float3(0.0, 0.0, 0.0);

    // Blue rings rotating clockwise
    float blueAngle = angle + time * RingSpeed;
    for (int i = 0; i < 6; i++) {
        float ringDist = 0.2 + float(i) * 0.08;
        float ringMask = 1.0 - smoothstep(0.0, NEON_RING_THICKNESS, abs(dist - ringDist));
        // Angular fade creates partial arcs
        float arcMask = saturate(sin(blueAngle * 2.0 + float(i) * 1.047) * 0.5 + 0.5);
        float3 ringColor = AS_GET_PALETTE_COLOR(VinylDisc_, BgPalette, frac(float(i) / 6.0));
        bgColor += ringColor * ringMask * arcMask * intensity;
    }

    // Purple rings rotating counter-clockwise
    float purpleAngle = angle - time * RingSpeed * 0.8;
    for (int j = 0; j < 4; j++) {
        float ringDist = 0.25 + float(j) * 0.1;
        float ringMask = 1.0 - smoothstep(0.0, NEON_RING_THICKNESS * 1.5, abs(dist - ringDist));
        float arcMask = saturate(sin(purpleAngle * 3.0 + float(j) * 1.571) * 0.5 + 0.5);
        float3 ringColor = AS_GET_PALETTE_COLOR(VinylDisc_, BgPalette, frac(float(j) / 4.0 + 0.5));
        bgColor += ringColor * ringMask * arcMask * intensity * 0.6;
    }

    return bgColor;
}

// Render neon burst background (radial streaks)
float3 renderNeonBurst(float2 uv, float dist, float angle, float time, float intensity) {
    float3 bgColor = float3(0.0, 0.0, 0.0);
    float rotAngle = angle + time * RingSpeed * 0.3;

    // Radial rays
    float rayPattern = pow(abs(sin(rotAngle * BURST_RAY_COUNT * 0.5)), 8.0);
    float distFade = exp(-dist * 2.5) * 0.8 + exp(-dist * 0.8) * 0.2;
    float3 rayColor = AS_GET_PALETTE_COLOR(VinylDisc_, BgPalette, frac(rotAngle / AS_TWO_PI));
    bgColor += rayColor * rayPattern * distFade * intensity;

    // Subtle glow at center
    float centerGlow = exp(-dist * 4.0);
    float3 glowColor = AS_GET_PALETTE_COLOR(VinylDisc_, BgPalette, frac(time * 0.1));
    bgColor += glowColor * centerGlow * intensity * 0.3;

    return bgColor;
}

// Render geometric pop background (animated rectangles)
float3 renderGeometricPop(float2 uv, float time, float intensity) {
    float3 bgColor = float3(0.0, 0.0, 0.0);

    for (int i = 0; i < PARTICLE_COUNT_MAX; i++) {
        if (i >= ParticleCount) break;

        // Deterministic pseudo-random position and timing per particle
        float seed = float(i) * 7.31;
        float2 particlePos = float2(
            AS_hash11(seed) * 1.6 - 0.8,
            AS_hash11(seed + 3.7) * 1.6 - 0.8
        );

        // Lifecycle: fade in, brighten, fade out, repeat
        float cycleTime = frac(time * 0.2 + AS_hash11(seed + 1.1));
        float lifecycle = sin(cycleTime * AS_PI); // 0 → 1 → 0
        lifecycle = lifecycle * lifecycle; // sharper falloff

        // Rectangle SDF
        float2 diff = abs(uv - particlePos);
        float rectSize = 0.02 + AS_hash11(seed + 5.5) * 0.04;
        float aspectR = 0.5 + AS_hash11(seed + 8.8) * 1.0;
        float rect = max(diff.x / (rectSize * aspectR), diff.y / rectSize);
        float rectMask = 1.0 - smoothstep(0.8, 1.0, rect);

        // Slight rotation per particle
        float pAngle = AS_hash11(seed + 2.2) * AS_TWO_PI + time * 0.3;
        float2 rotDiff = AS_rotate2D(diff, pAngle);
        float rotRect = max(abs(rotDiff.x) / (rectSize * aspectR), abs(rotDiff.y) / rectSize);
        rectMask = 1.0 - smoothstep(0.8, 1.0, rotRect);

        float3 particleColor = AS_GET_PALETTE_COLOR(VinylDisc_, BgPalette, frac(float(i) / float(ParticleCount)));
        bgColor += particleColor * rectMask * lifecycle * intensity;
    }

    return bgColor;
}

// Render waveform ring background
float3 renderWaveform(float2 uv, float dist, float angle, float time, float intensity) {
    float3 bgColor = float3(0.0, 0.0, 0.0);

    // Audio waveform ring around disc
    float waveRadius = DISC_RADIUS + 0.05;
    float audioLevel = AS_audioLevelFromSource(AudioSource);

    // Create a wavy ring
    float waveOffset = sin(angle * 16.0 + time * 3.0) * 0.015 * (0.3 + audioLevel * 0.7);
    waveOffset += sin(angle * 8.0 - time * 2.0) * 0.008;
    float ringDist = abs(dist - waveRadius - waveOffset);
    float ringMask = 1.0 - smoothstep(0.0, 0.012, ringDist);

    // Color based on angle
    float3 waveColor = AS_GET_PALETTE_COLOR(VinylDisc_, BgPalette, frac(angle / AS_TWO_PI + time * 0.05));
    bgColor += waveColor * ringMask * intensity;

    // Second thinner ring
    float wave2Offset = sin(angle * 12.0 - time * 4.0) * 0.01 * (0.2 + audioLevel * 0.8);
    float ring2Dist = abs(dist - waveRadius - 0.03 - wave2Offset);
    float ring2Mask = 1.0 - smoothstep(0.0, 0.006, ring2Dist);
    float3 wave2Color = AS_GET_PALETTE_COLOR(VinylDisc_, BgPalette, frac(angle / AS_TWO_PI + time * 0.05 + 0.5));
    bgColor += wave2Color * ring2Mask * intensity * 0.6;

    return bgColor;
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_VinylDisc(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Depth-aware early return
    AS_DEPTH_EARLY_RETURN(texcoord, EffectDepth)

    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float time = AS_getAnimationTime(AnimSpeed, AnimKeyframe);

    // --- Audio modulation ---
    float audioIridescence = (AudioTarget == 1 || AudioTarget == 5)
        ? AS_audioModulate(IridescenceStrength, AudioSource, AudioMult, true, 0)
        : IridescenceStrength;
    float audioWedgeWidth = (AudioTarget == 2 || AudioTarget == 5)
        ? AS_audioModulate(IridWedgeWidth, AudioSource, AudioMult, true, 0)
        : IridWedgeWidth;
    float audioSpinMult = (AudioTarget == 3 || AudioTarget == 5)
        ? AS_audioModulate(1.0, AudioSource, AudioMult, true, 0)
        : 1.0;
    float audioBgIntensity = (AudioTarget == 4 || AudioTarget == 5)
        ? AS_audioModulate(BackgroundIntensity, AudioSource, AudioMult, true, 0)
        : BackgroundIntensity;

    // --- Coordinate transformation ---
    float globalRotation = AS_getRotationRadians(SnapRotation, FineRotation);
    float2 centered = AS_centeredUVWithAspect(texcoord, ReShade::AspectRatio);

    // Apply position offset
    centered.x -= EffectCenter.x * (ReShade::AspectRatio >= 1.0 ? ReShade::AspectRatio * 0.5 : 0.5);
    centered.y += EffectCenter.y * (ReShade::AspectRatio < 1.0 ? (1.0 / ReShade::AspectRatio) * 0.5 : 0.5);

    // Apply scale
    float2 scaled = centered / max(EffectScale, AS_EPSILON);

    // Apply rotation
    float2 uv = AS_rotate2D(scaled, globalRotation);

    // --- Polar coordinates ---
    float dist = length(uv);
    float angle = atan2(uv.y, uv.x);

    // Spin rotation (applied to disc and groove angle calculation)
    float spinAngle = time * SPIN_SPEED_DEFAULT * audioSpinMult;

    // --- Debug: Background Only ---
    if (DebugMode == 4) {
        float3 bg = float3(0.0, 0.0, 0.0);
        if (BackgroundStyle == BG_NEON_RINGS)    bg = renderNeonRings(uv, dist, angle, time, audioBgIntensity);
        if (BackgroundStyle == BG_NEON_BURST)    bg = renderNeonBurst(uv, dist, angle, time, audioBgIntensity);
        if (BackgroundStyle == BG_GEOMETRIC_POP) bg = renderGeometricPop(uv, time, audioBgIntensity);
        if (BackgroundStyle == BG_WAVEFORM)      bg = renderWaveform(uv, dist, angle, time, audioBgIntensity);
        return float4(bg, 1.0);
    }

    // --- Render background layer ---
    float3 bgLayer = float3(0.0, 0.0, 0.0);
    if (BackgroundStyle == BG_NEON_RINGS)    bgLayer = renderNeonRings(uv, dist, angle, time, audioBgIntensity);
    if (BackgroundStyle == BG_NEON_BURST)    bgLayer = renderNeonBurst(uv, dist, angle, time, audioBgIntensity);
    if (BackgroundStyle == BG_GEOMETRIC_POP) bgLayer = renderGeometricPop(uv, time, audioBgIntensity);
    if (BackgroundStyle == BG_WAVEFORM)      bgLayer = renderWaveform(uv, dist, angle, time, audioBgIntensity);

    // --- Disc SDF masks (softness scales all transition widths) ---
    float sf = lerp(0.0002, DISC_EDGE_SOFTNESS_BASE, EdgeSoftness); // minimum prevents aliasing
    float discMask = 1.0 - smoothstep(DISC_RADIUS - sf, DISC_RADIUS + sf, dist);
    float holeMask = smoothstep(CENTER_HOLE_RADIUS - sf, CENTER_HOLE_RADIUS + sf, dist);
    float labelMask = 1.0 - smoothstep(LabelRadius - sf, LabelRadius + sf, dist);
    float grooveArea = discMask * holeMask * (1.0 - labelMask);

    // --- Debug: Disc Mask ---
    if (DebugMode == 1) return float4(discMask.xxx, 1.0);

    // --- Track/Groove rendering ---
    float grooveAngle = angle + spinAngle;

    // Map distance into the groove region (label edge → disc edge)
    float grooveRegionStart = LabelRadius + GROOVE_START_OFFSET;
    float grooveRegionEnd = DISC_RADIUS - 0.01;
    float grooveRegionWidth = grooveRegionEnd - grooveRegionStart;
    float normalizedDist = saturate((dist - grooveRegionStart) / max(grooveRegionWidth, AS_EPSILON));

    // Which track band are we in? (0 to TrackCount-1)
    float trackFloat = normalizedDist * float(TrackCount);
    float trackIndex = floor(trackFloat);
    float trackFrac = frac(trackFloat); // position within current track (0-1)

    // Gap between tracks: trackFrac near 0 or 1 = gap region
    float gapSoft = lerp(0.005, TRACK_GAP, EdgeSoftness);
    float gapMask = smoothstep(0.0, gapSoft, trackFrac) * (1.0 - smoothstep(1.0 - gapSoft, 1.0, trackFrac));

    // Fine groove lines within each track band
    float groovePattern = 0.0;
    float grooveShading = 1.0;
    float ridgeHighlight = 0.0;
    if (GrooveLinesPerTrack > 0) {
        float groovePhase = trackFrac * float(GrooveLinesPerTrack);
        groovePattern = sin(groovePhase * AS_TWO_PI);
        grooveShading = 1.0 - GrooveDepth * (groovePattern * 0.5 + 0.5);
        ridgeHighlight = pow(saturate(groovePattern), 4.0) * GrooveGlow * gapMask;
    }

    // Apply gap: darken gap regions slightly
    grooveShading = lerp(0.6, grooveShading, gapMask);

    // --- Debug: Groove Pattern ---
    if (DebugMode == 2) return float4((grooveShading * gapMask + ridgeHighlight).xxx, 1.0);

    // --- LP base color ---
    float3 lpBaseColor = getLPBaseColor(LPColorPreset, CustomLPColor);

    // Picture Disc: show a rotating copy of the scene through the disc
    if (LPColorPreset == LP_PICTURE) {
        // Rotate the UV coordinates around the disc center to sample the scene
        float pictureAngle = time * PictureSpinSpeed;
        float2 rotatedUV = AS_rotate2D(uv, pictureAngle);
        // Convert back from centered coordinates to texcoord space
        rotatedUV.x /= ReShade::AspectRatio;
        float2 picTexcoord = rotatedUV * 0.5 + AS_HALF;
        // Clamp to screen bounds to avoid sampling outside
        picTexcoord = saturate(picTexcoord);
        lpBaseColor = tex2Dlod(ReShade::BackBuffer, float4(picTexcoord, 0, 0)).rgb * 0.7;
    }

    // --- Thin-film iridescence (wedge reflection model) ---
    // Light source angle rotates with iridescence speed
    float lightAngle = IridLightAngle * AS_TWO_PI + time * IridescenceSpeed;

    // Color is determined by angular distance from light source
    // This creates rainbow spokes radiating from center (like real vinyl reflections)
    float angleDiff = angle - lightAngle;
    angleDiff = angleDiff - AS_TWO_PI * floor((angleDiff + AS_PI) / AS_TWO_PI);
    float angularPhase = angleDiff / (audioWedgeWidth * AS_PI); // normalized within wedge [-1, 1]
    float3 iridColor = iridescenceColor(angularPhase);

    // Wedge mask: reflection appears in two opposite segments (light + mirror)
    float wedgeMask1 = iridescenceWedgeMask(angle, lightAngle, audioWedgeWidth);
    float wedgeMask2 = iridescenceWedgeMask(angle, lightAngle + AS_PI, audioWedgeWidth);

    // Mirror wedge uses mirrored angular phase for color
    float angleDiff2 = angle - (lightAngle + AS_PI);
    angleDiff2 = angleDiff2 - AS_TWO_PI * floor((angleDiff2 + AS_PI) / AS_TWO_PI);
    float angularPhase2 = angleDiff2 / (audioWedgeWidth * AS_PI);
    float3 iridColor2 = iridescenceColor(angularPhase2);

    // Blend both wedges (wedge shape already baked into color)
    iridColor = iridColor * wedgeMask1 + iridColor2 * wedgeMask2;

    // Combine: strength * gap visibility (wedge already in iridColor)
    float iridMask = audioIridescence * gapMask;

    // Pearl/metallic presets get extra iridescence
    if (LPColorPreset == LP_PEARL || LPColorPreset == LP_GOLD || LPColorPreset == LP_SILVER) {
        iridMask *= 1.5;
    }

    // --- Debug: Iridescence Only ---
    if (DebugMode == 3) return float4(iridColor * iridMask * grooveArea, 1.0);

    // --- Compose disc surface ---
    float3 discSurface = lpBaseColor * grooveShading + ridgeHighlight;
    discSurface = discSurface + iridColor * iridMask * grooveArea;

    // --- Label area ---
    float3 labelSurface = LabelColor;
    if (UseLabelTexture) {
        // Map disc-space coordinates to label UV (centered, scaled to label radius)
        // Rotate label with the disc spin
        float2 labelUV = AS_rotate2D(uv, spinAngle);
        labelUV = labelUV / (LabelRadius * 2.0) + 0.5; // map [-labelRadius, labelRadius] to [0, 1]
        // Correct for texture aspect ratio
        float texAspect = float(VinylDisc_LabelWidth) / float(VinylDisc_LabelHeight);
        labelUV.x = (labelUV.x - 0.5) / texAspect + 0.5;
        float4 labelTex = tex2Dlod(VinylDisc_LabelSampler, float4(labelUV, 0, 0));
        labelSurface = lerp(LabelColor, labelTex.rgb, labelTex.a);
    }

    // --- Combine disc layers ---
    float3 discFinal = lerp(discSurface, labelSurface, labelMask);
    discFinal *= discMask * holeMask; // cut out center hole

    // --- Debug: Normals (depth-based) ---
    if (DebugMode == 5) {
        // Show the radial normal direction for debugging
        float2 normalDir = (dist > AS_EPSILON) ? normalize(uv) : float2(0.0, 0.0);
        return float4(normalDir * 0.5 + 0.5, 0.5, 1.0);
    }

    // --- Final composition ---
    // Background shows through where disc is absent
    float discAlpha = discMask * holeMask;
    float3 effectColor = lerp(bgLayer, discFinal, discAlpha);

    // For BG_NONE, make non-disc areas transparent to scene
    float effectAlpha;
    if (BackgroundStyle == BG_NONE) {
        effectAlpha = discAlpha;
    } else {
        // Background has content, so full opacity where either disc or bg exists
        float bgAlpha = saturate(length(bgLayer) * 2.0);
        effectAlpha = saturate(discAlpha + bgAlpha);
    }

    // Blend with scene
    float4 effectResult = float4(effectColor, effectAlpha);
    float4 result = AS_blendRGBA(effectResult, originalColor, BlendMode, BlendAmount);
    return result;
}

} // namespace AS_VinylDisc

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_BGX_VinylDisc <
    ui_label = "[AS] BGX: Vinyl Disc";
    ui_tooltip = "Spinning vinyl record with iridescent grooves and animated backgrounds.";
>
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = AS_VinylDisc::PS_VinylDisc;
    }
}

#endif // __AS_BGX_VinylDisc_1_fx
