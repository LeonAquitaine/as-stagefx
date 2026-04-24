/**
 * AS_VFX_DoubleExposure.1.fx - Double Exposure Blend Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Blends the scene with a transformed version of itself using depth separation.
 * Recreates the classic double exposure technique where two exposures overlap
 * on the same frame, with foreground silhouettes filled by background imagery.
 *
 * FEATURES:
 * - Multiple blend modes: Screen (classic), Multiply, Lighten, Average
 * - Offset, zoom, and flip controls for the second exposure layer
 * - Depth-based masking: foreground silhouette vs background fill
 * - Optional tinting and desaturation of the second layer
 * - Audio-reactive effect strength with animated offset drift
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Sample original scene and a second exposure at transformed UV coordinates.
 * 2. Apply optional zoom, flip, tint, and desaturation to second layer.
 * 3. Create depth-based blend mask (foreground as silhouette shape).
 * 4. Combine layers using selected blend mode weighted by depth mask.
 * 5. Mix result with original via effect strength.
 *
 * ===================================================================================
 */

#ifndef __AS_VFX_DoubleExposure_1_fx
#define __AS_VFX_DoubleExposure_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================

static const float STRENGTH_MIN = 0.0;
static const float STRENGTH_MAX = 1.0;
static const float STRENGTH_STEP = 0.01;
static const float STRENGTH_DEFAULT = 0.5;

static const float ZOOM_MIN = 0.5;
static const float ZOOM_MAX = 2.0;
static const float ZOOM_STEP = 0.01;
static const float ZOOM_DEFAULT = 1.0;

static const float OFFSET_MIN = -1.0;
static const float OFFSET_MAX = 1.0;
static const float OFFSET_STEP = 0.005;

static const float DEPTH_MIN = 0.0;
static const float DEPTH_MAX = 1.0;
static const float DEPTH_STEP = 0.01;

static const float DESAT_MIN = 0.0;
static const float DESAT_MAX = 1.0;
static const float DESAT_STEP = 0.01;
static const float DESAT_DEFAULT = 0.0;

static const float DRIFT_SPEED_MIN = 0.0;
static const float DRIFT_SPEED_MAX = 1.0;
static const float DRIFT_SPEED_STEP = 0.01;
static const float DRIFT_SPEED_DEFAULT = 0.0;

static const int EXPOSURE_BLEND_SCREEN = 0;
static const int EXPOSURE_BLEND_MULTIPLY = 1;
static const int EXPOSURE_BLEND_LIGHTEN = 2;
static const int EXPOSURE_BLEND_AVERAGE = 3;

// ============================================================================
// SHADER DESCRIPTOR
// ============================================================================

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// -- Effect Controls --

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform float EffectStrength < ui_type = "slider"; ui_label = "Effect Strength"; ui_tooltip = "Overall intensity of the double exposure effect.\n0.0 = original only, 1.0 = full double exposure."; ui_min = STRENGTH_MIN; ui_max = STRENGTH_MAX; ui_step = STRENGTH_STEP; ui_category = AS_CAT_APPEARANCE; > = STRENGTH_DEFAULT;
uniform int ExposureBlend < ui_type = "combo"; ui_label = "Exposure Blend"; ui_tooltip = "How the two exposures are combined.\nScreen: classic double exposure (light adds).\nMultiply: darker, moody blend.\nLighten: keeps the brighter of the two.\nAverage: simple 50/50 mix."; ui_items = "Screen\0Multiply\0Lighten\0Average\0"; ui_category = AS_CAT_APPEARANCE; > = EXPOSURE_BLEND_SCREEN;

// -- Second Exposure Transform --
uniform float2 ExposureOffset < ui_type = "drag"; ui_label = "Exposure Offset"; ui_tooltip = "Position offset for the second exposure layer (X, Y)."; ui_min = OFFSET_MIN; ui_max = OFFSET_MAX; ui_step = OFFSET_STEP; ui_category = "Second Exposure"; > = float2(0.0, 0.0);
uniform float ExposureZoom < ui_type = "slider"; ui_label = "Exposure Zoom"; ui_tooltip = "Scale of the second exposure.\n<1.0 zooms in, >1.0 zooms out."; ui_min = ZOOM_MIN; ui_max = ZOOM_MAX; ui_step = ZOOM_STEP; ui_category = "Second Exposure"; > = ZOOM_DEFAULT;
uniform bool FlipHorizontal < ui_type = "checkbox"; ui_label = "Flip Horizontal"; ui_tooltip = "Mirror the second exposure horizontally."; ui_category = "Second Exposure"; > = false;
uniform bool FlipVertical < ui_type = "checkbox"; ui_label = "Flip Vertical"; ui_tooltip = "Flip the second exposure vertically."; ui_category = "Second Exposure"; > = false;
uniform float3 TintSecond < ui_type = "color"; ui_label = "Tint Second Exposure"; ui_tooltip = "Apply a color tint to the second exposure layer.\nWhite = no tint."; ui_category = "Second Exposure"; > = float3(1.0, 1.0, 1.0);
uniform float DesaturateSecond < ui_type = "slider"; ui_label = "Desaturate Second"; ui_tooltip = "Optionally desaturate the second exposure layer.\n0.0 = full color, 1.0 = grayscale."; ui_min = DESAT_MIN; ui_max = DESAT_MAX; ui_step = DESAT_STEP; ui_category = "Second Exposure"; > = DESAT_DEFAULT;

// -- Depth Masking --
uniform float DepthStart < ui_type = "slider"; ui_label = "Depth Start"; ui_tooltip = "Depth where the double exposure blend begins.\nPixels closer than this stay as the original."; ui_min = DEPTH_MIN; ui_max = DEPTH_MAX; ui_step = DEPTH_STEP; ui_category = "Depth Masking"; > = 0.0;
uniform float DepthEnd < ui_type = "slider"; ui_label = "Depth End"; ui_tooltip = "Depth where the double exposure blend reaches full strength.\nPixels beyond this get the full double exposure effect."; ui_min = DEPTH_MIN; ui_max = DEPTH_MAX; ui_step = DEPTH_STEP; ui_category = "Depth Masking"; > = 0.3;
uniform bool InvertDepth < ui_type = "checkbox"; ui_label = "Invert Depth"; ui_tooltip = "Swap foreground/background role.\nWhen enabled, the foreground gets the double exposure fill."; ui_category = "Depth Masking"; > = false;

// -- Animation --
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, AS_CAT_ANIMATION)
uniform float DriftSpeed < ui_type = "slider"; ui_label = "Offset Drift Speed"; ui_tooltip = "Animated drift of the second exposure position.\n0.0 = static, higher = faster drift."; ui_min = DRIFT_SPEED_MIN; ui_max = DRIFT_SPEED_MAX; ui_step = DRIFT_SPEED_STEP; ui_category = AS_CAT_ANIMATION; > = DRIFT_SPEED_DEFAULT;

// -- Audio Reactivity --
AS_AUDIO_UI(DblExp_AudioSource, "Audio Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(DblExp_AudioMultiplier, "Audio Intensity", 1.0, 2.0, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(DblExp_AudioTarget, "None\0Effect Strength\0", 0)

// -- Stage --
AS_STAGEDEPTH_UI(EffectDepth)

// -- Final Mix --
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// -- Debug --
AS_DEBUG_UI("Off\0Second Exposure\0Depth Mask\0Blended Layer\0")

// ============================================================================
// PIXEL SHADER
// ============================================================================

float4 PS_DoubleExposure(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);

    // Stage depth check
    float stageDepth = ReShade::GetLinearizedDepth(texcoord);
    if (stageDepth < EffectDepth)
    {
        if (DebugMode == 0) return originalColor;
    }

    // Audio reactivity
    float audioMod = AS_audioModulate(1.0, DblExp_AudioSource, DblExp_AudioMultiplier, true, 0);
    float strengthFinal = EffectStrength;
    if (DblExp_AudioTarget == 1) strengthFinal *= audioMod;

    // Animation time for offset drift
    float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);

    // Compute second exposure UV
    float2 secondUV = texcoord + ExposureOffset;

    // Animated drift
    if (DriftSpeed > 0.0)
    {
        secondUV.x += sin(time * 0.37) * DriftSpeed * 0.1;
        secondUV.y += cos(time * 0.29) * DriftSpeed * 0.07;
    }

    // Apply zoom (scale around center)
    secondUV = 0.5 + (secondUV - 0.5) * ExposureZoom;

    // Apply flips
    if (FlipHorizontal) secondUV.x = 1.0 - secondUV.x;
    if (FlipVertical) secondUV.y = 1.0 - secondUV.y;

    // Clamp to valid UV range
    secondUV = saturate(secondUV);

    // Sample second exposure
    float3 secondColor = tex2D(ReShade::BackBuffer, secondUV).rgb;

    // Apply tint
    secondColor *= TintSecond;

    // Apply desaturation
    if (DesaturateSecond > 0.0)
    {
        secondColor = AS_adjustSaturation(secondColor, 1.0 - DesaturateSecond);
    }

    // Depth-based blend mask
    float depth = ReShade::GetLinearizedDepth(texcoord);
    float depthMask = smoothstep(DepthStart, max(DepthEnd, DepthStart + 0.001), depth);
    if (InvertDepth) depthMask = 1.0 - depthMask;

    // Blend the two exposures
    float3 blended;
    if (ExposureBlend == EXPOSURE_BLEND_SCREEN)
    {
        blended = 1.0 - (1.0 - originalColor.rgb) * (1.0 - secondColor);
    }
    else if (ExposureBlend == EXPOSURE_BLEND_MULTIPLY)
    {
        blended = originalColor.rgb * secondColor;
    }
    else if (ExposureBlend == EXPOSURE_BLEND_LIGHTEN)
    {
        blended = max(originalColor.rgb, secondColor);
    }
    else // Average
    {
        blended = (originalColor.rgb + secondColor) * 0.5;
    }

    // Mix based on depth mask and effect strength
    float3 mixed = lerp(originalColor.rgb, blended, depthMask * strengthFinal);

    // Debug views
    if (DebugMode == 1) return float4(secondColor, 1.0);
    if (DebugMode == 2) return float4(depthMask.xxx, 1.0);
    if (DebugMode == 3) return float4(blended, 1.0);

    // Final composite
    float3 result = AS_composite(mixed, originalColor.rgb, BlendMode, BlendAmount);

    return float4(result, originalColor.a);
}

// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_VFX_DoubleExposure
<
    ui_label = "[AS] VFX: Double Exposure";
    ui_tooltip = "Classic double exposure effect with depth-based blending.\n"
                 "Blends the scene with a transformed copy of itself.\n"
                 "Performance: Light (single-pass UV transform and blend)";
>
{
    pass Main
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_DoubleExposure;
    }
}

#endif // __AS_VFX_DoubleExposure_1_fx
