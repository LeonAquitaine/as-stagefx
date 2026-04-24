/**
 * AS_VFX_PrismOverlay.1.fx - Crystal Prism Lens Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Simulates holding a crystal or glass prism in front of the camera lens. Creates
 * rainbow light refractions, partial scene reflections, and dreamy distortion at
 * the edges of the frame — a popular creative photography technique on Instagram
 * and in editorial portrait work.
 *
 * FEATURES:
 * - Configurable prism position, size, and rotation
 * - Rainbow chromatic separation at the prism boundary
 * - Scene reflection/distortion within the prism area
 * - Adjustable refraction strength and edge softness
 * - Audio-reactive prism rotation and refraction
 * - Palette integration for custom refraction colors
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Define a prism-shaped region on screen (triangular or faceted)
 * 2. Inside the prism: warp UV coordinates to create reflection/distortion
 * 3. At the prism edges: apply chromatic aberration (separate R/G/B channels)
 * 4. Outside the prism: original scene with optional edge glow
 * 5. Composite everything additively for the rainbow light effect
 *
 * ===================================================================================
 */

#ifndef __AS_VFX_PrismOverlay_1_fx
#define __AS_VFX_PrismOverlay_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================

static const float PRISM_SIZE_MIN = 0.1;
static const float PRISM_SIZE_MAX = 1.5;
static const float PRISM_SIZE_STEP = 0.01;
static const float PRISM_SIZE_DEFAULT = 0.6;

static const float REFRACTION_MIN = 0.0;
static const float REFRACTION_MAX = 0.1;
static const float REFRACTION_STEP = 0.001;
static const float REFRACTION_DEFAULT = 0.03;

static const float DISTORTION_MIN = 0.0;
static const float DISTORTION_MAX = 1.0;
static const float DISTORTION_STEP = 0.01;
static const float DISTORTION_DEFAULT = 0.3;

static const float EDGE_GLOW_MIN = 0.0;
static const float EDGE_GLOW_MAX = 1.0;
static const float EDGE_GLOW_STEP = 0.01;
static const float EDGE_GLOW_DEFAULT = 0.4;

static const float EDGE_WIDTH_MIN = 0.01;
static const float EDGE_WIDTH_MAX = 0.3;
static const float EDGE_WIDTH_STEP = 0.005;
static const float EDGE_WIDTH_DEFAULT = 0.08;

static const float REFLECTION_MIN = 0.0;
static const float REFLECTION_MAX = 1.0;
static const float REFLECTION_STEP = 0.01;
static const float REFLECTION_DEFAULT = 0.25;

static const float FACETS_MIN = 3;
static const float FACETS_MAX = 8;
static const float FACETS_DEFAULT = 3;

static const float BLUR_AMOUNT_MIN = 0.0;
static const float BLUR_AMOUNT_MAX = 1.0;
static const float BLUR_AMOUNT_STEP = 0.01;
static const float BLUR_AMOUNT_DEFAULT = 0.15;

// ============================================================================
// SHADER DESCRIPTOR
// ============================================================================

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// -- Prism Shape --

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform float PrismSize < ui_type = "slider"; ui_label = "Prism Size"; ui_tooltip = "How much of the frame the prism covers.\nSmaller = corner accent, larger = dominant overlay."; ui_min = PRISM_SIZE_MIN; ui_max = PRISM_SIZE_MAX; ui_step = PRISM_SIZE_STEP; ui_category = "Prism Shape"; > = PRISM_SIZE_DEFAULT;
uniform int PrismFacets < ui_type = "slider"; ui_label = "Facets"; ui_tooltip = "Number of prism facets.\n3 = triangle, 4 = diamond, 5+ = rounder crystal."; ui_min = FACETS_MIN; ui_max = FACETS_MAX; ui_category = "Prism Shape"; > = FACETS_DEFAULT;
uniform float2 PrismCenter < ui_type = "drag"; ui_label = "Position"; ui_tooltip = "Screen position of the prism center."; ui_min = -1.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Prism Shape"; > = float2(-0.3, -0.2);

// -- Refraction --
uniform float RefractionStrength < ui_type = "slider"; ui_label = "Rainbow Spread"; ui_tooltip = "How far apart the R/G/B channels separate at prism edges.\nHigher = stronger rainbow effect."; ui_min = REFRACTION_MIN; ui_max = REFRACTION_MAX; ui_step = REFRACTION_STEP; ui_category = "Refraction"; > = REFRACTION_DEFAULT;
uniform float DistortionAmount < ui_type = "slider"; ui_label = "Scene Distortion"; ui_tooltip = "How much the scene warps inside the prism area.\nSimulates the bending of light through glass."; ui_min = DISTORTION_MIN; ui_max = DISTORTION_MAX; ui_step = DISTORTION_STEP; ui_category = "Refraction"; > = DISTORTION_DEFAULT;
uniform float ReflectionStrength < ui_type = "slider"; ui_label = "Reflection"; ui_tooltip = "How much of a flipped/reflected scene shows inside the prism.\nSimulates internal reflection in the crystal."; ui_min = REFLECTION_MIN; ui_max = REFLECTION_MAX; ui_step = REFLECTION_STEP; ui_category = "Refraction"; > = REFLECTION_DEFAULT;
uniform float InsideBlur < ui_type = "slider"; ui_label = "Inside Blur"; ui_tooltip = "Softness of the scene inside the prism.\nSimulates the slight defocus from looking through glass."; ui_min = BLUR_AMOUNT_MIN; ui_max = BLUR_AMOUNT_MAX; ui_step = BLUR_AMOUNT_STEP; ui_category = "Refraction"; > = BLUR_AMOUNT_DEFAULT;

// -- Edge Glow --
uniform float EdgeGlow < ui_type = "slider"; ui_label = "Edge Glow"; ui_tooltip = "Brightness of the rainbow glow at prism edges.\nSimulates light refracting at the glass boundary."; ui_min = EDGE_GLOW_MIN; ui_max = EDGE_GLOW_MAX; ui_step = EDGE_GLOW_STEP; ui_category = "Refraction"; > = EDGE_GLOW_DEFAULT;
uniform float EdgeWidth < ui_type = "slider"; ui_label = "Edge Width"; ui_tooltip = "Thickness of the rainbow edge band."; ui_min = EDGE_WIDTH_MIN; ui_max = EDGE_WIDTH_MAX; ui_step = EDGE_WIDTH_STEP; ui_category = "Refraction"; > = EDGE_WIDTH_DEFAULT;

// -- Palette & Style --
AS_PALETTE_SELECTION_UI(PalettePreset, "Refraction Palette", AS_PALETTE_RAINBOW, AS_CAT_PALETTE)
AS_DECLARE_CUSTOM_PALETTE(PrismOverlay_, AS_CAT_PALETTE)

// -- Animation --
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, AS_CAT_ANIMATION)
AS_ROTATION_UI(SnapRotation, FineRotation)

// -- Audio Reactivity --
AS_AUDIO_UI(PrismOverlay_AudioSource, "Audio Source", AS_AUDIO_OFF, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(PrismOverlay_AudioMultiplier, "Audio Intensity", 1.0, 2.0, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(PrismOverlay_AudioTarget, "None\0Rainbow Spread\0Rotation\0Size\0All\0", 0)

// -- Stage --
AS_STAGEDEPTH_UI(EffectDepth)

// -- Final Mix --
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// -- Debug --
AS_DEBUG_UI("Off\0Prism Mask\0Edge Band\0Distorted UV\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

namespace AS_PrismOverlay {

    // Signed distance to a regular polygon (prism cross-section)
    float sdPolygon(float2 p, int sides, float radius) {
        float angle = AS_TWO_PI / (float)sides;
        float halfAngle = angle * 0.5;
        float a = atan2(p.y, p.x);
        // Fold into one sector
        float sector = AS_mod(a + halfAngle, angle) - halfAngle;
        float2 folded = float2(cos(sector), abs(sin(sector))) * length(p);
        return folded.x - radius;
    }

    // Cheap blur via 5-tap cross sampling
    float3 sampleBlurred(sampler samp, float2 uv, float amount) {
        float2 px = ReShade::PixelSize * amount * 8.0;
        float3 sum = tex2D(samp, uv).rgb * 0.4;
        sum += tex2D(samp, uv + float2(px.x, 0.0)).rgb * 0.15;
        sum += tex2D(samp, uv - float2(px.x, 0.0)).rgb * 0.15;
        sum += tex2D(samp, uv + float2(0.0, px.y)).rgb * 0.15;
        sum += tex2D(samp, uv - float2(0.0, px.y)).rgb * 0.15;
        return sum;
    }

    // Rainbow color from edge angle
    float3 getRainbowColor(float angle, float time, int palettePreset) {
        float t = frac(angle / AS_TWO_PI + 0.5 + time * 0.05);
        if (palettePreset == AS_PALETTE_CUSTOM) {
            return AS_GET_INTERPOLATED_CUSTOM_COLOR(PrismOverlay_, t);
        }
        return AS_getInterpolatedColor(palettePreset, t);
    }

} // namespace AS_PrismOverlay

// ============================================================================
// PIXEL SHADER
// ============================================================================

float4 PS_PrismOverlay(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);

    // Audio reactivity
    float audioMod = AS_audioModulate(1.0, PrismOverlay_AudioSource, PrismOverlay_AudioMultiplier, true, 0);
    float refractionFinal = RefractionStrength;
    float sizeFinal = PrismSize;

    if (PrismOverlay_AudioTarget == 1 || PrismOverlay_AudioTarget == 4) refractionFinal *= audioMod;
    if (PrismOverlay_AudioTarget == 3 || PrismOverlay_AudioTarget == 4) sizeFinal *= audioMod;

    float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);

    // Compute prism rotation (snap + fine + audio + animation)
    float rotation = AS_getRotationRadians(SnapRotation, FineRotation);
    if (PrismOverlay_AudioTarget == 2 || PrismOverlay_AudioTarget == 4) {
        rotation += (audioMod - 1.0) * AS_PI;
    }
    rotation += time * 0.2; // Slow animated rotation

    // Center coordinates on prism position, aspect-correct
    float2 centered = texcoord - (PrismCenter * 0.5 + 0.5);
    centered.x *= ReShade::AspectRatio;

    // Apply rotation
    float2 rotated = AS_rotate2D(centered, rotation);

    // Compute distance to prism shape
    float prismDist = AS_PrismOverlay::sdPolygon(rotated, PrismFacets, sizeFinal * 0.5);

    // Edge band: where the rainbow refraction happens
    float edgeMask = 1.0 - smoothstep(0.0, EdgeWidth, abs(prismDist));

    // Inside mask: smooth transition into the prism
    float insideMask = 1.0 - smoothstep(-EdgeWidth * 0.5, EdgeWidth * 0.5, prismDist);

    // Debug views
    if (DebugMode == 1) return float4(insideMask.xxx, 1.0);
    if (DebugMode == 2) return float4(edgeMask.xxx, 1.0);

    // Start with original scene
    float3 result = originalColor.rgb;

    // Inside the prism: distort and optionally reflect
    if (insideMask > 0.001) {
        // Distort UVs based on distance from prism center (bending through glass)
        float2 distortDir = normalize(rotated + AS_EPSILON);
        float distortMag = (1.0 - saturate(abs(prismDist) / (sizeFinal * 0.5))) * DistortionAmount;
        float2 distortedUV = texcoord + distortDir * distortMag * 0.1;

        // Clamp to screen
        distortedUV = clamp(distortedUV, 0.0, 1.0);

        if (DebugMode == 3) return float4(frac(distortedUV * 5.0), 0.0, 1.0);

        // Sample distorted scene (with optional blur for glass defocus)
        float3 insideColor;
        if (InsideBlur > 0.001) {
            insideColor = AS_PrismOverlay::sampleBlurred(ReShade::BackBuffer, distortedUV, InsideBlur);
        } else {
            insideColor = tex2D(ReShade::BackBuffer, distortedUV).rgb;
        }

        // Add reflection (sample from mirrored/offset position)
        if (ReflectionStrength > 0.001) {
            float2 reflectedUV = float2(1.0 - distortedUV.x, distortedUV.y); // Horizontal flip
            float3 reflectedColor = tex2D(ReShade::BackBuffer, reflectedUV).rgb;
            insideColor = lerp(insideColor, reflectedColor, ReflectionStrength * 0.5);
        }

        // Blend inside color with original based on inside mask
        result = lerp(result, insideColor, insideMask * 0.7);
    }

    // Edge rainbow: chromatic aberration at prism boundary
    if (edgeMask > 0.001 && refractionFinal > 0.001) {
        // Direction from prism center to pixel (refraction direction)
        float2 refractDir = normalize(centered + AS_EPSILON);

        // Separate R/G/B channels with different offsets
        float2 uvR = texcoord + refractDir * refractionFinal * 1.0;
        float2 uvG = texcoord + refractDir * refractionFinal * 0.0; // Green stays centered
        float2 uvB = texcoord - refractDir * refractionFinal * 1.0;

        float3 chromatic = float3(
            tex2D(ReShade::BackBuffer, clamp(uvR, 0.0, 1.0)).r,
            tex2D(ReShade::BackBuffer, clamp(uvG, 0.0, 1.0)).g,
            tex2D(ReShade::BackBuffer, clamp(uvB, 0.0, 1.0)).b
        );

        // Add rainbow color glow at edges
        float angle = atan2(rotated.y, rotated.x);
        float3 rainbow = AS_PrismOverlay::getRainbowColor(angle, time, PalettePreset);

        // Combine chromatic separation with rainbow glow
        float3 edgeColor = lerp(chromatic, chromatic + rainbow * EdgeGlow, edgeMask);

        result = lerp(result, edgeColor, edgeMask);
    }

    // Depth masking
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth) {
        result = originalColor.rgb;
    }

    // User's BlendMode/BlendAmount for final mix
    float3 finalResult = AS_composite(result, originalColor.rgb, BlendMode, BlendAmount);

    return float4(finalResult, originalColor.a);
}

// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_VFX_PrismOverlay
<
    ui_label = "[AS] VFX: Prism Overlay";
    ui_tooltip = "Crystal prism held in front of the lens.\n"
                 "Rainbow refractions and dreamy distortions for creative portraits.\n"
                 "Performance: Light (single-pass)";
>
{
    pass Main
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_PrismOverlay;
    }
}

#endif // __AS_VFX_PrismOverlay_1_fx
