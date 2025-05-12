/**
 * AS_FX_PastRacer_Audio.fx - (Inspired by "past racer" by jetlab GLSL)
 * Translated and Enhanced for ReShade by AI (Gemini) with User Collaboration.
 * Integrated with AS_Utils for audio reactivity.
 * Scene 0 flare event can now be triggered by beat detection.
 * Includes fix for scene orientation.
 *
 * Description:
 * A ray marching shader that generates one of two selectable abstract procedural scenes.
 * Features domain repetition, custom transformations, and pseudo-random patterns.
 * Scene 0's geometry and flare effects are reactive to audio frequency bands.
 */

#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_getTime(), AS_mod(), AS_getFrequencyBand(), AS_getNumFrequencyBands(), UI macros

// --- Tunable Uniforms ---
uniform int PR_SceneSelection <
    ui_type = "combo"; ui_label = "Select Scene";
    ui_items = "Audio Boxes (Scene 0)\0Corridor Structure (Scene 1)\0";
    ui_tooltip = "Switches between the two different procedural scenes.";
    ui_category = "Scene Selection";
> = 0;

uniform float PR_GlobalTimeScale <
    ui_type = "drag"; ui_min = 0.0; ui_max = 3.0; ui_step = 0.01;
    ui_label = "Global Animation Speed";
    ui_tooltip = "Multiplies the master time for all animations.";
    ui_category = "Animation";
> = 1.0f;

uniform int PR_RayMarchSteps <
    ui_type = "drag"; ui_min = 10; ui_max = 200; ui_step = 1;
    ui_label = "Ray March Steps";
    ui_tooltip = "Maximum steps for ray marching. Higher is more accurate but slower.";
    ui_category = "Quality & Performance";
> = 100;

uniform float PR_MaxTraceDistance <
    ui_type = "drag"; ui_min = 50.0; ui_max = 1000.0; ui_step = 10.0;
    ui_label = "Max Trace Distance";
    ui_tooltip = "Maximum distance a ray will travel.";
    ui_category = "Quality & Performance";
> = 300.0f;

uniform float PR_HitEpsilon <
    ui_type = "drag"; ui_min = 0.001; ui_max = 0.1; ui_step = 0.001;
    ui_label = "Hit Precision (Epsilon)";
    ui_tooltip = "Threshold for considering a ray to have hit a surface.";
    ui_category = "Quality & Performance";
> = 0.01f;

uniform float PR_FieldOfView <
    ui_type = "drag"; ui_min = 0.1; ui_max = 2.0; ui_step = 0.01;
    ui_label = "Field of View";
    ui_tooltip = "Controls the camera's field of view. Smaller is more zoomed in (larger value for fov parameter in code).";
    ui_category = "Camera";
> = 0.4f;

uniform float PR_FFT_Multiplier <
    ui_type = "drag"; ui_min = 0.0; ui_max = 100.0; ui_step = 1.0;
    ui_label = "Box Height Audio Strength (Scene 0)";
    ui_tooltip = "Multiplies the audio frequency band value, affecting Scene 0's box heights.";
    ui_category = "Scene Details (Scene 0)";
> = 50.0f;

AS_AUDIO_SOURCE_UI(PR_S0_Flare_AudioSource, "Flare Audio Source (Scene 0)", AS_AUDIO_BEAT, "Scene Details (Scene 0)")
AS_AUDIO_MULTIPLIER_UI(PR_S0_Flare_AudioMultiplier, "Flare Audio Intensity (Scene 0)", AS_RANGE_AUDIO_MULT_DEFAULT, AS_RANGE_AUDIO_MULT_MAX, "Scene Details (Scene 0)")

uniform float PR_VignetteStrength <
    ui_type = "drag"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01;
    ui_label = "Vignette Strength";
    ui_tooltip = "Strength of the screen-edge darkening effect. Original based on 1.2 - length(uv).";
    ui_category = "Post-Effects";
> = 1.2f;

uniform float PR_Gamma < 
    ui_type = "drag"; ui_min = 1.0; ui_max = 3.0; ui_step = 0.01;
    ui_label = "Gamma Correction";
    ui_tooltip = "Final gamma adjustment. Standard is often 2.2.";
    ui_category = "Post-Effects";
> = 2.2f;

// ============================================================================
// COLOR CONTROLS
// ============================================================================
uniform float3 PR_Scene0_PrimaryColor < ui_type = "color"; ui_label = "Scene 0: Primary Color"; ui_tooltip = "Primary color for audio-reactive boxes in Scene 0"; ui_category = "Color Controls"; > = float3(0.3f, 0.4f, 1.0f);

uniform float3 PR_Scene0_SecondaryColor < ui_type = "color"; ui_label = "Scene 0: Secondary Color"; ui_tooltip = "Secondary color for flare effects in Scene 0"; ui_category = "Color Controls"; > = float3(1.0f, 0.4f, 0.6f);

uniform float3 PR_Scene1_PrimaryColor < ui_type = "color"; ui_label = "Scene 1: Primary Color"; ui_tooltip = "Primary color for corridor structure in Scene 1"; ui_category = "Color Controls"; > = float3(1.0f, 0.3f, 0.8f);

uniform float3 PR_DiffuseColor < ui_type = "color"; ui_label = "Diffuse Light Color"; ui_tooltip = "Color of the diffuse lighting"; ui_category = "Color Controls"; > = float3(1.0f, 1.0f, 1.0f);

uniform float3 PR_SkyTint_Horizon < ui_type = "color"; ui_label = "Sky Color (Horizon)"; ui_tooltip = "Color of the sky at the horizon"; ui_category = "Color Controls"; > = float3(1.0f, 0.6f, 0.7f);

uniform float3 PR_SkyTint_Zenith < ui_type = "color"; ui_label = "Sky Color (Zenith)"; ui_tooltip = "Color of the sky at its brightest point"; ui_category = "Color Controls"; > = float3(1.0f, 0.9f, 0.3f);

// ============================================================================
// LIGHTING & EFFECTS
// ============================================================================
uniform float PR_LightIntensity < ui_type = "drag"; ui_min = 0.1; ui_max = 20.0; ui_step = 0.1; ui_label = "Light Intensity"; ui_tooltip = "Brightness multiplier for the main light source"; ui_category = "Lighting & Effects"; > = 10.0f;

uniform float PR_SpecularPower < ui_type = "drag"; ui_min = 1.0; ui_max = 50.0; ui_step = 1.0; ui_label = "Specular Hardness"; ui_tooltip = "Controls the size of specular highlights (higher = smaller, sharper)"; ui_category = "Lighting & Effects"; > = 10.0f;

uniform float PR_SpecularIntensity < ui_type = "drag"; ui_min = 0.0; ui_max = 5.0; ui_step = 0.1; ui_label = "Specular Intensity"; ui_tooltip = "Brightness of specular highlights"; ui_category = "Lighting & Effects"; > = 1.0f;

uniform float PR_GlowIntensity < ui_type = "drag"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.05; ui_label = "Glow Intensity"; ui_tooltip = "Intensity of the post-glow effect (bloom-like)"; ui_category = "Lighting & Effects"; > = 1.0f;

// ============================================================================
// SCENE 0 SPECIFIC
// ============================================================================
uniform float PR_S0_BoxSize < ui_type = "drag"; ui_min = 0.1; ui_max = 5.0; ui_step = 0.1; ui_label = "Box Size (Scene 0)"; ui_tooltip = "Size of the audio-reactive boxes"; ui_category = "Scene Details (Scene 0)"; > = 1.0f;

uniform float PR_S0_FlareScale < ui_type = "drag"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.05; ui_label = "Flare Effect Scale (Scene 0)"; ui_tooltip = "Scale of the flare visual effect"; ui_category = "Scene Details (Scene 0)"; > = 1.0f;

uniform float PR_S0_AnimSpeed < ui_type = "drag"; ui_min = 0.1; ui_max = 5.0; ui_step = 0.1; ui_label = "Animation Speed (Scene 0)"; ui_tooltip = "Speed multiplier for scene-specific animations"; ui_category = "Scene Details (Scene 0)"; > = 1.0f;

// ============================================================================
// SCENE 1 SPECIFIC
// ============================================================================
uniform float PR_S1_TunnelSize < ui_type = "drag"; ui_min = 5.0; ui_max = 50.0; ui_step = 1.0; ui_label = "Tunnel Size (Scene 1)"; ui_tooltip = "Size of the main tunnel structure"; ui_category = "Scene Details (Scene 1)"; > = 20.0f;

uniform float PR_S1_GridPatternIntensity < ui_type = "drag"; ui_min = 0.0; ui_max = 20.0; ui_step = 0.1; ui_label = "Grid Pattern Intensity (Scene 1)"; ui_tooltip = "Intensity of the grid pattern displacement"; ui_category = "Scene Details (Scene 1)"; > = 12.7f;

uniform float PR_S1_AnimSpeed < ui_type = "drag"; ui_min = 0.1; ui_max = 5.0; ui_step = 0.1; ui_label = "Animation Speed (Scene 1)"; ui_tooltip = "Speed multiplier for scene-specific animations"; ui_category = "Scene Details (Scene 1)"; > = 1.0f;

// ============================================================================
// CAMERA CONTROLS
// ============================================================================
uniform float PR_CameraShakeAmount < ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.05; ui_label = "Camera Shake"; ui_tooltip = "Amount of procedural camera shake"; ui_category = "Camera"; > = 0.3f;

uniform float3 PR_LightDirection < ui_type = "drag"; ui_min = -1.0; ui_max = 1.0; ui_step = 0.1; ui_label = "Light Direction"; ui_tooltip = "Direction of the main light source"; ui_category = "Camera"; > = float3(-1.0f, -1.3f, -2.0f);

uniform float PR_CameraDistance < ui_type = "drag"; ui_min = 10.0; ui_max = 100.0; ui_step = 1.0; ui_label = "Camera Distance"; ui_tooltip = "Base distance of the camera from the center of the scene"; ui_category = "Camera"; > = 50.0f;

uniform float2 PR_CameraPositionXZ < ui_type = "drag"; ui_min = -50.0; ui_max = 50.0; ui_step = 1.0; ui_label = "Camera Position XZ"; ui_tooltip = "Horizontal position offset of the camera"; ui_category = "Camera"; > = float2(0.0f, 0.0f);

uniform float PR_CameraPositionY < ui_type = "drag"; ui_min = -50.0; ui_max = 50.0; ui_step = 1.0; ui_label = "Camera Height Y"; ui_tooltip = "Vertical position offset of the camera"; ui_category = "Camera"; > = 0.0f;

uniform bool PR_DisableCameraAutomation < ui_label = "Manual Camera Mode"; ui_tooltip = "When enabled, disables automatic camera movement and uses only the manual settings"; ui_category = "Camera"; > = false;

uniform float3 PR_LookAtPosition < ui_type = "drag"; ui_min = -50.0; ui_max = 50.0; ui_step = 1.0; ui_label = "Look At Position"; ui_tooltip = "Position the camera is looking at"; ui_category = "Camera"; > = float3(0.0f, 0.0f, 0.0f);

// --- Constants ---
static const float PI = 3.1415926535f;

// --- Helper Functions & Definitions ---
float RepeatCentered(float val, float period) { return (frac(val / period + 0.5f) - 0.5f) * period; }
float2 RepeatCentered2(float2 val, float2 period) { return (frac(val / period + 0.5f) - 0.5f) * period; }
float3 RepeatCentered3(float3 val, float3 period) { return (frac(val / period + 0.5f) - 0.5f) * period; }
float GetRepeatID(float val, float period) { return floor(val / period + 0.5f); }
float2 GetRepeatID2(float2 val, float2 period) { return floor(val / period + 0.5f); }

float GetFFTValue(float2 t_audio_uv) {
    float fft_sample_coord = (frac(t_audio_uv.x * 10.0f) + frac(t_audio_uv.y)) * 0.1f; 
    int num_bands = AS_getNumFrequencyBands();
    if (num_bands <= 0) return 0.0f * PR_FFT_Multiplier;
    float normalized_band_selector = saturate(fft_sample_coord / 0.2f); 
    int band_index = (int)floor(normalized_band_selector * (float)(num_bands -1)); 
    band_index = clamp(band_index, 0, num_bands - 1); 
    float fft_amplitude = AS_getFrequencyBand(band_index);
    return fft_amplitude * PR_FFT_Multiplier; 
}

float2 Hash2DTo2D(float2 p_hash){ return frac(sin(p_hash * float2(425.522f, 847.554f) + p_hash.yx * float2(847.554f, 425.522f)) * 352.742f); }
float Hash1D(float a_hash) { return frac(sin(a_hash * 254.574f) * 652.512f); }

float GetCurveValue(float t_curve, float d_curve, float time_val_unused, float transition_power) { 
    t_curve /= d_curve;
    return lerp(Hash1D(floor(t_curve)), Hash1D(floor(t_curve) + 1.0f), pow(smoothstep(0.0f, 1.0f, frac(t_curve)), transition_power));
}

float GetTickedValue(float t_tick, float d_tick, float transition_power) {
    t_tick /= d_tick;
    return (floor(t_tick) + pow(smoothstep(0.0f, 1.0f, frac(t_tick)), transition_power)) * d_tick;
}

float SDF_Box(float3 p_box, float3 s_box) { p_box = abs(p_box) - s_box; return max(p_box.x, max(p_box.y, p_box.z));}

float2x2 GetRotationMatrix(float angle_rot) {
    float ca = cos(angle_rot); float sa = sin(angle_rot); return float2x2(ca, -sa, sa, ca); 
}

float SDE_GridPattern(float3 p_grid, float time_val) { /* ... unchanged ... */ 
    float v_grid = 0.0f;
    p_grid *= 0.004f; 
    for(int i_grid = 0; i_grid < 3; ++i_grid) {
        float i_grid_f = (float)i_grid;
        p_grid *= 1.7f; 
        p_grid.xz = mul(p_grid.xz, GetRotationMatrix(0.3f + i_grid_f)); 
        p_grid.xy = mul(p_grid.xy, GetRotationMatrix(0.4f + i_grid_f * 1.3f)); 
        p_grid += float3(0.1f,0.3f,-0.13f)*(i_grid_f+1.0f); 
        float3 g_comp = abs(frac(p_grid)-0.5f)*2.0f;
        v_grid -= min(g_comp.x,min(g_comp.y,g_comp.z))*0.7f;
    }
    return v_grid;
}

float SDE_DescribeWorld(float3 p_world, float time_val, int scene_idx, inout float acc_at, inout float acc_at2)
{
    float d_world = 1e10; 
    if (scene_idx == 0) { 
        // Apply scene-specific animation speed
        float animatedTime = time_val * PR_S0_AnimSpeed;
        
        p_world.xz = mul(p_world.xz, GetRotationMatrix(sin(-length(p_world.xz) * 0.07f + animatedTime * 1.0f) * 1.0f));
        p_world.y += pow(smoothstep(0.0f, 1.0f, sin(-pow(length(p_world.xz), 2.0f) * 0.001f + animatedTime * 4.0f)), 3.0f) * 4.0f;
        d_world = -p_world.y; 
        for(int i_map0 = 0; i_map0 < 4; ++i_map0) {
            float i_map0_f = (float)i_map0;
            float3 p2_map0 = p_world;
            p2_map0.xz = mul(p2_map0.xz, GetRotationMatrix(i_map0_f + 0.7f));
            p2_map0.xz -= 7.0f; 
            float2 rep_id_vec = GetRepeatID2(p2_map0.xz, float2(10.0f, 10.0f));
            float2 rnd_for_fft = Hash2DTo2D(rep_id_vec); 
            float fft_val = GetFFTValue(rnd_for_fft); 
            p2_map0.xz = RepeatCentered2(p2_map0.xz, float2(10.0f, 10.0f));
            
            // Apply box size uniform to the audio-reactive boxes
            d_world = min(d_world, SDF_Box(p2_map0, float3(PR_S0_BoxSize, 0.3f * fft_val, PR_S0_BoxSize)));
        }
        float3 p3_map0 = p_world; float t3_map0 = animatedTime * 0.13f;
        p3_map0.xz = mul(p3_map0.xz, GetRotationMatrix(t3_map0));
        p3_map0.xy = mul(p3_map0.xy, GetRotationMatrix(t3_map0 * 1.3f));
        p3_map0 = RepeatCentered3(p3_map0, float3(5.0f, 5.0f, 5.0f));
        float d2_map0 = SDF_Box(p3_map0, float3(1.7f, 1.7f, 1.7f)); 
        d_world = min(d_world, d_world - d2_map0 * 0.1f);
        float3 p4_map0 = p_world; float t4_map0_rot = animatedTime * 1.33f;
        p4_map0.xz = RepeatCentered2(p4_map0.xz, float2(200.0f, 200.0f));
        p4_map0.yz = mul(p4_map0.yz, GetRotationMatrix(t4_map0_rot));
        p4_map0.xz = mul(p4_map0.xz, GetRotationMatrix(t4_map0_rot * 1.3f));
        
        // Apply flare scale to the first flare accumulator
        acc_at += 0.04f * PR_S0_FlareScale / (1.2f + abs(length(p4_map0.xz) - 17.0f));
        
        float3 p5_map0 = p_world; float t5_map0 = animatedTime * 1.23f;
        p5_map0.xz = RepeatCentered2(p5_map0.xz, float2(200.0f, 200.0f));
        p5_map0.yz = mul(p5_map0.yz, GetRotationMatrix(t5_map0 * 0.7f));
        p5_map0.xy = mul(p5_map0.xy, GetRotationMatrix(t5_map0));
        
        // Apply flare scale to the second flare accumulator
        acc_at2 += 0.04f * PR_S0_FlareScale / (1.2f + abs(SDF_Box(p5_map0, float3(37.0f, 37.0f, 37.0f))));
        return d_world * 0.7f;
    } else { // SCENE 1
        // Apply scene-specific animation speed
        float animatedTime = time_val * PR_S1_AnimSpeed;
        
        float ppy_map1 = p_world.y;
        p_world.y = RepeatCentered(p_world.y, 300.0f);
        p_world.xz = mul(p_world.xz, GetRotationMatrix(sin(-length(p_world.xz) * 0.0007f + animatedTime * 0.5f + ppy_map1 * 0.005f) * 1.0f));
        float3 p4_map1 = p_world;
        
        // Apply tunnel size uniform
        d_world = SDF_Box(p4_map1, float3(PR_S1_TunnelSize, PR_S1_TunnelSize, PR_S1_TunnelSize));
        float ss_map1 = PR_S1_TunnelSize * 0.5f; // Halving the size makes the tunnels more proportional
        d_world = max(d_world, -SDF_Box(p4_map1, float3(ss_map1, ss_map1, 100.0f)));
        d_world = max(d_world, -SDF_Box(p4_map1, float3(ss_map1, 100.0f, ss_map1)));
        d_world = max(d_world, -SDF_Box(p4_map1, float3(100.0f, ss_map1, ss_map1)));
        float3 p3_map1 = p_world;
        p3_map1.xz = mul(p3_map1.xz, GetRotationMatrix(sin(animatedTime * 3.0f + p_world.y * 0.01f) * 0.3f));
        p3_map1.xz = abs(p3_map1.xz) - 30.0f;
        p3_map1.xz = abs(p3_map1.xz) - 10.0f * (sin(animatedTime + p_world.y * 0.05f) * 0.5f + 0.5f);
        d_world = min(d_world, length(p3_map1.xz) - 5.0f);
        float g_map1 = SDE_GridPattern(p_world, animatedTime);
        
        // Apply grid pattern intensity uniform
        float d2_map1 = d_world - 5.0f - g_map1 * PR_S1_GridPatternIntensity; 
        d_world = min(d_world + 4.3f, d2_map1); 
        
        float3 p6_map1 = p_world; float t6_map1 = animatedTime * 1.33f;
        p6_map1.xz = RepeatCentered2(p6_map1.xz, float2(40.0f, 40.0f));
        p6_map1.yz = mul(p6_map1.yz, GetRotationMatrix(t6_map1));
        p6_map1.xz = mul(p6_map1.xz, GetRotationMatrix(t6_map1 * 1.3f));
        acc_at += 0.04f / (1.2f + abs(length(p6_map1.xz) - 17.0f));
        float3 p5_map1 = p_world; float t5_map1 = animatedTime * 1.23f;
        p5_map1.yz = mul(p5_map1.yz, GetRotationMatrix(t5_map1 * 0.7f));
        p5_map1.xy = mul(p5_map1.xy, GetRotationMatrix(t5_map1));
        acc_at2 += 0.04f / (0.7f + abs(SDF_Box(p5_map1, float3(37.0f, 37.0f, 37.0f))));
        float3 p7_map1 = p_world; float t3_map1 = animatedTime * 0.13f;
        p7_map1.xz = mul(p7_map1.xz, GetRotationMatrix(t3_map1));
        p7_map1.xy = mul(p7_map1.xy, GetRotationMatrix(t3_map1 * 1.3f));
        p7_map1 = RepeatCentered3(p7_map1, float3(5.0f, 5.0f, 5.0f));
        float d7_map1 = SDF_Box(p7_map1, float3(1.7f, 1.7f, 1.7f)); 
        d_world = min(d_world, d_world * 0.7f - d7_map1 * 0.7f); 
        return d_world * 0.7f;
    }
    return d_world; 
}

// --- Main Pixel Shader ---
float4 PS_OutlineOnline2020(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float master_time = AS_getTime() * PR_GlobalTimeScale;
    float current_time = AS_mod(master_time, 300.0f); 
    
    float2 uv = texcoord - 0.5f; 
    uv.x *= ReShade::AspectRatio; 
    uv.y *= -1.0f; 
      float at_accumulator = 0.0f;
    float at2_accumulator = 0.0f;
    
    // Initialize base camera position with user-defined distance
    float3 initial_ray_origin = float3(PR_CameraPositionXZ.x, PR_CameraPositionY, -PR_CameraDistance);
    
    // Apply automatic camera movement if not disabled
    if (!PR_DisableCameraAutomation) {
        initial_ray_origin.xz += (GetCurveValue(current_time, 1.6f, current_time, 10.0f) - 0.5f) * 30.0f;
    }
    
    float3 look_at_target = PR_LookAtPosition;
    
    // --- Calculate lighting_part and flare_intensity_mod based on audio ---
    float base_lighting_part = smoothstep(-0.1f, 0.1f, sin(current_time));
    float actual_lighting_part = base_lighting_part;
    float flare_intensity_mod = 1.0f;

    if (PR_SceneSelection == 0)
    {
        if (PR_S0_Flare_AudioSource == AS_AUDIO_BEAT)
        {
            float beatLevel = AS_getAudioSource(AS_AUDIO_BEAT); // This is a pulse [0,1] that decays
            actual_lighting_part = beatLevel; // Flare "mood" (at/at2 dominance) pulses with the beat
            flare_intensity_mod = PR_S0_Flare_AudioMultiplier; // Control brightness of the beat-triggered flare
        }
        else if (PR_S0_Flare_AudioSource != AS_AUDIO_OFF) // Other audio sources (Volume, Bands, Solid)
        {
            // actual_lighting_part remains base_lighting_part (slow sine wave for mood timing)
            float audioLevel = AS_getAudioSource(PR_S0_Flare_AudioSource);
            flare_intensity_mod = audioLevel * PR_S0_Flare_AudioMultiplier; // Flare intensity continuously modulated
        }
        // If PR_S0_Flare_AudioSource is AS_AUDIO_OFF, actual_lighting_part is base_lighting_part, 
        // and flare_intensity_mod is 1.0f (original non-audio behavior for flare intensity).
    }    // If not Scene 0, actual_lighting_part and flare_intensity_mod keep their default:
    // base_lighting_part and 1.0f respectively.
    
    // Apply automatic camera rotation and shake if enabled
    float cam_adv = current_time * 0.1f; 
    if (!PR_DisableCameraAutomation) {
        // Apply camera shake scaled by the user's setting
        initial_ray_origin.yz = mul(initial_ray_origin.yz, GetRotationMatrix(sin(cam_adv * 0.3f) * PR_CameraShakeAmount + 0.5f));
        initial_ray_origin.xz = mul(initial_ray_origin.xz, GetRotationMatrix(cam_adv));
    }
 
    // Scene-specific camera adjustments
    if (PR_SceneSelection == 1) {  
        // For Scene 1, apply initial offsets if in automatic mode
        if (!PR_DisableCameraAutomation) {
            initial_ray_origin.y -= 100.0f;
            initial_ray_origin.x += 100.0f;
            float push_offset = GetTickedValue(current_time, 0.5f, 10.0f) * 100.0f; 
            initial_ray_origin.y += push_offset;
            look_at_target.y += push_offset;
        } else {
            // In manual mode, keep the look_at_target slightly ahead of camera
            look_at_target.y = initial_ray_origin.y;
            look_at_target.z = initial_ray_origin.z + 50.0f;
        }
    }
    
    float3 cam_dir_z = normalize(look_at_target - initial_ray_origin);
    float3 cam_dir_x = normalize(cross(float3(0.0f, 1.0f, 0.0f), cam_dir_z)); 
    float3 cam_dir_y = normalize(cross(cam_dir_x, cam_dir_z));
    float3 ray_direction = normalize(uv.x * cam_dir_x + uv.y * cam_dir_y + PR_FieldOfView * cam_dir_z);
    
    float3 accumulated_color = float3(0.0f, 0.0f, 0.0f); // This will be the base for the flare mood
    float3 current_ray_pos = initial_ray_origin;

    for(int k = 0; k < PR_RayMarchSteps; ++k) {
        float dist_to_scene = abs(SDE_DescribeWorld(current_ray_pos, current_time, PR_SceneSelection, at_accumulator, at2_accumulator));
        if(dist_to_scene < PR_HitEpsilon) { break; }
        if(dist_to_scene > PR_MaxTraceDistance) break; 
        current_ray_pos += ray_direction * dist_to_scene;
    }
    
    float at_curve_val = 1.0f + GetCurveValue(current_time, 0.3f, current_time, 10.0f);
    float at2_curve_val = 1.0f + GetCurveValue(current_time, 0.4f, current_time, 10.0f);

    float3 flare_component_color = 0.0f;
    flare_component_color += at_accumulator  * PR_Scene0_PrimaryColor * at_curve_val;
    flare_component_color += at2_accumulator * PR_Scene0_SecondaryColor * at2_curve_val;
    
    flare_component_color *= flare_intensity_mod; // Apply audio/static intensity mod
    
    // This 'accumulated_color' will primarily be the flare component, mixed by actual_lighting_part
    accumulated_color = flare_component_color * actual_lighting_part; 
    
    // --- Calculate lighting_color2 (the "other" lighting mood) ---
    float fog_dist = length(current_ray_pos - initial_ray_origin);
    float fog_factor = 1.0f - clamp(fog_dist / PR_MaxTraceDistance, 0.0f, 1.0f);
    float2 norm_off = float2(0.01f, 0.0f); 
    float at_norm_dummy = 0.0f, at2_norm_dummy = 0.0f; 
    float map_p  = SDE_DescribeWorld(current_ray_pos, current_time, PR_SceneSelection, at_norm_dummy, at2_norm_dummy); at_norm_dummy=0.0f; at2_norm_dummy=0.0f;
    float map_px = SDE_DescribeWorld(current_ray_pos - norm_off.xyy, current_time, PR_SceneSelection, at_norm_dummy, at2_norm_dummy); at_norm_dummy=0.0f; at2_norm_dummy=0.0f;
    float map_py = SDE_DescribeWorld(current_ray_pos - norm_off.yxy, current_time, PR_SceneSelection, at_norm_dummy, at2_norm_dummy); at_norm_dummy=0.0f; at2_norm_dummy=0.0f;
    float map_pz = SDE_DescribeWorld(current_ray_pos - norm_off.yyx, current_time, PR_SceneSelection, at_norm_dummy, at2_norm_dummy);
    float3 surface_normal = normalize(float3(map_p - map_px, map_p - map_py, map_p - map_pz) / norm_off.x); 
    float3 light_direction = normalize(PR_LightDirection);
    float3 halfway_vector = normalize(light_direction - ray_direction);
    float soft_shadow_occlusion = 0.0f;
    for(int s_idx = 1; s_idx < 20; ++s_idx) { 
        float s_idx_f = (float)s_idx; float shadow_ray_dist = s_idx_f * 5.2f; 
        at_norm_dummy=0.0f; at2_norm_dummy=0.0f;
        soft_shadow_occlusion += smoothstep(0.0f, 1.0f, SDE_DescribeWorld(current_ray_pos + light_direction * shadow_ray_dist + surface_normal * 0.01f, current_time, PR_SceneSelection, at_norm_dummy, at2_norm_dummy) / shadow_ray_dist); 
    }
    if (19 > 0) soft_shadow_occlusion /= 19.0f; 
    float3 lighting_color2 = float3(0.0f, 0.0f, 0.0f);
    lighting_color2 += soft_shadow_occlusion * PR_Scene1_PrimaryColor * 0.15f * fog_factor;
    at_norm_dummy=0.0f; at2_norm_dummy=0.0f;
    float ao_factor = smoothstep(0.0f, 1.0f, SDE_DescribeWorld(current_ray_pos + surface_normal * 0.1f, current_time, PR_SceneSelection, at_norm_dummy, at2_norm_dummy)); 
    float3 sky_color = lerp(PR_SkyTint_Horizon * 0.1f, PR_SkyTint_Zenith * PR_LightIntensity, pow(max(0.0f, dot(ray_direction, light_direction)), 20.0f));
    float diffuse_term = max(0.0f, dot(surface_normal, light_direction));
    float specular_term = pow(max(0.0f, dot(halfway_vector, surface_normal)), PR_SpecularPower); 
    lighting_color2 += diffuse_term * (PR_DiffuseColor + specular_term * PR_SpecularIntensity) * fog_factor * ao_factor; 
    lighting_color2 += pow(1.0f - fog_factor, 2.0f) * sky_color;
    // --- End of lighting_color2 calculation ---

    accumulated_color += lighting_color2 * (1.0f - actual_lighting_part); // Mix in the "other" lighting based on the part not taken by flare mood
    
    accumulated_color *= (PR_VignetteStrength - length(uv));
    
    accumulated_color += max(accumulated_color.yzx - 1.0f, 0.0f);
    accumulated_color += max(accumulated_color.zxy - 1.0f, 0.0f);
    
    accumulated_color = smoothstep(0.0f, 1.0f, accumulated_color); 
    accumulated_color = pow(accumulated_color, 1.0f / PR_Gamma); 
        
    return float4(accumulated_color, 1.0f);
}

// --- ReShade Technique Definition ---
technique OutlineOnline2020_Raymarcher_Tech <
    ui_label = "Outline Online 2020 Raymarcher";
    ui_tooltip = "Raymarcher with two selectable procedural scenes, inspired by a live coding session.\n"
                 "Features audio-reactive geometry & effects, reflections, and complex lighting. Tunable.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_OutlineOnline2020;
    }
}

#ifndef __TECHNIQUE_GUARD_OL2020_FX__ 
#define __TECHNIQUE_GUARD_OL2020_FX__
#endif