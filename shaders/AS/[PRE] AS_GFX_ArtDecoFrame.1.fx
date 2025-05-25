/**
 * AS_GFX_ArtDecoFrame.1.fx - Art Deco/Nouveau Frame Generator with Procedural Gold Material
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Generates ornate Art Deco/Art Nouveau style decorative frames with realistic procedural gold material simulation.
 * Creates geometric patterns with towers, diamonds, tramlines, and decorative fans, all rendered in authentic metallic gold.
 *
 * FEATURES:
 * - Complex geometric frame construction with multiple layers and decorative elements
 * - Procedural gold material with surface roughness, metallic reflections, and Fresnel effects
 * - Configurable tramlines, towers, corner diamonds, and decorative fans
 * - Real-time surface noise simulation for authentic gold texture variation
 * - Customizable gold hue, saturation, brightness, and metallic properties
 * - Resolution-independent rendering for consistent appearance across screen sizes
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Constructs Art Deco frame geometry using signed distance field functions
 * 2. Applies procedural gold material using HSV color space and fractal noise
 * 3. Simulates surface imperfections with FBM noise for realistic metal appearance
 * 4. Implements Fresnel effects for authentic metallic reflection behavior
 * 5. Renders elements in proper Z-order: fans, diamonds, towers, and frame boxes
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_GFX_ArtDecoFrame_1_fx
#define __AS_GFX_ArtDecoFrame_1_fx

#include "ReShade.fxh"
#include "AS_Noise.1.fxh"
#include "AS_Utils.1.fxh"

#define M_PI 3.14159265358979323846
#define F_EDGE 0.001

// === UI Controls ===
// Gold Style - Main Visual Appearance
uniform float GoldHue < ui_label="Hue"; ui_type="slider"; ui_min=0.0; ui_max=360.0; ui_category="Gold Style"; > = 45.0;
uniform float GoldSaturation < ui_label="Saturation"; ui_type="slider"; ui_min=0.0; ui_max=1.0; ui_category="Gold Style"; > = 0.8;
uniform float GoldBrightness < ui_label="Brightness"; ui_type="slider"; ui_min=0.0; ui_max=2.0; ui_category="Gold Style"; > = 0.85;
uniform float GoldMetallic < ui_label="Metallic"; ui_type="slider"; ui_min=0.0; ui_max=1.0; ui_category="Gold Style"; > = 0.9;
uniform float GoldRoughness < ui_label="Roughness"; ui_type="slider"; ui_min=0.01; ui_max=1.0; ui_category="Gold Style"; > = 0.2;
uniform float NoiseScale < ui_label="Texture Scale"; ui_type="slider"; ui_min=0.1; ui_max=20.0; ui_category="Gold Style"; > = 3.0;
uniform float NoiseIntensity < ui_label="Texture Strength"; ui_type="slider"; ui_min=0.0; ui_max=2.0; ui_category="Gold Style"; > = 0.6;
uniform float NoiseBrightness < ui_label="Texture Brightness"; ui_type="slider"; ui_min=0.0; ui_max=2.0; ui_category="Gold Style"; > = 0.8;
uniform float FresnelPower < ui_label="Shine"; ui_type="slider"; ui_min=0.1; ui_max=10.0; ui_category="Gold Style"; > = 5.0;

// Frame Size - Basic Dimensions
uniform float2 MainSize < ui_label="Outer Frame"; ui_type="slider"; ui_min=0.05; ui_max=2.0; ui_category="Frame Size"; > = float2(0.7, 0.5);
uniform float2 SubSize < ui_label="Inner Frame"; ui_type="slider"; ui_min=0.05; ui_max=2.0; ui_category="Frame Size"; > = float2(0.4, 0.35);

// Decorative Elements - Diamonds, Towers & Fans
uniform float DiamondScalarSize < ui_label="Center Diamond Size"; ui_type="slider"; ui_min=0.05; ui_max=3.0; ui_category="Decorative Elements"; > = 0.9;
uniform float CornerDiamondScalarHalfSize < ui_label="Corner Diamond Size"; ui_type="slider"; ui_min=0.02; ui_max=1.0; ui_category="Decorative Elements"; > = 0.2;
uniform float2 CentralTowerSize < ui_label="Center Tower"; ui_type="slider"; ui_min=0.025; ui_max=1.5; ui_category="Decorative Elements"; > = float2(0.1, 0.8); 
uniform float CentralTowerChamfer < ui_label="Tower Taper"; ui_type="slider"; ui_min=0.0; ui_max=1.0; ui_category="Decorative Elements"; > = 0.5;
uniform float2 SecondaryTowerSize < ui_label="Side Towers"; ui_type="slider"; ui_min=0.01; ui_max=1.0; ui_category="Decorative Elements"; > = float2(0.05, 0.5); 
uniform float SecondaryTowerOffsetX < ui_label="Side Tower Spread"; ui_type="slider"; ui_min=0.0; ui_max=1.0; ui_category="Decorative Elements"; > = 0.2;
uniform bool FanEnable < ui_label="Enable Fans"; ui_type="checkbox"; ui_category="Decorative Elements"; > = true;
uniform bool MirrorFansGlobally < ui_label="Mirror Fans"; ui_type="checkbox"; ui_category="Decorative Elements"; > = false; 
uniform bool FansBehindDiamond < ui_label="Fans Behind Diamond"; ui_type="checkbox"; ui_category="Decorative Elements"; > = false; 
uniform int FanLineCount < ui_label="Fan Lines"; ui_type="slider"; ui_min=3; ui_max=50; ui_category="Decorative Elements"; > = 25;
uniform float FanSpreadDegrees < ui_label="Fan Spread"; ui_type="slider"; ui_min=10.0; ui_max=180.0; ui_category="Decorative Elements"; > = 90.0;
uniform float FanLength < ui_label="Fan Length"; ui_type="slider"; ui_min=0.1; ui_max=2.0; ui_category="Decorative Elements"; > = 0.6;
uniform float FanYOffset < ui_label="Fan Position"; ui_type="slider"; ui_min=0.0; ui_max=1.0; ui_category="Decorative Elements"; > = 0.45;

// Advanced - Technical Fine-Tuning
uniform int NumTramlines < ui_label="Border Lines"; ui_type="slider"; ui_min=1; ui_max=5; ui_category="Advanced"; ui_category_closed=true; > = 3;
uniform float BorderThickness < ui_label="Outer Border Width"; ui_type="slider"; ui_min=0.001; ui_max=0.1; ui_category="Advanced"; ui_category_closed=true; > = 0.02;
uniform float TramlineIndividualThickness < ui_label="Inner Border Width"; ui_type="slider"; ui_min=0.0005; ui_max=0.01; ui_category="Advanced"; ui_category_closed=true; > = 0.0015;
uniform float TramlineSpacing < ui_label="Border Spacing"; ui_type="slider"; ui_min=0.001; ui_max=0.02; ui_category="Advanced"; ui_category_closed=true; > = 0.003;
uniform float DetailPadding < ui_label="Detail Padding"; ui_type="slider"; ui_min=0.001; ui_max=0.2; ui_category="Advanced"; ui_category_closed=true; > = 0.01;
uniform float DetailLineWidth < ui_label="Detail Width"; ui_type="slider"; ui_min=0.001; ui_max=0.05; ui_category="Advanced"; ui_category_closed=true; > = 0.005;
uniform float FanBaseRadius < ui_label="Fan Base Offset"; ui_type="slider"; ui_min=0.0; ui_max=0.5; ui_category="Advanced"; ui_category_closed=true; > = 0.05;
uniform float FanLineThickness < ui_label="Fan Line Width"; ui_type="slider"; ui_min=0.0005; ui_max=0.005; ui_category="Advanced"; ui_category_closed=true; > = 0.001;
uniform float3 FrameFillColorBackup < ui_label="Fallback Fill Color"; ui_type="color"; ui_category="Advanced"; ui_category_closed=true; > = float3(0.05, 0.05, 0.05);
uniform float3 FrameLineColorBackup < ui_label="Fallback Line Color"; ui_type="color"; ui_category="Advanced"; ui_category_closed=true; > = float3(0.9, 0.75, 0.35);

// === Coordinate & SDF Helpers ===
float2 SquareSpaceUV(float2 uv) {
    float bWidth = BUFFER_WIDTH;
    float bHeight = BUFFER_HEIGHT;
    float2 screenDimensions = float2(bWidth, bHeight);
    float2 screenPos = uv * screenDimensions;
    float minDim = min(bWidth, bHeight);
    float2 screenCenter = 0.5 * screenDimensions;
    float2 centeredPos = screenPos - screenCenter;
    if (abs(minDim) < 0.0001) { return float2(0.0, 0.0); }
    float2 scaledPos = centeredPos / minDim;
    return scaledPos * 2.0;
}

float2 rotate(float2 uv, float angle_rad) {
    float s = sin(angle_rad);
    float c = cos(angle_rad);
    return float2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
}

float sdBox(float2 p, float2 b) { // p is relative to box center, b is half-size
    float2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdThickLineSegment(float2 p, float2 a, float2 b, float thickness) {
    float2 pa = p - a; float2 ba = b - a;
    float dot_ba_ba = dot(ba, ba);
    if (dot_ba_ba < 0.000001) { return length(pa) - thickness * 0.5; }
    float h = clamp(dot(pa, ba) / dot_ba_ba, 0.0, 1.0);
    return length(pa - ba * h) - thickness * 0.5;
}

// === Procedural Gold Material System ===
float3 HSVtoRGB(float3 hsv) {
    float h = hsv.x / 60.0;
    float s = hsv.y;
    float v = hsv.z;
    float c = v * s;
    float x = c * (1.0 - abs(fmod(h, 2.0) - 1.0));
    float m = v - c;
    
    float3 rgb;
    if (h < 1.0) rgb = float3(c, x, 0);
    else if (h < 2.0) rgb = float3(x, c, 0);
    else if (h < 3.0) rgb = float3(0, c, x);
    else if (h < 4.0) rgb = float3(0, x, c);
    else if (h < 5.0) rgb = float3(x, 0, c);
    else rgb = float3(c, 0, x);
    
    return rgb + m;
}

float CalculateFresnelFactor(float2 uv, float2 center, float power) {
    float2 toCenter = normalize(uv - center);
    float2 normal = float2(0, 1); // Assume upward normal for simplicity
    float cosTheta = abs(dot(toCenter, normal));
    return pow(1.0 - cosTheta, power);
}

float3 GenerateProceduralGold(float2 uv, bool isFill) {
    // Base gold color from HSV
    float3 baseGold = HSVtoRGB(float3(GoldHue, GoldSaturation, GoldBrightness));
    
    // Generate multiple layers of surface noise using FBM with correct parameters
    float surfaceNoise = AS_Fbm2D(uv * NoiseScale, 4, 2.0, 0.5);
    
    // Apply noise to roughness variation with MUCH enhanced intensity
    float roughnessVariation = GoldRoughness + (surfaceNoise - 0.5) * NoiseIntensity * 2.0;
    roughnessVariation = saturate(roughnessVariation);
    
    // Calculate Fresnel effect for metallic appearance
    float2 screenCenter = float2(0.5, 0.5);
    float fresnelFactor = CalculateFresnelFactor(uv, screenCenter, FresnelPower);
    
    // Apply noise to modify Fresnel intensity for surface variation
    float noisyFresnelFactor = fresnelFactor * (1.0 + (surfaceNoise - 0.5) * NoiseIntensity);
    noisyFresnelFactor = saturate(noisyFresnelFactor);
    
    // Metallic reflection tint (cooler for highlights) with noise variation
    float3 metallicTint = lerp(baseGold, float3(1.0, 0.95, 0.8), noisyFresnelFactor * GoldMetallic);
      // Apply roughness and noise to metallic intensity
    float metallicIntensity = GoldMetallic * (1.0 - roughnessVariation * 0.5);
    metallicIntensity *= (1.0 + (surfaceNoise - 0.5) * NoiseIntensity * 0.5);
    metallicIntensity = saturate(metallicIntensity);
    
    // Enhanced surface brightness variation with dedicated brightness control
    float brightnessMod = 1.0 + (surfaceNoise - 0.5) * NoiseBrightness;
    brightnessMod = saturate(brightnessMod);
    
    // Apply noise to individual color channels for MUCH more dramatic variation
    float3 noiseColorMod = float3(
        1.0 + (AS_Fbm2D(uv * NoiseScale + 0.1, 4, 2.0, 0.5) - 0.5) * NoiseIntensity * 0.4,
        1.0 + (AS_Fbm2D(uv * NoiseScale + 0.3, 4, 2.0, 0.5) - 0.5) * NoiseIntensity * 0.3,
        1.0 + (AS_Fbm2D(uv * NoiseScale + 0.7, 4, 2.0, 0.5) - 0.5) * NoiseIntensity * 0.2
    );
    noiseColorMod = saturate(noiseColorMod);
    
    // Final gold color with ENHANCED surface variation
    float3 finalGold = lerp(baseGold, metallicTint, metallicIntensity);
    finalGold *= brightnessMod;
    finalGold *= noiseColorMod;
    
    // Differentiate fill vs line colors
    if (isFill) {
        // Fill areas are slightly darker and less metallic
        finalGold *= 0.7;
    } else {
        // Line areas are brighter and more reflective with ENHANCED noise
        finalGold *= 1.2;
        float3 highlightColor = lerp(float3(1.0, 0.9, 0.7), float3(1.2, 1.0, 0.8), surfaceNoise);
        finalGold = lerp(finalGold, highlightColor, noisyFresnelFactor * 0.3);
    }
    
    return saturate(finalGold);
}

// === Drawing Functions ===
float drawSingleTramlineSDF(float2 p_eval, float2 line_center_half_size, float line_actual_thickness) {
    float sdf_line_center = sdBox(p_eval, line_center_half_size);
    return saturate(1.0 - smoothstep(
                            line_actual_thickness * 0.5 - F_EDGE,
                            line_actual_thickness * 0.5 + F_EDGE,
                            abs(sdf_line_center)
                         ));
}

float4 drawSolidElementWithTramlines(
    float2 p, float2 outer_box_half_size, bool is_diamond,                   
    int num_tram, float tram_standard_thick, float last_tram_thick, float tram_space,
    float detail_pad, float detail_lw, float3 fill_c, float3 line_c                      
)
{
    float2 p_eval = is_diamond ? abs(rotate(p, M_PI / 4.0)) : p; 
    float3 final_color = fill_c; 
    float tramlines_total_alpha = 0.0;
    float current_offset_from_outer_edge = 0.0;
    float2 inner_edge_of_last_drawn_tramline_hs = outer_box_half_size;

    for (int i = 0; i < num_tram; ++i) {
        float current_line_actual_thickness = (i == num_tram - 1 && num_tram > 0) ? last_tram_thick : tram_standard_thick;
        float2 line_center_half_size = max(0.0.xx, outer_box_half_size - current_offset_from_outer_edge - current_line_actual_thickness * 0.5);
        float tram_alpha = drawSingleTramlineSDF(p_eval, line_center_half_size, current_line_actual_thickness);
        final_color = lerp(final_color, line_c, tram_alpha); 
        tramlines_total_alpha = max(tramlines_total_alpha, tram_alpha);
        current_offset_from_outer_edge += current_line_actual_thickness + tram_space;
        if (i == num_tram -1) { 
             inner_edge_of_last_drawn_tramline_hs = max(0.0.xx, outer_box_half_size - current_offset_from_outer_edge + tram_space);
        }
    }
     if (num_tram == 0) { inner_edge_of_last_drawn_tramline_hs = outer_box_half_size; }

    float2 fill_area_half_size = inner_edge_of_last_drawn_tramline_hs;
    float sdf_fill_area = sdBox(p_eval, fill_area_half_size);
    float fill_alpha = smoothstep(F_EDGE, -F_EDGE, sdf_fill_area);
    final_color = lerp(lerp(fill_c, line_c, tramlines_total_alpha), fill_c, fill_alpha);

    float2 detail_line_center_half_size = max(0.0.xx, fill_area_half_size - detail_pad - detail_lw * 0.5);
    float sdf_detail_line_center = sdBox(p_eval, detail_line_center_half_size);
    float detail_line_alpha = saturate(1.0 - smoothstep(detail_lw * 0.5 - F_EDGE, detail_lw * 0.5 + F_EDGE, abs(sdf_detail_line_center)));
    float3 detail_line_color_val = lerp(fill_c, line_c, 0.5); 
    final_color = lerp(final_color, detail_line_color_val, detail_line_alpha);
    
    float combined_total_alpha = fill_alpha;
     if (fill_alpha < 0.1) { combined_total_alpha = saturate(tramlines_total_alpha + detail_line_alpha); }
    return float4(final_color, combined_total_alpha);
}

float4 drawComplexDiamond(
    float2 p_orig, float diamond_scalar_half_size, float3 fill_c, float3 line_c, 
    int num_tram, float tram_standard_thick, float last_tram_thick, float tram_space,
    float detail_pad, float detail_lw
)
{
    float2 diamond_outer_half_size = float2(diamond_scalar_half_size, diamond_scalar_half_size);
    float2 p_eval = abs(rotate(p_orig, M_PI / 4.0)); 
    float3 final_color = fill_c;
    float tramlines_total_alpha = 0.0;
    float current_offset_main = 0.0;
    float2 inner_edge_of_last_drawn_tramline_hs_diamond = diamond_outer_half_size;

    for (int i = 0; i < num_tram; ++i) {
        float current_line_actual_thickness = (i == num_tram - 1 && num_tram > 0) ? last_tram_thick : tram_standard_thick;
        float2 line_center_hs = max(0.0.xx, diamond_outer_half_size - current_offset_main - current_line_actual_thickness * 0.5);
        float tram_alpha = drawSingleTramlineSDF(p_eval, line_center_hs, current_line_actual_thickness);
        tramlines_total_alpha = max(tramlines_total_alpha, tram_alpha); 
        current_offset_main += current_line_actual_thickness + tram_space;
         if (i == num_tram -1) { inner_edge_of_last_drawn_tramline_hs_diamond = max(0.0.xx, diamond_outer_half_size - current_offset_main + tram_space); }
    }
    if (num_tram == 0) { inner_edge_of_last_drawn_tramline_hs_diamond = diamond_outer_half_size; }

    float fill_alpha = smoothstep(F_EDGE, -F_EDGE, sdBox(p_eval, inner_edge_of_last_drawn_tramline_hs_diamond));
    final_color = lerp(lerp(fill_c, line_c, tramlines_total_alpha), fill_c, fill_alpha); 

    float3 detail_lines_color_val = lerp(fill_c, line_c, 0.5);
    float2 inlay1_center_half_size = max(0.0.xx, inner_edge_of_last_drawn_tramline_hs_diamond - detail_pad - detail_lw * 0.5);
    float sdf_inlay1_center = sdBox(p_eval, inlay1_center_half_size);
    float alpha_inlay1_line = saturate(1.0 - smoothstep(detail_lw * 0.5 - F_EDGE, detail_lw * 0.5 + F_EDGE, abs(sdf_inlay1_center)));
    final_color = lerp(final_color, detail_lines_color_val, alpha_inlay1_line);
    
    float offset_for_line2_center = detail_pad + detail_lw + detail_pad; 
    float2 inlay2_center_half_size = max(0.0.xx, inner_edge_of_last_drawn_tramline_hs_diamond - offset_for_line2_center - detail_lw * 0.5);
    float sdf_inlay2_center = sdBox(p_eval, inlay2_center_half_size);
    float alpha_inlay2_line = saturate(1.0 - smoothstep(detail_lw * 0.5 - F_EDGE, detail_lw * 0.5 + F_EDGE, abs(sdf_inlay2_center)));
    final_color = lerp(final_color, detail_lines_color_val, alpha_inlay2_line);
    
    float combined_total_alpha = fill_alpha;
     if (fill_alpha < 0.1) { combined_total_alpha = saturate(tramlines_total_alpha + alpha_inlay1_line + alpha_inlay2_line); }
    return float4(final_color, combined_total_alpha);
}

float4 drawFan(float2 p_screen, float2 fan_origin_uv, float y_direction_multiplier,
               int line_count, float spread_rad, float base_radius, float line_length, 
               float line_thick, float3 line_c)
{
    if (line_count <= 0) { // Explicit early return
        return float4(line_c, 0.0);
    }

    float min_dist_to_line = 10.0; 

    for (int i = 0; i < line_count; ++i) {
        float t = (line_count == 1) ? 0.5 : float(i) / float(line_count - 1); 
        float angle = spread_rad * (t - 0.5); 
        float2 dir = float2(sin(angle), cos(angle) * y_direction_multiplier);
        float2 start_point = fan_origin_uv + dir * base_radius;
        float2 end_point = fan_origin_uv + dir * (base_radius + line_length);
        float current_line_sdf = sdThickLineSegment(p_screen, start_point, end_point, line_thick);
        min_dist_to_line = min(min_dist_to_line, current_line_sdf);
    }
    
    float fan_alpha = saturate(1.0 - smoothstep(0.0, F_EDGE*2.0, min_dist_to_line));
    float4 result_color = float4(line_c, fan_alpha);
    return result_color; 
}

float GetCentralTowerChamferedTopY(float x_abs_local, float tower_half_w, float tower_total_h, float chamfer_h_extent_ratio) {
    if (chamfer_h_extent_ratio < 0.001 || tower_half_w < 0.0001) return tower_total_h; 
    float chamfer_x_reach_from_side = tower_half_w * saturate(chamfer_h_extent_ratio); 
    float flat_top_half_width = max(0.0, tower_half_w - chamfer_x_reach_from_side); 
    if (x_abs_local <= flat_top_half_width) { return tower_total_h; 
    } else if (x_abs_local <= tower_half_w) {
        float x_on_slope = x_abs_local - flat_top_half_width; 
        float y_drop = x_on_slope; 
        return tower_total_h - y_drop;
    }
    return tower_total_h - chamfer_x_reach_from_side; 
}

struct TowerOutput { float4 color_alpha; };

TowerOutput drawCentralTower(
    float2 p_screen_uv,                 
    float2 tower_base_center_sq_base,   
    float2 tower_dims,                  // X is HALF-WIDTH, Y is TOTAL HEIGHT (from UI)
    float chamfer_ratio, 
    float3 fill_c, float3 line_c
) {
    TowerOutput result; 
    result.color_alpha = float4(0,0,0,0); 

    float2 p_local_to_base = p_screen_uv - tower_base_center_sq_base; 

    float2 p_for_sdBox = p_local_to_base - float2(0, tower_dims.y / 2.0);
    float2 box_half_dims_for_sdf = float2(tower_dims.x, tower_dims.y / 2.0);
    float sdf_base_box = sdBox(float2(abs(p_for_sdBox.x), p_for_sdBox.y), box_half_dims_for_sdf);

    float chamfer_ceiling_y = GetCentralTowerChamferedTopY(abs(p_local_to_base.x), tower_dims.x, tower_dims.y, chamfer_ratio);
    float sdf_chamfer_cut = p_local_to_base.y - chamfer_ceiling_y;

    float sdf_final_shape = max(sdf_base_box, sdf_chamfer_cut);
    
    float fill_alpha = smoothstep(F_EDGE, -F_EDGE, sdf_final_shape);
    float3 color = fill_c;
    float line_alpha = smoothstep(F_EDGE, 0.0, abs(sdf_final_shape)); 
    color = lerp(color, line_c, line_alpha);
    
    result.color_alpha = float4(color, fill_alpha); 
    return result;
}

float4 drawSecondaryTower(
    float2 p_screen_uv, float2 tower_base_center_sq_base, float2 tower_dims, 
    float max_y_clip_from_its_base, bool is_left_tower_of_pair, float3 fill_c, float3 line_c
) {
    float2 p_local_to_base = p_screen_uv - tower_base_center_sq_base; 
    float2 p_for_sdBox = p_local_to_base - float2(0, tower_dims.y / 2.0);
    float2 box_half_dims_for_sdf = float2(tower_dims.x, tower_dims.y / 2.0);
    float sdf_base_box = sdBox(float2(abs(p_for_sdBox.x), p_for_sdBox.y), box_half_dims_for_sdf);
    float sdf_slant_cut;
    float total_height = tower_dims.y;
    float half_width = tower_dims.x;
    float slope = is_left_tower_of_pair ? -1.0 : 1.0; 
    float x_inner_top_corner_local = is_left_tower_of_pair ? half_width : -half_width;
    float y_intercept_slant = total_height - slope * x_inner_top_corner_local;
    sdf_slant_cut = p_local_to_base.y - (slope * p_local_to_base.x + y_intercept_slant);
    float sdf_shape_with_slant = max(sdf_base_box, sdf_slant_cut);
    float sdf_overall_top_clip = p_local_to_base.y - max_y_clip_from_its_base;
    float sdf_final_shape = max(sdf_shape_with_slant, sdf_overall_top_clip);
    float fill_alpha = smoothstep(F_EDGE, -F_EDGE, sdf_final_shape);
    float3 color = fill_c;
    float line_alpha = smoothstep(F_EDGE, 0.0, abs(sdf_final_shape));
    color = lerp(color, line_c, line_alpha);
    return float4(color, fill_alpha);
}


// === Main Pixel Shader ===
float4 PS_Main(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float4 output_color = tex2D(ReShade::BackBuffer, uv);
    float2 sq_base = SquareSpaceUV(uv);

    // Calculate Main Diamond's INNER void for precise fan clipping
    float2 main_diamond_outer_hs_for_clip_calc = float2(DiamondScalarSize, DiamondScalarSize);
    float temp_offset_for_diamond_clip = 0.0;
    float2 main_diamond_inner_void_hs_for_clip = main_diamond_outer_hs_for_clip_calc; 
    if (NumTramlines > 0) {
        for (int i_clip = 0; i_clip < NumTramlines; ++i_clip) {
            float current_line_thick_clip = (i_clip == NumTramlines - 1) ? BorderThickness : TramlineIndividualThickness;
            temp_offset_for_diamond_clip += current_line_thick_clip;
            if (i_clip < NumTramlines - 1) { temp_offset_for_diamond_clip += TramlineSpacing; }
        }
        main_diamond_inner_void_hs_for_clip = max(0.0.xx, main_diamond_outer_hs_for_clip_calc - temp_offset_for_diamond_clip);
    }
    float2 fan_clip_mask_hs = main_diamond_inner_void_hs_for_clip + BorderThickness * 0.5;
    float main_diamond_clipping_sdf = sdBox(abs(rotate(sq_base, M_PI / 4.0)), fan_clip_mask_hs);
    float diamond_clip_mask = 1.0 - smoothstep(0.0, F_EDGE, main_diamond_clipping_sdf);

    float effective_fan_length = FanLength;
    if (FanEnable && !FansBehindDiamond) { effective_fan_length += BorderThickness * 0.5; }

    // --- Render Order ---    // 1. Fans if "Behind Diamond"
    if (FanEnable && FansBehindDiamond) {
        float top_fan_y_dir = MirrorFansGlobally ? -1.0 : 1.0;
        float bottom_fan_y_dir = MirrorFansGlobally ? 1.0 : -1.0;
        float3 goldLineColor = GenerateProceduralGold(uv, false);
        float4 upper_fan = drawFan(sq_base, float2(0.0, FanYOffset), top_fan_y_dir, FanLineCount, FanSpreadDegrees * M_PI / 180.0, FanBaseRadius, FanLength, FanLineThickness, goldLineColor);
        output_color.rgb = lerp(output_color.rgb, upper_fan.rgb, upper_fan.a);
        float4 lower_fan = drawFan(sq_base, float2(0.0, -FanYOffset), bottom_fan_y_dir, FanLineCount, FanSpreadDegrees * M_PI / 180.0, FanBaseRadius, FanLength, FanLineThickness, goldLineColor);
        output_color.rgb = lerp(output_color.rgb, lower_fan.rgb, lower_fan.a);    }    // 2. Main Diamond
    float3 fillColor = FrameFillColorBackup; // Keep original dark background
    float3 goldLineColor = GenerateProceduralGold(uv, false); // Only lines get gold
    float4 diamond_elem = drawComplexDiamond(sq_base, DiamondScalarSize, fillColor, goldLineColor, NumTramlines, TramlineIndividualThickness, BorderThickness, TramlineSpacing, DetailPadding, DetailLineWidth);
    output_color.rgb = lerp(output_color.rgb, diamond_elem.rgb, diamond_elem.a);

    // Define fill and line colors for towers and boxes
    float3 goldFillColor = FrameFillColorBackup; // Fill areas use dark background color
    // goldLineColor already defined above for lines// 3. Corner Diamonds
    float2 main_box_outer_hs_for_corner_calc = MainSize;
    float temp_offset_for_main_box_inner_edge = 0.0;
    float2 main_box_inner_tram_edge_hs = main_box_outer_hs_for_corner_calc; 
    if (NumTramlines > 0) { 
        for (int i_main_box = 0; i_main_box < NumTramlines; ++i_main_box) {
            float current_line_thick_main = (i_main_box == NumTramlines - 1) ? BorderThickness : TramlineIndividualThickness;
            temp_offset_for_main_box_inner_edge += current_line_thick_main;
            if (i_main_box < NumTramlines - 1) { temp_offset_for_main_box_inner_edge += TramlineSpacing;}
        }
        main_box_inner_tram_edge_hs = max(0.0.xx, main_box_outer_hs_for_corner_calc - temp_offset_for_main_box_inner_edge);
    }    float corner_diamond_target_center_x = main_box_inner_tram_edge_hs.x;
    float2 left_cd_pos_center_sq_base = float2(-corner_diamond_target_center_x, 0.0); 
    float4 left_corner_diamond_elem = drawComplexDiamond(sq_base - left_cd_pos_center_sq_base, CornerDiamondScalarHalfSize, fillColor, goldLineColor, NumTramlines, TramlineIndividualThickness, BorderThickness, TramlineSpacing, DetailPadding, DetailLineWidth);
    output_color.rgb = lerp(output_color.rgb, left_corner_diamond_elem.rgb, left_corner_diamond_elem.a);
    float2 right_cd_pos_center_sq_base = float2(corner_diamond_target_center_x, 0.0); 
    float4 right_corner_diamond_elem = drawComplexDiamond(sq_base - right_cd_pos_center_sq_base, CornerDiamondScalarHalfSize, fillColor, goldLineColor, NumTramlines, TramlineIndividualThickness, BorderThickness, TramlineSpacing, DetailPadding, DetailLineWidth);
    output_color.rgb = lerp(output_color.rgb, right_corner_diamond_elem.rgb, right_corner_diamond_elem.a);

    // 4. Towers (Central and Secondary) 
    float central_tower_y_base_on_screen = -CentralTowerSize.y / 2.0; 
    float2 central_tower_base_center_sq_base_param = float2(0.0, central_tower_y_base_on_screen);  // Used _param here
      TowerOutput central_tower = drawCentralTower(sq_base, 
                                                 central_tower_base_center_sq_base_param, // Used _param here
                                                 CentralTowerSize, 
                                                 CentralTowerChamfer, 
                                                 goldFillColor, goldLineColor);
    
    float secondary_tower_y_base_on_screen = -SecondaryTowerSize.y / 2.0; 

    float ct_top_y_at_stl_x_from_ct_base = GetCentralTowerChamferedTopY(
        abs(-SecondaryTowerOffsetX - central_tower_base_center_sq_base_param.x), // Used _param here
        CentralTowerSize.x, CentralTowerSize.y, CentralTowerChamfer);
    float max_y_clip_L_local = (ct_top_y_at_stl_x_from_ct_base + central_tower_base_center_sq_base_param.y) // Used _param here
                             - (secondary_tower_y_base_on_screen); 
                                        
    float ct_top_y_at_str_x_from_ct_base = GetCentralTowerChamferedTopY(
        abs(SecondaryTowerOffsetX - central_tower_base_center_sq_base_param.x), // Used _param here
        CentralTowerSize.x, CentralTowerSize.y, CentralTowerChamfer);
    float max_y_clip_R_local = (ct_top_y_at_str_x_from_ct_base + central_tower_base_center_sq_base_param.y) // Used _param here
                             - (secondary_tower_y_base_on_screen);    float2 sec_tower_l_base_center_sq_base_param = float2(-SecondaryTowerOffsetX, secondary_tower_y_base_on_screen);
    float4 sec_tower_l_elem = drawSecondaryTower(sq_base, sec_tower_l_base_center_sq_base_param, 
                                                 SecondaryTowerSize, max_y_clip_L_local, true, goldFillColor, goldLineColor);
    
    float2 sec_tower_r_base_center_sq_base_param = float2(SecondaryTowerOffsetX, secondary_tower_y_base_on_screen);
    float4 sec_tower_r_elem = drawSecondaryTower(sq_base, sec_tower_r_base_center_sq_base_param,
                                                 SecondaryTowerSize, max_y_clip_R_local, false, goldFillColor, goldLineColor);
    
    output_color.rgb = lerp(output_color.rgb, sec_tower_l_elem.rgb, sec_tower_l_elem.a);
    output_color.rgb = lerp(output_color.rgb, sec_tower_r_elem.rgb, sec_tower_r_elem.a);
    output_color.rgb = lerp(output_color.rgb, central_tower.color_alpha.rgb, central_tower.color_alpha.a);    // 5. Boxes (Main and Sub)
    float4 sub_box_elem = drawSolidElementWithTramlines(sq_base, SubSize, false, NumTramlines, TramlineIndividualThickness, BorderThickness, TramlineSpacing, DetailPadding, DetailLineWidth, goldFillColor, goldLineColor);
    output_color.rgb = lerp(output_color.rgb, sub_box_elem.rgb, sub_box_elem.a);
    float4 main_box_elem = drawSolidElementWithTramlines(sq_base, MainSize, false, NumTramlines, TramlineIndividualThickness, BorderThickness, TramlineSpacing, DetailPadding, DetailLineWidth, goldFillColor, goldLineColor);
    output_color.rgb = lerp(output_color.rgb, main_box_elem.rgb, main_box_elem.a);    // 6. Fans if NOT "Behind Diamond"
    if (FanEnable && !FansBehindDiamond) { 
        float top_fan_y_dir = MirrorFansGlobally ? -1.0 : 1.0;
        float bottom_fan_y_dir = MirrorFansGlobally ? 1.0 : -1.0;
        float3 goldLineColorFans = GenerateProceduralGold(uv, false);
        float4 upper_fan = drawFan(sq_base, float2(0.0, FanYOffset), top_fan_y_dir, FanLineCount, FanSpreadDegrees * M_PI / 180.0, FanBaseRadius, effective_fan_length, FanLineThickness, goldLineColorFans);
        upper_fan.a *= diamond_clip_mask; 
        output_color.rgb = lerp(output_color.rgb, upper_fan.rgb, upper_fan.a);
        float4 lower_fan = drawFan(sq_base, float2(0.0, -FanYOffset), bottom_fan_y_dir, FanLineCount, FanSpreadDegrees * M_PI / 180.0, FanBaseRadius, effective_fan_length, FanLineThickness, goldLineColorFans);
        lower_fan.a *= diamond_clip_mask; 
        output_color.rgb = lerp(output_color.rgb, lower_fan.rgb, lower_fan.a);
    }
    
    return output_color;
}

// === Technique ===
technique ArtDecoFrame
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Main;
    }
}

#endif