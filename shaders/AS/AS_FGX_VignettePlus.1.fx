/**
 * AS_FGX_VignettePlus.1.fx - Enhanced vignette effects with customizable patterns
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * (Full header retained from your version)
 */

#ifndef __AS_FGX_VignettePlus_1_fx
#define __AS_FGX_VignettePlus_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

namespace ASVignettePlus {

// CONSTANTS (Retained from your version)
static const float ALPHA_EPSILON = 0.00001f;
static const float CENTER_COORD = 0.5f;
static const float PERCENT_TO_NORMAL = 0.01f;
static const float FULL_OPACITY = 1.0f;
static const float3 BLACK_COLOR = float3(0.0, 0.0, 0.0);
static const float DEFAULT_FALLOFF_START = 10.0;
static const float DEFAULT_FALLOFF_END = 75.0;
static const float DEFAULT_PATTERN_SIZE = 0.03;
static const float DEFAULT_COVERAGE_BOOST = 1.05;
static const float MIN_FALLOFF = 0.0f;
static const float MAX_FALLOFF = 100.0f;
static const float MIN_PATTERN_SIZE = 0.001f;
static const float MAX_PATTERN_SIZE = 0.1f;
static const float MIN_COVERAGE_BOOST = 1.0f;
static const float MAX_COVERAGE_BOOST = 1.2f;

// --- Visual Style Constants ---
static const int STYLE_SMOOTH_GRADIENT = 0;
static const int STYLE_DUOTONE_CIRCLES = 1;
static const int STYLE_LINES_PERPENDICULAR = 2;
static const int STYLE_LINES_PARALLEL = 3;

// --- Mirror Style Constants --- (NEW)
static const int MIRROR_STYLE_NONE = 0;
static const int MIRROR_STYLE_EDGE = 1;  // Effect emanates from edges inwards
static const int MIRROR_STYLE_CENTER = 2; // Effect emanates from center outwards

// --- Debug Mode Constants ---
static const int DEBUG_OFF = 0;
static const int DEBUG_MASK = 1;
static const int DEBUG_FALLOFF = 2;
static const int DEBUG_PATTERN = 3;
static const int DEBUG_PATTERN_ONLY = 4;

#ifndef M_PI_VIGNETTEPLUS 
#define M_PI_VIGNETTEPLUS 3.14159265358979323846f
#endif

//------------------------------------------------------------------------------------------------
// Uniforms (UI Elements)
//------------------------------------------------------------------------------------------------

// --- Group I: Main Effect Style & Appearance ---
uniform int EffectStyle < ui_type = "combo"; ui_label = "Visual Style"; ui_items = "Smooth Gradient\0Duotone: Circles\0Lines - Perpendicular\0Lines - Parallel\0"; ui_tooltip = "Selects the overall visual appearance of the effect."; ui_category = "Style"; > = STYLE_DUOTONE_CIRCLES;
uniform float3 EffectColor < ui_type = "color"; ui_label = "Effect Color"; ui_tooltip = "The primary color used for the gradient or duotone patterns."; ui_category = "Style"; > = float3(0.0, 0.0, 0.0);

uniform int MirrorStyle < // Changed from bool MirrorDirection
    ui_type = "combo"; 
    ui_label = "Mirroring Style"; 
    ui_items = "None\0Edge Mirrored (From Edges)\0Center Mirrored (From Center)\0"; 
    ui_tooltip = "Selects how the directional effect is mirrored.\nNone: Standard directional effect.\nEdge Mirrored: Effect starts at outer edges and moves inwards.\nCenter Mirrored: Effect starts at the central axis and moves outwards."; 
    ui_category = "Style"; 
> = MIRROR_STYLE_NONE; // Default to None

uniform bool InvertAlpha < ui_type = "checkbox"; ui_label = "Invert Transparency"; ui_tooltip = "Flips the effect's opacity: solid areas become transparent, and vice-versa."; ui_category = "Style"; > = false;

// --- Group II: Falloff Controls ---
uniform float FalloffStart < ui_type = "slider"; ui_label = "Falloff Start (%)"; ui_min = MIN_FALLOFF; ui_max = MAX_FALLOFF; ui_step = 0.1; ui_tooltip = "Defines where the effect begins to transition from solid. Order of Start/End doesn't matter."; ui_category = "Falloff"; > = DEFAULT_FALLOFF_START;
uniform float FalloffEnd < ui_type = "slider"; ui_label = "Falloff End (%)"; ui_min = MIN_FALLOFF; ui_max = MAX_FALLOFF; ui_step = 0.1; ui_tooltip = "Defines where the effect becomes fully transparent after transitioning. Order of Start/End doesn't matter."; ui_category = "Falloff"; > = DEFAULT_FALLOFF_END;

// --- Group III: Pattern Specifics (for Duotone/Lines) ---
uniform float PatternElementSize < ui_type = "slider"; ui_label = "Pattern Element Size / Spacing"; ui_tooltip = "For Duotone/Lines: Controls the base size of circles, or spacing of lines."; ui_min = MIN_PATTERN_SIZE; ui_max = MAX_PATTERN_SIZE; ui_step = 0.001; ui_category = "Pattern"; > = DEFAULT_PATTERN_SIZE;
uniform float PatternCoverageBoost < ui_type = "slider"; ui_label = "Pattern Coverage Boost"; ui_tooltip = "For Duotone/Lines: Slightly enlarges elements in solid areas to ensure full coverage. 1.0 = no boost."; ui_min = MIN_COVERAGE_BOOST; ui_max = MAX_COVERAGE_BOOST; ui_step = 0.005; ui_category = "Pattern"; > = DEFAULT_COVERAGE_BOOST;

// --- Group IV: Direction & Orientation ---
AS_ROTATION_UI(SnapRotation, FineRotation)
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
float fmod_positive(float a, float b) { return a - b * floor(a / b); }
float2 HexGridRoundAxial(float2 fa) { float q=fa.x,r=fa.y,s=-q-r;float qr=round(q),rr=round(r),sr=round(s);float qd=abs(qr-q),rd=abs(rr-r),sd=abs(sr-s);if(qd>rd&&qd>sd)qr=-rr-sr;else if(rd>sd)rr=-qr-sr;return float2(qr,rr); }
float2 HexGridAxialToCartesian(float2 ax, float gd) { float xF=sqrt(3.f),yF=1.5f;return float2((xF*ax.x+xF/2.f*ax.y)/gd,(yF*ax.y)/gd); }
float2 HexGridCartesianToFractionalAxial(float2 ca, float gd) { float qF=sqrt(3.f)/3.f,rxF=-1.f/3.f,ryF=2.f/3.f;return float2((qF*ca.x+rxF*ca.y)*gd,(ryF*ca.y)*gd); }
float2 HexGridCartesianToNearestCell(float2 ca, float gd) { return HexGridRoundAxial(HexGridCartesianToFractionalAxial(ca,gd)); }

// --- Composition Logic ---
float GetCompositionFactor(float2 texcoord, float rotation_radians, int mirror_style) { // Changed mirror parameter
    float2 centered_coord = texcoord - CENTER_COORD;
    float cos_angle = cos(rotation_radians);
    float sin_angle = sin(rotation_radians);

    float projected_value_pixel_scaled = 
        (centered_coord.x * ReShade::ScreenSize.x) * cos_angle + 
        (centered_coord.y * ReShade::ScreenSize.y) * sin_angle;

    float max_extent_pixel_scaled = 
        CENTER_COORD * (ReShade::ScreenSize.x * abs(cos_angle) + 
                        ReShade::ScreenSize.y * abs(sin_angle));
    
    // base_directional_factor ranges 0-1 from one screen edge to the other, along the visually correct rotated direction.
    float base_directional_factor = (projected_value_pixel_scaled / (max_extent_pixel_scaled + ALPHA_EPSILON)) * CENTER_COORD + CENTER_COORD;
    base_directional_factor = saturate(base_directional_factor); // Ensure it's 0-1 before mirroring logic

    float final_factor;
    if (mirror_style == MIRROR_STYLE_EDGE) {
        // Edge Mirrored: factor is 0.0 at edges, 1.0 at center line
        final_factor = (base_directional_factor < CENTER_COORD) ? 
                       (base_directional_factor / CENTER_COORD) : 
                       ((1.0f - base_directional_factor) / CENTER_COORD);
    } else if (mirror_style == MIRROR_STYLE_CENTER) {
        // Center Mirrored: factor is 0.0 at center line, 1.0 at edges
        final_factor = abs(base_directional_factor - CENTER_COORD) * 2.0f;
    } else { // MIRROR_STYLE_NONE or any other case
        final_factor = base_directional_factor;
    }
    
    return saturate(final_factor); // Final saturation for safety
}

// --- Vignette Alpha Calculation ---
float CalculateVignetteAlpha(float position, float normalizedStartInput, float normalizedEndInput) {
    float first_threshold = min(normalizedStartInput, normalizedEndInput);
    float second_threshold = max(normalizedStartInput, normalizedEndInput);
    if (first_threshold >= second_threshold) { 
        return position <= first_threshold ? 1.0f : 0.0f;
    }
    if (position <= first_threshold) { return 1.0f; }
    else if (position >= second_threshold) { return 0.0f; }
    else {
        float t = (position - first_threshold) / (second_threshold - first_threshold);
        return 1.0f - smoothstep(0.0f, 1.0f, t); 
    }
}

//------------------------------------------------------------------------------------------------
// Pattern Functions
//------------------------------------------------------------------------------------------------
float4 ApplySmoothGradientPS(float raw_alpha_param, float3 color) { /* ... */ return float4(color, raw_alpha_param); }

float4 ApplyDuotoneCirclesPS(float2 texcoord, float raw_alpha_param, float3 color,
                             float circle_cell_radius_base, float coverage_boost_uniform) {
    if (raw_alpha_param <= ALPHA_EPSILON) return float4(color, 0.0f);
    float2 uv_dither = texcoord; uv_dither.y /= ReShade::AspectRatio; 
    float current_grid_density = 1.0f / circle_cell_radius_base;
    float2 nC = HexGridCartesianToNearestCell(uv_dither,current_grid_density); float2 cC = HexGridAxialToCartesian(nC,current_grid_density);
    float dist = distance(cC, uv_dither);
    float boost = lerp(1.0f, coverage_boost_uniform, raw_alpha_param);
    float radius = circle_cell_radius_base * raw_alpha_param * boost;
    float aa_w = fwidth(dist); 
    return float4(color, smoothstep(radius + aa_w * 0.5f, radius - aa_w * 0.5f, dist));
}

float4 ApplyDuotoneLinesSharedLogic(float2 texcoord, float raw_alpha_param, float3 color,
                                    float line_cycle_width_uv, float effect_rotation_rad, float coverage_boost_uniform,
                                    bool use_u_component_for_banding) {
    if (raw_alpha_param <= ALPHA_EPSILON) return float4(color, 0.0f);
    float2 ctd_coord = texcoord - CENTER_COORD; float W = ReShade::ScreenSize.x; float H = ReShade::ScreenSize.y;
    float cos_a = cos(effect_rotation_rad), sin_a = sin(effect_rotation_rad);
    float comp_pixels; float max_extent_pixels;
    if (use_u_component_for_banding) {
        comp_pixels = (ctd_coord.x*W)*cos_a + (ctd_coord.y*H)*sin_a;
        max_extent_pixels = CENTER_COORD * (W*abs(cos_a) + H*abs(sin_a));
    } else {
        comp_pixels = -(ctd_coord.x*W)*sin_a + (ctd_coord.y*H)*cos_a;
        max_extent_pixels = CENTER_COORD * (W*abs(sin_a) + H*abs(cos_a));
    }
    float norm_pos_banding = (comp_pixels/(max_extent_pixels+ALPHA_EPSILON))*CENTER_COORD + CENTER_COORD;
    float cycle_in_raw = saturate(norm_pos_banding)/line_cycle_width_uv;
    float coord_cycle = frac(cycle_in_raw); 
    float base_half_thick = raw_alpha_param*CENTER_COORD;
    float boost = lerp(1.0f,coverage_boost_uniform,raw_alpha_param);
    float boosted_half_thick = base_half_thick*boost;
    float val_to_test = abs(coord_cycle-CENTER_COORD);
    float edge_thresh = boosted_half_thick; 
    float aa_w_cycle = fwidth(cycle_in_raw); 
    return float4(color, smoothstep(edge_thresh+aa_w_cycle*0.5f, edge_thresh-aa_w_cycle*0.5f, val_to_test));
}

float4 ApplyDuotoneLinesParallelPS(float2 tc,float ra,float3 col,float lcw,float er,float cbu){ return ApplyDuotoneLinesSharedLogic(tc,ra,col,lcw,er,cbu,false); }
float4 ApplyDuotoneLinesPerpendicularPS(float2 tc,float ra,float3 col,float lcw,float er,float cbu){ return ApplyDuotoneLinesSharedLogic(tc,ra,col,lcw,er,cbu,true); }

//------------------------------------------------------------------------------------------------
// Pixel Shader
//------------------------------------------------------------------------------------------------
float4 VignettePlusPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth) { return tex2D(ReShade::BackBuffer, texcoord); }
    
    float3 original_color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float rotation_radians = AS_getRotationRadians(SnapRotation, FineRotation); 
    
    float composition_f = GetCompositionFactor(texcoord, rotation_radians, MirrorStyle); // Pass MirrorStyle
    float tA_norm = FalloffStart * PERCENT_TO_NORMAL;
    float tB_norm = FalloffEnd * PERCENT_TO_NORMAL;
    float raw_vignette_alpha = CalculateVignetteAlpha(composition_f, tA_norm, tB_norm);
    
    float4 vignette_effect_color_alpha = float4(EffectColor, 0.0f);
    
    if (EffectStyle == STYLE_SMOOTH_GRADIENT) {
        vignette_effect_color_alpha = ApplySmoothGradientPS(raw_vignette_alpha, EffectColor);
    } else if (EffectStyle == STYLE_DUOTONE_CIRCLES) {
        vignette_effect_color_alpha = ApplyDuotoneCirclesPS(texcoord, raw_vignette_alpha, EffectColor, PatternElementSize, PatternCoverageBoost);
    } else if (EffectStyle == STYLE_LINES_PERPENDICULAR) {
        vignette_effect_color_alpha = ApplyDuotoneLinesPerpendicularPS(texcoord, raw_vignette_alpha, EffectColor, PatternElementSize, rotation_radians, PatternCoverageBoost);
    } else if (EffectStyle == STYLE_LINES_PARALLEL) {
        vignette_effect_color_alpha = ApplyDuotoneLinesParallelPS(texcoord, raw_vignette_alpha, EffectColor, PatternElementSize, rotation_radians, PatternCoverageBoost);
    }
    
    float final_effect_alpha = vignette_effect_color_alpha.a;
    if (InvertAlpha) { final_effect_alpha = 1.0f - final_effect_alpha; }
    
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
{ pass { VertexShader = PostProcessVS; PixelShader = ASVignettePlus::VignettePlusPS; } }

} // namespace ASVignettePlus
#endif // __AS_FGX_VignettePlus_1_fx