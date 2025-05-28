/**
 * AS_BGX_RaymarchedChain.1.fx - Raymarched Animated Chain
 * Author: Leon Aquitaine
 * License: CC BY 4.0
 * Original Shader: "Corrente" by Elsio (https://www.shadertoy.com/view/ctSfRV)
 *
 * DESCRIPTION:
 * This shader renders a raymarched scene featuring an animated, endlessly
 * twisting chain composed of interconnected torus shapes. The chain follows a
 * procedurally defined path, and its segments rotate and evolve over time,
 * creating a mesmerizing, complex visual.
 *
 * FEATURES:
 * - Raymarched chain of torus shapes.
 * - Procedural path animation.
 * - Customizable animation speed and overall time multiplier.
 * - Adjustable parameters for path shape, torus geometry, and chain appearance.
 * - Dynamic coloring based on raymarching depth and iteration.
 * - Camera orientation controlled by UI rotation inputs.
 * - Standard AS-StageFX controls for blending.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Screen UVs are set up for raymarching, establishing a camera ray.
 * 2. Camera ray direction is modified by UI rotation controls.
 * 3. The `map` function defines the signed distance function (SDF) for the scene:
 * - It adjusts the sample point based on a procedural `path` function that varies with depth (z) and time.
 * - It iteratively applies rotations and scaling to the sample point.
 * - In each iteration, it calls the `chain` SDF, which models two perpendicular tori.
 * - The minimum distance from these operations determines the scene SDF, and a base color is assigned.
 * 4. The `chain` function calculates the SDF for two interlinked tori at 90-degree angles.
 * 5. The `torus` function calculates the SDF for a single torus.
 * 6. The main pixel shader performs raymarching using the `map` function.
 * 7. If a surface is hit, normals are calculated by sampling the SDF at nearby points.
 * 8. Lighting and final coloring are applied based on normals, view direction, and the base color from the `map` function.
 * 9. If no surface is hit, a default background color is used.
 */

// ============================================================================
// TECHNIQUE GUARD
// ============================================================================
#ifndef __AS_BGX_RaymarchedChain_1_fx
#define __AS_BGX_RaymarchedChain_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // Contains AS_PI, AS_HALF_PI, AS_getTime, AS_applyBlend, AS_BLEND_OPAQUE, etc.
// AS_Palette.1.fxh is not strictly needed as custom color logic is primary here.

// ============================================================================
// TUNABLE CONSTANTS & UI DEFINITIONS
// ============================================================================

// Animation
static const float ANIMATION_SPEED_MIN = 0.0f; static const float ANIMATION_SPEED_MAX = 5.0f; static const float ANIMATION_SPEED_DEFAULT = 1.0f;
static const float ANIMATION_KEYFRAME_MIN = 0.0f; static const float ANIMATION_KEYFRAME_MAX = 100.0f; static const float ANIMATION_KEYFRAME_DEFAULT = 0.0f;
static const float TIME_MULTIPLIER_MIN = 0.1f; static const float TIME_MULTIPLIER_MAX = 5.0f; static const float TIME_MULTIPLIER_DEFAULT = 2.0f;
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")
uniform float TimeMultiplier < ui_type = "slider"; ui_label = "Global Time Multiplier"; ui_min = TIME_MULTIPLIER_MIN; ui_max = TIME_MULTIPLIER_MAX; ui_category = "Animation"; > = TIME_MULTIPLIER_DEFAULT;

// Path Parameters
static const float PATH_SCALE_MIN = 0.1f; static const float PATH_SCALE_MAX = 3.0f; static const float PATH_SCALE_DEFAULT = 1.3f;
static const float PATH_FREQ1_MIN = 0.1f; static const float PATH_FREQ1_MAX = 2.0f; static const float PATH_FREQ1_DEFAULT = 0.3f;
static const float PATH_FREQ2_MIN = 0.1f; static const float PATH_FREQ2_MAX = 2.0f; static const float PATH_FREQ2_DEFAULT = 0.5f;
uniform float PathScale < ui_type = "slider"; ui_label = "Path Scale"; ui_min = PATH_SCALE_MIN; ui_max = PATH_SCALE_MAX; ui_category = "Path"; > = PATH_SCALE_DEFAULT;
uniform float PathFreq1 < ui_type = "slider"; ui_label = "Path Frequency 1 (Sin)"; ui_min = PATH_FREQ1_MIN; ui_max = PATH_FREQ1_MAX; ui_category = "Path"; > = PATH_FREQ1_DEFAULT;
uniform float PathFreq2 < ui_type = "slider"; ui_label = "Path Frequency 2 (Cos)"; ui_min = PATH_FREQ2_MIN; ui_max = PATH_FREQ2_MAX; ui_category = "Path"; > = PATH_FREQ2_DEFAULT;

// Torus Geometry
static const float TORUS_MAIN_RADIUS_MIN = 0.05f; static const float TORUS_MAIN_RADIUS_MAX = 1.0f; static const float TORUS_MAIN_RADIUS_DEFAULT = 0.28f;
static const float TORUS_TUBE_RADIUS_MIN = 0.01f; static const float TORUS_TUBE_RADIUS_MAX = 0.5f; static const float TORUS_TUBE_RADIUS_DEFAULT = 0.07f;
uniform float TorusMainRadius < ui_type = "slider"; ui_label = "Torus Main Radius"; ui_min = TORUS_MAIN_RADIUS_MIN; ui_max = TORUS_MAIN_RADIUS_MAX; ui_category = "Geometry"; > = TORUS_MAIN_RADIUS_DEFAULT;
uniform float TorusTubeRadius < ui_type = "slider"; ui_label = "Torus Tube Radius"; ui_min = TORUS_TUBE_RADIUS_MIN; ui_max = TORUS_TUBE_RADIUS_MAX; ui_category = "Geometry"; > = TORUS_TUBE_RADIUS_DEFAULT;

// Chain Parameters
static const float CHAIN_Z_SCALE_MIN = 0.5f; static const float CHAIN_Z_SCALE_MAX = 3.0f; static const float CHAIN_Z_SCALE_DEFAULT = 1.5f;
static const float CHAIN_Z_OFFSET_MULT_MIN = 0.5f; static const float CHAIN_Z_OFFSET_MULT_MAX = 5.0f; static const float CHAIN_Z_OFFSET_MULT_DEFAULT = 2.2f;
uniform float ChainZScale < ui_type = "slider"; ui_label = "Chain Z Scale"; ui_min = CHAIN_Z_SCALE_MIN; ui_max = CHAIN_Z_SCALE_MAX; ui_category = "Geometry"; > = CHAIN_Z_SCALE_DEFAULT;
uniform float ChainZOffsetMultiplier < ui_type = "slider"; ui_label = "Chain Z Offset Multiplier (Time)"; ui_min = CHAIN_Z_OFFSET_MULT_MIN; ui_max = CHAIN_Z_OFFSET_MULT_MAX; ui_category = "Geometry"; > = CHAIN_Z_OFFSET_MULT_DEFAULT;

// Map Iteration Parameters
static const float MAP_ITER_SCALE_MIN = 1.1f; static const float MAP_ITER_SCALE_MAX = 3.0f; static const float MAP_ITER_SCALE_DEFAULT = 1.5f;
static const float MAP_ITER_SHRINK_MIN = 0.5f; static const float MAP_ITER_SHRINK_MAX = 2.0f; static const float MAP_ITER_SHRINK_DEFAULT = 1.0f;
static const int MAP_ITERATIONS_MIN = 1; static const int MAP_ITERATIONS_MAX = 5; static const int MAP_ITERATIONS_DEFAULT = 2;
uniform float MapIterationScale < ui_type = "slider"; ui_label = "Map Iteration Scale (ss)"; ui_min = MAP_ITER_SCALE_MIN; ui_max = MAP_ITER_SCALE_MAX; ui_category = "Raymarching"; > = MAP_ITER_SCALE_DEFAULT;
uniform float MapIterationShrink < ui_type = "slider"; ui_label = "Map Iteration Shrink (s)"; ui_min = MAP_ITER_SHRINK_MIN; ui_max = MAP_ITER_SHRINK_MAX; ui_category = "Raymarching"; > = MAP_ITER_SHRINK_DEFAULT;
uniform int MapIterations < ui_type = "slider"; ui_label = "Map Iterations"; ui_min = MAP_ITERATIONS_MIN; ui_max = MAP_ITERATIONS_MAX; ui_step = 1; ui_category = "Raymarching"; > = MAP_ITERATIONS_DEFAULT;

// Raymarching
static const int RAYMARCH_STEPS_MIN = 20; static const int RAYMARCH_STEPS_MAX = 300; static const int RAYMARCH_STEPS_DEFAULT = 200;
static const float RAYMARCH_FAR_MIN = 10.0f; static const float RAYMARCH_FAR_MAX = 100.0f; static const float RAYMARCH_FAR_DEFAULT = 60.0f;
static const float RAYMARCH_STEP_SCALE_MIN = 0.1f; static const float RAYMARCH_STEP_SCALE_MAX = 1.0f; static const float RAYMARCH_STEP_SCALE_DEFAULT = 0.5f;
static const float RAYMARCH_HIT_THRESHOLD_MIN = 0.0001f; static const float RAYMARCH_HIT_THRESHOLD_MAX = 0.01f; static const float RAYMARCH_HIT_THRESHOLD_DEFAULT = 0.001f;
uniform int RaymarchSteps < ui_type = "slider"; ui_label = "Max Raymarch Steps"; ui_min = RAYMARCH_STEPS_MIN; ui_max = RAYMARCH_STEPS_MAX; ui_category = "Raymarching"; > = RAYMARCH_STEPS_DEFAULT;
uniform float RaymarchFarPlane < ui_type = "slider"; ui_label = "Raymarch Far Plane"; ui_min = RAYMARCH_FAR_MIN; ui_max = RAYMARCH_FAR_MAX; ui_category = "Raymarching"; > = RAYMARCH_FAR_DEFAULT;
uniform float RaymarchStepScale < ui_type = "slider"; ui_label = "Raymarch Step Scale"; ui_min = RAYMARCH_STEP_SCALE_MIN; ui_max = RAYMARCH_STEP_SCALE_MAX; ui_category = "Raymarching"; > = RAYMARCH_STEP_SCALE_DEFAULT;
uniform float RaymarchHitThreshold < ui_type = "slider"; ui_label = "Raymarch Hit Threshold"; ui_min = RAYMARCH_HIT_THRESHOLD_MIN; ui_max = RAYMARCH_HIT_THRESHOLD_MAX; ui_category = "Raymarching"; > = RAYMARCH_HIT_THRESHOLD_DEFAULT;

// Coloring
static const float COLOR_BASE_R_MIN = 0.0f; static const float COLOR_BASE_R_MAX = 1.0f; static const float COLOR_BASE_R_DEFAULT = 1.0f;
static const float COLOR_BASE_G_MIN = 0.0f; static const float COLOR_BASE_G_MAX = 1.0f; static const float COLOR_BASE_G_DEFAULT = 0.75f;
static const float COLOR_BASE_B_MIN = 0.0f; static const float COLOR_BASE_B_MAX = 1.0f; static const float COLOR_BASE_B_DEFAULT = 0.0f;
static const float COLOR_ITER_MULT_MIN = 0.0f; static const float COLOR_ITER_MULT_MAX = 0.5f; static const float COLOR_ITER_MULT_DEFAULT = 0.125f;
static const float COLOR_ITER_ADD_MIN = 0.0f; static const float COLOR_ITER_ADD_MAX = 0.5f; static const float COLOR_ITER_ADD_DEFAULT = 0.2f;
static const float LIGHT_DOT_PRODUCT_MULT_MIN = 0.0f; static const float LIGHT_DOT_PRODUCT_MULT_MAX = 1.0f; static const float LIGHT_DOT_PRODUCT_MULT_DEFAULT = 0.1f;
static const float LIGHT_AMBIENT_MIN = 0.0f; static const float LIGHT_AMBIENT_MAX = 1.0f; static const float LIGHT_AMBIENT_DEFAULT = 0.45f;
static const float FINAL_COLOR_POW_MIN = 0.1f; static const float FINAL_COLOR_POW_MAX = 3.0f; static const float FINAL_COLOR_POW_DEFAULT = 0.7f;
static const float FINAL_COLOR_MULT_MIN = 0.1f; static const float FINAL_COLOR_MULT_MAX = 5.0f; static const float FINAL_COLOR_MULT_DEFAULT = 1.6f;
static const float FINAL_COLOR_SCALE_MIN = 0.1f; static const float FINAL_COLOR_SCALE_MAX = 10.0f; static const float FINAL_COLOR_SCALE_DEFAULT = 3.5f;
static const float FINAL_COLOR_SUB_MIN = -1.0f; static const float FINAL_COLOR_SUB_MAX = 1.0f; static const float FINAL_COLOR_SUB_DEFAULT = -0.6f;

uniform float3 BaseColorFactor < ui_type = "color"; ui_label = "Base Color Factor"; ui_category = "Color"; > = float3(COLOR_BASE_R_DEFAULT, COLOR_BASE_G_DEFAULT, COLOR_BASE_B_DEFAULT);
uniform float ColorIterMultiplier < ui_type = "slider"; ui_label = "Color Iteration Multiplier"; ui_min = COLOR_ITER_MULT_MIN; ui_max = COLOR_ITER_MULT_MAX; ui_category = "Color"; > = COLOR_ITER_MULT_DEFAULT;
uniform float ColorIterAdd < ui_type = "slider"; ui_label = "Color Iteration Add"; ui_min = COLOR_ITER_ADD_MIN; ui_max = COLOR_ITER_ADD_MAX; ui_category = "Color"; > = COLOR_ITER_ADD_DEFAULT;
uniform float LightDotProductMultiplier < ui_type = "slider"; ui_label = "Lighting Dot Product Multiplier"; ui_min = LIGHT_DOT_PRODUCT_MULT_MIN; ui_max = LIGHT_DOT_PRODUCT_MULT_MAX; ui_category = "Color"; > = LIGHT_DOT_PRODUCT_MULT_DEFAULT;
uniform float LightAmbient < ui_type = "slider"; ui_label = "Lighting Ambient"; ui_min = LIGHT_AMBIENT_MIN; ui_max = LIGHT_AMBIENT_MAX; ui_category = "Color"; > = LIGHT_AMBIENT_DEFAULT;
uniform float FinalColorPower < ui_type = "slider"; ui_label = "Final Color Power"; ui_min = FINAL_COLOR_POW_MIN; ui_max = FINAL_COLOR_POW_MAX; ui_category = "Color"; > = FINAL_COLOR_POW_DEFAULT;
uniform float FinalColorMultiplier < ui_type = "slider"; ui_label = "Final Color Multiplier"; ui_min = FINAL_COLOR_MULT_MIN; ui_max = FINAL_COLOR_MULT_MAX; ui_category = "Color"; > = FINAL_COLOR_MULT_DEFAULT;
uniform float FinalColorScale < ui_type = "slider"; ui_label = "Final Color Scale"; ui_min = FINAL_COLOR_SCALE_MIN; ui_max = FINAL_COLOR_SCALE_MAX; ui_category = "Color"; > = FINAL_COLOR_SCALE_DEFAULT;
uniform float FinalColorSubtract < ui_type = "slider"; ui_label = "Final Color Subtract"; ui_min = FINAL_COLOR_SUB_MIN; ui_max = FINAL_COLOR_SUB_MAX; ui_category = "Color"; > = FINAL_COLOR_SUB_DEFAULT;
uniform float4 BackgroundColor < ui_type = "color"; ui_label = "Background Color"; ui_category = "Color"; > = float4(0.5, 0.5, 0.5, 1.0);

// Camera Controls
// Position and rotation controls affect the camera/view
uniform float3 CameraPosition < ui_type = "drag"; ui_label = "Camera Position (XYZ)"; ui_tooltip = "Position of the camera in 3D space"; ui_min = -5.0; ui_max = 5.0; ui_step = 0.01; ui_category = "Camera"; > = float3(0.0, 0.0, -1.0);
uniform float CameraPitch < ui_type = "slider"; ui_label = "Camera Pitch"; ui_tooltip = "Camera tilt up/down"; ui_min = -90.0; ui_max = 90.0; ui_step = 0.1; ui_category = "Camera"; > = 0.0;
uniform float CameraYaw < ui_type = "slider"; ui_label = "Camera Yaw"; ui_tooltip = "Camera rotation left/right"; ui_min = -180.0; ui_max = 180.0; ui_step = 0.1; ui_category = "Camera"; > = 0.0;

// Stage Controls
AS_POS_UI(EffectCenter)       // Position in central square coordinate system
AS_SCALE_UI(EffectScale)      // Scale factor (0.1 to 5.0)
AS_STAGEDEPTH_UI(EffectDepth) // Depth masking (0.0 to 1.0)
AS_ROTATION_UI(EffectRotationSnap, EffectRotationFine) // Effect rotation controls

// Final Mix
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_OPAQUE) // Use named constant instead of numeric value
AS_BLENDAMOUNT_UI(BlendAmount)


// ============================================================================
// GLOBAL VARIABLES & HELPER FUNCTIONS
// ============================================================================

// Global variable to store color from map function
static float3 ps_cor;
static float ps_current_time; // To store AS_getTime() * TimeMultiplier result

// Rotation matrix function
float2x2 fn_rot(float a) {
    float s = sin(a), c = cos(a);
    return float2x2(c, s, -s, c);
}

// Path function
float2 fn_path(float z) {
    return PathScale * float2(
        sin(z * PathFreq1),
        cos(z * PathFreq2)
    );
}

// Torus SDF
float fn_torus(float3 p) {
    return length(float2(length(p.xz) - TorusMainRadius, p.y)) - TorusTubeRadius;
}

// Chain SDF
float fn_chain(float3 p) {
    p.z = ChainZScale * p.z - ChainZOffsetMultiplier * ps_current_time;

    float3 q = p;
    q.xy = mul(q.xy, fn_rot(AS_HALF_PI)); // Rotate 90 degrees
    q.z = frac(p.z + 0.5) - 0.5;
    p.z = frac(p.z) - 0.5;

    return min(fn_torus(p), fn_torus(q));
}

// Main scene SDF (map function)
float fn_map(float3 p) {
    p.z += ps_current_time;
    p.xy -= fn_path(p.z) - fn_path(ps_current_time);

    float ss = MapIterationScale;
    float s_iter = MapIterationShrink; // Renamed 's' to 's_iter' to avoid conflict with raymarch step 's'

    float2x2 rotate_matrix = ss * fn_rot(0.5 * p.z); 

    float i = 0.0, d = 100.0; 
    ps_cor = BaseColorFactor; 

    for (int j = 0; j < MapIterations; ++j) { 
        i++; 
        p.xy = abs(mul(p.xy, rotate_matrix)) - s_iter; 
        s_iter /= ss; 

        float c = fn_chain(p) * s_iter; 
        if (c < d) {
            d = c;
            ps_cor = BaseColorFactor * (ColorIterMultiplier * i + ColorIterAdd);
        }
    }
    return d;
}

// Get normal by sampling SDF
float3 get_normal(float3 p) {
    const float2 e = float2(0.005f, 0.0f); 
    float map_p = fn_map(p); // Cache fn_map(p)
    return normalize(
        float3(
            map_p - fn_map(p - e.xyy),
            map_p - fn_map(p - e.yxy),
            map_p - fn_map(p - e.yyx)
        )
    );
}


// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_RaymarchedChain(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float4 original_color = tex2D(ReShade::BackBuffer, texcoord);
    ps_current_time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe) * TimeMultiplier;
    
    // Early depth check - skip effect if pixel is in front of EffectDepth
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    if (sceneDepth < EffectDepth - AS_DEPTH_EPSILON) {
        return original_color;
    }    // 1. Convert to normalized central square [-1,1] with aspect ratio correction
    float aspectRatio = ReShade::AspectRatio;
    float2 uv_norm;
    if (aspectRatio >= 1.0) {
        uv_norm.x = (texcoord.x - 0.5) * 2.0 * aspectRatio;
        uv_norm.y = (texcoord.y - 0.5) * 2.0;
    } else {
        uv_norm.x = (texcoord.x - 0.5) * 2.0;
        uv_norm.y = (texcoord.y - 0.5) * 2.0 / aspectRatio;
    }
    
    // 2. Apply effect rotation, position, and scale in the correct order
    // First apply effect rotation (around screen center)
    float effect_rotation = AS_getRotationRadians(EffectRotationSnap, EffectRotationFine);
    uv_norm = mul(uv_norm, fn_rot(effect_rotation));
    
    // Next apply effect position offset
    uv_norm -= EffectCenter;
    
    // Finally apply effect scale
    uv_norm /= EffectScale;
    
    // Camera setup
    float3 ro = CameraPosition; // Camera position from UI
    float3 rd = normalize(float3(uv_norm.x, uv_norm.y, 1.0)); // Ray direction
    
    // Apply camera rotation to ray direction (in radians)
    float camera_pitch_rad = CameraPitch * (AS_PI / 180.0);
    float camera_yaw_rad = CameraYaw * (AS_PI / 180.0);
    
    rd.yz = mul(rd.yz, fn_rot(camera_pitch_rad)); 
    rd.xz = mul(rd.xz, fn_rot(camera_yaw_rad));


    // Raymarching
    float s_step = 0.0; // Renamed 's' to 's_step'
    float d_total = 0.0; // Renamed 'd' to 'd_total'
    float i_ray = 0.0;
    for (i_ray = 0.0; i_ray < RaymarchSteps; i_ray++) {
        s_step = fn_map(ro + d_total * rd);
        d_total += s_step * RaymarchStepScale;
        if (d_total > RaymarchFarPlane || s_step < RaymarchHitThreshold) break;
    }    float4 col_final;
    if (d_total < RaymarchFarPlane) {
        float3 p_hit = ro + rd * d_total;
        float3 n = get_normal(p_hit);

        col_final.rgb = ps_cor; 
        col_final.rgb *= -dot(reflect(n, rd), n) * LightDotProductMultiplier + LightAmbient;
        col_final.rgb = pow(abs(col_final.rgb * FinalColorMultiplier), FinalColorPower) * FinalColorScale + FinalColorSubtract; // Use abs before pow for safety
        col_final.a = 1.0; // Surface hit is fully opaque
    } else {
        col_final = BackgroundColor; // Use the full RGBA from background color
    }

    col_final = saturate(col_final);

    return AS_applyBlend(col_final, original_color, BlendMode, BlendAmount);
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_BGX_RaymarchedChain <
    ui_label = "[AS] BGX: Raymarched Chain";
    ui_tooltip = "Renders a raymarched scene of an animated, twisting chain of tori.\n"
                 "Original GLSL shader 'Corrente' by Elsio on Shadertoy.";
> {
    pass MainPass {
        VertexShader = PostProcessVS;
        PixelShader = PS_RaymarchedChain;
    }
}

#endif // __AS_BGX_RaymarchedChain_1_fx