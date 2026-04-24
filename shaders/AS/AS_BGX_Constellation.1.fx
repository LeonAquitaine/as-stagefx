// AS_BGX_Constellation.1.fx
// Leon Aquitaine - CC BY 4.0

#ifndef __AS_BGX_Constellation_1_fx
#define __AS_BGX_Constellation_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Noise.1.fxh"

namespace AS_Constellation {

static const float LINE_CORE_THICKNESS_MIN      = 0.001f;
static const float LINE_CORE_THICKNESS_MAX      = 0.05f;
static const float LINE_CORE_THICKNESS_DEFAULT  = 0.01f;

static const float LINE_FALLOFF_WIDTH_MIN       = 0.001f;
static const float LINE_FALLOFF_WIDTH_MAX       = 0.1f;
static const float LINE_FALLOFF_WIDTH_DEFAULT   = 0.02f;

static const float LINE_OVERALL_BRIGHTNESS_MIN      = 0.0f;
static const float LINE_OVERALL_BRIGHTNESS_MAX      = 10.0f;
static const float LINE_OVERALL_BRIGHTNESS_DEFAULT  = 1.0f;

static const float LINE_LENGTH_MOD_STRENGTH_MIN     = 0.0f;
static const float LINE_LENGTH_MOD_STRENGTH_MAX     = 1.0f;
static const float LINE_LENGTH_MOD_STRENGTH_DEFAULT = 1.0f;

static const float SPARKLE_SHARPNESS_MIN        = 1.0f;
static const float SPARKLE_SHARPNESS_MAX        = 50.0f;
static const float SPARKLE_SHARPNESS_DEFAULT    = 10.0f;

static const float SPARKLE_BASE_INTENSITY_MIN      = 0.0f;
static const float SPARKLE_BASE_INTENSITY_MAX      = 5.0f;
static const float SPARKLE_BASE_INTENSITY_DEFAULT  = 1.0f;

static const float SPARKLE_TWINKLE_SPEED_MIN       = 0.0f;
static const float SPARKLE_TWINKLE_SPEED_MAX       = 50.0f;
static const float SPARKLE_TWINKLE_SPEED_DEFAULT   = 10.0f;

static const float SPARKLE_TWINKLE_MAGNITUDE_MIN      = 0.0f;
static const float SPARKLE_TWINKLE_MAGNITUDE_MAX      = 1.0f;
static const float SPARKLE_TWINKLE_MAGNITUDE_DEFAULT  = 1.0f;

static const float SPARKLE_PHASE_VARIATION_MIN      = 0.0f;
static const float SPARKLE_PHASE_VARIATION_MAX      = 50.0f;
static const float SPARKLE_PHASE_VARIATION_DEFAULT  = 10.0f;

static const float PALETTE_TIME_SCALE_MIN       = 0.0f;
static const float PALETTE_TIME_SCALE_MAX       = 100.0f;
static const float PALETTE_TIME_SCALE_DEFAULT   = 20.0f;

static const float PALETTE_COLOR_AMPLITUDE_MIN      = 0.0f;
static const float PALETTE_COLOR_AMPLITUDE_MAX      = 1.0f;
static const float PALETTE_COLOR_AMPLITUDE_DEFAULT  = 0.25f;

static const float PALETTE_COLOR_BIAS_MIN           = 0.0f;
static const float PALETTE_COLOR_BIAS_MAX           = 1.0f;
static const float PALETTE_COLOR_BIAS_DEFAULT       = 0.75f;

static const float ZOOM_MIN     = 0.1f;
static const float ZOOM_MAX     = 5.0f;
static const float ZOOM_DEFAULT = 1.0f;

static const float AUDIO_GAIN_ZOOM_MAX              = 2.0f;
static const float AUDIO_GAIN_ZOOM_DEFAULT          = 0.0f;

static const float AUDIO_GAIN_GRADIENT_MAX          = 5.0f;
static const float AUDIO_GAIN_GRADIENT_DEFAULT      = 1.0f;

static const float AUDIO_GAIN_LINE_BRIGHTNESS_MAX      = 2.0f;
static const float AUDIO_GAIN_LINE_BRIGHTNESS_DEFAULT  = 0.0f;

static const float AUDIO_GAIN_LINE_FALLOFF_MAX       = 2.0f;
static const float AUDIO_GAIN_LINE_FALLOFF_DEFAULT   = 0.0f;

static const float AUDIO_GAIN_SPARKLE_MAG_MAX        = 3.0f;
static const float AUDIO_GAIN_SPARKLE_MAG_DEFAULT    = 0.0f;

static const int   LAYER_COUNT              = 4;
static const float LAYER_SCALE_STEP         = 1.6f;
static const float LAYER_CYCLE_PERIOD       = 14.0f;
static const float LAYER_CYCLE_OFFSET       = 1.0f / (float)LAYER_COUNT;
static const float STAR_DRIFT_SPEED         = 0.07f;
static const float STAR_JITTER_AMP          = 0.35f;
static const float FIELD_ROTATION_SPEED     = 0.03f;
static const float PALETTE_MAIN_TIME_SCALE  = 0.02f;
static const float LINE_PREFERRED_LENGTH    = 1.0f;

uniform int as_shader_descriptor <
    ui_type = "radio";
    ui_label = " ";
    ui_text = "\nConstellation\n\n";
>;

uniform float LineCoreThickness <
    ui_type = "drag";
    ui_label = "Core Thickness";
    ui_min = LINE_CORE_THICKNESS_MIN;
    ui_max = LINE_CORE_THICKNESS_MAX;
    ui_step = 0.001f;
    ui_tooltip = "Width of the solid center of each constellation line. Increase for bolder, more visible connections.";
    ui_category = "Lines";
> = LINE_CORE_THICKNESS_DEFAULT;

uniform float LineFalloffWidth <
    ui_type = "drag";
    ui_label = "Edge Softness";
    ui_min = LINE_FALLOFF_WIDTH_MIN;
    ui_max = LINE_FALLOFF_WIDTH_MAX;
    ui_step = 0.001f;
    ui_tooltip = "How gradually constellation lines fade at their edges. Higher values create softer, more diffused lines.";
    ui_category = "Lines";
> = LINE_FALLOFF_WIDTH_DEFAULT;

uniform float LineOverallBrightness <
    ui_type = "drag";
    ui_label = "Overall Brightness";
    ui_min = LINE_OVERALL_BRIGHTNESS_MIN;
    ui_max = LINE_OVERALL_BRIGHTNESS_MAX;
    ui_step = 0.1f;
    ui_tooltip = "Master brightness multiplier for all constellation lines. Increase to make the line network more prominent.";
    ui_category = "Lines";
> = LINE_OVERALL_BRIGHTNESS_DEFAULT;

uniform float LineLengthModStrength <
    ui_type = "drag";
    ui_label = "Length Affects Brightness";
    ui_min = LINE_LENGTH_MOD_STRENGTH_MIN;
    ui_max = LINE_LENGTH_MOD_STRENGTH_MAX;
    ui_step = 0.01f;
    ui_tooltip = "How much a line's length influences its brightness. At 1.0, shorter lines appear brighter than longer ones.";
    ui_category = "Lines";
> = LINE_LENGTH_MOD_STRENGTH_DEFAULT;

uniform float SparkleSharpness <
    ui_type = "drag";
    ui_label = "Sharpness";
    ui_min = SPARKLE_SHARPNESS_MIN;
    ui_max = SPARKLE_SHARPNESS_MAX;
    ui_step = 0.1f;
    ui_tooltip = "How focused each star point appears. Higher values create tiny pinpoint stars; lower values make broader glows.";
    ui_category = "Stars";
> = SPARKLE_SHARPNESS_DEFAULT;

uniform float SparkleBaseIntensity <
    ui_type = "drag";
    ui_label = "Base Intensity";
    ui_min = SPARKLE_BASE_INTENSITY_MIN;
    ui_max = SPARKLE_BASE_INTENSITY_MAX;
    ui_step = 0.01f;
    ui_tooltip = "Base brightness of each star before twinkling is applied. Zero hides the stars completely.";
    ui_category = "Stars";
> = SPARKLE_BASE_INTENSITY_DEFAULT;

uniform float SparkleTwinkleSpeed <
    ui_type = "drag";
    ui_label = "Twinkle Speed";
    ui_min = SPARKLE_TWINKLE_SPEED_MIN;
    ui_max = SPARKLE_TWINKLE_SPEED_MAX;
    ui_step = 0.1f;
    ui_tooltip = "How fast the stars flicker on and off. Higher values produce rapid twinkling.";
    ui_category = "Stars";
> = SPARKLE_TWINKLE_SPEED_DEFAULT;

uniform float SparkleTwinkleMagnitude <
    ui_type = "drag";
    ui_label = "Twinkle Amount";
    ui_min = SPARKLE_TWINKLE_MAGNITUDE_MIN;
    ui_max = SPARKLE_TWINKLE_MAGNITUDE_MAX;
    ui_step = 0.01f;
    ui_tooltip = "Strength of the twinkling effect. At zero stars shine steadily; at maximum they pulse dramatically.";
    ui_category = "Stars";
> = SPARKLE_TWINKLE_MAGNITUDE_DEFAULT;

uniform float SparklePhaseVariation <
    ui_type = "drag";
    ui_label = "Twinkle Variation";
    ui_min = SPARKLE_PHASE_VARIATION_MIN;
    ui_max = SPARKLE_PHASE_VARIATION_MAX;
    ui_step = 0.1f;
    ui_tooltip = "How differently each star twinkles relative to its neighbors. Higher values make each star blink independently.";
    ui_category = "Stars";
> = SPARKLE_PHASE_VARIATION_DEFAULT;

uniform float PaletteTimeScale <
    ui_type = "drag";
    ui_label = "Palette Animation Speed";
    ui_min = PALETTE_TIME_SCALE_MIN;
    ui_max = PALETTE_TIME_SCALE_MAX;
    ui_step = 0.1f;
    ui_tooltip = "How fast the color palette shifts over time. Zero freezes the colors; higher values cycle quickly.";
    ui_category = AS_CAT_PALETTE;
> = PALETTE_TIME_SCALE_DEFAULT;

uniform float3 PaletteColorPhaseFactors <
    ui_type = "drag";
    ui_label = "Palette Color Phase Factors (RGB)";
    ui_min = 0.0f;
    ui_max = 1.0f;
    ui_step = 0.001f;
    ui_tooltip = "Controls the phase offset for each color channel, determining which colors appear at different times.";
    ui_category = AS_CAT_PALETTE;
> = float3(0.345f, 0.543f, 0.682f);

uniform float PaletteColorAmplitude <
    ui_type = "drag";
    ui_label = "Palette Color Amplitude";
    ui_min = PALETTE_COLOR_AMPLITUDE_MIN;
    ui_max = PALETTE_COLOR_AMPLITUDE_MAX;
    ui_step = 0.01f;
    ui_tooltip = "Range of color variation in the palette. Higher values produce more vivid color swings.";
    ui_category = AS_CAT_PALETTE;
> = PALETTE_COLOR_AMPLITUDE_DEFAULT;

uniform float PaletteColorBias <
    ui_type = "drag";
    ui_label = "Palette Color Bias (Brightness)";
    ui_min = PALETTE_COLOR_BIAS_MIN;
    ui_max = PALETTE_COLOR_BIAS_MAX;
    ui_step = 0.01f;
    ui_tooltip = "Base brightness offset for the palette. Higher values make the overall color scheme lighter and warmer.";
    ui_category = AS_CAT_PALETTE;
> = PALETTE_COLOR_BIAS_DEFAULT;

AS_ANIMATION_UI(TimeSpeed, TimeKeyframe, "Animation")

uniform float Zoom <
    ui_type = "drag";
    ui_label = "Zoom";
    ui_min = ZOOM_MIN;
    ui_max = ZOOM_MAX;
    ui_step = 0.01f;
    ui_tooltip = "Adjust to zoom in or out of the pattern.";
    ui_category = AS_CAT_ANIMATION;
> = ZOOM_DEFAULT;

AS_AUDIO_UI(MasterAudioSource, "Audio Source", AS_AUDIO_BASS, "Audio Reactivity")
AS_AUDIO_GAIN_UI(AudioGain_GradientEffect,    "Gradient",         AUDIO_GAIN_GRADIENT_MAX,        AUDIO_GAIN_GRADIENT_DEFAULT)
AS_AUDIO_GAIN_UI(AudioGain_LineBrightness,    "Line Brightness",  AUDIO_GAIN_LINE_BRIGHTNESS_MAX, AUDIO_GAIN_LINE_BRIGHTNESS_DEFAULT)
AS_AUDIO_GAIN_UI(AudioGain_LineFalloff,       "Line Softness",    AUDIO_GAIN_LINE_FALLOFF_MAX,    AUDIO_GAIN_LINE_FALLOFF_DEFAULT)
AS_AUDIO_GAIN_UI(AudioGain_SparkleMagnitude,  "Sparkle Amount",   AUDIO_GAIN_SPARKLE_MAG_MAX,     AUDIO_GAIN_SPARKLE_MAG_DEFAULT)
AS_AUDIO_GAIN_UI(AudioGain_Zoom,              "Zoom",             AUDIO_GAIN_ZOOM_MAX,            AUDIO_GAIN_ZOOM_DEFAULT)

AS_STAGEDEPTH_UI(EffectDepth)

AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

float2 starPositionInCell(float2 cell, float time)
{
    float2 h = AS_hash22(cell);
    float2 drifth = AS_hash22(cell + float2(17.17f, 31.91f));
    float2 driftPhase = drifth * AS_TWO_PI;

    float2 jitter = (h - 0.5f) * 2.0f * STAR_JITTER_AMP;

    float2 drift;
    drift.x = sin(time * STAR_DRIFT_SPEED + driftPhase.x) * 0.08f;
    drift.y = cos(time * STAR_DRIFT_SPEED * 0.87f + driftPhase.y) * 0.08f;

    return float2(0.5f, 0.5f) + jitter + drift;
}

float distToSegment(float2 p, float2 a, float2 b)
{
    float2 ab = b - a;
    float denom = max(dot(ab, ab), AS_EPSILON);
    float t = saturate(dot(p - a, ab) / denom);
    float2 q = a + ab * t;
    return length(p - q);
}

float lineLengthWeight(float len)
{
    float d = (len - LINE_PREFERRED_LENGTH);
    float w = exp(-d * d * 2.2f);
    return saturate(w);
}

float starGlow(float2 p, float2 starPos, float sharpness)
{
    float d = length(p - starPos);
    return 1.0f / (1.0f + pow(d * sharpness, 2.0f));
}

float starTwinkle(float2 cell, float time, float speed, float magnitude, float phaseVar)
{
    float2 h = AS_hash22(cell + float2(3.77f, 9.13f));
    float phase = (h.x - 0.5f) * 2.0f * phaseVar + h.y * AS_TWO_PI;
    float t = sin(time * speed + phase);
    return 1.0f + t * magnitude;
}

float renderLayer(float2 uv,
                  float  time,
                  float  coreThickness,
                  float  falloffWidth,
                  float  lineLenMod,
                  float  sharpness,
                  float  baseIntensity,
                  float  twinkleSpeed,
                  float  twinkleMag,
                  float  phaseVar)
{
    float2 cellF = floor(uv);
    float2 local = uv - cellF;

    float acc = 0.0f;

    float2 hubCell = cellF;
    float2 hubPos  = starPositionInCell(hubCell, time);

    [unroll]
    for (int oy = -1; oy <= 1; ++oy)
    {
        [unroll]
        for (int ox = -1; ox <= 1; ++ox)
        {
            float2 off = float2((float)ox, (float)oy);
            float2 nCell = hubCell + off;
            float2 nPosLocal = starPositionInCell(nCell, time) + off;

            float glow = starGlow(local, nPosLocal, sharpness);
            float tw   = starTwinkle(nCell, time, twinkleSpeed, twinkleMag, phaseVar);
            acc += baseIntensity * glow * tw;

            if (ox != 0 || oy != 0)
            {
                float d = distToSegment(local, hubPos, nPosLocal);
                float len = length(nPosLocal - hubPos);

                float lineBright = 1.0f - smoothstep(coreThickness,
                                                    coreThickness + max(falloffWidth, 0.001f),
                                                    d);

                float wLen = lineLengthWeight(len);
                float lenMix = lerp(1.0f, wLen, saturate(lineLenMod));

                float hubTw = starTwinkle(hubCell, time, twinkleSpeed, twinkleMag * 0.5f, phaseVar);
                float nTw   = starTwinkle(nCell,    time, twinkleSpeed, twinkleMag * 0.5f, phaseVar);
                float endpointTw = 0.5f * (hubTw + nTw);

                acc += lineBright * lenMix * endpointTw;
            }
        }
    }

    return acc;
}

float layerEnvelope(int layerIdx, float time)
{
    float phase = frac(time / LAYER_CYCLE_PERIOD + (float)layerIdx * LAYER_CYCLE_OFFSET);
    float tri = 1.0f - abs(phase * 2.0f - 1.0f);
    return smoothstep(0.0f, 1.0f, tri);
}

float4 PS_Constellation(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);

    float time = AS_getAnimationTime(TimeSpeed, TimeKeyframe);

    float2 pixelCoord = texcoord * ReShade::ScreenSize;
    float2 centered = (pixelCoord - ReShade::ScreenSize * 0.5f) / ReShade::ScreenSize.y;

    float audioLevel = AS_audioLevelFromSource(MasterAudioSource);

    float audioBoostedZoom = Zoom * (1.0f + audioLevel * AudioGain_Zoom);
    float2 uv = centered / max(audioBoostedZoom, AS_EPSILON);

    float angle = time * FIELD_ROTATION_SPEED;
    float ca = cos(angle);
    float sa = sin(angle);
    uv = float2(uv.x * ca - uv.y * sa, uv.x * sa + uv.y * ca);

    float audioBoostedFalloff    = max(0.001f,
                                       LineFalloffWidth * (1.0f + audioLevel * AudioGain_LineFalloff));
    float audioBoostedSparkleMag = SparkleTwinkleMagnitude *
                                       (1.0f + audioLevel * AudioGain_SparkleMagnitude);
    float audioBoostedLineBright = LineOverallBrightness *
                                       (1.0f + audioLevel * AudioGain_LineBrightness);

    float accumulated = 0.0f;
    [unroll]
    for (int li = 0; li < LAYER_COUNT; ++li)
    {
        float exponent = (float)li - 0.5f * (float)(LAYER_COUNT - 1);
        float layerScale = pow(LAYER_SCALE_STEP, exponent);

        float cellDensity = 6.0f * layerScale;

        float2 layerOffset = float2((float)li * 0.37f, (float)li * 0.19f);

        float2 layerUV = uv * cellDensity + layerOffset;

        float env = layerEnvelope(li, time);

        float layerContrib = renderLayer(
            layerUV,
            time + (float)li * 3.1f,
            LineCoreThickness,
            audioBoostedFalloff,
            LineLengthModStrength,
            SparkleSharpness,
            SparkleBaseIntensity,
            SparkleTwinkleSpeed,
            audioBoostedSparkleMag,
            SparklePhaseVariation
        );

        float layerBrightScale = 1.0f / (0.5f + (float)li * 0.35f);

        accumulated += env * layerContrib * layerBrightScale;
    }

    float mainAnimationTime = time * PALETTE_MAIN_TIME_SCALE;
    float3 palette = sin(mainAnimationTime * PaletteTimeScale * PaletteColorPhaseFactors)
                        * PaletteColorAmplitude + PaletteColorBias;

    float3 finalColor = accumulated * audioBoostedLineBright * palette;

    float audioModulatedGradient = audioLevel * AudioGain_GradientEffect;
    float gradientEffect = (centered.y) * audioModulatedGradient * 2.0f;
    finalColor -= gradientEffect * palette;

    float depthMask = AS_isInFrontOfStage(texcoord, EffectDepth) ? 0.0f : 1.0f;

    return float4(AS_composite(saturate(finalColor), originalColor.rgb, BlendMode, BlendStrength * depthMask), 1.0f);
}

} // namespace AS_Constellation

technique AS_BGX_Constellation <
    ui_label = "[AS] BGX: Constellation";
    ui_tooltip = "Dynamic cosmic constellation pattern with twinkling stars and connecting Lines.\n"
                 "Perfect for cosmic, night sky, or abstract network visualizations.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = AS_Constellation::PS_Constellation;
    }
}

#endif
