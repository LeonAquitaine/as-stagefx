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

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_WarpDistort_1_fx
#define __AS_VFX_WarpDistort_1_fx

#include "AS_Utils.1.fxh"

// ============================================================================
// EFFECT-SPECIFIC PARAMETERS
// ============================================================================

// --- Audio Mirror Controls ---
uniform int MirrorShape < ui_type = "combo"; ui_label = "Shape"; ui_items = "Circular\0Resolution-Relative\0"; ui_category = "Audio Mirror"; > = 0;
uniform float MirrorBaseRadius < ui_type = "slider"; ui_label = "Base Radius"; ui_tooltip = "Base radius of the mirror circle."; ui_min = 0.05; ui_max = 0.5; ui_step = 0.01; ui_category = "Audio Mirror"; > = 0.18;
uniform float MirrorWaveFreq < ui_type = "slider"; ui_label = "Wave Freq"; ui_tooltip = "Frequency of the wave/ripple effect."; ui_min = 1.0; ui_max = 20.0; ui_step = 0.1; ui_category = "Audio Mirror"; > = 8.0;
uniform float MirrorWaveStrength < ui_type = "slider"; ui_label = "Wave Strength"; ui_tooltip = "Strength of the wave/ripple distortion."; ui_min = 0.0; ui_max = 0.2; ui_step = 0.005; ui_category = "Audio Mirror"; > = 0.06;
uniform float MirrorEdgeSoftness < ui_type = "slider"; ui_label = "Edge Softness"; ui_tooltip = "Softness of the mirror's edge (fade out)."; ui_min = 0.0; ui_max = 0.2; ui_step = 0.005; ui_category = "Audio Mirror"; > = 0.08;
uniform float MirrorReflectStrength < ui_type = "slider"; ui_label = "Mirror Strength"; ui_tooltip = "How strongly the mirror distorts the scene (1 = full mirror, 0 = no effect)."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Audio Mirror"; > = 0.85;

// ============================================================================
// AUDIO REACTIVITY
// ============================================================================

AS_AUDIO_SOURCE_UI(MirrorAudioSource, "Radius Source", AS_AUDIO_VOLUME, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(MirrorRadiusAudioMult, "Radius Strength", 0.12, 0.5, "Audio Reactivity")

AS_AUDIO_SOURCE_UI(MirrorWaveAudioSource, "Wave Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(MirrorWaveAudioMult, "Wave Strength", 0.3, 1.0, "Audio Reactivity")

// ============================================================================
// STAGE/POSITION CONTROLS
// ============================================================================
AS_POSITION_UI(WarpCenter) // Defines float2 WarpCenter; category "Position", default (0,0)
// AS_ROTATION_UI(WarpSnapRotation, WarpFineRotation) // Removed rotation controls
AS_STAGEDEPTH_UI(WarpDepth) // Defines float WarpDepth; category "Stage", default 0.05

// ============================================================================
// FINAL MIX
// ============================================================================
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// ============================================================================
// DEBUG
// ============================================================================
AS_DEBUG_MODE_UI("Off\0Audio Levels\0Warp Pattern\0")

// ============================================================================
// MAIN PIXEL SHADER
// ============================================================================

float4 PS_AudioMirror(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // --- Setup --- 
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    float effectDepth = WarpDepth;

    if (sceneDepth < effectDepth - 0.0005) {
        return orig;
    }

    float aspect_ratio = ReShade::AspectRatio;
    // float rotation_rad = AS_getRotationRadians(WarpSnapRotation, WarpFineRotation); // Rotation removed

    // --- Calculate Effective WarpCenter Offset ---
    float2 effective_WarpCenter_offset;
    effective_WarpCenter_offset.x = WarpCenter.x * 0.5;
    effective_WarpCenter_offset.y = -WarpCenter.y * 0.5;

    // --- Coordinate Transformation --- 
    float2 uv_centered_aspect;
    uv_centered_aspect.x = (texcoord.x - 0.5) * aspect_ratio;
    uv_centered_aspect.y = texcoord.y - 0.5;

    // Vector from the effect's center to the current pixel, in centered aspect-aware space.
    // This is now the effect's local coordinate system as there's no rotation.
    float2 vec_pixel_from_center_local = uv_centered_aspect - effective_WarpCenter_offset;

    // --- Distance and Direction in Effect Space --- 
    float2 uv_for_calc = vec_pixel_from_center_local;
    if (MirrorShape == 1) { // Circular shape: correct for aspect ratio distortion for distance/direction calc
        if (aspect_ratio != 0.0) {
            uv_for_calc.x /= aspect_ratio;
        }
    }

    float dist = length(uv_for_calc);
    float2 dir = float2(0.0, 0.0);
    if (dist > 1e-5) {
        dir = normalize(uv_for_calc);
    }

    // --- Audio and Effect Calculations --- 
    float audio = AS_getAudioSource(MirrorAudioSource);
    float waveAudio = AS_getAudioSource(MirrorWaveAudioSource);
    float radius = MirrorBaseRadius + audio * MirrorRadiusAudioMult;
    float edge = smoothstep(radius, radius + MirrorEdgeSoftness, dist);
    float mask = 1.0 - edge;
    float time = AS_getTime();
    float wave = sin(dist * MirrorWaveFreq * AS_TWO_PI + time * 2.0) * (MirrorWaveStrength + waveAudio * MirrorWaveAudioMult);

    // --- Source Coordinate Calculation in Effect Space --- 
    // uv_for_calc is the current pixel's position in local (circularized if MirrorShape==1) effect space.
    float2 mirrorCoord_source_local_circular = dir * (radius - (dist - wave)); // Warped source
    float2 reflected_source_local_circular = uv_for_calc * -1.0 + 2.0 * (dir * radius); // Mirrored source
    
    float2 final_sample_vec_local_circular = lerp(uv_for_calc, 
                                                lerp(mirrorCoord_source_local_circular, reflected_source_local_circular, MirrorReflectStrength), 
                                                mask);

    // --- Transform Source Coordinate back to Screen Texcoord Space ---
    // 1. Un-circularize (if MirrorShape==1) to get back to aspected local space (relative to effect center)
    float2 final_sample_vec_local_aspected = final_sample_vec_local_circular;
    if (MirrorShape == 1) {
        final_sample_vec_local_aspected.x *= aspect_ratio;
    }

    // 2. Add effective_WarpCenter_offset to get absolute point in centered_aspect screen space.
    //    (No un-rotation needed as rotation was removed)
    float2 final_abs_point_centered_aspect = final_sample_vec_local_aspected + effective_WarpCenter_offset;

    // 3. Convert this absolute point back to [0,1] texcoord space.
    float2 final_texcoord_to_sample;
    if (aspect_ratio != 0.0) {
      final_texcoord_to_sample.x = (final_abs_point_centered_aspect.x / aspect_ratio) + 0.5;
    } else {
      final_texcoord_to_sample.x = 0.5;
    }
    final_texcoord_to_sample.y = final_abs_point_centered_aspect.y + 0.5;
    
    final_texcoord_to_sample = clamp(final_texcoord_to_sample, 0.0, 1.0);

    float4 scene = tex2D(ReShade::BackBuffer, final_texcoord_to_sample);

    // --- Debug and Final Output --- 
    if (DebugMode == 1) return float4(mask.xxx, 1.0); // Show mask
    if (DebugMode == 2) return float4(audio.xxx, 1.0); // Show audio level for MirrorAudioSource
    // Note: DebugMode for "Warp Pattern" (value 2 in AS_DEBUG_MODE_UI) would typically show 'final_texcoord_to_sample' or similar.
    // For now, re-using audio display for DebugMode == 2.

    float3 blended = AS_blendResult(orig.rgb, scene.rgb, BlendMode);
    float3 result = lerp(orig.rgb, blended, mask * BlendAmount);
    return float4(result, orig.a);
}

technique AS_Warp < ui_label = "[AS] VFX: Warp Distort"; ui_tooltip = "Circular mirrored effect that pulses and waves with music."; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_AudioMirror;
    }
}

#endif // __AS_VFX_WarpDistort_1_fx
