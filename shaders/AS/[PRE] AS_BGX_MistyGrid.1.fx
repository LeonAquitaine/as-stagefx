/**
 * Raymarching Abstract Fractal - Converted from GLSL
 *
 * Original GLSL shader by an unknown author, likely from Shadertoy or similar.
 * This is an initial conversion to ReShade HLSL format.
 *
 * Key changes:
 * - mainImage to MainPS pixel shader.
 * - iTime to Timer uniform (scaled).
 * - iResolution to ReShade::ScreenSize.
 * - vec/mat types to float/floatNxM.
 * - Global accumulators (at, at2, at3) passed as inout parameters.
 * - [loop] attribute added to the main raymarching loop.
 */

#include "ReShade.fxh" // Basic ReShade utilities

//------------------------------------------------------------------------------------------------
// Uniforms
//------------------------------------------------------------------------------------------------
uniform float Timer < source = "timer"; ui_label = "Timer (ms)"; ui_tooltip = "Animation timer in milliseconds."; >;

//------------------------------------------------------------------------------------------------
// Helper Functions (GLSL to HLSL)
//------------------------------------------------------------------------------------------------

// Rotation matrix function
float2x2 rot_hlsl(float a) {
    float ca = cos(a);
    float sa = sin(a);
    // HLSL matrix constructor: float2x2(col0.x, col1.x, col0.y, col1.y) for row-major style assignment
    // or float2x2(row0col0, row0col1, row1col0, row1col1)
    // Given GLSL mat2(ca,sa,-sa,ca) (column-major), this is:
    // col0 = (ca, -sa), col1 = (sa, ca)
    // In HLSL, float2x2(m00, m01, m10, m11)
    return float2x2(ca, sa, -sa, ca); // This creates mat[0]=(ca,sa), mat[1]=(-sa,ca)
}

// Box signed distance function (SDF)
float box_hlsl(float3 p, float3 s) {
    p = abs(p) - s;
    return max(p.x, max(p.y, p.z));
}

/**
 * Fractal iteration function.
 * @param p Input point.
 * @param t_param Time-dependent parameter for this iteration step (from map_hlsl's 't_map').
 * @param effect_time Overall animation time (from MainPS's 'local_time').
 */
float3 fr_hlsl(float3 p, float t_param, float effect_time) {
    // Original GLSL: float s = 0.7 - smoothstep(0.0,1.0,abs(fract(time*0.1)-0.5)*2.0)*0.3;
    // 'effect_time' here corresponds to the global 'time' in the original GLSL.
    float s_factor = 0.7 - smoothstep(0.0, 1.0, abs(frac(effect_time * 0.1) - 0.5) * 2.0) * 0.3;

    // The loop should be unrollable by the compiler as it's small and fixed.
    // Adding [unroll] explicitly can ensure this if needed, but usually not necessary for count 5.
    for (int i = 0; i < 5; ++i) {
        float t2 = t_param + (float)i;
        // In HLSL, mul(vector, matrix) is common for row vectors.
        // p.xy = p.xy * mat  =>  p.xy = mul(p.xy, mat)
        p.xy = mul(p.xy, rot_hlsl(t2));
        p.yz = mul(p.yz, rot_hlsl(t2 * 0.7));

        float fold_dist = 10.0;
        p = (frac(p / fold_dist - 0.5) - 0.5) * fold_dist; // Domain folding
        p = abs(p);
        p -= s_factor; // Apply scaling/offset
    }
    return p;
}

/**
 * Main distance estimator function (SDF map).
 * @param p Point in space to sample.
 * @param effect_time Overall animation time.
 * @param at_acc Accumulator 1 (passed by reference).
 * @param at2_acc Accumulator 2 (passed by reference).
 * @param at3_acc Accumulator 3 (passed by reference).
 * @return Signed distance to the surface.
 */
float map_hlsl(float3 p, float effect_time, inout float at_acc, inout float at2_acc, inout float at3_acc) {
    float3 initial_p = p; // Store original p for some calculations (bp in GLSL)

    // Initial rotations based on p's components and time
    p.xy = mul(p.xy, rot_hlsl((p.z * 0.023 + effect_time * 0.1) * 0.3));
    p.yz = mul(p.yz, rot_hlsl((p.x * 0.087) * 0.4));

    float t_map_internal = effect_time * 0.5; // Corresponds to 't' inside GLSL map
    float3 p_fr1 = fr_hlsl(p, t_map_internal * 0.2, effect_time);
    float3 p_fr2 = fr_hlsl(p + float3(5.0, 0.0, 0.0), t_map_internal * 0.23, effect_time);

    float d1 = box_hlsl(p_fr1, float3(1.0, 1.3, 4.0));
    float d2 = box_hlsl(p_fr2, float3(3.0, 0.7, 0.4));

    // Combine distances and apply further modifications
    float d = max(abs(d1), abs(d2)) - 0.2; // Note: abs(d1), abs(d2) used here.
    
    float fold_dist_map = 1.0;
    float3 p_box3 = (frac(p_fr1 / fold_dist_map - 0.5) - 0.5) * fold_dist_map; // Using p_fr1 for this box
    float d3 = box_hlsl(p_box3, float3(0.4, 0.4, 0.4));
    d = d - d3 * 0.4; // Subtracting another SDF (boolean subtraction or erosion)

    // Accumulate 'at_acc' based on proximity to the current surface 'd'
    at_acc += 0.13 / (0.13 + abs(d));

    // Further SDF operations using the initial point 'initial_p'
    float d5_box_boundary = box_hlsl(initial_p, float3(4.0, 4.0, 4.0));
    
    float fold_dist2_map = 8.0;
    float3 p_sphere_like = initial_p;
    p_sphere_like.z = abs(p_sphere_like.z) - 13.0;
    p_sphere_like.x = (frac(p_sphere_like.x / fold_dist2_map - 0.5) - 0.5) * fold_dist2_map;
    float d6_sphere_like = length(p_sphere_like.xz) - 1.0;

    // Accumulate 'at2_acc' and 'at3_acc'
    at2_acc += 0.2 / (0.15 + abs(d5_box_boundary));
    at3_acc += 0.2 / (0.5 + abs(d6_sphere_like));
    
    return d; // Return the final distance estimate for this point
}

// Camera transformation function
void cam_hlsl(inout float3 p, float effect_time) {
    float t_cam_internal = effect_time * 0.1; // Corresponds to 't' inside GLSL cam
    p.yz = mul(p.yz, rot_hlsl(t_cam_internal));
    p.zx = mul(p.zx, rot_hlsl(t_cam_internal * 1.2));
}

// Random function (simple hash)
float rnd_hlsl(float2 uv_rand) { // Changed param name to avoid conflict
    return frac(dot(sin(uv_rand * 752.322 + uv_rand.yx * 653.842), float2(254.652, 254.652)));
}

//------------------------------------------------------------------------------------------------
// Pixel Shader
//------------------------------------------------------------------------------------------------
float4 MainPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    // Calculate local_time from ReShade Timer (ms to s)
    float local_time = (Timer / 1000.0) * 1.0 + 137.0;

    // Setup UV coordinates: GLSL version centers and aspect corrects.
    // texcoord is already 0-1.
    float2 uv = texcoord - 0.5; // Center UVs
    uv.x *= ReShade::ScreenSize.x / ReShade::ScreenSize.y; // Aspect correction

    // Initialize accumulators for this pixel
    float at_accumulator = 0.0;
    float at2_accumulator = 0.0;
    float at3_accumulator = 0.0;

    // Factor for raymarching step modification
    // Using texcoord directly for rnd_hlsl as it's often used for screen-space patterns.
    float factor = 0.9 + 0.1 * rnd_hlsl(texcoord); 

    // Ray setup
    float3 ray_origin = float3(0.0, 0.0, -15.0);
    float3 ray_direction = normalize(float3(-uv, 1.0)); // Note: -uv.x for typical Shadertoy style if y is not flipped

    // Apply camera transformations
    cam_hlsl(ray_origin, local_time);
    cam_hlsl(ray_direction, local_time);

    float3 current_ray_pos = ray_origin;
    int iteration_count = 0; // For the commented-out original color calculation

    [loop] // Crucial for ReShade raymarching loops
    for (int i = 0; i < 80; ++i) {
        iteration_count = i; // Store last iteration count
        float dist_to_surface = map_hlsl(current_ray_pos, local_time, at_accumulator, at2_accumulator, at3_accumulator);
        
        // Original GLSL step logic:
        // float d_abs_map = abs(dist_to_surface);
        // float d_step = abs(max(d_abs_map, -(length(current_ray_pos - ray_origin) - 6.0)));
        // d_step *= factor;
        // if(d_step < 0.001) { d_step = 0.1; }

        // Simplified and safer raymarching step:
        // Use a fraction of the signed distance, or a minimum step if very close.
        // The original shader's step logic is complex and might be for specific volumetric effects.
        // Let's try to adhere to the original's unusual stepping for now.
        float d_abs_map = abs(dist_to_surface);
        float d_step      = abs(max(d_abs_map, -(length(current_ray_pos - ray_origin) - 6.0)));
        d_step           *= factor;

        if (d_step < 0.001) {
            d_step = 0.01; // March a small fixed step if very close, original had 0.1
                           // This allows accumulators to build up near surfaces.
        }
        
        current_ray_pos += ray_direction * d_step;

        // Far plane escape condition
        if (length(current_ray_pos - ray_origin) > 100.0) { // Increased far plane for safety
            break;
        }
        // Break if very close to surface (more typical for surface rendering)
        // The original shader doesn't break on hit, but continues accumulating.
        // if (abs(dist_to_surface) < 0.001) break; 
    }

    // Color calculation based on accumulators
    float3 final_color = float3(0.0, 0.0, 0.0);
    // final_color += pow(1.0 - (float)iteration_count / 101.0, 8.0); // Original commented out

    float3 sky_color = lerp(float3(1.0, 0.5, 0.3), float3(0.2, 1.5, 0.7), pow(abs(ray_direction.z), 8.0));
    sky_color = lerp(sky_color, float3(0.4, 0.5, 1.7), pow(abs(ray_direction.y), 8.0));

    // final_color += at_accumulator * 0.002 * sky_color; // Original commented out
    final_color += pow(at2_accumulator * 0.008, 1.0) * sky_color;
    final_color += pow(at3_accumulator * 0.072, 2.0) * sky_color * float3(0.7, 0.3, 1.0) * 2.0;

    final_color *= (1.2 - length(uv)); // Vignette

    // Post-processing / Tonemapping
    final_color = 1.0 - exp(-final_color * 15.0);
    final_color = pow(final_color, float3(1.2, 1.2, 1.2)); // Gamma-like correction
    final_color *= 1.2; // Brightness adjustment
    // final_color += 0.2 * sky_color; // Original commented out

    return float4(final_color, 1.0);
}

//------------------------------------------------------------------------------------------------
// Technique Definition
//------------------------------------------------------------------------------------------------
technique RaymarchGLSLDemo < ui_label = "Raymarch GLSL Demo"; >
{
    pass
    {
        VertexShader = PostProcessVS; // Standard ReShade fullscreen vertex shader
        PixelShader = MainPS;       // Our raymarching pixel shader
    }
}
