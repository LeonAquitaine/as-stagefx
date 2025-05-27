/**
 * AS_GFX_ArtDecoFrame.1.fx - Art Deco/Nouveau Frame Generator with Procedural Gold Material
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION: * Generates ornate Art Deco/Art Nouveau style decorative frames with realistic procedural gold material simulation.
 * Creates geometric patterns with diamonds, tramlines, and decorative fans, all rendered in authentic metallic gold.
 *
 * FEATURES:
 * - Complex geometric frame construction with multiple layers and decorative elements
 * - Procedural gold material with surface roughness, metallic reflections, and Fresnel effects
 * - Configurable tramlines, corner diamonds, and decorative fans with mirroring support
 * - Real-time surface noise simulation for authentic gold texture variation
 * - Audio reactivity for dynamic animation and parameter control
 * - Stage depth masking for proper 3D scene integration
 * - Customizable animation speed and keyframe positioning
 * - Standard blend modes for seamless scene compositing
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Constructs Art Deco frame geometry using signed distance field functions
 * 2. Applies procedural gold material using HSV color space and fractal noise
 * 3. Simulates surface imperfections with FBM noise for realistic metal appearance
 * 4. Implements Fresnel effects for authentic metallic reflection behavior
 * 5. Renders elements in proper Z-order: fans, diamonds, and frame boxes
 * 6. Integrates audio reactivity and stage depth controls for dynamic effects
 *
 * ===================================================================================
 */
 
// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_GFX_ArtDecoFrame_1_fx
#define __AS_GFX_ArtDecoFrame_1_fx

#include "ReShade.fxh"
#include "AS_Noise.1.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

// ============================================================================
// CONSTANTS - Replace magic numbers for better maintainability
// ============================================================================
static const float ARTDECO_BORDER_EDGE = 0.001f;

// Resolution and scaling constants
static const float ARTDECO_RESOLUTION_BASELINE = AS_RESOLUTION_BASE_HEIGHT; // Use AS_Utils constant

// Audio reactivity scaling factors
static const float ARTDECO_AUDIO_BRIGHTNESS_SCALE = AS_HALF;
static const float ARTDECO_AUDIO_NOISE_SCALE = 0.8f;
static const float ARTDECO_AUDIO_FRESNEL_SCALE = 0.3f;
static const float ARTDECO_AUDIO_SURFACE_SCALE = 0.6f;

// Noise generation parameters
static const int ARTDECO_NOISE_OCTAVES = 4;
static const float ARTDECO_NOISE_LACUNARITY = 2.0f;
static const float ARTDECO_NOISE_GAIN = AS_HALF;

// Material appearance constants
static const float ARTDECO_FILL_BRIGHTNESS_FACTOR = 0.7f;
static const float ARTDECO_LINE_BRIGHTNESS_FACTOR = 1.2f;
static const float ARTDECO_METALLIC_ROUGHNESS_FACTOR = AS_HALF;
static const float ARTDECO_NOISE_METALLIC_FACTOR = AS_HALF;
static const float ARTDECO_HIGHLIGHT_BLEND_FACTOR = 0.3f;

// Color channel noise variation
static const float ARTDECO_NOISE_RED_INTENSITY = 0.4f;
static const float ARTDECO_NOISE_GREEN_INTENSITY = 0.3f;
static const float ARTDECO_NOISE_BLUE_INTENSITY = 0.2f;

// Noise sample offsets for color channel variation
static const float ARTDECO_NOISE_OFFSET_RED = 0.1f;
static const float ARTDECO_NOISE_OFFSET_GREEN = 0.3f;
static const float ARTDECO_NOISE_OFFSET_BLUE = 0.7f;

// Metallic highlight colors
static const float3 ARTDECO_METALLIC_TINT = float3(1.0f, 0.95f, 0.8f);
static const float3 ARTDECO_HIGHLIGHT_COLOR_BASE = float3(1.0f, 0.9f, 0.7f);
static const float3 ARTDECO_HIGHLIGHT_COLOR_BRIGHT = float3(1.2f, 1.0f, 0.8f);

// Geometry constants
static const float ARTDECO_ROTATION_45_DEG = AS_QUARTER_PI;
static const float ARTDECO_SNAP_ROTATION_STEP = 90.0f;
static const float ARTDECO_FAN_ANGLE_CENTER = AS_HALF;
static const float ARTDECO_FAN_LENGTH_OFFSET_FACTOR = AS_HALF;
static const float ARTDECO_FAN_DIRECTION_UP = 1.0f;
static const float ARTDECO_FAN_DIRECTION_DOWN = -1.0f;
static const float ARTDECO_SMOOTHSTEP_EDGE_2X = ARTDECO_BORDER_EDGE * 2.0f;

// UI Parameter Constants - Min, Max, Default values
// Gold Style parameters
static const float GOLD_HUE_MIN = 0.0f;
static const float GOLD_HUE_MAX = 360.0f;
static const float GOLD_HUE_DEFAULT = 45.0f;

static const float GOLD_SATURATION_MIN = AS_RANGE_ZERO_ONE_MIN;
static const float GOLD_SATURATION_MAX = AS_RANGE_ZERO_ONE_MAX;
static const float GOLD_SATURATION_DEFAULT = 0.8f;

static const float GOLD_BRIGHTNESS_MIN = AS_RANGE_ZERO_ONE_MIN;
static const float GOLD_BRIGHTNESS_MAX = 2.0f;
static const float GOLD_BRIGHTNESS_DEFAULT = 0.85f;

static const float GOLD_METALLIC_MIN = AS_RANGE_ZERO_ONE_MIN;
static const float GOLD_METALLIC_MAX = AS_RANGE_ZERO_ONE_MAX;
static const float GOLD_METALLIC_DEFAULT = 0.9f;

static const float GOLD_ROUGHNESS_MIN = 0.01f;
static const float GOLD_ROUGHNESS_MAX = AS_RANGE_ZERO_ONE_MAX;
static const float GOLD_ROUGHNESS_DEFAULT = 0.2f;

static const float NOISE_SCALE_MIN = 0.1f;
static const float NOISE_SCALE_MAX = 20.0f;
static const float NOISE_SCALE_DEFAULT = 3.0f;

static const float NOISE_INTENSITY_MIN = AS_RANGE_ZERO_ONE_MIN;
static const float NOISE_INTENSITY_MAX = 2.0f;
static const float NOISE_INTENSITY_DEFAULT = 0.6f;

static const float NOISE_BRIGHTNESS_MIN = AS_RANGE_ZERO_ONE_MIN;
static const float NOISE_BRIGHTNESS_MAX = 2.0f;
static const float NOISE_BRIGHTNESS_DEFAULT = 0.8f;

static const float FRESNEL_POWER_MIN = 0.1f;
static const float FRESNEL_POWER_MAX = 10.0f;
static const float FRESNEL_POWER_DEFAULT = 5.0f;

// Frame size parameters
static const float FRAME_SIZE_MIN = 0.05f;
static const float FRAME_SIZE_MAX = 2.0f;
static const float2 MAIN_SIZE_DEFAULT = float2(0.7f, 0.5f);
static const float2 SUB_SIZE_DEFAULT = float2(0.4f, 0.35f);

// Decorative elements parameters
static const float DIAMOND_SIZE_MIN = 0.05f;
static const float DIAMOND_SIZE_MAX = 3.0f;
static const float DIAMOND_SIZE_DEFAULT = 0.9f;

static const float CORNER_DIAMOND_SIZE_MIN = 0.02f;
static const float CORNER_DIAMOND_SIZE_MAX = AS_RANGE_ZERO_ONE_MAX;
static const float CORNER_DIAMOND_SIZE_DEFAULT = 0.2f;

static const int FAN_LINE_COUNT_MIN = 3;
static const int FAN_LINE_COUNT_MAX = 50;
static const int FAN_LINE_COUNT_DEFAULT = 25;

static const float FAN_SPREAD_MIN = 10.0f;
static const float FAN_SPREAD_MAX = 180.0f;
static const float FAN_SPREAD_DEFAULT = 90.0f;

static const float FAN_LENGTH_MIN = 0.1f;
static const float FAN_LENGTH_MAX = 2.0f;
static const float FAN_LENGTH_DEFAULT = 0.6f;

static const float FAN_POSITION_MIN = AS_RANGE_ZERO_ONE_MIN;
static const float FAN_POSITION_MAX = AS_RANGE_ZERO_ONE_MAX;
static const float FAN_POSITION_DEFAULT = 0.45f;

// Advanced parameters
static const int NUM_TRAMLINES_MIN = 1;
static const int NUM_TRAMLINES_MAX = 5;
static const int NUM_TRAMLINES_DEFAULT = 3;

static const float BORDER_THICKNESS_MIN = 0.001f;
static const float BORDER_THICKNESS_MAX = 0.1f;
static const float BORDER_THICKNESS_DEFAULT = 0.02f;

static const float TRAMLINE_THICKNESS_MIN = 0.0005f;
static const float TRAMLINE_THICKNESS_MAX = 0.01f;
static const float TRAMLINE_THICKNESS_DEFAULT = 0.0015f;

static const float TRAMLINE_SPACING_MIN = 0.001f;
static const float TRAMLINE_SPACING_MAX = 0.02f;
static const float TRAMLINE_SPACING_DEFAULT = 0.003f;

static const float DETAIL_PADDING_MIN = 0.001f;
static const float DETAIL_PADDING_MAX = 0.2f;
static const float DETAIL_PADDING_DEFAULT = 0.01f;

static const float DETAIL_LINE_WIDTH_MIN = 0.001f;
static const float DETAIL_LINE_WIDTH_MAX = 0.05f;
static const float DETAIL_LINE_WIDTH_DEFAULT = 0.005f;

static const float FAN_BASE_RADIUS_MIN = AS_RANGE_ZERO_ONE_MIN;
static const float FAN_BASE_RADIUS_MAX = AS_HALF;
static const float FAN_BASE_RADIUS_DEFAULT = 0.05f;

static const float FAN_LINE_THICKNESS_MIN = 0.0005f;
static const float FAN_LINE_THICKNESS_MAX = 0.005f;
static const float FAN_LINE_THICKNESS_DEFAULT = 0.001f;

// Default colors
static const float3 FRAME_FILL_COLOR_DEFAULT = float3(0.05f, 0.05f, 0.05f);
static const float3 FRAME_LINE_COLOR_DEFAULT = float3(0.9f, 0.75f, 0.35f);

// Audio parameters
static const float AUDIO_MULT_MIN = 1.0f;
static const float AUDIO_MULT_MAX = 4.0f;
static const int AUDIO_TARGET_DEFAULT = 0;

// Fresnel power clamp range
static const float FRESNEL_POWER_CLAMP_MIN = 0.1f;
static const float FRESNEL_POWER_CLAMP_MAX = 20.0f;

// Palette blend parameter
static const float PALETTE_BLEND_MIN = AS_RANGE_ZERO_ONE_MIN;
static const float PALETTE_BLEND_MAX = AS_RANGE_ZERO_ONE_MAX;
static const float PALETTE_BLEND_DEFAULT = 0.3f;

// Rotation constants
static const float ARTDECO_SNAP_ROTATION_STEP = 90.0f;
static const float ARTDECO_DEGREES_TO_RADIANS = AS_PI / 180.0f;

// Fan drawing constants
static const float ARTDECO_FAN_MIN_DIST_INIT = 10.0f;
static const float ARTDECO_BORDER_EDGE_DOUBLE = ARTDECO_BORDER_EDGE * 2.0f;

// Palette integration constants
static const float ARTDECO_PALETTE_RESOLUTION_BASE = 1080.0f;
static const float ARTDECO_PALETTE_BLEND_FACTOR = 0.3f;
static const int ARTDECO_PALETTE_NOISE_OCTAVES = 4;
static const float ARTDECO_PALETTE_NOISE_LACUNARITY = 2.0f;
static const float ARTDECO_PALETTE_NOISE_GAIN = AS_HALF;

// Coordinate transformation constants
static const float ARTDECO_SQUARE_SPACE_SCALE = 2.0f;
static const float ARTDECO_SCREEN_CENTER_FACTOR = AS_HALF;
static const float ARTDECO_HSV_HUE_DIVISOR = 60.0f;
static const float ARTDECO_THICKNESS_HALF_FACTOR = AS_HALF;
static const float ARTDECO_EPSILON = 0.000001f;
static const float ARTDECO_FILL_ALPHA_THRESHOLD = 0.1f;

// === UI Controls ===
// Gold Style - Main Visual Appearance
uniform float GoldHue < ui_label="Hue"; ui_type="slider"; ui_min=GOLD_HUE_MIN; ui_max=GOLD_HUE_MAX; ui_category="Gold Style"; > = GOLD_HUE_DEFAULT;
uniform float GoldSaturation < ui_label="Saturation"; ui_type="slider"; ui_min=GOLD_SATURATION_MIN; ui_max=GOLD_SATURATION_MAX; ui_category="Gold Style"; > = GOLD_SATURATION_DEFAULT;
uniform float GoldBrightness < ui_label="Brightness"; ui_type="slider"; ui_min=GOLD_BRIGHTNESS_MIN; ui_max=GOLD_BRIGHTNESS_MAX; ui_category="Gold Style"; > = GOLD_BRIGHTNESS_DEFAULT;
uniform float GoldMetallic < ui_label="Metallic"; ui_type="slider"; ui_min=GOLD_METALLIC_MIN; ui_max=GOLD_METALLIC_MAX; ui_category="Gold Style"; > = GOLD_METALLIC_DEFAULT;
uniform float GoldRoughness < ui_label="Roughness"; ui_type="slider"; ui_min=GOLD_ROUGHNESS_MIN; ui_max=GOLD_ROUGHNESS_MAX; ui_category="Gold Style"; > = GOLD_ROUGHNESS_DEFAULT;
uniform float NoiseScale < ui_label="Texture Scale"; ui_type="slider"; ui_min=NOISE_SCALE_MIN; ui_max=NOISE_SCALE_MAX; ui_category="Gold Style"; > = NOISE_SCALE_DEFAULT;
uniform float NoiseIntensity < ui_label="Texture Strength"; ui_type="slider"; ui_min=NOISE_INTENSITY_MIN; ui_max=NOISE_INTENSITY_MAX; ui_category="Gold Style"; > = NOISE_INTENSITY_DEFAULT;
uniform float NoiseBrightness < ui_label="Texture Brightness"; ui_type="slider"; ui_min=NOISE_BRIGHTNESS_MIN; ui_max=NOISE_BRIGHTNESS_MAX; ui_category="Gold Style"; > = NOISE_BRIGHTNESS_DEFAULT;
uniform float FresnelPower < ui_label="Shine"; ui_type="slider"; ui_min=FRESNEL_POWER_MIN; ui_max=FRESNEL_POWER_MAX; ui_category="Gold Style"; > = FRESNEL_POWER_DEFAULT;

// Frame Size - Basic Dimensions
uniform float2 MainSize < ui_label="Outer Frame"; ui_type="slider"; ui_min=FRAME_SIZE_MIN; ui_max=FRAME_SIZE_MAX; ui_category="Frame Size"; > = MAIN_SIZE_DEFAULT;
uniform float2 SubSize < ui_label="Inner Frame"; ui_type="slider"; ui_min=FRAME_SIZE_MIN; ui_max=FRAME_SIZE_MAX; ui_category="Frame Size"; > = SUB_SIZE_DEFAULT;

// Decorative Elements - Diamonds, Towers & Fans
uniform float DiamondScalarSize < ui_label="Center Diamond Size"; ui_type="slider"; ui_min=DIAMOND_SIZE_MIN; ui_max=DIAMOND_SIZE_MAX; ui_category="Decorative Elements"; > = DIAMOND_SIZE_DEFAULT;
uniform float CornerDiamondScalarHalfSize < ui_label="Corner Diamond Size"; ui_type="slider"; ui_min=CORNER_DIAMOND_SIZE_MIN; ui_max=CORNER_DIAMOND_SIZE_MAX; ui_category="Decorative Elements"; > = CORNER_DIAMOND_SIZE_DEFAULT;

uniform bool FanEnable < ui_label="Enable Fans"; ui_type="checkbox"; ui_category="Decorative Elements"; > = true;
uniform bool MirrorFansGlobally < ui_label="Mirror Fans"; ui_type="checkbox"; ui_category="Decorative Elements"; > = false; 
uniform bool FansBehindDiamond < ui_label="Fans Behind Diamond"; ui_type="checkbox"; ui_category="Decorative Elements"; > = false; 
uniform int FanLineCount < ui_label="Fan Lines"; ui_type="slider"; ui_min=FAN_LINE_COUNT_MIN; ui_max=FAN_LINE_COUNT_MAX; ui_category="Decorative Elements"; > = FAN_LINE_COUNT_DEFAULT;
uniform float FanSpreadDegrees < ui_label="Fan Spread"; ui_type="slider"; ui_min=FAN_SPREAD_MIN; ui_max=FAN_SPREAD_MAX; ui_category="Decorative Elements"; > = FAN_SPREAD_DEFAULT;
uniform float FanLength < ui_label="Fan Length"; ui_type="slider"; ui_min=FAN_LENGTH_MIN; ui_max=FAN_LENGTH_MAX; ui_category="Decorative Elements"; > = FAN_LENGTH_DEFAULT;
uniform float FanYOffset < ui_label="Fan Position"; ui_type="slider"; ui_min=FAN_POSITION_MIN; ui_max=FAN_POSITION_MAX; ui_category="Decorative Elements"; > = FAN_POSITION_DEFAULT;

// Advanced - Technical Fine-Tuning
uniform int NumTramlines < ui_label="Border Lines"; ui_type="slider"; ui_min=NUM_TRAMLINES_MIN; ui_max=NUM_TRAMLINES_MAX; ui_category="Advanced"; ui_category_closed=true; > = NUM_TRAMLINES_DEFAULT;
uniform float BorderThickness < ui_label="Outer Border Width"; ui_type="slider"; ui_min=BORDER_THICKNESS_MIN; ui_max=BORDER_THICKNESS_MAX; ui_category="Advanced"; ui_category_closed=true; > = BORDER_THICKNESS_DEFAULT;
uniform float TramlineIndividualThickness < ui_label="Inner Border Width"; ui_type="slider"; ui_min=TRAMLINE_THICKNESS_MIN; ui_max=TRAMLINE_THICKNESS_MAX; ui_category="Advanced"; ui_category_closed=true; > = TRAMLINE_THICKNESS_DEFAULT;
uniform float TramlineSpacing < ui_label="Border Spacing"; ui_type="slider"; ui_min=TRAMLINE_SPACING_MIN; ui_max=TRAMLINE_SPACING_MAX; ui_category="Advanced"; ui_category_closed=true; > = TRAMLINE_SPACING_DEFAULT;
uniform float DetailPadding < ui_label="Detail Padding"; ui_type="slider"; ui_min=DETAIL_PADDING_MIN; ui_max=DETAIL_PADDING_MAX; ui_category="Advanced"; ui_category_closed=true; > = DETAIL_PADDING_DEFAULT;
uniform float DetailLineWidth < ui_label="Detail Width"; ui_type="slider"; ui_min=DETAIL_LINE_WIDTH_MIN; ui_max=DETAIL_LINE_WIDTH_MAX; ui_category="Advanced"; ui_category_closed=true; > = DETAIL_LINE_WIDTH_DEFAULT;
uniform float FanBaseRadius < ui_label="Fan Base Offset"; ui_type="slider"; ui_min=FAN_BASE_RADIUS_MIN; ui_max=FAN_BASE_RADIUS_MAX; ui_category="Advanced"; ui_category_closed=true; > = FAN_BASE_RADIUS_DEFAULT;
uniform float FanLineThickness < ui_label="Fan Line Width"; ui_type="slider"; ui_min=FAN_LINE_THICKNESS_MIN; ui_max=FAN_LINE_THICKNESS_MAX; ui_category="Advanced"; ui_category_closed=true; > = FAN_LINE_THICKNESS_DEFAULT;
uniform float3 FrameFillColorBackup < ui_label="Fallback Fill Color"; ui_type="color"; ui_category="Advanced"; ui_category_closed=true; > = FRAME_FILL_COLOR_DEFAULT;
uniform float3 FrameLineColorBackup < ui_label="Fallback Line Color"; ui_type="color"; ui_category="Advanced"; ui_category_closed=true; > = FRAME_LINE_COLOR_DEFAULT;

// Audio Reactivity
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(AudioMultiplier, "Audio Intensity", AUDIO_MULT_MIN, AUDIO_MULT_MAX, "Audio Reactivity")

// Audio reactivity targets
uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target"; ui_tooltip = "Which parameter reacts to audio input"; ui_category = "Audio Reactivity";
    ui_items = "None\0Gold Brightness\0Gold Noise Intensity\0Gold Fresnel Power\0Gold Surface Detail\0"; > = AUDIO_TARGET_DEFAULT;

// ============================================================================
// POSITION & SCALE CONTROLS
// ============================================================================
AS_POSITION_SCALE_UI(Position, Scale)

// ============================================================================
// PALETTE SYSTEM  
// ============================================================================
AS_PALETTE_SELECTION_UI(PalettePreset, "Color Palette", AS_PALETTE_METAL, "Palette & Style")
uniform float PaletteColorBlend < ui_type = "slider"; ui_label = "Palette Blend"; ui_tooltip = "Controls how much palette colors affect the gold material"; ui_min = PALETTE_BLEND_MIN; ui_max = PALETTE_BLEND_MAX; ui_category = "Palette & Style"; > = PALETTE_BLEND_DEFAULT;

// ============================================================================
// STAGE CONTROLS
// ============================================================================
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(SnapRotation, FineRotation)

// Final Mix
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_NORMAL)
AS_BLENDAMOUNT_UI(BlendAmount)

// === Coordinate & SDF Helpers ===
// Helper function to transform coordinates according to the Implementation Guide rules
float2 AS_getArtDecoCoords(float2 texcoord, float2 position, float scale, float rotation) {
    // Step 1: Convert to normalized central square [-1,1] with aspect ratio correction
    float aspectRatio = ReShade::AspectRatio;
    float2 uv_norm;
    if (aspectRatio >= 1.0) {
        uv_norm.x = (texcoord.x - 0.5) * 2.0 * aspectRatio;
        uv_norm.y = (texcoord.y - 0.5) * 2.0;
    } else {
        uv_norm.x = (texcoord.x - 0.5) * 2.0;
        uv_norm.y = (texcoord.y - 0.5) * 2.0 / aspectRatio;
    }
    
    // Step 2: Apply global rotation around screen center
    if (abs(rotation) > AS_EPSILON) {
        float sinRot = sin(-rotation), cosRot = cos(-rotation);
        uv_norm = float2(
            uv_norm.x * cosRot - uv_norm.y * sinRot,
            uv_norm.x * sinRot + uv_norm.y * cosRot
        );
    }
    
    // Step 3: Apply position and scale directly in normalized central square space
    // Position is applied with correct -1.5 to +1.5 range mapping
    uv_norm.x = (uv_norm.x / scale) - position.x;  
    uv_norm.y = (uv_norm.y / scale) + position.y;  // Note: Y is inverted in screen space
    
    // Step 4: Scale to Art Deco coordinate space (maintains aspect ratio independence)
    return uv_norm * ARTDECO_SQUARE_SPACE_SCALE;
}

float sdBox(float2 p, float2 b) { // p is relative to box center, b is half-size
    float2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdThickLineSegment(float2 p, float2 a, float2 b, float thickness) {
    float2 pa = p - a; float2 ba = b - a;
    float dot_ba_ba = dot(ba, ba);
    if (dot_ba_ba < ARTDECO_EPSILON) { return length(pa) - thickness * ARTDECO_THICKNESS_HALF_FACTOR; }
    float h = clamp(dot(pa, ba) / dot_ba_ba, 0.0, 1.0);
    return length(pa - ba * h) - thickness * ARTDECO_THICKNESS_HALF_FACTOR;
}

// === Procedural Gold Material System ===
float3 HSVtoRGB(float3 hsv) {
    float h = hsv.x / ARTDECO_HSV_HUE_DIVISOR;
    float s = hsv.y;
    float v = hsv.z;
    float c = v * s;
    float x = c * (1.0 - abs(fmod(h, ARTDECO_SQUARE_SPACE_SCALE) - 1.0));
    float m = v - c;
    
    float3 rgb;
    if (h < 1.0) rgb = float3(c, x, 0);
    else if (h < 2.0) rgb = float3(x, c, 0);
    else if (h < 3.0) rgb = float3(0, c, x);
    else if (h < 4.0) rgb = float3(0, x, c);
    else if (h < 5.0) rgb = float3(x, 0, c);
    else rgb = float3(c, 0, x);
    
    return rgb + m;
}

float CalculateFresnelFactor(float2 uv, float2 center, float power) {
    float2 toCenter = normalize(uv - center);
    float2 normal = float2(0, 1); // Assume upward normal for simplicity
    float cosTheta = abs(dot(toCenter, normal));
    return pow(1.0 - cosTheta, power);
}

float3 GenerateProceduralGold(float2 uv, bool isFill) {
    // Resolution independence - normalize to 1080p baseline
    float resolutionScale = (float)BUFFER_HEIGHT / ARTDECO_PALETTE_RESOLUTION_BASE;
    float2 scaledUV = uv * resolutionScale;
    
    // Audio reactivity processing - only for gold parameters
    float goldBrightness_final = GoldBrightness;
    float noiseIntensity_final = NoiseIntensity;
    float fresnelPower_final = FresnelPower;
    float noiseBrightness_final = NoiseBrightness;
    
    if (AudioTarget > 0) {
        float audioValue = AS_applyAudioReactivity(1.0, AudioSource, AudioMultiplier, true) - 1.0;
        
        if (AudioTarget == 1) { // Gold Brightness
            goldBrightness_final = GoldBrightness + (GoldBrightness * audioValue * ARTDECO_AUDIO_BRIGHTNESS_SCALE);
        }
        else if (AudioTarget == 2) { // Gold Noise Intensity
            noiseIntensity_final = NoiseIntensity + (NoiseIntensity * audioValue * ARTDECO_AUDIO_NOISE_SCALE);
        }
        else if (AudioTarget == 3) { // Gold Fresnel Power
            fresnelPower_final = FresnelPower + (FresnelPower * audioValue * ARTDECO_AUDIO_FRESNEL_SCALE);
        }
        else if (AudioTarget == 4) { // Gold Surface Detail
            noiseBrightness_final = NoiseBrightness + (NoiseBrightness * audioValue * ARTDECO_AUDIO_SURFACE_SCALE);
        }
    }
    
    // Clamp values to reasonable ranges
    goldBrightness_final = goldBrightness_final; // Remove saturate per user request
    noiseIntensity_final = noiseIntensity_final;   // Remove saturate per user request  
    fresnelPower_final = clamp(fresnelPower_final, FRESNEL_POWER_CLAMP_MIN, FRESNEL_POWER_CLAMP_MAX);
    noiseBrightness_final = noiseBrightness_final; // Remove saturate per user request
    
    // Base gold color from HSV using audio-modified brightness
    float3 baseGold = HSVtoRGB(float3(GoldHue, GoldSaturation, goldBrightness_final));
    
    // Generate multiple layers of surface noise using FBM with correct parameters
    float surfaceNoise = AS_Fbm2D(scaledUV * NoiseScale, ARTDECO_NOISE_OCTAVES, ARTDECO_NOISE_LACUNARITY, ARTDECO_NOISE_GAIN);
    
    // Apply noise to roughness variation with audio-modified intensity
    float roughnessVariation = GoldRoughness + (surfaceNoise - AS_HALF) * noiseIntensity_final * ARTDECO_SQUARE_SPACE_SCALE;
    roughnessVariation = saturate(roughnessVariation);
    
    // Calculate Fresnel effect for metallic appearance with audio-modified power
    float2 screenCenter = float2(AS_HALF, AS_HALF);
    float fresnelFactor = CalculateFresnelFactor(uv, screenCenter, fresnelPower_final);
    
    // Apply noise to modify Fresnel intensity for surface variation with audio-modified intensity
    float noisyFresnelFactor = fresnelFactor * (1.0 + (surfaceNoise - AS_HALF) * noiseIntensity_final);
    noisyFresnelFactor = saturate(noisyFresnelFactor);
    
    // Metallic reflection tint (cooler for highlights) with noise variation
    float3 metallicTint = lerp(baseGold, ARTDECO_METALLIC_TINT, noisyFresnelFactor * GoldMetallic);
    
    // Apply roughness and noise to metallic intensity
    float metallicIntensity = GoldMetallic * (1.0 - roughnessVariation * AS_HALF);
    metallicIntensity *= (1.0 + (surfaceNoise - AS_HALF) * noiseIntensity_final * AS_HALF);
    metallicIntensity = saturate(metallicIntensity);
    
    // Enhanced surface brightness variation with audio-modified brightness control
    float brightnessMod = 1.0 + (surfaceNoise - AS_HALF) * noiseBrightness_final;
    brightnessMod = saturate(brightnessMod);
    
    // Apply noise to individual color channels with audio-modified intensity
    float3 noiseColorMod = float3(
        1.0 + (AS_Fbm2D(scaledUV * NoiseScale + ARTDECO_NOISE_OFFSET_RED, ARTDECO_NOISE_OCTAVES, ARTDECO_NOISE_LACUNARITY, ARTDECO_NOISE_GAIN) - AS_HALF) * noiseIntensity_final * ARTDECO_NOISE_RED_INTENSITY,
        1.0 + (AS_Fbm2D(scaledUV * NoiseScale + ARTDECO_NOISE_OFFSET_GREEN, ARTDECO_NOISE_OCTAVES, ARTDECO_NOISE_LACUNARITY, ARTDECO_NOISE_GAIN) - AS_HALF) * noiseIntensity_final * ARTDECO_NOISE_GREEN_INTENSITY,
        1.0 + (AS_Fbm2D(scaledUV * NoiseScale + ARTDECO_NOISE_OFFSET_BLUE, ARTDECO_NOISE_OCTAVES, ARTDECO_NOISE_LACUNARITY, ARTDECO_NOISE_GAIN) - AS_HALF) * noiseIntensity_final * ARTDECO_NOISE_BLUE_INTENSITY
    );
    noiseColorMod = saturate(noiseColorMod);
    
    // Final gold color with ENHANCED surface variation
    float3 finalGold = lerp(baseGold, metallicTint, metallicIntensity);
    finalGold *= brightnessMod;
    finalGold *= noiseColorMod;
    
    // Differentiate fill vs line colors
    if (isFill) {
        // Fill areas are slightly darker and less metallic
        finalGold *= ARTDECO_FILL_BRIGHTNESS_FACTOR;
    } else {
        // Line areas are brighter and more reflective with ENHANCED noise
        finalGold *= ARTDECO_LINE_BRIGHTNESS_FACTOR;
        float3 highlightColor = lerp(ARTDECO_HIGHLIGHT_COLOR_BASE, ARTDECO_HIGHLIGHT_COLOR_BRIGHT, surfaceNoise);
        finalGold = lerp(finalGold, highlightColor, noisyFresnelFactor * ARTDECO_HIGHLIGHT_BLEND_FACTOR);
    }
    
    return saturate(finalGold);
}

// === Drawing Functions ===
float drawSingleTramlineSDF(float2 p_eval, float2 line_center_half_size, float line_actual_thickness) {
    float sdf_line_center = sdBox(p_eval, line_center_half_size);
    return saturate(1.0 - smoothstep(
                            line_actual_thickness * AS_HALF - ARTDECO_BORDER_EDGE,
                            line_actual_thickness * AS_HALF + ARTDECO_BORDER_EDGE,
                            abs(sdf_line_center)
                         ));
}

float4 drawSolidElementWithTramlines(
    float2 p, float2 outer_box_half_size, bool is_diamond,                   
    int num_tram, float tram_standard_thick, float last_tram_thick, float tram_space,
    float detail_pad, float detail_lw, float3 fill_c, float3 line_c                      
)
{
    float2 p_eval = is_diamond ? abs(AS_rotate2D(p, AS_QUARTER_PI)) : p; 
    float3 final_color = fill_c; 
    float tramlines_total_alpha = 0.0;
    float current_offset_from_outer_edge = 0.0;
    float2 inner_edge_of_last_drawn_tramline_hs = outer_box_half_size;

    for (int i = 0; i < num_tram; ++i) {
        float current_line_actual_thickness = (i == num_tram - 1 && num_tram > 0) ? last_tram_thick : tram_standard_thick;
        float2 line_center_half_size = max(0.0.xx, outer_box_half_size - current_offset_from_outer_edge - current_line_actual_thickness * AS_HALF);
        float tram_alpha = drawSingleTramlineSDF(p_eval, line_center_half_size, current_line_actual_thickness);
        final_color = lerp(final_color, line_c, tram_alpha); 
        tramlines_total_alpha = max(tramlines_total_alpha, tram_alpha);
        current_offset_from_outer_edge += current_line_actual_thickness + tram_space;
        if (i == num_tram -1) { 
             inner_edge_of_last_drawn_tramline_hs = max(0.0.xx, outer_box_half_size - current_offset_from_outer_edge + tram_space);
        }
    }
     if (num_tram == 0) { inner_edge_of_last_drawn_tramline_hs = outer_box_half_size; }

    float2 fill_area_half_size = inner_edge_of_last_drawn_tramline_hs;
    float sdf_fill_area = sdBox(p_eval, fill_area_half_size);
    float fill_alpha = smoothstep(ARTDECO_BORDER_EDGE, -ARTDECO_BORDER_EDGE, sdf_fill_area);
    final_color = lerp(lerp(fill_c, line_c, tramlines_total_alpha), fill_c, fill_alpha);    float2 detail_line_center_half_size = max(0.0.xx, fill_area_half_size - detail_pad - detail_lw * AS_HALF);
    float sdf_detail_line_center = sdBox(p_eval, detail_line_center_half_size);
    float detail_line_alpha = saturate(1.0 - smoothstep(detail_lw * AS_HALF - ARTDECO_BORDER_EDGE, detail_lw * AS_HALF + ARTDECO_BORDER_EDGE, abs(sdf_detail_line_center)));
    float3 detail_line_color_val = lerp(fill_c, line_c, AS_HALF);
    final_color = lerp(final_color, detail_line_color_val, detail_line_alpha);
    
    float combined_total_alpha = fill_alpha;
     if (fill_alpha < 0.1) { combined_total_alpha = saturate(tramlines_total_alpha + detail_line_alpha); }
    return float4(final_color, combined_total_alpha);
}

float4 drawComplexDiamond(
    float2 p_orig, float diamond_scalar_half_size, float3 fill_c, float3 line_c, 
    int num_tram, float tram_standard_thick, float last_tram_thick, float tram_space,
    float detail_pad, float detail_lw
)
{
    float2 diamond_outer_half_size = float2(diamond_scalar_half_size, diamond_scalar_half_size);
    float2 p_eval = abs(AS_rotate2D(p_orig, AS_QUARTER_PI)); 
    float3 final_color = fill_c;
    float tramlines_total_alpha = 0.0;
    float current_offset_main = 0.0;
    float2 inner_edge_of_last_drawn_tramline_hs_diamond = diamond_outer_half_size;

    for (int i = 0; i < num_tram; ++i) {
        float current_line_actual_thickness = (i == num_tram - 1 && num_tram > 0) ? last_tram_thick : tram_standard_thick;
        float2 line_center_hs = max(0.0.xx, diamond_outer_half_size - current_offset_main - current_line_actual_thickness * AS_HALF);
        float tram_alpha = drawSingleTramlineSDF(p_eval, line_center_hs, current_line_actual_thickness);
        tramlines_total_alpha = max(tramlines_total_alpha, tram_alpha); 
        current_offset_main += current_line_actual_thickness + tram_space;
         if (i == num_tram -1) { inner_edge_of_last_drawn_tramline_hs_diamond = max(0.0.xx, diamond_outer_half_size - current_offset_main + tram_space); }
    }
    if (num_tram == 0) { inner_edge_of_last_drawn_tramline_hs_diamond = diamond_outer_half_size; }

    float fill_alpha = smoothstep(ARTDECO_BORDER_EDGE, -ARTDECO_BORDER_EDGE, sdBox(p_eval, inner_edge_of_last_drawn_tramline_hs_diamond));
    final_color = lerp(lerp(fill_c, line_c, tramlines_total_alpha), fill_c, fill_alpha);     float3 detail_lines_color_val = lerp(fill_c, line_c, AS_HALF);
    float2 inlay1_center_half_size = max(0.0.xx, inner_edge_of_last_drawn_tramline_hs_diamond - detail_pad - detail_lw * AS_HALF);
    float sdf_inlay1_center = sdBox(p_eval, inlay1_center_half_size);
    float alpha_inlay1_line = saturate(1.0 - smoothstep(detail_lw * AS_HALF - ARTDECO_BORDER_EDGE, detail_lw * AS_HALF + ARTDECO_BORDER_EDGE, abs(sdf_inlay1_center)));
    final_color = lerp(final_color, detail_lines_color_val, alpha_inlay1_line);
    
    float offset_for_line2_center = detail_pad + detail_lw + detail_pad;    float2 inlay2_center_half_size = max(0.0.xx, inner_edge_of_last_drawn_tramline_hs_diamond - offset_for_line2_center - detail_lw * AS_HALF);
    float sdf_inlay2_center = sdBox(p_eval, inlay2_center_half_size);
    float alpha_inlay2_line = saturate(1.0 - smoothstep(detail_lw * AS_HALF - ARTDECO_BORDER_EDGE, detail_lw * AS_HALF + ARTDECO_BORDER_EDGE, abs(sdf_inlay2_center)));
    final_color = lerp(final_color, detail_lines_color_val, alpha_inlay2_line);
    
    float combined_total_alpha = fill_alpha;
     if (fill_alpha < 0.1) { combined_total_alpha = saturate(tramlines_total_alpha + alpha_inlay1_line + alpha_inlay2_line); }
    return float4(final_color, combined_total_alpha);
}

float4 drawFan(float2 p_screen, float2 fan_origin_uv, float y_direction_multiplier,
               int line_count, float spread_rad, float base_radius, float line_length, 
               float line_thick, float3 line_c)
{
    if (line_count <= 0) { // Explicit early return
        return float4(line_c, 0.0);
    }    float min_dist_to_line = ARTDECO_FAN_MIN_DIST_INIT; 

    for (int i = 0; i < line_count; ++i) {        float t = (line_count == 1) ? AS_HALF : float(i) / float(line_count - 1); 
        float angle = spread_rad * (t - AS_HALF);
        float2 dir = float2(sin(angle), cos(angle) * y_direction_multiplier);
        float2 start_point = fan_origin_uv + dir * base_radius;
        float2 end_point = fan_origin_uv + dir * (base_radius + line_length);
        float current_line_sdf = sdThickLineSegment(p_screen, start_point, end_point, line_thick);
        min_dist_to_line = min(min_dist_to_line, current_line_sdf);
    }    
    float fan_alpha = saturate(1.0 - smoothstep(0.0, ARTDECO_BORDER_EDGE_DOUBLE, min_dist_to_line));
    float4 result_color = float4(line_c, fan_alpha);
    return result_color; 
}




// === Main Pixel Shader ===
float4 PS_Main(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float4 output_color = tex2D(ReShade::BackBuffer, uv);
      // Calculate rotation using AS standard function
    float totalRotation = AS_getRotationRadians(SnapRotation, FineRotation);
    
    // Get Art Deco coordinates using AS standard transformation with Position and Scale
    float2 sq_base = AS_getArtDecoCoords(uv, Position, Scale, totalRotation);

    // Calculate Main Diamond's INNER void for precise fan clipping
    float2 main_diamond_outer_hs_for_clip_calc = float2(DiamondScalarSize, DiamondScalarSize);
    float temp_offset_for_diamond_clip = 0.0;
    float2 main_diamond_inner_void_hs_for_clip = main_diamond_outer_hs_for_clip_calc; 
    if (NumTramlines > 0) {
        for (int i_clip = 0; i_clip < NumTramlines; ++i_clip) {
            float current_line_thick_clip = (i_clip == NumTramlines - 1) ? BorderThickness : TramlineIndividualThickness;
            temp_offset_for_diamond_clip += current_line_thick_clip;
            if (i_clip < NumTramlines - 1) { temp_offset_for_diamond_clip += TramlineSpacing; }
        }
        main_diamond_inner_void_hs_for_clip = max(0.0.xx, main_diamond_outer_hs_for_clip_calc - temp_offset_for_diamond_clip);
    }    float2 fan_clip_mask_hs = main_diamond_inner_void_hs_for_clip + BorderThickness * AS_HALF;
    float main_diamond_clipping_sdf = sdBox(abs(AS_rotate2D(sq_base, AS_QUARTER_PI)), fan_clip_mask_hs);
    float diamond_clip_mask = 1.0 - smoothstep(0.0, ARTDECO_BORDER_EDGE, main_diamond_clipping_sdf);float effective_fan_length = FanLength;
    if (FanEnable && !FansBehindDiamond) { effective_fan_length += BorderThickness * AS_HALF; }

    // --- Render Order ---    // 1. Fans if "Behind Diamond"
    if (FanEnable && FansBehindDiamond) {
        float top_fan_y_dir = MirrorFansGlobally ? -1.0 : 1.0;
        float bottom_fan_y_dir = MirrorFansGlobally ? 1.0 : -1.0;
        float3 goldLineColor = GenerateProceduralGold(uv, false);float4 upper_fan = drawFan(sq_base, float2(0.0, FanYOffset), top_fan_y_dir, FanLineCount, FanSpreadDegrees * ARTDECO_DEGREES_TO_RADIANS, FanBaseRadius, FanLength, FanLineThickness, goldLineColor);
        output_color.rgb = lerp(output_color.rgb, upper_fan.rgb, upper_fan.a);
        float4 lower_fan = drawFan(sq_base, float2(0.0, -FanYOffset), bottom_fan_y_dir, FanLineCount, FanSpreadDegrees * ARTDECO_DEGREES_TO_RADIANS, FanBaseRadius, FanLength, FanLineThickness, goldLineColor);
        output_color.rgb = lerp(output_color.rgb, lower_fan.rgb, lower_fan.a);    }    // 2. Main Diamond
    float3 fillColor = FrameFillColorBackup; // Keep original dark background
    float3 goldLineColor = GenerateProceduralGold(uv, false); // Only lines get gold
    float4 diamond_elem = drawComplexDiamond(sq_base, DiamondScalarSize, fillColor, goldLineColor, NumTramlines, TramlineIndividualThickness, BorderThickness, TramlineSpacing, DetailPadding, DetailLineWidth);
    output_color.rgb = lerp(output_color.rgb, diamond_elem.rgb, diamond_elem.a);

    // Define fill and line colors for towers and boxes
    float3 goldFillColor = FrameFillColorBackup; // Fill areas use dark background color
    // goldLineColor already defined above for lines// 3. Corner Diamonds
    float2 main_box_outer_hs_for_corner_calc = MainSize;
    float temp_offset_for_main_box_inner_edge = 0.0;
    float2 main_box_inner_tram_edge_hs = main_box_outer_hs_for_corner_calc; 
    if (NumTramlines > 0) { 
        for (int i_main_box = 0; i_main_box < NumTramlines; ++i_main_box) {
            float current_line_thick_main = (i_main_box == NumTramlines - 1) ? BorderThickness : TramlineIndividualThickness;
            temp_offset_for_main_box_inner_edge += current_line_thick_main;
            if (i_main_box < NumTramlines - 1) { temp_offset_for_main_box_inner_edge += TramlineSpacing;}
        }
        main_box_inner_tram_edge_hs = max(0.0.xx, main_box_outer_hs_for_corner_calc - temp_offset_for_main_box_inner_edge);
    }    float corner_diamond_target_center_x = main_box_inner_tram_edge_hs.x;
    float2 left_cd_pos_center_sq_base = float2(-corner_diamond_target_center_x, 0.0); 
    float4 left_corner_diamond_elem = drawComplexDiamond(sq_base - left_cd_pos_center_sq_base, CornerDiamondScalarHalfSize, fillColor, goldLineColor, NumTramlines, TramlineIndividualThickness, BorderThickness, TramlineSpacing, DetailPadding, DetailLineWidth);
    output_color.rgb = lerp(output_color.rgb, left_corner_diamond_elem.rgb, left_corner_diamond_elem.a);    float2 right_cd_pos_center_sq_base = float2(corner_diamond_target_center_x, 0.0); 
    float4 right_corner_diamond_elem = drawComplexDiamond(sq_base - right_cd_pos_center_sq_base, CornerDiamondScalarHalfSize, fillColor, goldLineColor, NumTramlines, TramlineIndividualThickness, BorderThickness, TramlineSpacing, DetailPadding, DetailLineWidth);
    output_color.rgb = lerp(output_color.rgb, right_corner_diamond_elem.rgb, right_corner_diamond_elem.a);

    // 4. Boxes (Main and Sub)
    float4 sub_box_elem = drawSolidElementWithTramlines(sq_base, SubSize, false, NumTramlines, TramlineIndividualThickness, BorderThickness, TramlineSpacing, DetailPadding, DetailLineWidth, goldFillColor, goldLineColor);
    output_color.rgb = lerp(output_color.rgb, sub_box_elem.rgb, sub_box_elem.a);
    float4 main_box_elem = drawSolidElementWithTramlines(sq_base, MainSize, false, NumTramlines, TramlineIndividualThickness, BorderThickness, TramlineSpacing, DetailPadding, DetailLineWidth, goldFillColor, goldLineColor);
    output_color.rgb = lerp(output_color.rgb, main_box_elem.rgb, main_box_elem.a);    // 5. Fans if NOT "Behind Diamond"
    if (FanEnable && !FansBehindDiamond) { 
        float top_fan_y_dir = MirrorFansGlobally ? -1.0 : 1.0;
        float bottom_fan_y_dir = MirrorFansGlobally ? 1.0 : -1.0;
        float3 goldLineColorFans = GenerateProceduralGold(uv, false);float4 upper_fan = drawFan(sq_base, float2(0.0, FanYOffset), top_fan_y_dir, FanLineCount, FanSpreadDegrees * ARTDECO_DEGREES_TO_RADIANS, FanBaseRadius, effective_fan_length, FanLineThickness, goldLineColorFans);
        upper_fan.a *= diamond_clip_mask; 
        output_color.rgb = lerp(output_color.rgb, upper_fan.rgb, upper_fan.a);
        float4 lower_fan = drawFan(sq_base, float2(0.0, -FanYOffset), bottom_fan_y_dir, FanLineCount, FanSpreadDegrees * ARTDECO_DEGREES_TO_RADIANS, FanBaseRadius, effective_fan_length, FanLineThickness, goldLineColorFans);lower_fan.a *= diamond_clip_mask; 
        output_color.rgb = lerp(output_color.rgb, lower_fan.rgb, lower_fan.a);
    }    // === PALETTE INTEGRATION ===
    // Use gold surface noise as palette coordinate for cohesive color integration
    float2 scaledUV = uv * ((float)BUFFER_HEIGHT / ARTDECO_PALETTE_RESOLUTION_BASE);
    float paletteNoise = AS_Fbm2D(scaledUV * NoiseScale, ARTDECO_PALETTE_NOISE_OCTAVES, ARTDECO_PALETTE_NOISE_LACUNARITY, ARTDECO_PALETTE_NOISE_GAIN);
    float3 paletteColor = AS_getInterpolatedColor(PalettePreset, paletteNoise);
    
    // Apply palette tinting to gold elements based on material properties
    float3 goldElements = output_color.rgb - tex2D(ReShade::BackBuffer, uv).rgb;
    float goldMask = saturate(length(goldElements));
    
    // Blend palette color with existing gold, preserving metallic qualities
    output_color.rgb = lerp(output_color.rgb, 
                           lerp(output_color.rgb, paletteColor * output_color.rgb, ARTDECO_PALETTE_BLEND_FACTOR), 
                           goldMask * PaletteColorBlend);
      // === STAGE DEPTH AND FINAL PROCESSING ===
    // Apply stage depth masking
    float sceneDepth = ReShade::GetLinearizedDepth(uv);
    float depthMask = AS_depthMask(sceneDepth, EffectDepth, 1.0, 1.0);
    output_color.a *= depthMask;
    
    // Apply blend mode with background
    float4 background = tex2D(ReShade::BackBuffer, uv);
    output_color = AS_applyBlend(background, output_color, BlendMode, BlendAmount);
    
    return output_color;
}

// === Technique ===
technique AS_GFX_ArtDecoFrame_1 < 
    ui_label = "[AS] GFX: Art Deco Frame"; 
    ui_tooltip = "Elegant Art Deco style decorative frame for UI composition."; 
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Main;
    }
}

#endif