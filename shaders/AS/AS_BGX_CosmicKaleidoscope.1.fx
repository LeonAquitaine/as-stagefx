/**
 * AS_BGX_CosmicKaleidoscope.1.fx - Volumetric Mandelbox/Mandelbulb-like fractal
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Based on "cosmos in crystal" by nayk
 * Shadertoy: https://www.shadertoy.com/view/MXccR4
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Renders a raymarched volumetric fractal resembling a Mandelbox or Mandelbulb.
 * Includes fixes for accurate tiling (mod) and missing rotation from original source.
 *
 * FEATURES:
 * - Raymarched volumetric fractal with adjustable parameters
 * - Kaleidoscope-like mirroring effect with customizable repetitions
 * - Audio reactivity for dynamic parameter adjustments
 * - Palette-based coloring system with customizable options
 * - Full rotation, position and depth control for scene integration
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Performs volumetric raymarching to explore 3D fractal space
 * 2. Applies iterated math operations to create fractal patterns
 * 3. Implements domain repetition for tiling and kaleidoscope effects
 * 4. Accumulates color based on distance and iteration properties
 * 5. Applies rotation, audio reactivity and palette mapping
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_CosmicKaleidoscope_1_fx
#define __AS_BGX_CosmicKaleidoscope_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

namespace ASCosmicKaleidoscope {
// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges from #defines)
// ============================================================================
// --- Fractal & Raymarching ---
static const int ITERATIONS_MIN = 1; static const int ITERATIONS_MAX = 30; static const int ITERATIONS_DEFAULT = 13;
static const float FORMUPARAM_MIN = 0.1; static const float FORMUPARAM_MAX = 1.5; static const float FORMUPARAM_STEP = 0.01; static const float FORMUPARAM_DEFAULT = 0.53;
static const int VOLSTEPS_MIN = 5; static const int VOLSTEPS_MAX = 80; static const int VOLSTEPS_DEFAULT = 20;
static const float STEPSIZE_MIN = 0.01; static const float STEPSIZE_MAX = 0.5; static const float STEPSIZE_STEP = 0.01; static const float STEPSIZE_DEFAULT = 0.1;
static const float ZOOM_MIN = 0.1; static const float ZOOM_MAX = 3.0; static const float ZOOM_STEP = 0.01; static const float ZOOM_DEFAULT = 0.800;
static const float TILE_MIN = 0.1; static const float TILE_MAX = 3.0; static const float TILE_STEP = 0.05; static const float TILE_DEFAULT = 0.850;
static const int MIRROR_COUNT_MIN = 1; static const int MIRROR_COUNT_MAX = 4; static const int MIRROR_COUNT_DEFAULT = 1; // Controls kaleidoscope: 0=none, 1=2 copies, 2=4 copies, etc.
static const float BRIGHTNESS_MIN = 0.0001; static const float BRIGHTNESS_MAX = 0.01; static const float BRIGHTNESS_STEP = 0.0001; static const float BRIGHTNESS_DEFAULT = 0.0015;
static const float DARKMATTER_MIN = 0.0; static const float DARKMATTER_MAX = 1.0; static const float DARKMATTER_STEP = 0.01; static const float DARKMATTER_DEFAULT = 0.300;
static const float DISTFADING_MIN = 0.5; static const float DISTFADING_MAX = 1.0; static const float DISTFADING_STEP = 0.01; static const float DISTFADING_DEFAULT = 0.730;
static const float SATURATION_MIN = 0.0; static const float SATURATION_MAX = 2.0; static const float SATURATION_STEP = 0.05; static const float SATURATION_DEFAULT = 0.850;
// --- Animation ---
static const float ANIMATION_SPEED_MIN = 0.0; static const float ANIMATION_SPEED_MAX = 5.0; static const float ANIMATION_SPEED_STEP = 0.01; static const float ANIMATION_SPEED_DEFAULT = 1.0;
static const float ANIMATION_KEYFRAME_MIN = 0.0; static const float ANIMATION_KEYFRAME_MAX = 100.0; static const float ANIMATION_KEYFRAME_STEP = 0.1; static const float ANIMATION_KEYFRAME_DEFAULT = 0.0;
static const float CAMERA_MOVE_SPEED_MIN = 0.0; static const float CAMERA_MOVE_SPEED_MAX = 0.5; static const float CAMERA_MOVE_SPEED_STEP = 0.001; static const float CAMERA_MOVE_SPEED_DEFAULT = 0.01; 
static const float FRACTAL_ROTATION_SPEED_MIN = 0.0; static const float FRACTAL_ROTATION_SPEED_MAX = 0.1; static const float FRACTAL_ROTATION_SPEED_STEP = 0.001; static const float FRACTAL_ROTATION_SPEED_DEFAULT = 0.01; 
// Audio 
static const int AUDIO_TARGET_DEFAULT = 2; static const float AUDIO_MULTIPLIER_DEFAULT = 1.0; static const float AUDIO_MULTIPLIER_MAX = 2.0;
// Palette & Style
static const float COLOR_INTENSITY_DEFAULT = 1.0; static const float COLOR_INTENSITY_MAX = 3.0; static const float COLOR_CYCLE_SPEED_DEFAULT = 0.1; static const float COLOR_CYCLE_SPEED_MAX = 2.0;
// --- Internal Constants ---
static const float EPSILON = 1e-5f; static const float HALF_POINT = 0.5f; // Removed PI and TWOPI, use AS_PI and AS_TWO_PI from AS_Utils

// --- UI Uniform Definitions ---

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nBased on 'Star Nest' by Kali\nLink: https://www.shadertoy.com/view/XlfGRj\nLicence: CC Share-Alike Non-Commercial\n\n";>;

uniform int UI_Iterations < ui_type = "slider"; ui_label = "Fractal Iterations"; ui_min = ITERATIONS_MIN; ui_max = ITERATIONS_MAX; ui_category = "Fractal Parameters"; > = ITERATIONS_DEFAULT;
uniform float UI_Formuparam < ui_type = "slider"; ui_label = "Fractal Parameter"; ui_min = FORMUPARAM_MIN; ui_max = FORMUPARAM_MAX; ui_step = FORMUPARAM_STEP; ui_category = "Fractal Parameters"; > = FORMUPARAM_DEFAULT;
uniform float UI_Tile < ui_type = "slider"; ui_label = "Tiling / Domain Repetition"; ui_min = TILE_MIN; ui_max = TILE_MAX; ui_step = TILE_STEP; ui_category = "Fractal Parameters"; > = TILE_DEFAULT;
uniform int UI_MirrorCount < ui_type = "slider"; ui_label = "Mirror Count"; ui_tooltip = "Controls the kaleidoscope effect: 0=none, 1=2 copies, 2=4 copies, 3=8 copies, etc."; ui_min = MIRROR_COUNT_MIN; ui_max = MIRROR_COUNT_MAX; ui_category = "Fractal Parameters"; > = MIRROR_COUNT_DEFAULT;
uniform int UI_Volsteps < ui_type = "slider"; ui_label = "Volume Steps (Quality)"; ui_min = VOLSTEPS_MIN; ui_max = VOLSTEPS_MAX; ui_category = "Raymarching"; > = VOLSTEPS_DEFAULT;
uniform float UI_Stepsize < ui_type = "slider"; ui_label = "Step Size"; ui_min = STEPSIZE_MIN; ui_max = STEPSIZE_MAX; ui_step = STEPSIZE_STEP; ui_category = "Raymarching"; > = STEPSIZE_DEFAULT;
uniform float UI_Zoom < ui_type = "slider"; ui_label = "Camera Zoom"; ui_min = ZOOM_MIN; ui_max = ZOOM_MAX; ui_step = ZOOM_STEP; ui_category = "Raymarching"; > = ZOOM_DEFAULT;
uniform float UI_Distfading < ui_type = "slider"; ui_label = "Distance Fading"; ui_min = DISTFADING_MIN; ui_max = DISTFADING_MAX; ui_step = DISTFADING_STEP; ui_category = "Raymarching"; > = DISTFADING_DEFAULT;
uniform float UI_Brightness < ui_type = "slider"; ui_label = "Brightness"; ui_min = BRIGHTNESS_MIN; ui_max = BRIGHTNESS_MAX; ui_step = BRIGHTNESS_STEP; ui_format = "%.4f"; ui_category = "Coloring & Appearance"; > = BRIGHTNESS_DEFAULT;
uniform float UI_Darkmatter < ui_type = "slider"; ui_label = "Dark Matter / Absorption"; ui_min = DARKMATTER_MIN; ui_max = DARKMATTER_MAX; ui_step = DARKMATTER_STEP; ui_category = "Coloring & Appearance"; > = DARKMATTER_DEFAULT;
uniform float UI_Saturation < ui_type = "slider"; ui_label = "Color Saturation"; ui_min = SATURATION_MIN; ui_max = SATURATION_MAX; ui_step = SATURATION_STEP; ui_category = "Coloring & Appearance"; > = SATURATION_DEFAULT;
uniform bool UsePaletteColor < ui_label = "Use Palette Color Mapping"; ui_tooltip = "Overrides default coloring with palette lookup based on accumulated color length."; ui_category = "Coloring & Appearance"; > = false;
AS_PALETTE_SELECTION_UI(PalettePreset, "Color Palette", AS_PALETTE_NEON, "Coloring & Appearance")
AS_DECLARE_CUSTOM_PALETTE(CosmosCrystal_, "Coloring & Appearance") 
uniform float ColorCycleSpeed < ui_type = "slider"; ui_label = "Palette Color Cycle Speed"; ui_min = -COLOR_CYCLE_SPEED_MAX; ui_max = COLOR_CYCLE_SPEED_MAX; ui_step = 0.1; ui_category = "Coloring & Appearance"; > = COLOR_CYCLE_SPEED_DEFAULT;
uniform float ColorIntensity < ui_type = "slider"; ui_label = "Palette Color Intensity"; ui_min = 0.1; ui_max = COLOR_INTENSITY_MAX; ui_step = 0.01; ui_category = "Coloring & Appearance"; > = COLOR_INTENSITY_DEFAULT;
uniform float AnimationKeyframe < ui_type = "slider"; ui_label = "Animation Keyframe"; ui_tooltip = "Sets a specific point in time for the animation. Useful for finding and saving specific patterns."; ui_min = ANIMATION_KEYFRAME_MIN; ui_max = ANIMATION_KEYFRAME_MAX; ui_step = ANIMATION_KEYFRAME_STEP; ui_category = "Animation"; > = ANIMATION_KEYFRAME_DEFAULT;
uniform float AnimationSpeed < ui_type = "slider"; ui_label = "Time Speed (Evolution)"; ui_min = ANIMATION_SPEED_MIN; ui_max = ANIMATION_SPEED_MAX; ui_step = ANIMATION_SPEED_STEP; ui_category = "Animation"; > = ANIMATION_SPEED_DEFAULT;
uniform float CameraMoveSpeed < ui_type = "slider"; ui_label = "Camera Movement Speed"; ui_min = CAMERA_MOVE_SPEED_MIN; ui_max = CAMERA_MOVE_SPEED_MAX; ui_step = CAMERA_MOVE_SPEED_STEP; ui_category = "Animation"; > = CAMERA_MOVE_SPEED_DEFAULT;
uniform float FractalRotationSpeed < ui_type = "slider"; ui_label = "Fractal XY Rotation Speed"; ui_tooltip = "Speed of the internal XY rotation applied during raymarching."; ui_min = FRACTAL_ROTATION_SPEED_MIN; ui_max = FRACTAL_ROTATION_SPEED_MAX; ui_step = FRACTAL_ROTATION_SPEED_STEP; ui_category = "Animation"; > = FRACTAL_ROTATION_SPEED_DEFAULT; 
AS_AUDIO_UI(Cosmos_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity") 
AS_AUDIO_MULT_UI(Cosmos_AudioMultiplier, "Audio Intensity", AUDIO_MULTIPLIER_DEFAULT, AUDIO_MULTIPLIER_MAX, "Audio Reactivity") 
uniform int Cosmos_AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter"; ui_items = "None\0Fractal Parameter\0Brightness\0Dark Matter\0Saturation\0Camera Move Speed\0Fractal Rotation Speed\0"; ui_category = "Audio Reactivity"; > = AUDIO_TARGET_DEFAULT;
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation)
AS_POSITION_SCALE_UI(Position, Scale)
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)
AS_DEBUG_UI("Off\0Show Audio Reactivity\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Standard 2D Rotation Matrix
float2x2 rotMat(in float r) {
    float c = cos(r); float s = sin(r); return float2x2(c, -s, s, c);
}

// Palette lookup helper
float3 getCosmosCrystalColor(float t, float time) { 
    if (ColorCycleSpeed != 0.0) { t = frac(t + ColorCycleSpeed * 0.1 * time); }
    t = saturate(t); 
    if (PalettePreset == AS_PALETTE_CUSTOM) { return AS_GET_INTERPOLATED_CUSTOM_COLOR(CosmosCrystal_, t); }
    return AS_getInterpolatedColor(PalettePreset, t); 
}

// ============================================================================
// PIXEL SHADER CORE LOGIC (Adapted from mainVR)
// ============================================================================
float4 renderCosmosCrystal(float3 ro, float3 rd, float iTime, 
                            const int iterations, const float formuparam, const int volsteps, const float stepsize,
                            const float tile, const float brightness, const float darkmatter, const float distfading, const float saturation,
                            const float fractalrotspeed, // Added rotation speed parameter
                            const float audio_FractalParam, const float audio_Brightness, const float audio_DarkMatter, const float audio_Saturation, const float audio_FractalRot)
{
    float3 dir = normalize(rd); 
    float3 from = ro;

    // Apply audio reactivity directly to parameters used in this function
    float current_formuparam = formuparam * audio_FractalParam;
    float current_brightness = brightness * audio_Brightness;
    float current_darkmatter = darkmatter * audio_DarkMatter;
    float current_saturation = saturation * audio_Saturation;
    float current_fractalrotspeed = fractalrotspeed * audio_FractalRot;

    float s = 0.1f; 
    float fade = 1.0f; 
    float3 v = 0.0f; // Use float3(0,0,0) for clarity

    float tile_x2 = tile * 2.0f;
    float3 tile_vec = float3(tile, tile, tile);
    float3 p; // Declare p outside loop

    for (int r = 0; r < volsteps; ++r) 
    {
        p = from + s * dir; // Nayk's original doesn't seem to have the *0.5 on dir here

        // --- Tiling Fold --- Corrected GLSL mod translation ---
        // Apply mirroring based on UI_MirrorCount
        // Higher mirror count creates more repetitions (kaleidoscope effect)
        if (UI_MirrorCount > 0) {
            // Calculate the correct tiling repetition based on mirror count
            // 0 = no repetition, 1 = 2 copies, 2 = 4 copies, 3 = 8 copies, 4 = 16 copies
            int mirrorPower = 1 << UI_MirrorCount; // 2^MirrorCount
            float mirrorTile = tile / max(1, UI_MirrorCount); // Scale tile size inversely with mirror count
            float mirrorTile_x2 = mirrorTile * 2.0f;
            float3 mirrorTile_vec = float3(mirrorTile, mirrorTile, mirrorTile);
            
            // Same folding logic but with adjusted tile size
            float3 mod_p_2T = p - floor(p / mirrorTile_x2) * mirrorTile_x2;
            p = abs(mirrorTile_vec - mod_p_2T);
        }
        // --- End Tiling Fold ---
       
        // --- Apply Rotation (from Nayk's original, applied once per ray step r) ---
        p.xy = mul(p.xy, rotMat(iTime * current_fractalrotspeed)); 
        // --- End Rotation ---

        float pa = 0.0f; 
        float a = 0.0f; 

        // Using dynamic loop count based on UI_Iterations
        [loop] 
        for (int i = 0; i < iterations; ++i) 
        {
            p = abs(p) / max(dot(p, p), 1e-8f) - current_formuparam; // Safeguard dot product division with small epsilon
            float p_len = length(p);
            a += abs(p_len - pa); 
            pa = p_len; 
        }

        float dm = max(0.0f, current_darkmatter - a * a * 0.001f); 
        a = a * a * a; 

        if (r > 6) fade *= max(0.0f, 1.3f - dm); // Avoid negative fade multiplier

        v += fade * float3(s, s*s, s*s*s*s) * a * current_brightness; 

        fade *= distfading; 
        s += stepsize;
        if (fade < 0.01f) break; 
    }

    // Apply saturation
    float v_luma = dot(v, float3(0.333f, 0.333f, 0.333f)); // Corrected float3 constructor
    v = lerp(v_luma.xxx, v, current_saturation); // Corrected lerp usage with explicit .xxx swizzle

    return float4(saturate(v * 0.01f), 1.0f); // Apply final scale and clamp
}

// ============================================================================
// Main Pixel Shader
// ============================================================================
float4 ASCosmicKaleidoscopePS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET 
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth) return originalColor;

    // --- Audio Reactivity ---
    float audioReactivity = AS_applyAudioReactivity(1.0, Cosmos_AudioSource, Cosmos_AudioMultiplier, true);
    float audio_Formuparam = 1.0, audio_Brightness = 1.0, audio_DarkMatter = 1.0, audio_Saturation = 1.0, audio_CamMove = 1.0, audio_FractalRot = 1.0;
    if (Cosmos_AudioTarget == 1) audio_Formuparam *= audioReactivity;
    else if (Cosmos_AudioTarget == 2) audio_Brightness *= audioReactivity;
    else if (Cosmos_AudioTarget == 3) audio_DarkMatter *= audioReactivity;
    else if (Cosmos_AudioTarget == 4) audio_Saturation *= audioReactivity;
    else if (Cosmos_AudioTarget == 5) audio_CamMove *= audioReactivity;
    else if (Cosmos_AudioTarget == 6) audio_FractalRot *= audioReactivity; // Added Fractal Rotation Target

    // --- Time and Resolution ---
    // Calculate animation time with keyframe handling
    float iTime;
    if (AnimationSpeed <= 0.0001) {
        // When animation speed is effectively zero, use keyframe directly
        iTime = AnimationKeyframe;
    } else {
        // Otherwise use animated time plus keyframe offset
        iTime = (AS_getTime() * AnimationSpeed) + AnimationKeyframe;
    }
    float2 iResolution = ReShade::ScreenSize;

    // --- Camera Setup ---
    float2 uv = texcoord * 2.0f - 1.0f; 
    uv.x *= iResolution.x / iResolution.y; 

    // Use Position and Scale from the AS_POSITION_SCALE_UI macro
    float3 ro = float3(0.0f, 0.0f, 1.0f); // Base camera position
    ro.z *= Scale; // Apply Z scaling from the Scale uniform
    ro.z += iTime * CameraMoveSpeed * audio_CamMove; // Add time-based movement
    ro.xy -= Position; // FIXED: Invert Position for correct movement direction
    
    float3 rd = normalize(float3(uv * UI_Zoom, 1.0f));
    float rotationRadians = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
    rd.xy = mul(rd.xy, rotMat(rotationRadians)); // Apply screen-space rotation to direction

    // --- Render the effect ---
    float4 effectColor = renderCosmosCrystal(ro, rd, iTime, 
                                            UI_Iterations, UI_Formuparam, UI_Volsteps, UI_Stepsize,
                                            UI_Tile, UI_Brightness, UI_Darkmatter, UI_Distfading, UI_Saturation,
                                            FractalRotationSpeed, // Pass rotation speed
                                            audio_Formuparam, audio_Brightness, audio_DarkMatter, audio_Saturation, audio_FractalRot); // Pass audio factors

    // --- Optional Palette Mapping ---
    float3 finalRGB = effectColor.rgb;
    if (UsePaletteColor) {
        float intensity = saturate(length(finalRGB) / sqrt(3.0f)); 
        float3 paletteColor = getCosmosCrystalColor(intensity, iTime);
        finalRGB = paletteColor * ColorIntensity; 
    } 
    
    effectColor.rgb = saturate(finalRGB); 

    // --- Final Blending & Debug ---
    float4 finalColor = float4(AS_applyBlend(effectColor.rgb, originalColor.rgb, BlendMode), 1.0f);
    finalColor = lerp(originalColor, finalColor, BlendStrength);
    
    if (DebugMode != AS_DEBUG_OFF) {
        float4 debugMask = float4(0, 0, 0, 0);
        if (DebugMode == 1) { 
             debugMask = float4(audioReactivity, audioReactivity, audioReactivity, 1.0);
        }
        float2 debugCenter = float2(0.1f, 0.1f); 
        float debugRadius = 0.08f;
        if (length(texcoord - debugCenter) < debugRadius) return debugMask;
    }
    
    return finalColor;
}

} // namespace ASCosmicKaleidoscope

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_CosmicKaleidoscope < ui_label="[AS] BGX: Cosmic Kaleidoscope"; ui_tooltip="Volumetric fractal raymarcher with adjustable kaleidoscope effect by nayk, ported by Leon Aquitaine.";>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = ASCosmicKaleidoscope::ASCosmicKaleidoscopePS;
    }
}

#endif // __AS_BGX_CosmicKaleidoscope_1_fx
