/**
 * Description:
 * This shader generates animated, abstract, psychedelic visuals. 
 * It iteratively distorts screen coordinates, creating complex, flowing patterns.
 * This distorted space, along with an overlay of vertical stripe patterns, 
 * determines a value ('len') used for psychedelic coloring.
 
 * Source: https://neort.io/art/bkm813c3p9f7drq1j86g
 * liquid chrome by iamsaitam
 */

#include "ReShade.fxh" // Required for ReShade specific uniforms and functions
#include "AS_Utils.1.fxh" // For AS_getTime() and AS_mod()

// --- Tunable Uniforms with Artist-Friendly Labels ---

uniform float coord_scale <
    ui_type = "drag"; ui_min = 1.0; ui_max = 50.0; ui_step = 0.1;
    ui_label = "Pattern Detail Scale";
    ui_tooltip = "Adjusts the overall size of the psychedelic patterns. Higher values zoom in, revealing finer details and faster perceived motion.";
> = 10.0f;

uniform int warp_iterations <
    ui_type = "drag"; ui_min = 1; ui_max = 20; ui_step = 1;
    ui_label = "Warp Complexity";
    ui_tooltip = "Increases the intricacy and 'folding' of the core warped pattern. More iterations lead to deeper, more detailed distortions.";
> = 5;

uniform float warp_time_factor_x <
    ui_type = "drag"; ui_min = 0.0; ui_max = 0.5; ui_step = 0.001;
    ui_label = "Horizontal Flow Speed";
    ui_tooltip = "Controls the speed of the horizontal animation or 'breathing' in the main warp pattern.";
> = 0.07f;

uniform float warp_offset_amp_x <
    ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Horizontal Flow Strength";
    ui_tooltip = "Determines how much the pattern animates or 'breathes' along the horizontal axis.";
> = 0.2f;

uniform float warp_time_factor_y <
    ui_type = "drag"; ui_min = 0.0; ui_max = 0.5; ui_step = 0.001;
    ui_label = "Vertical Flow Speed";
    ui_tooltip = "Controls the speed of the vertical animation or 'undulation' in the main warp pattern.";
> = 0.1f;

uniform float len_post_warp_cos_factor <
    ui_type = "drag"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01;
    ui_label = "Color Band Frequency";
    ui_tooltip = "Adjusts the density of color bands or concentric rings overlaying the pattern. Higher values create more, tighter bands.";
> = 0.4f;

uniform float len_post_warp_subtract <
    ui_type = "drag"; ui_min = -20.0; ui_max = 20.0; ui_step = 0.1; // Expanded range for more shift
    ui_label = "Color Band Offset";
    ui_tooltip = "Shifts the phase or starting point of the color banding/ring pattern, affecting color distribution.";
> = 10.0f;

uniform int stripe_iterations <
    ui_type = "drag"; ui_min = 0; ui_max = 10; ui_step = 1;
    ui_label = "Vertical Line Layers";
    ui_tooltip = "Number of overlaid vertical stripe patterns. Each layer adds more lines with different spacing. Set to 0 to disable stripes.";
> = 5;

uniform float stripe_period_base <
    ui_type = "drag"; ui_min = 0.005; ui_max = 0.5; ui_step = 0.001; // Min slightly lower for very dense option
    ui_label = "Vertical Line Spacing";
    ui_tooltip = "Controls the fundamental spacing of the vertical line patterns. Smaller values create denser, more frequent lines.";
> = 0.09f;

uniform float stripe_scale <
    ui_type = "drag"; ui_min = 10.0; ui_max = 1000.0; ui_step = 1.0;
    ui_label = "Vertical Line Sharpness";
    ui_tooltip = "Adjusts the sharpness or definition of the vertical lines. Higher values can make lines thinner and more pronounced.";
> = 200.0f;

uniform float color_phase_r <
    ui_type = "drag"; ui_min = -6.28318; ui_max = 6.28318; ui_step = 0.01; // Approx -2PI to 2PI
    ui_label = "Red Hue Cycle";
    ui_tooltip = "Shifts the color palette by adjusting the cycle for the red channel. Experiment for different color schemes.";
> = 0.2f;

uniform float color_phase_g <
    ui_type = "drag"; ui_min = -6.28318; ui_max = 6.28318; ui_step = 0.01;
    ui_label = "Green Hue Cycle";
    ui_tooltip = "Shifts the color palette by adjusting the cycle for the green channel.";
> = 0.1f;

uniform float color_phase_b <
    ui_type = "drag"; ui_min = -6.28318; ui_max = 6.28318; ui_step = 0.01;
    ui_label = "Blue Hue Cycle";
    ui_tooltip = "Shifts the color palette by adjusting the cycle for the blue channel.";
> = -0.05f;

uniform float color_r_multiplier <
    ui_type = "drag"; ui_min = 0.0; ui_max = 3.0; ui_step = 0.01;
    ui_label = "Red Intensity";
    ui_tooltip = "Controls the overall intensity or brightness of the red color channel.";
> = 1.15f;

uniform float background_gradient_strength <
    ui_type = "drag"; ui_min = 0.0; ui_max = 0.1; ui_step = 0.001;
    ui_label = "Distortion Tint Strength";
    ui_tooltip = "Controls the intensity of a color tint that is mixed in based on the final warped coordinates.";
> = 0.01f;

uniform float4 background_base_color <
    ui_type = "color";
    ui_label = "Distortion Tint Color";
    ui_tooltip = "Sets the color of the tint mixed in based on the final warped coordinates, affecting the overall image tone.";
> = float4(0.05, 0.07, 0.10, 0.0);

// Internal constant for safety, not a UI tunable
static const float SAFE_DENOMINATOR_EPSILON = 1e-6f;

// --- Pixel Shader ---
float4 PS_PsychedelicWarp(float4 vpos : SV_Position) : SV_Target
{
    float2 resolution = ReShade::ScreenSize;
    float time = AS_getTime(); 

    float2 coord = vpos.xy / resolution;
    float2 st = coord; 
    
    coord *= coord_scale; 
    
    float len = 0.0f; 
    
    // First Loop: Iterative Coordinate Warping
    for (int i = 0; i < warp_iterations; i++) 
    {
        len = length(coord); 
        coord.x += cos(coord.y + sin(len)) + cos(time * warp_time_factor_x) * warp_offset_amp_x;
        coord.y += sin(coord.x + cos(len)) + sin(time * warp_time_factor_y);
    }
    
    len *= cos(len * len_post_warp_cos_factor);
    len -= len_post_warp_subtract;
    
    // Second Loop: Adding Vertical Stripe Details
    if (stripe_iterations > 0)
    {
        for (float i = 0.0f; i < (float)stripe_iterations; i += 1.0f) 
        {
            float period_multiplier = i + 1.0f; 
            float current_stripe_period = stripe_period_base * period_multiplier;
            len += 1.0f / (abs(AS_mod(st.x, current_stripe_period) * stripe_scale) + SAFE_DENOMINATOR_EPSILON);
        }
    }
    
    // Final Color Calculation
    float3 color = float3(
        cos(len + color_phase_r) * color_r_multiplier, 
        cos(len + color_phase_g), 
        cos(len - color_phase_b)
    );
    
    return float4(color, 1.0f);
}

// --- ReShade Technique Definition ---
technique PsychedelicWarp_Studio < // Renamed technique for a more artistic feel
    ui_label = "Psychedelic Warp Studio";
    ui_tooltip = "Create evolving abstract art with kaleidoscopic warps, flowing colors, and stripe patterns.\n"
                 "Fine-tune the visual alchemy with the controls below!";
>
{
    pass PsychedelicWarp_Pass
    {
        VertexShader = PostProcessVS; 
        PixelShader = PS_PsychedelicWarp;
    }
}


