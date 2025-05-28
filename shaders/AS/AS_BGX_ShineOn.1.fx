/**
 * AS_BGX_ShineOn.1.fx - Fractal noise-based glow effect with crystal highlights
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Based on "Shine On" by emodeman
 * Shadertoy: https://www.shadertoy.com/view/st23zw
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a dynamic, evolving fractal noise pattern with bright, sparkly crystal 
 * highlights that move across the screen. Combines multiple layers of noise with  
 * procedural animation for a mesmerizing background effect.
 * 
 * FEATURES:
 * - Layered noise patterns with dynamic animation
 * - Crystal point highlights with customizable parameters
 * - Audio reactivity support through Listeningway
 * - Depth-aware rendering can be placed behind scene objects
 * - Extensive customization options for all effect aspects
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Generates dynamic fractal Brownian motion noise patterns
 * 2. Applies multiple rotation and time-dependent transformations * 3. Creates animated crystal points that move across the screen
 * 4. Combines all elements with adjustable color transformations
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_ShineOn_1_fx
#define __AS_BGX_ShineOn_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

namespace ASShineOn {
// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================

// --- Tunable Constants ---
// Main Parameters
static const float ZOOM_MIN = 0.1f;
static const float ZOOM_MAX = 5.0f;
static const float ZOOM_STEP = 0.01f;
static const float ZOOM_DEFAULT = 3.20f;

static const float ANIM_SPEED_MIN = 0.0f;
static const float ANIM_SPEED_MAX = 2.0f;
static const float ANIM_SPEED_STEP = 0.01f;
static const float ANIM_SPEED_DEFAULT = 0.62f;
static const float ANIM_KEYFRAME_MIN = 0.0f;
static const float ANIM_KEYFRAME_MAX = 100.0f;
static const float ANIM_KEYFRAME_STEP = 0.1f;
static const float ANIM_KEYFRAME_DEFAULT = 0.0f;

// Crystal Parameters
static const int CRYSTAL_ITERATIONS_MIN = 1; 
static const int CRYSTAL_ITERATIONS_MAX = 30; 
static const int CRYSTAL_ITERATIONS_DEFAULT = 12;

static const float CRYSTAL_STEP_MIN = 1.0f;
static const float CRYSTAL_STEP_MAX = 10.0f;
static const float CRYSTAL_STEP_STEP = 0.1f;
static const float CRYSTAL_STEP_DEFAULT = 4.1f;

static const float CRYSTAL_SIZE_FACTOR_MIN = 0.0001f;
static const float CRYSTAL_SIZE_FACTOR_MAX = 0.01f;
static const float CRYSTAL_SIZE_FACTOR_STEP = 0.0001f;
static const float CRYSTAL_SIZE_FACTOR_DEFAULT = 0.0029f;

static const float CRYSTAL_AMP_MIN = 0.1f;
static const float CRYSTAL_AMP_MAX = 1.5f;
static const float CRYSTAL_AMP_STEP = 0.05f;
static const float CRYSTAL_AMP_DEFAULT = 1.13f;

static const float CRYSTAL_RADIUS_MIN = 0.0f;
static const float CRYSTAL_RADIUS_MAX = 50.0f;
static const float CRYSTAL_RADIUS_STEP = 0.5f;
static const float CRYSTAL_RADIUS_DEFAULT = 17.4f;

static const float CRYSTAL_RANGE_OFFSET_MIN = 0.0f;
static const float CRYSTAL_RANGE_OFFSET_MAX = 300.0f;
static const float CRYSTAL_RANGE_OFFSET_STEP = 1.0f;
static const float CRYSTAL_RANGE_OFFSET_DEFAULT = 63.0f;

static const float CRYSTAL_TIME_FACTOR_MIN = 0.0f;
static const float CRYSTAL_TIME_FACTOR_MAX = 2.0f;
static const float CRYSTAL_TIME_FACTOR_STEP = 0.05f;
static const float CRYSTAL_TIME_FACTOR_DEFAULT = 0.78f;

// FBM Parameters
static const int FBM_OCTAVES_MIN = 1;
static const int FBM_OCTAVES_MAX = 28;
static const int FBM_OCTAVES_DEFAULT = 2;

static const float FBM_AMP_DECAY_MIN = 0.5f;
static const float FBM_AMP_DECAY_MAX = 0.95f;
static const float FBM_AMP_DECAY_STEP = 0.01f;
static const float FBM_AMP_DECAY_DEFAULT = 0.75f;

static const float FBM_FREQ_INC_MIN = 1.0f;
static const float FBM_FREQ_INC_MAX = 2.0f;
static const float FBM_FREQ_INC_STEP = 0.01f;
static const float FBM_FREQ_INC_DEFAULT = 1.43f;

static const int FBM_LOW_OCTAVES_MIN = 1;
static const int FBM_LOW_OCTAVES_MAX = 8;
static const int FBM_LOW_OCTAVES_DEFAULT = 3;

// Main Noise Parameters
static const float MAIN_TIME_SCALE_MIN = 0.0f;
static const float MAIN_TIME_SCALE_MAX = 1.0f;
static const float MAIN_TIME_SCALE_STEP = 0.01f;
static const float MAIN_TIME_SCALE_DEFAULT = 0.1f;

static const float MAIN_UV_SCALE1_MIN = 0.5f;
static const float MAIN_UV_SCALE1_MAX = 5.0f;
static const float MAIN_UV_SCALE1_STEP = 0.1f;
static const float MAIN_UV_SCALE1_DEFAULT = 2.0f;

static const float MAIN_UV_SCALE2_MIN = 5.0f;
static const float MAIN_UV_SCALE2_MAX = 60.0f;
static const float MAIN_UV_SCALE2_STEP = 1.0f;
static const float MAIN_UV_SCALE2_DEFAULT = 29.0f;

static const float MAIN_UV_SCALE3_MIN = 0.5f;
static const float MAIN_UV_SCALE3_MAX = 4.0f;
static const float MAIN_UV_SCALE3_STEP = 0.1f;
static const float MAIN_UV_SCALE3_DEFAULT = 2.6f;

static const float MAIN_UV_SCALE4_MIN = 1.0f;
static const float MAIN_UV_SCALE4_MAX = 16.0f;
static const float MAIN_UV_SCALE4_STEP = 0.5f;
static const float MAIN_UV_SCALE4_DEFAULT = 6.3f;

static const float MAIN_RAND_MIX_MIN = 0.0f;
static const float MAIN_RAND_MIX_MAX = 0.1f;
static const float MAIN_RAND_MIX_STEP = 0.001f;
static const float MAIN_RAND_MIX_DEFAULT = 0.006f;

// Color Parameters
static const float COLOR_SCALE1_MIN = 0.5f;
static const float COLOR_SCALE1_MAX = 3.0f;
static const float COLOR_SCALE1_STEP = 0.05f;
static const float COLOR_SCALE1_DEFAULT = 1.6f;

static const float COLOR_SCALE2_MIN = 1.0f;
static const float COLOR_SCALE2_MAX = 6.0f;
static const float COLOR_SCALE2_STEP = 0.1f;
static const float COLOR_SCALE2_DEFAULT = 3.7f;

static const float SMOOTHSTEP_MIN_MIN = 0.0f;
static const float SMOOTHSTEP_MIN_MAX = 0.9f;
static const float SMOOTHSTEP_MIN_STEP = 0.01f;
static const float SMOOTHSTEP_MIN_DEFAULT = 0.20f;

static const float SMOOTHSTEP_MAX_MIN = 0.1f;
static const float SMOOTHSTEP_MAX_MAX = 1.0f;
static const float SMOOTHSTEP_MAX_STEP = 0.01f;
static const float SMOOTHSTEP_MAX_DEFAULT = 0.67f;

static const float POW_EXPONENT_SCALE_MIN = 0.01f;
static const float POW_EXPONENT_SCALE_MAX = 5.0f;
static const float POW_EXPONENT_SCALE_STEP = 0.01f;
static const float POW_EXPONENT_SCALE_DEFAULT = 1.59f;

// Audio
static const int AUDIO_TARGET_DEFAULT = 2;
static const float AUDIO_MULTIPLIER_DEFAULT = 1.0f;
static const float AUDIO_MULTIPLIER_MAX = 2.0f;

// --- Internal Constants ---
static const float AS_PI = 3.14159265f;
static const float AS_EPSILON = 1e-5f;
static const float NOISE_DOT_VEC1_X = 12.9898f;
static const float NOISE_DOT_VEC1_Y = 78.233f; 
static const float NOISE_DOT_VEC1_Z = 37.429f;
static const float NOISE_MAGIC1 = 43758.5453f;
static const float NOISE_P_Y_FACTOR = 57.0f;
static const float NOISE_P_Z_FACTOR = 113.0f;

// ============================================================================
// UI UNIFORMS
// ============================================================================

// --- Stage ---
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation)

// --- Main Parameters ---
uniform float Zoom < ui_type = "slider"; ui_label = "Zoom"; ui_tooltip = "Zoom factor for the noise pattern. >1 zooms in, <1 zooms out."; ui_min = ZOOM_MIN; ui_max = ZOOM_MAX; ui_step = ZOOM_STEP; ui_category = "Main Parameters"; > = ZOOM_DEFAULT;
uniform float AnimationKeyframe < ui_type = "slider"; ui_label = "Animation Keyframe"; ui_tooltip = "Sets a specific point in time for the animation. Useful for finding and saving specific patterns."; ui_min = ANIM_KEYFRAME_MIN; ui_max = ANIM_KEYFRAME_MAX; ui_step = ANIM_KEYFRAME_STEP; ui_category = "Main Parameters"; > = ANIM_KEYFRAME_DEFAULT;
uniform float AnimSpeed < ui_type = "slider"; ui_label = "Animation Speed"; ui_tooltip = "Controls the overall speed of the animation. Set to 0 to pause animation and use keyframe only."; ui_min = ANIM_SPEED_MIN; ui_max = ANIM_SPEED_MAX; ui_step = ANIM_SPEED_STEP; ui_category = "Main Parameters"; > = ANIM_SPEED_DEFAULT;

// --- Crystal Parameters ---
uniform int CrystalIterations < ui_type = "slider"; ui_label = "Crystal Iterations"; ui_tooltip = "Number of crystal points to render. Higher values create more highlights."; ui_min = CRYSTAL_ITERATIONS_MIN; ui_max = CRYSTAL_ITERATIONS_MAX; ui_category = "Crystal Parameters"; > = CRYSTAL_ITERATIONS_DEFAULT;
uniform float CrystalStep < ui_type = "slider"; ui_label = "Crystal Loop Step"; ui_tooltip = "Step size between crystal iterations. Affects spacing and pattern."; ui_min = CRYSTAL_STEP_MIN; ui_max = CRYSTAL_STEP_MAX; ui_step = CRYSTAL_STEP_STEP; ui_category = "Crystal Parameters"; > = CRYSTAL_STEP_DEFAULT;
uniform float CrystalSizeFactor < ui_type = "slider"; ui_label = "Crystal Size Factor"; ui_tooltip = "Controls the overall size of crystal points."; ui_format = "%.4f"; ui_min = CRYSTAL_SIZE_FACTOR_MIN; ui_max = CRYSTAL_SIZE_FACTOR_MAX; ui_step = CRYSTAL_SIZE_FACTOR_STEP; ui_category = "Crystal Parameters"; > = CRYSTAL_SIZE_FACTOR_DEFAULT;
uniform float CrystalAmp < ui_type = "slider"; ui_label = "Crystal Color Amp/Offset"; ui_tooltip = "Affects the intensity and color of crystal highlights."; ui_min = CRYSTAL_AMP_MIN; ui_max = CRYSTAL_AMP_MAX; ui_step = CRYSTAL_AMP_STEP; ui_category = "Crystal Parameters"; > = CRYSTAL_AMP_DEFAULT;
uniform float CrystalRadius < ui_type = "slider"; ui_label = "Crystal Point Radius"; ui_tooltip = "Size of each crystal highlight point."; ui_min = CRYSTAL_RADIUS_MIN; ui_max = CRYSTAL_RADIUS_MAX; ui_step = CRYSTAL_RADIUS_STEP; ui_category = "Crystal Parameters"; > = CRYSTAL_RADIUS_DEFAULT; 
uniform float CrystalRangeOffset < ui_type = "slider"; ui_label = "Crystal Range Offset"; ui_tooltip = "Controls how far crystal points can range from center."; ui_min = CRYSTAL_RANGE_OFFSET_MIN; ui_max = CRYSTAL_RANGE_OFFSET_MAX; ui_step = CRYSTAL_RANGE_OFFSET_STEP; ui_category = "Crystal Parameters"; > = CRYSTAL_RANGE_OFFSET_DEFAULT;
uniform float CrystalTimeFactor < ui_type = "slider"; ui_label = "Crystal Time Speed Factor"; ui_tooltip = "Animation speed multiplier for crystal movement."; ui_min = CRYSTAL_TIME_FACTOR_MIN; ui_max = CRYSTAL_TIME_FACTOR_MAX; ui_step = CRYSTAL_TIME_FACTOR_STEP; ui_category = "Crystal Parameters"; > = CRYSTAL_TIME_FACTOR_DEFAULT;

// --- Noise Parameters ---
uniform int FbmOctaves < ui_type = "slider"; ui_label = "FBM Octaves"; ui_tooltip = "Number of fractal iterations for main noise. Higher values add more detail."; ui_min = FBM_OCTAVES_MIN; ui_max = FBM_OCTAVES_MAX; ui_category = "Noise Parameters"; > = FBM_OCTAVES_DEFAULT;
uniform float FbmAmpDecay < ui_type = "slider"; ui_label = "FBM Amp Decay (Persistence)"; ui_tooltip = "How quickly amplitude decreases with each octave. Higher values create more prominent details."; ui_min = FBM_AMP_DECAY_MIN; ui_max = FBM_AMP_DECAY_MAX; ui_step = FBM_AMP_DECAY_STEP; ui_category = "Noise Parameters"; > = FBM_AMP_DECAY_DEFAULT;
uniform float FbmFreqInc < ui_type = "slider"; ui_label = "FBM Freq Increase (Lacunarity)"; ui_tooltip = "How quickly frequency increases with each octave. Higher values create more intricate patterns."; ui_min = FBM_FREQ_INC_MIN; ui_max = FBM_FREQ_INC_MAX; ui_step = FBM_FREQ_INC_STEP; ui_category = "Noise Parameters"; > = FBM_FREQ_INC_DEFAULT;
uniform int FbmLowOctaves < ui_type = "slider"; ui_label = "FBM Low Octaves"; ui_tooltip = "Number of octaves for the low-frequency noise layer."; ui_min = FBM_LOW_OCTAVES_MIN; ui_max = FBM_LOW_OCTAVES_MAX; ui_category = "Noise Parameters"; > = FBM_LOW_OCTAVES_DEFAULT;

// --- UV Scaling Parameters ---
uniform float MainTimeScale < ui_type = "slider"; ui_label = "Main Noise Time Scale"; ui_tooltip = "Speed multiplier for the main noise animation."; ui_min = MAIN_TIME_SCALE_MIN; ui_max = MAIN_TIME_SCALE_MAX; ui_step = MAIN_TIME_SCALE_STEP; ui_category = "UV Scaling"; > = MAIN_TIME_SCALE_DEFAULT;
uniform float MainUVScale1 < ui_type = "slider"; ui_label = "Main UV Scale 1 (rv)"; ui_tooltip = "Scale factor for primary UV transformation."; ui_min = MAIN_UV_SCALE1_MIN; ui_max = MAIN_UV_SCALE1_MAX; ui_step = MAIN_UV_SCALE1_STEP; ui_category = "UV Scaling"; > = MAIN_UV_SCALE1_DEFAULT;
uniform float MainUVScale2 < ui_type = "slider"; ui_label = "Main UV Scale 2 (rv)"; ui_tooltip = "Scale factor for secondary UV transformation."; ui_min = MAIN_UV_SCALE2_MIN; ui_max = MAIN_UV_SCALE2_MAX; ui_step = MAIN_UV_SCALE2_STEP; ui_category = "UV Scaling"; > = MAIN_UV_SCALE2_DEFAULT;
uniform float MainUVScale3 < ui_type = "slider"; ui_label = "Main UV Scale 3 (fbm1)"; ui_tooltip = "Scale factor for first FBM noise layer."; ui_min = MAIN_UV_SCALE3_MIN; ui_max = MAIN_UV_SCALE3_MAX; ui_step = MAIN_UV_SCALE3_STEP; ui_category = "UV Scaling"; > = MAIN_UV_SCALE3_DEFAULT;
uniform float MainUVScale4 < ui_type = "slider"; ui_label = "Main UV Scale 4 (fbm2)"; ui_tooltip = "Scale factor for second FBM noise layer."; ui_min = MAIN_UV_SCALE4_MIN; ui_max = MAIN_UV_SCALE4_MAX; ui_step = MAIN_UV_SCALE4_STEP; ui_category = "UV Scaling"; > = MAIN_UV_SCALE4_DEFAULT;
uniform float MainRandMix < ui_type = "slider"; ui_label = "Main Noise Mix Factor"; ui_tooltip = "Amount of random noise to mix into the pattern."; ui_min = MAIN_RAND_MIX_MIN; ui_max = MAIN_RAND_MIX_MAX; ui_step = MAIN_RAND_MIX_STEP; ui_format = "%.3f"; ui_category = "UV Scaling"; > = MAIN_RAND_MIX_DEFAULT;

// --- Color Parameters ---
uniform float ColorScale1 < ui_type = "slider"; ui_label = "Main Color Scale 1"; ui_tooltip = "First color scaling factor."; ui_min = COLOR_SCALE1_MIN; ui_max = COLOR_SCALE1_MAX; ui_step = COLOR_SCALE1_STEP; ui_category = "Color Parameters"; > = COLOR_SCALE1_DEFAULT;
uniform float ColorScale2 < ui_type = "slider"; ui_label = "Main Color Scale 2"; ui_tooltip = "Second color scaling factor."; ui_min = COLOR_SCALE2_MIN; ui_max = COLOR_SCALE2_MAX; ui_step = COLOR_SCALE2_STEP; ui_category = "Color Parameters"; > = COLOR_SCALE2_DEFAULT;
uniform float SmoothstepMin < ui_type = "slider"; ui_label = "Main Contrast Min"; ui_tooltip = "Minimum threshold for contrast adjustment (smoothstep)."; ui_min = SMOOTHSTEP_MIN_MIN; ui_max = SMOOTHSTEP_MIN_MAX; ui_step = SMOOTHSTEP_MIN_STEP; ui_category = "Color Parameters"; > = SMOOTHSTEP_MIN_DEFAULT;
uniform float SmoothstepMax < ui_type = "slider"; ui_label = "Main Contrast Max"; ui_tooltip = "Maximum threshold for contrast adjustment (smoothstep)."; ui_min = SMOOTHSTEP_MAX_MIN; ui_max = SMOOTHSTEP_MAX_MAX; ui_step = SMOOTHSTEP_MAX_STEP; ui_category = "Color Parameters"; > = SMOOTHSTEP_MAX_DEFAULT;
uniform float PowExponentScale < ui_type = "slider"; ui_label = "Crystal Exponent Scale"; ui_tooltip = "Scales the exponent vector derived from crystal(). Affects brightness/color."; ui_min = POW_EXPONENT_SCALE_MIN; ui_max = POW_EXPONENT_SCALE_MAX; ui_step = POW_EXPONENT_SCALE_STEP; ui_category = "Color Parameters"; > = POW_EXPONENT_SCALE_DEFAULT;

// --- Audio Reactivity ---
AS_AUDIO_UI(ShineOn_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(ShineOn_AudioMultiplier, "Audio Intensity", AUDIO_MULTIPLIER_DEFAULT, AUDIO_MULTIPLIER_MAX, "Audio Reactivity")
uniform int ShineOn_AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter"; ui_items = "None\0Animation Speed\0Crystal Size\0Crystal Color Amp\0Crystal Time Factor\0"; ui_tooltip = "Which parameter should respond to audio"; ui_category = "Audio Reactivity"; > = AUDIO_TARGET_DEFAULT;

// --- Final Mix ---
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

// --- Debug ---
AS_DEBUG_UI("Off\0Show Audio Reactivity\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================
float3 MIX(float3 x, float3 y) { return abs(x - y); } 
float2x2 rot2d(float angle) { float c = cos(angle); float s = sin(angle); return float2x2(c, -s, s, c); }
float r(float a, float b) { return frac(sin(dot(float2(a, b), float2(NOISE_DOT_VEC1_X, NOISE_DOT_VEC1_Y))) * NOISE_MAGIC1); }
float h(float n) { return frac(sin(n) * NOISE_MAGIC1); }
float noise(float3 x) { 
    float3 p  = floor(x); float3 f  = frac(x); f = f * f * (3.0f - 2.0f * f); 
    float n = p.x + p.y * NOISE_P_Y_FACTOR + NOISE_P_Z_FACTOR * p.z;
    float v00 = lerp(h(n + 0.0f), h(n + 1.0f), f.x); float v10 = lerp(h(n + 57.0f), h(n + 58.0f), f.x);
    float v01 = lerp(h(n + 113.0f), h(n + 114.0f), f.x); float v11 = lerp(h(n + 170.0f), h(n + 171.0f), f.x); 
    return lerp(lerp(v00, v10, f.y), lerp(v01, v11, f.y), f.z); }
float3 dnoise2f(float2 p) {
    float i = floor(p.x), j = floor(p.y); float u = frac(p.x), v = frac(p.y); 
    float du = 30.0f * u * u * (u * (u - 2.0f) + 1.0f); float dv = 10.0f * v * v * (v * (v - 2.0f) + 1.0f); 
    float u_interp = u*u*u*(u*(u*6.0f - 15.0f)+10.0f); float v_interp = v*v*v*(v*(v*6.0f - 15.0f)+10.0f);
    float a = r(i, j); float b = r(i + 1.0f, j); float c = r(i, j + 1.0f); float d = r(i + 1.0f, j + 1.0f);
    float k0 = a; float k1 = b - a; float k2 = c - a; float k3 = a - b - c + d; 
    float value = k0 + k1 * u_interp + k2 * v_interp + k3 * u_interp * v_interp;
    float dValue_du = du * (k1 + k3 * v_interp); float dValue_dv = dv * (k2 + k3 * u_interp); 
    return float3(value, dValue_du, dValue_dv); }
float fbm(float2 uv, float iTime, const int octaves, const float amplitude_decay, const float frequency_increase) {            
    float2 p = uv; float f = 0.0f, dx = 0.0f, dz = 0.0f, w = 0.5f; 
    [loop] for (int i = 0; i < octaves; ++i) { float3 n = dnoise2f(uv); dx += n.y; dz += n.z;
        f += w * n.x / (1.0f + dx * dx + dz * dz); w *= amplitude_decay; uv *= frequency_increase; 
        float rot_angle = 1.25f * noise(float3(p * 0.1f, 0.12f * iTime)) + 0.75f * noise(float3(p * 0.1f, 0.20f * iTime)); 
        uv = mul(uv, rot2d(rot_angle)); } return f; }
float fbmLow(float2 uv, const int octaves) { 
    float f = 0.0f, dx = 0.0f, dz = 0.0f, w = 0.5f; 
    const float amplitude_decay = 0.75f; const float frequency_increase = 1.5f; 
    [loop] for (int i = 0; i < octaves; ++i) { float3 n = dnoise2f(uv); dx += n.y; dz += n.z;
        f += w * n.x / (1.0f + dx * dx + dz * dz); w *= amplitude_decay; uv *= frequency_increase; } return f; }
float CV(float3 c, float2 uv, float2 iResolution, const float crystal_size_factor, const float crystal_radius) {
    float size = 640.0f / iResolution.x * crystal_size_factor; 
    return 1.0f - saturate(size * (length(c.xy - uv) - crystal_radius)); }
float3 crystal(float2 fc, float iTime, float2 iResolution, 
                 const int crystal_iterations, const float crystal_step, 
                 const float crystal_size_factor, const float crystal_time_factor, 
                 const float crystal_amp, const float crystal_radius, 
                 const float crystal_range_offset) {
    float3 O = 0.0f; float3 c_color;
    float z_time = iTime * crystal_time_factor; 
    int iter_count = 0;
    [loop] for (float i = 0.0f; iter_count < crystal_iterations; i += crystal_step, ++iter_count) { 
        c_color = float3(sin(i * 0.57f +  7.0f + z_time * 0.70f), sin(i * 0.59f - 15.0f - z_time * 0.65f), sin(i * 0.60f + z_time * 0.90f)) * crystal_amp + crystal_amp; 
        float range_x = iResolution.x / 2.0f - crystal_range_offset; float range_y = iResolution.y / 2.0f - crystal_range_offset;
        float center_x = iResolution.x / 2.0f; float center_y = iResolution.y / 2.0f;
        float2 circle_center = float2(sin(z_time * 0.50f + i / 4.5f) * range_x + center_x, sin(z_time * 0.73f + i / 3.0f) * range_y + center_y);
        float cv_mask = CV(float3(circle_center, crystal_radius), fc, iResolution, crystal_size_factor, crystal_radius);
        O = MIX(O, c_color * cv_mask); } return O; }

// ============================================================================
// MAIN PIXEL SHADER
// ============================================================================
float4 ASShineOnPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    // Get original color and check depth
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth) {
        return originalColor;
    }

    // Apply audio reactivity to parameters
    float audioReactivity = AS_applyAudioReactivity(1.0, ShineOn_AudioSource, ShineOn_AudioMultiplier, true);
    
    float currentAnimSpeed = AnimSpeed;
    float currentCrystalSizeFactor = CrystalSizeFactor;
    float currentCrystalAmp = CrystalAmp;
    float currentCrystalTimeFactor = CrystalTimeFactor;
    
    // Apply audio reactivity to selected parameter
    if (ShineOn_AudioTarget == 1) {
        currentAnimSpeed *= audioReactivity;
    } else if (ShineOn_AudioTarget == 2) {
        currentCrystalSizeFactor *= audioReactivity;
    } else if (ShineOn_AudioTarget == 3) {
        currentCrystalAmp *= audioReactivity;
    } else if (ShineOn_AudioTarget == 4) {
        currentCrystalTimeFactor *= audioReactivity;
    }

    // Setup time with keyframe handling
    float iTime;
    if (currentAnimSpeed <= 0.0001f) {
        // When animation speed is effectively zero, use keyframe directly
        iTime = AnimationKeyframe;
    } else {
        // Otherwise use animated time plus keyframe offset
        iTime = (AS_getTime() * currentAnimSpeed) + AnimationKeyframe;
    }
    
    float2 iResolution = ReShade::ScreenSize;
    float2 fragCoord = vpos.xy;

    // Coordinate setup with aspect ratio correction
    float2 uv = float2(texcoord.x * 2.0f - 1.0f, (1.0f - texcoord.y) * 2.0f - 1.0f);
    float aspect = iResolution.x / iResolution.y;
    uv.y /= aspect;

    // Apply global rotation
    float rotationRadians = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
    float s = sin(rotationRadians);
    float c = cos(rotationRadians);
    float2 rotatedUV = float2(
        uv.x * c - uv.y * s,
        uv.x * s + uv.y * c
    );
    uv = rotatedUV;
    
    // Apply Zoom
    uv *= Zoom; 

    float t = iTime * MainTimeScale; 
    
    // rv calculation (uses zoomed uv)
    float denom_s = length(uv * MainUVScale1);
    float2 denom_v = uv * MainUVScale2;
    denom_s = max(denom_s, AS_EPSILON);
    denom_v.x = sign(denom_v.x) * max(abs(denom_v.x), AS_EPSILON);
    denom_v.y = sign(denom_v.y) * max(abs(denom_v.y), AS_EPSILON);
    float2 rv = uv / (denom_s * denom_v); 

    float2 uv_rot1 = mul(uv, rot2d(0.3f * t)); // Uses zoomed uv
    
    float2 fbmLow_arg = float2(length(uv) - t, length(uv) - t) + rv; // Uses zoomed uv
    float fbm_low_val = fbmLow(fbmLow_arg, FbmLowOctaves); 
    
    float val_input_scale = MainUVScale3 * fbm_low_val;
    // Pass zoomed uv (via uv_rot1) and parameters to fbm
    float val = 0.5f * fbm(uv_rot1 * val_input_scale, iTime, FbmOctaves, FbmAmpDecay, FbmFreqInc); 

    float2 uv_rot2 = mul(uv, rot2d(-0.6f * t)); // Uses zoomed uv

    // Pass zoomed uv (via uv_rot2) and parameters to fbm
    float fc_fbm_val = fbm(uv_rot2 * val * MainUVScale4, iTime, FbmOctaves, FbmAmpDecay, FbmFreqInc); 
    // Pass zoomed uv (via uv_rot2) to r()
    float fc = 0.5f * fc_fbm_val + MainRandMix * r(uv_rot2.x, uv_rot2.y); 

    // Color transformations
    float3 fragC = ColorScale1 * float3(fc, fc, fc); 
    fragC *= ColorScale2;
    fragC = fragC / (1.0f + fragC); 
    fragC = smoothstep(SmoothstepMin, SmoothstepMax, fragC); 

    // Apply crystal pow modifier (crystal uses un-zoomed fragCoord)
    float3 crystal_mod = crystal(fragCoord, iTime, iResolution, 
                                  CrystalIterations, CrystalStep, currentCrystalSizeFactor, 
                                  currentCrystalTimeFactor, 
                                  currentCrystalAmp, CrystalRadius, CrystalRangeOffset); 
    
    float3 crystal_exponent = max(crystal_mod * PowExponentScale, AS_EPSILON); 
    fragC = pow(fragC, crystal_exponent); 
    
    // Final output with blend
    float4 effectColor = float4(saturate(fragC), 1.0f);
    float4 finalColor = float4(AS_applyBlend(effectColor.rgb, originalColor.rgb, BlendMode), 1.0f);
    finalColor = lerp(originalColor, finalColor, BlendStrength);
    
    // Debug overlay if enabled
    if (DebugMode != AS_DEBUG_OFF) {
        float4 debugMask = float4(0, 0, 0, 0);
        
        // Audio reactivity visualization
        if (DebugMode == 1) {
            debugMask = float4(audioReactivity, audioReactivity, audioReactivity, 1.0);
        }
        
        // Create a debug overlay region in the top-left
        float2 debugCenter = float2(0.1, 0.1);
        float debugRadius = 0.08;
        float dist = length(texcoord - debugCenter);
        
        if (dist < debugRadius) {
            return debugMask;
        }
    }
    
    return finalColor;
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_ShineOn < ui_label = "[AS] BGX: Shine On"; ui_tooltip = "Dynamic fractal noise glow effect with crystal highlights"; >
{
    pass
    {
        VertexShader = PostProcessVS; 
        PixelShader = ASShineOn::ASShineOnPS;
    }
}

} // namespace ASShineOn

#endif // __AS_BGX_ShineOn_1_fx

