/**
 * AS_GFX_ArtDecoFrame.1.fx - Art Deco/Nouveau Frame Generator
 * Author: Leon Aquitaine
 *
 * Changelog (v9 based on user feedback):
 * - Removed Lrand noise function and GlobalSeed uniform. All details now fully render.
 * - Removed CornerDiamondCenterXOffset uniform.
 * - Corner diamonds are now centered exactly on the main frame's side borders.
 */

#include "ReShade.fxh"

// Define PI & fixed edge for smoothsteps
#define M_PI 3.14159265358979323846
#define F_EDGE 0.001

// === Coordinate & SDF Helpers ===
float2 SquareSpaceUV(float2 uv) {
    float2 screenPos = uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float minDim = min(BUFFER_WIDTH, BUFFER_HEIGHT);
    float2 centered = screenPos - 0.5 * float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    return centered / minDim * 2.0;
}

float2 rotate(float2 uv, float angle_rad) {
    float s = sin(angle_rad);
    float c = cos(angle_rad);
    return float2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
}

float sdBox(float2 p, float2 b) { // b is half-size
    float2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// sdTriangleIsosceles is no longer used by default, but kept for potential future use
float sdTriangleIsosceles(float2 p, float w, float h) {
    p.x = abs(p.x);
    float2 a = float2(w, 0);
    float2 b = float2(0, h);
    float2 ba = b - a;
    float2 pa = p - a;
    float h_sdf = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h_sdf) * sign(pa.x * ba.y - pa.y * ba.x);
}

// === UI Controls ===
// Unified Colors
uniform float3 FrameFillColor < ui_label="Frame Fill Color"; ui_type="color"; > = float3(0.05, 0.05, 0.05);
uniform float3 FrameLineColor < ui_label="Frame Line Color"; ui_type="color"; > = float3(0.9, 0.75, 0.35);

// Shared Border/Detail Controls
uniform float BorderThickness < ui_label="Border Thickness"; ui_type="drag"; ui_min=0.001; ui_max=0.1; > = 0.02;
uniform float DetailPadding < ui_label="Detail Padding"; ui_type="drag"; ui_min=0.001; ui_max=0.2; > = 0.01;
uniform float DetailLineWidth < ui_label="Detail Line Thickness"; ui_type="drag"; ui_min=0.001; ui_max=0.05; > = 0.005;

// Main & Sub Boxes
uniform float2 MainSize < ui_label="Main Frame Half-Size"; ui_type="drag"; ui_min=0.05; ui_max=2.0; > = float2(0.7, 0.5);
uniform float2 SubSize < ui_label="Subframe Half-Size"; ui_type="drag"; ui_min=0.05; ui_max=2.0; > = float2(0.4, 0.35);

// Background Diamond
uniform float DiamondScalarSize < ui_label="Main Diamond Half-Size (Scalar)"; ui_type="drag"; ui_min=0.05; ui_max=3.0; > = 0.9;

// Corner Diamonds
uniform float CornerDiamondScalarHalfSize < ui_label="Corner Diamond Half-Size"; ui_type="drag"; ui_min=0.02; ui_max=1.0; > = 0.2;
// CornerDiamondCenterXOffset removed

// Central Tower
uniform float2 CentralTowerSize < ui_label="Central Tower Half-Size (W, H)"; ui_type="drag"; ui_min=0.025; ui_max=0.75; > = float2(0.1, 0.4);
uniform float CentralTowerChamfer < ui_label="Central Tower Chamfer (0-1, extent from side)"; ui_type="drag"; ui_min=0.0; ui_max=1.0; > = 0.5;

// Secondary Towers
uniform float2 SecondaryTowerSize < ui_label="Secondary Tower Half-Size (W, H)"; ui_type="drag"; ui_min=0.01; ui_max=0.5; > = float2(0.05, 0.25);
uniform float SecondaryTowerOffsetX < ui_label="Secondary Towers Offset X (from center)"; ui_type="drag"; ui_min=0.0; ui_max=1.0; > = 0.2;


// === Drawing Functions ===
float4 drawSolidElementWithDetails(
    float2 p,
    float2 outer_half_size,            
    bool is_diamond,                   
    float main_border_thickness,       
    float detail_padding,              
    float detail_line_width,         
    float3 fill_c,                     
    float3 line_c                      
)
{
    float2 p_eval = is_diamond ? abs(rotate(p, M_PI / 4.0)) : p; 

    float2 main_border_inner_half_size = max(0.0.xx, outer_half_size - main_border_thickness);
    float sdf_mb_outer_edge = sdBox(p_eval, outer_half_size);
    float sdf_mb_inner_edge = sdBox(p_eval, main_border_inner_half_size);

    float main_border_alpha = saturate(smoothstep(F_EDGE, -F_EDGE, sdf_mb_outer_edge) *
                                     (1.0 - smoothstep(F_EDGE, -F_EDGE, sdf_mb_inner_edge)));
    
    float fill_alpha = smoothstep(F_EDGE, -F_EDGE, sdf_mb_inner_edge);

    float2 detail_line_center_half_size = max(0.0.xx, main_border_inner_half_size - detail_padding - detail_line_width * 0.5);
    float sdf_detail_line_center = sdBox(p_eval, detail_line_center_half_size);
    float detail_line_alpha = saturate(1.0 - smoothstep(
                                        detail_line_width * 0.5 - F_EDGE,
                                        detail_line_width * 0.5 + F_EDGE,
                                        abs(sdf_detail_line_center)
                                     ));
    float3 final_color = fill_c;
    final_color = lerp(final_color, line_c, main_border_alpha);
    float3 detail_line_color_val = lerp(fill_c, line_c, 0.5);
    final_color = lerp(final_color, detail_line_color_val, detail_line_alpha);
    
    float combined_total_alpha = fill_alpha;
     if (fill_alpha < 0.1) { 
        combined_total_alpha = saturate(main_border_alpha + detail_line_alpha);
     }
    return float4(final_color, combined_total_alpha);
}

float4 drawComplexDiamond(
    float2 p_orig, float diamond_scalar_half_size,
    float3 fill_c, float3 line_c, 
    float main_border_thick,
    float detail_pad, 
    float detail_lw
    // Removed noise_val, seed
)
{
    float2 diamond_outer_half_size = float2(diamond_scalar_half_size, diamond_scalar_half_size);
    float2 p_eval = abs(rotate(p_orig, M_PI / 4.0)); 

    float2 diamond_main_border_inner_half_size = max(0.0.xx, diamond_outer_half_size - main_border_thick);
    float sdf_dmb_outer_edge = sdBox(p_eval, diamond_outer_half_size);
    float sdf_dmb_inner_edge = sdBox(p_eval, diamond_main_border_inner_half_size);

    float diamond_main_border_alpha = saturate(smoothstep(F_EDGE, -F_EDGE, sdf_dmb_outer_edge) *
                                            (1.0 - smoothstep(F_EDGE, -F_EDGE, sdf_dmb_inner_edge)));
    
    float diamond_fill_alpha = smoothstep(F_EDGE, -F_EDGE, sdf_dmb_inner_edge);
    float3 final_color = fill_c;
    final_color = lerp(final_color, line_c, diamond_main_border_alpha);

    float3 detail_lines_color_val = lerp(fill_c, line_c, 0.5);

    // First detail line (always drawn)
    float2 inlay1_center_half_size = max(0.0.xx, diamond_main_border_inner_half_size - detail_pad - detail_lw * 0.5);
    float sdf_inlay1_center = sdBox(p_eval, inlay1_center_half_size);
    float alpha_inlay1_line = saturate(1.0 - smoothstep(
                                        detail_lw * 0.5 - F_EDGE,
                                        detail_lw * 0.5 + F_EDGE,
                                        abs(sdf_inlay1_center)
                                     ));
    final_color = lerp(final_color, detail_lines_color_val, alpha_inlay1_line);
    
    // Second detail line (always drawn)
    float offset_for_line2_center = detail_pad + detail_lw + detail_pad; 
    float2 inlay2_center_half_size = max(0.0.xx, diamond_main_border_inner_half_size - offset_for_line2_center - detail_lw * 0.5);
    float sdf_inlay2_center = sdBox(p_eval, inlay2_center_half_size);
    float alpha_inlay2_line = saturate(1.0 - smoothstep(
                                        detail_lw * 0.5 - F_EDGE,
                                        detail_lw * 0.5 + F_EDGE,
                                        abs(sdf_inlay2_center)
                                     ));
    final_color = lerp(final_color, detail_lines_color_val, alpha_inlay2_line);
    
    float combined_total_alpha = diamond_fill_alpha;
     if (diamond_fill_alpha < 0.1) {
       // If no fill, alpha is union of main border and any visible detail lines
       combined_total_alpha = saturate(diamond_main_border_alpha + alpha_inlay1_line + alpha_inlay2_line); 
    }
    return float4(final_color, combined_total_alpha);
}

float GetChamferYAtX(float x_offset_from_center, float tower_half_width, float tower_half_height, float chamfer_val_fraction) {
    if (chamfer_val_fraction < 0.001) return tower_half_height;
    float horizontal_extent_of_slope = tower_half_width * saturate(chamfer_val_fraction);
    float flat_top_half_width = tower_half_width - horizontal_extent_of_slope;
    if (abs(x_offset_from_center) <= flat_top_half_width) return tower_half_height;
    float x_pos_on_slope = abs(x_offset_from_center) - flat_top_half_width; 
    float y_drop = x_pos_on_slope; 
    return tower_half_height - y_drop;
}

struct TowerOutput { float4 color_alpha; };

TowerOutput drawCentralTower(float2 p_local_base_centered, float2 half_size, float chamfer_fraction, 
                             float3 fill_c, float3 line_c)
{
    float2 p_detail_sym = float2(abs(p_local_base_centered.x), p_local_base_centered.y);
    float sdf_base_box = sdBox(p_detail_sym, half_size);
    float chamfer_cut_line_sdf = -1.0; 
    if (chamfer_fraction > 0.001) {
        float y_on_chamfer_line = GetChamferYAtX(p_detail_sym.x, half_size.x, half_size.y, chamfer_fraction);
        float flat_top_half_width = half_size.x * (1.0 - saturate(chamfer_fraction));
        if (p_detail_sym.x > flat_top_half_width) { 
            chamfer_cut_line_sdf = p_detail_sym.y - y_on_chamfer_line;
        }
    }
    float sdf_final_shape = sdf_base_box;
    if (chamfer_cut_line_sdf > -0.5) { 
      sdf_final_shape = max(sdf_base_box, chamfer_cut_line_sdf);
    }
    float fill_alpha = smoothstep(F_EDGE, -F_EDGE, sdf_final_shape);
    float3 color = fill_c;
    float line_alpha = smoothstep(F_EDGE, 0.0, abs(sdf_final_shape));
    color = lerp(color, line_c, line_alpha);
    TowerOutput result;
    result.color_alpha = float4(color, fill_alpha);
    return result;
}

float4 drawSecondaryTower(float2 p_local_base_centered, float2 half_size, float max_y_clip_local,
                          float3 fill_c, float3 line_c)
{
    float sdf_base_box = sdBox(p_local_base_centered, half_size);
    float sdf_clipped = max(sdf_base_box, p_local_base_centered.y - max_y_clip_local);
    float fill_alpha = smoothstep(F_EDGE, -F_EDGE, sdf_clipped);
    float3 color = fill_c;
    float line_alpha = smoothstep(F_EDGE, 0.0, abs(sdf_clipped));
    color = lerp(color, line_c, line_alpha);
    return float4(color, fill_alpha);
}

// === Main Pixel Shader ===
float4 PS_Main(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float4 output_color = tex2D(ReShade::BackBuffer, uv);
    float2 sq_base = SquareSpaceUV(uv);

    // Layer 0: Background Diamond
    float4 diamond_elem = drawComplexDiamond(sq_base, DiamondScalarSize, 
                                             FrameFillColor, FrameLineColor,
                                             BorderThickness, DetailPadding, DetailLineWidth);
    output_color.rgb = lerp(output_color.rgb, diamond_elem.rgb, diamond_elem.a);

    // --- Corner Diamonds ---
    // Left Corner Diamond: Centered on the left edge of the Main Frame
    float2 left_cd_uv_offset = float2(MainSize.x, 0.0); // X-distance from screen center to main frame's left edge center
    float4 left_corner_diamond_elem = drawComplexDiamond(sq_base + left_cd_uv_offset, CornerDiamondScalarHalfSize,
                                                        FrameFillColor, FrameLineColor,
                                                        BorderThickness, DetailPadding, DetailLineWidth);
    output_color.rgb = lerp(output_color.rgb, left_corner_diamond_elem.rgb, left_corner_diamond_elem.a);

    // Right Corner Diamond: Centered on the right edge of the Main Frame
    float2 right_cd_uv_offset = float2(MainSize.x, 0.0); // X-distance from screen center to main frame's right edge center
    float4 right_corner_diamond_elem = drawComplexDiamond(sq_base - right_cd_uv_offset, CornerDiamondScalarHalfSize,
                                                         FrameFillColor, FrameLineColor,
                                                         BorderThickness, DetailPadding, DetailLineWidth);
    output_color.rgb = lerp(output_color.rgb, right_corner_diamond_elem.rgb, right_corner_diamond_elem.a);

    // Layer 1: Sub Box
    float4 sub_box_elem = drawSolidElementWithDetails(sq_base, SubSize, false,
                                                      BorderThickness, DetailPadding, DetailLineWidth, 
                                                      FrameFillColor, FrameLineColor);
    output_color.rgb = lerp(output_color.rgb, sub_box_elem.rgb, sub_box_elem.a);

    // Layer 2: Main Box
    float4 main_box_elem = drawSolidElementWithDetails(sq_base, MainSize, false,
                                                       BorderThickness, DetailPadding, DetailLineWidth, 
                                                       FrameFillColor, FrameLineColor);
    output_color.rgb = lerp(output_color.rgb, main_box_elem.rgb, main_box_elem.a);
    
    // --- Towers ---
    float tower_base_y_offset = -CentralTowerSize.y; 
    float secondary_tower_base_y_in_sq_base = -SecondaryTowerSize.y;

    float2 central_tower_local_uv = float2(sq_base.x, sq_base.y - tower_base_y_offset);
    TowerOutput central_tower = drawCentralTower(central_tower_local_uv, CentralTowerSize, CentralTowerChamfer,
                                            FrameFillColor, FrameLineColor);
    
    float central_tower_effective_base_y_sq = tower_base_y_offset;
    float clip_y_secondary_l_abs_sq_base = GetChamferYAtX(-SecondaryTowerOffsetX, CentralTowerSize.x, CentralTowerSize.y, CentralTowerChamfer) + central_tower_effective_base_y_sq;
    float clip_y_secondary_r_abs_sq_base = GetChamferYAtX( SecondaryTowerOffsetX, CentralTowerSize.x, CentralTowerSize.y, CentralTowerChamfer) + central_tower_effective_base_y_sq;
    float max_y_local_secondary_l = clip_y_secondary_l_abs_sq_base - secondary_tower_base_y_in_sq_base;
    float max_y_local_secondary_r = clip_y_secondary_r_abs_sq_base - secondary_tower_base_y_in_sq_base;

    float2 sec_tower_l_local_uv = float2(sq_base.x + SecondaryTowerOffsetX, sq_base.y - secondary_tower_base_y_in_sq_base);
    float4 sec_tower_l_elem = drawSecondaryTower(sec_tower_l_local_uv, SecondaryTowerSize, max_y_local_secondary_l,
                                                FrameFillColor, FrameLineColor);
    output_color.rgb = lerp(output_color.rgb, sec_tower_l_elem.rgb, sec_tower_l_elem.a);

    float2 sec_tower_r_local_uv = float2(sq_base.x - SecondaryTowerOffsetX, sq_base.y - secondary_tower_base_y_in_sq_base);
    float4 sec_tower_r_elem = drawSecondaryTower(sec_tower_r_local_uv, SecondaryTowerSize, max_y_local_secondary_r,
                                                FrameFillColor, FrameLineColor);
    output_color.rgb = lerp(output_color.rgb, sec_tower_r_elem.rgb, sec_tower_r_elem.a);
    
    output_color.rgb = lerp(output_color.rgb, central_tower.color_alpha.rgb, central_tower.color_alpha.a);

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