// AS_BGX_MeltWave.1.fx
// Leon Aquitaine - CC BY 4.0

#ifndef __AS_BGX_MeltWave_1_fx
#define __AS_BGX_MeltWave_1_fx

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

namespace AS_MeltWave {

static const int   ITERATIONS_MIN            = 10;
static const int   ITERATIONS_MAX            = 80;
static const int   ITERATIONS_STEP           = 1;
static const int   ITERATIONS_DEFAULT        = 40;

static const float BRIGHTNESS_MIN            = 0.5;
static const float BRIGHTNESS_MAX            = 2.0;
static const float BRIGHTNESS_STEP           = 0.01;
static const float BRIGHTNESS_DEFAULT        = 0.975;

static const float MELT_INTENSITY_MIN        = 0.25;
static const float MELT_INTENSITY_MAX        = 4.0;
static const float MELT_INTENSITY_STEP       = 0.05;
static const float MELT_INTENSITY_DEFAULT    = 1.0;

static const float SATURATION_MIN            = 0.0;
static const float SATURATION_MAX            = 2.0;
static const float SATURATION_STEP           = 0.01;
static const float SATURATION_DEFAULT        = 1.0;

static const float COLOR_CYCLE_SPEED_MIN     = -2.0;
static const float COLOR_CYCLE_SPEED_MAX     = 2.0;
static const float COLOR_CYCLE_SPEED_STEP    = 0.1;
static const float COLOR_CYCLE_SPEED_DEFAULT = 0.1;

static const float ANIMATION_SPEED_MIN       = 0.0;
static const float ANIMATION_SPEED_MAX       = 5.0;
static const float ANIMATION_SPEED_STEP      = 0.01;
static const float ANIMATION_SPEED_DEFAULT   = 1.25;

static const float ANIMATION_KEYFRAME_MIN    = 0.0;
static const float ANIMATION_KEYFRAME_MAX    = 100.0;
static const float ANIMATION_KEYFRAME_STEP   = 0.1;
static const float ANIMATION_KEYFRAME_DEFAULT= 0.0;

static const float POSITION_MIN              = -1.5;
static const float POSITION_MAX              = 1.5;
static const float POSITION_STEP             = 0.01;
static const float POSITION_DEFAULT          = 0.0;

static const float SCALE_MIN                 = 0.5;
static const float SCALE_MAX                 = 2.0;
static const float SCALE_STEP                = 0.01;
static const float SCALE_DEFAULT             = 1.0;

static const float AUDIO_MULTIPLIER_DEFAULT  = 1.0;
static const float AUDIO_MULTIPLIER_MAX      = 5.0;

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform int Iterations <
    ui_type = "slider";
    ui_label = "Zoom Intensity";
    ui_tooltip = "Number of warp iterations. Higher values produce busier, more intricate fine-scale structure; lower values produce broad, simple patterns.";
    ui_min = ITERATIONS_MIN; ui_max = ITERATIONS_MAX; ui_step = ITERATIONS_STEP;
    ui_category = "Effect Settings";
> = ITERATIONS_DEFAULT;

uniform float Brightness <
    ui_type = "slider";
    ui_label = "Brightness";
    ui_tooltip = "Multiplier applied to the final effect color before compositing.";
    ui_min = BRIGHTNESS_MIN; ui_max = BRIGHTNESS_MAX; ui_step = BRIGHTNESS_STEP;
    ui_category = "Effect Settings";
> = BRIGHTNESS_DEFAULT;

uniform float MeltIntensity <
    ui_type = "slider";
    ui_label = "Melt Intensity";
    ui_tooltip = "Amplitude of the fluid distortion warping. Higher values produce stronger swirls and flow.";
    ui_min = MELT_INTENSITY_MIN; ui_max = MELT_INTENSITY_MAX; ui_step = MELT_INTENSITY_STEP;
    ui_category = "Effect Settings";
> = MELT_INTENSITY_DEFAULT;

uniform bool UseOriginalColors <
    ui_label = "Use Original Math Colors";
    ui_tooltip = "If enabled, uses the original mathematical coloring method. Otherwise, uses palettes.";
    ui_category = AS_CAT_PALETTE;
> = true;

uniform float Saturation <
    ui_type = "slider";
    ui_label = "Original Color Saturation";
    ui_tooltip = "Saturation for original math colors (if Use Original Math Colors is enabled).";
    ui_min = SATURATION_MIN; ui_max = SATURATION_MAX; ui_step = SATURATION_STEP;
    ui_category = AS_CAT_PALETTE;
> = SATURATION_DEFAULT;

uniform float3 TintColor <
    ui_type = "color";
    ui_label = "Original Color Tint";
    ui_tooltip = "Tint for original math colors (if Use Original Math Colors is enabled).";
    ui_category = AS_CAT_PALETTE;
> = float3(1.0, 1.0, 1.0);

AS_PALETTE_SELECTION_UI(PalettePreset, "Color Palette", AS_PALETTE_NEON, AS_CAT_PALETTE)
AS_DECLARE_CUSTOM_PALETTE(MeltWave_, AS_CAT_PALETTE)

uniform float ColorCycleSpeed <
    ui_type = "slider";
    ui_label = "Palette Color Cycle Speed";
    ui_tooltip = "Controls how fast palette colors cycle. 0 = static. Only active if not using original math colors.";
    ui_min = COLOR_CYCLE_SPEED_MIN; ui_max = COLOR_CYCLE_SPEED_MAX; ui_step = COLOR_CYCLE_SPEED_STEP;
    ui_category = AS_CAT_PALETTE;
> = COLOR_CYCLE_SPEED_DEFAULT;

AS_BACKGROUND_COLOR_UI(BackgroundColor, float3(0.0, 0.0, 0.0), AS_CAT_PALETTE)

AS_AUDIO_UI(MeltWave_AudioSource, "Audio Source", AS_AUDIO_BASS, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(MeltWave_AudioMultiplier, "Audio Multiplier", AUDIO_MULTIPLIER_DEFAULT, AUDIO_MULTIPLIER_MAX, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(MeltWave_AudioTarget, "Melt Intensity\0Animation Speed\0Brightness\0Zoom\0All\0", 2)

AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, AS_CAT_ANIMATION)

AS_POSITION_SCALE_UI(Position, Scale)
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(RotationSnap, RotationFine)

AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

AS_DEBUG_UI("Off\0Show Audio Reactivity\0")

float2 ComputePattern(float2 coord, float time, float meltAmt, int iters)
{
    const float kTurn = 2.39996323;
    const float kFreqGrow = 1.07;
    const float kAmpDecay = 0.965;

    float2 p = coord;
    float amp = meltAmt;
    float freq = 1.0;
    float phase = time * 0.35;

    [loop]
    for (int i = 0; i < 80; ++i)
    {
        if (i >= iters) break;

        float a = kTurn * float(i);
        float cs = cos(a);
        float sn = sin(a);

        float2 q = float2(
            p.x * cs - p.y * sn,
            p.x * sn + p.y * cs
        );
        q += float2(cos(phase * 0.7 + a), sin(phase * 0.9 - a)) * 0.5;

        float2 warp = float2(
            sin(q.y * freq + phase + a),
            cos(q.x * freq - phase * 1.13 + a * 0.5)
        );

        p += warp * amp;

        amp  *= kAmpDecay;
        freq *= kFreqGrow;
        phase += 0.21;
    }

    return p;
}

float4 PS_MeltWave(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    AS_DEPTH_EARLY_RETURN(texcoord, EffectDepth)

    float audioReactivity = AS_audioModulate(1.0, MeltWave_AudioSource, MeltWave_AudioMultiplier, true, 0);

    float localMelt       = MeltIntensity;
    float localAnimSpeed  = AnimationSpeed;
    float localBrightness = Brightness;
    int   localIterations = Iterations;

    if (MeltWave_AudioTarget == 0 || MeltWave_AudioTarget == 4) localMelt       *= audioReactivity;
    if (MeltWave_AudioTarget == 1 || MeltWave_AudioTarget == 4) localAnimSpeed  *= audioReactivity;
    if (MeltWave_AudioTarget == 2 || MeltWave_AudioTarget == 4) localBrightness *= audioReactivity;
    if (MeltWave_AudioTarget == 3 || MeltWave_AudioTarget == 4) {
        int scaled = (int)round(float(localIterations) * audioReactivity);
        localIterations = clamp(scaled, ITERATIONS_MIN, ITERATIONS_MAX);
    }

    float time = AS_getAnimationTime(localAnimSpeed, AnimationKeyframe);

    float aspectRatio = ReShade::AspectRatio;
    float2 uv = AS_centeredUVWithAspect(texcoord, aspectRatio);

    float rot = -AS_getRotationRadians(RotationSnap, RotationFine);
    uv = AS_rotate2D(uv, rot);

    uv = AS_applyPositionAndScale(uv, Position, Scale);

    uv *= 3.5;

    if (aspectRatio >= 1.0) uv.x *= aspectRatio;
    else                    uv.x /= aspectRatio;

    float2 rawPattern = ComputePattern(uv, time, localMelt, localIterations);

    float3 processedColor;

    if (UseOriginalColors)
    {
        const float kThird = 2.0943951;
        float fieldA = rawPattern.x + rawPattern.y * 0.5;
        float fieldB = rawPattern.y - rawPattern.x * 0.5;
        float seed   = time * 0.25;

        float r = 0.5 + 0.5 * sin(fieldA + seed);
        float g = 0.5 + 0.5 * sin(fieldB + seed + kThird);
        float b = 0.5 + 0.5 * sin(fieldA - fieldB + seed + 2.0 * kThird);

        float3 col = float3(r, g, b);
        col = saturate(col * 1.1 - 0.05);

        col = AS_adjustSaturation(col, Saturation);
        col *= TintColor;

        processedColor = col;
    }
    else
    {
        float3 patternRGB = float3(
            0.5 + 0.5 * sin(rawPattern.x),
            0.5 + 0.5 * sin(rawPattern.y),
            0.5 + 0.5 * sin(rawPattern.x + rawPattern.y)
        );

        float t = dot(patternRGB, AS_LUMA_REC709);

        if (abs(ColorCycleSpeed) > AS_EPSILON)
        {
            t = frac(t + time * ColorCycleSpeed * 0.05);
        }
        else
        {
            t = saturate(t);
        }

        processedColor = AS_GET_PALETTE_COLOR(MeltWave_, PalettePreset, t);
    }

    processedColor *= localBrightness;

    float effectAlpha = saturate((processedColor.r + processedColor.g + processedColor.b) / 4.0 * 1.5);

    float3 blendedColor = AS_blendRGB(processedColor, BackgroundColor, BlendMode);
    float3 mixed = lerp(BackgroundColor, blendedColor, BlendAmount * effectAlpha);
    float4 outColor = float4(lerp(_as_originalColor.rgb, mixed, BlendAmount), _as_originalColor.a);

    if (DebugMode == 1)
    {
        float2 debugCenter = float2(0.1, 0.1);
        float2 dvec = texcoord - debugCenter;
        if (aspectRatio >= 1.0) dvec.x *= aspectRatio;
        else                    dvec.y /= aspectRatio;
        float dlen = length(dvec);
        float radius = 0.08;
        if (dlen <= radius)
        {
            float grey = saturate(audioReactivity);
            float edge = 1.0 - smoothstep(radius - 0.006, radius, dlen);
            outColor.rgb = lerp(outColor.rgb, float3(grey, grey, grey), edge);
        }
    }

    return outColor;
}

} // namespace AS_MeltWave

technique AS_BGX_MeltWave < ui_label = "[AS] BGX: Melt Wave"; ui_tooltip = "Generates a flowing, liquid-like psychedelic visual effect with customizable parameters and audio reactivity."; >
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = AS_MeltWave::PS_MeltWave;
    }
}

#endif
