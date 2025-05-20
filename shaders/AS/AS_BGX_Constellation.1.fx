/**
 * AS_BGX_Constellation.1.fx - Dynamic Cosmic Constellation Pattern
 * Author: Leon Aquitaine (adapted from Art of Code)
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates an animated stellar constellation pattern with twinkling stars and connecting lines.
 * Perfect for cosmic, night sky, or abstract network visualizations with a hand-drawn aesthetic.
 *
 * FEATURES:
 * - Dynamic constellation lines with customizable thickness and falloff
 * - Twinkling star points with adjustable sparkle properties
 * - Procedurally animated line connections
 * - Animated color palette with adjustable parameters
 * - Audio reactivity for gradient effects, line brightness, and sparkle magnitude
 * - Depth-aware rendering
 * - Standard blend options
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Generates a grid of animated star points that move in procedural patterns
 * 2. Creates line connections between these points based on proximity rules
 * 3. Applies twinkling effects to stars using sine-based animation
 * 4. Combines multiple layers at different scales for a parallax depth effect
 * 5. Processes color based on animated palette parameters
 * 
 * Inspired by: Art of Code (YouTube)
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_Constellation_1_fx
#define __AS_BGX_Constellation_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_getTime(), AS_getAudioSource(), UI macros, AS_PI etc.

namespace ASConstellation {

// ============================================================================
// CONSTANTS
// ============================================================================

// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================

// --- Constellation Lines ---
static const float LINE_CORE_THICKNESS_MIN = 0.001; 
static const float LINE_CORE_THICKNESS_MAX = 0.05;
static const float LINE_CORE_THICKNESS_DEFAULT = 0.01;

static const float LINE_FALLOFF_WIDTH_MIN = 0.001;
static const float LINE_FALLOFF_WIDTH_MAX = 0.1;
static const float LINE_FALLOFF_WIDTH_DEFAULT = 0.02;

static const float LINE_OVERALL_BRIGHTNESS_MIN = 0.0;
static const float LINE_OVERALL_BRIGHTNESS_MAX = 10.0;
static const float LINE_OVERALL_BRIGHTNESS_DEFAULT = 1.0;

static const float LINE_LENGTH_MOD_STRENGTH_MIN = 0.0;
static const float LINE_LENGTH_MOD_STRENGTH_MAX = 1.0;
static const float LINE_LENGTH_MOD_STRENGTH_DEFAULT = 1.0;

// --- Star Sparkles ---
static const float SPARKLE_SHARPNESS_MIN = 1.0;
static const float SPARKLE_SHARPNESS_MAX = 50.0;
static const float SPARKLE_SHARPNESS_DEFAULT = 10.0;

static const float SPARKLE_BASE_INTENSITY_MIN = 0.0;
static const float SPARKLE_BASE_INTENSITY_MAX = 5.0;
static const float SPARKLE_BASE_INTENSITY_DEFAULT = 1.0;

static const float SPARKLE_TWINKLE_SPEED_MIN = 0.0;
static const float SPARKLE_TWINKLE_SPEED_MAX = 50.0;
static const float SPARKLE_TWINKLE_SPEED_DEFAULT = 10.0;

static const float SPARKLE_TWINKLE_MAGNITUDE_MIN = 0.0;
static const float SPARKLE_TWINKLE_MAGNITUDE_MAX = 1.0;
static const float SPARKLE_TWINKLE_MAGNITUDE_DEFAULT = 1.0;

static const float SPARKLE_PHASE_VARIATION_MIN = 0.0;
static const float SPARKLE_PHASE_VARIATION_MAX = 50.0;
static const float SPARKLE_PHASE_VARIATION_DEFAULT = 10.0;

// --- Color Palette ---
static const float PALETTE_TIME_SCALE_MIN = 0.0;
static const float PALETTE_TIME_SCALE_MAX = 100.0;
static const float PALETTE_TIME_SCALE_DEFAULT = 20.0;

static const float PALETTE_COLOR_AMPLITUDE_MIN = 0.0;
static const float PALETTE_COLOR_AMPLITUDE_MAX = 1.0;
static const float PALETTE_COLOR_AMPLITUDE_DEFAULT = 0.25;

static const float PALETTE_COLOR_BIAS_MIN = 0.0;
static const float PALETTE_COLOR_BIAS_MAX = 1.0;
static const float PALETTE_COLOR_BIAS_DEFAULT = 0.75;

// --- Audio Reactivity ---
static const float AUDIO_GAIN_GRADIENT_MIN = 0.0;
static const float AUDIO_GAIN_GRADIENT_MAX = 5.0;
static const float AUDIO_GAIN_GRADIENT_DEFAULT = 1.0;

static const float AUDIO_GAIN_LINE_BRIGHTNESS_MIN = 0.0;
static const float AUDIO_GAIN_LINE_BRIGHTNESS_MAX = 2.0;
static const float AUDIO_GAIN_LINE_BRIGHTNESS_DEFAULT = 0.0;

static const float AUDIO_GAIN_LINE_FALLOFF_MIN = 0.0;
static const float AUDIO_GAIN_LINE_FALLOFF_MAX = 2.0;
static const float AUDIO_GAIN_LINE_FALLOFF_DEFAULT = 0.0;

static const float AUDIO_GAIN_SPARKLE_MAG_MIN = 0.0;
static const float AUDIO_GAIN_SPARKLE_MAG_MAX = 3.0;
static const float AUDIO_GAIN_SPARKLE_MAG_DEFAULT = 0.0;

// ============================================================================
// UI DECLARATIONS - Organized by category
// ============================================================================

//------------------------------------------------------------------------------------------------
// Animation & Time Controls
//------------------------------------------------------------------------------------------------
AS_ANIMATION_UI(TimeSpeed, TimeKeyframe, "Animation & Time")

//------------------------------------------------------------------------------------------------
// Audio Reactivity
//------------------------------------------------------------------------------------------------
AS_AUDIO_SOURCE_UI(MasterAudioSource, "Master Audio Source", AS_AUDIO_BASS, "Audio Reactivity")

uniform float AudioGain_GradientEffect < ui_type = "slider"; ui_label = "Gradient Effect Audio Gain"; ui_tooltip = "How much audio affects the color gradient subtraction."; ui_min = AUDIO_GAIN_GRADIENT_MIN; ui_max = AUDIO_GAIN_GRADIENT_MAX; ui_step = 0.01; ui_category = "Audio Reactivity"; > = AUDIO_GAIN_GRADIENT_DEFAULT;
uniform float AudioGain_LineBrightness < ui_type = "slider"; ui_label = "Line Brightness Audio Gain"; ui_tooltip = "How much audio affects overall line brightness."; ui_min = AUDIO_GAIN_LINE_BRIGHTNESS_MIN; ui_max = AUDIO_GAIN_LINE_BRIGHTNESS_MAX; ui_step = 0.01; ui_category = "Audio Reactivity"; > = AUDIO_GAIN_LINE_BRIGHTNESS_DEFAULT;
uniform float AudioGain_LineFalloff < ui_type = "slider"; ui_label = "Line Falloff Audio Gain"; ui_tooltip = "How much audio affects line falloff width (can make lines appear thinner/softer)."; ui_min = AUDIO_GAIN_LINE_FALLOFF_MIN; ui_max = AUDIO_GAIN_LINE_FALLOFF_MAX; ui_step = 0.01; ui_category = "Audio Reactivity"; > = AUDIO_GAIN_LINE_FALLOFF_DEFAULT;
uniform float AudioGain_SparkleMagnitude < ui_type = "slider"; ui_label = "Sparkle Magnitude Audio Gain"; ui_tooltip = "How much audio affects sparkle twinkle strength."; ui_min = AUDIO_GAIN_SPARKLE_MAG_MIN; ui_max = AUDIO_GAIN_SPARKLE_MAG_MAX; ui_step = 0.01; ui_category = "Audio Reactivity"; > = AUDIO_GAIN_SPARKLE_MAG_DEFAULT;

//------------------------------------------------------------------------------------------------
// Constellation Lines
//------------------------------------------------------------------------------------------------
uniform float LineCoreThickness < ui_type = "drag"; ui_label = "Line Core Thickness"; ui_min = LINE_CORE_THICKNESS_MIN; ui_max = LINE_CORE_THICKNESS_MAX; ui_step = 0.001; ui_category = "Constellation Lines"; > = LINE_CORE_THICKNESS_DEFAULT;
uniform float LineFalloffWidth < ui_type = "drag"; ui_label = "Line Falloff Width"; ui_min = LINE_FALLOFF_WIDTH_MIN; ui_max = LINE_FALLOFF_WIDTH_MAX; ui_step = 0.001; ui_category = "Constellation Lines"; > = LINE_FALLOFF_WIDTH_DEFAULT;
uniform float LineOverallBrightness < ui_type = "drag"; ui_label = "Line Overall Brightness"; ui_min = LINE_OVERALL_BRIGHTNESS_MIN; ui_max = LINE_OVERALL_BRIGHTNESS_MAX; ui_step = 0.1; ui_category = "Constellation Lines"; > = LINE_OVERALL_BRIGHTNESS_DEFAULT;
uniform float LineLengthModStrength < ui_type = "drag"; ui_label = "Line Length Brightness Modulation"; ui_min = LINE_LENGTH_MOD_STRENGTH_MIN; ui_max = LINE_LENGTH_MOD_STRENGTH_MAX; ui_step = 0.01; ui_category = "Constellation Lines"; > = LINE_LENGTH_MOD_STRENGTH_DEFAULT;

//------------------------------------------------------------------------------------------------
// Star Sparkles
//------------------------------------------------------------------------------------------------
uniform float SparkleSharpness < ui_type = "drag"; ui_label = "Sparkle Sharpness / Area Divisor"; ui_min = SPARKLE_SHARPNESS_MIN; ui_max = SPARKLE_SHARPNESS_MAX; ui_step = 0.1; ui_category = "Star Sparkles"; > = SPARKLE_SHARPNESS_DEFAULT;
uniform float SparkleBaseIntensity < ui_type = "drag"; ui_label = "Sparkle Base Intensity"; ui_min = SPARKLE_BASE_INTENSITY_MIN; ui_max = SPARKLE_BASE_INTENSITY_MAX; ui_step = 0.01; ui_category = "Star Sparkles"; > = SPARKLE_BASE_INTENSITY_DEFAULT;
uniform float SparkleTwinkleSpeed < ui_type = "drag"; ui_label = "Sparkle Twinkle Speed"; ui_min = SPARKLE_TWINKLE_SPEED_MIN; ui_max = SPARKLE_TWINKLE_SPEED_MAX; ui_step = 0.1; ui_category = "Star Sparkles"; > = SPARKLE_TWINKLE_SPEED_DEFAULT;
uniform float SparkleTwinkleMagnitude < ui_type = "drag"; ui_label = "Sparkle Twinkle Magnitude"; ui_min = SPARKLE_TWINKLE_MAGNITUDE_MIN; ui_max = SPARKLE_TWINKLE_MAGNITUDE_MAX; ui_step = 0.01; ui_category = "Star Sparkles"; > = SPARKLE_TWINKLE_MAGNITUDE_DEFAULT;
uniform float SparklePhaseVariation < ui_type = "drag"; ui_label = "Sparkle Twinkle Phase Variation"; ui_min = SPARKLE_PHASE_VARIATION_MIN; ui_max = SPARKLE_PHASE_VARIATION_MAX; ui_step = 0.1; ui_category = "Star Sparkles"; > = SPARKLE_PHASE_VARIATION_DEFAULT;

//------------------------------------------------------------------------------------------------
// Color Palette
//------------------------------------------------------------------------------------------------
uniform float PaletteTimeScale < ui_type = "drag"; ui_label = "Palette Animation Speed"; ui_min = PALETTE_TIME_SCALE_MIN; ui_max = PALETTE_TIME_SCALE_MAX; ui_step = 0.1; ui_category = "Color Palette"; > = PALETTE_TIME_SCALE_DEFAULT;
uniform float3 PaletteColorPhaseFactors < ui_type = "drag"; ui_label = "Palette Color Phase Factors (RGB)"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_category = "Color Palette"; > = float3(0.345f, 0.543f, 0.682f);
uniform float PaletteColorAmplitude < ui_type = "drag"; ui_label = "Palette Color Amplitude"; ui_min = PALETTE_COLOR_AMPLITUDE_MIN; ui_max = PALETTE_COLOR_AMPLITUDE_MAX; ui_step = 0.01; ui_category = "Color Palette"; > = PALETTE_COLOR_AMPLITUDE_DEFAULT;
uniform float PaletteColorBias < ui_type = "drag"; ui_label = "Palette Color Bias (Brightness)"; ui_min = PALETTE_COLOR_BIAS_MIN; ui_max = PALETTE_COLOR_BIAS_MAX; ui_step = 0.01; ui_category = "Color Palette"; > = PALETTE_COLOR_BIAS_DEFAULT;

//------------------------------------------------------------------------------------------------
// Stage & Depth
//------------------------------------------------------------------------------------------------
AS_STAGEDEPTH_UI(EffectDepth)

//------------------------------------------------------------------------------------------------
// Final Mix
//------------------------------------------------------------------------------------------------
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================
float dist_line(float2 p, float2 a, float2 b) {
    float2 pa = p - a;
    float2 ba = b - a;
    float t = saturate(dot(pa, ba) / (dot(ba, ba) + AS_EPSILON)); 
    return length(pa - ba * t);   
}

float n21(float2 p) {
    p = frac(p * float2(233.24f, 851.73f));
    p += dot(p, p + 23.45f);
    return frac(p.x * p.y);
}

float2 n22(float2 p) {
    float n = n21(p);
    return float2(n, n21(p + n)); 
}

float2 get_pos(float2 id, float2 offs, float current_time_local) { 
    float2 n = n22(id + offs) * current_time_local; 
    return offs + sin(n) * 0.4f; 
}

float line(float2 p, float2 a, float2 b, float current_LineCoreThickness, float current_LineFalloffWidth_audio_mod) {
    float d = dist_line(p, a, b);
    float line_fade_end = current_LineCoreThickness + current_LineFalloffWidth_audio_mod; // Use audio-modulated falloff
    float m = smoothstep(line_fade_end, current_LineCoreThickness, d); 
    float d2 = length(a - b); 
    float d2_modulation_original = smoothstep(1.6f, 0.5f, d2) * 0.5f + smoothstep(0.05f, 0.03f, abs(d2 - 0.75f));
    m *= lerp(1.0f, saturate(d2_modulation_original), LineLengthModStrength); 
    return m;
}

float layer(float2 uv, float current_time_local, float current_LineCoreThickness, float current_LineFalloffWidth_audio_mod, float current_SparkleTwinkleMagnitude_audio_mod) { 
    float m = 0.0f;
    float2 gv = frac(uv) - 0.5f; 
    float2 id = floor(uv);      
    float2 p_arr[9]; 
    int idx = 0; 
    for (float y_offset = -1.0f; y_offset <= 1.0f; y_offset += 1.0f) {
        for (float x_offset = -1.0f; x_offset <= 1.0f; x_offset += 1.0f) {
            if (idx < 9) p_arr[idx++] = get_pos(id, float2(x_offset, y_offset), current_time_local);
        }
    }
    float t_sparkle_anim = current_time_local * SparkleTwinkleSpeed; 
    for (int k = 0; k < 9; k++) { 
        m += line(gv, p_arr[4], p_arr[k], current_LineCoreThickness, current_LineFalloffWidth_audio_mod); 
        float2 j_sparkle = (p_arr[k] - gv) * SparkleSharpness; 
        float sparkle_intensity_base = SparkleBaseIntensity / (dot(j_sparkle, j_sparkle) + AS_EPSILON); 
        float twinkle_effect = (sin(t_sparkle_anim + frac(p_arr[k].x) * SparklePhaseVariation) * 0.5f + 0.5f);
        m += sparkle_intensity_base * twinkle_effect * current_SparkleTwinkleMagnitude_audio_mod; // Use audio-modulated magnitude
    }
    m += line(gv, p_arr[1], p_arr[3], current_LineCoreThickness, current_LineFalloffWidth_audio_mod); 
    m += line(gv, p_arr[1], p_arr[5], current_LineCoreThickness, current_LineFalloffWidth_audio_mod); 
    m += line(gv, p_arr[5], p_arr[7], current_LineCoreThickness, current_LineFalloffWidth_audio_mod); 
    m += line(gv, p_arr[3], p_arr[7], current_LineCoreThickness, current_LineFalloffWidth_audio_mod);
    return m;
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_Constellation(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);    float current_iTime = AS_getAnimationTime(TimeSpeed, TimeKeyframe);
    float2 fragCoord = texcoord * ReShade::ScreenSize; 
    float2 uv = (fragCoord - 0.5f * ReShade::ScreenSize) / ReShade::ScreenSize.y;
    float gradient_base = uv.y; 
    float m_accum = 0.0f; 
    float t_anim_main = current_iTime * 0.1f; 
    float s_rot = sin(t_anim_main * 2.0f);
    float c_rot = cos(t_anim_main * 5.0f); 
    float2x2 rot_matrix = float2x2(c_rot, s_rot, -s_rot, c_rot); 
    float2 uv_rotated = mul(uv, rot_matrix);

    // Get master audio level once
    float master_audio_level = AS_getAudioSource(MasterAudioSource);

    // Apply audio reactivity to parameters using master audio level and specific gains
    float active_LineOverallBrightness = LineOverallBrightness * (1.0f + master_audio_level * AudioGain_LineBrightness);
    float active_SparkleTwinkleMagnitude = SparkleTwinkleMagnitude * (1.0f + master_audio_level * AudioGain_SparkleMagnitude);
    float active_LineFalloffWidth = LineFalloffWidth * (1.0f + master_audio_level * AudioGain_LineFalloff);
    active_LineFalloffWidth = max(0.001f, active_LineFalloffWidth); 

    // FFT simulated value for gradient effect, also using master audio level
    float fft_simulated = master_audio_level * AudioGain_GradientEffect;

    const float step_val = 1.0f / 4.0f;
    for (float i_layer = 0.0f; i_layer < (1.0f - step_val / 2.0f); i_layer += step_val) { 
        float z_phase = frac(i_layer + t_anim_main);        float size_mix = lerp(10.0f, 0.5f, z_phase);  
        float fade_mix = smoothstep(0.0f, 0.5f, z_phase) * smoothstep(1.0f, 0.8f, z_phase); 
        
        m_accum += layer(uv_rotated * size_mix + i_layer * 20.0f, 
                         current_iTime, 
                         LineCoreThickness, // Base thickness
                         active_LineFalloffWidth, // Audio-modulated falloff
                         active_SparkleTwinkleMagnitude // Audio-modulated sparkle magnitude
                        ) * fade_mix;
    }
    
    float3 base_color_palette = sin(t_anim_main * PaletteTimeScale * PaletteColorPhaseFactors) * PaletteColorAmplitude + PaletteColorBias;
    
    float3 col_final = m_accum * active_LineOverallBrightness * base_color_palette; // Use audio-modulated brightness
    
    float gradient_eff = gradient_base * fft_simulated * 2.0f; 
    col_final -= gradient_eff * base_color_palette; 
    
    // Apply depth masking
    float depth = ReShade::GetLinearizedDepth(texcoord);
    float depthMask = depth >= EffectDepth;
    
    // Blend the final color with the original scene
    float3 blended = AS_ApplyBlend(saturate(col_final), originalColor.rgb, BlendMode);
    return float4(lerp(originalColor.rgb, blended, BlendStrength * depthMask), 1.0f);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_Constellation <
    ui_label = "[AS] BGX: Constellation";
    ui_tooltip = "Dynamic cosmic constellation pattern with twinkling stars and connecting lines.\n"
                 "Perfect for cosmic, night sky, or abstract network visualizations.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Constellation;
    }
}

} // namespace ASConstellation

#endif // __AS_BGX_Constellation_1_fx
