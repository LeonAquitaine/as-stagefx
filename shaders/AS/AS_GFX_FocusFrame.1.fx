/**
 * AS_GFX_FocusFrame.1.fx - Creates a focused frame with a stylized background.
 *
 * Author: Leon Aquitaine
 * License: CC BY 4.0
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader creates a "focus frame" effect by defining a clear, centered
 * rectangular area with a soft, feathered edge. The frame's aspect ratio is fully
 * adjustable. The surrounding space is rendered as a blurred, zoomed, and dimmed
 * version of the background, ideal for creating cinematic compositions.
 *
 * FEATURES:
 * - A fully adjustable central frame with controls for size and aspect ratio.
 * - A soft, feathered edge for a smooth blend between the focus area and background.
 * - High-quality, performant two-pass Gaussian blur for the background.
 * - Intuitive controls for composition and background effects.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1.  (Pass 1) A horizontal Gaussian blur is applied to the entire screen, based on
 * the zoomed UV coordinates, and the result is stored in an intermediate texture.
 * 2.  (Pass 2) A vertical Gaussian blur is applied to the result of the first pass.
 * This final blurred color is then used for the background.
 * 3.  The frame's dimensions are calculated based on size and aspect ratio controls.
 * 4.  A smoothed mask is generated using smoothstep to define the focus area with
 * soft, feathered edges.
 * 5.  The final image is composed by layering the blurred background and the focused
 * original image, blended according to the mask.
 *
 * ===================================================================================
 */

#ifndef __AS_GFX_FocusFrame_1_fx
#define __AS_GFX_FocusFrame_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// INTERMEDIATE TEXTURE
// ============================================================================

texture FocusFrame_BlurHBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler FocusFrame_BlurHSampler { Texture = FocusFrame_BlurHBuffer; };

// ============================================================================
// UI DECLARATIONS
// ============================================================================

uniform int as_shader_descriptor <ui_type = "radio"; ui_label = " ";ui_text ="\nCreates a focused rectangular frame with a blurred, dimmed background.\nIdeal for portrait compositions and drawing attention to subjects.\n\n";>;

// -- Composition & Framing --
uniform float FocusAreaSize < ui_type = "slider"; ui_label = "Frame Size"; ui_tooltip = "Controls the size of the central frame."; ui_min = 0.1; ui_max = 1.0; ui_category = "Composition & Framing"; > = 0.9;
uniform float FrameAspectRatio < ui_type = "slider"; ui_label = "Frame Aspect Ratio"; ui_tooltip = "Controls the width-to-height ratio of the frame.\n1.0 = Square, < 1.0 = Tall, > 1.0 = Wide."; ui_min = 0.25; ui_max = 4.0; ui_step = 0.05; ui_category = "Composition & Framing"; > = 1.0;
uniform float Feather < ui_type = "slider"; ui_label = "Edge Softness"; ui_tooltip = "Controls how soft or sharp the frame's edge is. A higher value creates a smoother, more gradual blend."; ui_min = 0.0; ui_max = 0.1; ui_category = "Composition & Framing"; > = 0.005;

// -- Background Effect --
uniform float BackgroundZoom < ui_type = "slider"; ui_label = "Zoom"; ui_tooltip = "How much to magnify the background area outside the frame."; ui_min = 1.0; ui_max = 5.0; ui_category = "Background Effect"; > = 1.5;
uniform float BlurAmount < ui_type = "slider"; ui_label = "Blurriness"; ui_tooltip = "The intensity of the background blur."; ui_min = 0.0; ui_max = 25.0; ui_category = "Background Effect"; > = 10.0;
uniform float BackgroundBrightness < ui_type = "slider"; ui_label = "Brightness"; ui_tooltip = "Adjusts the brightness of the background area."; ui_min = 0.0; ui_max = 1.0; ui_category = "Background Effect"; > = 0.6;

// ============================================================================
// Stage & Depth
// ============================================================================
AS_STAGEDEPTH_UI(EffectDepth)

// ============================================================================
// Final Mix
// ============================================================================
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================
static const float BLUR_EXP_COEFF_EPSILON = 1e-5; // For Gaussian blur denominator stability
static const float BLUR_AXIS_SCALE = 2.0;         // Used for blur offset scaling
static const float DEFAULT_MASK_POWER = 1.0;      // Reserved for future mask shaping

// ============================================================================
// PIXEL SHADERS
// ============================================================================

// PASS 1: Horizontal Gaussian Blur
float4 PS_FocusFrame_BlurH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float3 gaussianSum = 0.0;
    float gaussianSumWeight = 0.0;

    int nSteps = floor(BlurAmount);
    // Get zoomed UV for the background effect
    const float2 zoomUV = 0.5 + (texcoord - 0.5) / BackgroundZoom;
    if (nSteps <= 0) return tex2D(ReShade::BackBuffer, zoomUV);

    const float expCoeff = -2.0 / (nSteps * nSteps + BLUR_EXP_COEFF_EPSILON);
    const float2 blurAxisScaled = float2(ReShade::PixelSize.x, 0.0);

    for (float iStep = -nSteps; iStep <= nSteps; iStep++)
    {
        float weight = exp(iStep * iStep * expCoeff);
        float offset = BLUR_AXIS_SCALE * iStep - 0.5;

        gaussianSum += tex2Dlod(ReShade::BackBuffer, float4(zoomUV + blurAxisScaled * offset, 0, 0)).rgb * weight;
        gaussianSumWeight += weight;
    }

    return float4(gaussianSum / gaussianSumWeight, 1.0);
}

// PASS 2: Vertical Gaussian Blur and Final Composition
float4 PS_FocusFrame_BlurV_and_Combine(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float3 gaussianSum = 0.0;
    float gaussianSumWeight = 0.0;
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);

    int nSteps = floor(BlurAmount);
    if (nSteps <= 0)
    {
        gaussianSum = tex2D(FocusFrame_BlurHSampler, texcoord).rgb;
    }
    else
    {
        const float expCoeff = -2.0 / (nSteps * nSteps + BLUR_EXP_COEFF_EPSILON);
        const float2 blurAxisScaled = float2(0.0, ReShade::PixelSize.y);

        for (float iStep = -nSteps; iStep <= nSteps; iStep++)
        {
            float weight = exp(iStep * iStep * expCoeff);
            float offset = BLUR_AXIS_SCALE * iStep - 0.5;

            gaussianSum += tex2Dlod(FocusFrame_BlurHSampler, float4(texcoord + blurAxisScaled * offset, 0, 0)).rgb * weight;
            gaussianSumWeight += weight;
        }
        gaussianSum /= gaussianSumWeight;
    }

    // --- Calculate the final background color ---
    float4 backgroundColor = float4(gaussianSum * BackgroundBrightness, 1.0);

    // --- Calculate the bounds of the focus area ---
    float2 size;
    // 1. Calculate base size for a visually perfect square
    if (ReShade::AspectRatio >= 1.0) // Landscape or square screen
    {
        size = float2(FocusAreaSize / ReShade::AspectRatio, FocusAreaSize);
    }
    else // Portrait screen
    {
        size = float2(FocusAreaSize, FocusAreaSize * ReShade::AspectRatio);
    }

    // 2. Apply the user-defined aspect ratio adjustment to the width
    size.x *= FrameAspectRatio;

    // 3. Define final min/max UVs
    float2 minUV = 0.5 - size * 0.5;
    float2 maxUV = 0.5 + size * 0.5;

    // --- Create a smoothed mask for the focus area ---
    float dist_x = min(texcoord.x - minUV.x, maxUV.x - texcoord.x);
    float dist_y = min(texcoord.y - minUV.y, maxUV.y - texcoord.y);
    // Adjust feathering based on the frame's aspect ratio to keep it visually consistent
    float mask_x = smoothstep(0.0, Feather / (ReShade::AspectRatio * FrameAspectRatio), dist_x / (ReShade::AspectRatio * FrameAspectRatio));
    float mask_y = smoothstep(0.0, Feather, dist_y);    float mask = min(mask_x, mask_y);

    // --- Final Composition ---
    // First apply the focus frame effect (mask between blur and original)
    float3 focusFrameResult = lerp(backgroundColor.rgb, originalColor.rgb, mask);
    
    // Apply stage depth masking - pixels in front of EffectDepth should be plainly copied
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    float depthMask = sceneDepth >= EffectDepth ? 1.0 : 0.0;
    
    // Then apply blend mode and strength to blend the entire effect with the scene
    float3 blended = AS_applyBlend(focusFrameResult, originalColor.rgb, BlendMode);
    float3 result = lerp(originalColor.rgb, blended, BlendStrength * depthMask);
    
    return float4(result, originalColor.a);
}

// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_GFX_FocusFrame
<
    ui_label = "[AS] GFX: Focus Frame";
    ui_tooltip = "Creates a focused frame with a stylized, blurred background.\n"
                 "Ideal for portrait shots or drawing attention to a subject.";
>
{
    pass BlurH_Pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_FocusFrame_BlurH;
        RenderTarget = FocusFrame_BlurHBuffer;
    }
    pass BlurV_and_Combine_Pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_FocusFrame_BlurV_and_Combine;
    }
}

#endif // __AS_GFX_FocusFrame_1_fx
