#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // Custom header for AS utilities

// Define PI and TAU locally for this shader
#define LOCAL_PI 3.141592654f
#define LOCAL_TAU (2.0f * LOCAL_PI)

// Rotation matrix macro for HLSL
#define ROT(a) float2x2(cos(a), sin(a), -sin(a), cos(a))

namespace LogarithmicSpiralsArtistic {

// Global constants (ExpBy will now depend on a uniform)
static const float ALPHA_EPSILON = 0.00001f; // For safe division

//------------------------------------------------------------------------------------------------
// Artistic Control Uniforms
//------------------------------------------------------------------------------------------------
uniform float AnimationScale < ui_type="slider"; ui_label="Animation Scale"; ui_min=0.0; ui_max=2.0; ui_step=0.01; ui_tooltip="Overall speed of all time-based animations."; > = 0.75;
uniform float SpiralExpansionRate < ui_type="slider"; ui_label="Spiral Expansion Rate"; ui_min=1.01; ui_max=2.5; ui_step=0.01; ui_tooltip="Controls how rapidly spirals expand/contract. Original: 1.2"; > = 1.2;

uniform float TransformSpeed1 < ui_type="slider"; ui_label="Transform Animation Speed 1"; ui_min=0.0; ui_max=1.0; ui_step=0.01; > = 0.12;
uniform float TransformSpeed2 < ui_type="slider"; ui_label="Transform Animation Speed 2"; ui_min=0.0; ui_max=1.0; ui_step=0.01; > = 0.23;

uniform float GlobalRotationSpeed < ui_type="slider"; ui_label="Global Rotation Speed"; ui_min=-0.5; ui_max=0.5; ui_step=0.005; > = -0.125;
uniform float ArmTwistFactor < ui_type="slider"; ui_label="Spiral Arm Twist Factor"; ui_min=0.0; ui_max=2.0; ui_step=0.01; > = 0.66;

uniform float ColorHueFactor < ui_type="slider"; ui_label="Primary Color Hue Factor"; ui_min=0.0; ui_max=2.0; ui_step=0.01; > = 0.85;
uniform float GlowColorIntensity < ui_type="slider"; ui_label="Ambient Glow Intensity"; ui_min=0.0; ui_max=0.1; ui_step=0.001; > = 0.01;
uniform float FadeCycleSpeed < ui_type="slider"; ui_label="Sphere Fade Cycle Speed"; ui_min=0.0; ui_max=1.0; ui_step=0.01; > = 0.33;

uniform float SphereBaseRadiusScale < ui_type="slider"; ui_label="Sphere Base Radius Scale"; ui_min=0.01; ui_max=0.5; ui_step=0.005; > = 0.125;
uniform float SphereFadeRadiusScale < ui_type="slider"; ui_label="Sphere Fade Radius Scale"; ui_min=0.0; ui_max=1.0; ui_step=0.01; ui_tooltip="Max radius additional scale based on fade (added to base)"; > = 0.375; // Orig max was 0.5, so 0.125 + 0.375 = 0.5

uniform float SpecularPower < ui_type="slider"; ui_label="Specular Power"; ui_min=1.0; ui_max=64.0; ui_step=1.0; > = 10.0;
uniform float SpecularIntensity < ui_type="slider"; ui_label="Specular Intensity"; ui_min=0.0; ui_max=2.0; ui_step=0.01; > = 0.5;
uniform float AmbientLightLevel < ui_type="slider"; ui_label="Ambient Light Level (Sphere)"; ui_min=0.0; ui_max=1.0; ui_step=0.01; > = 0.2;

uniform float OutputBrightness < ui_type="slider"; ui_label="Output Brightness Boost"; ui_min=0.1; ui_max=5.0; ui_step=0.01; > = 1.5;
uniform float DetailGlowStrength < ui_type="slider"; ui_label="Detail-based Glow Strength"; ui_min=0.0; ui_max=50.0; ui_step=0.1; > = 10.0;


// Helper Functions (Translated from GLSL)
float modPolar(inout float2 p, float repetitions) {
    if (abs(repetitions) < ALPHA_EPSILON) repetitions = sign(repetitions) * ALPHA_EPSILON;
    float angle = LOCAL_TAU / repetitions;
    float a = atan2(p.y, p.x) + angle / 2.0f;
    float r = length(p);
    float c = floor(a / angle);
    a = AS_mod(a, angle); 
    a = a - angle / 2.0f;
    p = float2(cos(a), sin(a)) * r;
    if (abs(c) >= (repetitions / 2.0f)) c = abs(c);
    return c;
}

float forward_exp(float l, float exp_base) { // Pass expansion base
    return exp2(log2(exp_base) * l);
}

float reverse_exp(float l, float exp_base) { // Pass expansion base
    if (abs(l) < ALPHA_EPSILON && l <= 0.0f) l = ALPHA_EPSILON;
    else if (abs(l) < ALPHA_EPSILON) l = ALPHA_EPSILON;
    float log2_exp_base = log2(exp_base);
    if (abs(log2_exp_base) < ALPHA_EPSILON) return l / (sign(log2_exp_base) * ALPHA_EPSILON);
    return log2(l) / log2_exp_base;
}

float3 pow_f3_f1(float3 base, float exponent) { return float3(pow(base.x, exponent), pow(base.y, exponent), pow(base.z, exponent)); }

float3 sphere(float3 col, float2x2 rot_matrix, float3 bcol, float2 p_sphere, float r_sphere, float aa_sphere,
              float in_spec_power, float in_spec_intensity, float in_ambient_level, float tanh_bcol_factor) { // Added new params
    float3 lightDir = normalize(float3(1.0f, 1.5f, 2.0f)); // Could be uniforms
    lightDir.xy = mul(rot_matrix, lightDir.xy); 
    float r_sq = r_sphere * r_sphere;
    float p_dot_p = dot(p_sphere, p_sphere);
    float z2 = r_sq - p_dot_p;
    float3 rd_norm = -normalize(float3(p_sphere, 0.1f)); // 0.1f could be uniform "Reflection Z"

    if (z2 > 0.0f) {
        float z = sqrt(z2);
        float3 cp = float3(p_sphere, z);
        float3 cn = normalize(cp);
        float3 cr = reflect(rd_norm, cn);
        float cd = max(dot(lightDir, cn), 0.0f);
        
        float3 cspe = pow_f3_f1(max(dot(lightDir, cr), 0.0f).xxx, in_spec_power) * tanh(tanh_bcol_factor * bcol) * in_spec_intensity;

        float3 ccol = lerp(in_ambient_level.xxx, 1.0f.xxx, cd * cd) * bcol;
        ccol += cspe;
        float d_dist = length(p_sphere) - r_sphere;

        if (aa_sphere > ALPHA_EPSILON) {
             col = lerp(col, ccol, 1.0f - smoothstep(-aa_sphere, 0.0f, d_dist));
        } else { 
             col = lerp(col, ccol, d_dist < 0.0f ? 1.0f : 0.0f);
        }
    }
    return col;
}

float2 toSmith(float2 p_smith) { /* ... same ... */ float d_s=(1.f-p_smith.x)*(1.f-p_smith.x)+p_smith.y*p_smith.y; d_s=abs(d_s)<ALPHA_EPSILON?sign(d_s)*ALPHA_EPSILON:d_s; return float2((1.f+p_smith.x)*(1.f-p_smith.x)-p_smith.y*p_smith.y,2.f*p_smith.y)/d_s; }
float2 fromSmith(float2 p_smith) { /* ... same, corrected ... */ float d_s=(p_smith.x+1.f)*(p_smith.x+1.f)+p_smith.y*p_smith.y; d_s=abs(d_s)<ALPHA_EPSILON?sign(d_s)*ALPHA_EPSILON:d_s; return float2((p_smith.x+1.f)*(p_smith.x-1.f)+p_smith.y*p_smith.y,2.f*p_smith.y)/d_s; }

float2 transform_coords(float2 p_in, float time_param, float speed1, float speed2) { // Added speed params
    float2 p_transformed = p_in;
    float2 const_vec_one = float2(1.0f, 1.0f);
    float2 sp0 = toSmith(p_transformed);
    float2 sp1 = toSmith(p_transformed + mul(ROT(speed1 * time_param), const_vec_one));
    float2 sp2 = toSmith(p_transformed - mul(ROT(speed2 * time_param), const_vec_one));
    p_transformed = fromSmith(sp0 + sp1 - sp2);
    return p_transformed;
}

float3 sRGB_convert(float3 t) { /* ... same ... */ t=max(t,0.f); float3 p=float3(pow(t.x,1.f/2.4f),pow(t.y,1.f/2.4f),pow(t.z,1.f/2.4f)); float3 l=12.92f*t; float3 nl=1.055f*p-0.055f; return float3(t.x<0.0031308f?l.x:nl.x,t.y<0.0031308f?l.y:nl.y,t.z<0.0031308f?l.z:nl.z); }
float3 aces_approx_convert(float3 v) { /* ... same ... */ v=max(v,0.f); v*=0.6f; float a=2.51f,b=0.03f,c=2.43f,d=0.59f,e=0.14f; float3 num=v*(a*v+b); float3 den=v*(c*v+d)+e; den=float3(abs(den.x)<ALPHA_EPSILON?sign(den.x)*ALPHA_EPSILON:den.x,abs(den.y)<ALPHA_EPSILON?sign(den.y)*ALPHA_EPSILON:den.y,abs(den.z)<ALPHA_EPSILON?sign(den.z)*ALPHA_EPSILON:den.z); return saturate(num/den); }

// Main rendering logic function, now using uniforms
float3 effect_render(float2 p_eff, float time_eff, 
                     float anim_scale, float spiral_exp_rate, float trans_speed1, float trans_speed2,
                     float global_rot_speed, float arm_twist_factor, float color_hue_factor,
                     float glow_intensity, float fade_speed, float sphere_base_r, float sphere_fade_r_scale,
                     float spec_pow, float spec_intens, float ambient_lvl,
                     float output_bright, float detail_glow_str)
{
    float2 p_initial_transformed = transform_coords(p_eff, time_eff * anim_scale, trans_speed1, trans_speed2);
    float2 np_eff = p_eff + float2(ReShade::PixelSize.x, ReShade::PixelSize.y);
    float2 ntp_eff = transform_coords(np_eff, time_eff * anim_scale, trans_speed1, trans_speed2);
    float aa = 2.0f * distance(p_initial_transformed, ntp_eff);
    
    float2 p_current = p_initial_transformed;

    float ltm = anim_scale * time_eff; // Was 0.75f * time_param, now controlled by anim_scale
    float2x2 rot0 = ROT(global_rot_speed * ltm);  
    p_current = mul(rot0, p_current);
    
    float mtm = frac(ltm);
    float ntm_floor = floor(ltm); // Renamed from ntm to avoid conflict
    float gd = dot(p_current, p_current);
    float zz = forward_exp(mtm, spiral_exp_rate); // Use uniform for expansion rate
    zz = abs(zz) < ALPHA_EPSILON ? sign(zz) * ALPHA_EPSILON : zz;

    float2 p0 = p_current / zz;
    float l0 = length(p0);
      
    float n0_val = ceil(reverse_exp(max(l0, ALPHA_EPSILON), spiral_exp_rate));
    float r0 = forward_exp(n0_val, spiral_exp_rate);
    float r1 = forward_exp(n0_val - 1.0f, spiral_exp_rate);
    float r_avg = (r0 + r1) / 2.0f;
    float w = r0 - r1;
    n0_val -= ntm_floor;

    float2 p1 = p0;
    float reps_calc = floor(LOCAL_TAU * r_avg / (w + ALPHA_EPSILON));
    reps_calc = max(reps_calc, 1.0f);
        
    float2x2 rot1 = ROT(arm_twist_factor * n0_val);  
    p1 = mul(rot1, p1);
    float m1_polar = modPolar(p1, reps_calc); // p1 is inout
    if (abs(reps_calc) > ALPHA_EPSILON) m1_polar /= reps_calc; else m1_polar = 0.0f;
    p1.x -= r_avg;
    
    float3 ccol = (1.0f + cos(color_hue_factor * float3(0.0f, 1.0f, 2.0f) + LOCAL_TAU * (m1_polar) + 0.5f * n0_val)) * 0.5f;
    float3 gcol = (1.0f + cos(float3(0.0f, 1.0f, 2.0f) + global_rot_speed * 0.5f * ltm)) * glow_intensity; // Used global_rot_speed for glow color variation speed
    float2x2 rot2 = ROT(LOCAL_TAU * m1_polar);

    float3 col_out = float3(0.0f, 0.0f, 0.0f);
    float fade = 0.5f + 0.5f * cos(LOCAL_TAU * m1_polar + fade_speed * ltm);
    
    float2x2 combined_rotation = mul(mul(rot0, rot1), rot2);

    // Calculate sphere radius based on uniforms
    float current_sphere_radius = lerp(sphere_base_r, sphere_base_r + sphere_fade_r_scale, fade) * w;

    col_out = sphere(col_out, combined_rotation, ccol * lerp(0.25f, 1.0f, sqrt(saturate(fade))), 
                     p1, current_sphere_radius, aa / zz,
                     spec_pow, spec_intens, ambient_lvl, 8.0f); // Pass 8.0f for tanh_bcol_factor, could be uniform
    col_out *= output_bright;
    col_out += gcol / max(gd, 0.001f);
    float aa_glow_val = aa * detail_glow_str; // Use DetailGlowStrength
    // Prevent aa_glow_val from becoming excessively huge if aa is large (e.g. on first frame or view change)
    aa_glow_val = min(aa_glow_val, glow_intensity * 100.0f); // Cap relative to glow_intensity
    col_out += gcol * aa_glow_val;


    col_out = aces_approx_convert(col_out);
    col_out = sRGB_convert(col_out);

    return col_out;
}

// Main Pixel Shader
float4 MinimalLogSpiralsPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target0
{
    float2 p_transformed_uv = (texcoord * 2.0f - 1.0f); 
    p_transformed_uv.x *= ReShade::ScreenSize.x / ReShade::ScreenSize.y; 

    float3 col = effect_render(
        p_transformed_uv, 
        AS_getTime(), // Base time
        AnimationScale, SpiralExpansionRate, TransformSpeed1, TransformSpeed2,
        GlobalRotationSpeed, ArmTwistFactor, ColorHueFactor, GlowColorIntensity,
        FadeCycleSpeed, SphereBaseRadiusScale, SphereFadeRadiusScale,
        SpecularPower, SpecularIntensity, AmbientLightLevel,
        OutputBrightness, DetailGlowStrength
    );

    return float4(col, 1.0f);
}

technique MinimalLogarithmicSpirals_Artistic_Tech < // Renamed Technique
    ui_label = "[AS] Logarithmic Spirals (Artistic)";
    ui_tooltip = "Artistic Logarithmic Spirals by nmz/stormoid, with exposed controls.\nOriginal: https://www.shadertoy.com/view/NdfyRM";
> {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = MinimalLogSpiralsPS;
    }
}

} // end namespace LogarithmicSpiralsArtistic