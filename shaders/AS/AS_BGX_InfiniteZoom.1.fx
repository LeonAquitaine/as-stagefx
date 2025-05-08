#ifndef __AS_BGX_InfiniteZoom_1_fx
#define __AS_BGX_InfiniteZoom_1_fx

/**
 * AS_BGX_InfiniteZoom.1.fx - Kaleidoscopic infinite zoom/tunnel effect
 * Author: Leon Aquitaine (translated from Shadertoy/Pouet)
 * Original Author: Danilo Guanabara (https://www.pouet.net/prod.php?which=57245)
 * License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
 * (as per Shadertoy default - please verify original source if critical)
 * * DESCRIPTION:
 * Creates a mesmerizing, infinitely zooming kaleidoscopic pattern effect.
 * Suitable as a dynamic background or overlay. Includes controls for animation,
 * distortion, color palettes, audio reactivity, and scene integration.
 * * CREDITS:
 * Based on shader by Danilo Guanabara: https://www.pouet.net/prod.php?which=57245
 * Adapted for ReShade by Leon Aquitaine
 * * FEATURES:
 * - Infinitely zooming kaleidoscopic patterns.
 * - Customizable distortion parameters (amplitude, frequencies).
 * - Adjustable animation speed.
 * - Optional color palettes with cycling.
 * - Audio reactivity support.
 * - Depth-aware rendering.
 * - Adjustable rotation.
 * - Standard blending options.
 */

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"     // Assuming this contains AS_getTime, AS_applyAudioReactivity, UI macros etc.
#include "AS_Palettes.1.fxh"   // Assuming this contains palette functions and UI macros

namespace ASInfiniteZoom {
// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================

// --- Tunable Constants ---
// Pattern/Distortion
static const float Z_OFFSET_PER_CHANNEL_MIN = 0.0;
static const float Z_OFFSET_PER_CHANNEL_MAX = 0.5;
static const float Z_OFFSET_PER_CHANNEL_STEP = 0.01;
static const float Z_OFFSET_PER_CHANNEL_DEFAULT = 0.07;

static const float DISTORT_SIN_Z_AMP_MIN = 0.0;     // Min value for sin(z) is -1. +1 makes it 0.
static const float DISTORT_SIN_Z_AMP_MAX = 2.0;     // Max value for sin(z) is 1. +1 makes it 2.
static const float DISTORT_SIN_Z_AMP_STEP = 0.05;
static const float DISTORT_SIN_Z_AMP_DEFAULT = 1.0; // This matches the '+1.0' in the original

static const float DISTORT_SIN_L_FREQ_MIN = 1.0;
static const float DISTORT_SIN_L_FREQ_MAX = 25.0;
static const float DISTORT_SIN_L_FREQ_STEP = 0.5;
static const float DISTORT_SIN_L_FREQ_DEFAULT = 9.0;

static const float DISTORT_SIN_Z_FREQ_MIN = 0.0;
static const float DISTORT_SIN_Z_FREQ_MAX = 5.0;
static const float DISTORT_SIN_Z_FREQ_STEP = 0.1;
static const float DISTORT_SIN_Z_FREQ_DEFAULT = 2.0; // Matches '-z-z' -> '-2.0*z'

static const float CHANNEL_INTENSITY_NUMERATOR_MIN = 0.001;
static const float CHANNEL_INTENSITY_NUMERATOR_MAX = 0.1;
static const float CHANNEL_INTENSITY_NUMERATOR_STEP = 0.001;
static const float CHANNEL_INTENSITY_NUMERATOR_DEFAULT = 0.01;

static const float FINAL_DISTANCE_FADE_FACTOR_MIN = 0.1;
static const float FINAL_DISTANCE_FADE_FACTOR_MAX = 5.0;
static const float FINAL_DISTANCE_FADE_FACTOR_STEP = 0.05;
static const float FINAL_DISTANCE_FADE_FACTOR_DEFAULT = 1.0; // Original just divides by l (factor = 1.0)

// Animation
static const float ANIMATION_SPEED_MIN = 0.0;
static const float ANIMATION_SPEED_MAX = 5.0;
static const float ANIMATION_SPEED_STEP = 0.01;
static const float ANIMATION_SPEED_DEFAULT = 1.0;

// Audio (Defaults assumed, adjust as needed)
static const int AUDIO_TARGET_DEFAULT = 1; // e.g., Target Animation Speed
static const float AUDIO_MULTIPLIER_DEFAULT = 1.0;
static const float AUDIO_MULTIPLIER_MAX = 2.0;

// Palette & Style (Defaults assumed, adjust as needed)
static const float ORIG_COLOR_INTENSITY_DEFAULT = 1.0;
static const float ORIG_COLOR_INTENSITY_MAX = 3.0;
static const float ORIG_COLOR_SATURATION_DEFAULT = 1.0;
static const float ORIG_COLOR_SATURATION_MAX = 2.0;
static const float COLOR_CYCLE_SPEED_DEFAULT = 0.1;
static const float COLOR_CYCLE_SPEED_MAX = 2.0;

// --- Stage ---
AS_STAGEDEPTH_UI(EffectDepth, "Effect Depth", "Stage")
AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation, "Stage")

// --- Pattern/Distortion ---
uniform float UI_ZOffsetPerChannel < ui_type = "slider"; ui_label = "RGB Time Offset"; ui_tooltip = "Time offset between RGB channels, affects color separation."; ui_min = Z_OFFSET_PER_CHANNEL_MIN; ui_max = Z_OFFSET_PER_CHANNEL_MAX; ui_step = Z_OFFSET_PER_CHANNEL_STEP; ui_category = "Pattern/Distortion"; > = Z_OFFSET_PER_CHANNEL_DEFAULT;
uniform float UI_DistortSinZAmp < ui_type = "slider"; ui_label = "Distortion Amplitude (Time)"; ui_tooltip = "Amplitude of time-based distortion wave (sin(z)+Amp)."; ui_min = DISTORT_SIN_Z_AMP_MIN; ui_max = DISTORT_SIN_Z_AMP_MAX; ui_step = DISTORT_SIN_Z_AMP_STEP; ui_category = "Pattern/Distortion"; > = DISTORT_SIN_Z_AMP_DEFAULT;
uniform float UI_DistortSinLFreq < ui_type = "slider"; ui_label = "Distortion Frequency (Distance)"; ui_tooltip = "Frequency of distance-based distortion wave (sin(l*Freq - ...))."; ui_min = DISTORT_SIN_L_FREQ_MIN; ui_max = DISTORT_SIN_L_FREQ_MAX; ui_step = DISTORT_SIN_L_FREQ_STEP; ui_category = "Pattern/Distortion"; > = DISTORT_SIN_L_FREQ_DEFAULT;
uniform float UI_DistortSinZFreq < ui_type = "slider"; ui_label = "Distortion Frequency (Time)"; ui_tooltip = "Frequency of time component in distance distortion wave (sin(... - Freq*z))."; ui_min = DISTORT_SIN_Z_FREQ_MIN; ui_max = DISTORT_SIN_Z_FREQ_MAX; ui_step = DISTORT_SIN_Z_FREQ_STEP; ui_category = "Pattern/Distortion"; > = DISTORT_SIN_Z_FREQ_DEFAULT;
uniform float UI_ChannelIntensityNumerator < ui_type = "slider"; ui_label = "Line Brightness/Thickness"; ui_tooltip = "Numerator controlling brightness/thickness of pattern lines (Num / dist_to_cell_center)."; ui_min = CHANNEL_INTENSITY_NUMERATOR_MIN; ui_max = CHANNEL_INTENSITY_NUMERATOR_MAX; ui_step = CHANNEL_INTENSITY_NUMERATOR_STEP; ui_category = "Pattern/Distortion"; > = CHANNEL_INTENSITY_NUMERATOR_DEFAULT;
uniform float UI_FinalDistanceFadeFactor < ui_type = "slider"; ui_label = "Center Fade Strength"; ui_tooltip = "Multiplier for fading effect towards the center (Mult / distance_from_center)."; ui_min = FINAL_DISTANCE_FADE_FACTOR_MIN; ui_max = FINAL_DISTANCE_FADE_FACTOR_MAX; ui_step = FINAL_DISTANCE_FADE_FACTOR_STEP; ui_category = "Pattern/Distortion"; > = FINAL_DISTANCE_FADE_FACTOR_DEFAULT;

// --- Animation ---
uniform float AnimationSpeed < ui_type = "slider"; ui_label = "Animation Speed"; ui_tooltip = "Controls the overall animation speed of the effect."; ui_min = ANIMATION_SPEED_MIN; ui_max = ANIMATION_SPEED_MAX; ui_step = ANIMATION_SPEED_STEP; ui_category = "Animation"; > = ANIMATION_SPEED_DEFAULT;

// --- Audio Reactivity ---
AS_AUDIO_SOURCE_UI(InfZoom_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity") // Changed prefix
AS_AUDIO_MULTIPLIER_UI(InfZoom_AudioMultiplier, "Audio Intensity", AUDIO_MULTIPLIER_DEFAULT, AUDIO_MULTIPLIER_MAX, "Audio Reactivity") // Changed prefix
uniform int InfZoom_AudioTarget < // Changed prefix
    ui_type = "combo"; 
    ui_label = "Audio Target Parameter"; 
    ui_items = "None\0Animation Speed\0Distortion Amplitude (Time)\0Distortion Frequency (Distance)\0Line Brightness\0"; 
    ui_category = "Audio Reactivity"; 
> = AUDIO_TARGET_DEFAULT;

// --- Palette & Style ---
uniform bool UseOriginalColors < ui_label = "Use Original Math Colors"; ui_tooltip = "When enabled, uses the mathematically calculated RGB colors instead of palettes."; ui_category = "Palette & Style"; > = true;
uniform float OriginalColorIntensity < ui_type = "slider"; ui_label = "Original Color Intensity"; ui_tooltip = "Adjusts the intensity of original colors when enabled."; ui_min = 0.1; ui_max = ORIG_COLOR_INTENSITY_MAX; ui_step = 0.01; ui_category = "Palette & Style"; ui_spacing = 0; > = ORIG_COLOR_INTENSITY_DEFAULT;
uniform float OriginalColorSaturation < ui_type = "slider"; ui_label = "Original Color Saturation"; ui_tooltip = "Adjusts the saturation of original colors when enabled."; ui_min = 0.0; ui_max = ORIG_COLOR_SATURATION_MAX; ui_step = 0.01; ui_category = "Palette & Style"; > = ORIG_COLOR_SATURATION_DEFAULT;
AS_PALETTE_SELECTION_UI(PalettePreset, "Color Palette", AS_PALETTE_NEON, "Palette & Style") // Default Turbo? Pick one.
AS_DECLARE_CUSTOM_PALETTE(InfiniteZoom_, "Palette & Style") // Changed prefix
uniform float ColorCycleSpeed < ui_type = "slider"; ui_label = "Color Cycle Speed"; ui_tooltip = "Controls how fast palette colors cycle. 0 = static."; ui_min = -COLOR_CYCLE_SPEED_MAX; ui_max = COLOR_CYCLE_SPEED_MAX; ui_step = 0.1; ui_category = "Palette & Style"; > = COLOR_CYCLE_SPEED_DEFAULT;

// --- Final Mix ---
AS_BLENDMODE_UI(BlendMode, "Final Mix")
AS_BLENDAMOUNT_UI(BlendStrength, "Final Mix")

// --- Debug ---
AS_DEBUG_MODE_UI("Off\0Show Audio Reactivity\0")

// --- Internal Constants ---
static const float EPSILON = 1e-5f; // Adjusted epsilon slightly
static const float HALF_POINT = 0.5f; 
static const int MAX_LOOP_ITERATIONS = 3; // Fixed loop count from original

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Get color from the currently selected palette
float3 getInfiniteZoomColor(float t, float time) { // Changed name
    if (ColorCycleSpeed != 0.0) {
        float cycleRate = ColorCycleSpeed * 0.1;
        t = frac(t + cycleRate * time);
    }
    t = saturate(t); 
    
    if (PalettePreset == AS_PALETTE_COUNT) { // Use custom palette
        return AS_GET_INTERPOLATED_CUSTOM_COLOR(InfiniteZoom_, t); // Changed prefix
    }
    return AS_getInterpolatedColor(PalettePreset, t); // Use preset palette
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 InfiniteZoomPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET {
    // Get original pixel color and depth
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);

    // Apply depth test
    if (depth < EffectDepth) {
        return originalColor;
    }

    // Apply audio reactivity to selected parameters
    float animSpeed = AnimationSpeed;
    float distortSinZAmp = UI_DistortSinZAmp;
    float distortSinLFreq = UI_DistortSinLFreq;
    float channelIntensityNumerator = UI_ChannelIntensityNumerator;
    
    float audioReactivity = AS_applyAudioReactivity(1.0, InfZoom_AudioSource, InfZoom_AudioMultiplier, true);
    
    // Map audio target combo index to parameter adjustment
    if (InfZoom_AudioTarget == 1) animSpeed *= audioReactivity;
    else if (InfZoom_AudioTarget == 2) distortSinZAmp *= audioReactivity;
    else if (InfZoom_AudioTarget == 3) distortSinLFreq *= audioReactivity;
    else if (InfZoom_AudioTarget == 4) channelIntensityNumerator *= audioReactivity;

    // Get time, resolution, aspect ratio
    float2 iResolution = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float aspectRatio = iResolution.x / iResolution.y;
    float iTime = AS_getTime() * animSpeed; 

    // Calculate base coordinates (centered, aspect-corrected, rotated)
    float2 centeredCoord;
    if (aspectRatio >= 1.0) {
        centeredCoord.x = (texcoord.x - HALF_POINT) * aspectRatio;
        centeredCoord.y = texcoord.y - HALF_POINT;
    } else {
        centeredCoord.x = texcoord.x - HALF_POINT;
        centeredCoord.y = (texcoord.y - HALF_POINT) / aspectRatio;
    }
    float rotationRadians = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
    float s = sin(rotationRadians);
    float c = cos(rotationRadians);
    float2 p_aspect = float2( // Renamed from rotatedCoord for consistency with GLSL 'p' logic
        centeredCoord.x * c - centeredCoord.y * s,
        centeredCoord.x * s + centeredCoord.y * c
    );

    // Calculate distance 'l' and normalized direction 'p_norm' once
    float l = length(p_aspect);
    float2 p_norm = (l > EPSILON) ? p_aspect / l : float2(0.0f, 0.0f);

    // Initialization for loop
    float3 accumulated_c = float3(0.0f, 0.0f, 0.0f); 
    float z = iTime; 

    // Loop 3 times for R, G, B channels
    [loop] // Hint to compiler
    for (int i = 0; i < MAX_LOOP_ITERATIONS; ++i) 
    {
        // Start with normalized texcoord (before centering/aspect correction)
        float2 uv = texcoord; 
        z += UI_ZOffsetPerChannel; 

        // Calculate UV distortion
        float distortion_magnitude = (sin(z) + distortSinZAmp) * abs(sin(l * distortSinLFreq - UI_DistortSinZFreq * z));
        uv += p_norm * distortion_magnitude;

        // Calculate channel value based on distance from wrapped cell center
        float2 wrapped_uv_centered = frac(uv) - HALF_POINT; 
        float dist_cell_center = length(wrapped_uv_centered);
        dist_cell_center = max(dist_cell_center, EPSILON); // Avoid division by zero

        float channel_val = channelIntensityNumerator / dist_cell_center;

        // Assign to R, G, or B component
        if (i == 0) accumulated_c.r = channel_val;
        else if (i == 1) accumulated_c.g = channel_val;
        else accumulated_c.b = channel_val; 
    }

    // --- Final Color Processing ---
    l = max(l, EPSILON); // Avoid division by zero if pixel is exactly at center
    float3 raw_rgb = (accumulated_c / l) * UI_FinalDistanceFadeFactor;

    float3 finalRGB;
    if (UseOriginalColors) {
        // Use the raw math-based colors, adjusted by user controls
        finalRGB = raw_rgb * OriginalColorIntensity;
        
        // Apply saturation adjustment
        float3 grayColor = dot(finalRGB, float3(0.299f, 0.587f, 0.114f)); // Luma calculation
        finalRGB = lerp(grayColor, finalRGB, OriginalColorSaturation);
    } else {
        // Use palette-based colors
        // Map intensity to palette (using length as a simple measure)
        float intensity = saturate(length(raw_rgb) / sqrt(3.0f)); // Normalize intensity roughly
        float3 paletteColor = getInfiniteZoomColor(intensity, iTime); // Use helper function
        finalRGB = paletteColor * (intensity * 0.8f + 0.2f); // Apply intensity back to palette color
    }
    
    // Ensure final color is valid
    finalRGB = saturate(finalRGB); // Clamp to [0,1] range

    float4 effectColor = float4(finalRGB, 1.0f);

    // --- Final Blending & Debug ---
    float4 finalColor = float4(AS_blendResult(originalColor.rgb, effectColor.rgb, BlendMode), 1.0f);
    finalColor = lerp(originalColor, finalColor, BlendStrength);
    
    // Show debug overlay if enabled
    if (DebugMode != AS_DEBUG_OFF) {
        float4 debugMask = float4(0, 0, 0, 0);
        if (DebugMode == 1) { // Show Audio Reactivity
             debugMask = float4(audioReactivity, audioReactivity, audioReactivity, 1.0);
        }
        
        float2 debugCenter = float2(0.1f, 0.1f); // Example position
        float debugRadius = 0.08f;
        if (length(texcoord - debugCenter) < debugRadius) {
            return debugMask;
        }
    }
    
    return finalColor;
}

} // namespace ASInfiniteZoom

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_InfiniteZoom < ui_label="[AS] BGX: Infinite Zoom"; ui_tooltip="Kaleidoscopic infinite zoom/tunnel effect by Danilo Guanabara, ported by Leon Aquitaine.";>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = ASInfiniteZoom::InfiniteZoomPS;
    }
}

#endif // __AS_BGX_InfiniteZoom_1_fx