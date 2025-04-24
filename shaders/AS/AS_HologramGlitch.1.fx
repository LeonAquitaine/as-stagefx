/**
 * AS_HologramGlitch.1.fx - Audio-Driven Hologram/Glitch Effect Shader
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader creates a hologram and digital glitch effect that pulses, jitters, and color-splits
 * in sync with music using Listeningway audio data. Designed for impactful, professional-grade visuals.
 *
 * FEATURES:
 * - Audio-reactive scanlines, RGB split, and digital glitching
 * - Pulsing, jitter, and color offset driven by music (volume, beat, bass, treble)
 * - User-selectable audio source for each effect
 * - Adjustable intensity, speed, and randomness
 * - Debug visualizations for mask and audio
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. The shader applies scanlines, color channel offsets, and random jitter to the scene.
 * 2. The intensity, speed, and randomness of each effect are modulated by the selected Listeningway source.
 * 3. Effects can be combined or used independently for a custom look.
 *
 * ===================================================================================
 */

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "ListeningwayUniforms.fxh"
#include "AS_Utils.1.fxh"

// --- Listeningway Integration ---
AS_LISTENINGWAY_UI_CONTROLS("Listeningway Integration")

AS_AUDIO_SOURCE_UI(ScanlineSource, "Scanline Source", AS_AUDIO_BEAT, "Listeningway Integration")
AS_AUDIO_MULTIPLIER_UI(ScanlineIntensity, "Scanline Intensity", 0.35, 1.0, "Listeningway Integration")
AS_AUDIO_MULTIPLIER_UI(ScanlineSpeed, "Scanline Speed", 2.0, 10.0, "Listeningway Integration")

AS_AUDIO_SOURCE_UI(RGBSplitSource, "RGB Split Source", AS_AUDIO_BEAT, "Listeningway Integration")
AS_AUDIO_MULTIPLIER_UI(RGBSplitAmount, "RGB Split", 0.012, 0.03, "Listeningway Integration")

AS_AUDIO_SOURCE_UI(RGBSplitAngleSource, "RGB Split Angle Source", AS_AUDIO_BEAT, "Listeningway Integration")

AS_AUDIO_SOURCE_UI(GlitchSource, "Glitch Source", AS_AUDIO_BEAT, "Listeningway Integration")
AS_AUDIO_MULTIPLIER_UI(GlitchStrength, "Glitch Strength", 0.018, 0.05, "Listeningway Integration")
AS_AUDIO_MULTIPLIER_UI(GlitchSpeed, "Glitch Speed", 7.0, 20.0, "Listeningway Integration")

// --- Shader Controls ---
uniform float HoloGlitchDepth < ui_type = "slider"; ui_label = "Depth"; ui_tooltip = "Controls the reference depth for the glitch effect. Lower values bring the effect closer to the camera, higher values push it further back."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Cut-off Distance"; > = 0.05;

// --- Blend ---
uniform int BlendMode < ui_type = "combo"; ui_label = "Mode"; ui_items = "Normal\0Lighter Only\0Darker Only\0Additive\0Multiply\0Screen\0"; ui_category = "Blend"; > = 0;
uniform float BlendAmount < ui_type = "slider"; ui_label = "Amount"; ui_tooltip = "How strongly the effect is blended with the scene."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Blend"; > = 1.0;

// --- Debug ---
AS_DEBUG_MODE_UI("Off\0Scanline\0RGB Split\0Glitch\0Audio\0")

// --- Frame Count ---
uniform int frameCount < source = "framecount"; >;

// --- Main Effect ---
float4 PS_HoloGlitch(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float time = AS_getTime(frameCount);

    float scanlineAudio = AS_getAudioSource(ScanlineSource);
    float rgbAudio = AS_getAudioSource(RGBSplitSource);
    float rgbAngleAudio = AS_getAudioSource(RGBSplitAngleSource);
    float glitchAudio = AS_getAudioSource(GlitchSource);

    // Scanline effect
    float scanline = sin((texcoord.y + time * ScanlineSpeed * (0.5 + scanlineAudio)) * 600.0) * 0.5 + 0.5;
    float scanlineMask = lerp(1.0, scanline, ScanlineIntensity * scanlineAudio);

    // RGB split effect
    float angle = AS_radians(rgbAngleAudio * 360.0); // 0-1 mapped to 0-360 degrees
    float2 rgbOffset = float2(cos(angle), sin(angle)) * (RGBSplitAmount * rgbAudio);

    // Glitch/jitter effect
    float glitchPhase = time * GlitchSpeed * (0.5 + glitchAudio);
    float2 jitter = float2(
        (AS_hash11(texcoord * 100.0 + glitchPhase) - 0.5) * GlitchStrength * glitchAudio,
        (AS_hash11(texcoord * 100.0 + glitchPhase + 1.0) - 0.5) * GlitchStrength * glitchAudio
    );
    float2 rCoord = texcoord + rgbOffset + jitter;
    float2 gCoord = texcoord + jitter;
    float2 bCoord = texcoord - rgbOffset + jitter;
    float4 col;
    col.r = tex2D(ReShade::BackBuffer, rCoord).r;
    col.g = tex2D(ReShade::BackBuffer, gCoord).g;
    col.b = tex2D(ReShade::BackBuffer, bCoord).b;
    col.a = 1.0;

    // Depth occlusion: mask out effect if something is in front
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    float effectDepth = HoloGlitchDepth;
    if (sceneDepth < effectDepth - 0.0005)
        return tex2D(ReShade::BackBuffer, texcoord);

    // Combine with scanline
    col.rgb *= scanlineMask;

    // Debug visualizations
    if (DebugMode == 1) return float4(scanlineMask.xxx, 1.0);
    if (DebugMode == 2) return float4(abs(rgbOffset.x).xxx, 1.0);
    if (DebugMode == 3) return float4(abs(jitter.x).xxx, 1.0);
    if (DebugMode == 4) return float4(scanlineAudio, rgbAudio, glitchAudio, 1.0);

    // Blend with scene
    float3 blended = AS_blendResult(tex2D(ReShade::BackBuffer, texcoord).rgb, col.rgb, BlendMode);
    col.rgb = lerp(tex2D(ReShade::BackBuffer, texcoord).rgb, blended, BlendAmount);

    return col;
}

technique AS_HologramGlitch < ui_label = "[AS] Hologram Glitch"; ui_tooltip = "Audio-driven hologram and digital glitch effect with scanlines, RGB split, and jitter."; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_HoloGlitch;
    }
}
