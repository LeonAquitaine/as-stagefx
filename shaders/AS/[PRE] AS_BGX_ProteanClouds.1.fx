/**
 * AS_BGX_ProteanClouds.1.fx - Dynamic Volumetric Cloud Formation
 * Author: Leon Aquitaine (based on original by Nimitz/Kali)
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Renders dynamic, evolving volumetric clouds through raymarching techniques. Creates
 * an immersive, abstract cloudscape with dynamic color variations and realistic lighting.
 *
 * FEATURES:
 * - High-quality volumetric cloud formations rendered with raymarching
 * - Customizable cloud density, shape, and detail
 * - Dynamic camera movement with adjustable path and sway
 * - Sophisticated internal lighting and self-shadowing
 * - Color palette system with customizable parameters
 * - Audio reactivity for multiple cloud parameters
 * - Resolution-independent rendering with precise position controls
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Raymarches a 3D density field with FBM-like noise functions
 * 2. Calculates cloud density from transformed noise patterns
 * 3. Applies dynamic lighting with self-shadows for volumetric feel
 * 4. Adds atmospheric fog with distance and color controls
 * 5. Uses camera animation along a procedural path for immersion
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_ProteanClouds_1_fx
#define __AS_BGX_ProteanClouds_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh" 
#include "AS_Palette.1.fxh"

// Global Parameters
static float g_prm1;
static float2 g_bsMo_NoMouse; 
static float g_iTime_global_for_map; 

//--------------------------------------------------------------------------------------
// UI UNIFORMS
//--------------------------------------------------------------------------------------
AS_ANIMATION_UI(MasterTimeSpeed, MasterTimeKeyframe, "Global Animation")

// --- Performance & Quality ---
uniform int Raymarch_Steps < ui_category="Performance & Quality"; ui_type="slider"; ui_min=30; ui_max=250; ui_step=1; ui_label="Raymarch Steps"; ui_tooltip="Max steps for raymarching clouds. Original: 130"; > = 130;
uniform int Noise_Octaves < ui_category="Performance & Quality"; ui_type="slider"; ui_min=1; ui_max=8; ui_step=1; ui_label="Noise Octaves"; ui_tooltip="Number of layers for cloud noise generation. Original: 5"; > = 5;
uniform float DynamicStep_Min < ui_category="Performance & Quality"; ui_type="drag"; ui_min=0.01; ui_max=0.5; ui_step=0.01; ui_label="Min Dynamic Step Size"; ui_tooltip="Minimum step size for raymarching. Original: 0.09"; > = 0.09f;
uniform float DynamicStep_Max < ui_category="Performance & Quality"; ui_type="drag"; ui_min=0.1; ui_max=1.0; ui_step=0.01; ui_label="Max Dynamic Step Size"; ui_tooltip="Maximum step size for raymarching. Original: 0.3"; > = 0.3f;
uniform float DynamicStep_DensityInfluence < ui_category="Performance & Quality"; ui_type="drag"; ui_min=0.0; ui_max=0.2; ui_step=0.001; ui_label="Density Influence on Step Size"; ui_tooltip="How much cloud density affects step size reduction. Original: 0.05"; > = 0.05f;

// --- Camera & Scene Animation ---
uniform float Camera_PathSpeedFactor < ui_category="Camera & Scene Animation"; ui_type="drag"; ui_min=0.1; ui_max=10.0; ui_step=0.1; ui_label="Camera Path Speed"; ui_tooltip="Speed of camera movement along its Z-axis path. Original factor for time: 3.0"; > = 3.0;
uniform float Camera_SwayAmplitude < ui_category="Camera & Scene Animation"; ui_type="drag"; ui_min=0.0; ui_max=2.0; ui_step=0.01; ui_label="Camera Sway Amplitude"; ui_tooltip="Magnitude of the camera's side-to-side sway (center sway). Original: 0.85"; > = 0.85;
uniform float Camera_SwayFrequencyFactor < ui_category="Camera & Scene Animation"; ui_type="drag"; ui_min=0.1; ui_max=2.0; ui_step=0.01; ui_label="Camera Sway Frequency Scale"; ui_tooltip="Scales the frequency of the camera sway. Default: 1.0"; > = 1.0;
uniform float Camera_FOV_Effect < ui_category="Camera & Scene Animation"; ui_type="drag"; ui_min=0.5; ui_max=2.5; ui_step=0.01; ui_label="Field of View (Effect Scale)"; ui_tooltip="Scales ray spread, affecting FOV. Original: 1.0"; > = 1.0;
uniform float Scene_InternalRotationSpeedFactor < ui_category="Camera & Scene Animation"; ui_type="drag"; ui_min=0.0; ui_max=0.2; ui_step=0.001; ui_label="Cloud Internal XY Rotation Speed"; ui_tooltip="Speed of the cloud pattern's internal XY rotation (in map function). Original factor: 0.09"; > = 0.09f; // Renamed variable from Scene_RotationSpeed
uniform float Prm1_AnimationSpeedFactor < ui_category="Camera & Scene Animation"; ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_step=0.01; ui_label="Global Param 'prm1' Anim Speed"; ui_tooltip="Speed of animation for the global 'prm1' parameter. Original factor: 0.3"; > = 0.3f; // Renamed variable from Prm1_AnimationSpeed
uniform float RayDir_RotationStrength < ui_category="Camera & Scene Animation"; ui_type="drag"; ui_min=-0.5; ui_max=0.5; ui_step=0.01; ui_label="Ray Direction Twist Strength"; ui_tooltip="Strength of the time-displaced twist applied to ray directions. Original factor: 0.2"; > = 0.2f;

// --- Cloud Shape & Noise ---
uniform float Cloud_OverallScale < ui_category="Cloud Shape & Noise"; ui_type="drag"; ui_min=0.1; ui_max=2.0; ui_step=0.01; ui_label="Cloud Pattern Scale"; > = 0.61f;
uniform float Cloud_NoiseDisplacementBase < ui_category="Cloud Shape & Noise"; ui_type="drag"; ui_min=0.0; ui_max=0.5; ui_step=0.01; ui_label="Noise Displacement Base"; > = 0.1f;
uniform float Cloud_NoisePrm1Influence < ui_category="Cloud Shape & Noise"; ui_type="drag"; ui_min=0.0; ui_max=0.5; ui_step=0.01; ui_label="Noise Displacement Prm1 Influence"; > = 0.2f;
uniform float Cloud_NoiseFrequencyBase < ui_category="Cloud Shape & Noise"; ui_type="drag"; ui_min=0.1; ui_max=2.0; ui_step=0.01; ui_label="Noise Internal Frequency"; > = 0.75f;
uniform float Cloud_NoiseTimeInfluence < ui_category="Cloud Shape & Noise"; ui_type="drag"; ui_min=0.0; ui_max=2.0; ui_step=0.01; ui_label="Noise Internal Animation Speed"; > = 0.8f;
uniform float Cloud_NoiseAmplitudeDecay < ui_category="Cloud Shape & Noise"; ui_type="drag"; ui_min=0.3; ui_max=0.9; ui_step=0.01; ui_label="Noise Amplitude Decay (Octaves)"; > = 0.57f;
uniform float Cloud_NoiseFreqLacunarity < ui_category="Cloud Shape & Noise"; ui_type="drag"; ui_min=1.0; ui_max=3.0; ui_step=0.01; ui_label="Noise Frequency Lacunarity (Octaves)"; > = 1.4f;
uniform float Cloud_DensityBias < ui_category="Cloud Shape & Noise"; ui_type="drag"; ui_min=-5.0; ui_max=5.0; ui_step=0.01; ui_label="Cloud Density Bias"; > = -2.5f;
uniform float Cloud_ShapeFactor < ui_category="Cloud Shape & Noise"; ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_step=0.01; ui_label="Cloud Central Shape Factor"; > = 0.2f;
uniform float Cloud_BaseDensityOffset < ui_category="Cloud Shape & Noise"; ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_step=0.01; ui_label="Cloud Base Density Offset"; > = 0.25f;

// --- Cloud Lighting & Color ---
uniform float Cloud_ColoringDensityMin < ui_category="Cloud Lighting & Color"; ui_type="drag"; ui_min=0.0; ui_max=2.0; ui_step=0.01; ui_label="Min Density for Coloring"; > = 0.6f;
uniform float3 Cloud_PaletteBase < ui_category="Cloud Lighting & Color"; ui_type="color"; ui_label="Palette Base Vector"; > = float3(5.0, 0.4, 0.2);
uniform float Cloud_PaletteShapeInfluence < ui_category="Cloud Lighting & Color"; ui_type="drag"; ui_min=0.0; ui_max=0.5; ui_step=0.001; ui_label="Palette Shape Influence (mpv.y)"; > = 0.1f;
uniform float Cloud_PaletteDepthInfluence < ui_category="Cloud Lighting & Color"; ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_step=0.01; ui_label="Palette Depth Influence (sin strength)"; > = 0.5f;
uniform float Cloud_PaletteDepthFrequency < ui_category="Cloud Lighting & Color"; ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_step=0.01; ui_label="Palette Depth Frequency"; > = 0.4f;
uniform float Cloud_PalettePhase < ui_category="Cloud Lighting & Color"; ui_type="drag"; ui_min=0.0; ui_max=5.0; ui_step=0.01; ui_label="Palette Phase Offset"; > = 1.8f;
uniform float Cloud_StepOpacity < ui_category="Cloud Lighting & Color"; ui_type="drag"; ui_min=0.01; ui_max=0.5; ui_step=0.001; ui_label="Cloud Step Opacity"; > = 0.08f;
uniform float Shading_Strength < ui_category="Cloud Lighting & Color"; ui_type="drag"; ui_min=0.0; ui_max=3.0; ui_step=0.01; ui_label="Self-Shadowing/Shading Strength"; > = 1.0;

// --- Fog & Post FX ---
uniform float Fog_Density < ui_category="Fog & Post FX"; ui_type="drag"; ui_min=0.0; ui_max=0.5; ui_step=0.001; ui_label="Fog Density"; > = 0.2f;
uniform float Fog_StartFactor < ui_category="Fog & Post FX"; ui_type="drag"; ui_min=0.0; ui_max=5.0; ui_step=0.01; ui_label="Fog Start Factor"; > = 2.2f;
uniform float4 Fog_ColorAndAlpha < ui_category="Fog & Post FX"; ui_type="coloralpha"; ui_label="Fog Color & Opacity"; > = float4(0.06,0.11,0.11, 0.1);
uniform float3 ColorGrade_Power < ui_category="Fog & Post FX"; ui_type="drag"; ui_min=0.1; ui_max=2.0; ui_step=0.01; ui_label="Color Grading Power"; > = float3(0.55,0.65,0.6);
uniform float3 ColorGrade_Multiplier < ui_category="Fog & Post FX"; ui_type="drag"; ui_min=0.5; ui_max=1.5; ui_step=0.01; ui_label="Color Grading Multiplier"; > = float3(1.0,0.97,0.9);
uniform float Vignette_Power < ui_category="Fog & Post FX"; ui_type="drag"; ui_min=0.01; ui_max=0.5; ui_step=0.001; ui_label="Vignette Power"; > = 0.12f;
uniform float Vignette_EdgeBrightness < ui_category="Fog & Post FX"; ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_step=0.01; ui_label="Vignette Edge Brightness"; > = 0.3f;
uniform float Vignette_CenterBoost < ui_category="Fog & Post FX"; ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_step=0.01; ui_label="Vignette Center Boost"; > = 0.7f;


// ============================================================================
// UI DECLARATIONS
// ============================================================================

// Tunable Constants
uniform float Light_DistanceOffset < ui_type = "slider"; ui_label = "Light Distance Offset"; ui_min = 0.0; ui_max = 10.0; ui_step = 0.1; ui_category = "Lighting"; > = 2.5;

//--------------------------------------------------------------------------------------
// HELPER FUNCTIONS
//--------------------------------------------------------------------------------------
float2x2 rot(float a) { // Removed 'in'
    float c = cos(a); float s = sin(a);
    return float2x2(c, s, -s, c);
}
static const float3x3 m3 = float3x3(0.33338f,0.56034f,-0.71817f,-0.87887f,0.32651f,-0.15323f,0.15162f,0.69596f,0.61339f) * 1.93f;
float mag2(float2 p) { return dot(p,p); }
float linstep(float mn, float mx, float x) { return saturate((x-mn)/(mx-mn)); } // Removed 'in'
float2 disp(float t, float sway_freq_scale) { 
    return float2(sin(t * 0.22f * sway_freq_scale), cos(t * 0.175f * sway_freq_scale)) * 2.0f; 
}

float2 map(float3 p) { // Removed 'in', uses g_iTime_global_for_map, g_prm1, g_bsMo_NoMouse
    float3 p2 = p;
    p2.xy -= disp(p.z, 1.0f).xy; 
    p.xy = mul(p.xy, rot(sin(p.z + g_iTime_global_for_map) * (0.1f + g_prm1 * 0.05f) + g_iTime_global_for_map * Scene_InternalRotationSpeedFactor));
    float cl = mag2(p2.xy);
    float d = 0.0f;
    p *= Cloud_OverallScale;
    float z_iter = 1.0f;
    float trk = 1.0f;
    float dspAmp = Cloud_NoiseDisplacementBase + g_prm1 * Cloud_NoisePrm1Influence;

    for(int i = 0; i < Noise_Octaves; i++) {
        p += sin(p.zxy * Cloud_NoiseFrequencyBase * trk + g_iTime_global_for_map * trk * Cloud_NoiseTimeInfluence) * dspAmp;
        d -= abs(dot(cos(p), sin(p.yzx)) * z_iter);
        z_iter *= Cloud_NoiseAmplitudeDecay;
        trk *= Cloud_NoiseFreqLacunarity;
        p = mul(p, m3);
    }
    d = abs(d + g_prm1 * 3.0f) + g_prm1 * 0.3f + Cloud_DensityBias + g_bsMo_NoMouse.y; 
    return float2(d + cl * Cloud_ShapeFactor + Cloud_BaseDensityOffset, cl);
}

float4 render(float3 ro, float3 rd, float time_for_render_logic) { // Removed 'in'
    float4 rez = 0.0f.xxxx; 
    float3 lpos = float3(disp(time_for_render_logic + Light_DistanceOffset, 1.0f) * 0.5f, time_for_render_logic + Light_DistanceOffset);
    float t = 1.5f; 
    float fogT = 0.0f; 

    [loop]
    for(int i=0; i < Raymarch_Steps; i++) {
        if(rez.a > 0.99f) break;
        float3 pos = ro + t*rd;
        float2 mpv = map(pos);
        float den = saturate(mpv.x - 0.3f) * 1.12f; 
        float dn = clamp(mpv.x + 2.0f,0.0f,3.0f); 
        
        float4 col_step = 0.0f.xxxx;
        if (mpv.x > Cloud_ColoringDensityMin) {
            col_step = float4(sin(Cloud_PaletteBase + mpv.y * Cloud_PaletteShapeInfluence + sin(pos.z * Cloud_PaletteDepthFrequency) * Cloud_PaletteDepthInfluence + Cloud_PalettePhase) * 0.5f + 0.5f, Cloud_StepOpacity);
            col_step *= den*den*den;
            col_step.rgb *= linstep(4.0f, -2.5f, mpv.x) * 2.3f; 
            
            float dif = saturate((den - map(pos + 0.8f).x) / 9.0f); 
            dif += saturate((den - map(pos + 0.35f).x) / 2.5f);     
            dif *= Shading_Strength;

            float3 shading_color_term1 = float3(0.005f,0.045f,0.075f); 
            float3 shading_color_term2 = float3(0.033f,0.07f,0.03f);   
            col_step.xyz *= den*(shading_color_term1 + 1.5f * shading_color_term2 * dif); 
        }
        
        float fogC = exp(t * Fog_Density - Fog_StartFactor);
        col_step += Fog_ColorAndAlpha * saturate(fogC - fogT);
        fogT = fogC;
        rez += col_step * (1.0f - rez.a);
        t += clamp(0.5f - dn * dn * DynamicStep_DensityInfluence, DynamicStep_Min, DynamicStep_Max); 
        if (t > 50.0f) break; // Safety clip, original had no explicit far clip in render loop
    }
    return saturate(rez);
}

float getsat(float3 c) { float mi=min(min(c.x,c.y),c.z); float ma=max(max(c.x,c.y),c.z); return (ma-mi)/(ma+AS_EPSILON); }
float3 iLerp(float3 a, float3 b, float x) { // Removed 'in' 
    float3 ic = lerp(a,b,x)+float3(1e-6f,0,0); 
    float sd=abs(getsat(ic)-lerp(getsat(a),getsat(b),x)); 
    float3 dir=normalize(float3(2.*ic.x-ic.y-ic.z,2.*ic.y-ic.x-ic.z,2.*ic.z-ic.y-ic.x)+AS_EPSILON.xxx); 
    float lgt=dot(1.0f.xxx,ic); 
    float ff=dot(dir,normalize(ic+AS_EPSILON.xxx)); 
    ic+=1.5f*dir*sd*ff*lgt; return saturate(ic); 
}

//--------------------------------------------------------------------------------------
// Main Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS_ProteanClouds(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float2 R_Screen = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float master_time = AS_getAnimationTime(MasterTimeSpeed, MasterTimeKeyframe); 

    g_iTime_global_for_map = master_time; 
    g_bsMo_NoMouse = float2(0.0, 0.0); 
    g_prm1 = smoothstep(-0.4f, 0.4f, sin(master_time * Prm1_AnimationSpeedFactor)); 
    
    float2 q_norm_uv = texcoord; 
    float2 p_centered_uv = (vpos.xy - 0.5f * R_Screen) / R_Screen.y; 
    
    float time_for_main_logic = master_time * Camera_PathSpeedFactor; 
    
    float3 ro = float3(0.0f, 0.0f, time_for_main_logic); 
    ro += float3(sin(master_time) * 0.5f, 0.0f, 0.0f); 
        
    float dspAmp_cam = Camera_SwayAmplitude; 
    ro.xy += disp(ro.z * Camera_SwayFrequencyFactor, 1.0f) * dspAmp_cam; 

    float tgtDst = 3.5f; 
    float3 target_pt = float3(disp(time_for_main_logic + tgtDst, Camera_SwayFrequencyFactor)*dspAmp_cam, time_for_main_logic + tgtDst);
    float3 target_vec = normalize(ro - target_pt); 

    float3 rightdir = normalize(cross(target_vec, float3(0,1,0)));
    if (abs(dot(target_vec, float3(0,1,0))) > 0.999f) rightdir = float3(1,0,0);
    float3 updir = normalize(cross(rightdir, target_vec));
    
    float3 rd=normalize((p_centered_uv.x*rightdir + p_centered_uv.y*updir)*Camera_FOV_Effect - target_vec);
    
    rd.xy = mul(rd.xy, rot(-disp(g_iTime_global_for_map + 3.5f, 1.0f).x * RayDir_RotationStrength)); 

    float4 scn = render(ro, rd, time_for_main_logic); 
        
    float3 col = scn.rgb;
    col = iLerp(col.bgr, col.rgb, saturate(1.0f - g_prm1)); 
    
    col = pow(col, ColorGrade_Power) * ColorGrade_Multiplier;

    float vignette_mask_shape = pow(16.0f * q_norm_uv.x * q_norm_uv.y * (1.0f - q_norm_uv.x) * (1.0f - q_norm_uv.y), Vignette_Power);
    col *= lerp(Vignette_EdgeBrightness, Vignette_EdgeBrightness + Vignette_CenterBoost, vignette_mask_shape);
    
    return float4(col, 1.0f);
}

//--------------------------------------------------------------------------------------
// Technique Definition
//--------------------------------------------------------------------------------------
technique ProteanClouds_Artist_V2 // Incremented version name
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_ProteanClouds;
    }
}


#endif // __AS_BGX_ProteanClouds_1_fx