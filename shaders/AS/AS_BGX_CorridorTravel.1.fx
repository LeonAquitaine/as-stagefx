/**
 * AS_BGX_CorridorTravel.1.fx - Dynamic Corridor Travel Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *  * CREDITS:
 * Based on "Corridor Travel" by NuSan
 * Shadertoy: https://www.shadertoy.com/view/3sXyRN
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Simulates an artistic flight through an abstract, glowing, patterned tunnel.
 * Features multiple samples per pixel for pseudo-DOF and motion blur,
 * and simulates light bounces with artistic reflection logic.
 *
 * FEATURES:
 * - Highly tunable graphics and animation parameters
 * - Multiple ray samples for high-quality depth of field and motion blur
 * - Simulated light bounces for realistic-looking reflections
 * - Animated grid, cell, and floor patterns
 * - Complex camera movement with adjustable rotation
 * - Audio reactivity for various parameters
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Generates primary rays that vary based on DOF and motion blur parameters
 * 2. Ray marches through a procedurally defined tunnel with reflections
 * 3. Calculates surface patterns based on uv-coordinates and time
 * 4. Combines multiple samples for anti-aliasing and motion effects
 * 5. Applies final adjustments for brightness and gamma
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_CorridorTravel_1_fx
#define __AS_BGX_CorridorTravel_1_fx

#include "ReShade.fxh"     // For ReShade::ScreenSize, ReShade::AspectRatio, PostProcessVS
#include "AS_Utils.1.fxh"  // For AS_getTime(), AS_mod() (Assumed available)

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
static const float PI = 3.1415926535f;
static const float DEFAULT_TUNNEL_SIZE_XY = 0.9f;
static const float DEFAULT_TUNNEL_LENGTH = 1000.0f;
static const float DEFAULT_FOV = 2.0f;

// ============================================================================
// QUALITY & PERFORMANCE
// ============================================================================

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nBased on 'Corridor Travel' by NuSan\nLink: https://www.shadertoy.com/view/3sXyRN\nLicence: CC Share-Alike Non-Commercial\n\n";>;

uniform int PR_Steps < ui_type = "drag"; ui_min = 1; ui_max = 100; ui_step = 1; ui_label = "Sample Count"; ui_tooltip = "Number of samples per pixel. Higher = better quality but slower."; ui_category = "Quality & Performance"; > = 30;
uniform int PR_Bounces < ui_type = "drag"; ui_min = 0; ui_max = 5; ui_step = 1; ui_label = "Light Bounces"; ui_tooltip = "Number of light reflections per sample. More bounces = more detailed reflections."; ui_category = "Quality & Performance"; > = 3;

// ============================================================================
// ANIMATION CONTROLS
// ============================================================================
// --- Time Stepping Parameters ---
uniform float PR_CamTime_BaseSpeed < ui_type = "drag"; ui_min = 0.1; ui_max = 5.0; ui_step = 0.1; ui_label = "Forward Speed"; ui_tooltip = "Base movement speed through the corridor."; ui_category = "Animation"; > = 1.9f;
uniform float PR_CamTime_TickPeriod < ui_type = "drag"; ui_min = 0.1; ui_max = 5.0; ui_step = 0.1; ui_label = "Tick Period"; ui_tooltip = "Period for the 'stepping' motion effect."; ui_category = "Animation"; > = 1.9f;
uniform float PR_CamTime_TickStrength < ui_type = "drag"; ui_min = 0.0; ui_max = 3.0; ui_step = 0.1; ui_label = "Tick Strength"; ui_tooltip = "Intensity of the 'stepping' motion effect."; ui_category = "Animation"; > = 1.0f;

// --- Camera Animation ---
uniform float PR_CamAnim_TimeScale < ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_label = "Camera Speed"; ui_tooltip = "Speed of the camera's procedural animation path."; ui_category = "Animation"; > = 0.3f;
uniform float PR_CamAnim_XZ_RotAmount < ui_type = "drag"; ui_min = 0.0; ui_max = 3.14159; ui_step = 0.01; ui_label = "Horizontal Rotation"; ui_tooltip = "Amplitude of camera rotation on the horizontal plane (yaw)."; ui_category = "Animation"; > = 0.3f;
uniform float PR_CamAnim_XY_TimeFactor < ui_type = "drag"; ui_min = 0.1; ui_max = 2.0; ui_step = 0.01; ui_label = "Roll Rotation Speed"; ui_tooltip = "Speed of camera roll rotation."; ui_category = "Animation"; > = 0.7f;
uniform float PR_CamAnim_XY_RotAmount < ui_type = "drag"; ui_min = 0.0; ui_max = 3.14159; ui_step = 0.01; ui_label = "Roll Rotation Amount"; ui_tooltip = "Amplitude of camera roll rotation."; ui_category = "Animation"; > = 0.4f;

// ============================================================================
// EMISSIVE PATTERN
// ============================================================================
uniform float3 PR_Emission_BaseTint < ui_type = "color"; ui_label = "Base Color"; ui_tooltip = "Base color for the main emissive pattern."; ui_category = "Emissive Pattern"; > = float3(1.0f, 0.5f, 0.2f); 

uniform float PR_Emission_Wave1_Freq < ui_type = "drag"; ui_min = 0.001; ui_max = 0.2; ui_step = 0.001; ui_label = "Wave 1 Frequency"; ui_tooltip = "Frequency of the first wave pattern."; ui_category = "Emissive Pattern"; > = 0.025f;
uniform float PR_Emission_Wave1_Amp < ui_type = "drag"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_label = "Wave 1 Amplitude"; ui_tooltip = "Strength of the first wave pattern."; ui_category = "Emissive Pattern"; > = 0.9f;
uniform float PR_Emission_Wave2_Freq < ui_type = "drag"; ui_min = 0.001; ui_max = 0.2; ui_step = 0.001; ui_label = "Wave 2 Frequency"; ui_tooltip = "Frequency of the second wave pattern."; ui_category = "Emissive Pattern"; > = 0.05f;
uniform float PR_Emission_Wave2_Amp < ui_type = "drag"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_label = "Wave 2 Amplitude"; ui_tooltip = "Strength of the second wave pattern."; ui_category = "Emissive Pattern"; > = 0.5f;
uniform float PR_Emission_OverallBrightness < ui_type = "drag"; ui_min = 0.0; ui_max = 10.0; ui_step = 0.1; ui_label = "Brightness"; ui_tooltip = "Overall brightness multiplier for emissive patterns."; ui_category = "Emissive Pattern"; > = 2.0f;

// ============================================================================
// PATTERN CONTROLS
// ============================================================================
uniform float PR_Surface_UV_Scale < ui_type = "drag"; ui_min = 0.5; ui_max = 10.0; ui_step = 0.1; ui_label = "Pattern Scale"; ui_tooltip = "Overall scaling for textures on tunnel walls."; ui_category = "Pattern Controls"; > = 3.0f;
uniform float PR_Surface_Anim_Z_Scroll < ui_type = "drag"; ui_min = -10.0; ui_max = 10.0; ui_step = 0.1; ui_label = "Depth Scroll Speed"; ui_tooltip = "Speed of pattern scrolling along tunnel depth."; ui_category = "Pattern Controls"; > = 3.0f;
uniform float PR_Surface_Anim_V_Scroll < ui_type = "drag"; ui_min = -10.0; ui_max = 10.0; ui_step = 0.1; ui_label = "Vertical Scroll Speed"; ui_tooltip = "Speed of pattern scrolling along the vertical axis."; ui_category = "Pattern Controls"; > = 3.0f;

// ============================================================================
// TUNNEL GEOMETRY
// ============================================================================
uniform float PR_TunnelSizeXY < ui_type = "drag"; ui_min = 0.1; ui_max = 5.0; ui_step = 0.05; ui_label = "Tunnel Width"; ui_tooltip = "Size of the tunnel on its X and Y axes."; ui_category = "Tunnel Geometry"; > = 0.9f;
uniform float PR_TunnelFarPlane < ui_type = "drag"; ui_min = 10.0; ui_max = 5000.0; ui_step = 10.0; ui_label = "Tunnel Length"; ui_tooltip = "How far the tunnel extends. Larger values make it seem longer."; ui_category = "Tunnel Geometry"; > = 1000.0f;

// ============================================================================
// REFLECTION CONTROLS
// ============================================================================
uniform float PR_RoughnessBase < ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_label = "Surface Roughness"; ui_tooltip = "Base roughness for reflections. 0.0 = perfect mirror, 1.0 = diffuse."; ui_category = "Reflection Controls"; > = 0.85f;
uniform float PR_RoughnessVariation < ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_label = "Roughness Variation"; ui_tooltip = "How much the roughness varies across surfaces."; ui_category = "Reflection Controls"; > = 0.2f;
uniform float PR_ReflectionAngleBias < ui_type = "drag"; ui_min = 0.1; ui_max = 10.0; ui_step = 0.1; ui_label = "Fresnel Effect"; ui_tooltip = "How reflections change with viewing angle. Higher values emphasize edge reflections."; ui_category = "Reflection Controls"; > = 3.0f;
uniform float PR_ReflectionPathDecay < ui_type = "drag"; ui_min = 0.1; ui_max = 1.0; ui_step = 0.01; ui_label = "Reflection Fade"; ui_tooltip = "How quickly reflections fade with each bounce. Lower values = faster fade."; ui_category = "Reflection Controls"; > = 0.9f;

// ============================================================================
// CELL PATTERN
// ============================================================================
uniform float PR_CellPattern_CurvePeriod < ui_type = "drag"; ui_min = 0.05; ui_max = 1.0; ui_step = 0.01; ui_label = "Animation Period"; ui_tooltip = "Time period for cell pattern animation."; ui_category = "Cell Pattern"; ui_category_closed = true; > = 0.3f;
uniform float PR_CellPattern_Threshold < ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_label = "Visibility"; ui_tooltip = "Controls the visibility threshold for the cellular pattern."; ui_category = "Cell Pattern"; > = 0.5f;

// ============================================================================
// GRID PATTERN
// ============================================================================
uniform float PR_GridPattern_Z_Freq < ui_type = "drag"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_label = "Frequency"; ui_tooltip = "Frequency of the grid pattern along the tunnel."; ui_category = "Grid Pattern"; ui_category_closed = true; > = 0.4f;
uniform float PR_GridPattern_Threshold < ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_label = "Visibility"; ui_tooltip = "Controls the grid pattern visibility threshold."; ui_category = "Grid Pattern"; > = 0.5f;

// ============================================================================
// FLOOR EFFECT
// ============================================================================
uniform float3 PR_Floor_Color < ui_type = "color"; ui_label = "Color"; ui_category = "Floor Effect"; ui_category_closed = true; > = float3(0.7f, 0.5f, 1.2f);
uniform float PR_Floor_Y_Threshold < ui_type = "drag"; ui_min = -2.0; ui_max = 0.0; ui_step = 0.01; ui_label = "Height"; ui_tooltip = "Height at which the floor effect appears."; ui_category = "Floor Effect"; > = -0.9f;
uniform float PR_Floor_CurvePeriod < ui_type = "drag"; ui_min = 0.05; ui_max = 1.0; ui_step = 0.01; ui_label = "Animation Period"; ui_tooltip = "Time period for the floor effect animation."; ui_category = "Floor Effect"; > = 0.2f;
uniform float PR_Floor_CurveScale < ui_type = "drag"; ui_min = 0.0; ui_max = 5.0; ui_step = 0.1; ui_label = "Intensity"; ui_tooltip = "Intensity of the floor effect."; ui_category = "Floor Effect"; > = 2.0f; 
uniform float PR_Floor_CurveBias < ui_type = "drag"; ui_min = 0.0; ui_max = 5.0; ui_step = 0.1; ui_label = "Intensity Offset"; ui_tooltip = "Offset applied to the floor effect intensity."; ui_category = "Floor Effect"; > = 1.0f; 
uniform float PR_Floor_HashThreshold < ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_label = "Pattern Density"; ui_tooltip = "Controls the density of the floor effect pattern."; ui_category = "Floor Effect"; > = 0.2f;

// ============================================================================
// DEPTH OF FIELD
// ============================================================================
uniform float PR_FovZ < ui_type = "drag"; ui_min = 0.5; ui_max = 10.0; ui_step = 0.1; ui_label = "Field of View"; ui_tooltip = "Controls the FOV. Smaller values = wider view, larger = narrower/zoom."; ui_category = "Depth of Field"; > = 2.0f;
uniform float PR_DofStrength < ui_type = "drag"; ui_min = 0.0; ui_max = 0.1; ui_step = 0.001; ui_label = "Blur Amount"; ui_tooltip = "Controls the aperture size for depth of field effect."; ui_category = "Depth of Field"; > = 0.02f;
uniform float PR_DofDistFactor < ui_type = "drag"; ui_min = 0.01; ui_max = 1.0; ui_step = 0.01; ui_label = "Focus Distance"; ui_tooltip = "Smaller values bring focus closer to the camera."; ui_category = "Depth of Field"; > = 0.2f;
uniform float PR_MotionBlurTimeDelta < ui_type = "drag"; ui_min = 0.0; ui_max = 0.2; ui_step = 0.001; ui_label = "Motion Blur"; ui_tooltip = "Time jitter between samples for motion blur. Higher values increase blur length."; ui_category = "Depth of Field"; > = 0.05f;

// ============================================================================
// AUDIO REACTIVITY
// ============================================================================
AS_AUDIO_UI(CorridorTravel_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(CorridorTravel_AudioMultiplier, "Audio Intensity", 1.0, 2.0, "Audio Reactivity")

uniform int CorridorTravel_AudioTarget < ui_type = "combo"; ui_label = "Audio Target"; ui_tooltip = "Select which parameter will be modulated by audio"; ui_items = "None\0Global Speed\0Camera Animation\0Pattern Scale\0Emission Brightness\0"; ui_category = "Audio Reactivity"; > = 1;

AS_ANIMATION_SPEED_UI(PR_OverallTimeScale, "Animation")
AS_ANIMATION_KEYFRAME_UI(CorridorTravel_AnimationKeyframe, "Animation")

// ============================================================================
// STAGE CONTROLS
// ============================================================================
AS_STAGEDEPTH_UI(CorridorTravel_EffectDepth)
AS_ROTATION_UI(CorridorTravel_SnapRotation, CorridorTravel_FineRotation)
AS_POSITION_SCALE_UI(CorridorTravel_Position, CorridorTravel_Scale)

// ============================================================================
// BLEND CONTROLS
// ============================================================================
AS_BLENDMODE_UI(CorridorTravel_BlendMode)
AS_BLENDAMOUNT_UI(CorridorTravel_BlendAmount)

// ============================================================================
// FINAL ADJUSTMENTS
// ============================================================================
uniform float PR_FinalBrightness < ui_type = "drag"; ui_min = 0.1; ui_max = 5.0; ui_step = 0.05; ui_label = "Brightness"; ui_tooltip = "Final brightness adjustment."; ui_category = "Final Adjustments"; > = 2.0f;
uniform float PR_Gamma < ui_type = "drag"; ui_min = 1.0; ui_max = 3.0; ui_step = 0.01; ui_label = "Gamma"; ui_tooltip = "Gamma correction. Standard is 2.2."; ui_category = "Final Adjustments"; > = 2.2f;

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

float2x2 GetRotationMatrix(float angle) {
    float ca = cos(angle);
    float sa = sin(angle);
    return float2x2(ca, -sa, sa, ca); 
}

void ApplyCameraTransform(inout float3 p, float t_cam, float cam_anim_time_scale, 
                                                       float cam_anim_xz_rot_amount, 
                                                       float cam_anim_xy_time_factor, 
                                                       float cam_anim_xy_rot_amount) {
    t_cam *= cam_anim_time_scale; 
    p.xz = mul(p.xz, GetRotationMatrix(sin(t_cam) * cam_anim_xz_rot_amount)); 
    p.xy = mul(p.xy, GetRotationMatrix(sin(t_cam * cam_anim_xy_time_factor) * cam_anim_xy_rot_amount)); 
}

float Hash1D(float t) {
    return frac(sin(t * 788.874f));
}

float GetCurveValue(float t, float d_period, float curve_transition_power) {
    t /= d_period;
    float t_floor = floor(t);
    return lerp(Hash1D(t_floor), Hash1D(t_floor + 1.0f), pow(smoothstep(0.0f, 1.0f, frac(t)), curve_transition_power));
}

float GetTickedTime(float t, float d_period) {
    t /= d_period;
    float m = frac(t);
    m = smoothstep(0.0f, 1.0f, m);
    m = smoothstep(0.0f, 1.0f, m);
    return (floor(t) + m) * d_period;
}

float Hash2DTo1D(float2 uv) {
    return frac(dot(sin(uv * 425.215f + uv.yx * 714.388f), float2(522.877f, 522.877f)));
}

float2 Hash2DTo2D(float2 uv) {
    return frac(sin(uv * 425.215f + uv.yx * 714.388f) * 522.877f); 
}

float3 Hash2DTo3D(float2 id) {
    return frac(sin(id.xyy * float3(427.544f, 224.877f, 974.542f) + id.yxx * float3(947.544f, 547.847f, 652.454f)) * 342.774f);
}

float GetProcessedCamTime(float t_input, float base_speed, float tick_period, float tick_strength) { 
    return t_input * base_speed + GetTickedTime(t_input, tick_period) * tick_strength;
}

// Apply rotation around the origin to both ray origin and direction
// This ensures proper 3D rotation of the scene
void RotateSceneAroundCenter(inout float3 ray_origin, inout float3 ray_direction, float angle) {
    if (abs(angle) < 0.0001f) return; // Skip if no rotation
    
    float s = sin(angle);
    float c = cos(angle);
    
    // Rotate in the XZ plane (yaw)
    float x = ray_origin.x;
    float z = ray_origin.z;
    ray_origin.x = x * c - z * s;
    ray_origin.z = x * s + z * c;
    
    x = ray_direction.x;
    z = ray_direction.z;
    ray_direction.x = x * c - z * s;
    ray_direction.z = x * s + z * c;
}

// --- Main Pixel Shader ---
// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_CorridorTravel(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{    // Get background color first for potential blending
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    
    // Apply standard animation time with keyframe support
    float time = AS_getAnimationTime(PR_OverallTimeScale, CorridorTravel_AnimationKeyframe);
    time = AS_mod(time, 300.0f);
    
    // Apply audio reactivity based on selected target
    float audioFactor = 0.0;
    if (CorridorTravel_AudioTarget > 0) {
        audioFactor = AS_applyAudioReactivity(1.0, CorridorTravel_AudioSource, CorridorTravel_AudioMultiplier, true) - 1.0;
    }
    
    // Modify parameters based on audio target selection
    float timeScale = PR_OverallTimeScale;
    float camAnimSpeed = PR_CamAnim_TimeScale;
    float patternScale = PR_Surface_UV_Scale;
    float emissionBrightness = PR_Emission_OverallBrightness;
    
    if (CorridorTravel_AudioTarget == 1) { // Global Speed
        timeScale += timeScale * audioFactor;
    } else if (CorridorTravel_AudioTarget == 2) { // Camera Animation
        camAnimSpeed += camAnimSpeed * audioFactor;
    } else if (CorridorTravel_AudioTarget == 3) { // Pattern Scale
        patternScale += patternScale * audioFactor * 0.5;
    } else if (CorridorTravel_AudioTarget == 4) { // Emission Brightness
        emissionBrightness += emissionBrightness * audioFactor;
    }
      // Stage depth is handled by testing if we should render at all
    float depthSample = ReShade::GetLinearizedDepth(texcoord);
    if (depthSample < CorridorTravel_EffectDepth)
        return originalColor;
      
    // Get rotation value from UI controls - will be applied to 3D scene
    float rotation = AS_getRotationRadians(CorridorTravel_SnapRotation, CorridorTravel_FineRotation);
    
    // Apply position and scale only (without rotation) using standard AS function
    // Rotation will be handled separately in the 3D scene
    float2 uv = AS_transformCoord(texcoord, CorridorTravel_Position, CorridorTravel_Scale, 0.0);
    
    float3 total_color = float3(0.0f, 0.0f, 0.0f);
    
    float3 box_extents = float3(PR_TunnelSizeXY, PR_TunnelSizeXY, PR_TunnelFarPlane); 
    
    for(int j = 0; j < PR_Steps; ++j) {
        float j_float = (float)j;
          float time_jittered = GetProcessedCamTime(
            time + j_float * (PR_MotionBlurTimeDelta / max(1.f,(float)PR_Steps)),
            PR_CamTime_BaseSpeed, PR_CamTime_TickPeriod, PR_CamTime_TickStrength
        );
        
        // Create ray origin and ray direction for proper perspective
        float3 ray_origin = float3(0.0f, 0.0f, -1.0f);
        
        // We need to properly center the UV for the ray direction
        // uv from AS_transformCoord is already centered and aspect-ratio corrected
        float2 ray_uv = uv;
        
        // Apply depth of field
        float2 dof_offset = Hash2DTo2D(ray_uv + j_float * 74.542f + 35.877f) * 2.0f - 1.0f;
        ray_origin.xy += dof_offset * PR_DofStrength;          // Create ray direction with proper aspect ratio
        float3 ray_direction = normalize(float3(-ray_uv - dof_offset * PR_DofStrength * PR_DofDistFactor, PR_FovZ));
        
        // Apply scene rotation from the rotation UI (independent of camera animation)
        RotateSceneAroundCenter(ray_origin, ray_direction, rotation);
        // Apply camera animation with audio-reactive parameters
        ApplyCameraTransform(ray_origin, time_jittered, camAnimSpeed, PR_CamAnim_XZ_RotAmount, 
                             PR_CamAnim_XY_TimeFactor, PR_CamAnim_XY_RotAmount);
        ApplyCameraTransform(ray_direction, time_jittered, camAnimSpeed, PR_CamAnim_XZ_RotAmount, 
                             PR_CamAnim_XY_TimeFactor, PR_CamAnim_XY_RotAmount);
        
        float3 path_throughput = float3(1.0f, 1.0f, 1.0f);
            
        for(int bounce = 0; bounce < PR_Bounces; ++bounce) { // Use uniform PR_Bounces
            float bounce_float = (float)bounce;
            
            float3 inv_ray_dir = 1.0f / (ray_direction + 1e-6f); 
            float3 t_to_near_planes = ( box_extents - ray_origin) * inv_ray_dir;
            float3 t_to_far_planes  = (-box_extents - ray_origin) * inv_ray_dir;
            float3 box_t_artistic = max(t_to_near_planes, t_to_far_planes); 
            float hit_dist = min(box_t_artistic.x, box_t_artistic.y); 

            if (hit_dist < 0.0f || hit_dist > box_extents.z * 2.0f) break; 

            float3 hit_point = ray_origin + ray_direction * hit_dist;
            
            float2 surface_uv;
            float3 surface_normal; 
            
            if(box_t_artistic.x < box_t_artistic.y) {
                surface_uv = hit_point.yz;
                surface_uv.x += 1.0f; // Tunable: PR_Surface_UV_X_Offset_WallX
                surface_normal = float3(sign(box_t_artistic.x), 0.0f, 0.0f); 
            } else {
                surface_uv = hit_point.xz;
                surface_normal = float3(0.0f, sign(box_t_artistic.y), 0.0f);
            }
            if (dot(surface_normal, ray_direction) > 0.0f) surface_normal *= -1.0f;            float3 p_animated = hit_point;
            p_animated.z += time_jittered * PR_Surface_Anim_Z_Scroll;
            surface_uv.y += time_jittered * PR_Surface_Anim_V_Scroll;
            surface_uv *= patternScale; // Use audio-reactive pattern scale
            float2 cell_id = floor(surface_uv);
            
            float roughness = min(1.0f, PR_RoughnessBase + PR_RoughnessVariation * Hash2DTo1D(cell_id + 100.5f));
            
            float3 surface_color_emission = float3(0.0f, 0.0f, 0.0f);
            surface_color_emission += float3(PR_Emission_BaseTint.r + max(0.0f, cos(surface_uv.y * PR_Emission_Wave1_Freq) * PR_Emission_Wave1_Amp), 
                                            PR_Emission_BaseTint.g,
                                            PR_Emission_BaseTint.b + max(0.0f, sin(surface_uv.y * PR_Emission_Wave2_Freq) * PR_Emission_Wave2_Amp)) 
                                  * emissionBrightness; // Use audio-reactive brightness
            
            surface_color_emission *= smoothstep(PR_CellPattern_Threshold * GetCurveValue(time + cell_id.y*0.01f + cell_id.x*0.03f, PR_CellPattern_CurvePeriod, 10.0f), 0.0f, Hash2DTo1D(cell_id)); // Added 10.0f for curve_transition_power
            
            surface_color_emission *= step(PR_GridPattern_Threshold, sin(p_animated.x) * sin(p_animated.z * PR_GridPattern_Z_Freq));
            
            float floor_curve_val = GetCurveValue(time, PR_Floor_CurvePeriod, 10.0f); // Added 10.0f
            surface_color_emission += PR_Floor_Color * step(p_animated.y, PR_Floor_Y_Threshold) * max(0.0f, floor_curve_val * PR_Floor_CurveScale - PR_Floor_CurveBias) * step(Hash2DTo1D(cell_id + 0.7f), PR_Floor_HashThreshold);
            
            total_color += surface_color_emission * path_throughput;
            
            float fresnel_like = pow(1.0f - max(0.0f, dot(surface_normal, ray_direction)), PR_ReflectionAngleBias);
            path_throughput *= fresnel_like * PR_ReflectionPathDecay;
            
            if (dot(path_throughput, path_throughput) < 1e-3f) break;

            float3 pure_reflection_dir = reflect(ray_direction, surface_normal);
            float3 random_hemi_dir = normalize(Hash2DTo3D(uv + j_float * 74.524f + bounce_float * 35.712f) - 0.5f);
            if(dot(random_hemi_dir, surface_normal) < 0.0f) random_hemi_dir *= -1.0f;
            
            ray_direction = normalize(lerp(random_hemi_dir, pure_reflection_dir, roughness));
            ray_origin = hit_point + ray_direction * 0.001f; 
        } 
    }     if (PR_Steps > 0) total_color /= (float)PR_Steps;
    
    total_color *= PR_FinalBrightness; 
    total_color = smoothstep(0.0f, 1.0f, total_color); 
    total_color = pow(total_color, 1.0f / PR_Gamma);
      // Apply standard AS blending between effect and original color
    float4 effectColor = float4(total_color, 1.0);
    float4 finalColor = float4(AS_applyBlend(effectColor.rgb, originalColor.rgb, CorridorTravel_BlendMode), 1.0);
    finalColor = lerp(originalColor, finalColor, CorridorTravel_BlendAmount);
        
    return finalColor;
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_CorridorTravel <
    ui_label = "[AS] BGX: Corridor Travel";
    ui_tooltip = "Simulates a flight through an abstract, glowing tunnel with DOF, motion blur, and artistic reflections.\n"
                 "Original inspiration by NuSan's 'Corridor Travel' (2020) and jetlab's 'past racer'.\n"
                 "Performance depends on Sample Count and Light Bounces settings.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CorridorTravel;
    }
}

#endif // __AS_BGX_CorridorTravel_1_fx
