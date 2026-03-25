/**
 * AS_VFX_NeonEdgeGlow.1.fx - Cyberpunk-style colored edge glow effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Detects depth edges using a Sobel operator and applies a colored neon glow around
 * them. The effect creates a cyberpunk-inspired rim light appearance on foreground
 * subjects, with customizable colors via palette or direct tint controls.
 *
 * FEATURES:
 * - Sobel-based depth edge detection with adjustable sensitivity
 * - Wide sampling radius for smooth, diffused glow edges
 * - Multiple color modes: Cyberpunk preset, direct tint, or palette-driven
 * - Inner/outer color gradient for depth in the glow
 * - Audio-reactive glow intensity (pulse on beat)
 * - Stage depth masking for foreground-only glow
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Sample depth at current pixel and 8 neighbors (full Sobel kernel).
 * 2. Compute horizontal and vertical gradients for edge magnitude.
 * 3. Apply glow falloff and color based on selected mode.
 * 4. Additively composite the glow onto the original scene.
 *
 * ===================================================================================
 */

#ifndef __AS_VFX_NeonEdgeGlow_1_fx
#define __AS_VFX_NeonEdgeGlow_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

// ============================================================================
// NAMESPACE
// ============================================================================
namespace AS_NeonEdgeGlow {

// ============================================================================
// CONSTANTS
// ============================================================================
static const float GLOWINTENSITY_MIN = 0.0;
static const float GLOWINTENSITY_MAX = 2.0;
static const float GLOWINTENSITY_DEFAULT = 0.8;

static const float GLOWWIDTH_MIN = 1.0;
static const float GLOWWIDTH_MAX = 20.0;
static const float GLOWWIDTH_DEFAULT = 6.0;

static const float SENSITIVITY_MIN = 10.0;
static const float SENSITIVITY_MAX = 200.0;
static const float SENSITIVITY_DEFAULT = 80.0;

static const float3 CYBERPUNK_INNER = float3(0.0, 0.9, 1.0);
static const float3 CYBERPUNK_OUTER = float3(0.8, 0.0, 1.0);
static const float3 DEFAULT_TINT_COLOR = float3(0.0, 0.9, 1.0);

static const float EDGE_THRESHOLD = 0.01;
static const float GLOW_FALLOFF_POWER = 2.0;

static const int COLOR_MODE_CYBERPUNK = 0;
static const int COLOR_MODE_TINT = 1;
static const int COLOR_MODE_PALETTE = 2;

static const int GLOW_SAMPLES = 4;

// ============================================================================
// UNIFORMS
// ============================================================================

uniform int as_shader_descriptor <ui_type = "radio"; ui_label = " "; ui_text = "\nCyberpunk-style neon edge glow using depth-based edge detection.\nAdds vivid colored rim lighting to foreground subjects.\n\nAS StageFX | Neon Edge Glow by Leon Aquitaine\n"; > = 0;

// --- Glow Appearance ---
uniform float GlowIntensity < ui_type = "slider"; ui_label = "Glow Intensity"; ui_tooltip = "Overall brightness of the edge glow."; ui_min = GLOWINTENSITY_MIN; ui_max = GLOWINTENSITY_MAX; ui_step = 0.01; ui_category = AS_CAT_APPEARANCE; > = GLOWINTENSITY_DEFAULT;
uniform float GlowWidth < ui_type = "slider"; ui_label = "Glow Width"; ui_tooltip = "How wide the glow extends from detected edges (sampling radius in pixels)."; ui_min = GLOWWIDTH_MIN; ui_max = GLOWWIDTH_MAX; ui_step = 0.5; ui_category = AS_CAT_APPEARANCE; > = GLOWWIDTH_DEFAULT;
uniform float EdgeSensitivity < ui_type = "slider"; ui_label = "Edge Sensitivity"; ui_tooltip = "How subtle depth changes must be to trigger the glow. Higher values detect finer edges."; ui_min = SENSITIVITY_MIN; ui_max = SENSITIVITY_MAX; ui_step = 1.0; ui_category = AS_CAT_APPEARANCE; > = SENSITIVITY_DEFAULT;

// --- Color ---
uniform int ColorMode < ui_type = "combo"; ui_label = "Color Mode"; ui_tooltip = "How the glow color is determined."; ui_items = "Cyberpunk\0Tint Color\0Palette\0"; ui_category = AS_CAT_COLOR; > = COLOR_MODE_CYBERPUNK;
uniform float3 TintColor < ui_type = "color"; ui_label = "Tint Color"; ui_tooltip = "Base glow color when Color Mode is set to Tint."; ui_category = AS_CAT_COLOR; > = DEFAULT_TINT_COLOR;

// --- Palette ---
AS_PALETTE_SELECTION_UI(PalettePreset, "Color Palette", AS_PALETTE_NEON, AS_CAT_COLOR)
AS_DECLARE_CUSTOM_PALETTE(NeonGlow_, AS_CAT_COLOR)

// --- Audio ---
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_BEAT, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(AudioMultiplier, "Glow Intensity", 1.0, 3.0, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(AudioTarget, "None\0Glow Intensity\0", 0)

// --- Stage ---
AS_STAGEDEPTH_UI(EffectDepth)

// --- Final Mix ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_LIGHTEN)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug ---
AS_DEBUG_UI("Off\0Edge Mask\0Glow Color\0Depth\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

float SampleEdgeMagnitude(float2 texcoord, float radius)
{
    float2 pixelSize = ReShade::PixelSize * radius;

    float depth_c  = ReShade::GetLinearizedDepth(texcoord);
    float depth_l  = ReShade::GetLinearizedDepth(texcoord + float2(-pixelSize.x, 0.0));
    float depth_r  = ReShade::GetLinearizedDepth(texcoord + float2( pixelSize.x, 0.0));
    float depth_u  = ReShade::GetLinearizedDepth(texcoord + float2(0.0, -pixelSize.y));
    float depth_d  = ReShade::GetLinearizedDepth(texcoord + float2(0.0,  pixelSize.y));
    float depth_tl = ReShade::GetLinearizedDepth(texcoord + float2(-pixelSize.x, -pixelSize.y));
    float depth_tr = ReShade::GetLinearizedDepth(texcoord + float2( pixelSize.x, -pixelSize.y));
    float depth_bl = ReShade::GetLinearizedDepth(texcoord + float2(-pixelSize.x,  pixelSize.y));
    float depth_br = ReShade::GetLinearizedDepth(texcoord + float2( pixelSize.x,  pixelSize.y));

    // Full Sobel operator
    float sobel_x = -depth_tl - 2.0 * depth_l - depth_bl
                   + depth_tr + 2.0 * depth_r + depth_br;
    float sobel_y = -depth_tl - 2.0 * depth_u - depth_tr
                   + depth_bl + 2.0 * depth_d + depth_br;

    return length(float2(sobel_x, sobel_y));
}

float3 GetGlowColor(float edgeFactor)
{
    if (ColorMode == COLOR_MODE_CYBERPUNK)
    {
        return lerp(CYBERPUNK_OUTER, CYBERPUNK_INNER, saturate(edgeFactor));
    }
    else if (ColorMode == COLOR_MODE_TINT)
    {
        return TintColor;
    }
    else
    {
        // Palette mode: blend across 3 palette colors using edge factor
        float t = saturate(edgeFactor);
        float3 c0, c2, c4;
        if (PalettePreset == AS_PALETTE_CUSTOM)
        {
            c0 = AS_GET_CUSTOM_PALETTE_COLOR(NeonGlow_, 0);
            c2 = AS_GET_CUSTOM_PALETTE_COLOR(NeonGlow_, 2);
            c4 = AS_GET_CUSTOM_PALETTE_COLOR(NeonGlow_, 4);
        }
        else
        {
            c0 = AS_getPaletteColor(PalettePreset, 0);
            c2 = AS_getPaletteColor(PalettePreset, 2);
            c4 = AS_getPaletteColor(PalettePreset, 4);
        }
        return (t < 0.5) ? lerp(c0, c2, t * 2.0) : lerp(c2, c4, (t - 0.5) * 2.0);
    }
}

// ============================================================================
// PIXEL SHADER
// ============================================================================

float4 NeonEdgeGlowPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    AS_DEPTH_EARLY_RETURN(texcoord, EffectDepth)

    float3 originalColor = _as_originalColor.rgb;
    float depth = ReShade::GetLinearizedDepth(texcoord);

    // Sample edges at multiple radii for smooth glow falloff
    float edgeAccum = 0.0;
    float weightAccum = 0.0;

    [unroll]
    for (int i = 0; i < GLOW_SAMPLES; ++i)
    {
        float radius = 1.0 + GlowWidth * (float(i) / float(GLOW_SAMPLES - 1));
        float edge = SampleEdgeMagnitude(texcoord, radius) * EdgeSensitivity;
        float weight = 1.0 - (float(i) / float(GLOW_SAMPLES));
        edgeAccum += saturate(edge) * weight;
        weightAccum += weight;
    }

    float edgeMag = edgeAccum / max(weightAccum, AS_EPSILON);

    // Apply glow falloff
    float glow = pow(saturate(edgeMag), 1.0 / max(GLOW_FALLOFF_POWER, 0.1));

    // Audio reactivity
    float glowFinal = GlowIntensity;
    if (AudioTarget == 1)
    {
        glowFinal = AS_audioModulate(GlowIntensity, AudioSource, AudioMultiplier, true, 0);
    }

    glow = saturate(glow * glowFinal);

    // Get glow color based on mode
    float3 glowColor = GetGlowColor(edgeMag);

    // Debug modes
    if (DebugMode == 1) return float4(edgeMag.xxx, 1.0);
    if (DebugMode == 2) return float4(glowColor * glow, 1.0);
    if (DebugMode == 3) return float4(depth.xxx, 1.0);

    // Additive composite: glow only adds light
    float3 effectColor = originalColor + glowColor * glow;
    return float4(AS_composite(effectColor, originalColor, BlendMode, BlendAmount), 1.0);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
} // namespace AS_NeonEdgeGlow

technique AS_VFX_NeonEdgeGlow <
    ui_label = "[AS] VFX: Neon Edge Glow";
    ui_tooltip = "Cyberpunk-style colored edge glow on foreground subjects using depth-based edge detection.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = AS_NeonEdgeGlow::NeonEdgeGlowPS;
    }
}

#endif // __AS_VFX_NeonEdgeGlow_1_fx
