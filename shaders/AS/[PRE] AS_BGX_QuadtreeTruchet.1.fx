/**
 * AS_BGX_QuadtreeTruchet.1.fx - Multiscale, multitile, overlapped, weaved Truchet pattern.
 * Author: Shane (Original Shadertoy), Leon Aquitaine (ReShade Adaptation)
 * License: CC BY-NC-SA 3.0 (Original Shadertoy License) / CC BY 4.0 (AS-StageFX Adaptation)
 * You are free to use, share, and adapt this shader for any purpose, including commercially,
 * as long as you provide attribution to both Shane and Leon Aquitaine.
 * Original Source: https://www.shadertoy.com/view/4t3BW4
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Renders a "Quadtree Truchet" pattern, which is a multiscale, multitile, overlapped,
 * and optionally weaved Truchet pattern. The effect generates complex geometric designs
 * by recursively subdividing a grid and rendering Truchet tiles at different scales
 * and with varying probabilities.
 *
 * FEATURES:
 * - Quadtree-based recursive pattern generation over 3 levels.
 * - Overlapping tiles with rules to prevent smaller tiles drawing over larger ones.
 * - Multiple color modes: White, Spectrum, and Pink.
 * - Optional "stacked tiles" view to visualize layering.
 * - Optional "line tiles" for an art-deco appearance, including a mild weave effect.
 * - Animated rotation and vertical panning of the pattern.
 * - Debug view to show the underlying quadtree grid structure.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Screen coordinates are normalized and centered, then scaled for the pattern.
 * 2. The pattern space is animated with global rotation and vertical panning.
 * 3. A 3-level quadtree iteration process begins:
 * a. For each level, a 3x3 neighborhood of cells is considered to handle tile overlaps.
 * b. Cell IDs and random values (using AS_hash22) determine if a tile is rendered at the current scale,
 * its orientation, and its specific Truchet components (arcs, lines, circles).
 * c. Logic prevents smaller tiles from drawing over already placed larger tiles from previous levels.
 * d. Distance fields for two "colors" per tile (d and d2) and grid lines are accumulated.
 * 4. After all levels, the distance fields are combined based on whether "stacked" or "continuous" view is selected.
 * 5. Colors are applied based on the selected ColorMode. Spectrum and Pink modes use screen coordinates for gradients.
 * 6. Optional grid visualization can be overlaid.
 * 7. Final color is blended with the backbuffer.
 *
 * ===================================================================================
 */

#ifndef __AS_BGX_QuadtreeTruchet_1_fx
#define __AS_BGX_QuadtreeTruchet_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_getAnimationTime, AS_applyBlend, AS_PI, etc.
#include "AS_Noise.1.fxh" // For AS_hash22

// ============================================================================
// UI: TUNABLE CONSTANTS & PARAMETERS
// ============================================================================

// Pattern Settings
static const float PATTERN_SCALE_MIN = 0.5, PATTERN_SCALE_MAX = 20.0, PATTERN_SCALE_DEFAULT = 5.0;
static const float TILE_STROKE_THICKNESS_MIN = 0.05, TILE_STROKE_THICKNESS_MAX = 0.5, TILE_STROKE_THICKNESS_DEFAULT = 1.0/3.0;
static const float GRID_LINE_WIDTH_MIN = 0.001, GRID_LINE_WIDTH_MAX = 0.05, GRID_LINE_WIDTH_DEFAULT = 0.01;

uniform float PatternScale < ui_type = "slider"; ui_label = "Pattern Scale"; ui_tooltip = "Initial zoom level of the pattern."; ui_min = PATTERN_SCALE_MIN; ui_max = PATTERN_SCALE_MAX; ui_category = "Pattern Settings"; > = PATTERN_SCALE_DEFAULT;
uniform float TileStrokeThickness < ui_type = "slider"; ui_label = "Tile Stroke Thickness"; ui_tooltip = "Thickness of the Truchet tile strokes, relative to tile radius."; ui_min = TILE_STROKE_THICKNESS_MIN; ui_max = TILE_STROKE_THICKNESS_MAX; ui_category = "Pattern Settings"; > = TILE_STROKE_THICKNESS_DEFAULT;
uniform bool EnableLineTiles < ui_label = "Enable Line Tiles (Art Deco)"; ui_tooltip = "Replaces some arcs with straight lines, creating an art-deco look. Also enables a mild weave effect."; ui_category = "Pattern Settings"; > = false;

// Style & Color
uniform int ColorMode < ui_type = "combo"; ui_label = "Color Mode"; ui_items = "White\0Spectrum\0Pink\0"; ui_tooltip = "Selects the color scheme for the pattern."; ui_category = "Palette & Style"; > = 1;
uniform bool EnableStackedTiles < ui_label = "Enable Stacked Tiles View"; ui_tooltip = "Shows tile layers stacked, revealing the generation process. Disables continuous surface look."; ui_category = "Palette & Style"; > = false;

// Animation Controls
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")
static const float ANIM_TIME_SCALE_MIN = 0.01, ANIM_TIME_SCALE_MAX = 2.0, ANIM_TIME_SCALE_DEFAULT = 0.125; // Original was iTime/8
static const float ROTATION_SPEED_MIN = 0.0, ROTATION_SPEED_MAX = 1.0, ROTATION_SPEED_DEFAULT = 0.25; // Adjusted for visual feel
static const float PAN_SPEED_MIN = -2.0, PAN_SPEED_MAX = 2.0, PAN_SPEED_DEFAULT = 0.2; // Adjusted for visual feel

uniform float AnimationTimeScale < ui_type = "slider"; ui_label = "Animation Time Scale Factor"; ui_tooltip = "Scales the internal time used for animations (e.g., rotation cycle speed)."; ui_min = ANIM_TIME_SCALE_MIN; ui_max = ANIM_TIME_SCALE_MAX; ui_category = "Animation"; > = ANIM_TIME_SCALE_DEFAULT;
uniform float OverallRotationSpeed < ui_type = "slider"; ui_label = "Overall Rotation Speed"; ui_tooltip = "Speed of the main pattern rotation."; ui_min = ROTATION_SPEED_MIN; ui_max = ROTATION_SPEED_MAX; ui_category = "Animation"; > = ROTATION_SPEED_DEFAULT;
uniform float PanSpeedY < ui_type = "slider"; ui_label = "Vertical Pan Speed"; ui_tooltip = "Speed of the vertical panning animation."; ui_min = PAN_SPEED_MIN; ui_max = PAN_SPEED_MAX; ui_category = "Animation"; > = PAN_SPEED_DEFAULT;

// Final Mix
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// Debug
uniform bool ShowGrid < ui_label = "Show Quadtree Grid"; ui_tooltip = "Overlays the quadtree grid structure for debugging."; ui_category = "Debug"; > = false;
uniform float GridLineWidth < ui_type = "slider"; ui_label = "Debug Grid Line Width"; ui_tooltip = "Width of the debug grid lines."; ui_min = GRID_LINE_WIDTH_MIN; ui_max = GRID_LINE_WIDTH_MAX; ui_category = "Debug"; > = GRID_LINE_WIDTH_DEFAULT;


// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Standard 2D rotation matrix.
float2x2 r2(in float a) {
    float c = cos(a);
    float s = sin(a);
    return float2x2(c, s, -s, c);
}

// ============================================================================
// PIXEL SHADER
// ============================================================================

float4 PS_ASBGXQuadtreeTruchet(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float4 orig_color = tex2D(ReShade::BackBuffer, texcoord);
    float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);

    // Screen coordinates, centered, aspect corrected (y ranges approx -0.5 to 0.5).
    float2 uv_screen_centered = (texcoord - 0.5) * float2(ReShade::AspectRatio, 1.0);

    // Scaling, rotation and translation for pattern space.
    float2 oP = uv_screen_centered * PatternScale;
    float anim_time_scaled = time * AnimationTimeScale; // Original used iTime/8.
    oP = mul(r2(sin(anim_time_scaled) * AS_PI / 8.0 * OverallRotationSpeed), oP); // AS_PI/8.0 part of original angle calc.
    oP.y -= PanSpeedY * time; // Original was oP -= vec2(cos(iTime/8.)*0., -iTime); which simplifies to oP.y += iTime with speed control

    // Distance field values -- One for each color. They're "float4"s to hold the three
    // layers and an an unused spare. The grid vector holds grid values.
    float4 d = float4(100000.0, 100000.0, 100000.0, 100000.0);
    float4 d2 = float4(100000.0, 100000.0, 100000.0, 100000.0);
    float4 grid = float4(100000.0, 100000.0, 100000.0, 100000.0);

    // Random constants for each layer. The X values are Truchet flipping threshold
    // values, and the Y values represent the chance that a particular sized tile will render.
    static const float2 rndTh[3] = { float2(0.5, 0.35), float2(0.5, 0.7), float2(0.5, 1.0) };

    // The scale dimensions. Gets multiplied by two each iteration.
    float dim = 1.0;
    float stroke_half_thickness_factor = TileStrokeThickness / 2.0;

    // Three tile levels.
    for (int k = 0; k < 3; k++) {
        // Base cell ID.
        float2 ip = floor(oP * dim);

        for (int j = -1; j <= 1; j++) {            for (int i = -1; i <= 1; i++) {
                // The neighboring cell ID.
                float2 current_cell_id = ip + float2(i, j);
                float2 rndIJ = AS_Hash22VariantB(current_cell_id); // Using Shadertoy-compatible hash

                // Cell IDs for previous dimensions to check for overlaps.
                float2 rndIJ2 = AS_Hash22VariantB(floor(current_cell_id / 2.0));
                float2 rndIJ4 = AS_Hash22VariantB(floor(current_cell_id / 4.0));

                if (k == 1 && rndIJ2.y < rndTh[0].y) continue;
                if (k == 2 && (rndIJ2.y < rndTh[1].y || rndIJ4.y < rndTh[0].y)) continue;

                if (rndIJ.y < rndTh[k].y) {
                    // Local cell coordinates.
                    float2 p = oP - (ip + 0.5 + float2(i, j)) / dim;

                    // The grid square.
                    float square = max(abs(p.x), abs(p.y)) - 0.5 / dim;

                    // The grid lines (for debug).
                    float gr = abs(square) - (GridLineWidth / 2.0) / dim; // Scale grid line width with dim
                    grid.x = min(grid.x, gr);

                    // TILE COLOR ONE.
                    if (rndIJ.x < rndTh[k].x) p.xy = p.yx;
                    if (frac(rndIJ.x * 57.543 + 0.37) < rndTh[k].x) p.x = -p.x;

                    float2 p2 = abs(float2(p.y - p.x, p.x + p.y) * 0.70710678118) - float2(0.5, 0.5) * 0.70710678118 / dim;
                    float c3 = length(p2) - stroke_half_thickness_factor / dim; // (0.5/3.0) from original means thickness is 1/3 of radius (0.5)

                    float c, c_alt; // c_alt is c2 in original

                    // Truchet arc one.
                    c = abs(length(p - float2(-0.5, 0.5) / dim) - 0.5 / dim) - stroke_half_thickness_factor / dim;

                    // Truchet arc two or alternative.
                    if (frac(rndIJ.x * 157.763 + 0.49) > 0.35) {
                        c_alt = abs(length(p - float2(0.5, -0.5) / dim) - 0.5 / dim) - stroke_half_thickness_factor / dim;
                    } else {
                        c_alt = length(p - float2(0.5, 0.0) / dim) - stroke_half_thickness_factor / dim;
                        c_alt = min(c_alt, length(p - float2(0.0, -0.5) / dim) - stroke_half_thickness_factor / dim);
                    }

                    if (EnableLineTiles) {
                        if (frac(rndIJ.x * 113.467 + 0.51) < 0.35) {
                            c = abs(p.x) - stroke_half_thickness_factor / dim;
                        }
                        if (frac(rndIJ.x * 123.853 + 0.49) < 0.35) {
                            c_alt = abs(p.y) - stroke_half_thickness_factor / dim;
                        }
                    }

                    float truchet = min(c, c_alt);

                    if (EnableLineTiles) { // Weave effect
                        float lne = abs(c - (0.5 / 12.0 / 4.0) / dim) - (0.5 / 12.0 / 4.0) / dim; // Original constants for weave detail
                        truchet = max(truchet, -lne);
                    }
                    
                    c = min(c3, max(square, truchet));
                    d[k] = min(d[k], c);

                    // TILE COLOR TWO.
                    float2 p_abs_local = abs(p) - 0.5 / dim; // p relative to corner for corner circles
                    float l = length(p_abs_local);
                    c = min(l - stroke_half_thickness_factor / dim, square); // circles at grid vertices + square
                    d2[k] = min(d2[k], c);

                    // For grid debug view
                    grid.y = min(grid.y, l - (0.5 / 8.0) / sqrt(dim)); // circle radius for grid points
                    grid.z = min(grid.z, l); // distance to closest grid vertex
                    grid.w = dim; // current dimension for scaling debug visuals
                }
            }
        }
        dim *= 2.0; // Subdivide for next level
    }

    // The scene color.
    float3 col = float3(0.25, 0.25, 0.25); // Initial grey background

    // Resolution based falloff for smoothing.
    float fo = ReShade::PixelSize.y * 5.0; // 5 pixels

    // Tile colors.
    float3 pCol1, pCol2;
    switch (ColorMode) {
        case 0: // White
            pCol1 = float3(1.0, 1.0, 1.0);
            pCol2 = float3(0.125, 0.125, 0.125);
            break;
        case 1: // Spectrum
            pCol1 = float3(0.7, 1.4, 0.4);
            pCol2 = float3(0.125, 0.125, 0.125);
            break;
        case 2: // Pink
            pCol1 = lerp(float3(1.0, 0.1, 0.2), float3(1.0, 0.1, 0.5), uv_screen_centered.y * 0.5 + 0.5);
            pCol2 = float3(0.1, 0.02, 0.06);
            break;
        default: // White
            pCol1 = float3(1.0, 1.0, 1.0);
            pCol2 = float3(0.125, 0.125, 0.125);
            break;
    }
    
    // Simple line pattern for non-spectrum modes if not stacked
    float pat3_lines = clamp(sin((oP.x - oP.y) * AS_TWO_PI * ReShade::ScreenSize.y / 24.0) * 1.0 + 0.9, 0.0, 1.0) * 0.25 + 0.75;


    if (EnableStackedTiles) {
        float pw = 0.02; // Outline width for stacked view
        d -= pw / 2.0;
        d2 -= pw / 2.0;

        for (int k_render = 0; k_render < 3; k_render++) {
            col = lerp(col, float3(0,0,0), (1.0 - smoothstep(0.0, fo * 5.0, d2[k_render])) * 0.35);
            col = lerp(col, float3(0,0,0), 1.0 - smoothstep(0.0, fo, d2[k_render]));
            col = lerp(col, pCol2, 1.0 - smoothstep(0.0, fo, d2[k_render] + pw));

            col = lerp(col, float3(0,0,0), (1.0 - smoothstep(0.0, fo * 5.0, d[k_render])) * 0.35);
            col = lerp(col, float3(0,0,0), 1.0 - smoothstep(0.0, fo, d[k_render]));
            col = lerp(col, pCol1, 1.0 - smoothstep(0.0, fo, d[k_render] + pw));
            
            // Swap colors for next layer
            float3 temp = pCol1; pCol1 = pCol2; pCol2 = temp;
        }
        col *= pat3_lines;

    } else { // Continuous surface
        float d_combined = d.x; // Use d.x as the primary working distance
        d_combined = max(d2.x, -d.x); // Start with first level combination
        d_combined = min(max(d_combined, -d2.y), d.y); // Combine with second level
        d_combined = max(min(d_combined, d2.z), -d.z); // Combine with third level

        if (ColorMode == 1) { // Spectrum specific coloring
            float pat_spectrum_stripes = clamp(-sin(d_combined * AS_TWO_PI * 20.0) - 0.0, 0.0, 1.0);
            col *= pat_spectrum_stripes;

            d_combined = -(d_combined + 0.03); // Invert and offset for rendering

            col = lerp(col, float3(0,0,0), (1.0 - smoothstep(0.0, fo * 5.0, d_combined)));
            col = lerp(col, float3(0,0,0), 1.0 - smoothstep(0.0, fo, d_combined));
            col = lerp(col, float3(0.8, 1.2, 0.6), 1.0 - smoothstep(0.0, fo * 2.0, d_combined + 0.02));
            col = lerp(col, float3(0,0,0), 1.0 - smoothstep(0.0, fo * 2.0, d_combined + 0.03));
            float pat2_highlight_spectrum = clamp(sin(d_combined * AS_TWO_PI * 16.0) * 1.0 + 0.9, 0.0, 1.0) * 0.3 + 0.7;
            col = lerp(col, pCol1 * pat2_highlight_spectrum, 1.0 - smoothstep(0.0, fo * 2.0, d_combined + 0.05));
            
            float sh_spectrum = clamp(0.75 + d_combined * 2.0, 0.0, 1.0); // Shading for spectrum
            col *= sh_spectrum;

        } else { // White or Pink coloring
            col = pCol1; // Base color

            col = lerp(col, float3(0,0,0), (1.0 - smoothstep(0.0, fo * 5.0, d_combined)) * 0.35);
            col = lerp(col, float3(0,0,0), 1.0 - smoothstep(0.0, fo, d_combined));
            col = lerp(col, pCol2, 1.0 - smoothstep(0.0, fo, d_combined + 0.02));

            col *= pat3_lines;
        }
    }

    // Mild spotlight.
    col *= max(1.15 - length(uv_screen_centered) * 0.5, 0.0);

    // Debug Grid Visualization
    if (ShowGrid) {
        float3 vCol1 = float3(0.8, 1.0, 0.7);
        float3 vCol2 = float3(1.0, 0.7, 0.4);
        if (ColorMode == 2) { // Pink mode adjustment for grid colors
            vCol1 = vCol1.zxy;
            vCol2 = vCol2.zyx;
        }

        // Grid lines (grid.x contains sdf for lines)
        float3 bg_col_for_grid = col; // Store current color to mix with grid
        float grid_line_sdf = grid.x; // Already scaled by 1/dim
        col = lerp(col, float3(0,0,0), (1.0 - smoothstep(0.0, 0.02, grid_line_sdf - 0.02)) * 0.7);
        col = lerp(col, vCol1 + bg_col_for_grid / 2.0, 1.0 - smoothstep(0.0, 0.01, grid_line_sdf));
        
        // Circles on grid vertices (grid.y contains sdf for circles, grid.w has current dim for scaling)
        float grid_point_fo = ReShade::PixelSize.y * 10.0 / sqrt(grid.w); // Scale with grid level
        float grid_point_sdf = grid.y; 
        col = lerp(col, float3(0,0,0), (1.0 - smoothstep(0.0, grid_point_fo * 3.0, grid_point_sdf - 0.02)) * 0.5);
        col = lerp(col, float3(0,0,0), 1.0 - smoothstep(0.0, grid_point_fo, grid_point_sdf - 0.02));
        col = lerp(col, vCol2, 1.0 - smoothstep(0.0, grid_point_fo, grid_point_sdf));
        // Original also had grid.z for another circle layer, omitting for slight simplification of debug
    }
    
    // Mix the colors for spectrum mode based on screen UVs
    if (ColorMode == 1) { // Spectrum
        col = lerp(col, col.yxz, uv_screen_centered.y * 0.75 + 0.5);
        col = lerp(col, col.zxy, uv_screen_centered.x * 0.7 + 0.5); // Original was uv.x * .7
    }

    // Rough gamma correction from original, and output.
    col = sqrt(max(col, 0.0));
    float4 final_effect_color = float4(col, 1.0);

    return AS_applyBlend(final_effect_color, orig_color, BlendMode, BlendAmount);
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_BGX_QuadtreeTruchet <
    ui_tooltip = "Renders a multiscale, multitile, overlapped, weaved Truchet pattern.\n"
                 "Based on 'Quadtree Truchet' by Shane on Shadertoy.\n"
                 "Features recursive pattern generation, optional art-deco styling, and animation.";
> {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_ASBGXQuadtreeTruchet;
    }
}

#endif // __AS_BGX_QuadtreeTruchet_1_fx