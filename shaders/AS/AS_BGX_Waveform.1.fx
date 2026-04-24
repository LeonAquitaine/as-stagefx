/**
 * AS_BGX_Waveform.1.fx - Raymarched audio-reactive waveform background
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported (CC BY-NC-SA 3.0)
 * Inherited from the upstream work published on Shadertoy (default licence per https://www.shadertoy.com/terms).
 * Free for non-commercial use with attribution. Derivatives must be distributed under the same licence.
 *
 * CREDITS:
 * Based on "Waveform [315]" by Xor (XorDev)
 * Shadertoy: https://www.shadertoy.com/view/Wcc3z2
 *
 * The upstream includes a commented-out Shadertoy audio input
 * (`texture(iChannel0, ...).r`) that was disabled after Shadertoy's Soundcloud
 * integration stopped working. In this port the audio displacement is driven
 * by Listeningway frequency bands instead — each horizontal position in the
 * scene samples a different band of the live audio spectrum.
 */

#ifndef __AS_BGX_Waveform_1_fx
#define __AS_BGX_Waveform_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

namespace AS_Waveform {

static const int   RAYMARCH_STEPS_MIN     = 20;
static const int   RAYMARCH_STEPS_MAX     = 120;
static const int   RAYMARCH_STEPS_DEFAULT = 90;

static const int   SINE_OCTAVES_MIN     = 2;
static const int   SINE_OCTAVES_MAX     = 8;
static const int   SINE_OCTAVES_DEFAULT = 5;

static const float PROC_WAVE_MIN     = 0.0;
static const float PROC_WAVE_MAX     = 2.0;
static const float PROC_WAVE_STEP    = 0.01;
static const float PROC_WAVE_DEFAULT = 1.0;

static const float EXPOSURE_MIN     = 100.0;
static const float EXPOSURE_MAX     = 3000.0;
static const float EXPOSURE_STEP    = 10.0;
static const float EXPOSURE_DEFAULT = 900.0;

static const float AUDIO_INTENSITY_MIN     = 0.0;
static const float AUDIO_INTENSITY_MAX     = 20.0;
static const float AUDIO_INTENSITY_STEP    = 0.1;
static const float AUDIO_INTENSITY_DEFAULT = 6.0;

static const float AUDIO_SPREAD_MIN     = 2.0;
static const float AUDIO_SPREAD_MAX     = 30.0;
static const float AUDIO_SPREAD_STEP    = 0.1;
static const float AUDIO_SPREAD_DEFAULT = 6.0;

static const float AUDIO_SENSIBILITY_MIN     = 0.0;
static const float AUDIO_SENSIBILITY_MAX     = 8.0;
static const float AUDIO_SENSIBILITY_STEP    = 0.05;
static const float AUDIO_SENSIBILITY_DEFAULT = 2.5;

uniform int as_shader_descriptor <
    ui_type = "radio";
    ui_label = " ";
    ui_text = "\nBased on 'Waveform [315]' by Xor\nLink: https://www.shadertoy.com/view/Wcc3z2\nLicence: CC BY-NC-SA 3.0 Unported\n\n";
>;

uniform int RaymarchSteps <
    ui_type = "slider";
    ui_label = "Quality";
    ui_tooltip = "Number of raymarching steps per pixel. Higher values produce smoother results at higher GPU cost.";
    ui_min = RAYMARCH_STEPS_MIN; ui_max = RAYMARCH_STEPS_MAX;
    ui_category = "Effect Settings";
> = RAYMARCH_STEPS_DEFAULT;

uniform float ProceduralWaveStrength <
    ui_type = "slider";
    ui_label = "Procedural Wave Motion";
    ui_tooltip = "Strength of the additive sine-wave octaves that animate the surface continuously, independent of audio. 0 disables them entirely (the surface then falls still in silence, shaped purely by the Listeningway spectrum); 1 is the baseline; 2 doubles the swell.";
    ui_min = PROC_WAVE_MIN; ui_max = PROC_WAVE_MAX; ui_step = PROC_WAVE_STEP;
    ui_category = "Effect Settings";
> = PROC_WAVE_DEFAULT;

uniform int SineOctaves <
    ui_type = "slider";
    ui_label = "Wave Detail";
    ui_tooltip = "How many octaves of sine-wave displacement contribute to the waveform surface. Higher values produce finer detail. No effect when 'Procedural Wave Motion' is at 0.";
    ui_min = SINE_OCTAVES_MIN; ui_max = SINE_OCTAVES_MAX;
    ui_category = "Effect Settings";
> = SINE_OCTAVES_DEFAULT;

uniform float Exposure <
    ui_type = "slider";
    ui_label = "Exposure";
    ui_tooltip = "Tanh-tonemap exposure divisor. Lower values produce a brighter image; higher values dim the effect.";
    ui_min = EXPOSURE_MIN; ui_max = EXPOSURE_MAX; ui_step = EXPOSURE_STEP;
    ui_category = "Effect Settings";
> = EXPOSURE_DEFAULT;

uniform float AudioIntensity <
    ui_type = "slider";
    ui_label = "Audio Waveform Intensity";
    ui_tooltip = "How strongly the Listeningway frequency spectrum deforms the waveform surface. Zero disables the audio effect entirely; the scene still animates via the internal sine octaves.";
    ui_min = AUDIO_INTENSITY_MIN; ui_max = AUDIO_INTENSITY_MAX; ui_step = AUDIO_INTENSITY_STEP;
    ui_category = AS_CAT_AUDIO;
> = AUDIO_INTENSITY_DEFAULT;

uniform float AudioSensibility <
    ui_type = "slider";
    ui_label = "Audio Sensibility";
    ui_tooltip = "Gain applied to raw Listeningway band values before they drive the waveform. Raise this if the effect looks flat on quiet music or if Listeningway is outputting low-amplitude bands.";
    ui_min = AUDIO_SENSIBILITY_MIN; ui_max = AUDIO_SENSIBILITY_MAX; ui_step = AUDIO_SENSIBILITY_STEP;
    ui_category = AS_CAT_AUDIO;
> = AUDIO_SENSIBILITY_DEFAULT;

uniform float AudioSpread <
    ui_type = "slider";
    ui_label = "Audio Frequency Spread";
    ui_tooltip = "Horizontal world-space span over which the audio spectrum is mapped. The default (6.0) roughly aligns band 0 with the left edge and the highest live band with the right edge at typical raymarch depths. Lower values compress the spectrum toward screen centre; higher values push bass and treble off the sides of the frame.";
    ui_min = AUDIO_SPREAD_MIN; ui_max = AUDIO_SPREAD_MAX; ui_step = AUDIO_SPREAD_STEP;
    ui_category = AS_CAT_AUDIO;
> = AUDIO_SPREAD_DEFAULT;

AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, AS_CAT_ANIMATION)

AS_POSITION_SCALE_UI(Position, Scale)
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(RotationSnap, RotationFine)

AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

float4 PS_Waveform(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    AS_DEPTH_EARLY_RETURN(texcoord, EffectDepth)

    float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);

    float2 screenSize = ReShade::ScreenSize;
    float2 center = screenSize * 0.5;

    // ReShade texcoord.y is top-down; the Shadertoy source expects
    // bottom-up GL convention for the raymarch direction's Y sign.
    float2 I = float2(texcoord.x, 1.0 - texcoord.y) * screenSize;
    float2 delta = I - center;

    float rot = -AS_getRotationRadians(RotationSnap, RotationFine);
    float cr = cos(rot);
    float sr = sin(rot);
    delta = float2(delta.x * cr - delta.y * sr, delta.x * sr + delta.y * cr);

    delta /= max(Scale, AS_STABILITY_EPSILON);
    delta -= Position * center;

    I = delta + center;

    float3 refRes = float3(screenSize.x, screenSize.y, screenSize.y);

    float4 O = float4(0.0, 0.0, 0.0, 0.0);
    float d = 0.0;
    float z = 0.0;
    float r = 0.0;

    int steps = clamp(RaymarchSteps, RAYMARCH_STEPS_MIN, RAYMARCH_STEPS_MAX);
    int octaves = clamp(SineOctaves, SINE_OCTAVES_MIN, SINE_OCTAVES_MAX);
    float invSpread = 1.0 / max(AudioSpread, AS_STABILITY_EPSILON);

    [loop]
    for (int i = 0; i < 120; ++i)
    {
        if (i >= steps) break;

        float3 p = z * normalize(float3(I + I, 0.0) - refRes);

        p += float3(1.0, 1.0, 1.0);
        r = max(-p.y, 0.0);

        p.y += r + r;

        // Per-iteration spectrum sample. Centring on (p.x - 1) removes the
        // +1 offset injected above so that the screen centre maps to the
        // middle of the live band range. AS_getFreqByPercentSmooth runs a
        // Catmull-Rom spline through the band values so the surface
        // connects adjacent samples with a smooth curve rather than the
        // plateau-and-step look of nearest-neighbour sampling.
        float audioBand = saturate(AS_getFreqByPercentSmooth(saturate((p.x - 1.0) * invSpread + 0.5)) * AudioSensibility);
        p.y -= AudioIntensity * audioBand;

        if (ProceduralWaveStrength > 0.0)
        {
            d = 1.0;
            [loop]
            for (int j = 0; j < 8; ++j)
            {
                if (j >= octaves) break;
                p.y += ProceduralWaveStrength * cos(p * d + 2.0 * time * cos(d) + z).x / d;
                d += d;
            }
        }

        float pzPlus3 = p.z + 3.0;
        d = (0.1 * r
             + abs(p.y - 1.0) / (1.0 + r + r + r * r)
             + max(pzPlus3, -pzPlus3 * 0.1)) / 8.0;
        z += d;

        float denom = max(d * z, AS_EPSILON);
        O += (cos(z * 0.5 + time + float4(0.0, 2.0, 4.0, 3.0)) + 1.3) / denom;
    }

    O = tanh(O / max(Exposure, AS_EPSILON));

    // Highlight desaturation: when the brightest channel of a pixel is already
    // pushing towards saturation, pull the dimmer channels up to match so the
    // peak reads as a clean white-hot core rather than as the chromaticity of
    // whatever palette colour the raymarch happened to accumulate at the stall
    // point. This preserves the hot edge at true peaks without interfering
    // with the palette in the body of the glow — pixels below the 0.9
    // threshold are untouched.
    float loudest = max(max(O.r, O.g), O.b);
    float highlightPull = smoothstep(0.9, 1.0, loudest);
    O.rgb = lerp(O.rgb, float3(loudest, loudest, loudest), highlightPull);

    float3 finalColor = AS_composite(saturate(O.rgb), _as_originalColor.rgb, BlendMode, BlendAmount);
    return float4(finalColor, 1.0);
}

} // namespace AS_Waveform

technique AS_BGX_Waveform <
    ui_label = "[AS] BGX: Waveform";
    ui_tooltip = "Raymarched audio-reactive waveform background. The horizontal axis of the scene samples the live audio spectrum via Listeningway, mirroring it across a reflective surface.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = AS_Waveform::PS_Waveform;
    }
}

#endif
