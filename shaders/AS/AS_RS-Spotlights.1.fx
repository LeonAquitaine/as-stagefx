/**
 * AS_RockStage-Spotlights.1.fx - Directional Stage Lighting Effect
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

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "ListeningwayUniforms.fxh"
#include "AS_Utils.1.fxh"

// --- Controls ---
// --- Light Beams ---
uniform int NumSpots < ui_type = "slider"; ui_label = "Spotlight Count"; ui_min = 1; ui_max = 3; ui_category = "Light Beams"; > = 3;

// --- Light Beam A ---
uniform float3 Spot1_Color < ui_type = "color"; ui_label = "Color"; ui_category = "Light Beam A"; > = float3(0.3,0.6,1.0);
uniform float2 Spot1_Position < ui_type = "drag"; ui_label = "Position"; ui_min = 0.0; ui_max = 1.0; ui_category = "Light Beam A"; > = float2(0.3,0.35);
uniform float Spot1_Radius < ui_type = "slider"; ui_label = "Size"; ui_min = 0.05; ui_max = 1.5; ui_category = "Light Beam A"; > = 0.18;
uniform float Spot1_Intensity < ui_type = "slider"; ui_label = "Intensity"; ui_min = 0.0; ui_max = 2.0; ui_category = "Light Beam A"; > = 1.0;
uniform float Spot1_Angle < ui_type = "slider"; ui_label = "Opening"; ui_min = 10.0; ui_max = 160.0; ui_category = "Light Beam A"; > = 90.0;
uniform float Spot1_Direction < ui_type = "slider"; ui_label = "Direction"; ui_min = -190.0; ui_max = 180.0; ui_category = "Light Beam A"; > = 0.0;
uniform int Spot1_AudioSource < ui_type = "combo"; ui_label = "Source"; ui_items = "Off\0Solid\0Volume\0Beat\0Bass\0Treble\0"; ui_category = "Light Beam A"; > = 3;
uniform float Spot1_AudioMult < ui_type = "slider"; ui_label = "Pulse"; ui_min = 0.0; ui_max = 0.5; ui_category = "Light Beam A"; > = 0.15;
uniform float Spot1_SwaySpeed < ui_type = "slider"; ui_label = "Speed"; ui_min = 0.0; ui_max = 5.0; ui_category = "Light Beam A"; > = 0.0;
uniform float Spot1_SwayAngle < ui_type = "slider"; ui_label = "Sway"; ui_min = 0.0; ui_max = 180.0; ui_category = "Light Beam A"; > = 0.0;

// --- Light Beam B ---
uniform float3 Spot2_Color < ui_type = "color"; ui_label = "Color"; ui_category = "Light Beam B"; > = float3(1.0,0.5,0.2);
uniform float2 Spot2_Position < ui_type = "drag"; ui_label = "Position"; ui_min = 0.0; ui_max = 1.0; ui_category = "Light Beam B"; > = float2(0.7,0.35);
uniform float Spot2_Radius < ui_type = "slider"; ui_label = "Size"; ui_min = 0.05; ui_max = 1.5; ui_category = "Light Beam B"; > = 0.18;
uniform float Spot2_Intensity < ui_type = "slider"; ui_label = "Intensity"; ui_min = 0.0; ui_max = 2.0; ui_category = "Light Beam B"; > = 1.0;
uniform float Spot2_Angle < ui_type = "slider"; ui_label = "Opening"; ui_min = 10.0; ui_max = 160.0; ui_category = "Light Beam B"; > = 90.0;
uniform float Spot2_Direction < ui_type = "slider"; ui_label = "Direction"; ui_min = -190.0; ui_max = 180.0; ui_category = "Light Beam B"; > = 0.0;
uniform int Spot2_AudioSource < ui_type = "combo"; ui_label = "Source"; ui_items = "Off\0Solid\0Volume\0Beat\0Bass\0Treble\0"; ui_category = "Light Beam B"; > = 3;
uniform float Spot2_AudioMult < ui_type = "slider"; ui_label = "Pulse"; ui_min = 0.0; ui_max = 0.5; ui_category = "Light Beam B"; > = 0.15;
uniform float Spot2_SwaySpeed < ui_type = "slider"; ui_label = "Speed"; ui_min = 0.0; ui_max = 5.0; ui_category = "Light Beam B"; > = 0.0;
uniform float Spot2_SwayAngle < ui_type = "slider"; ui_label = "Sway"; ui_min = 0.0; ui_max = 180.0; ui_category = "Light Beam B"; > = 0.0;

// --- Light Beam C ---
uniform float3 Spot3_Color < ui_type = "color"; ui_label = "Color"; ui_category = "Light Beam C"; > = float3(0.8,0.3,1.0);
uniform float2 Spot3_Position < ui_type = "drag"; ui_label = "Position"; ui_min = 0.0; ui_max = 1.0; ui_category = "Light Beam C"; > = float2(0.5,0.22);
uniform float Spot3_Radius < ui_type = "slider"; ui_label = "Size"; ui_min = 0.05; ui_max = 1.5; ui_category = "Light Beam C"; > = 0.18;
uniform float Spot3_Intensity < ui_type = "slider"; ui_label = "Intensity"; ui_min = 0.0; ui_max = 2.0; ui_category = "Light Beam C"; > = 1.0;
uniform float Spot3_Angle < ui_type = "slider"; ui_label = "Opening"; ui_min = 10.0; ui_max = 160.0; ui_category = "Light Beam C"; > = 90.0;
uniform float Spot3_Direction < ui_type = "slider"; ui_label = "Direction"; ui_min = -190.0; ui_max = 180.0; ui_category = "Light Beam C"; > = 0.0;
uniform int Spot3_AudioSource < ui_type = "combo"; ui_label = "Source"; ui_items = "Off\0Solid\0Volume\0Beat\0Bass\0Treble\0"; ui_category = "Light Beam C"; > = 3;
uniform float Spot3_AudioMult < ui_type = "slider"; ui_label = "Pulse"; ui_min = 0.0; ui_max = 0.5; ui_category = "Light Beam C"; > = 0.15;
uniform float Spot3_SwaySpeed < ui_type = "slider"; ui_label = "Speed"; ui_min = 0.0; ui_max = 5.0; ui_category = "Light Beam C"; > = 0.0;
uniform float Spot3_SwayAngle < ui_type = "slider"; ui_label = "Sway"; ui_min = 0.0; ui_max = 180.0; ui_category = "Light Beam C"; > = 0.0;

// --- Global Audio Settings ---
AS_LISTENINGWAY_UI_CONTROLS("Audio Reactivity")
AS_AUDIO_SOURCE_UI(SpotAudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(SpotAudioMult, "Audio Pulse", 0.15, 0.5, "Audio Reactivity")

// --- Bokeh Settings ---
uniform float BokehDensity < ui_type = "slider"; ui_label = "Density"; ui_min = 0.0; ui_max = 1.0; ui_category = "Stage Effects"; > = 0.25;
uniform float BokehSize < ui_type = "slider"; ui_label = "Size"; ui_min = 0.01; ui_max = 0.2; ui_category = "Stage Effects"; > = 0.08;
uniform float BokehStrength < ui_type = "slider"; ui_label = "Strength"; ui_min = 0.0; ui_max = 2.0; ui_category = "Stage Effects"; > = 0.7;

// --- Stage Depth Control ---
uniform float StageDepth < ui_type = "slider"; ui_label = "Distance"; ui_tooltip = "Controls how far back the stage effect appears (lower = closer, higher = further)."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Stage Distance"; > = 0.08;

// --- Blend Settings ---
uniform int BlendMode < ui_type = "combo"; ui_label = "Mode"; ui_items = "Normal\0Lighter Only\0Darker Only\0Additive\0Multiply\0Screen\0"; ui_category = "Final Mix"; > = 3;
uniform float BlendAmount < ui_type = "slider"; ui_label = "Strength"; ui_min = 0.0; ui_max = 1.0; ui_category = "Final Mix"; > = 1.0;

// --- Debug Settings ---
AS_DEBUG_MODE_UI("Off\0Spotlights\0Bokeh\0")

uniform int frameCount < source = "framecount"; >;

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
    float time = AS_getTime(frameCount);
    for (int i = 0; i < NumSpots; ++i) {
        float2 spos = spots[i];
        float3 scol = cols[i];
        float srad = rads[i];
        float sint = ints[i];
        float coneAngle = AS_radians(clamp(angles[i], 10.0, 160.0));
        float baseDir = dirs[i];
        float sway = swayAngles[i] * sin(time * swaySpeeds[i]);
        float dirAngle = AS_radians(baseDir + sway);
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
        float val = (1.0 - edge) * angleMask * (sint + audioVal * audioMults[i]) * (1.0 - dist);
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
    float2 uv = texcoord;
    float audioPulse = AS_getAudioSource(SpotAudioSource);
    float3 spotSum, spotMask;
    float3 spotlights = renderSpotlights(uv, audioPulse, spotSum, spotMask);
    float3 bokeh = renderBokeh(uv, spotSum);
    float3 fx = spotlights + bokeh;
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    if (sceneDepth < StageDepth - 0.0005)
        return orig;
    if (DebugMode == 1) return float4(spotlights, 1.0);
    if (DebugMode == 3) return float4(bokeh, 1.0);
    fx = saturate(fx);
    float3 blended = AS_blendResult(orig.rgb, fx, BlendMode);
    float3 result = lerp(orig.rgb, blended, BlendAmount);
    return float4(result, orig.a);
}

technique AS_RS_Spotlights < ui_label = "[AS] Rock Stage: Spotlights"; ui_tooltip = "Configurable stage spotlights with audio reactivity."; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_Spotlights;
    }
}
