/**
 * AS_GFX_LightWrap.1.fx - Depth-Based Light Wrap Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Bleeds bright background color around the foreground subject's silhouette edges,
 * creating the illusion that the background is actually illuminating the character.
 * This is the compositing technique used in professional VFX to integrate subjects
 * into their environment. Essential when using BGX background replacements.
 *
 * FEATURES:
 * - Depth-based foreground/background separation using standard stage depth
 * - Separable Gaussian blur for smooth, natural light bleeding
 * - Luminance threshold to only wrap bright backgrounds
 * - Three color modes: Background Color, Tint Color, or Palette
 * - Audio-reactive wrap intensity, width, and threshold
 * - Adjustable falloff curve for wrap edge character
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. (Pass 1) Isolate background: foreground pixels (depth < threshold) output black,
 *    background pixels output their scene color (gated by luminance threshold).
 *    Result stored in an intermediate texture.
 * 2. (Pass 2) Horizontal Gaussian blur of the isolated background, spreading
 *    background color into the foreground region.
 * 3. (Pass 3) Vertical Gaussian blur of the horizontal result, then composite
 *    the blurred wrap with the original scene using Screen blend (or user choice).
 *
 * ===================================================================================
 */

#ifndef __AS_GFX_LightWrap_1_fx
#define __AS_GFX_LightWrap_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================

static const float WRAP_WIDTH_MIN = 1.0;
static const float WRAP_WIDTH_MAX = 40.0;
static const float WRAP_WIDTH_STEP = 0.5;
static const float WRAP_WIDTH_DEFAULT = 8.0;

static const float WRAP_INTENSITY_MIN = 0.0;
static const float WRAP_INTENSITY_MAX = 2.0;
static const float WRAP_INTENSITY_STEP = 0.01;
static const float WRAP_INTENSITY_DEFAULT = 0.6;

static const float LUMA_THRESHOLD_MIN = 0.0;
static const float LUMA_THRESHOLD_MAX = 1.0;
static const float LUMA_THRESHOLD_STEP = 0.01;
static const float LUMA_THRESHOLD_DEFAULT = 0.3;

static const float WRAP_FALLOFF_MIN = 0.2;
static const float WRAP_FALLOFF_MAX = 4.0;
static const float WRAP_FALLOFF_STEP = 0.05;
static const float WRAP_FALLOFF_DEFAULT = 1.5;

static const float SURFACE_REACH_MIN = 0.0;
static const float SURFACE_REACH_MAX = 1.0;
static const float SURFACE_REACH_STEP = 0.01;
static const float SURFACE_REACH_DEFAULT = 0.3;

static const float SURFACE_SHARPNESS_MIN = 0.5;
static const float SURFACE_SHARPNESS_MAX = 8.0;
static const float SURFACE_SHARPNESS_STEP = 0.1;
static const float SURFACE_SHARPNESS_DEFAULT = 2.0;

static const int COLOR_MODE_BACKGROUND = 0;
static const int COLOR_MODE_TINT = 1;
static const int COLOR_MODE_PALETTE = 2;

static const float BLUR_AXIS_SCALE = 2.0;

// ============================================================================
// TEXTURES & SAMPLERS
// ============================================================================

texture LightWrap_MaskBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler LightWrap_MaskSampler { Texture = LightWrap_MaskBuffer; };

texture LightWrap_BlurBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler LightWrap_BlurSampler { Texture = LightWrap_BlurBuffer; };

// ============================================================================
// SHADER DESCRIPTOR
// ============================================================================

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// -- Wrap Appearance --

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform float WrapWidth < ui_type = "slider"; ui_label = "Wrap Width"; ui_tooltip = "How far the background light bleeds around the subject edges. Higher values create a wider, softer wrap."; ui_min = WRAP_WIDTH_MIN; ui_max = WRAP_WIDTH_MAX; ui_step = WRAP_WIDTH_STEP; ui_category = "Wrap Appearance"; > = WRAP_WIDTH_DEFAULT;
uniform float WrapIntensity < ui_type = "slider"; ui_label = "Wrap Intensity"; ui_tooltip = "Strength of the light wrap effect. Higher values create a more visible bleed."; ui_min = WRAP_INTENSITY_MIN; ui_max = WRAP_INTENSITY_MAX; ui_step = WRAP_INTENSITY_STEP; ui_category = "Wrap Appearance"; > = WRAP_INTENSITY_DEFAULT;
uniform float LuminanceThreshold < ui_type = "slider"; ui_label = "Luminance Threshold"; ui_tooltip = "Minimum background brightness required to generate wrap. Dark backgrounds produce no bleed. Set to 0 to wrap all backgrounds."; ui_min = LUMA_THRESHOLD_MIN; ui_max = LUMA_THRESHOLD_MAX; ui_step = LUMA_THRESHOLD_STEP; ui_category = "Wrap Appearance"; > = LUMA_THRESHOLD_DEFAULT;
uniform float WrapFalloff < ui_type = "slider"; ui_label = "Edge Prominence"; ui_tooltip = "How prominent the wrap is at the silhouette edge.\nHigher = stronger, broader edge glow. Lower = subtle, tight edge only."; ui_min = WRAP_FALLOFF_MIN; ui_max = WRAP_FALLOFF_MAX; ui_step = WRAP_FALLOFF_STEP; ui_category = "Wrap Appearance"; > = WRAP_FALLOFF_DEFAULT;

// -- Surface Reflection --
uniform float SurfaceReach < ui_type = "slider"; ui_label = "Surface Reach"; ui_tooltip = "How far the wrap extends along inclined surfaces.\n0.0 = depth edge only (flat bleed).\nHigher = light spreads along curved surfaces like a crescent moon."; ui_min = SURFACE_REACH_MIN; ui_max = SURFACE_REACH_MAX; ui_step = SURFACE_REACH_STEP; ui_category = "Wrap Appearance"; > = SURFACE_REACH_DEFAULT;
uniform float SurfaceSharpness < ui_type = "slider"; ui_label = "Surface Sharpness"; ui_tooltip = "How tightly light concentrates on the sharpest edges.\nHigher = tight crescent. Lower = broad, gradual reflection across the surface."; ui_min = SURFACE_SHARPNESS_MIN; ui_max = SURFACE_SHARPNESS_MAX; ui_step = SURFACE_SHARPNESS_STEP; ui_category = "Wrap Appearance"; > = SURFACE_SHARPNESS_DEFAULT;

// -- Foreground Override --
uniform int ForegroundMode < ui_type = "combo"; ui_label = "Foreground"; ui_tooltip = "How the foreground subject is rendered.\nOriginal Scene: character is unchanged.\nSolid Color: character is replaced with a solid color (silhouette effect).\nWrap adds on top in both modes."; ui_items = "Original Scene\0Solid Color\0"; ui_category = "Wrap Appearance"; > = 0;
uniform float3 ForegroundColor < ui_type = "color"; ui_label = "Silhouette Color"; ui_tooltip = "Color used for the foreground when Solid Color mode is active. Black creates a dramatic silhouette."; ui_category = "Wrap Appearance"; > = float3(0.0, 0.0, 0.0);

// -- Color Mode --
uniform int ColorMode < ui_type = "combo"; ui_label = "Color Mode"; ui_tooltip = "How the wrap color is determined.\nBackground Color: uses actual scene color (most realistic).\nTint Color: uses a fixed color you choose.\nPalette: uses the selected palette mapped by edge angle."; ui_items = "Background Color\0Tint Color\0Palette\0"; ui_category = "Wrap Appearance"; > = COLOR_MODE_BACKGROUND;
uniform float3 TintColor < ui_type = "color"; ui_label = "Tint Color"; ui_tooltip = "Fixed wrap color when Color Mode is set to Tint."; ui_category = "Wrap Appearance"; > = float3(1.0, 0.95, 0.85);

// -- Palette & Style --
AS_PALETTE_SELECTION_UI(PalettePreset, "Wrap Palette", AS_PALETTE_SUNSET, AS_CAT_PALETTE)
AS_DECLARE_CUSTOM_PALETTE(LightWrap_, AS_CAT_PALETTE)

// -- Animation --
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, AS_CAT_ANIMATION)

// -- Audio Reactivity --
AS_AUDIO_UI(LightWrap_AudioSource, "Audio Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(LightWrap_AudioMultiplier, "Audio Intensity", 1.0, 2.0, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(LightWrap_AudioTarget, "None\0Wrap Intensity\0Wrap Width\0Luminance Threshold\0All\0", 0)

// -- Stage --
AS_STAGEDEPTH_UI(EffectDepth)

// -- Final Mix --
AS_BLENDMODE_UI_DEFAULT(BlendMode, 2) // Default: Screen
AS_BLENDAMOUNT_UI(BlendAmount)

// -- Debug --
AS_DEBUG_UI("Off\0Edge Mask\0Wrap Color (Pre-Blur)\0Wrap Result\0Depth\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

namespace AS_LightWrap {

    /**
     * Returns the wrap color for a given texcoord based on the selected color mode.
     * In Background mode, returns the scene color. In Tint mode, returns TintColor.
     * In Palette mode, maps the screen angle to the palette.
     */
    float3 getWrapColor(float2 texcoord, float3 sceneColor, float time) {
        if (ColorMode == COLOR_MODE_TINT) {
            return TintColor;
        }
        if (ColorMode == COLOR_MODE_PALETTE) {
            // Map edge position to palette via angle from screen center
            float2 centered = texcoord - 0.5;
            float angle = atan2(centered.y, centered.x);
            float t = frac((angle / AS_TWO_PI) + 0.5 + time * 0.1);
            if (PalettePreset == AS_PALETTE_CUSTOM) {
                return AS_GET_INTERPOLATED_CUSTOM_COLOR(LightWrap_, t);
            }
            return AS_getInterpolatedColor(PalettePreset, t);
        }
        // Default: Background Color
        return sceneColor;
    }

} // namespace AS_LightWrap

// ============================================================================
// PIXEL SHADERS
// ============================================================================

// Pass 1: Isolate background color, mask out foreground
float4 PS_LightWrap_Mask(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float depth = ReShade::GetLinearizedDepth(texcoord);
    float3 sceneColor = tex2D(ReShade::BackBuffer, texcoord).rgb;

    // Foreground = in front of stage depth → no contribution (black)
    if (depth < EffectDepth) {
        return float4(0.0, 0.0, 0.0, 0.0);
    }

    // Luminance gate: only bright backgrounds contribute
    float luma = dot(sceneColor, AS_LUMA_REC709);
    if (luma < LuminanceThreshold) {
        return float4(0.0, 0.0, 0.0, 0.0);
    }

    // Get the wrap color based on color mode
    float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);
    float3 wrapColor = AS_LightWrap::getWrapColor(texcoord, sceneColor, time);

    // Scale by how much the luminance exceeds the threshold (smooth ramp)
    float lumaFactor = saturate((luma - LuminanceThreshold) / max(1.0 - LuminanceThreshold, AS_EPSILON));

    return float4(wrapColor * lumaFactor, lumaFactor);
}

// Pass 2: Alpha-weighted horizontal Gaussian blur.
// This pass handles the hard mask boundary: transparent foreground pixels
// contribute nothing (not black). Output has correctly weighted color + alpha.
float4 PS_LightWrap_BlurH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float audioMod = AS_audioModulate(1.0, LightWrap_AudioSource, LightWrap_AudioMultiplier, true, 0);
    float wrapWidthFinal = WrapWidth;
    if (LightWrap_AudioTarget == 2 || LightWrap_AudioTarget == 4) {
        wrapWidthFinal *= audioMod;
    }

    int nSteps = max(1, (int)floor(wrapWidthFinal));
    const float expCoeff = -2.0 / (nSteps * nSteps + AS_GAUSS_EXP_EPSILON);
    const float2 blurAxis = float2(ReShade::PixelSize.x, 0.0);

    float3 colorSum = 0.0;
    float alphaWeightSum = 0.0;
    float totalWeight = 0.0;

    for (int i = -nSteps; i <= nSteps; i++)
    {
        float weight = exp((float)(i * i) * expCoeff);
        float offset = BLUR_AXIS_SCALE * (float)i - 0.5;
        float4 samp = tex2Dlod(LightWrap_MaskSampler, float4(texcoord + blurAxis * offset, 0, 0));

        // Alpha-weighted: transparent pixels contribute nothing
        colorSum += samp.rgb * samp.a * weight;
        alphaWeightSum += samp.a * weight;
        totalWeight += weight;
    }

    // Output: true color (divided by alpha sum) + coverage alpha
    float3 finalColor = colorSum / max(alphaWeightSum, AS_EPSILON);
    float finalAlpha = alphaWeightSum / totalWeight;

    return float4(finalColor, finalAlpha);
}

// Pass 3: Vertical Gaussian blur + final composite
float4 PS_LightWrap_BlurV_Composite(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);

    // Apply audio reactivity
    float audioMod = AS_audioModulate(1.0, LightWrap_AudioSource, LightWrap_AudioMultiplier, true, 0);
    float wrapWidthFinal = WrapWidth;
    float wrapIntensityFinal = WrapIntensity;
    float lumaThresholdFinal = LuminanceThreshold;

    if (LightWrap_AudioTarget == 1 || LightWrap_AudioTarget == 4) {
        wrapIntensityFinal *= audioMod;
    }
    if (LightWrap_AudioTarget == 2 || LightWrap_AudioTarget == 4) {
        wrapWidthFinal *= audioMod;
    }
    if (LightWrap_AudioTarget == 3 || LightWrap_AudioTarget == 4) {
        lumaThresholdFinal *= audioMod;
    }

    // Alpha-weighted vertical blur (same technique as horizontal pass)
    int nSteps = max(1, (int)floor(wrapWidthFinal));
    const float expCoeff = -2.0 / (nSteps * nSteps + AS_GAUSS_EXP_EPSILON);
    const float2 blurAxis = float2(0.0, ReShade::PixelSize.y);

    float3 colorSum = 0.0;
    float alphaWeightSum = 0.0;
    float totalWeight = 0.0;

    for (int i = -nSteps; i <= nSteps; i++)
    {
        float weight = exp((float)(i * i) * expCoeff);
        float offset = BLUR_AXIS_SCALE * (float)i - 0.5;
        float4 samp = tex2Dlod(LightWrap_BlurSampler, float4(texcoord + blurAxis * offset, 0, 0));

        colorSum += samp.rgb * samp.a * weight;
        alphaWeightSum += samp.a * weight;
        totalWeight += weight;
    }

    float3 wrapColor = colorSum / max(alphaWeightSum, AS_EPSILON);
    float wrapAlpha = alphaWeightSum / totalWeight;

    // Background pixels pass through untouched
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth >= EffectDepth) {
        // Debug views still work on background
        if (DebugMode == 1) return float4(0.0, 0.0, 0.0, 1.0);
        if (DebugMode == 4) return float4(depth.xxx, 1.0);
        return originalColor;
    }

    // Compute Fresnel (surface inclination) for all foreground pixels.
    // Used for both wrap falloff extension AND silhouette shading.
    float fresnel = 0.0;
    if (SurfaceReach > 0.0) {
        float2 px = ReShade::PixelSize * 12.0;
        float depthC = depth;
        float depthR = ReShade::GetLinearizedDepth(texcoord + float2(px.x, 0.0));
        float depthD = ReShade::GetLinearizedDepth(texcoord + float2(0.0, px.y));

        float maxDepthDiff = max(abs(depthR - depthC), abs(depthD - depthC));

        if (maxDepthDiff >= 0.008) {
            // Large depth discontinuity. Two cases:
            // 1. Silhouette edge (neighbor crosses into background) → maximum fresnel
            // 2. Internal polygon edge (both sides foreground) → skip (would cause artifacts)
            bool isSilhouetteEdge = (depthR >= EffectDepth) || (depthD >= EffectDepth);
            fresnel = isSilhouetteEdge ? 1.0 : 0.0;
        } else {
            // Smooth surface — compute actual fresnel from depth normals
            float3 dx = float3(px.x, 0.0, depthR - depthC);
            float3 dy = float3(0.0, px.y, depthD - depthC);
            float3 normal = normalize(cross(dy, dx));
            fresnel = AS_fresnelTerm(normal, float3(0.0, 0.0, 1.0), SurfaceSharpness);
        }
    }

    // Edge Prominence: higher values bring up low alpha values (stronger edge glow).
    // Internally: pow(alpha, 1/prominence). prominence=1 is linear, >1 boosts edges.
    // Fresnel further boosts prominence on inclined surfaces (wider crescent).
    float prominence = WrapFalloff;
    if (fresnel > 0.0 && wrapAlpha > 0.001) {
        // Inclined surfaces get even more prominence (wider crescent)
        prominence = lerp(WrapFalloff, WrapFalloff * 2.5, fresnel * SurfaceReach);
    }

    // Apply: higher prominence = smaller exponent = edge values brought up
    float wrapStrength = pow(saturate(wrapAlpha), 1.0 / max(prominence, 0.2));

    // Debug views
    if (DebugMode == 1) {
        return float4(wrapAlpha.xxx, 1.0);
    }
    if (DebugMode == 2) {
        return float4(tex2D(LightWrap_MaskSampler, texcoord).rgb, 1.0);
    }
    if (DebugMode == 3) {
        return float4(wrapColor * wrapStrength, 1.0);
    }
    if (DebugMode == 4) {
        return float4(fresnel.xxx, 1.0);
    }

    // Determine base foreground color (original scene or solid silhouette)
    // In solid color mode, Fresnel shades the silhouette to preserve 3D form:
    // inclined surfaces are slightly brighter, flat surfaces stay at base color.
    float3 baseColor = originalColor.rgb;
    if (ForegroundMode == 1) {
        baseColor = ForegroundColor * (1.0 + fresnel * SurfaceReach * 0.5);
    }

    // Additive light: wrap can only BRIGHTEN, never darken.
    float3 wrapLight = wrapColor * wrapStrength * wrapIntensityFinal;
    float3 wrappedScene = baseColor + wrapLight;

    // User's BlendMode/BlendAmount controls final mix of FULL effect vs original.
    float3 result = AS_composite(wrappedScene, originalColor.rgb, BlendMode, BlendAmount);

    return float4(result, originalColor.a);
}

// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_GFX_LightWrap
<
    ui_label = "[AS] GFX: Light Wrap";
    ui_tooltip = "Bleeds bright background light around subject edges for natural compositing.\n"
                 "Use with BGX backgrounds to make subjects look integrated into the scene.\n"
                 "Performance: Moderate (3-pass Gaussian blur)";
>
{
    pass Mask_Pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_LightWrap_Mask;
        RenderTarget = LightWrap_MaskBuffer;
    }
    pass BlurH_Pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_LightWrap_BlurH;
        RenderTarget = LightWrap_BlurBuffer;
    }
    pass BlurV_Composite_Pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_LightWrap_BlurV_Composite;
    }
}

#endif // __AS_GFX_LightWrap_1_fx
