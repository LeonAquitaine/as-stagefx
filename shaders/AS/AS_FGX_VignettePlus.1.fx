/**
 * AS_FGX_VignettePlus.1.fx - Enhanced vignette effects with customizable patterns
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * * The hexagonal grid implementation is inspired by/adapted from the hexagonal wipe shader on Shadertoy:
 * https://www.shadertoy.com/view/XfjyWG created by blandprix (2024-08-06)
 * * ===================================================================================
 *
 * DESCRIPTION:
 * A vignette shader that provides multiple visual styles and customizable pattern options. 
 * This shader creates directional, controllable vignette effects for stage compositions 
 * and scene framing. Perfect for adding mood, focus, or stylistic elements.
 *
 * FEATURES:
 * - Four distinct visual styles:
 * • Smooth Gradient: Classic vignette with smooth falloff
 * • Duotone Circles: Hexagonal grid-based pattern with circular elements
 * • Directional Lines: Both perpendicular and parallel line patterns
 * - Precise control over effect coverage with start/end falloff points
 * - Adjustable pattern density, size, and coverage boosting
 * - Standard StageFX rotation, depth masking and blend mode controls
 * - Directional control with mirroring option for symmetrical effects
 * - Comprehensive debug visualization modes for fine-tuning
 * - Optimized for performance across various resolutions
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Calculates composition factor based on screen position and rotation angle (aspect-corrected)
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
#include "AS_Utils.1.fxh" // Assumed to be provided by you, containing AS_ specific macros and helpers

// ============================================================================
// NAMESPACE
// ============================================================================
namespace ASVignettePlus {

// ============================================================================
// CONSTANTS
// ============================================================================

// --- Threshold Constants ---
static const float ALPHA_EPSILON = 0.00001f;      // Minimum alpha threshold for processing (used to prevent div by zero)
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
static const float MIN_PATTERN_SIZE = 0.001f;     // Minimum pattern element size
static const float MAX_PATTERN_SIZE = 0.1f;       // Maximum pattern element size
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

#ifndef M_PI_VIGNETTEPLUS 
#define M_PI_VIGNETTEPLUS 3.14159265358979323846f // Local PI definition for robust portability
#endif

//------------------------------------------------------------------------------------------------
// Uniforms (UI Elements)
//------------------------------------------------------------------------------------------------

// --- Group I: Main Effect Style & Appearance ---
uniform int EffectStyle < ui_type = "combo"; ui_label = "Visual Style"; ui_items = "Smooth Gradient\0Duotone: Circles\0Lines - Perpendicular\0Lines - Parallel\0"; ui_tooltip = "Selects the overall visual appearance of the effect."; ui_category = "Style"; > = STYLE_DUOTONE_CIRCLES;
uniform float3 EffectColor < ui_type = "color"; ui_label = "Effect Color"; ui_tooltip = "The primary color used for the gradient or duotone patterns."; ui_category = "Style"; > = float3(0.0, 0.0, 0.0);
uniform bool MirrorDirection < ui_type = "checkbox"; ui_label = "Mirror Effect"; ui_tooltip = "Mirrors the directional effect, making it symmetrical around its central axis."; ui_category = "Style"; > = false;
uniform bool InvertAlpha < ui_type = "checkbox"; ui_label = "Invert Transparency"; ui_tooltip = "Flips the effect's opacity: solid areas become transparent, and vice-versa."; ui_category = "Style"; > = false;

// --- Group II: Falloff Controls ---
uniform float FalloffStart < ui_type = "slider"; ui_label = "Falloff Start (%)"; ui_min = MIN_FALLOFF; ui_max = MAX_FALLOFF; ui_step = 0.1; ui_tooltip = "Defines where the effect begins to transition from solid. Order of Start/End doesn't matter."; ui_category = "Falloff"; > = DEFAULT_FALLOFF_START;
uniform float FalloffEnd < ui_type = "slider"; ui_label = "Falloff End (%)"; ui_min = MIN_FALLOFF; ui_max = MAX_FALLOFF; ui_step = 0.1; ui_tooltip = "Defines where the effect becomes fully transparent after transitioning. Order of Start/End doesn't matter."; ui_category = "Falloff"; > = DEFAULT_FALLOFF_END;

// --- Group III: Pattern Specifics (for Duotone/Lines) ---
uniform float PatternElementSize < ui_type = "slider"; ui_label = "Pattern Element Size / Spacing"; ui_tooltip = "For Duotone/Lines: Controls the base size of circles, or spacing of lines."; ui_min = MIN_PATTERN_SIZE; ui_max = MAX_PATTERN_SIZE; ui_step = 0.001; ui_category = "Pattern"; > = DEFAULT_PATTERN_SIZE;
uniform float PatternCoverageBoost < ui_type = "slider"; ui_label = "Pattern Coverage Boost"; ui_tooltip = "For Duotone/Lines: Slightly enlarges elements in solid areas to ensure full coverage. 1.0 = no boost."; ui_min = MIN_COVERAGE_BOOST; ui_max = MAX_COVERAGE_BOOST; ui_step = 0.005; ui_category = "Pattern"; > = DEFAULT_COVERAGE_BOOST;

// --- Group IV: Direction & Orientation ---
AS_ROTATION_UI(SnapRotation, FineRotation) // Macro from AS_Utils.1.fxh

// --- Stage Depth Control ---
AS_STAGEDEPTH_UI(EffectDepth) // Macro from AS_Utils.1.fxh
// --- Final Mix Controls ---
AS_BLENDMODE_UI(BlendMode) // Macro from AS_Utils.1.fxh
AS_BLENDAMOUNT_UI(BlendAmount) // Macro from AS_Utils.1.fxh

// --- Debug ---
AS_DEBUG_MODE_UI("Off\0Mask\0Falloff\0Pattern\0Pattern Only\0") // Macro from AS_Utils.1.fxh

//------------------------------------------------------------------------------------------------
// Helper Functions
//------------------------------------------------------------------------------------------------

// --- Hexagonal Grid Helper Functions (for Duotone Circles) ---
float fmod_positive(float a, float b) { return a - b * floor(a / b); }
float2 HexGridRoundAxial(float2 fa) { float q=fa.x,r=fa.y,s=-q-r;float qr=round(q),rr=round(r),sr=round(s);float qd=abs(qr-q),rd=abs(rr-r),sd=abs(sr-s);if(qd>rd&&qd>sd)qr=-rr-sr;else if(rd>sd)rr=-qr-sr;return float2(qr,rr); }
float2 HexGridAxialToCartesian(float2 ax, float gd) { float xF=sqrt(3.f),yF=1.5f;return float2((xF*ax.x+xF/2.f*ax.y)/gd,(yF*ax.y)/gd); }
float2 HexGridCartesianToFractionalAxial(float2 ca, float gd) { float qF=sqrt(3.f)/3.f,rxF=-1.f/3.f,ryF=2.f/3.f;return float2((qF*ca.x+rxF*ca.y)*gd,(ryF*ca.y)*gd); }
float2 HexGridCartesianToNearestCell(float2 ca, float gd) { return HexGridRoundAxial(HexGridCartesianToFractionalAxial(ca,gd)); }

// --- Composition Logic ---
// Calculates a factor (0-1) representing the vignette progression, accounting for rotation and aspect ratio.
float GetCompositionFactor(float2 texcoord, float rotation_radians, bool mirror) {
    float2 centered_coord = texcoord - CENTER_COORD;

    float cos_angle = cos(rotation_radians);
    float sin_angle = sin(rotation_radians);

    // Project onto the desired visual angle in a space scaled by actual screen dimensions
    // This ensures the rotation angle is visually correct regardless of aspect ratio.
    float projected_value_pixel_scaled = 
        (centered_coord.x * ReShade::ScreenSize.x) * cos_angle + 
        (centered_coord.y * ReShade::ScreenSize.y) * sin_angle;

    // Normalize this projected value based on the screen's maximum extent along this rotated direction.
    float max_extent_pixel_scaled = 
        CENTER_COORD * (ReShade::ScreenSize.x * abs(cos_angle) + 
                        ReShade::ScreenSize.y * abs(sin_angle));
    
    float factor = (projected_value_pixel_scaled / (max_extent_pixel_scaled + ALPHA_EPSILON)) * CENTER_COORD + CENTER_COORD;
    
    if (mirror) {
        factor = (factor < CENTER_COORD) ? (factor / CENTER_COORD) : ((1.0f - factor) / CENTER_COORD);
    }
    
    return saturate(factor);
}

// --- Vignette Alpha Calculation ---
// Calculates the raw vignette alpha based on the composition factor and falloff thresholds.
float CalculateVignetteAlpha(float position, float normalizedStartInput, float normalizedEndInput) {
    float first_threshold = min(normalizedStartInput, normalizedEndInput);
    float second_threshold = max(normalizedStartInput, normalizedEndInput);
    
    if (first_threshold >= second_threshold) { // Handles cases where thresholds are equal or crossed
        return position <= first_threshold ? 1.0f : 0.0f;
    }
    // Consistent use of ordered thresholds for the logic below
    if (position <= first_threshold) {
        return 1.0f; // Solid area
    }
    else if (position >= second_threshold) {
        return 0.0f; // Transparent area
    }
    else {
        // Transition area
        float t = (position - first_threshold) / (second_threshold - first_threshold);
        return 1.0f - smoothstep(0.0f, 1.0f, t); 
    }
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
    
    float2 uv_dither = texcoord; 
    uv_dither.y /= ReShade::AspectRatio; // Aspect correction for hex grid space
    
    float current_grid_density = 1.0f / circle_cell_radius_base;
    
    float2 nearestCell = HexGridCartesianToNearestCell(uv_dither, current_grid_density); 
    float2 cellCenter = HexGridAxialToCartesian(nearestCell, current_grid_density);
    
    float dist_uv = distance(cellCenter, uv_dither); // Distance in aspect-corrected UV space
    
    float boost = lerp(1.0f, coverage_boost_uniform, raw_alpha_param);
    float target_radius_uv = circle_cell_radius_base * raw_alpha_param * boost;
    
    float aa_transition_width_uv = fwidth(dist_uv); // fwidth for robust AA
    float dither_mask_alpha = smoothstep(target_radius_uv + aa_transition_width_uv * 0.5f, 
                                         target_radius_uv - aa_transition_width_uv * 0.5f, 
                                         dist_uv);
                                         
    return float4(color, dither_mask_alpha);
}

// Shared logic for line patterns with isotropic correction for banding and fwidth AA
float4 ApplyDuotoneLinesSharedLogic(float2 texcoord, float raw_alpha_param, float3 color,
                                    float line_cycle_width_uv, float effect_rotation_rad, float coverage_boost_uniform,
                                    bool use_u_component_for_banding) {
    if (raw_alpha_param <= ALPHA_EPSILON) return float4(color, 0.0f);
    
    float2 centered_coord = texcoord - CENTER_COORD;
    float W = ReShade::ScreenSize.x;
    float H = ReShade::ScreenSize.y;

    float cos_a = cos(effect_rotation_rad);
    float sin_a = sin(effect_rotation_rad);
    
    float component_for_banding_pixels;
    float max_extent_pixels_for_banding_axis;

    if (use_u_component_for_banding) { // For Lines - Perpendicular (bands along U-visual axis)
        component_for_banding_pixels = (centered_coord.x * W) * cos_a + (centered_coord.y * H) * sin_a;
        max_extent_pixels_for_banding_axis = CENTER_COORD * (W * abs(cos_a) + H * abs(sin_a));
    } else { // For Lines - Parallel (bands along V-visual axis)
        component_for_banding_pixels = -(centered_coord.x * W) * sin_a + (centered_coord.y * H) * cos_a;
        max_extent_pixels_for_banding_axis = CENTER_COORD * (W * abs(sin_a) + H * abs(cos_a));
    }
    
    float normalized_pos_for_banding = (component_for_banding_pixels / (max_extent_pixels_for_banding_axis + ALPHA_EPSILON)) * CENTER_COORD + CENTER_COORD;
    
    float cycle_input_raw = saturate(normalized_pos_for_banding) / line_cycle_width_uv; // Value whose frac is taken
    float coord_in_cycle = frac(cycle_input_raw); 
    
    float base_half_thick_norm = raw_alpha_param * CENTER_COORD; 
    float boost = lerp(1.0f, coverage_boost_uniform, raw_alpha_param);
    float boosted_target_half_thickness_norm = base_half_thick_norm * boost;
    
    float value_to_test_against_thickness = abs(coord_in_cycle - CENTER_COORD); 
    float edge_threshold_norm = boosted_target_half_thickness_norm; 

    // fwidth of the value that defines the repeating cycle, before frac, scaled by how many cycles fit in normalized_pos.
    float aa_transition_width_cycle_units = fwidth(cycle_input_raw); 
    
    float line_alpha = smoothstep(edge_threshold_norm + aa_transition_width_cycle_units * 0.5f, 
                                  edge_threshold_norm - aa_transition_width_cycle_units * 0.5f, 
                                  value_to_test_against_thickness);
    
    return float4(color, line_alpha);
}

float4 ApplyDuotoneLinesParallelPS(float2 texcoord, float raw_alpha_param, float3 color,
                                   float line_cycle_width_uv, float effect_rotation_rad, float coverage_boost_uniform) {
    return ApplyDuotoneLinesSharedLogic(texcoord, raw_alpha_param, color, line_cycle_width_uv, effect_rotation_rad, coverage_boost_uniform, false);
}

float4 ApplyDuotoneLinesPerpendicularPS(float2 texcoord, float raw_alpha_param, float3 color,
                                        float line_cycle_width_uv, float effect_rotation_rad, float coverage_boost_uniform) {
    return ApplyDuotoneLinesSharedLogic(texcoord, raw_alpha_param, color, line_cycle_width_uv, effect_rotation_rad, coverage_boost_uniform, true);
}

//------------------------------------------------------------------------------------------------
// Pixel Shader
//------------------------------------------------------------------------------------------------
float4 VignettePlusPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth) { 
        return tex2D(ReShade::BackBuffer, texcoord);
    }
    
    float3 original_color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float rotation_radians = AS_getRotationRadians(SnapRotation, FineRotation); 
    
    float composition_f = GetCompositionFactor(texcoord, rotation_radians, MirrorDirection);
    float tA_norm = FalloffStart * PERCENT_TO_NORMAL;
    float tB_norm = FalloffEnd * PERCENT_TO_NORMAL;
    float raw_vignette_alpha = CalculateVignetteAlpha(composition_f, tA_norm, tB_norm);
    
    float4 vignette_effect_color_alpha = float4(EffectColor, 0.0f);
    
    if (EffectStyle == STYLE_SMOOTH_GRADIENT) {
        vignette_effect_color_alpha = ApplySmoothGradientPS(raw_vignette_alpha, EffectColor);
    } 
    else if (EffectStyle == STYLE_DUOTONE_CIRCLES) {
        vignette_effect_color_alpha = ApplyDuotoneCirclesPS(texcoord, raw_vignette_alpha, EffectColor, PatternElementSize, PatternCoverageBoost);
    } 
    else if (EffectStyle == STYLE_LINES_PERPENDICULAR) {
        vignette_effect_color_alpha = ApplyDuotoneLinesPerpendicularPS(texcoord, raw_vignette_alpha, EffectColor, PatternElementSize, rotation_radians, PatternCoverageBoost);
    } 
    else if (EffectStyle == STYLE_LINES_PARALLEL) {
        vignette_effect_color_alpha = ApplyDuotoneLinesParallelPS(texcoord, raw_vignette_alpha, EffectColor, PatternElementSize, rotation_radians, PatternCoverageBoost);
    }
    
    float final_effect_alpha = vignette_effect_color_alpha.a;
    if (InvertAlpha) { 
        final_effect_alpha = 1.0f - final_effect_alpha;
    }
    
    float3 blended_color = lerp(original_color, vignette_effect_color_alpha.rgb, final_effect_alpha);
    float4 effect_result = float4(blended_color, FULL_OPACITY);
    float4 final_color = effect_result;

    if (BlendAmount < FULL_OPACITY) {
        float4 background = float4(original_color, FULL_OPACITY);
        final_color = AS_ApplyBlend(effect_result, background, BlendMode, BlendAmount);
    }

    if (DebugMode != DEBUG_OFF) {
        if (DebugMode == DEBUG_MASK) { return float4(final_effect_alpha.xxx, FULL_OPACITY); }
        else if (DebugMode == DEBUG_FALLOFF) { return float4(raw_vignette_alpha.xxx, FULL_OPACITY); }
        else if (DebugMode == DEBUG_PATTERN) { return float4(vignette_effect_color_alpha.a.xxx, FULL_OPACITY); }
        else if (DebugMode == DEBUG_PATTERN_ONLY) {
            float3 pattern_only = lerp(BLACK_COLOR, EffectColor, vignette_effect_color_alpha.a);
            return float4(pattern_only, FULL_OPACITY);
        }
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
        VertexShader = PostProcessVS; // Assumed PostProcessVS is defined (typically in ReShade.fxh or your AS_Utils.fxh)
        PixelShader = ASVignettePlus::VignettePlusPS;
    }
}

} // namespace ASVignettePlus
#endif // __AS_FGX_VignettePlus_1_fx