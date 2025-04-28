/**
 * AS_VFX_WarpDistort.1.fx - Audio-Reactive Circular Mirror Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader creates a circular mirrored (or wavy) region behind the character that pulses
 * and warps in sync with music using Listeningway audio data. The effect is highly customizable
 * and designed for impactful, professional-grade visuals.
 *
 * FEATURES:
 * - Circular or elliptical mirror region with soft edge
 * - Audio-reactive pulsing, radius, and wave/ripple effects
 * - User-selectable audio source (volume, beat, bass, treble)
 * - Adjustable mirror strength, wave frequency, and edge softness
 * - Debug visualizations for mask and audio
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. The shader computes the distance from each pixel to the user-defined center.
 * 2. If within the (audio-reactive) radius, the scene is mirrored or warped.
 * 3. The radius, wave, and mirror strength are modulated by the selected Listeningway source.
 * 4. The effect fades out at the edge for a natural look.
 *
 * ===================================================================================
 */

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "AS_Utils.1.fxh"

// --- Shader Controls ---
// --- Center Group ---
uniform float MirrorCenterX < ui_type = "slider"; ui_label = "X (Horizontal)"; ui_tooltip = "Horizontal position of the mirror center (0 = left, 1 = right)."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Position"; > = 0.5;
uniform float MirrorCenterY < ui_type = "slider"; ui_label = "Y (Vertical)"; ui_tooltip = "Vertical position of the mirror center (0 = top, 1 = bottom)."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Position"; > = 0.5;

uniform int MirrorShape < ui_type = "combo"; ui_label = "Shape"; ui_items = "Screen-Relative\0Circular\0"; ui_category = "Audio Mirror"; > = 0;
uniform float MirrorBaseRadius < ui_type = "slider"; ui_label = "Base Radius"; ui_tooltip = "Base radius of the mirror circle."; ui_min = 0.05; ui_max = 0.5; ui_step = 0.01; ui_category = "Audio Mirror"; > = 0.18;
uniform float MirrorWaveFreq < ui_type = "slider"; ui_label = "Wave Freq"; ui_tooltip = "Frequency of the wave/ripple effect."; ui_min = 1.0; ui_max = 20.0; ui_step = 0.1; ui_category = "Audio Mirror"; > = 8.0;
uniform float MirrorWaveStrength < ui_type = "slider"; ui_label = "Wave Strength"; ui_tooltip = "Strength of the wave/ripple distortion."; ui_min = 0.0; ui_max = 0.2; ui_step = 0.005; ui_category = "Audio Mirror"; > = 0.06;
uniform float MirrorEdgeSoftness < ui_type = "slider"; ui_label = "Edge Softness"; ui_tooltip = "Softness of the mirror's edge (fade out)."; ui_min = 0.0; ui_max = 0.2; ui_step = 0.005; ui_category = "Audio Mirror"; > = 0.08;
uniform float MirrorReflectStrength < ui_type = "slider"; ui_label = "Mirror Strength"; ui_tooltip = "How strongly the mirror distorts the scene (1 = full mirror, 0 = no effect)."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Audio Mirror"; > = 0.85;
uniform float MirrorDepth < ui_type = "slider"; ui_label = "Depth"; ui_tooltip = "Controls the reference depth for the mirror effect. Lower values bring the effect closer to the camera, higher values push it further back."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Audio Mirror"; > = 0.05;
uniform float BlendAmount < ui_type = "slider"; ui_label = "Amount"; ui_tooltip = "How strongly the effect is blended with the scene."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Blend"; > = 1.0;

// --- Listeningway Integration ---

AS_AUDIO_SOURCE_UI(MirrorAudioSource, "Radius Source", AS_AUDIO_BEAT, "Listeningway Integration")
AS_AUDIO_MULTIPLIER_UI(MirrorRadiusAudioMult, "Radius Strength", 0.12, 0.5, "Listeningway Integration")

AS_AUDIO_SOURCE_UI(MirrorWaveAudioSource, "Wave Source", AS_AUDIO_BEAT, "Listeningway Integration")
AS_AUDIO_MULTIPLIER_UI(MirrorWaveAudioMult, "Wave Strength", 0.3, 1.0, "Listeningway Integration")

// --- Blend ---
uniform int BlendMode <
    ui_type = "combo";
    ui_label = "Mode";
    ui_items = "Normal\0Lighter Only\0Darker Only\0Additive\0Multiply\0Screen\0";
    ui_category = "Blend";
> = 0;

// --- Debug ---
AS_DEBUG_MODE_UI("Off\0Audio Levels\0Warp Pattern\0")

// --- Main Effect ---


float4 PS_AudioMirror(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float2 center = float2(MirrorCenterX, MirrorCenterY);
    float2 uv = texcoord - center;
    float2 screen = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float dist;
    float2 dir;
    if (MirrorShape == 1) {
        float minDim = min(screen.x, screen.y);
        float2 uv_circ = float2(uv.x * screen.x / minDim, uv.y * screen.y / minDim);
        dist = length(uv_circ);
        dir = normalize(uv_circ);
    } else {
        dist = length(uv);
        dir = normalize(uv);
    }
    float audio = AS_getAudioSource(MirrorAudioSource);
    float waveAudio = AS_getAudioSource(MirrorWaveAudioSource);
    float radius = MirrorBaseRadius + audio * MirrorRadiusAudioMult;
    float edge = smoothstep(radius, radius + MirrorEdgeSoftness, dist);
    float mask = 1.0 - edge;
    float time = AS_getTime();
    float wave = sin(dist * MirrorWaveFreq * 6.2831 + time * 2.0) * (MirrorWaveStrength + waveAudio * MirrorWaveAudioMult);
    float2 mirrorCoord = center + dir * (radius - (dist - wave));
    float2 reflected = center + (texcoord - center) * -1.0 + 2.0 * (dir * radius);
    float2 finalCoord = lerp(texcoord, lerp(mirrorCoord, reflected, MirrorReflectStrength), mask);
    float4 scene = tex2D(ReShade::BackBuffer, finalCoord);
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    float effectDepth = MirrorDepth;
    if (sceneDepth < effectDepth - 0.0005)
        return orig;
    if (DebugMode == 1) return float4(mask.xxx, 1.0);
    if (DebugMode == 2) return float4(audio.xxx, 1.0);
    float3 blended = AS_blendResult(orig.rgb, scene.rgb, BlendMode);
    float3 result = lerp(orig.rgb, blended, mask * BlendAmount);
    return float4(result, orig.a);
}

technique AS_Warp < ui_label = "[AS] Cinematic: Warp"; ui_tooltip = "Circular mirrored effect that pulses and waves with music."; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_AudioMirror;
    }
}
