/**
 * AS_GFX_RippedPaper.1.fx - Ripped Paper Band Effect
 * Author: Gemini (Generated for User)
 * License: CC BY 4.0
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader renders a stylized horizontal band across the screen, simulating the
 * appearance of a strip of paper with torn, irregular edges. It's designed to be
 * used as a graphic overlay or a background element.
 *
 * FEATURES:
 * - Procedurally generated torn edges using Simplex noise.
 * - Adjustable band height and vertical positioning.
 * - Customizable edge roughness, detail frequency, and feathering.
 * - Optional subtle highlights and shadows near the edges to enhance realism.
 * - Choice between using the scene color or a solid color for the background.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Defines a base horizontal band based on UI parameters.
 * 2. Uses Simplex noise to displace the top and bottom edges of the band,
 * creating an irregular "torn" look. The noise is varied along the x-axis.
 * 3. Applies feathering to the torn edges using smoothstep for a soft transition.
 * 4. Renders the paper color within the band and allows the background (either
 * scene color or a solid color) to show through outside the band.
 * 5. Optionally adds subtle highlights and shadows to the paper near the
 * torn edges to give a slight sense of depth or texture.
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_GFX_RIPPEDPAPER_1_FX
#define __AS_GFX_RIPPEDPAPER_1_FX

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_MAX_RESOLUTION_AUTOSCALE, not strictly needed here but good practice
#include "AS_Noise.1.fxh"  // For AS_SimplexNoise2D

// ============================================================================
// UI UNIFORMS & CONSTANTS
// ============================================================================

// --- Category: Band Settings ---
static const float RIPPEDPAPER_HEIGHT_MIN = 0.01f;
static const float RIPPEDPAPER_HEIGHT_MAX = 1.0f;
static const float RIPPEDPAPER_HEIGHT_DEFAULT = 0.3f;
uniform float BandHeight < ui_type = "slider"; ui_label = "Band Height"; ui_tooltip = "Controls the height of the paper band (fraction of screen height)."; ui_min = RIPPEDPAPER_HEIGHT_MIN; ui_max = RIPPEDPAPER_HEIGHT_MAX; ui_step = 0.01f; ui_category = "Band Settings"; > = RIPPEDPAPER_HEIGHT_DEFAULT;

static const float RIPPEDPAPER_CENTER_Y_MIN = 0.0f;
static const float RIPPEDPAPER_CENTER_Y_MAX = 1.0f;
static const float RIPPEDPAPER_CENTER_Y_DEFAULT = 0.5f;
uniform float BandCenterY < ui_type = "slider"; ui_label = "Band Vertical Position"; ui_tooltip = "Vertical center of the band (0.0 = top, 0.5 = center, 1.0 = bottom)."; ui_min = RIPPEDPAPER_CENTER_Y_MIN; ui_max = RIPPEDPAPER_CENTER_Y_MAX; ui_step = 0.01f; ui_category = "Band Settings"; > = RIPPEDPAPER_CENTER_Y_DEFAULT;

// --- Category: Edge Appearance ---
static const float RIPPEDPAPER_ROUGHNESS_MIN = 0.0f;
static const float RIPPEDPAPER_ROUGHNESS_MAX = 0.1f;
static const float RIPPEDPAPER_ROUGHNESS_DEFAULT = 0.025f;
uniform float EdgeRoughness < ui_type = "slider"; ui_label = "Edge Roughness"; ui_tooltip = "Amplitude of the torn edge effect (displacement amount)."; ui_min = RIPPEDPAPER_ROUGHNESS_MIN; ui_max = RIPPEDPAPER_ROUGHNESS_MAX; ui_step = 0.001f; ui_category = "Edge Appearance"; > = RIPPEDPAPER_ROUGHNESS_DEFAULT;

static const float RIPPEDPAPER_FREQUENCY_MIN = 1.0f;
static const float RIPPEDPAPER_FREQUENCY_MAX = 60.0f;
static const float RIPPEDPAPER_FREQUENCY_DEFAULT = 20.0f;
uniform float EdgeFrequency < ui_type = "slider"; ui_label = "Edge Detail Frequency"; ui_tooltip = "Scale of the noise pattern for edge details. Higher values = finer, more frequent tears."; ui_min = RIPPEDPAPER_FREQUENCY_MIN; ui_max = RIPPEDPAPER_FREQUENCY_MAX; ui_step = 0.1f; ui_category = "Edge Appearance"; > = RIPPEDPAPER_FREQUENCY_DEFAULT;

static const float RIPPEDPAPER_FEATHER_MIN = 0.0001f;
static const float RIPPEDPAPER_FEATHER_MAX = 0.05f;
static const float RIPPEDPAPER_FEATHER_DEFAULT = 0.005f;
uniform float EdgeFeather < ui_type = "slider"; ui_label = "Edge Feathering"; ui_tooltip = "Softness of the torn edges. Higher values = more blur/smoother transition."; ui_min = RIPPEDPAPER_FEATHER_MIN; ui_max = RIPPEDPAPER_FEATHER_MAX; ui_step = 0.0001f; ui_category = "Edge Appearance"; > = RIPPEDPAPER_FEATHER_DEFAULT;

// --- Category: Color & Shading ---
uniform float3 PaperColor < ui_type = "color"; ui_label = "Paper Color"; ui_category = "Color & Shading"; > = float3(0.92f, 0.92f, 0.88f);

static const float RIPPEDPAPER_SHADOW_INT_MIN = 0.0f;
static const float RIPPEDPAPER_SHADOW_INT_MAX = 1.0f;
static const float RIPPEDPAPER_SHADOW_INT_DEFAULT = 0.4f;
uniform float ShadowIntensity < ui_type = "slider"; ui_label = "Edge Shadow Intensity"; ui_tooltip = "Strength of the subtle darkening on the paper near torn edges."; ui_min = RIPPEDPAPER_SHADOW_INT_MIN; ui_max = RIPPEDPAPER_SHADOW_INT_MAX; ui_step = 0.01f; ui_category = "Color & Shading"; > = RIPPEDPAPER_SHADOW_INT_DEFAULT;

static const float RIPPEDPAPER_HIGHLIGHT_INT_MIN = 0.0f;
static const float RIPPEDPAPER_HIGHLIGHT_INT_MAX = 1.0f;
static const float RIPPEDPAPER_HIGHLIGHT_INT_DEFAULT = 0.5f;
uniform float HighlightIntensity < ui_type = "slider"; ui_label = "Edge Highlight Intensity"; ui_tooltip = "Strength of the subtle highlight on the paper near torn edges."; ui_min = RIPPEDPAPER_HIGHLIGHT_INT_MIN; ui_max = RIPPEDPAPER_HIGHLIGHT_INT_MAX; ui_step = 0.01f; ui_category = "Color & Shading"; > = RIPPEDPAPER_HIGHLIGHT_INT_DEFAULT;

uniform bool UseSceneColorForBackground < ui_label = "Use Scene Color for Background"; ui_tooltip = "If checked, uses the original scene color behind the paper. If unchecked, uses a solid background color."; ui_category = "Color & Shading"; > = true;
uniform float3 BackgroundColorSolid < ui_type = "color"; ui_label = "Solid Background Color (if not using scene)"; ui_category = "Color & Shading"; > = float3(0.1f, 0.1f, 0.1f);


// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_RippedPaper(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 original_color = tex2D(ReShade::BackBuffer, texcoord);
    float3 background_final_color = UseSceneColorForBackground ? original_color.rgb : BackgroundColorSolid;

    // Base band definition
    float band_half_height = BandHeight * 0.5f;
    float nominal_band_top_y = BandCenterY - band_half_height;
    float nominal_band_bottom_y = BandCenterY + band_half_height;

    // Noise for edges (Simplex noise returns approx -1 to 1)
    // Different y-seeds for noise to make top and bottom edges independent
    float noise_val_top = AS_PerlinNoise2D(float2(texcoord.x * EdgeFrequency, 0.375f));
    float noise_val_bottom = AS_PerlinNoise2D(float2(texcoord.x * EdgeFrequency, 0.812f));

    // Apply roughness: positive noise displacement makes paper extend upwards (smaller y) for top, downwards (larger y) for bottom
    float actual_band_top_y = nominal_band_top_y - (noise_val_top * EdgeRoughness);
    float actual_band_bottom_y = nominal_band_bottom_y + (noise_val_bottom * EdgeRoughness);
    
    // Ensure bottom is not above top after noise
    if (actual_band_bottom_y < actual_band_top_y + EdgeFeather * 2.0f) { // Ensure min thickness for feathering
        actual_band_bottom_y = actual_band_top_y + EdgeFeather * 2.0f;
    }


    // Alpha calculation for feathered edges
    float dist_to_top_edge = texcoord.y - actual_band_top_y;
    float alpha_top = smoothstep(0.0f, EdgeFeather, dist_to_top_edge);

    float dist_to_bottom_edge = actual_band_bottom_y - texcoord.y;
    float alpha_bottom = smoothstep(0.0f, EdgeFeather, dist_to_bottom_edge);

    float paper_alpha = saturate(alpha_top * alpha_bottom);

    // Paper color with edge highlighting/shadowing
    float3 modified_paper_color = PaperColor;

    if (paper_alpha > 0.001f) // Apply only if likely on paper
    {
        // Top Edge shading
        float dist_inside_top = dist_to_top_edge; // Positive when inside the band from top edge
        if (dist_inside_top > 0.0f)
        {
            float highlight_factor_top = smoothstep(0.0f, EdgeFeather * 0.6f, dist_inside_top) * (1.0f - smoothstep(EdgeFeather * 0.6f, EdgeFeather * 1.2f, dist_inside_top));
            modified_paper_color = lerp(modified_paper_color, PaperColor * (1.0f + HighlightIntensity * 0.3f), highlight_factor_top);

            float shadow_factor_top = smoothstep(EdgeFeather * 0.7f, EdgeFeather * 1.4f, dist_inside_top) * (1.0f - smoothstep(EdgeFeather * 1.4f, EdgeFeather * 2.0f, dist_inside_top));
            modified_paper_color = lerp(modified_paper_color, PaperColor * (1.0f - ShadowIntensity * 0.3f), shadow_factor_top);
        }

        // Bottom Edge shading
        float dist_inside_bottom = dist_to_bottom_edge; // Positive when inside the band from bottom edge
         if (dist_inside_bottom > 0.0f)
        {
            float highlight_factor_bottom = smoothstep(0.0f, EdgeFeather * 0.6f, dist_inside_bottom) * (1.0f - smoothstep(EdgeFeather * 0.6f, EdgeFeather * 1.2f, dist_inside_bottom));
            modified_paper_color = lerp(modified_paper_color, PaperColor * (1.0f + HighlightIntensity * 0.3f), highlight_factor_bottom);
            
            float shadow_factor_bottom = smoothstep(EdgeFeather * 0.7f, EdgeFeather * 1.4f, dist_inside_bottom) * (1.0f - smoothstep(EdgeFeather * 1.4f, EdgeFeather * 2.0f, dist_inside_bottom));
            modified_paper_color = lerp(modified_paper_color, PaperColor * (1.0f - ShadowIntensity * 0.3f), shadow_factor_bottom);
        }
        modified_paper_color = saturate(modified_paper_color);
    }
    
    float3 final_color = lerp(background_final_color, modified_paper_color, paper_alpha);

    return float4(final_color, original_color.a);
}


// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_GFX_RippedPaper < ui_tooltip = "Renders a horizontal band with stylized torn paper edges."; >
{
    pass RippedPaperPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_RippedPaper;
    }
}

#endif // __AS_GFX_RIPPEDPAPER_1_FX