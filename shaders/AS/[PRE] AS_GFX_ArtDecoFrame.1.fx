/**
 * AS_GFX_ArtDecoFrame.1.fx - Art Deco/Nouveau Frame Generator
 * Author: Leon Aquitaine (with additions by AI)
 *
 * Changelog (v12.1 base, with targeted corner diamond placement fix):
 * - Corner diamonds' centers are now placed exactly at the inner edge of the
 * main frame's tramline border.
 */

#include "ReShade.fxh"

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

float sdBox(float2 p, float2 b) {
    float2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdThickLineSegment(float2 p, float2 a, float2 b, float thickness) {
    float2 pa = p - a;
    float2 ba = b - a;
    float dot_ba_ba = dot(ba, ba);

    // Corrected from v13.3 to handle zero-length segments
    if (dot_ba_ba < 0.000001) { 
        return length(pa) - thickness * 0.5; 
    }

    float h = clamp(dot(pa, ba) / dot_ba_ba, 0.0, 1.0);
    return length(pa - ba * h) - thickness * 0.5;
}

// === UI Controls ===
// Unified Colors
uniform float3 FrameFillColor < ui_label="Frame Fill Color"; ui_type="color"; > = float3(0.05, 0.05, 0.05);
uniform float3 FrameLineColor < ui_label="Frame Line Color"; ui_type="color"; > = float3(0.9, 0.75, 0.35);

// Shared Border/Detail Controls
uniform float BorderThickness < ui_label="Last Tramline Thickness"; ui_type="drag"; ui_min=0.001; ui_max=0.1; > = 0.02;
uniform float DetailPadding < ui_label="Detail Line Padding (from inner tramline)"; ui_type="drag"; ui_min=0.001; ui_max=0.2; > = 0.01;
uniform float DetailLineWidth < ui_label="Detail Line Thickness"; ui_type="drag"; ui_min=0.001; ui_max=0.05; > = 0.005;

// Tramline Controls
uniform int NumTramlines < ui_label="Number of Tramlines"; ui_type="slider"; ui_min=1; ui_max=5; > = 3;
uniform float TramlineIndividualThickness < ui_label="Standard Tramline Thickness"; ui_type="drag"; ui_min=0.0005; ui_max=0.01; > = 0.0015;
uniform float TramlineSpacing < ui_label="Tramline Spacing"; ui_type="drag"; ui_min=0.001; ui_max=0.02; > = 0.003;

// Main & Sub Boxes
uniform float2 MainSize < ui_label="Main Frame Half-Size"; ui_type="drag"; ui_min=0.05; ui_max=2.0; > = float2(0.7, 0.5);
uniform float2 SubSize < ui_label="Subframe Half-Size"; ui_type="drag"; ui_min=0.05; ui_max=2.0; > = float2(0.4, 0.35);

// Background Diamond
uniform float DiamondScalarSize < ui_label="Main Diamond Half-Size (Scalar)"; ui_type="drag"; ui_min=0.05; ui_max=3.0; > = 0.9;

// Corner Diamonds
uniform float CornerDiamondScalarHalfSize < ui_label="Corner Diamond Half-Size"; ui_type="drag"; ui_min=0.02; ui_max=1.0; > = 0.2;

// Central Tower
uniform float2 CentralTowerSize < ui_label="Central Tower Half-Size (W, H)"; ui_type="drag"; ui_min=0.025; ui_max=0.75; > = float2(0.1, 0.4);
uniform float CentralTowerChamfer < ui_label="Central Tower Chamfer (0-1, extent from side)"; ui_type="drag"; ui_min=0.0; ui_max=1.0; > = 0.5;

// Secondary Towers
uniform float2 SecondaryTowerSize < ui_label="Secondary Tower Half-Size (W, H)"; ui_type="drag"; ui_min=0.01; ui_max=0.5; > = float2(0.05, 0.25);
uniform float SecondaryTowerOffsetX < ui_label="Secondary Towers Offset X (from center)"; ui_type="drag"; ui_min=0.0; ui_max=1.0; > = 0.2;

// Fan Elements
uniform bool FanEnable <ui_label="Enable Fans"; ui_type="checkbox";> = true;
uniform bool MirrorFansGlobally <ui_label="Mirror Fans Globally"; ui_type="checkbox";> = false; 
uniform bool FansBehindDiamond <ui_label="Render Fans Behind Diamond"; ui_type="checkbox";> = false; 
uniform int FanLineCount < ui_label="Fan Line Count (per fan)"; ui_type="slider"; ui_min=3; ui_max=50; > = 25;
uniform float FanSpreadDegrees < ui_label="Fan Spread (Degrees)"; ui_type="drag"; ui_min=10.0; ui_max=180.0; > = 90.0;
uniform float FanBaseRadius < ui_label="Fan Base Radius (Offset from Origin)"; ui_type="drag"; ui_min=0.0; ui_max=0.5; > = 0.05;
uniform float FanLength < ui_label="Fan Line Length"; ui_type="drag"; ui_min=0.1; ui_max=2.0; > = 0.6;
uniform float FanLineThickness < ui_label="Fan Line Thickness"; ui_type="drag"; ui_min=0.0005; ui_max=0.005; > = 0.001;
uniform float FanYOffset < ui_label="Fan Y Offset (from screen center)"; ui_type="drag"; ui_min=0.0; ui_max=1.0; > = 0.45;


// === Drawing Functions ===
// (Using the versions from the code you provided, assuming they were preferred)
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

    float2 fill_area_half_size = inner_edge_of_last_drawn_tramline_hs; // Fill up to this calculated inner edge
    float sdf_fill_area = sdBox(p_eval, fill_area_half_size);
    float fill_alpha = smoothstep(F_EDGE, -F_EDGE, sdf_fill_area);
    // This coloring makes fill primary, then tramlines overlay it.
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
        tramlines_total_alpha = max(tramlines_total_alpha, tram_alpha); // Accumulate max alpha for tramlines
        current_offset_main += current_line_actual_thickness + tram_space;
         if (i == num_tram -1) { inner_edge_of_last_drawn_tramline_hs_diamond = max(0.0.xx, diamond_outer_half_size - current_offset_main + tram_space); }
    }
    if (num_tram == 0) { inner_edge_of_last_drawn_tramline_hs_diamond = diamond_outer_half_size; }

    float fill_alpha = smoothstep(F_EDGE, -F_EDGE, sdBox(p_eval, inner_edge_of_last_drawn_tramline_hs_diamond));
    final_color = lerp(lerp(fill_c, line_c, tramlines_total_alpha), fill_c, fill_alpha); // Same coloring as box

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
    float min_dist_to_line = 10.0;
    if (line_count <= 0) return float4(line_c, 0.0);

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
    return float4(line_c, fan_alpha);
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
    TowerOutput result; 
    result.color_alpha = float4(0,0,0,0); 

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

    float main_diamond_sdf = sdBox(abs(rotate(sq_base, M_PI / 4.0)), DiamondScalarSize);
    float diamond_clip_mask = 1.0 - smoothstep(0.0, F_EDGE, main_diamond_sdf); // Corrected mask

    if (FanEnable && FansBehindDiamond) {
        float top_fan_y_dir = MirrorFansGlobally ? -1.0 : 1.0;
        float bottom_fan_y_dir = MirrorFansGlobally ? 1.0 : -1.0;
        float4 upper_fan = drawFan(sq_base, float2(0.0, FanYOffset), top_fan_y_dir, FanLineCount, FanSpreadDegrees * M_PI / 180.0, FanBaseRadius, FanLength, FanLineThickness, FrameLineColor);
        output_color.rgb = lerp(output_color.rgb, upper_fan.rgb, upper_fan.a);
        float4 lower_fan = drawFan(sq_base, float2(0.0, -FanYOffset), bottom_fan_y_dir, FanLineCount, FanSpreadDegrees * M_PI / 180.0, FanBaseRadius, FanLength, FanLineThickness, FrameLineColor);
        output_color.rgb = lerp(output_color.rgb, lower_fan.rgb, lower_fan.a);
    }

    float4 diamond_elem = drawComplexDiamond(sq_base, DiamondScalarSize, FrameFillColor, FrameLineColor, NumTramlines, TramlineIndividualThickness, BorderThickness, TramlineSpacing, DetailPadding, DetailLineWidth);
    output_color.rgb = lerp(output_color.rgb, diamond_elem.rgb, diamond_elem.a);

    // --- Corner Diamonds Placement ---
    // Calculate the x-coordinate of the main frame's actual inner visual edge (after all its tramlines)
    float2 main_box_outer_hs_for_calc = MainSize;
    float temp_current_offset_for_main_box_inner_edge = 0.0;
    float2 main_box_inner_tram_edge_hs = main_box_outer_hs_for_calc; // Default if NumTramlines is 0

    if (NumTramlines > 0) { // Check to prevent issues if NumTramlines could be 0, though UI min is 1
        for (int i = 0; i < NumTramlines; ++i) {
            float current_line_thick = (i == NumTramlines - 1) ? BorderThickness : TramlineIndividualThickness;
            temp_current_offset_for_main_box_inner_edge += current_line_thick;
            if (i < NumTramlines - 1) { // Add spacing if it's not the very last thickness being added
                temp_current_offset_for_main_box_inner_edge += TramlineSpacing;
            }
        }
        main_box_inner_tram_edge_hs = max(0.0.xx, main_box_outer_hs_for_calc - temp_current_offset_for_main_box_inner_edge);
    }
    float corner_diamond_target_center_x = main_box_inner_tram_edge_hs.x;


    // Left Corner Diamond
    float2 left_cd_pos = float2(-corner_diamond_target_center_x, 0.0); 
    float4 left_corner_diamond_elem = drawComplexDiamond(sq_base - left_cd_pos, CornerDiamondScalarHalfSize, FrameFillColor, FrameLineColor, NumTramlines, TramlineIndividualThickness, BorderThickness, TramlineSpacing, DetailPadding, DetailLineWidth);
    output_color.rgb = lerp(output_color.rgb, left_corner_diamond_elem.rgb, left_corner_diamond_elem.a);

    // Right Corner Diamond
    float2 right_cd_pos = float2(corner_diamond_target_center_x, 0.0); 
    float4 right_corner_diamond_elem = drawComplexDiamond(sq_base - right_cd_pos, CornerDiamondScalarHalfSize, FrameFillColor, FrameLineColor, NumTramlines, TramlineIndividualThickness, BorderThickness, TramlineSpacing, DetailPadding, DetailLineWidth);
    output_color.rgb = lerp(output_color.rgb, right_corner_diamond_elem.rgb, right_corner_diamond_elem.a);


    // --- Boxes drawn AFTER main diamond and corner diamonds ---
    float4 sub_box_elem = drawSolidElementWithTramlines(sq_base, SubSize, false, NumTramlines, TramlineIndividualThickness, BorderThickness, TramlineSpacing, DetailPadding, DetailLineWidth, FrameFillColor, FrameLineColor);
    output_color.rgb = lerp(output_color.rgb, sub_box_elem.rgb, sub_box_elem.a);
    float4 main_box_elem = drawSolidElementWithTramlines(sq_base, MainSize, false, NumTramlines, TramlineIndividualThickness, BorderThickness, TramlineSpacing, DetailPadding, DetailLineWidth, FrameFillColor, FrameLineColor);
    output_color.rgb = lerp(output_color.rgb, main_box_elem.rgb, main_box_elem.a);

    // --- Fans drawn AFTER boxes if !FansBehindDiamond, so they appear on top of boxes (but clipped by diamond) ---
    if (FanEnable && !FansBehindDiamond) { 
        float top_fan_y_dir = MirrorFansGlobally ? -1.0 : 1.0;
        float bottom_fan_y_dir = MirrorFansGlobally ? 1.0 : -1.0;
        float4 upper_fan = drawFan(sq_base, float2(0.0, FanYOffset), top_fan_y_dir, FanLineCount, FanSpreadDegrees * M_PI / 180.0, FanBaseRadius, FanLength, FanLineThickness, FrameLineColor);
        upper_fan.a *= diamond_clip_mask; 
        output_color.rgb = lerp(output_color.rgb, upper_fan.rgb, upper_fan.a);
        float4 lower_fan = drawFan(sq_base, float2(0.0, -FanYOffset), bottom_fan_y_dir, FanLineCount, FanSpreadDegrees * M_PI / 180.0, FanBaseRadius, FanLength, FanLineThickness, FrameLineColor);
        lower_fan.a *= diamond_clip_mask; 
        output_color.rgb = lerp(output_color.rgb, lower_fan.rgb, lower_fan.a);
    }
    
    // --- Towers drawn last ---
    float tower_base_y_offset = -CentralTowerSize.y; 
    float secondary_tower_base_y_in_sq_base = -SecondaryTowerSize.y;
    float2 central_tower_local_uv = float2(sq_base.x, sq_base.y - tower_base_y_offset);
    TowerOutput central_tower = drawCentralTower(central_tower_local_uv, CentralTowerSize, CentralTowerChamfer, FrameFillColor, FrameLineColor);
    float central_tower_effective_base_y_sq = tower_base_y_offset;
    float clip_y_secondary_l_abs_sq_base = GetChamferYAtX(-SecondaryTowerOffsetX, CentralTowerSize.x, CentralTowerSize.y, CentralTowerChamfer) + central_tower_effective_base_y_sq;
    float clip_y_secondary_r_abs_sq_base = GetChamferYAtX( SecondaryTowerOffsetX, CentralTowerSize.x, CentralTowerSize.y, CentralTowerChamfer) + central_tower_effective_base_y_sq;
    float max_y_local_secondary_l = clip_y_secondary_l_abs_sq_base - secondary_tower_base_y_in_sq_base;
    float max_y_local_secondary_r = clip_y_secondary_r_abs_sq_base - secondary_tower_base_y_in_sq_base;
    float2 sec_tower_l_local_uv = float2(sq_base.x + SecondaryTowerOffsetX, sq_base.y - secondary_tower_base_y_in_sq_base);
    float4 sec_tower_l_elem = drawSecondaryTower(sec_tower_l_local_uv, SecondaryTowerSize, max_y_local_secondary_l, FrameFillColor, FrameLineColor);
    output_color.rgb = lerp(output_color.rgb, sec_tower_l_elem.rgb, sec_tower_l_elem.a);
    float2 sec_tower_r_local_uv = float2(sq_base.x - SecondaryTowerOffsetX, sq_base.y - secondary_tower_base_y_in_sq_base);
    float4 sec_tower_r_elem = drawSecondaryTower(sec_tower_r_local_uv, SecondaryTowerSize, max_y_local_secondary_r, FrameFillColor, FrameLineColor);
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