/**
 * AS_LFX_StageSpotlights.1.fx - Directional Stage Lighting Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader simulates a vibrant rock concert stage lighting system with directional
 * spotlights, glow effects, and audio reactivity. Perfect for creating dramatic
 * lighting for screenshots and videos.
 *
 * FEATURES:
 * - Up to 4 independently controllable spotlights with customizable properties
 * - Audio-reactive light intensity, automated sway, and pulsing via Listeningway
 * - Adjustable position, size, color, angle, and direction for each spotlight
 * - Beautiful bokeh glow effects that inherit spotlight colors
 * - Depth-based masking for scene integration
 * - Multiple blend modes for different lighting scenarios
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. The shader creates cone-shaped directional light beams from defined source points
 * 2. Each spotlight's intensity and movement can be modulated by audio input
 * 3. Atmospheric bokeh effects are scattered across the scene based on spotlight colors
 * 4. All elements are composited with depth-aware blending for natural scene integration
 * 
 * ===================================================================================
 */

#ifndef __AS_LFX_StageSpotlights_1_fx
#define __AS_LFX_StageSpotlights_1_fx

#include "AS_Utils.1.fxh"

// ============================================================================
// HELPER MACROS & CONSTANTS
// ============================================================================

// --- Tunable Constants ---
static const int SPOTLIGHT_COUNT = 4;
static const float SPOT_RADIUS_MIN = 0.05;
static const float SPOT_RADIUS_MAX = 1.5;
static const float SPOT_RADIUS_DEFAULT = 0.5;
static const float SPOT_INTENSITY_MIN = 0.0;
static const float SPOT_INTENSITY_MAX = 2.0;
static const float SPOT_INTENSITY_DEFAULT = 0.5;
static const float SPOT_ANGLE_MIN = 10.0;
static const float SPOT_ANGLE_MAX = 160.0;
static const float SPOT_ANGLE_DEFAULT = 35.0;
static const float SPOT_DIRECTION_MIN = -190.0;
static const float SPOT_DIRECTION_MAX = 180.0;
static const float SPOT_DIRECTION_DEFAULT = 0.0;
static const float SPOT_AUDIOMULT_MIN = 0.5;
static const float SPOT_AUDIOMULT_MAX = 5.0;
static const float SPOT_AUDIOMULT_DEFAULT = 1.00;
static const float SPOT_SWAYSPEED_MIN = 0.0;
static const float SPOT_SWAYSPEED_MAX = 5.0;
static const float SPOT_SWAYSPEED_DEFAULT = 0.5;
static const float SPOT_SWAYANGLE_MIN = 0.0;
static const float SPOT_SWAYANGLE_MAX = 180.0;
static const float SPOT_SWAYANGLE_DEFAULT = 15.0;

static const float BOKEH_DENSITY_MIN = 0.0;
static const float BOKEH_DENSITY_MAX = 1.0;
static const float BOKEH_DENSITY_DEFAULT = 0.25;
static const float BOKEH_SIZE_MIN = 0.01;
static const float BOKEH_SIZE_MAX = 0.2;
static const float BOKEH_SIZE_DEFAULT = 0.08;
static const float BOKEH_STRENGTH_MIN = 0.0;
static const float BOKEH_STRENGTH_MAX = 2.0;
static const float BOKEH_STRENGTH_DEFAULT = 0.7;

// ============================================================================
// SPOTLIGHT UI MACRO
// ============================================================================

// Define a macro for the UI controls of each spotlight to avoid repetition
#define SPOTLIGHT_UI(index, defaultEnable, defaultColor, defaultPosition, \
                    defaultRadius, defaultIntensity, defaultAngle, defaultDirection, \
                    defaultSwaySpeed, defaultSwayAngle, defaultAudioSource, defaultAudioMult) \
uniform bool Spot##index##_Enable < ui_label = "Enable Spotlight " #index; ui_tooltip = "Toggle this spotlight on or off."; ui_category = "Light Beam " #index; ui_category_closed = index > 2; > = defaultEnable; \
uniform float3 Spot##index##_Color < ui_type = "color"; ui_label = "Color"; ui_category = "Light Beam " #index; > = defaultColor; \
uniform float2 Spot##index##_Position < ui_type = "drag"; ui_label = "Position"; ui_min = -0.2; ui_max = 1.2; ui_category = "Light Beam " #index; > = defaultPosition; \
uniform float Spot##index##_Radius < ui_type = "slider"; ui_label = "Size"; ui_min = SPOT_RADIUS_MIN; ui_max = SPOT_RADIUS_MAX; ui_category = "Light Beam " #index; > = defaultRadius; \
uniform float Spot##index##_Intensity < ui_type = "slider"; ui_label = "Intensity"; ui_min = SPOT_INTENSITY_MIN; ui_max = SPOT_INTENSITY_MAX; ui_category = "Light Beam " #index; > = defaultIntensity; \
uniform float Spot##index##_Angle < ui_type = "slider"; ui_label = "Opening"; ui_min = SPOT_ANGLE_MIN; ui_max = SPOT_ANGLE_MAX; ui_category = "Light Beam " #index; > = defaultAngle; \
uniform float Spot##index##_Direction < ui_type = "slider"; ui_label = "Direction"; ui_min = SPOT_DIRECTION_MIN; ui_max = SPOT_DIRECTION_MAX; ui_category = "Light Beam " #index; > = defaultDirection; \
uniform float Spot##index##_SwaySpeed < ui_type = "slider"; ui_label = "Speed"; ui_min = SPOT_SWAYSPEED_MIN; ui_max = SPOT_SWAYSPEED_MAX; ui_category = "Light Beam " #index; > = defaultSwaySpeed; \
uniform float Spot##index##_SwayAngle < ui_type = "slider"; ui_label = "Sway"; ui_min = SPOT_SWAYANGLE_MIN; ui_max = SPOT_SWAYANGLE_MAX; ui_category = "Light Beam " #index; > = defaultSwayAngle; \
uniform int Spot##index##_AudioSource < ui_type = "combo"; ui_label = "Source"; ui_items = "Volume\0Beat\0Bass\0Mid\0Treble\0"; ui_category = "Light Beam " #index; > = defaultAudioSource; \
uniform float Spot##index##_AudioMult < ui_type = "slider"; ui_label = "Source Intensity"; ui_tooltip = "Multiplier for the spotlight intensity"; ui_min = SPOT_AUDIOMULT_MIN; ui_max = SPOT_AUDIOMULT_MAX; ui_category = "Light Beam " #index; > = defaultAudioMult;

// ============================================================================
// SPOTLIGHT CONTROLS (Using the macro)
// ============================================================================

// Spotlight A controls
SPOTLIGHT_UI(1, true, float3(0.3, 0.6, 1.0), float2(0.2, 0.17), 
            SPOT_RADIUS_DEFAULT, SPOT_INTENSITY_DEFAULT, SPOT_ANGLE_DEFAULT, 30.0,
            SPOT_SWAYSPEED_DEFAULT, SPOT_SWAYANGLE_DEFAULT, 1, SPOT_AUDIOMULT_DEFAULT)

// Spotlight B controls
SPOTLIGHT_UI(2, false, float3(1.0, 0.5, 0.2), float2(0.7, 0.35), 
            SPOT_RADIUS_DEFAULT, SPOT_INTENSITY_DEFAULT, SPOT_ANGLE_DEFAULT, SPOT_DIRECTION_DEFAULT,
            SPOT_SWAYSPEED_DEFAULT, SPOT_SWAYANGLE_DEFAULT, 1, SPOT_AUDIOMULT_DEFAULT)

// Spotlight C controls
SPOTLIGHT_UI(3, false, float3(0.8, 0.3, 1.0), float2(0.5, 0.22), 
            SPOT_RADIUS_DEFAULT, SPOT_INTENSITY_DEFAULT, SPOT_ANGLE_DEFAULT, SPOT_DIRECTION_DEFAULT,
            SPOT_SWAYSPEED_DEFAULT, SPOT_SWAYANGLE_DEFAULT, 1, SPOT_AUDIOMULT_DEFAULT)

// Spotlight D controls
SPOTLIGHT_UI(4, false, float3(0.2, 1.0, 0.5), float2(0.5, 0.5), 
            SPOT_RADIUS_DEFAULT, SPOT_INTENSITY_DEFAULT, SPOT_ANGLE_DEFAULT, SPOT_DIRECTION_DEFAULT,
            SPOT_SWAYSPEED_DEFAULT, SPOT_SWAYANGLE_DEFAULT, 1, SPOT_AUDIOMULT_DEFAULT)

// --- Bokeh Settings ---
uniform float BokehDensity < ui_type = "slider"; ui_label = "Density"; ui_min = BOKEH_DENSITY_MIN; ui_max = BOKEH_DENSITY_MAX; ui_category = "Stage Effects"; > = BOKEH_DENSITY_DEFAULT;
uniform float BokehSize < ui_type = "slider"; ui_label = "Size"; ui_min = BOKEH_SIZE_MIN; ui_max = BOKEH_SIZE_MAX; ui_category = "Stage Effects"; > = BOKEH_SIZE_DEFAULT;
uniform float BokehStrength < ui_type = "slider"; ui_label = "Strength"; ui_min = BOKEH_STRENGTH_MIN; ui_max = BOKEH_STRENGTH_MAX; ui_category = "Stage Effects"; > = BOKEH_STRENGTH_DEFAULT;

// --- Stage Depth Control ---
// Standardized stage depth control
AS_STAGEDEPTH_UI(StageDepth, "Distance", "Stage Distance")

// --- Blend Settings ---
// Using the new macro with Additive (3) as the default blend mode
AS_BLENDMODE_UI_DEFAULT(BlendMode, "Final Mix", 3)
AS_BLENDAMOUNT_UI(BlendAmount, "Final Mix")

// --- Debug Settings ---
AS_DEBUG_MODE_UI("Off\0Spotlights\0Bokeh\0")

// ============================================================================
// HELPER FUNCTIONS & STRUCTURES
// ============================================================================

// Structure to hold spotlight parameters for easier handling
struct SpotlightParams {
    bool enable;
    float3 color;
    float2 position;
    float radius;
    float intensity;
    float angle;
    float direction;
    float swaySpeed;
    float swayAngle;
    int audioSource;
    float audioMult;
};

// Helper function to get spotlight parameters for a given index
SpotlightParams GetSpotlightParams(int spotIndex) {
    SpotlightParams params;
    
    if (spotIndex == 0) {
        params.enable = Spot1_Enable;
        params.color = Spot1_Color;
        params.position = Spot1_Position;
        params.radius = Spot1_Radius;
        params.intensity = Spot1_Intensity;
        params.angle = Spot1_Angle;
        params.direction = Spot1_Direction;
        params.swaySpeed = Spot1_SwaySpeed;
        params.swayAngle = Spot1_SwayAngle;
        params.audioSource = Spot1_AudioSource;
        params.audioMult = Spot1_AudioMult;
    }
    else if (spotIndex == 1) {
        params.enable = Spot2_Enable;
        params.color = Spot2_Color;
        params.position = Spot2_Position;
        params.radius = Spot2_Radius;
        params.intensity = Spot2_Intensity;
        params.angle = Spot2_Angle;
        params.direction = Spot2_Direction;
        params.swaySpeed = Spot2_SwaySpeed;
        params.swayAngle = Spot2_SwayAngle;
        params.audioSource = Spot2_AudioSource;
        params.audioMult = Spot2_AudioMult;
    }
    else if (spotIndex == 2) {
        params.enable = Spot3_Enable;
        params.color = Spot3_Color;
        params.position = Spot3_Position;
        params.radius = Spot3_Radius;
        params.intensity = Spot3_Intensity;
        params.angle = Spot3_Angle;
        params.direction = Spot3_Direction;
        params.swaySpeed = Spot3_SwaySpeed;
        params.swayAngle = Spot3_SwayAngle;
        params.audioSource = Spot3_AudioSource;
        params.audioMult = Spot3_AudioMult;
    }
    else { // spotIndex == 3
        params.enable = Spot4_Enable;
        params.color = Spot4_Color;
        params.position = Spot4_Position;
        params.radius = Spot4_Radius;
        params.intensity = Spot4_Intensity;
        params.angle = Spot4_Angle;
        params.direction = Spot4_Direction;
        params.swaySpeed = Spot4_SwaySpeed;
        params.swayAngle = Spot4_SwayAngle;
        params.audioSource = Spot4_AudioSource;
        params.audioMult = Spot4_AudioMult;
    }
    
    return params;
}

// Process a single spotlight
float3 ProcessSpotlight(float2 uv, SpotlightParams params, out float maskValue) {
    // Skip processing if spotlight is disabled
    maskValue = 0.0;
    if (!params.enable) return float3(0, 0, 0);
    
    float coneLength = 0.7;
    float coneSoft = 0.18;
    float time = AS_getTime();
    
    // Use only standard non-audio-reactive sway
    float sway = 0.0;
    if (params.swaySpeed > 0.0 && params.swayAngle > 0.0) {
        sway = AS_applySway(params.swayAngle, params.swaySpeed);
    }
    
    float dirAngle = AS_radians(params.direction) + sway;
    
    // Map the UI audio source value to the correct AS_AUDIO constants
    int mappedAudioSource;
    switch(params.audioSource) {
        case 0: mappedAudioSource = AS_AUDIO_VOLUME; break; // Volume
        case 1: mappedAudioSource = AS_AUDIO_BEAT; break;   // Beat
        case 2: mappedAudioSource = AS_AUDIO_BASS; break;   // Bass
        case 3: mappedAudioSource = AS_AUDIO_MID; break;    // Mid
        case 4: mappedAudioSource = AS_AUDIO_TREBLE; break; // Treble
        default: mappedAudioSource = AS_AUDIO_SOLID; break; // Fallback to solid
    }
    
    // Get audio value using standardized function with corrected mapping
    float audioVal = AS_getAudioSource(mappedAudioSource);
    
    float2 uv_screen = AS_rescaleToScreen(uv);
    float2 pos_screen = AS_rescaleToScreen(params.position);
    float2 rel = uv_screen - pos_screen;
    float dist = length(rel) / (coneLength * BUFFER_HEIGHT);
    float2 spotDir = float2(sin(dirAngle), cos(dirAngle));
    float dirDot = clamp(dot(normalize(rel), spotDir), -1.0, 1.0);
    float coneCos = cos(AS_radians(clamp(params.angle, 10.0, 160.0)) * 0.5);
    float angleMask = (dirDot >= coneCos && dist <= 1.0) ? smoothstep(coneCos, 1.0, dirDot) : 0.0;
    float edge = smoothstep(params.radius, params.radius + coneSoft, dist);
    
    // Apply Source Intensity correctly
    // New formula: (User-selected baseline Intensity) + (Source * Source Intensity)
    float sourceIntensity = params.audioMult * audioVal;
    float intensity = params.intensity + sourceIntensity;
    
    float val = (1.0 - edge) * angleMask * intensity * (1.0 - dist);
    maskValue = val;
    
    // Return the spotlight color contribution
    return params.color * val;
}

// ============================================================================
// MAIN SHADER FUNCTIONS
// ============================================================================

float3 renderSpotlights(float2 uv, float audioPulse, out float3 spotSum, out float3 spotMask) {
    float3 color = 0;
    float3 mask = 0;
    float3 sum = 0;
    
    // Process each spotlight using the parameter structure
    for (int i = 0; i < SPOTLIGHT_COUNT; i++) {
        SpotlightParams params = GetSpotlightParams(i);
        float maskValue;
        
        // Process this spotlight
        float3 spotColor = ProcessSpotlight(uv, params, maskValue);
        
        // Accumulate results
        color += spotColor;
        mask += maskValue;
        
        // For bokeh, we want a sum of colors even without considering intensity
        float edge = 0.0;
        if (params.enable) {
            float2 uv_screen = AS_rescaleToScreen(uv);
            float2 pos_screen = AS_rescaleToScreen(params.position);
            float2 rel = uv_screen - pos_screen;
            float dist = length(rel) / (0.7 * BUFFER_HEIGHT);
            edge = smoothstep(params.radius, params.radius + 0.18, dist);
            
            float dirAngle = AS_radians(params.direction);
            if (params.swaySpeed > 0.0 && params.swayAngle > 0.0) {
                dirAngle += AS_applySway(params.swayAngle, params.swaySpeed);
            }
            
            float2 spotDir = float2(sin(dirAngle), cos(dirAngle));
            float dirDot = clamp(dot(normalize(rel), spotDir), -1.0, 1.0);
            float coneCos = cos(AS_radians(clamp(params.angle, 10.0, 160.0)) * 0.5);
            float angleMask = (dirDot >= coneCos && dist <= 1.0) ? smoothstep(coneCos, 1.0, dirDot) : 0.0;
            
            sum += params.color * (1.0 - edge) * angleMask;
        }
    }
    
    spotSum = sum;
    spotMask = mask;
    return color;
}

float3 renderBokeh(float2 uv, float3 spotSum) {
    float3 bokeh = 0;
    float2 uv_screen = AS_rescaleToScreen(uv);
    float2 seed = uv_screen * 0.1 + frameCount * 0.01;
    for (int i = 0; i < 8; ++i) {
        float2 rnd = AS_hash21(seed + i * 12.9898);
        float2 pos = rnd * float2(BUFFER_WIDTH, BUFFER_HEIGHT);
        float size = BokehSize * (0.7 + rnd.x * 0.6) * BUFFER_HEIGHT;
        float fade = exp(-dot(uv_screen - pos, uv_screen - pos) / (size * size));
        bokeh += spotSum * fade * BokehStrength * BokehDensity;
    }
    return bokeh;
}

float4 PS_Spotlights(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Get original image first
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    
    // Get scene depth
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    
    // Skip effect if pixel is closer than stage depth
    if (sceneDepth < StageDepth - 0.0005)
        return orig;
    
    // Calculate spotlight and bokeh effects
    float2 uv = texcoord;
    float3 spotSum, spotMask;
    float3 spotlights = renderSpotlights(uv, 0.0, spotSum, spotMask); // Using 0.0 as we don't need global audio pulse
    float3 bokeh = renderBokeh(uv, spotSum);
    
    // Handle debug modes
    if (DebugMode == 1) return float4(spotlights, 1.0);
    if (DebugMode == 2) return float4(bokeh, 1.0);
    
    // Combine lighting effects
    float3 fx = spotlights + bokeh;
    fx = saturate(fx);
    
    // Apply appropriate blend mode
    // For lighting effects, Screen or Additive blend mode works best
    float3 blended = AS_blendResult(orig.rgb, fx, BlendMode);
    float3 result = lerp(orig.rgb, blended, BlendAmount);
    
    return float4(result, orig.a);
}

technique AS_StageSpotlights < ui_label = "[AS] LFX: Stage Spotlights"; ui_tooltip = "Configurable stage spotlights with audio reactivity."; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_Spotlights;
    }
}

#endif // __AS_LFX_StageSpotlights_1_fx
