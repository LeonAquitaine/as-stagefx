/**
 * Basic Translation: Shine On by emodeman
 * Source: https://www.shadertoy.com/view/st23zw
 * License: CC BY-NC-SA 3.0
 * Added Zoom slider. Restored pow() operation with tunable exponent scale.
 */

#include "ReShade.fxh" 

// --- Uniforms ---
uniform float Timer < source = "timer"; >;

// --- Tunable Parameters ---
uniform float UI_Zoom < ui_type="drag"; ui_label="Zoom"; ui_tooltip="Zoom factor for the noise pattern. >1 zooms in, <1 zooms out."; ui_min=0.1; ui_max=5.0; ui_step=0.01; > = 1.0f; // <<< NEW ZOOM PARAMETER
uniform float UI_Anim_Speed < ui_type="drag"; ui_label="Animation Speed"; ui_min=0.0; ui_max=2.0; ui_step=0.01; > = 0.5f; 
uniform int UI_Crystal_Iterations < ui_type="slider"; ui_label="Crystal Iterations"; ui_min=1; ui_max=30; > = 14;
uniform float UI_Crystal_Step < ui_type="slider"; ui_label="Crystal Loop Step"; ui_min=1.0; ui_max=10.0; ui_step=0.1; > = 4.5f;
uniform float UI_Crystal_SizeFactor < ui_type="slider"; ui_label="Crystal Size Factor"; ui_format="%.4f"; ui_min=0.0001; ui_max=0.01; ui_step=0.0001; > = 0.003f;
uniform float UI_Crystal_Amp < ui_type="slider"; ui_label="Crystal Color Amp/Offset"; ui_min=0.1; ui_max=1.5; ui_step=0.05; > = 0.75f;
uniform float UI_Crystal_Radius < ui_type="slider"; ui_label="Crystal Point Radius"; ui_min=0.0; ui_max=50.0; ui_step=0.5; > = 5.0f; 
uniform float UI_Crystal_RangeOffset < ui_type="slider"; ui_label="Crystal Range Offset"; ui_min=0.0; ui_max=300.0; ui_step=1.0; > = 60.0f;
uniform float UI_Crystal_TimeFactor < ui_type = "slider"; ui_label = "Crystal Time Speed Factor"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.05; > = 1.0f; 
uniform int UI_FBM_Octaves < ui_type="slider"; ui_label="FBM Octaves"; ui_min=1; ui_max=28; > = 8;
uniform float UI_FBM_AmpDecay < ui_type="slider"; ui_label="FBM Amp Decay (Persistence)"; ui_min=0.5; ui_max=0.95; ui_step=0.01; > = 0.80f;
uniform float UI_FBM_FreqInc < ui_type="slider"; ui_label="FBM Freq Increase (Lacunarity)"; ui_min=1.0; ui_max=2.0; ui_step=0.01; > = 1.20f;
uniform int UI_FBMLow_Octaves < ui_type="slider"; ui_label="FBM Low Octaves"; ui_min=1; ui_max=8; > = 4;
uniform float UI_Main_TimeScale < ui_type="slider"; ui_label="Main Noise Time Scale"; ui_min=0.0; ui_max=1.0; ui_step=0.01; > = 0.1f;
uniform float UI_Main_UVScale1 < ui_type="slider"; ui_label="Main UV Scale 1 (rv)"; ui_min=0.5; ui_max=5.0; ui_step=0.1; > = 2.5f;
uniform float UI_Main_UVScale2 < ui_type="slider"; ui_label="Main UV Scale 2 (rv)"; ui_min=5.0; ui_max=60.0; ui_step=1.0; > = 30.0f;
uniform float UI_Main_UVScale3 < ui_type="slider"; ui_label="Main UV Scale 3 (fbm1)"; ui_min=0.5; ui_max=4.0; ui_step=0.1; > = 2.0f;
uniform float UI_Main_UVScale4 < ui_type = "slider"; ui_label = "Main UV Scale 4 (fbm2)"; ui_min = 1.0; ui_max = 16.0; ui_step = 0.5; > = 8.0f;
uniform float UI_Main_RandMix < ui_type="slider"; ui_label="Main Noise Mix Factor"; ui_min=0.0; ui_max=0.1; ui_step=0.001; ui_format="%.3f";> = 0.02f;
uniform float UI_ColorScale1 < ui_type="slider"; ui_label="Main Color Scale 1"; ui_min=0.5; ui_max=3.0; ui_step=0.05; > = 1.6f;
uniform float UI_ColorScale2 < ui_type="slider"; ui_label="Main Color Scale 2"; ui_min=1.0; ui_max=6.0; ui_step=0.1; > = 3.8f;
uniform float UI_SmoothstepMin < ui_type="slider"; ui_label="Main Contrast Min"; ui_min=0.0; ui_max=0.9; ui_step=0.01; > = 0.18f;
uniform float UI_SmoothstepMax < ui_type="slider"; ui_label="Main Contrast Max"; ui_min=0.1; ui_max=1.0; ui_step=0.01; > = 0.88f;
uniform float UI_PowExponentScale < ui_type="slider"; ui_label="Pow Exponent Scale"; ui_tooltip="Scales the exponent vector derived from crystal(). Affects brightness/color."; ui_min=0.01; ui_max=5.0; ui_step=0.01; > = 1.0f; 

// --- Internal Constants ---
static const float PI = 3.14159265f;
static const float EPSILON = 1e-5f;
static const float3 NOISE_DOT_VEC1 = float3(12.9898f, 78.233f, 37.429f); 
static const float NOISE_DOT_VEC2_X = 12.9898f; 
static const float NOISE_DOT_VEC2_Y = 78.233f; 
static const float NOISE_MAGIC1 = 43758.5453f;
static const float NOISE_P_Y_FACTOR = 57.0f;
static const float NOISE_P_Z_FACTOR = 113.0f;

// --- Helper Functions ---
// (Keep all helper functions: MIX, CV, crystal, rot2d, r, h, noise, dnoise2f, fbm, fbmLow - exactly as before)
float3 MIX(float3 x, float3 y) { return abs(x - y); } 
float2x2 rot2d(float angle) { float c = cos(angle); float s = sin(angle); return float2x2(c, -s, s, c); }
float r(float a, float b) { return frac(sin(dot(float2(a, b), float2(NOISE_DOT_VEC2_X, NOISE_DOT_VEC2_Y))) * NOISE_MAGIC1); }
float h(float n) { return frac(sin(n) * NOISE_MAGIC1); }
float noise(float3 x) { 
    float3 p  = floor(x); float3 f  = frac(x); f = f * f * (3.0f - 2.0f * f); 
    float n = p.x + p.y * NOISE_P_Y_FACTOR + NOISE_P_Z_FACTOR * p.z;
    float v00 = lerp(h(n + 0.0f), h(n + 1.0f), f.x); float v10 = lerp(h(n + 57.0f), h(n + 58.0f), f.x);
    float v01 = lerp(h(n + 113.0f), h(n + 114.0f), f.x); float v11 = lerp(h(n + 170.0f), h(n + 171.0f), f.x); 
    return lerp(lerp(v00, v10, f.y), lerp(v01, v11, f.y), f.z); }
float3 dnoise2f(float2 p) {
    float i = floor(p.x), j = floor(p.y); float u = frac(p.x), v = frac(p.y); 
    float du = 30.0f * u * u * (u * (u - 2.0f) + 1.0f); float dv = 10.0f * v * v * (v * (v - 2.0f) + 1.0f); 
    float u_interp = u*u*u*(u*(u*6.0f - 15.0f)+10.0f); float v_interp = v*v*v*(v*(v*6.0f - 15.0f)+10.0f);
    float a = r(i, j); float b = r(i + 1.0f, j); float c = r(i, j + 1.0f); float d = r(i + 1.0f, j + 1.0f);
    float k0 = a; float k1 = b - a; float k2 = c - a; float k3 = a - b - c + d; 
    float value = k0 + k1 * u_interp + k2 * v_interp + k3 * u_interp * v_interp;
    float dValue_du = du * (k1 + k3 * v_interp); float dValue_dv = dv * (k2 + k3 * u_interp); 
    return float3(value, dValue_du, dValue_dv); }
float fbm(float2 uv, float iTime, const int octaves, const float amplitude_decay, const float frequency_increase) {            
    float2 p = uv; float f = 0.0f, dx = 0.0f, dz = 0.0f, w = 0.5f; 
    [loop] for (int i = 0; i < octaves; ++i) { float3 n = dnoise2f(uv); dx += n.y; dz += n.z;
        f += w * n.x / (1.0f + dx * dx + dz * dz); w *= amplitude_decay; uv *= frequency_increase; 
        float rot_angle = 1.25f * noise(float3(p * 0.1f, 0.12f * iTime)) + 0.75f * noise(float3(p * 0.1f, 0.20f * iTime)); 
        uv = mul(uv, rot2d(rot_angle)); } return f; }
float fbmLow(float2 uv, const int octaves) { 
    float f = 0.0f, dx = 0.0f, dz = 0.0f, w = 0.5f; 
    const float amplitude_decay = 0.75f; const float frequency_increase = 1.5f; 
    [loop] for (int i = 0; i < octaves; ++i) { float3 n = dnoise2f(uv); dx += n.y; dz += n.z;
        f += w * n.x / (1.0f + dx * dx + dz * dz); w *= amplitude_decay; uv *= frequency_increase; } return f; }
float CV(float3 c, float2 uv, float2 iResolution, const float crystal_size_factor, const float crystal_radius) {
    float size = 640.0f / iResolution.x * crystal_size_factor; 
    return 1.0f - saturate(size * (length(c.xy - uv) - crystal_radius)); }
float3 crystal(float2 fc, float iTime, float2 iResolution, 
                 const int crystal_iterations, const float crystal_step, 
                 const float crystal_size_factor, const float crystal_time_factor, 
                 const float crystal_amp, const float crystal_radius, 
                 const float crystal_range_offset) {
    float3 O = 0.0f; float3 c_color;
    float z_time = iTime * crystal_time_factor; 
    int iter_count = 0;
    [loop] for (float i = 0.0f; iter_count < crystal_iterations; i += crystal_step, ++iter_count) { 
        c_color = float3(sin(i * 0.57f +  7.0f + z_time * 0.70f), sin(i * 0.59f - 15.0f - z_time * 0.65f), sin(i * 0.60f + z_time * 0.90f)) * crystal_amp + crystal_amp; 
        float range_x = iResolution.x / 2.0f - crystal_range_offset; float range_y = iResolution.y / 2.0f - crystal_range_offset;
        float center_x = iResolution.x / 2.0f; float center_y = iResolution.y / 2.0f;
        float2 circle_center = float2(sin(z_time * 0.50f + i / 4.5f) * range_x + center_x, sin(z_time * 0.73f + i / 3.0f) * range_y + center_y);
        float cv_mask = CV(float3(circle_center, crystal_radius), fc, iResolution, crystal_size_factor, crystal_radius);
        O = MIX(O, c_color * cv_mask); } return O; }

// --- Main Pixel Shader ---
float4 ShineOnPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    float iTime = Timer / 1000.0f * UI_Anim_Speed; 
    float2 iResolution = ReShade::ScreenSize;
    float2 fragCoord = vpos.xy;

    // Coordinate setup
    float2 uv = float2(texcoord.x * 2.0f - 1.0f, (1.0f - texcoord.y) * 2.0f - 1.0f);
    float aspect = iResolution.x / iResolution.y;
    uv.y /= aspect; 

    // <<< Apply Zoom >>>
    uv *= UI_Zoom; 

    float t = iTime * UI_Main_TimeScale; 
    
    // rv calculation (uses zoomed uv)
    float denom_s = length(uv * UI_Main_UVScale1);
    float2 denom_v = uv * UI_Main_UVScale2;
    denom_s = max(denom_s, EPSILON);
    denom_v.x = sign(denom_v.x) * max(abs(denom_v.x), EPSILON);
    denom_v.y = sign(denom_v.y) * max(abs(denom_v.y), EPSILON);
    float2 rv = uv / (denom_s * denom_v); 

    float2 uv_rot1 = mul(uv, rot2d(0.3f * t)); // Uses zoomed uv
    
    float2 fbmLow_arg = float2(length(uv) - t, length(uv) - t) + rv; // Uses zoomed uv
    float fbm_low_val = fbmLow(fbmLow_arg, UI_FBMLow_Octaves); 
    
    float val_input_scale = UI_Main_UVScale3 * fbm_low_val;
    // Pass zoomed uv (via uv_rot1) and parameters to fbm
    float val = 0.5f * fbm(uv_rot1 * val_input_scale, iTime, UI_FBM_Octaves, UI_FBM_AmpDecay, UI_FBM_FreqInc); 

    float2 uv_rot2 = mul(uv, rot2d(-0.6f * t)); // Uses zoomed uv

    // Pass zoomed uv (via uv_rot2) and parameters to fbm
    float fc_fbm_val = fbm(uv_rot2 * val * UI_Main_UVScale4, iTime, UI_FBM_Octaves, UI_FBM_AmpDecay, UI_FBM_FreqInc); 
    // Pass zoomed uv (via uv_rot2) to r()
    float fc = 0.5f * fc_fbm_val + UI_Main_RandMix * r(uv_rot2.x, uv_rot2.y); 

    // Color transformations
    float3 fragC = UI_ColorScale1 * float3(fc, fc, fc); 
    fragC *= UI_ColorScale2;
    fragC = fragC / (1.0f + fragC); 
    fragC = smoothstep(UI_SmoothstepMin, UI_SmoothstepMax, fragC); 

    // Apply crystal pow modifier (crystal uses un-zoomed fragCoord)
    float3 crystal_mod = crystal(fragCoord, iTime, iResolution, 
                                  UI_Crystal_Iterations, UI_Crystal_Step, UI_Crystal_SizeFactor, 
                                  UI_Crystal_TimeFactor, 
                                  UI_Crystal_Amp, UI_Crystal_Radius, UI_Crystal_RangeOffset); 
    
    float3 crystal_exponent = max(crystal_mod * UI_PowExponentScale, EPSILON); 
    fragC = pow(fragC, crystal_exponent); 

    return float4(fragC, 1.0f); 
}


// --- Technique ---
technique ShineOn_Basic_Tunable < ui_label = "Shine On (Basic + Tunables)"; >
{
    pass
    {
        VertexShader = PostProcessVS; 
        PixelShader = ShineOnPS;
    }
}

/* // Standard ReShade Post Process Vertex Shader (if needed) ... */