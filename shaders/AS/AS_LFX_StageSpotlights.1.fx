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
 * - Up to 3 independently controllable spotlights with customizable properties
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



#include "AS_Utils.1.fxh"

// --- Tunable Constants ---
static const int NUMSPOTS_MIN = 1;
static const int NUMSPOTS_MAX = 3;
static const int NUMSPOTS_DEFAULT = 3;
static const float SPOT_RADIUS_MIN = 0.05;
static const float SPOT_RADIUS_MAX = 1.5;
static const float SPOT_RADIUS_DEFAULT = 0.18;
static const float SPOT_INTENSITY_MIN = 0.0;
static const float SPOT_INTENSITY_MAX = 2.0;
static const float SPOT_INTENSITY_DEFAULT = 1.0;
static const float SPOT_ANGLE_MIN = 10.0;
static const float SPOT_ANGLE_MAX = 160.0;
static const float SPOT_ANGLE_DEFAULT = 90.0;
static const float SPOT_DIRECTION_MIN = -190.0;
static const float SPOT_DIRECTION_MAX = 180.0;
static const float SPOT_DIRECTION_DEFAULT = 0.0;
static const float SPOT_AUDIOMULT_MIN = 0.0;
static const float SPOT_AUDIOMULT_MAX = 0.5;
static const float SPOT_AUDIOMULT_DEFAULT = 0.15;
static const float SPOT_SWAYSPEED_MIN = 0.0;
static const float SPOT_SWAYSPEED_MAX = 5.0;
static const float SPOT_SWAYSPEED_DEFAULT = 0.0;
static const float SPOT_SWAYANGLE_MIN = 0.0;
static const float SPOT_SWAYANGLE_MAX = 180.0;
static const float SPOT_SWAYANGLE_DEFAULT = 0.0;

// Using centralized tunables from AS_Utils.1.fxh for sway parameters
// static const float SPOT_SWAYSPEED_MIN = 0.0;
// static const float SPOT_SWAYSPEED_MAX = 5.0;
// static const float SPOT_SWAYSPEED_DEFAULT = 0.0;
// static const float SPOT_SWAYANGLE_MIN = 0.0;
// static const float SPOT_SWAYANGLE_MAX = 180.0;
// static const float SPOT_SWAYANGLE_DEFAULT = 0.0;

static const float BOKEH_DENSITY_MIN = 0.0;
static const float BOKEH_DENSITY_MAX = 1.0;
static const float BOKEH_DENSITY_DEFAULT = 0.25;
static const float BOKEH_SIZE_MIN = 0.01;
static const float BOKEH_SIZE_MAX = 0.2;
static const float BOKEH_SIZE_DEFAULT = 0.08;
static const float BOKEH_STRENGTH_MIN = 0.0;
static const float BOKEH_STRENGTH_MAX = 2.0;
static const float BOKEH_STRENGTH_DEFAULT = 0.7;
// Using centralized tunables for stage depth and blend amount
// static const float STAGEDEPTH_MIN = 0.0;
// static const float STAGEDEPTH_MAX = 1.0;
// static const float STAGEDEPTH_DEFAULT = 0.05;
// static const float BLENDAMOUNT_MIN = 0.0;
// static const float BLENDAMOUNT_MAX = 1.0;
// static const float BLENDAMOUNT_DEFAULT = 1.0;

// --- Controls ---
// --- Light Beams ---
uniform int NumSpots < ui_type = "slider"; ui_label = "Spotlight Count"; ui_min = NUMSPOTS_MIN; ui_max = NUMSPOTS_MAX; ui_category = "Light Beams"; > = NUMSPOTS_DEFAULT;

// --- Light Beam A ---
uniform float3 Spot1_Color < ui_type = "color"; ui_label = "Color"; ui_category = "Light Beam A"; > = float3(0.3,0.6,1.0);
uniform float2 Spot1_Position < ui_type = "drag"; ui_label = "Position"; ui_min = 0.0; ui_max = 1.0; ui_category = "Light Beam A"; > = float2(0.3,0.35);
uniform float Spot1_Radius < ui_type = "slider"; ui_label = "Size"; ui_min = SPOT_RADIUS_MIN; ui_max = SPOT_RADIUS_MAX; ui_category = "Light Beam A"; > = SPOT_RADIUS_DEFAULT;
uniform float Spot1_Intensity < ui_type = "slider"; ui_label = "Intensity"; ui_min = SPOT_INTENSITY_MIN; ui_max = SPOT_INTENSITY_MAX; ui_category = "Light Beam A"; > = SPOT_INTENSITY_DEFAULT;
uniform float Spot1_Angle < ui_type = "slider"; ui_label = "Opening"; ui_min = SPOT_ANGLE_MIN; ui_max = SPOT_ANGLE_MAX; ui_category = "Light Beam A"; > = SPOT_ANGLE_DEFAULT;
uniform float Spot1_Direction < ui_type = "slider"; ui_label = "Direction"; ui_min = SPOT_DIRECTION_MIN; ui_max = SPOT_DIRECTION_MAX; ui_category = "Light Beam A"; > = SPOT_DIRECTION_DEFAULT;
uniform float Spot1_SwaySpeed < ui_type = "slider"; ui_label = "Speed"; ui_min = SPOT_SWAYSPEED_MIN; ui_max = SPOT_SWAYSPEED_MAX; ui_category = "Light Beam A"; > = SPOT_SWAYSPEED_DEFAULT;
uniform float Spot1_SwayAngle < ui_type = "slider"; ui_label = "Sway"; ui_min = SPOT_SWAYANGLE_MIN; ui_max = SPOT_SWAYANGLE_MAX; ui_category = "Light Beam A"; > = SPOT_SWAYANGLE_DEFAULT;

// --- Light Beam B ---
uniform float3 Spot2_Color < ui_type = "color"; ui_label = "Color"; ui_category = "Light Beam B"; > = float3(1.0,0.5,0.2);
uniform float2 Spot2_Position < ui_type = "drag"; ui_label = "Position"; ui_min = 0.0; ui_max = 1.0; ui_category = "Light Beam B"; > = float2(0.7,0.35);
uniform float Spot2_Radius < ui_type = "slider"; ui_label = "Size"; ui_min = SPOT_RADIUS_MIN; ui_max = SPOT_RADIUS_MAX; ui_category = "Light Beam B"; > = SPOT_RADIUS_DEFAULT;
uniform float Spot2_Intensity < ui_type = "slider"; ui_label = "Intensity"; ui_min = SPOT_INTENSITY_MIN; ui_max = SPOT_INTENSITY_MAX; ui_category = "Light Beam B"; > = SPOT_INTENSITY_DEFAULT;
uniform float Spot2_Angle < ui_type = "slider"; ui_label = "Opening"; ui_min = SPOT_ANGLE_MIN; ui_max = SPOT_ANGLE_MAX; ui_category = "Light Beam B"; > = SPOT_ANGLE_DEFAULT;
uniform float Spot2_Direction < ui_type = "slider"; ui_label = "Direction"; ui_min = SPOT_DIRECTION_MIN; ui_max = SPOT_DIRECTION_MAX; ui_category = "Light Beam B"; > = SPOT_DIRECTION_DEFAULT;
uniform float Spot2_SwaySpeed < ui_type = "slider"; ui_label = "Speed"; ui_min = SPOT_SWAYSPEED_MIN; ui_max = SPOT_SWAYSPEED_MAX; ui_category = "Light Beam B"; > = SPOT_SWAYSPEED_DEFAULT;
uniform float Spot2_SwayAngle < ui_type = "slider"; ui_label = "Sway"; ui_min = SPOT_SWAYANGLE_MIN; ui_max = SPOT_SWAYANGLE_MAX; ui_category = "Light Beam B"; > = SPOT_SWAYANGLE_DEFAULT;

// --- Light Beam C ---
uniform float3 Spot3_Color < ui_type = "color"; ui_label = "Color"; ui_category = "Light Beam C"; > = float3(0.8,0.3,1.0);
uniform float2 Spot3_Position < ui_type = "drag"; ui_label = "Position"; ui_min = 0.0; ui_max = 1.0; ui_category = "Light Beam C"; > = float2(0.5,0.22);
uniform float Spot3_Radius < ui_type = "slider"; ui_label = "Size"; ui_min = SPOT_RADIUS_MIN; ui_max = SPOT_RADIUS_MAX; ui_category = "Light Beam C"; > = SPOT_RADIUS_DEFAULT;
uniform float Spot3_Intensity < ui_type = "slider"; ui_label = "Intensity"; ui_min = SPOT_INTENSITY_MIN; ui_max = SPOT_INTENSITY_MAX; ui_category = "Light Beam C"; > = SPOT_INTENSITY_DEFAULT;
uniform float Spot3_Angle < ui_type = "slider"; ui_label = "Opening"; ui_min = SPOT_ANGLE_MIN; ui_max = SPOT_ANGLE_MAX; ui_category = "Light Beam C"; > = SPOT_ANGLE_DEFAULT;
uniform float Spot3_Direction < ui_type = "slider"; ui_label = "Direction"; ui_min = SPOT_DIRECTION_MIN; ui_max = SPOT_DIRECTION_MAX; ui_category = "Light Beam C"; > = SPOT_DIRECTION_DEFAULT;
uniform float Spot3_SwaySpeed < ui_type = "slider"; ui_label = "Speed"; ui_min = SPOT_SWAYSPEED_MIN; ui_max = SPOT_SWAYSPEED_MAX; ui_category = "Light Beam C"; > = SPOT_SWAYSPEED_DEFAULT;
uniform float Spot3_SwayAngle < ui_type = "slider"; ui_label = "Sway"; ui_min = SPOT_SWAYANGLE_MIN; ui_max = SPOT_SWAYANGLE_MAX; ui_category = "Light Beam C"; > = SPOT_SWAYANGLE_DEFAULT;

// --- Spotlight Audio Controls ---
uniform int Spot1_AudioSource < ui_type = "combo"; ui_label = "Source"; ui_items = "Volume\0Beat\0Bass\0Mid\0Treble\0"; ui_category = "Light Beam A"; > = 1;
uniform float Spot1_AudioMult < ui_type = "slider"; ui_label = "Pulse"; ui_min = SPOT_AUDIOMULT_MIN; ui_max = SPOT_AUDIOMULT_MAX; ui_category = "Light Beam A"; > = SPOT_AUDIOMULT_DEFAULT;

uniform int Spot2_AudioSource < ui_type = "combo"; ui_label = "Source"; ui_items = "Volume\0Beat\0Bass\0Mid\0Treble\0"; ui_category = "Light Beam B"; > = 1;
uniform float Spot2_AudioMult < ui_type = "slider"; ui_label = "Pulse"; ui_min = SPOT_AUDIOMULT_MIN; ui_max = SPOT_AUDIOMULT_MAX; ui_category = "Light Beam B"; > = SPOT_AUDIOMULT_DEFAULT;

uniform int Spot3_AudioSource < ui_type = "combo"; ui_label = "Source"; ui_items = "Volume\0Beat\0Bass\0Mid\0Treble\0"; ui_category = "Light Beam C"; > = 1;
uniform float Spot3_AudioMult < ui_type = "slider"; ui_label = "Pulse"; ui_min = SPOT_AUDIOMULT_MIN; ui_max = SPOT_AUDIOMULT_MAX; ui_category = "Light Beam C"; > = SPOT_AUDIOMULT_DEFAULT;

// --- Global Audio Settings ---
AS_AUDIO_SOURCE_UI(SpotAudioSource, "Global Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(SpotAudioMult, "Global Audio Intensity", 0.5, 1.0, "Audio Reactivity")

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

// --- Main Effect ---
float3 renderSpotlights(float2 uv, float audioPulse, out float3 spotSum, out float3 spotMask) {
    float3 color = 0;
    float3 mask = 0;
    float3 sum = 0;
    float2 spots[3] = { Spot1_Position, Spot2_Position, Spot3_Position };
    float3 cols[3] = { Spot1_Color, Spot2_Color, Spot3_Color };
    float rads[3] = { Spot1_Radius, Spot2_Radius, Spot3_Radius };
    float ints[3] = { Spot1_Intensity, Spot2_Intensity, Spot3_Intensity };
    float angles[3] = { Spot1_Angle, Spot2_Angle, Spot3_Angle };
    float dirs[3] = { Spot1_Direction, Spot2_Direction, Spot3_Direction };
    int audioSources[3] = { Spot1_AudioSource, Spot2_AudioSource, Spot3_AudioSource };
    float audioMults[3] = { Spot1_AudioMult, Spot2_AudioMult, Spot3_AudioMult };
    float swaySpeeds[3] = { Spot1_SwaySpeed, Spot2_SwaySpeed, Spot3_SwaySpeed };
    float swayAngles[3] = { Spot1_SwayAngle, Spot2_SwayAngle, Spot3_SwayAngle };
    float coneLength = 0.7;
    float coneSoft = 0.18;
    float time = AS_getTime();
    for (int i = 0; i < NumSpots; ++i) {
        float2 spos = spots[i];
        float3 scol = cols[i];
        float srad = rads[i];
        float sint = ints[i];
        float coneAngle = AS_radians(clamp(angles[i], 10.0, 160.0));
        float baseDir = dirs[i];
        
        // Use only standard non-audio-reactive sway
        float sway = 0.0;
        if (swaySpeeds[i] > 0.0 && swayAngles[i] > 0.0) {
            sway = AS_applySway(swayAngles[i], swaySpeeds[i]);
        }
        
        float dirAngle = AS_radians(baseDir) + sway;
        
        // Get audio value using standardized function
        float audioVal = AS_getAudioSource(audioSources[i]);
        
        float2 uv_screen = AS_rescaleToScreen(uv);
        float2 spos_screen = AS_rescaleToScreen(spos);
        float2 rel = uv_screen - spos_screen;
        float dist = length(rel) / (coneLength * BUFFER_HEIGHT);
        float2 spotDir = float2(sin(dirAngle), cos(dirAngle));
        float dirDot = clamp(dot(normalize(rel), spotDir), -1.0, 1.0);
        float coneCos = cos(coneAngle * 0.5);
        float angleMask = (dirDot >= coneCos && dist <= 1.0) ? smoothstep(coneCos, 1.0, dirDot) : 0.0;
        float edge = smoothstep(srad, srad + coneSoft, dist);
        
        // Apply audio reactivity using standardized function
        float intensity = AS_applyAudioReactivity(sint, audioSources[i], audioMults[i], true);
        
        float val = (1.0 - edge) * angleMask * intensity * (1.0 - dist);
        color += scol * val;
        mask += val;
        sum += scol * (1.0 - edge) * angleMask;
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
    float audioPulse = AS_getAudioSource(SpotAudioSource);
    float3 spotSum, spotMask;
    float3 spotlights = renderSpotlights(uv, audioPulse, spotSum, spotMask);
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
