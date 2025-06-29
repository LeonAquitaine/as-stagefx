/**
 * AS_BGX_QuadtreeTruchet.1.fx - Multiscale Recursive Truchet Pattern
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Based on "Quadtree Truchet" by Shane (2018-06-21)
 * Shadertoy: https://www.shadertoy.com/view/4t3BW4
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a sophisticated Quadtree Truchet pattern with multiscale, overlapping tiles.
 * Generates complex geometric designs through recursive grid subdivision and probabilistic tile placement.
 *
 * FEATURES:
 * - Quadtree-based recursive pattern generation over 3 hierarchical levels
 * - Overlapping tile system with intelligent collision prevention
 * - Full AS palette system support with 24 built-in palettes plus custom options
 * - Multiple color application modes: Two-Tone, Spectrum Blend, and Gradient Blend
 * - Optional "stacked tiles" view to visualize the generation process
 * - Art Deco style with line tiles and weave effects
 * - Animated rotation and panning with customizable speed controls
 * - Audio reactivity for pattern scale, rotation, seed, and tile density
 * - Stage positioning controls for performance integration
 * - Debug visualization of the underlying quadtree structure
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Transforms screen coordinates into pattern space with scaling, rotation, and offset
 * 2. Iterates through 3 quadtree levels with increasing subdivision density
 * 3. For each level, evaluates a 3x3 neighborhood to handle tile overlaps properly
 * 4. Uses hash-based randomization to determine tile placement, orientation, and style
 * 5. Generates distance fields for dual-color Truchet arcs, lines, and corner elements
 * 6. Applies overlap prevention logic to maintain visual hierarchy across scales
 * 7. Combines distance fields into final pattern based on selected rendering mode
 * 8. Maps results through the palette system with optional spectrum/gradient effects
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_QuadtreeTruchet_1_fx
#define __AS_BGX_QuadtreeTruchet_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_getAnimationTime, AS_applyBlend, AS_PI, etc.
#include "AS_Noise.1.fxh" // For AS_hash22
#include "AS_Palette.1.fxh" // For AS palette support

// ============================================================================
// UI: TUNABLE CONSTANTS & PARAMETERS
// ============================================================================

// Pattern Settings
static const float PATTERN_SCALE_MIN = 0.5, PATTERN_SCALE_MAX = 20.0, PATTERN_SCALE_DEFAULT = 15.0;
static const float TILE_STROKE_THICKNESS_MIN = 0.05, TILE_STROKE_THICKNESS_MAX = 0.5, TILE_STROKE_THICKNESS_DEFAULT = 1.0/3.0;
static const float GRID_LINE_WIDTH_MIN = 0.001, GRID_LINE_WIDTH_MAX = 0.05, GRID_LINE_WIDTH_DEFAULT = 0.01;

// Pattern Distribution
static const float LARGE_TILE_PROBABILITY_MIN = 0.1, LARGE_TILE_PROBABILITY_MAX = 0.9, LARGE_TILE_PROBABILITY_DEFAULT = 0.35;
static const float MEDIUM_TILE_PROBABILITY_MIN = 0.3, MEDIUM_TILE_PROBABILITY_MAX = 0.9, MEDIUM_TILE_PROBABILITY_DEFAULT = 0.7;
static const float PATTERN_SEED_MIN = 1.0, PATTERN_SEED_MAX = 100.0, PATTERN_SEED_DEFAULT = 57.0;

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nBased on 'Quadtree Truchet' by Shane\nLink: https://www.shadertoy.com/view/4t3BW4\nLicence: CC Share-Alike Non-Commercial\n\n";>;

uniform float PatternScale < ui_type = "slider"; ui_label = "Pattern Scale"; ui_tooltip = "Initial zoom level of the pattern."; ui_min = PATTERN_SCALE_MIN; ui_max = PATTERN_SCALE_MAX; ui_category = "Pattern Settings"; > = PATTERN_SCALE_DEFAULT;
uniform float TileStrokeThickness < ui_type = "slider"; ui_label = "Tile Stroke Thickness"; ui_tooltip = "Thickness of the Truchet tile strokes, relative to tile radius."; ui_min = TILE_STROKE_THICKNESS_MIN; ui_max = TILE_STROKE_THICKNESS_MAX; ui_category = "Pattern Settings"; > = TILE_STROKE_THICKNESS_DEFAULT;
uniform bool EnableLineTiles < ui_label = "Enable Line Tiles (Art Deco)"; ui_tooltip = "Replaces some arcs with straight lines, creating an art-deco look. Also enables a mild weave effect."; ui_category = "Pattern Settings"; > = false;

// Pattern Distribution
uniform float LargeTileProbability < ui_type = "slider"; ui_label = "Large Tile Density"; ui_tooltip = "Controls how many large tiles appear in the pattern. Lower values = fewer tiles."; ui_min = LARGE_TILE_PROBABILITY_MIN; ui_max = LARGE_TILE_PROBABILITY_MAX; ui_category = "Pattern Distribution"; > = LARGE_TILE_PROBABILITY_DEFAULT;
uniform float MediumTileProbability < ui_type = "slider"; ui_label = "Medium Tile Density"; ui_tooltip = "Controls how many medium tiles appear in the pattern. Lower values = fewer tiles."; ui_min = MEDIUM_TILE_PROBABILITY_MIN; ui_max = MEDIUM_TILE_PROBABILITY_MAX; ui_category = "Pattern Distribution"; > = MEDIUM_TILE_PROBABILITY_DEFAULT;
uniform float PatternSeed < ui_type = "slider"; ui_label = "Pattern Seed"; ui_tooltip = "Changes the random pattern without affecting other parameters. Different values create different arrangements."; ui_min = PATTERN_SEED_MIN; ui_max = PATTERN_SEED_MAX; ui_category = "Pattern Distribution"; > = PATTERN_SEED_DEFAULT;

// Style & Color
AS_PALETTE_SELECTION_UI(PaletteSelection, "Color Palette", AS_PALETTE_CLASSIC_VU, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(TruchetPalette, "Palette & Style")
uniform int ColorMode < ui_type = "combo"; ui_label = "Color Application Mode"; ui_items = "Two-Tone\0Spectrum Blend\0Gradient Blend\0"; ui_tooltip = "How colors from the palette are applied to the pattern."; ui_category = "Palette & Style"; > = 1;
uniform bool EnableStackedTiles < ui_label = "Enable Stacked Tiles View"; ui_tooltip = "Shows tile layers stacked, revealing the generation process. Disables continuous surface look."; ui_category = "Palette & Style"; > = false;

// Visual Effects
static const float STRIPE_FREQUENCY_MIN = 5.0, STRIPE_FREQUENCY_MAX = 40.0, STRIPE_FREQUENCY_DEFAULT = 20.0;
static const float HIGHLIGHT_FREQUENCY_MIN = 5.0, HIGHLIGHT_FREQUENCY_MAX = 30.0, HIGHLIGHT_FREQUENCY_DEFAULT = 16.0;
static const float LINE_PATTERN_FREQUENCY_MIN = 10.0, LINE_PATTERN_FREQUENCY_MAX = 50.0, LINE_PATTERN_FREQUENCY_DEFAULT = 24.0;

uniform float StripeFrequency < ui_type = "slider"; ui_label = "Stripe Density"; ui_tooltip = "Controls the frequency of stripes in Spectrum Blend mode. Uses palette color 3 for stripe coloring."; ui_min = STRIPE_FREQUENCY_MIN; ui_max = STRIPE_FREQUENCY_MAX; ui_category = "Visual Effects"; > = STRIPE_FREQUENCY_DEFAULT;
uniform float HighlightFrequency < ui_type = "slider"; ui_label = "Highlight Density"; ui_tooltip = "Controls the frequency of highlights in Spectrum Blend mode. Uses palette color 5 for highlight coloring."; ui_min = HIGHLIGHT_FREQUENCY_MIN; ui_max = HIGHLIGHT_FREQUENCY_MAX; ui_category = "Visual Effects"; > = HIGHLIGHT_FREQUENCY_DEFAULT;
uniform float LinePatternFrequency < ui_type = "slider"; ui_label = "Line Pattern Frequency"; ui_tooltip = "Controls the frequency of the decorative line pattern overlay."; ui_min = LINE_PATTERN_FREQUENCY_MIN; ui_max = LINE_PATTERN_FREQUENCY_MAX; ui_category = "Visual Effects"; > = LINE_PATTERN_FREQUENCY_DEFAULT;

// Animation Controls
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")
static const float ANIM_TIME_SCALE_MIN = 0.01, ANIM_TIME_SCALE_MAX = 2.0, ANIM_TIME_SCALE_DEFAULT = 0.125; // Original was iTime/8
static const float ROTATION_SPEED_MIN = 0.0, ROTATION_SPEED_MAX = 1.0, ROTATION_SPEED_DEFAULT = 0.25; // Adjusted for visual feel
static const float PAN_SPEED_MIN = -2.0, PAN_SPEED_MAX = 2.0, PAN_SPEED_DEFAULT = 0.2; // Adjusted for visual feel

uniform float AnimationTimeScale < ui_type = "slider"; ui_label = "Animation Time Scale Factor"; ui_tooltip = "Scales the internal time used for animations (e.g., rotation cycle speed)."; ui_min = ANIM_TIME_SCALE_MIN; ui_max = ANIM_TIME_SCALE_MAX; ui_category = "Animation"; > = ANIM_TIME_SCALE_DEFAULT;
uniform float OverallRotationSpeed < ui_type = "slider"; ui_label = "Overall Rotation Speed"; ui_tooltip = "Speed of the main pattern rotation."; ui_min = ROTATION_SPEED_MIN; ui_max = ROTATION_SPEED_MAX; ui_category = "Animation"; > = ROTATION_SPEED_DEFAULT;
uniform float PanSpeedY < ui_type = "slider"; ui_label = "Vertical Pan Speed"; ui_tooltip = "Speed of the vertical panning animation."; ui_min = PAN_SPEED_MIN; ui_max = PAN_SPEED_MAX; ui_category = "Animation"; > = PAN_SPEED_DEFAULT;

// Audio Reactivity
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(AudioMultiplier, "Audio Intensity", 1.0, 2.0, "Audio Reactivity")
uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target"; ui_items = "None\0Pattern Scale\0Rotation Speed\0Pattern Seed\0Tile Density\0"; ui_tooltip = "Which parameter reacts to audio input."; ui_category = "Audio Reactivity"; > = 0;

// Atmosphere
static const float SPOTLIGHT_INTENSITY_MIN = 0.5, SPOTLIGHT_INTENSITY_MAX = 2.0, SPOTLIGHT_INTENSITY_DEFAULT = 1.15;
static const float SPOTLIGHT_RADIUS_MIN = 0.1, SPOTLIGHT_RADIUS_MAX = 1.0, SPOTLIGHT_RADIUS_DEFAULT = 0.5;

uniform float SpotlightIntensity < ui_type = "slider"; ui_label = "Spotlight Intensity"; ui_tooltip = "Controls the intensity of the central spotlight effect."; ui_min = SPOTLIGHT_INTENSITY_MIN; ui_max = SPOTLIGHT_INTENSITY_MAX; ui_category = "Atmosphere"; > = SPOTLIGHT_INTENSITY_DEFAULT;

uniform float SpotlightRadius < ui_type = "slider"; ui_label = "Spotlight Radius"; ui_tooltip = "Controls how far the spotlight effect extends from the center."; ui_min = SPOTLIGHT_RADIUS_MIN; ui_max = SPOTLIGHT_RADIUS_MAX; ui_category = "Atmosphere"; > = SPOTLIGHT_RADIUS_DEFAULT;

// Art Deco Style
static const float WEAVE_THICKNESS_MIN = 0.001, WEAVE_THICKNESS_MAX = 0.05, WEAVE_THICKNESS_DEFAULT = 0.01;

uniform float WeaveThickness < ui_type = "slider"; ui_label = "Weave Effect Thickness"; ui_tooltip = "Controls the thickness of the weave effect when Line Tiles are enabled."; ui_min = WEAVE_THICKNESS_MIN; ui_max = WEAVE_THICKNESS_MAX; ui_category = "Art Deco Style"; ui_category_closed = true; > = WEAVE_THICKNESS_DEFAULT;

// Stage/Position Controls
static const float STAGE_OFFSET_X_MIN = -1.0, STAGE_OFFSET_X_MAX = 1.0, STAGE_OFFSET_X_DEFAULT = 0.0;
static const float STAGE_OFFSET_Y_MIN = -1.0, STAGE_OFFSET_Y_MAX = 1.0, STAGE_OFFSET_Y_DEFAULT = 0.0;

uniform float StageOffsetX < ui_type = "slider"; ui_label = "Stage Offset X"; ui_tooltip = "Horizontal offset of the pattern on the stage."; ui_min = STAGE_OFFSET_X_MIN; ui_max = STAGE_OFFSET_X_MAX; ui_category = "Stage/Position"; ui_category_closed = true; > = STAGE_OFFSET_X_DEFAULT;
uniform float StageOffsetY < ui_type = "slider"; ui_label = "Stage Offset Y"; ui_tooltip = "Vertical offset of the pattern on the stage."; ui_min = STAGE_OFFSET_Y_MIN; ui_max = STAGE_OFFSET_Y_MAX; ui_category = "Stage/Position"; ui_category_closed = true; > = STAGE_OFFSET_Y_DEFAULT;

// Stage
AS_STAGEDEPTH_UI(EffectDepth)

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
float2x2 r2(float a) {
    float c = cos(a);
    float s = sin(a);
    return float2x2(c, s, -s, c);
}

// ============================================================================
// PIXEL SHADER
// ============================================================================

float4 PS_ASBGXQuadtreeTruchet(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float4 orig_color = tex2D(ReShade::BackBuffer, texcoord);
    
    // Stage depth check - early exit if scene depth is in front of effect depth
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    if (sceneDepth < EffectDepth - AS_DEPTH_EPSILON) {
        return orig_color;
    }
    
    float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);

    // Screen coordinates, centered, aspect corrected (y ranges approx -0.5 to 0.5).
    float2 uv_screen_centered = (texcoord - 0.5) * float2(ReShade::AspectRatio, 1.0);

    // Apply audio reactivity to selected parameters
    float patternScale_final = PatternScale;
    float rotationSpeed_final = OverallRotationSpeed;
    float patternSeed_final = PatternSeed;
    float largeTileProbability_final = LargeTileProbability;
    
    if (AudioTarget > 0) {
        float audioValue = AS_applyAudioReactivity(1.0, AudioSource, AudioMultiplier, true) - 1.0;
        
        // Pattern Scale
        if (AudioTarget == 1) {
            patternScale_final = PatternScale * (1.0 + audioValue * 0.5);
        }
        // Rotation Speed
        else if (AudioTarget == 2) {
            rotationSpeed_final = OverallRotationSpeed * (1.0 + audioValue * 2.0);
        }
        // Pattern Seed
        else if (AudioTarget == 3) {
            patternSeed_final = PatternSeed + (audioValue * 50.0);
        }
        // Tile Density
        else if (AudioTarget == 4) {
            largeTileProbability_final = saturate(LargeTileProbability + (audioValue * 0.3));
        }
    }    // Scaling, rotation and translation for pattern space.
    float2 oP = uv_screen_centered * patternScale_final;
    float anim_time_scaled = time * AnimationTimeScale; // Original used iTime/8.
    oP = mul(r2(sin(anim_time_scaled) * AS_PI / 8.0 * rotationSpeed_final), oP); // AS_PI/8.0 part of original angle calc.
    oP.y -= PanSpeedY * time; // Original was oP -= vec2(cos(iTime/8.)*0., -iTime); which simplifies to oP.y += iTime with speed control
    
    // Apply stage offset
    oP.x += StageOffsetX * patternScale_final;
    oP.y += StageOffsetY * patternScale_final;

    // Distance field values -- One for each color. They're "float4"s to hold the three
    // layers and an an unused spare. The grid vector holds grid values.
    float4 d = float4(100000.0, 100000.0, 100000.0, 100000.0);
    float4 d2 = float4(100000.0, 100000.0, 100000.0, 100000.0);
    float4 grid = float4(100000.0, 100000.0, 100000.0, 100000.0);    
      // Random constants for each layer. The X values are Truchet flipping threshold
    // values, and the Y values represent the chance that a particular sized tile will render.
    float2 rndTh[3] = { 
        float2(0.5, largeTileProbability_final), 
        float2(0.5, MediumTileProbability), 
        float2(0.5, 1.0) 
    };
    
    // Calculate derived randomization seeds from the pattern seed
    float baseSeed = patternSeed_final;
    float flipSeed1 = baseSeed + 0.543;
    float flipSeed2 = baseSeed * 2.76 + 0.49;
    float lineSeed1 = baseSeed * 2.0 + 0.51;
    float lineSeed2 = baseSeed * 2.13 + 0.49;

    // The scale dimensions. Gets multiplied by two each iteration.
    float dim = 1.0;
    float stroke_half_thickness_factor = TileStrokeThickness / 2.0;

    // Three tile levels.
    for (int k = 0; k < 3; k++) {
        // Base cell ID.
        float2 ip = floor(oP * dim);

        for (int j = -1; j <= 1; j++) {
            for (int i = -1; i <= 1; i++) {                // The neighboring cell ID.
                float2 current_cell_id = ip + float2(i, j);
                float2 rndIJ = AS_hash22(current_cell_id); // Using standard AS hash function

                // Cell IDs for previous dimensions to check for overlaps.
                float2 rndIJ2 = AS_hash22(floor(current_cell_id / 2.0));
                float2 rndIJ4 = AS_hash22(floor(current_cell_id / 4.0));

                if (k == 1 && rndIJ2.y < rndTh[0].y) continue;
                if (k == 2 && (rndIJ2.y < rndTh[1].y || rndIJ4.y < rndTh[0].y)) continue;

                if (rndIJ.y < rndTh[k].y) {
                    // Local cell coordinates.
                    float2 p = oP - (ip + 0.5 + float2(i, j)) / dim;

                    // The grid square.
                    float square = max(abs(p.x), abs(p.y)) - 0.5 / dim;

                    // The grid lines (for debug).
                    float gr = abs(square) - (GridLineWidth / 2.0) / dim; // Scale grid line width with dim
                    grid.x = min(grid.x, gr);                    // TILE COLOR ONE.
                    if (rndIJ.x < rndTh[k].x) p.xy = p.yx;
                    if (frac(rndIJ.x * flipSeed1 + 0.37) < rndTh[k].x) p.x = -p.x;

                    float2 p2 = abs(float2(p.y - p.x, p.x + p.y) * 0.70710678118) - float2(0.5, 0.5) * 0.70710678118 / dim;
                    float c3 = length(p2) - stroke_half_thickness_factor / dim; // (0.5/3.0) from original means thickness is 1/3 of radius (0.5)

                    float c, c_alt; // c_alt is c2 in original

                    // Truchet arc one.
                    c = abs(length(p - float2(-0.5, 0.5) / dim) - 0.5 / dim) - stroke_half_thickness_factor / dim;
                    
                    // Truchet arc two or alternative.
                    if (frac(rndIJ.x * flipSeed2 + 0.49) > 0.35) {
                        c_alt = abs(length(p - float2(0.5, -0.5) / dim) - 0.5 / dim) - stroke_half_thickness_factor / dim;
                    } else {
                        c_alt = length(p - float2(0.5, 0.0) / dim) - stroke_half_thickness_factor / dim;
                        c_alt = min(c_alt, length(p - float2(0.0, -0.5) / dim) - stroke_half_thickness_factor / dim);
                    }
                    
                    if (EnableLineTiles) {
                        if (frac(rndIJ.x * lineSeed1 + 0.51) < 0.35) {
                            c = abs(p.x) - stroke_half_thickness_factor / dim;
                        }
                        if (frac(rndIJ.x * lineSeed2 + 0.49) < 0.35) {
                            c_alt = abs(p.y) - stroke_half_thickness_factor / dim;
                        }
                    }

                    float truchet = min(c, c_alt);
                    
                    if (EnableLineTiles) { // Weave effect
                        float lne = abs(c - WeaveThickness / dim) - WeaveThickness / dim; // Using WeaveThickness parameter
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
    }    // The scene color - derived from palette
    float3 col;
    if (PaletteSelection == AS_PALETTE_CUSTOM) {
        // Use darkened version of custom palette color 1 (index 0) for background
        col = AS_GET_CUSTOM_PALETTE_COLOR(TruchetPalette, 0) * 0.25;
    } else {
        // Use darkened version of palette color 1 (index 0) for background
        col = AS_getPaletteColor(PaletteSelection, 0) * 0.25;
    }

    // Resolution based falloff for smoothing.
    float fo = ReShade::PixelSize.y * 5.0; // 5 pixels    // Tile colors from palette.
    float3 pCol1, pCol2;
    
    if (PaletteSelection == AS_PALETTE_CUSTOM) {
        // Use custom palette colors
        pCol1 = AS_GET_CUSTOM_PALETTE_COLOR(TruchetPalette, 0); // First custom color
        pCol2 = AS_GET_CUSTOM_PALETTE_COLOR(TruchetPalette, 3); // Fourth custom color for contrast
    } else {
        // Use built-in palette colors
        pCol1 = AS_getPaletteColor(PaletteSelection, 0); // First palette color
        pCol2 = AS_getPaletteColor(PaletteSelection, 3); // Fourth palette color for contrast
    }
      // Simple line pattern for non-spectrum modes if not stacked
    float pat3_lines = clamp(sin((oP.x - oP.y) * AS_TWO_PI * ReShade::ScreenSize.y / LinePatternFrequency) * 1.0 + 0.9, 0.0, 1.0) * 0.25 + 0.75;

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
    } 
    else { // Continuous surface
        float d_combined = d.x; // Use d.x as the primary working distance
        d_combined = max(d2.x, -d.x); // Start with first level combination
        d_combined = min(max(d_combined, -d2.y), d.y); // Combine with second level
        d_combined = max(min(d_combined, d2.z), -d.z); // Combine with third level
        if (ColorMode == 1) { // Spectrum Blend coloring
            // Get stripe color from palette (using color index 2)
            float3 stripeColor;
            if (PaletteSelection == AS_PALETTE_CUSTOM) {
                stripeColor = AS_GET_CUSTOM_PALETTE_COLOR(TruchetPalette, 2);
            } else {
                stripeColor = AS_getPaletteColor(PaletteSelection, 2);
            }
            
            float pat_spectrum_stripes = clamp(-sin(d_combined * AS_TWO_PI * StripeFrequency) - 0.0, 0.0, 1.0);
            // Apply stripe pattern using palette color
            col = lerp(col, stripeColor * 0.5, pat_spectrum_stripes * 0.3);

            d_combined = -(d_combined + 0.03); // Invert and offset for rendering

            col = lerp(col, float3(0,0,0), (1.0 - smoothstep(0.0, fo * 5.0, d_combined)));
            col = lerp(col, float3(0,0,0), 1.0 - smoothstep(0.0, fo, d_combined));
            
            // Get intermediate palette color for spectrum blend
            float3 pColMid;
            if (PaletteSelection == AS_PALETTE_CUSTOM) {
                pColMid = AS_GET_CUSTOM_PALETTE_COLOR(TruchetPalette, 1);
            } else {
                pColMid = AS_getPaletteColor(PaletteSelection, 1);
            }
            
            col = lerp(col, pColMid, 1.0 - smoothstep(0.0, fo * 2.0, d_combined + 0.02));
            col = lerp(col, float3(0,0,0), 1.0 - smoothstep(0.0, fo * 2.0, d_combined + 0.03));
            
            // Get highlight color from palette (using color index 4)
            float3 highlightColor;
            if (PaletteSelection == AS_PALETTE_CUSTOM) {
                highlightColor = AS_GET_CUSTOM_PALETTE_COLOR(TruchetPalette, 4);
            } else {
                highlightColor = AS_getPaletteColor(PaletteSelection, 4);
            }
            
            float pat2_highlight_spectrum = clamp(sin(d_combined * AS_TWO_PI * HighlightFrequency) * 1.0 + 0.9, 0.0, 1.0) * 0.3 + 0.7;
            col = lerp(col, highlightColor * pat2_highlight_spectrum, 1.0 - smoothstep(0.0, fo * 2.0, d_combined + 0.05));
            
            float sh_spectrum = clamp(0.75 + d_combined * 2.0, 0.0, 1.0); // Shading for spectrum
            col *= sh_spectrum;
        } 
        else if (ColorMode == 2) { // Gradient Blend coloring
            // Use interpolated palette colors based on distance field
            float gradientT = saturate((d_combined + 0.05) * 2.0); // Normalize distance to 0-1
            
            if (PaletteSelection == AS_PALETTE_CUSTOM) {
                col = AS_GET_INTERPOLATED_CUSTOM_COLOR(TruchetPalette, gradientT);
            } else {
                col = AS_getInterpolatedColor(PaletteSelection, gradientT);
            }
            
            col = lerp(col, float3(0,0,0), (1.0 - smoothstep(0.0, fo * 5.0, d_combined)) * 0.35);
            col = lerp(col, float3(0,0,0), 1.0 - smoothstep(0.0, fo, d_combined));
            col *= pat3_lines;
        }
        else { // Two-Tone coloring (original behavior)
            col = pCol1; // Base color

            col = lerp(col, float3(0,0,0), (1.0 - smoothstep(0.0, fo * 5.0, d_combined)) * 0.35);
            col = lerp(col, float3(0,0,0), 1.0 - smoothstep(0.0, fo, d_combined));
            col = lerp(col, pCol2, 1.0 - smoothstep(0.0, fo, d_combined + 0.02));

            col *= pat3_lines;
        }
    }
    
    // Mild spotlight.
    col *= max(SpotlightIntensity - length(uv_screen_centered) * SpotlightRadius, 0.0);    // Debug Grid Visualization
    if (ShowGrid) {
        // Get grid colors from palette
        float3 vCol1, vCol2;
        if (PaletteSelection == AS_PALETTE_CUSTOM) {
            vCol1 = AS_GET_CUSTOM_PALETTE_COLOR(TruchetPalette, 2);
            vCol2 = AS_GET_CUSTOM_PALETTE_COLOR(TruchetPalette, 4);
        } else {
            vCol1 = AS_getPaletteColor(PaletteSelection, 2);
            vCol2 = AS_getPaletteColor(PaletteSelection, 4);
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
      // Mix the colors for advanced color modes based on screen UVs
    if (ColorMode == 1) { // Spectrum Blend - add color variation based on position
        col = lerp(col, col.yxz, uv_screen_centered.y * 0.75 + 0.5);
        col = lerp(col, col.zxy, uv_screen_centered.x * 0.7 + 0.5);
    } else if (ColorMode == 2) { // Gradient Blend - add subtle position-based variation
        float positionVariation = (uv_screen_centered.x + uv_screen_centered.y) * 0.1;
        float3 positionColor;
        if (PaletteSelection == AS_PALETTE_CUSTOM) {
            positionColor = AS_GET_INTERPOLATED_CUSTOM_COLOR(TruchetPalette, positionVariation + 0.5);
        } else {
            positionColor = AS_getInterpolatedColor(PaletteSelection, positionVariation + 0.5);
        }
        col = lerp(col, positionColor, 0.15);
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
    ui_label = "[AS] BGX: Quadtree Truchet";
    ui_tooltip = "Renders a multiscale, multitile, overlapped, weaved Truchet pattern.";
> {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_ASBGXQuadtreeTruchet;
    }
}

#endif // __AS_BGX_QuadtreeTruchet_1_fx
