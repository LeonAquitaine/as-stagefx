/**
 * AS_BGX_GoldenClockwork.1.fx - Intricate Golden Apollonian Fractal Background
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Based on "Golden apollian" by mrange
 * Shadertoy: https://www.shadertoy.com/view/WlcfRS
 * Original License: CC0
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Renders a mesmerizing and intricate animated background effect reminiscent of golden
 * clockwork mechanisms or Apollonian gasket-like fractal patterns. The effect features
 * complex, evolving geometric designs with a characteristic golden color palette.
 *
 * FEATURES:
 * - Procedurally generated Apollonian fractal patterns
 * - Dynamic animation driven by time
 * - Golden color scheme with lighting and shading effects
 * - Depth-like progression through fractal layers
 * - Kaleidoscopic and mirroring options for pattern variation
 * - Resolution-independent rendering
 * - UI controls for animation, palette, fractal/kaleidoscope parameters, audio reactivity, and blending
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. The core visual is an Apollonian gasket fractal, generated iteratively.
 * 2. Coordinates are transformed through polar conversions, rotations, and mirroring (kaleidoscope).
 * 3. A path function (`offset_path`) defines the camera's movement through the 3D fractal space over time.
 * 4. Multiple "planes" or layers of the fractal are raymarched and blended.
 * 5. Lighting is simulated with diffuse and specular-like components based on virtual light sources.
 * 6. Helper functions define shapes (circle, hex) and smooth operations (pmin, SABS).
 * 7. The final color is post-processed for gamma correction and vignetting.
 * 8. UI controls allow customization of animation speed, pathing, colors, fractal style, kaleidoscope, audio reactivity, and blending.
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_GoldenClockwork_1_fx
#define __AS_BGX_GoldenClockwork_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "AS_Utils.1.fxh" // Provides AS_getTime, AS_mod, AS_PI, AS_TWO_PI, etc.
#include "ReShade.fxh"    // Standard ReShade functions and uniforms (already implicitly included by AS_Utils)

//--------------------------------------------------------------------------------------
// Samplers
//--------------------------------------------------------------------------------------
sampler sBackBuffer { Texture = ReShade::BackBufferTex; SRGBTexture = true; }; // Not used in this shader, but standard

// ============================================================================
// CONSTANTS & MACROS (Replaces original COMMON section)
// ============================================================================
#define ROT(a)          float2x2(cos(a), sin(a), -sin(a), cos(a))
#define PSIN(x)         (0.5f + 0.5f * sin(x))
#define LESS(a, b, c)   lerp(a, b, step(0.0f, c))
#define SABS(x, k)      LESS((0.5f / (k)) * (x) * (x) + (k) * 0.5f, abs(x), abs(x) - (k))
#define L2(x)           dot(x, x)
#define PLANE_PERIOD    5.0f

static const float3 std_gamma   = float3(2.2f, 2.2f, 2.2f);
static float3 G_baseRingCol; // Will be initialized in PS_GoldenApollian from uniform

// Define individual const float4 "effect" style equivalents
// .x = lw, .y = tw, .z = sk, .w = cs
static const float4 EFFECT_STYLE_0 = float4(0.125f, 0.0f, 0.0f, 0.0f);
static const float4 EFFECT_STYLE_1 = float4(0.125f, 0.0f, 0.0f, 1.0f);
static const float4 EFFECT_STYLE_2 = float4(0.125f, 0.0f, 1.0f, 1.0f);
static const float4 EFFECT_STYLE_3 = float4(0.125f, 1.0f, 1.0f, 1.0f);
static const float4 EFFECT_STYLE_4 = float4(0.125f, 1.0f, 1.0f, 0.0f);
static const float4 EFFECT_STYLE_5 = float4(0.125f, 1.0f, 0.0f, 0.0f);

static const float4 g_gc_effectStyles[6] = { // Renamed from 'effects'
    EFFECT_STYLE_0, EFFECT_STYLE_1, EFFECT_STYLE_2, EFFECT_STYLE_3, EFFECT_STYLE_4, EFFECT_STYLE_5
};
static float4 g_gc_currentEffectStyle; // Renamed from 'current_effect_state'

// ============================================================================
// UI DECLARATIONS
// ============================================================================


// Palette & Style
uniform float3 BaseRingColor < ui_type = "color"; ui_label = "Base Ring Color"; ui_category = "Palette & Style"; > = float3(1.0f, 0.65f, 0.25f);
uniform float3 SunLightColor < ui_type = "color"; ui_label = "Sun Light Color"; ui_category = "Palette & Style"; > = float3(1.0f, 0.8f, 0.88f);
uniform float3 PlaneObjectColor < ui_type = "color"; ui_label = "Plane Object Color"; ui_category = "Palette & Style"; > = float3(1.0f, 1.2f, 1.5f);
uniform int EffectCycleMode < ui_type = "combo"; ui_label = "Effect Style"; ui_items = "Cycle Effects\0Style 1 (Thin Lines)\0Style 2 (Thin Lines + Center)\0Style 3 (Thin Lines + Center + Kaleido)\0Style 4 (Thick Lines + Center + Kaleido)\0Style 5 (Thick Lines + Kaleido)\0Style 6 (Thick Lines)\0"; ui_category = "Palette & Style"; ui_tooltip = "Selects the visual style of the fractal planes, or cycles through them."; > = 6;

// Effect-Specific Parameters
uniform float FractalGlobalScale < ui_type = "slider"; ui_label = "Fractal Global Scale"; ui_min = 0.1; ui_max = 2.0; ui_category = "Fractal Details"; ui_tooltip = "Adjusts the overall scale of the Apollonian fractal structures."; > = 1.0;
uniform float KaleidoscopeStrength < ui_type = "slider"; ui_label = "Kaleidoscope Strength"; ui_min = 0.0; ui_max = 1.0; ui_category = "Kaleidoscope"; ui_tooltip = "Controls smoothness and extent of the kaleidoscopic effect. Applied if an effect style with kaleidoscope is active."; > = 0.5;
uniform float KaleidoscopeRepetitions < ui_type = "slider"; ui_label = "Kaleidoscope Repetitions"; ui_min = 2.0; ui_max = 30.0; ui_step = 1.0; ui_category = "Kaleidoscope"; ui_tooltip = "Sets the number of repetitions for the kaleidoscope effect. Applied if an effect style with kaleidoscope is active."; > = 10.0;

// Audio Reactivity
AS_AUDIO_UI(GoldenClockwork_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity") // Defines GoldenClockwork_AudioSource
uniform float AudioReactivityAmount < ui_type = "slider"; ui_label = "Audio Reactivity Amount"; ui_min = 0.0; ui_max = 2.0; ui_category = "Audio Reactivity"; ui_tooltip = "General multiplier for how much audio affects the target parameter."; > = 1.0;
uniform bool AudioReactPositive < ui_type = "checkbox"; ui_label = "Audio React Positive Only"; ui_category = "Audio Reactivity"; ui_tooltip = "If checked, audio makes the parameter increase. If unchecked, it can increase or decrease (centered)."; > = true;
uniform int AudioReactiveTarget < ui_type = "combo"; ui_label = "Audio Reactive Target"; ui_items = "None\0Time Scale\0Path Speed\0Fractal Scale\0Kaleidoscope Strength\0Kaleidoscope Reps\0"; ui_category = "Audio Reactivity"; > = 0;

// Animation Controls
AS_ANIMATION_UI(GlobalTimeScale, AnimationKeyframe, "Animation") // Defines GoldenClockwork_AnimationSpeed
uniform float PathSpeed < ui_type = "slider"; ui_label = "Path Speed Multiplier"; ui_min = 0.0; ui_max = 3.0; ui_category = "Animation"; ui_tooltip = "Multiplies the speed of camera movement along the fractal path."; > = 1.0;

// Stage/Position Controls
AS_STAGEDEPTH_UI(GoldenClockwork_EffectDepth)
AS_ROTATION_UI(GoldenClockwork_SnapRotation, GoldenClockwork_FineRotation)
AS_POSITION_SCALE_UI(GoldenClockwork_Position, GoldenClockwork_Scale)

// Mix & Blend
AS_BLENDMODE_UI(GoldenClockwork_BlendMode) // Defines GoldenClockwork_BlendMode
AS_BLENDAMOUNT_UI(BlendOpacity)

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================
float hash(float co) {
    co += 100.0f;
    return frac(sin(co * 12.9898f) * 13758.5453f);
}

float2 toPolar(float2 p) {
    return float2(length(p), atan2(p.y, p.x));
}

float2 toRect(float2 p) {
    return float2(p.x * cos(p.y), p.x * sin(p.y));
}

float modMirror1(inout float p, float size) {
    float halfsize = size * 0.5f;
    float c = floor((p + halfsize) / size);
    p = AS_mod(p + halfsize, size) - halfsize; // MOD
    p *= AS_mod(c, 2.0f) * 2.0f - 1.0f;        // MOD
    return c;
}

float smoothKaleidoscope(inout float2 p, float sm, float rep) {
    float2 hp = p;
    float2 hpp = toPolar(hp);
    float rn = modMirror1(hpp.y, AS_TWO_PI / rep); // Replaced TAU with AS_TWO_PI
    float sa = AS_PI / rep - SABS(AS_PI / rep - abs(hpp.y), sm); // Replaced PI with AS_PI
    hpp.y = sign(hpp.y) * (sa);
    hp = toRect(hpp);
    p = hp;
    return rn;
}

float4 alphaBlend(float4 back, float4 front) {
    float w = front.w + back.w * (1.0f - front.w);
    float3 xyz = (front.xyz * front.w + back.xyz * back.w * (1.0f - front.w)) / w; // Potential div by zero if w is 0
    return w > 0.0001f ? float4(xyz, w) : float4(0.0f, 0.0f, 0.0f, 0.0f); // Added small epsilon for w check
}

float3 alphaBlend(float3 back, float4 front) {
    return lerp(back, front.xyz, front.w);
}

float tanh_approx(float x) {
    float x2 = x * x;
    return clamp(x * (27.0f + x2) / (27.0f + 9.0f * x2), -1.0f, 1.0f);
}

float pmin(float a, float b, float k) {
    float h = clamp(0.5f + 0.5f * (b - a) / k, 0.0f, 1.0f);
    return lerp(b, a, h) - k * h * (1.0f - h);
}

float circle(float2 p, float r) {
    return length(p) - r;
}

float hex(float2 p, float r) {
    const float3 k_const = float3(-sqrt(3.0f) / 2.0f, 1.0f / 2.0f, sqrt(3.0f) / 3.0f);
    p = p.yx;
    p = abs(p);
    p -= 2.0f * min(dot(k_const.xy, p), 0.0f) * k_const.xy;
    p -= float2(clamp(p.x, -k_const.z * r, k_const.z * r), r);
    return length(p) * sign(p.y);
}

float apollian(float4 p, float s_base, float fractal_scale_mod) {
    float scale = 1.0f;
    for (int i = 0; i < 7; ++i) {
        p = -1.0f + 2.0f * frac(0.5f * p + 0.5f);
        float r2 = dot(p, p);
        float k_val = (s_base * fractal_scale_mod) / r2;
        p *= k_val;
        scale *= k_val;
    }

    float lw = 0.00125f * g_gc_currentEffectStyle.x; // Use renamed global

    float d0 = abs(p.y) - lw * scale;
    float d1 = abs(circle(p.xz, 0.005f * scale)) - lw * scale;
    float d = d0;
    d = lerp(d, min(d, d1), g_gc_currentEffectStyle.y); // Use renamed global
    return (d / scale);
}

float getAudioModulationFactor() {
    if (GoldenClockwork_AudioSource == 0 || AudioReactiveTarget == 0) return 0.0;

    float audio_signal = AS_applyAudioReactivity(1.0, GoldenClockwork_AudioSource, AudioReactivityAmount, AudioReactPositive);
    return audio_signal - 1.0;
}

// -----------------------------------------------------------------------------
// PATH
// -----------------------------------------------------------------------------
float3 offset_path(float z) { 
    float a = z;
    float2 p = -0.075f * (float2(cos(a), sin(a * sqrt(2.0f))) + float2(cos(a * sqrt(0.75f)), sin(a * sqrt(0.5f))));
    return float3(p, z);
}

float3 doffset_path(float z) {
    float eps = 0.1f;
    return 0.5f * (offset_path(z + eps) - offset_path(z - eps)) / eps;
}

float3 ddoffset_path(float z) {
    float eps = 0.1f;
    return 0.125f * (doffset_path(z + eps) - doffset_path(z - eps)) / eps; 
}

// -----------------------------------------------------------------------------
// PLANE MARCHER
// -----------------------------------------------------------------------------
float weird(float2 p, float h_param, float current_time_scaled, float final_fractal_scale) {
    float z = 4.0f;
    float tm = 0.1f * current_time_scaled + h_param * 10.0f; 
    p = mul(p, ROT(tm * 0.5f));
    float r = 0.5f;
    float4 off_local = float4(r * PSIN(tm * sqrt(3.0f)), r * PSIN(tm * sqrt(1.5f)), r * PSIN(tm * sqrt(2.0f)), 0.0f);
    float4 pp = float4(p.x, p.y, 0.0f, 0.0f) + off_local;
    pp.w = 0.125f * (1.0f - tanh_approx(length(pp.xyz)));
    pp.yz = mul(pp.yz, ROT(tm));
    pp.xz = mul(pp.xz, ROT(tm * sqrt(0.5f)));
    pp /= z;
    float d = apollian(pp, 0.8f + h_param, final_fractal_scale);
    return d * z;
}

float circles(float2 p) {
    float2 pp = toPolar(p);
    const float ss_val = 2.0f;
    pp.x = frac(pp.x / ss_val) * ss_val;
    p = toRect(pp);
    float d = circle(p, 1.0f);
    return d;
}

float2 df(float2 p, float h_param, float current_time_scaled, float final_fractal_scale, float final_k_strength, float final_k_reps) {
    float2 wp = p;
    float rep = final_k_reps;
    float ss_kaleido = final_k_strength * 0.3f / max(rep, 1.0f);

    if (g_gc_currentEffectStyle.z > 0.0f) { // Use renamed global
        smoothKaleidoscope(wp, ss_kaleido, rep);
    }

    float d0 = weird(wp, h_param, current_time_scaled, final_fractal_scale);
    float d1 = hex(p, 0.25f) - 0.1f;
    float d2 = circles(p);
    const float lw_df = 0.0125f;
    d2 = abs(d2) - lw_df;
    float d = d0;

    if (g_gc_currentEffectStyle.w > 0.0f) { // Use renamed global
        d = pmin(d, d2, 0.1f);
    }

    d = pmin(d, abs(d1) - lw_df, 0.1f);
    d = max(d, -(d1 + lw_df));
    return float2(d, d1 + lw_df);
}

float2 df_transformed(float3 p_vec, float3 off_vec, float s_scale, float2x2 rot_mat, float h_param, float current_time_scaled, float final_fractal_scale, float final_k_strength, float final_k_reps) {
    float2 p2 = p_vec.xy; 
    p2 -= off_vec.xy;
    p2 = mul(p2, rot_mat);
    return df(p2 / s_scale, h_param, current_time_scaled, final_fractal_scale, final_k_strength, final_k_reps) * s_scale;
}

float3 skyColor(float3 ro, float3 rd) {
    float ld = max(dot(rd, float3(0.0f, 0.0f, 1.0f)), 0.0f);
    return 1.0f * SunLightColor * tanh_approx(3.0f * pow(ld, 100.0f));
}

float4 plane(float3 ro, float3 rd, float3 pp_plane, float pd, float3 off_param, float aa, float n_plane, float golden_clockwork_time, float final_fractal_scale, float final_k_strength, float final_k_reps) {
    if (EffectCycleMode == 0) {
        int pi = int(AS_mod(n_plane / PLANE_PERIOD, 6.0f));
        g_gc_currentEffectStyle = g_gc_effectStyles[pi]; // Use renamed globals
    } else {
        g_gc_currentEffectStyle = g_gc_effectStyles[clamp(EffectCycleMode - 1, 0, 5)]; // Use renamed globals
    }

    float h_hash = hash(n_plane);
    float s_scale_plane = 0.25f * lerp(0.5f, 0.25f, h_hash);

    const float3 nor_plane = float3(0.0f, 0.0f, -1.0f);
    const float3 loff_plane = 2.0f * float3(0.25f * 0.5f, 0.125f * 0.5f, -0.125f);
    float3 lp1 = ro + loff_plane;
    float3 lp2 = ro + loff_plane * float3(-2.0f, 1.0f, 1.0f);

    float2x2 rot_mat_plane = ROT(AS_TWO_PI * h_hash);

    float2 d2_val = df_transformed(pp_plane, off_param, s_scale_plane, rot_mat_plane, h_hash, golden_clockwork_time, final_fractal_scale, final_k_strength, final_k_reps);

    float3 ld1 = normalize(lp1 - pp_plane);
    float3 ld2 = normalize(lp2 - pp_plane);
    float dif1 = pow(max(dot(nor_plane, ld1), 0.0f), 5.0f);
    float dif2 = pow(max(dot(nor_plane, ld2), 0.0f), 5.0f);
    float3 ref_val = reflect(rd, nor_plane);
    float spe1 = pow(max(dot(ref_val, ld1), 0.0f), 30.0f);
    float spe2 = pow(max(dot(ref_val, ld2), 0.0f), 30.0f);

    const float boff_plane = 0.0125f * 0.5f;
    float dbt = rd.z == 0.0f ? 1e9f : boff_plane / rd.z;
    
    float3 bpp = ro + (pd + dbt) * rd;

    float3 srd1 = normalize(lp1 - bpp);
    float3 srd2 = normalize(lp2 - bpp);
    float bl21 = L2(lp1 - bpp);
    float bl22 = L2(lp2 - bpp);

    float st1 = srd1.z == 0.0f ? 1e9f : -boff_plane / srd1.z;
    float st2 = srd2.z == 0.0f ? 1e9f : -boff_plane / srd2.z;

    float3 spp1 = bpp + st1 * srd1;
    float3 spp2 = bpp + st2 * srd2;
    
    float2 bd_val = df_transformed(bpp, off_param, s_scale_plane, rot_mat_plane, h_hash, golden_clockwork_time, final_fractal_scale, final_k_strength, final_k_reps);
    float2 sd1_val = df_transformed(spp1, off_param, s_scale_plane, rot_mat_plane, h_hash, golden_clockwork_time, final_fractal_scale, final_k_strength, final_k_reps);
    float2 sd2_val = df_transformed(spp2, off_param, s_scale_plane, rot_mat_plane, h_hash, golden_clockwork_time, final_fractal_scale, final_k_strength, final_k_reps);

    float3 col = float3(0.0f, 0.0f, 0.0f);
    const float ss_exp_plane = 200.0f;

    col += 0.1125f * PlaneObjectColor * dif1 * (1.0f - exp(-ss_exp_plane * (max(sd1_val.x, 0.0f)))) / bl21;
    col += 0.1125f * PlaneObjectColor * dif2 * 0.5f * (1.0f - exp(-ss_exp_plane * (max(sd2_val.x, 0.0f)))) / bl22;
    
    float3 ringCol = G_baseRingCol;
    ringCol *= clamp(0.1f + 2.5f * (0.1f + 0.25f * ((dif1 * dif1 / bl21 + dif2 * dif2 / bl22))), 0.0f, 1.0f);
    ringCol += sqrt(G_baseRingCol) * spe1 * 2.0f;
    ringCol += sqrt(G_baseRingCol) * spe2 * 2.0f;
    col = lerp(col, ringCol, smoothstep(-aa, aa, -d2_val.x));  

    float ha_val = smoothstep(-aa, aa, bd_val.y);

    return float4(col, lerp(0.0f, 1.0f, ha_val));
}

float3 main_color_logic(float3 ww, float3 uu, float3 vv, float3 ro, float2 p_coord, float golden_clockwork_time, float final_fractal_scale, float final_k_strength, float final_k_reps) { 
    float lp = length(p_coord);
    float2 np_val = p_coord + ReShade::PixelSize;
    float rdd = (2.0f - 0.5f * tanh_approx(lp));
    float3 rd_norm = normalize(p_coord.x * uu + p_coord.y * vv + rdd * ww);
    float3 nrd_norm = normalize(np_val.x * uu + np_val.y * vv + rdd * ww);

    const float planeDist = 1.0f - 0.75f;
    const int furthest = 9;
    const int fadeFrom = max(furthest - 4, 0);
    const float fadeDist = planeDist * float(furthest - fadeFrom);
    float nz_floor = floor(ro.z / planeDist); 

    float3 skyCol_val = skyColor(ro, rd_norm); 

    float4 acol = float4(0.0f, 0.0f, 0.0f, 0.0f);
    const float cutOff = 0.95f;
    
    for (int i = 1; i <= furthest; ++i) {
        float pz = planeDist * nz_floor + planeDist * float(i);
        float pd = rd_norm.z == 0.0f ? 1e9f : (pz - ro.z) / rd_norm.z;

        if (pd > 0.0f && acol.w < cutOff) {
            float3 pp = ro + rd_norm * pd;
            float3 npp = ro + nrd_norm * pd;

            float aa = 3.0f * length(pp - npp);

            float3 off_val = offset_path(pp.z); 

            float4 pcol = plane(ro, rd_norm, pp, pd, off_val, aa, nz_floor + float(i), golden_clockwork_time, final_fractal_scale, final_k_strength, final_k_reps);

            float nz_dist = pp.z - ro.z; 
            float fadeIn = exp(-2.5f * max((nz_dist - planeDist * float(fadeFrom)) / fadeDist, 0.0f));
            float fadeOut = smoothstep(0.0f, planeDist * 0.1f, nz_dist);
            pcol.xyz = lerp(skyCol_val, pcol.xyz, fadeIn);
            pcol.w *= fadeOut;

            pcol = clamp(pcol, 0.0f, 1.0f);

            acol = alphaBlend(pcol, acol);
        } else {
            break;
        }
    }

    float3 col = alphaBlend(skyCol_val, acol);
    return col;
}

float3 postProcess(float3 col_in, float2 q_uv) {
    float3 col = clamp(col_in, 0.0f, 1.0f);
    col = pow(col, 1.0f / std_gamma); 
    col = col * 0.6f + 0.4f * col * col * (3.0f - 2.0f * col);
    float gray = dot(col, float3(0.33f, 0.33f, 0.33f));
    col = lerp(col, float3(gray, gray, gray), -0.4f);
    col *= 0.5f + 0.5f * pow(19.0f * q_uv.x * q_uv.y * (1.0f - q_uv.x) * (1.0f - q_uv.y), 0.7f);
    return col;
}

float3 getSceneColor(float2 p_norm, float2 q_uv, float golden_clockwork_time, float final_path_speed, float final_fractal_scale, float final_k_strength, float final_k_reps) { 
    g_gc_currentEffectStyle = g_gc_effectStyles[5]; // Use renamed globals. Default for initial setup, will be overridden in plane()

    float tm = (golden_clockwork_time * 0.125f) * final_path_speed;
    float3 ro = offset_path(tm);
    float3 dro = doffset_path(tm);
    float3 ddro = ddoffset_path(tm);

    float3 ww = normalize(dro);
    float3 uu = normalize(cross(normalize(float3(0.0f, 1.0f, 0.0f) + ddro), ww));
    float3 vv = normalize(cross(ww, uu));

    float3 col = main_color_logic(ww, uu, vv, ro, p_norm, golden_clockwork_time, final_fractal_scale, final_k_strength, final_k_reps);
    col = clamp(col, 0.0f, 1.0f);
    col *= smoothstep(0.0f, 5.0f, golden_clockwork_time);
    col = postProcess(col, q_uv);

    return col;
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_GoldenApollian(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float3 back_col = tex2D(sBackBuffer, texcoord).rgb;

    // Depth Check - GoldenClockwork_EffectDepth is defined by AS_STAGEDEPTH_UI
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    if (sceneDepth < GoldenClockwork_EffectDepth) {
        return float4(back_col, 1.0f); // Return original scene color if occluded
    }

    G_baseRingCol = pow(BaseRingColor, float3(0.6f, 0.6f, 0.6f));

    float audio_modulation = getAudioModulationFactor();

    float final_global_time_scale = GlobalTimeScale;
    if (AudioReactiveTarget == 1) {
        final_global_time_scale = max(GlobalTimeScale * (1.0 + audio_modulation), 0.0); // Ensure time scale doesn't go negative
    }
    float golden_clockwork_time = AS_getAnimationTime(final_global_time_scale, AnimationKeyframe);

    float final_path_speed = PathSpeed;
    if (AudioReactiveTarget == 2) {
        final_path_speed = PathSpeed * (1.0 + audio_modulation);
    }

    float final_fractal_scale = FractalGlobalScale;
    if (AudioReactiveTarget == 3) {
        final_fractal_scale = FractalGlobalScale * (1.0 + audio_modulation);
    }
    
    float final_k_strength = KaleidoscopeStrength;
    if (AudioReactiveTarget == 4) {
        final_k_strength = clamp(KaleidoscopeStrength * (1.0 + audio_modulation), 0.0, 1.0);
    }

    float final_k_reps = KaleidoscopeRepetitions;
    if (AudioReactiveTarget == 5) {
        final_k_reps = max(2.0, KaleidoscopeRepetitions * (1.0 + audio_modulation));
    }

    float2 q = texcoord;
    q.y = 1.0f - q.y; 

    float2 p = -1.0f + 2.0f * q;
    p.x *= ReShade::ScreenSize.x / ReShade::ScreenSize.y;

    // Apply Position and Scale
    p -= GoldenClockwork_Position; // Center the effect around the new position
    p /= GoldenClockwork_Scale;    // Apply scaling

    // Apply Rotation
    float angle = AS_getRotationRadians(GoldenClockwork_SnapRotation, GoldenClockwork_FineRotation);
    float s = sin(angle);
    float c = cos(angle);
    p = float2(p.x * c - p.y * s, p.x * s + p.y * c);

    float3 col = getSceneColor(p, q, golden_clockwork_time, final_path_speed, final_fractal_scale, final_k_strength, final_k_reps);

    float3 blended_col = col;
    if (GoldenClockwork_BlendMode > 0 && BlendOpacity > 0.001) {
        blended_col = AS_applyBlend(col, back_col, GoldenClockwork_BlendMode); 
    }
    
    return float4(blended_col, BlendOpacity);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique GoldenApollian_Tech <
    ui_label="[AS] BGX: Golden Clockwork"; 
    ui_tooltip = "AS_BGX_GoldenClockwork.1.fx: Intricate Golden Apollonian Fractal Background.\n"
                 "Original GLSL by mrange (CC0: Golden apollian) - https://www.shadertoy.com/view/WlcfRS.\n"
                 "Features procedural Apollonian fractals, dynamic animation, golden color scheme, depth progression, and kaleidoscopic options.\n"
                 "Controls for animation speed, pathing, colors, fractal style, kaleidoscope, audio reactivity, and blending are available."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_GoldenApollian;
        BlendEnable = true;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
    }
}

#endif // __AS_BGX_GoldenClockwork_1_fx

