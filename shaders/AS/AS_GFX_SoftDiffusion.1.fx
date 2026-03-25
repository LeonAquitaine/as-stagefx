/**
 * AS_GFX_SoftDiffusion.1.fx - Beauty/Portrait Soft Diffusion Filter
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Beauty/portrait softening filter that smooths midtones while preserving edges.
 * Creates the classic "skin glow" look used in portrait photography and glamour
 * cinematography — soft, flattering light without losing important detail.
 *
 * FEATURES:
 * - Luminance-weighted diffusion: midtones soften, shadows and highlights stay sharp
 * - Adjustable blur radius and midtone focus band
 * - Optional warm skin glow boost in softened areas
 * - Depth-aware mode to only soften foreground (character beauty filter)
 * - Audio-reactive soft strength
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Pass 1: Horizontal Gaussian blur of the scene into BlurH buffer.
 * 2. Pass 2: Vertical Gaussian blur from BlurH into SoftLayer buffer.
 * 3. Pass 3: Blend soft layer with original using a luminance-based midtone mask.
 *    Shadows and highlights remain crisp; midtones receive the softening.
 *
 * ===================================================================================
 */

#ifndef __AS_GFX_SoftDiffusion_1_fx
#define __AS_GFX_SoftDiffusion_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================

static const float SOFT_STRENGTH_MIN = 0.0;
static const float SOFT_STRENGTH_MAX = 1.0;
static const float SOFT_STRENGTH_STEP = 0.01;
static const float SOFT_STRENGTH_DEFAULT = 0.4;

static const int BLUR_RADIUS_MIN = 2;
static const int BLUR_RADIUS_MAX = 25;
static const int BLUR_RADIUS_DEFAULT = 8;

static const float MIDTONE_FOCUS_MIN = 0.5;
static const float MIDTONE_FOCUS_MAX = 4.0;
static const float MIDTONE_FOCUS_STEP = 0.05;
static const float MIDTONE_FOCUS_DEFAULT = 1.5;

static const float HIGHLIGHT_PRESERVE_MIN = 0.0;
static const float HIGHLIGHT_PRESERVE_MAX = 1.0;
static const float HIGHLIGHT_PRESERVE_STEP = 0.01;
static const float HIGHLIGHT_PRESERVE_DEFAULT = 0.8;

static const float SHADOW_PRESERVE_MIN = 0.0;
static const float SHADOW_PRESERVE_MAX = 1.0;
static const float SHADOW_PRESERVE_STEP = 0.01;
static const float SHADOW_PRESERVE_DEFAULT = 0.7;

static const float SKIN_GLOW_MIN = 0.0;
static const float SKIN_GLOW_MAX = 0.5;
static const float SKIN_GLOW_STEP = 0.01;
static const float SKIN_GLOW_DEFAULT = 0.1;

// Compile-time max for blur loop
static const int MAX_BLUR_RADIUS = 25;

// ============================================================================
// RENDER TARGETS
// ============================================================================

texture SoftDiffusion_BlurH { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
texture SoftDiffusion_SoftLayer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };

sampler SoftDiffusion_SampBlurH { Texture = SoftDiffusion_BlurH; AddressU = CLAMP; AddressV = CLAMP; };
sampler SoftDiffusion_SampSoftLayer { Texture = SoftDiffusion_SoftLayer; AddressU = CLAMP; AddressV = CLAMP; };

// ============================================================================
// SHADER DESCRIPTOR
// ============================================================================

uniform int as_shader_descriptor < ui_type = "radio"; ui_label = " "; ui_text = "\nBeauty/portrait soft diffusion filter — smooths midtones while preserving edges.\nCreates the classic skin glow look from glamour photography.\n\nAS StageFX | Soft Diffusion by Leon Aquitaine\n"; > = 0;

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// -- Diffusion Controls --
uniform float SoftStrength < ui_type = "slider"; ui_label = "Soft Strength"; ui_tooltip = "How much softening is applied to midtone areas.\n0.0 = no softening, 1.0 = full diffusion in midtones."; ui_min = SOFT_STRENGTH_MIN; ui_max = SOFT_STRENGTH_MAX; ui_step = SOFT_STRENGTH_STEP; ui_category = AS_CAT_APPEARANCE; > = SOFT_STRENGTH_DEFAULT;
uniform int BlurRadius < ui_type = "slider"; ui_label = "Blur Radius"; ui_tooltip = "Size of the softening blur kernel.\nLarger values create broader, dreamier softening."; ui_min = BLUR_RADIUS_MIN; ui_max = BLUR_RADIUS_MAX; ui_category = AS_CAT_APPEARANCE; > = BLUR_RADIUS_DEFAULT;
uniform float MidtoneFocus < ui_type = "slider"; ui_label = "Midtone Focus"; ui_tooltip = "Controls how narrow the midtone softening band is.\nHigher values restrict softening to only mid-luminance pixels."; ui_min = MIDTONE_FOCUS_MIN; ui_max = MIDTONE_FOCUS_MAX; ui_step = MIDTONE_FOCUS_STEP; ui_category = AS_CAT_APPEARANCE; > = MIDTONE_FOCUS_DEFAULT;
uniform float HighlightPreserve < ui_type = "slider"; ui_label = "Highlight Preserve"; ui_tooltip = "How much to keep highlights crisp and unaffected.\nHigher values preserve more highlight detail."; ui_min = HIGHLIGHT_PRESERVE_MIN; ui_max = HIGHLIGHT_PRESERVE_MAX; ui_step = HIGHLIGHT_PRESERVE_STEP; ui_category = AS_CAT_APPEARANCE; > = HIGHLIGHT_PRESERVE_DEFAULT;
uniform float ShadowPreserve < ui_type = "slider"; ui_label = "Shadow Preserve"; ui_tooltip = "How much to keep shadows crisp and unaffected.\nHigher values preserve more shadow detail."; ui_min = SHADOW_PRESERVE_MIN; ui_max = SHADOW_PRESERVE_MAX; ui_step = SHADOW_PRESERVE_STEP; ui_category = AS_CAT_APPEARANCE; > = SHADOW_PRESERVE_DEFAULT;
uniform float SkinGlow < ui_type = "slider"; ui_label = "Skin Glow"; ui_tooltip = "Adds a subtle warm luminance boost in softened areas.\nCreates a gentle radiant glow effect."; ui_min = SKIN_GLOW_MIN; ui_max = SKIN_GLOW_MAX; ui_step = SKIN_GLOW_STEP; ui_category = AS_CAT_APPEARANCE; > = SKIN_GLOW_DEFAULT;
uniform bool DepthAware < ui_type = "checkbox"; ui_label = "Depth-Aware"; ui_tooltip = "When enabled, only softens the foreground (character).\nBackground stays sharp for a selective beauty filter."; ui_category = AS_CAT_APPEARANCE; > = false;

// -- Audio Reactivity --
AS_AUDIO_UI(SoftDiff_AudioSource, "Audio Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(SoftDiff_AudioMultiplier, "Audio Intensity", 1.0, 2.0, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(SoftDiff_AudioTarget, "None\0Soft Strength\0", 0)

// -- Stage --
AS_STAGEDEPTH_UI(EffectDepth)

// -- Final Mix --
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// -- Debug --
AS_DEBUG_UI("Off\0Blur Layer\0Midtone Mask\0Depth Mask\0")

// ============================================================================
// PIXEL SHADERS
// ============================================================================

// Pass 1: Horizontal Gaussian blur
float4 PS_BlurHorizontal(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float2 pixelSize = float2(1.0 / BUFFER_WIDTH, 0.0);
    float3 result = float3(0.0, 0.0, 0.0);
    float totalWeight = 0.0;

    for (int i = 0; i < MAX_BLUR_RADIUS * 2 + 1; i++)
    {
        if (i > BlurRadius * 2) break;

        int offset = i - BlurRadius;
        float2 sampleUV = texcoord + pixelSize * float(offset);

        // Gaussian weight approximation
        float weight = exp(-0.5 * float(offset * offset) / max(float(BlurRadius * BlurRadius) * 0.25, AS_EPSILON));

        result += tex2Dlod(ReShade::BackBuffer, float4(sampleUV, 0, 0)).rgb * weight;
        totalWeight += weight;
    }

    return float4(result / max(totalWeight, AS_EPSILON), 1.0);
}

// Pass 2: Vertical Gaussian blur
float4 PS_BlurVertical(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float2 pixelSize = float2(0.0, 1.0 / BUFFER_HEIGHT);
    float3 result = float3(0.0, 0.0, 0.0);
    float totalWeight = 0.0;

    for (int i = 0; i < MAX_BLUR_RADIUS * 2 + 1; i++)
    {
        if (i > BlurRadius * 2) break;

        int offset = i - BlurRadius;
        float2 sampleUV = texcoord + pixelSize * float(offset);

        float weight = exp(-0.5 * float(offset * offset) / max(float(BlurRadius * BlurRadius) * 0.25, AS_EPSILON));

        result += tex2Dlod(SoftDiffusion_SampBlurH, float4(sampleUV, 0, 0)).rgb * weight;
        totalWeight += weight;
    }

    return float4(result / max(totalWeight, AS_EPSILON), 1.0);
}

// Pass 3: Luminance-weighted blend
float4 PS_SoftDiffusion(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float3 softLayer = tex2D(SoftDiffusion_SampSoftLayer, texcoord).rgb;

    // Depth check
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth)
    {
        if (DebugMode == 0) return originalColor;
    }

    // Audio reactivity
    float audioMod = AS_audioModulate(1.0, SoftDiff_AudioSource, SoftDiff_AudioMultiplier, true, 0);
    float strengthFinal = SoftStrength;
    if (SoftDiff_AudioTarget == 1) strengthFinal *= audioMod;

    // Compute luminance for midtone mask
    float luma = dot(originalColor.rgb, AS_LUMA_REC709);

    // Midtone mask: peaks at luma=0.5, falls to zero at black and white
    float midtoneMask = 1.0 - abs(luma - 0.5) * 2.0;
    midtoneMask = saturate(midtoneMask);
    midtoneMask = pow(midtoneMask, MidtoneFocus);

    // Reduce mask in highlights and shadows based on preserve controls
    float highlightFade = 1.0 - smoothstep(0.6, 0.9, luma) * HighlightPreserve;
    float shadowFade = 1.0 - smoothstep(0.1, 0.4, 1.0 - luma) * ShadowPreserve;
    midtoneMask *= highlightFade * shadowFade;

    // Depth-aware: restrict softening to foreground
    float depthMask = 1.0;
    if (DepthAware)
    {
        depthMask = 1.0 - smoothstep(0.0, 0.5, depth);
    }

    // Apply skin glow: subtle warm luminance boost in softened areas
    float3 glowLayer = softLayer;
    if (SkinGlow > 0.0)
    {
        float softLuma = dot(softLayer, AS_LUMA_REC709);
        // Warm tint: slightly boost red and green relative to blue
        float3 warmBoost = float3(1.02, 1.01, 0.98) * (1.0 + SkinGlow);
        glowLayer = softLayer * warmBoost + float3(SkinGlow * 0.05, SkinGlow * 0.03, 0.0);
    }

    // Blend soft layer with original
    float blendFactor = midtoneMask * strengthFinal * depthMask;
    float3 diffused = lerp(originalColor.rgb, glowLayer, blendFactor);

    // Debug views
    if (DebugMode == 1) return float4(softLayer, 1.0);
    if (DebugMode == 2) return float4(midtoneMask.xxx, 1.0);
    if (DebugMode == 3) return float4(depthMask.xxx, 1.0);

    // Final composite
    float3 result = AS_composite(diffused, originalColor.rgb, BlendMode, BlendAmount);

    return float4(result, originalColor.a);
}

// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_GFX_SoftDiffusion
<
    ui_label = "[AS] GFX: Soft Diffusion";
    ui_tooltip = "Beauty/portrait soft diffusion filter.\n"
                 "Smooths midtones while preserving edges for a skin glow look.\n"
                 "Performance: Medium (3-pass Gaussian blur)";
>
{
    pass BlurH
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_BlurHorizontal;
        RenderTarget = SoftDiffusion_BlurH;
    }
    pass BlurV
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_BlurVertical;
        RenderTarget = SoftDiffusion_SoftLayer;
    }
    pass Combine
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SoftDiffusion;
    }
}

#endif // __AS_GFX_SoftDiffusion_1_fx
