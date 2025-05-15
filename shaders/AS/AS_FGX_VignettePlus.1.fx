/**
 * AS_FGX_VignettePlus.1.fx - Enhanced vignette effects with customizable patterns
 * Author: Leon Aquitaine (based on original VignettePlus by Anonymous)
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * A vignette shader that provides multiple visual styles and customizable pattern options. 
 * This shader creates directional, controllable vignette effects for stage compositions 
 * and scene framing. Perfect for adding mood, focus, or stylistic elements.
 *
 * FEATURES:
 * - Four distinct visual styles:
 *   • Smooth Gradient: Classic vignette with smooth falloff
 *   • Duotone Circles: Hexagonal grid-based pattern with circular elements
 *   • Directional Lines: Both perpendicular and parallel line patterns
 * - Precise control over effect coverage with start/end falloff points
 * - Adjustable pattern density, size, and coverage boosting
 * - Standard StageFX rotation, depth masking and blend mode controls
 * - Directional control with mirroring option for symmetrical effects
 * - Comprehensive debug visualization modes for fine-tuning
 * - Optimized for performance across various resolutions
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Calculates composition factor based on screen position and rotation angle
 * 2. Determines vignette alpha using configured falloff points with scale adjustment
 * 3. Applies selected pattern (gradient, circles, or lines) with anti-aliasing
 * 4. Implements standard AS StageFX depth masking and blend modes
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_FGX_VignettePlus_1_fx
#define __AS_FGX_VignettePlus_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// NAMESPACE
// ============================================================================
namespace ASVignettePlus {

// ============================================================================
// CONSTANTS
// ============================================================================

// --- Threshold Constants ---
static const float ALPHA_EPSILON = 0.0001f;       // Minimum alpha threshold for processing
static const float CENTER_COORD = 0.5f;           // Screen center coordinate
static const float PERCENT_TO_NORMAL = 0.01f;     // Conversion from percentage to 0-1 range
static const float FULL_OPACITY = 1.0f;           // Full opacity value
static const float3 BLACK_COLOR = float3(0.0, 0.0, 0.0); // Pure black color for debug views

// --- Default Values ---
static const float DEFAULT_FALLOFF_START = 10.0;  // Default falloff start (%)
static const float DEFAULT_FALLOFF_END = 75.0;    // Default falloff end (%)
static const float DEFAULT_PATTERN_SIZE = 0.03;   // Default pattern element size
static const float DEFAULT_COVERAGE_BOOST = 1.05; // Default pattern coverage boost factor

// --- UI Range Constants ---
static const float MIN_FALLOFF = 0.0f;            // Minimum falloff percentage
static const float MAX_FALLOFF = 100.0f;          // Maximum falloff percentage
static const float MIN_PATTERN_SIZE = 0.005f;     // Minimum pattern element size
static const float MAX_PATTERN_SIZE = 0.2f;       // Maximum pattern element size
static const float MIN_COVERAGE_BOOST = 1.0f;     // Minimum pattern coverage boost
static const float MAX_COVERAGE_BOOST = 1.2f;     // Maximum pattern coverage boost

// --- Visual Style Constants ---
static const int STYLE_SMOOTH_GRADIENT = 0;
static const int STYLE_DUOTONE_CIRCLES = 1;
static const int STYLE_LINES_PERPENDICULAR = 2;
static const int STYLE_LINES_PARALLEL = 3;

// --- Debug Mode Constants ---
static const int DEBUG_OFF = 0;
static const int DEBUG_MASK = 1;
static const int DEBUG_FALLOFF = 2;
static const int DEBUG_PATTERN = 3;
static const int DEBUG_PATTERN_ONLY = 4;

//------------------------------------------------------------------------------------------------
// Uniforms (UI Elements)
//------------------------------------------------------------------------------------------------

// --- Group I: Main Effect Style & Appearance ---
uniform int EffectStyle < ui_type = "combo"; ui_label = "Visual Style"; ui_items = "Smooth Gradient\0Duotone: Circles\0Duotone: Lines (Perpendicular)\0Duotone: Lines (Parallel)\0"; ui_tooltip = "Selects the overall visual appearance of the effect."; ui_category = "Style"; > = STYLE_SMOOTH_GRADIENT;

uniform float3 EffectColor < ui_type = "color"; ui_label = "Effect Color"; ui_tooltip = "The primary color used for the gradient or duotone patterns."; ui_category = "Style"; > = float3(0.0, 0.0, 0.0);

// --- Group II: Falloff Controls ---
uniform float FalloffStart < ui_type = "slider"; ui_label = "Falloff Start (%)"; ui_min = MIN_FALLOFF; ui_max = MAX_FALLOFF; ui_step = 0.1; ui_tooltip = "Defines where the effect begins to transition from solid. Order of Start/End doesn't matter."; ui_category = "Falloff"; > = DEFAULT_FALLOFF_START;

uniform float FalloffEnd < ui_type = "slider"; ui_label = "Falloff End (%)"; ui_min = MIN_FALLOFF; ui_max = MAX_FALLOFF; ui_step = 0.1; ui_tooltip = "Defines where the effect becomes fully transparent after transitioning. Order of Start/End doesn't matter."; ui_category = "Falloff"; > = DEFAULT_FALLOFF_END;

// --- Group III: Pattern Specifics (for Duotone/Lines) ---
uniform float PatternElementSize < ui_type = "slider"; ui_label = "Pattern Element Size / Spacing"; ui_tooltip = "For Duotone/Lines: Controls the base size of circles, or spacing of lines."; ui_min = MIN_PATTERN_SIZE; ui_max = MAX_PATTERN_SIZE; ui_step = 0.001; ui_category = "Pattern"; > = DEFAULT_PATTERN_SIZE;

uniform float PatternCoverageBoost < ui_type = "slider"; ui_label = "Pattern Coverage Boost"; ui_tooltip = "For Duotone/Lines: Slightly enlarges elements in solid areas to ensure full coverage. 1.0 = no boost."; ui_min = MIN_COVERAGE_BOOST; ui_max = MAX_COVERAGE_BOOST; ui_step = 0.005; ui_category = "Pattern"; > = DEFAULT_COVERAGE_BOOST;

// --- Group IV: Direction & Orientation ---
// Standard rotation controls for AS StageFX
AS_ROTATION_UI(SnapRotation, FineRotation)

uniform bool MirrorDirection < ui_type = "checkbox"; ui_label = "Mirror Effect"; ui_tooltip = "Mirrors the directional effect, making it symmetrical around its central axis."; ui_category = "Stage"; > = false;

// --- Group V: Output Control ---
uniform bool InvertAlpha < ui_type = "checkbox"; ui_label = "Invert Transparency"; ui_tooltip = "Flips the effect's opacity: solid areas become transparent, and vice-versa."; ui_category = "Stage"; > = false;

// --- Stage Depth Control ---
AS_STAGEDEPTH_UI(EffectDepth)

// --- Final Mix Controls ---
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug ---
AS_DEBUG_MODE_UI("Off\0Mask\0Falloff\0Pattern\0Pattern Only\0")

//------------------------------------------------------------------------------------------------
// Helper Functions
//------------------------------------------------------------------------------------------------

// --- Hexagonal Grid Helper Functions (for Duotone Circles) ---
float fmod_positive(float a, float b) { return a - b * floor(a / b); }

// Rounds a fractional axial coordinate to the nearest hexagonal grid point
float2 HexGridRoundAxial(float2 fractionalAxial) { 
    float q = fractionalAxial.x;
    float r = fractionalAxial.y;
    float s = -q - r;  // Third coordinate in axial system (q + r + s = 0)
    
    float qRound = round(q);
    float rRound = round(r);
    float sRound = round(s);
    
    // Calculate differences to determine which coordinate to adjust
    float qDiff = abs(qRound - q);
    float rDiff = abs(rRound - r);
    float sDiff = abs(sRound - s);
    
    // Adjust the coordinate with the largest difference to maintain constraint q + r + s = 0
    if (qDiff > rDiff && qDiff > sDiff) {
        qRound = -rRound - sRound;
    }
    else if (rDiff > sDiff) {
        rRound = -qRound - sRound;
    }
    
    return float2(qRound, rRound);
}

// Converts axial hex coordinates to cartesian (screen space) coordinates
float2 HexGridAxialToCartesian(float2 axialCoord, float gridDensity) { 
    // Constants derived from hexagon geometry
    float xFactor = sqrt(3.0f);
    float yFactor = 1.5f;
    
    // Convert using standard hexagonal grid transformation
    return float2(
        (xFactor * axialCoord.x + xFactor/2.0f * axialCoord.y) / gridDensity,
        (yFactor * axialCoord.y) / gridDensity
    );
}

// Converts cartesian (screen space) coordinates to fractional axial hex coordinates
float2 HexGridCartesianToFractionalAxial(float2 cartesianCoord, float gridDensity) { 
    // Constants derived from hexagon geometry
    float qFactor = sqrt(3.0f)/3.0f;
    float rFactorX = -1.0f/3.0f;
    float rFactorY = 2.0f/3.0f;
    
    // Apply inverse transformation
    return float2(
        (qFactor * cartesianCoord.x + rFactorX * cartesianCoord.y) * gridDensity,
        (rFactorY * cartesianCoord.y) * gridDensity
    );
}

// Converts cartesian coordinates directly to nearest hex grid cell (whole axial coordinates)
float2 HexGridCartesianToNearestCell(float2 cartesianCoord, float gridDensity) { 
    return HexGridRoundAxial(HexGridCartesianToFractionalAxial(cartesianCoord, gridDensity));
}

// --- Composition Logic ---
float GetCompositionFactor(float2 texcoord, float rotation_radians, bool mirror) {
    float2 centered_coord = texcoord - CENTER_COORD;
    float cos_angle = cos(rotation_radians);
    float sin_angle = sin(rotation_radians);
    
    // Calculate rotated coordinate (u component)
    float rotated_u_component = centered_coord.x * cos_angle + centered_coord.y * sin_angle;
    
    // Normalize to 0-1 range
    float factor = rotated_u_component + CENTER_COORD;
    
    // Apply mirroring if requested
    if (mirror) {
        factor = (factor < CENTER_COORD) ? 
                 (factor / CENTER_COORD) : 
                 ((1.0f - factor) / CENTER_COORD);
    }
    
    return saturate(factor);
}

// --- Vignette Alpha Calculation ---
float CalculateVignetteAlpha(float position, float normalizedStart, float normalizedEnd) {
    // Ensure start is smaller than end for correct transition
    float first_threshold = min(normalizedStart, normalizedEnd);
    float second_threshold = max(normalizedStart, normalizedEnd);
    
    // Early exit if thresholds are equal (no transition zone)
    if (first_threshold >= second_threshold) {
        return position <= first_threshold ? 1.0f : 0.0f;
    }
    
    float transitionFactor = 0.0;
        
    if (position <= normalizedStart) {
        // Before the start point: full effect
        transitionFactor = 1.0;
    }
    else if (position >= normalizedEnd) {
        // After the end point: no effect
        transitionFactor = 0.0;
    }
    else {
        // In the transition zone: smooth blend from 1 to 0
        float normalizedPos = (position - normalizedStart) / (normalizedEnd - normalizedStart);
        transitionFactor = 1.0 - smoothstep(0.0, 1.0, normalizedPos);
    }
    
    return transitionFactor;
}

//------------------------------------------------------------------------------------------------
// Pattern Functions
//------------------------------------------------------------------------------------------------

float4 ApplySmoothGradientPS(float raw_alpha_param, float3 color) {
    return float4(color, raw_alpha_param);
}

float4 ApplyDuotoneCirclesPS(float2 texcoord, float raw_alpha_param, float3 color,
                             float circle_cell_radius_base, float coverage_boost_uniform) {
    if (raw_alpha_param <= ALPHA_EPSILON) return float4(color, 0.0f);
    
    // Prepare UV coordinates with aspect ratio correction
    float2 uv_dither = texcoord; 
    uv_dither.y /= ReShade::AspectRatio;
    
    // Calculate grid density from cell radius
    float current_grid_density = 1.0f / circle_cell_radius_base;
    
    // Get the nearest hex grid cell center for current position
    float2 nearestCell = HexGridCartesianToNearestCell(uv_dither, current_grid_density); 
    float2 cellCenter = HexGridAxialToCartesian(nearestCell, current_grid_density);
    
    // Calculate distance from current position to cell center
    float dist_uv = distance(cellCenter, uv_dither);
    
    // Apply coverage boost based on alpha value
    float boost = lerp(1.0f, coverage_boost_uniform, raw_alpha_param);
    float radius_uv = circle_cell_radius_base * raw_alpha_param * boost;
    
    // Calculate anti-aliasing factor based on screen resolution
    float aa_scaler = min(ReShade::ScreenSize.x, ReShade::ScreenSize.y);
    float aa_dist = (radius_uv - dist_uv) * aa_scaler;
    
    return float4(color, smoothstep(0.0f, 1.0f, aa_dist));
}

float4 ApplyDuotoneLinesParallelPS(float2 texcoord, float raw_alpha_param, float3 color,
                                   float line_cycle_width_uv, float effect_rotation_rad, float coverage_boost_uniform) {
    if (raw_alpha_param <= ALPHA_EPSILON) return float4(color, 0.0f);
    
    // Center coordinates for rotation
    float2 ctd_coord = texcoord - CENTER_COORD;
    
    // Apply rotation transform
    float cos_a = cos(effect_rotation_rad), sin_a = sin(effect_rotation_rad);
    float v_rot = -ctd_coord.x * sin_a + ctd_coord.y * cos_a;
    
    // Calculate normalized position within pattern cycle
    float band_coord = v_rot + CENTER_COORD;
    float cycle_coord = frac(band_coord / line_cycle_width_uv);
    
    // Calculate line thickness with boosting for solid areas
    float base_half_thick = raw_alpha_param * CENTER_COORD;
    float boost = lerp(1.0f, coverage_boost_uniform, raw_alpha_param);
    float boosted_half_thick = base_half_thick * boost;
    
    // Calculate normalized distance from line center
    float dist_norm = boosted_half_thick - abs(cycle_coord - CENTER_COORD);
    
    // Anti-alias based on screen resolution
    float aa_scaler = min(ReShade::ScreenSize.x, ReShade::ScreenSize.y);
    float aa_dist = (dist_norm * 2.0f * line_cycle_width_uv) * aa_scaler;
    
    return float4(color, smoothstep(0.0f, 1.0f, aa_dist));
}

float4 ApplyDuotoneLinesPerpendicularPS(float2 texcoord, float raw_alpha_param, float3 color,
                                        float line_cycle_width_uv, float effect_rotation_rad, float coverage_boost_uniform) {
    if (raw_alpha_param <= ALPHA_EPSILON) return float4(color, 0.0f);
    
    // Center coordinates for rotation
    float2 ctd_coord = texcoord - CENTER_COORD;
    
    // Apply rotation transform
    float cos_a = cos(effect_rotation_rad), sin_a = sin(effect_rotation_rad);
    float u_rot = ctd_coord.x * cos_a + ctd_coord.y * sin_a;
    
    // Calculate normalized position within pattern cycle
    float band_coord = u_rot + CENTER_COORD;
    float cycle_coord = frac(band_coord / line_cycle_width_uv);
    
    // Calculate line thickness with boosting for solid areas
    float base_half_thick = raw_alpha_param * CENTER_COORD;
    float boost = lerp(1.0f, coverage_boost_uniform, raw_alpha_param);
    float boosted_half_thick = base_half_thick * boost;
    
    // Calculate normalized distance from line center
    float dist_norm = boosted_half_thick - abs(cycle_coord - CENTER_COORD);
    
    // Anti-alias based on screen resolution
    float aa_scaler = min(ReShade::ScreenSize.x, ReShade::ScreenSize.y);
    float aa_dist = (dist_norm * 2.0f * line_cycle_width_uv) * aa_scaler;
    
    return float4(color, smoothstep(0.0f, 1.0f, aa_dist));
}

//------------------------------------------------------------------------------------------------
// Pixel Shader
//------------------------------------------------------------------------------------------------
float4 VignettePlusPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    // Get depth and handle depth-based masking
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth) {
        return tex2D(ReShade::BackBuffer, texcoord);
    }
    
    float3 original_color = tex2D(ReShade::BackBuffer, texcoord).rgb;
      // Calculate rotation using standard AS helpers
    float rotation_radians = AS_getRotationRadians(SnapRotation, FineRotation);
    
    // Calculate composition factor
    float composition_f = GetCompositionFactor(texcoord, rotation_radians, MirrorDirection);
      // Normalize falloff values from percentage to 0-1 range
    float tA_norm = FalloffStart * PERCENT_TO_NORMAL;
    float tB_norm = FalloffEnd * PERCENT_TO_NORMAL;
    
    // Calculate vignette alpha
    float raw_vignette_alpha = CalculateVignetteAlpha(composition_f, tA_norm, tB_norm);
    
    // Initialize the effect output
    float4 vignette_effect_color_alpha = float4(EffectColor, 0.0f);
    
    // Apply the selected pattern
    if (EffectStyle == STYLE_SMOOTH_GRADIENT) {
        vignette_effect_color_alpha = ApplySmoothGradientPS(raw_vignette_alpha, EffectColor);
    } 
    else if (EffectStyle == STYLE_DUOTONE_CIRCLES) {
        vignette_effect_color_alpha = ApplyDuotoneCirclesPS(texcoord, raw_vignette_alpha, EffectColor, 
                                                            PatternElementSize, PatternCoverageBoost);
    } 
    else if (EffectStyle == STYLE_LINES_PERPENDICULAR) {
        vignette_effect_color_alpha = ApplyDuotoneLinesPerpendicularPS(texcoord, raw_vignette_alpha, EffectColor, 
                                                                        PatternElementSize, rotation_radians, PatternCoverageBoost);
    } 
    else if (EffectStyle == STYLE_LINES_PARALLEL) {
        vignette_effect_color_alpha = ApplyDuotoneLinesParallelPS(texcoord, raw_vignette_alpha, EffectColor, 
                                                                   PatternElementSize, rotation_radians, PatternCoverageBoost);
    }
    
    // Apply alpha inversion if enabled
    float final_effect_alpha = vignette_effect_color_alpha.a;
    if (InvertAlpha) {
        final_effect_alpha = 1.0f - final_effect_alpha;
    }    // Blend with original scene color
    float3 blended_color = lerp(original_color, vignette_effect_color_alpha.rgb, final_effect_alpha);
    
    // Create a float4 with the effect result for blending and potential debug display
    float4 effect_result = float4(blended_color, FULL_OPACITY);
    
    // Create the final output by applying standard blend modes
    float4 final_color = effect_result;
    if (BlendAmount < FULL_OPACITY) {
        float4 background = float4(original_color, FULL_OPACITY);
        // Use the float4 version of AS_ApplyBlend that accepts BlendAmount parameter
        final_color = AS_ApplyBlend(effect_result, background, BlendMode, BlendAmount);
    }// Handle debug modes
    if (DebugMode == DEBUG_MASK) { // Mask
        return float4(final_effect_alpha.xxx, FULL_OPACITY);
    }
    else if (DebugMode == DEBUG_FALLOFF) { // Falloff
        return float4(raw_vignette_alpha.xxx, FULL_OPACITY);
    }
    else if (DebugMode == DEBUG_PATTERN) { // Pattern
        float pattern_alpha = vignette_effect_color_alpha.a;
        return float4(pattern_alpha.xxx, FULL_OPACITY);
    }
    else if (DebugMode == DEBUG_PATTERN_ONLY) { // Pattern Only
        float3 pattern_only = lerp(BLACK_COLOR, EffectColor, vignette_effect_color_alpha.a);
        return float4(pattern_only, FULL_OPACITY);
    }
    
    return final_color;
}

//------------------------------------------------------------------------------------------------
// Technique Definition
//------------------------------------------------------------------------------------------------
technique AS_FGX_VignettePlus < ui_label = "[AS] FGX: Vignette Plus"; ui_tooltip = "Advanced vignette effects with customizable styles, falloff, and patterns."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = ASVignettePlus::VignettePlusPS;
    }
}

} // namespace ASVignettePlus

#endif // __AS_FGX_VignettePlus_1_fx