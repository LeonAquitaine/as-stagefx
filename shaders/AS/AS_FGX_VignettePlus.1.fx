/**
 * AS_FGX_VignettePlus.1.fx - Enhanced vignette effects with customizable patterns
 * Author: Leon Aquitaine (based on original VignettePlus by Anonymous)
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Implements various vignette effects with user-configurable shapes, patterns, and
 * transition areas. Designed to create professional directional vignette effects
 * for stage aesthetics, with standard AS StageFX features.
 *
 * FEATURES:
 * - Multiple visual styles: Smooth Gradient, Duotone Circles, Lines (Perpendicular/Parallel)
 * - Customizable falloff start/end points with smooth transitions
 * - Fully adjustable direction, shape, and pattern elements
 * - Rotation, stage depth, and blend mode controls
 * - Optional pattern coverage boost for consistent solid areas
 * - Full support for other AS StageFX standard features
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Calculates composition factor based on screen position and rotation angle
 * 2. Determines vignette alpha using configured falloff points
 * 3. Applies selected pattern (gradient, circles, or lines) with customizable parameters
 * 4. Supports standard AS StageFX depth masking and blend modes
 * 5. Optional debug visualization for effect tuning
 *
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

// --- Math Constants ---
#ifndef PI_VIGNETTEPLUS
#define PI_VIGNETTEPLUS AS_PI
#endif

// --- Default Values ---
static const float DEFAULT_FALLOFF_START = 10.0;  // Default falloff start (%)
static const float DEFAULT_FALLOFF_END = 75.0;    // Default falloff end (%)
static const float DEFAULT_PATTERN_SIZE = 0.03;   // Default pattern element size
static const float DEFAULT_COVERAGE_BOOST = 1.05; // Default pattern coverage boost factor

// --- Visual Style Constants ---
static const int STYLE_SMOOTH_GRADIENT = 0;
static const int STYLE_DUOTONE_CIRCLES = 1;
static const int STYLE_LINES_PERPENDICULAR = 2;
static const int STYLE_LINES_PARALLEL = 3;

// --- Debug Mode Constants ---
static const int DEBUG_PATTERN_ONLY = 4;

//------------------------------------------------------------------------------------------------
// Uniforms (UI Elements)
//------------------------------------------------------------------------------------------------

// --- Group I: Main Effect Style & Appearance ---
uniform int EffectStyle < 
    ui_type = "combo";
    ui_label = "Visual Style"; 
    ui_items = "Smooth Gradient\0Duotone: Circles\0Duotone: Lines (Perpendicular)\0Duotone: Lines (Parallel)\0";
    ui_tooltip = "Selects the overall visual appearance of the effect.";
    ui_category = "Style";
> = STYLE_SMOOTH_GRADIENT;

uniform float3 EffectColor < 
    ui_type = "color";
    ui_label = "Effect Color";
    ui_tooltip = "The primary color used for the gradient or duotone patterns.";
    ui_category = "Style";
> = float3(0.0, 0.0, 0.0);

// --- Group II: Effect Scale & Falloff ---
uniform float EffectScale < 
    ui_type = "slider";
    ui_label = "Effect Scale";
    ui_tooltip = "Controls how far the effect extends. Lower values = smaller effect area.";
    ui_min = 0.1; ui_max = 5.0; ui_step = 0.01;
    ui_category = "Falloff";
> = 1.0;

uniform float FalloffStart < 
    ui_type = "slider";
    ui_label = "Falloff Start (%)";
    ui_min = 0.0; ui_max = 100.0; ui_step = 0.1;
    ui_tooltip = "Defines where the effect begins to transition from solid. Order of Start/End doesn't matter.";
    ui_category = "Falloff";
> = DEFAULT_FALLOFF_START;

uniform float FalloffEnd < 
    ui_type = "slider";
    ui_label = "Falloff End (%)";
    ui_min = 0.0; ui_max = 100.0; ui_step = 0.1;
    ui_tooltip = "Defines where the effect becomes fully transparent after transitioning. Order of Start/End doesn't matter.";
    ui_category = "Falloff";
> = DEFAULT_FALLOFF_END;

// --- Group III: Pattern Specifics (for Duotone/Lines) ---
uniform float PatternElementSize < 
    ui_type = "slider";
    ui_label = "Pattern Element Size / Spacing";
    ui_tooltip = "For Duotone/Lines: Controls the base size of circles, or spacing of lines.";
    ui_min = 0.005; ui_max = 0.2; ui_step = 0.001;
    ui_category = "Pattern";
> = DEFAULT_PATTERN_SIZE;

uniform float PatternCoverageBoost < 
    ui_type = "slider";
    ui_label = "Pattern Coverage Boost"; 
    ui_tooltip = "For Duotone/Lines: Slightly enlarges elements in solid areas to ensure full coverage. 1.0 = no boost.";
    ui_min = 1.0; ui_max = 1.2; ui_step = 0.005;
    ui_category = "Pattern";
> = DEFAULT_COVERAGE_BOOST;

// --- Group IV: Direction & Orientation ---
// Standard rotation controls for AS StageFX
AS_ROTATION_UI(SnapRotation, FineRotation)

uniform bool MirrorDirection < 
    ui_type = "checkbox";
    ui_label = "Mirror Effect";
    ui_tooltip = "Mirrors the directional effect, making it symmetrical around its central axis.";
    ui_category = "Stage";
> = false;

// --- Group V: Output Control ---
uniform bool InvertAlpha < 
    ui_type = "checkbox";
    ui_label = "Invert Transparency";
    ui_tooltip = "Flips the effect's opacity: solid areas become transparent, and vice-versa.";
    ui_category = "Stage";
> = false;

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
float2 axial_round(float2 fa) { 
    float qf=fa.x,rf=fa.y,sf=-qf-rf,qr=round(qf),rr=round(rf),sr=round(sf);
    float qd=abs(qr-qf),rd=abs(rr-rf),sd=abs(sr-sf);
    if(qd>rd&&qd>sd)qr=-rr-sr;
    else if(rd>sd)rr=-qr-sr;
    return float2(qr,rr); 
}
float2 axial_to_cartesian(float2 ax, float gd) { 
    return float2((sqrt(3.f)*ax.x+sqrt(3.f)/2.f*ax.y)*(1.f/gd),(3.f/2.f*ax.y)*(1.f/gd)); 
}
float2 cartesian_to_fractional_axial(float2 ca, float gd) { 
    return float2((sqrt(3.f)/3.f*ca.x-1.f/3.f*ca.y)*gd,(2.f/3.f*ca.y)*gd); 
}
float2 cartesian_to_whole_axial(float2 ca, float gd) { 
    return axial_round(cartesian_to_fractional_axial(ca,gd)); 
}

// --- Composition Logic ---
float GetCompositionFactor(float2 texcoord, float rotation_radians, bool mirror) {
    float2 centered_coord = texcoord - 0.5f;
    float cos_angle = cos(rotation_radians);
    float sin_angle = sin(rotation_radians);
    float rotated_u_component = centered_coord.x * cos_angle + centered_coord.y * sin_angle;
    float factor = rotated_u_component + 0.5f;
    if (mirror) {
        factor = (factor < 0.5f) ? (factor / 0.5f) : ((1.0f - factor) / 0.5f);
    }
    return saturate(factor);
}

// --- Vignette Alpha Calculation ---
float CalculateVignetteAlpha(float position, float normalizedStart, float normalizedEnd, float scale) {
    // Ensure start is smaller than end for correct transition
    float first_threshold = min(normalizedStart, normalizedEnd);
    float second_threshold = max(normalizedStart, normalizedEnd);
    
    // Early exit if thresholds are equal (no transition zone)
    if (first_threshold >= second_threshold) {
        return position <= first_threshold ? 1.0f : 0.0f;
    }
    
    float transitionFactor = 0.0;
    
    // Apply scale to the effective screen area - this changes where the effect ends
    // Scale < 1.0: Effect covers less area from anchor edge
    // Scale > 1.0: Effect extends further (potentially beyond visible area)
    float scaledPosition = position / scale;
        
    if (scaledPosition <= normalizedStart) {
        // Before the start point: full effect
        transitionFactor = 1.0;
    }
    else if (scaledPosition >= normalizedEnd) {
        // After the end point: no effect
        transitionFactor = 0.0;
    }
    else {
        // In the transition zone: smooth blend from 1 to 0
        float normalizedPos = (scaledPosition - normalizedStart) / (normalizedEnd - normalizedStart);
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
    if (raw_alpha_param <= 0.0001f) return float4(color, 0.0f);
    float2 uv_dither = texcoord; uv_dither.y /= ReShade::AspectRatio;
    float current_grid_density = 1.0f / circle_cell_radius_base;
    float2 ca = cartesian_to_whole_axial(uv_dither, current_grid_density); 
    float2 cc = axial_to_cartesian(ca, current_grid_density);
    float dist_uv = distance(cc, uv_dither);
    float boost = lerp(1.0f, coverage_boost_uniform, raw_alpha_param);
    float radius_uv = circle_cell_radius_base * raw_alpha_param * boost;
    float aa_scaler = min(BUFFER_WIDTH, BUFFER_HEIGHT);
    float aa_dist = (radius_uv - dist_uv) * aa_scaler;
    return float4(color, smoothstep(0.0f, 1.0f, aa_dist));
}

float4 ApplyDuotoneLinesParallelPS(float2 texcoord, float raw_alpha_param, float3 color,
                                   float line_cycle_width_uv, float effect_rotation_rad, float coverage_boost_uniform) {
    if (raw_alpha_param <= 0.0001f) return float4(color, 0.0f);
    float2 ctd_coord = texcoord - 0.5f;
    float cos_a = cos(effect_rotation_rad), sin_a = sin(effect_rotation_rad);
    float v_rot = -ctd_coord.x * sin_a + ctd_coord.y * cos_a;
    float band_coord = v_rot + 0.5f;
    float cycle_coord = frac(band_coord / line_cycle_width_uv);
    float base_half_thick = raw_alpha_param * 0.5f;
    float boost = lerp(1.0f, coverage_boost_uniform, raw_alpha_param);
    float boosted_half_thick = base_half_thick * boost;
    float dist_norm = boosted_half_thick - abs(cycle_coord - 0.5f);
    float aa_scaler = min(BUFFER_WIDTH, BUFFER_HEIGHT);
    float aa_dist = (dist_norm * 2.0f * line_cycle_width_uv) * aa_scaler;
    return float4(color, smoothstep(0.0f, 1.0f, aa_dist));
}

float4 ApplyDuotoneLinesPerpendicularPS(float2 texcoord, float raw_alpha_param, float3 color,
                                        float line_cycle_width_uv, float effect_rotation_rad, float coverage_boost_uniform) {
    if (raw_alpha_param <= 0.0001f) return float4(color, 0.0f);
    float2 ctd_coord = texcoord - 0.5f;
    float cos_a = cos(effect_rotation_rad), sin_a = sin(effect_rotation_rad);
    float u_rot = ctd_coord.x * cos_a + ctd_coord.y * sin_a;
    float band_coord = u_rot + 0.5f;
    float cycle_coord = frac(band_coord / line_cycle_width_uv);
    float base_half_thick = raw_alpha_param * 0.5f;
    float boost = lerp(1.0f, coverage_boost_uniform, raw_alpha_param);
    float boosted_half_thick = base_half_thick * boost;
    float dist_norm = boosted_half_thick - abs(cycle_coord - 0.5f);
    float aa_scaler = min(BUFFER_WIDTH, BUFFER_HEIGHT);
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
    
    // Normalize falloff values
    float tA_norm = FalloffStart / 100.0f;
    float tB_norm = FalloffEnd / 100.0f;
    
    // Calculate vignette alpha with scale factor
    float raw_vignette_alpha = CalculateVignetteAlpha(composition_f, tA_norm, tB_norm, EffectScale);
    
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
    }
    
    // Blend with original scene color
    float3 blended_color = lerp(original_color, vignette_effect_color_alpha.rgb, final_effect_alpha);
      // Create a float4 with the effect result for blending and potential debug display
    float4 effect_result = float4(blended_color, 1.0);
    
    // Create the final output by applying standard blend modes
    float4 final_color = effect_result;
    if (BlendAmount < 1.0) {
        float4 background = float4(original_color, 1.0);
        // Use the float4 version of AS_ApplyBlend that accepts BlendAmount parameter
        final_color = AS_ApplyBlend(effect_result, background, BlendMode, BlendAmount);
    }
    
    // Handle debug modes
    if (DebugMode == 1) { // Mask
        return float4(final_effect_alpha.xxx, 1.0);
    }
    else if (DebugMode == 2) { // Falloff
        return float4(raw_vignette_alpha.xxx, 1.0);
    }
    else if (DebugMode == 3) { // Pattern
        float pattern_alpha = vignette_effect_color_alpha.a;
        return float4(pattern_alpha.xxx, 1.0);
    }
    else if (DebugMode == DEBUG_PATTERN_ONLY) { // Pattern Only
        float3 pattern_only = lerp(float3(0,0,0), EffectColor, vignette_effect_color_alpha.a);
        return float4(pattern_only, 1.0);
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