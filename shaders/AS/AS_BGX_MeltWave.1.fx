/**
 * AS_BGX_MeltWave.1.fx - Psychedelic Liquid Distortion Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Based on "70s Melt" by tomorrowevening (2013-08-12)
 * Shadertoy: https://www.shadertoy.com/view/XsX3zl
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a flowing, warping psychedelic effect inspired by 1970s visual aesthetics.
 * The effect generates mesmerizing colored patterns with sine-based distortions that
 * evolve over time, creating a liquid, melting appearance.
 *
 * FEATURES:
 * - Adjustable zoom levels and distortion intensity
 * - Palette system with both mathematical and preset color options
 * - Dynamic time-based animation with keyframe support
 * - Audio reactivity that can be mapped to different effect parameters
 * - Resolution-independent transformation with position and rotation controls
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Creates an iterative sine-based distortion effect on screen coordinates
 * 2. Uses cosine functions to modulate distortion parameters over time
 * 3. Generates RGB colors based on the distorted coordinates
 * 4. Applies either mathematical coloring or palette-based coloring
 * 5. Provides audio reactivity with selectable parameter targeting
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_MeltWave_1_fx
#define __AS_BGX_MeltWave_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

namespace ASMeltWave {

// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================

// Effect Settings
static const int ITERATIONS_MIN = 10;
static const int ITERATIONS_MAX = 80;
static const int ITERATIONS_STEP = 1;
static const int ITERATIONS_DEFAULT = 40;

static const float BRIGHTNESS_MIN = 0.5;
static const float BRIGHTNESS_MAX = 2.0;
static const float BRIGHTNESS_STEP = 0.01;
static const float BRIGHTNESS_DEFAULT = 0.975;

static const float MELT_INTENSITY_MIN = 0.25;
static const float MELT_INTENSITY_MAX = 4.0;
static const float MELT_INTENSITY_STEP = 0.05;
static const float MELT_INTENSITY_DEFAULT = 1.0;

// Palette & Style
static const float SATURATION_MIN = 0.0;
static const float SATURATION_MAX = 2.0;
static const float SATURATION_STEP = 0.01;
static const float SATURATION_DEFAULT = 1.0;

static const float COLOR_CYCLE_SPEED_MIN = -2.0;
static const float COLOR_CYCLE_SPEED_MAX = 2.0;
static const float COLOR_CYCLE_SPEED_STEP = 0.1;
static const float COLOR_CYCLE_SPEED_DEFAULT = 0.1;

// Animation
static const float ANIMATION_SPEED_MIN = 0.0;
static const float ANIMATION_SPEED_MAX = 5.0;
static const float ANIMATION_SPEED_STEP = 0.01;
static const float ANIMATION_SPEED_DEFAULT = 1.25;

static const float ANIMATION_KEYFRAME_MIN = 0.0;
static const float ANIMATION_KEYFRAME_MAX = 100.0;
static const float ANIMATION_KEYFRAME_STEP = 0.1;
static const float ANIMATION_KEYFRAME_DEFAULT = 0.0;

// Position
static const float POSITION_MIN = -1.5;
static const float POSITION_MAX = 1.5;
static const float POSITION_STEP = 0.01;
static const float POSITION_DEFAULT = 0.0;

static const float SCALE_MIN = 0.5;
static const float SCALE_MAX = 2.0;
static const float SCALE_STEP = 0.01;
static const float SCALE_DEFAULT = 1.0;

// Audio
static const float AUDIO_MULTIPLIER_DEFAULT = 1.0;
static const float AUDIO_MULTIPLIER_MAX = 5.0;

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Effect Settings ---

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nBased on '70s Melt' by tomorrowevening\nLink: https://www.shadertoy.com/view/XsX3zl\nLicence: CC Share-Alike Non-Commercial\n\n";>;

uniform int Iterations < ui_type = "slider"; ui_label = "Zoom Intensity"; ui_min = ITERATIONS_MIN; ui_max = ITERATIONS_MAX; ui_step = ITERATIONS_STEP; ui_category = "Effect Settings"; > = ITERATIONS_DEFAULT;
uniform float Brightness < ui_type = "slider"; ui_label = "Brightness"; ui_min = BRIGHTNESS_MIN; ui_max = BRIGHTNESS_MAX; ui_step = BRIGHTNESS_STEP; ui_category = "Effect Settings"; > = BRIGHTNESS_DEFAULT;
uniform float MeltIntensity < ui_type = "slider"; ui_label = "Melt Intensity"; ui_min = MELT_INTENSITY_MIN; ui_max = MELT_INTENSITY_MAX; ui_step = MELT_INTENSITY_STEP; ui_category = "Effect Settings"; > = MELT_INTENSITY_DEFAULT;

// --- Palette & Style ---
uniform bool UseOriginalColors < ui_type = "toggle"; ui_label = "Use Original Math Colors"; ui_tooltip = "If enabled, uses the original mathematical coloring method. Otherwise, uses palettes."; ui_category = "Palette & Style"; > = true;
uniform float Saturation < ui_type = "slider"; ui_label = "Original Color Saturation"; ui_tooltip = "Saturation for original math colors (if Use Original Math Colors is enabled)."; ui_min = SATURATION_MIN; ui_max = SATURATION_MAX; ui_step = SATURATION_STEP; ui_category = "Palette & Style"; > = SATURATION_DEFAULT;
uniform float3 TintColor < ui_type = "color"; ui_label = "Original Color Tint"; ui_tooltip = "Tint for original math colors (if Use Original Math Colors is enabled)."; ui_category = "Palette & Style"; > = float3(1.0, 1.0, 1.0);
AS_PALETTE_SELECTION_UI(PalettePreset, "Color Palette", AS_PALETTE_NEON, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(MeltWave_, "Palette & Style")
uniform float ColorCycleSpeed < ui_type = "slider"; ui_label = "Palette Color Cycle Speed"; ui_tooltip = "Controls how fast palette colors cycle. 0 = static. Only active if not using original math colors."; ui_min = COLOR_CYCLE_SPEED_MIN; ui_max = COLOR_CYCLE_SPEED_MAX; ui_step = COLOR_CYCLE_SPEED_STEP; ui_category = "Palette & Style"; > = COLOR_CYCLE_SPEED_DEFAULT;
uniform float3 BackgroundColor < ui_type = "color"; ui_label = "Background Color"; ui_tooltip = "Solid background color the effect is blended onto."; ui_category = "Palette & Style"; > = float3(0.0, 0.0, 0.0);

// --- Audio Reactivity ---
AS_AUDIO_UI(MeltWave_AudioSource, "Audio Source", AS_AUDIO_BASS, "Audio Reactivity")
AS_AUDIO_MULT_UI(MeltWave_AudioMultiplier, "Audio Multiplier", AUDIO_MULTIPLIER_DEFAULT, AUDIO_MULTIPLIER_MAX, "Audio Reactivity")
uniform int MeltWave_AudioTarget < ui_type = "combo"; ui_label = "Audio Target"; ui_items = "Melt Intensity\0Animation Speed\0Brightness\0Zoom\0All\0"; ui_category = "Audio Reactivity"; > = 2;

// --- Animation Controls ---
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")

// --- Position Controls ---
AS_POSITION_SCALE_UI(Position, Scale)

// --- Stage Controls ---
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(RotationSnap, RotationFine)

// --- Final Mix ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug ---
AS_DEBUG_UI("Off\0Show Audio Reactivity\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Cosine range function from original shader, remaps cosine to a custom range
float cosRange(float amt, float range, float minimum) {
    return (((1.0 + cos(radians(amt))) * 0.5) * range) + minimum;
}

// Get color from palette 
float3 getMeltWaveColor(float t, float time) {
    // Add time-based cycling to the lookup parameter if color cycle speed is non-zero
    if (ColorCycleSpeed != 0.0)
        t = frac(t + time * ColorCycleSpeed * 0.05);
    
    t = saturate(t); // Ensure t is in [0,1]
    
    if (PalettePreset == AS_PALETTE_CUSTOM) {
        // Use custom palette
        return AS_GET_INTERPOLATED_CUSTOM_COLOR(MeltWave_, t);
    }
    
    // Use preset palette
    return AS_getInterpolatedColor(PalettePreset, t);
}

// ============================================================================
// PIXEL SHADER
// ============================================================================

float4 PS_MeltWave(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Get original pixel color and depth
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);
    
    // Apply depth test
    if (depth < EffectDepth) {
        return originalColor;
    }
    
    // Handle audio reactivity
    float zoomIntensity = float(Iterations);
    float meltValue = MeltIntensity;
    float brightnessValue = Brightness;
    float animationValue = AnimationSpeed;
    
    float audioReactivity = AS_applyAudioReactivity(1.0, MeltWave_AudioSource, MeltWave_AudioMultiplier, true);
    
    if (MeltWave_AudioTarget == 0 || MeltWave_AudioTarget == 4) { // Melt Intensity or All
        meltValue *= audioReactivity;
    }
    if (MeltWave_AudioTarget == 1 || MeltWave_AudioTarget == 4) { // Animation Speed or All
        animationValue *= audioReactivity;
    }
    if (MeltWave_AudioTarget == 2 || MeltWave_AudioTarget == 4) { // Brightness or All
        brightnessValue *= audioReactivity;
    }
    if (MeltWave_AudioTarget == 3 || MeltWave_AudioTarget == 4) { // Zoom or All
        zoomIntensity *= audioReactivity;
    }
    
    // Calculate animation time with the standardized helper function
    float time = AS_getAnimationTime(animationValue, AnimationKeyframe);
    
    // --- Coordinate Transformation: Center → Rotate → Position/Scale ---
    float aspectRatio = ReShade::AspectRatio;
    float2 centered = AS_centerCoord(texcoord, aspectRatio); // Centered, aspect-corrected
    // Apply rotation around center
    float rotation = AS_getRotationRadians(RotationSnap, RotationFine);
    float s = sin(-rotation);
    float c = cos(-rotation);
    float2 rotated = float2(centered.x * c - centered.y * s, centered.x * s + centered.y * c);
    // Now apply position and scale
    float2 p = AS_applyPosScale(rotated, Position, Scale);
    p *= 2.0; // Expand to -2 to 2 range for effect intensity
    // Apply aspect ratio correction for resolution independence
    p.x /= aspectRatio;
    
    // Time-based modulations (from original shader)
    float ct = cosRange(time * 5.0, 3.0, 1.1);
    float xBoost = cosRange(time * 0.2, 5.0, 5.0);
    float yBoost = cosRange(time * 0.1, 10.0, 5.0);
    float fScale = cosRange(time * 15.5, 1.25, 0.5) * meltValue;
    
    // Apply the iterative distortion
    int maxIterations = int(zoomIntensity);
    
    for (int i = 1; i < maxIterations; i++) {
        float _i = float(i);
        float2 newp = p;
        newp.x += 0.25 / _i * sin(_i * p.y + time * cos(ct) * 0.5 / 20.0 + 0.005 * _i) * fScale + xBoost;
        newp.y += 0.25 / _i * sin(_i * p.x + time * ct * 0.3 / 40.0 + 0.03 * float(i + 15)) * fScale + yBoost;
        p = newp;
    }
    
    // Generate base colors from the final distorted 'p'
    float3 raw_pattern_col = float3(
        0.5 * sin(3.0 * p.x) + 0.5,
        0.5 * sin(3.0 * p.y) + 0.5,
        sin(p.x + p.y)
    );

    float3 processed_col; // This will be the color before vignette/extrusion

    if (UseOriginalColors) {
        processed_col = raw_pattern_col;
        
        // Apply original saturation (from UI)
        float luminance = dot(processed_col, float3(0.299, 0.587, 0.114));
        processed_col = lerp(luminance.xxx, processed_col, Saturation);
        
        // Apply original tint color (from UI)
        processed_col *= TintColor;
    } else {
        // Use palette color
        float palette_map_value = dot(raw_pattern_col, float3(0.299, 0.587, 0.114)); // Use luminance of raw pattern
        processed_col = getMeltWaveColor(palette_map_value, time);
    }

    // Apply master brightness
    processed_col *= brightnessValue; 
    
    // Calculate extrusion for alpha
    float extrusion = (processed_col.x + processed_col.y + processed_col.z) / 4.0;
    extrusion *= 1.5;
    
    // Create final result with alpha based on extrusion
    float4 effectColor = float4(processed_col, extrusion);
    
    // Blend with UI BackgroundColor using standard AS blend function
    float3 blendedColor = AS_applyBlend(effectColor.rgb, BackgroundColor, BlendMode);
    float3 finalColor = lerp(BackgroundColor, blendedColor, BlendAmount * effectColor.a);
    
    // Debug mode handling
    if (DebugMode == 1) { // Show Audio Reactivity
        float2 debugCenter = float2(0.1f, 0.1f);
        float debugRadius = 0.08f;
        if (length(texcoord - debugCenter) < debugRadius) {
            return float4(audioReactivity, audioReactivity, audioReactivity, 1.0);
        }
    }
    
    // Final output
    return float4(lerp(originalColor.rgb, finalColor, BlendAmount), originalColor.a);
}

} // namespace ASMeltWave

// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_BGX_MeltWave < ui_label="[AS] BGX: Melt Wave"; ui_tooltip = "Generates a flowing, liquid-like psychedelic visual effect with customizable parameters and audio reactivity."; >
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = ASMeltWave::PS_MeltWave;
    }
}

#endif // __AS_BGX_MeltWave_1_fx
