/**
 * AS_BGX_Synthwave.1.fx - Synthwave Background
 * Author: Leon Aquitaine (AS-StageFX adaptation)
 * Original: "Neon triangulator" by context
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Renders a flight through a triangular corridor with neon lights and reflective
 * surfaces, creating a classic synthwave or retro-futuristic aesthetic. This is a
 * raymarching-based effect that generates a complete 3D scene.
 *
 * FEATURES:
 * - Procedurally generated, endlessly repeating triangular tunnel
 * - Reflective surfaces with multiple light bounces
 * - Customizable performance settings for quality and iterations
 * - Full AS-StageFX integration with rotation, animation, and depth controls
 * - Standard blending modes and stage depth masking
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. The scene is generated using raymarching with signed distance fields
 * 2. Triangular symmetry created using modPolar3 for corridor geometry
 * 3. Multiple light bounces simulate reflections and complex lighting
 * 4. ACES tonemapping provides cinematic color grading
 * 5. Integrated with AS-StageFX standard controls and depth masking
 *
 * ===================================================================================
 */

#ifndef __AS_BGX_Synthwave_1_fx
#define __AS_BGX_Synthwave_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Noise.1.fxh"

// ============================================================================
// UI CONTROLS
// ============================================================================

// Basic Settings
static const int ITER_MIN = 40, ITER_MAX = 150, ITER_DEFAULT = 77;
static const int BOUNCE_MIN = 1, BOUNCE_MAX = 8, BOUNCE_DEFAULT = 4;
uniform int MaxIter < ui_type = "slider"; ui_label = "Visual Detail"; ui_tooltip = "Higher values show more detail but may reduce performance"; ui_min = ITER_MIN; ui_max = ITER_MAX; ui_category = "Basic"; > = ITER_DEFAULT;
uniform int MaxBounces < ui_type = "slider"; ui_label = "Light Bounces"; ui_tooltip = "More bounces create richer lighting but cost performance"; ui_min = BOUNCE_MIN; ui_max = BOUNCE_MAX; ui_category = "Basic"; > = BOUNCE_DEFAULT;

// Animation
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")
uniform float CameraSpeed < ui_type = "slider"; ui_label = "Travel Speed"; ui_tooltip = "How fast you move through the tunnel"; ui_min = 0.1; ui_max = 3.0; ui_category = "Animation"; > = 1.0;
uniform float FOV < ui_type = "slider"; ui_label = "Field of View"; ui_tooltip = "Wider view creates fish-eye effect, narrower zooms in"; ui_min = 1.0; ui_max = 4.0; ui_category = "Animation"; > = 2.0;

// Tunnel Appearance
uniform float3 SunColorHSV < ui_type = "color"; ui_label = "Center Light Color"; ui_tooltip = "Color of the bright light at the tunnel center"; ui_category = "Tunnel"; > = float3(0.72, 0.9, 0.0004);
uniform float WallColorHue < ui_type = "slider"; ui_label = "Wall Color"; ui_tooltip = "Base color of the tunnel walls"; ui_min = 0.0; ui_max = 1.0; ui_category = "Tunnel"; > = 0.7;
uniform float WallColorVariation < ui_type = "slider"; ui_label = "Color Variation"; ui_tooltip = "How much the wall colors change across surfaces"; ui_min = 0.0; ui_max = 0.5; ui_category = "Tunnel"; > = 0.15;
uniform float WallSaturation < ui_type = "slider"; ui_label = "Color Richness"; ui_tooltip = "How vivid and saturated the colors appear"; ui_min = 0.0; ui_max = 1.0; ui_category = "Tunnel"; > = 0.9;
uniform float WallBrightness < ui_type = "slider"; ui_label = "Wall Brightness"; ui_tooltip = "Overall brightness of the tunnel surfaces"; ui_min = 0.0; ui_max = 1.0; ui_category = "Tunnel"; > = 0.25;

// Glowing Effects
uniform float GlowIntensity < ui_type = "slider"; ui_label = "Overall Glow"; ui_tooltip = "Brightness of all glowing effects"; ui_min = 0.0; ui_max = 10.0; ui_category = "Glow"; > = 1.0;
uniform bool EnableOrbs < ui_label = "Floating Lights"; ui_tooltip = "Show glowing spheres floating in the tunnel"; ui_category = "Glow"; > = true;
uniform float OrbGlowHue < ui_type = "slider"; ui_label = "Light Color"; ui_tooltip = "Color of the floating light spheres"; ui_min = 0.0; ui_max = 1.0; ui_category = "Glow"; > = 0.6;
uniform float OrbGlowVariation < ui_type = "slider"; ui_label = "Light Color Variety"; ui_tooltip = "How much the light colors change"; ui_min = 0.0; ui_max = 0.5; ui_category = "Glow"; > = 0.2;
static const float SPACING_MIN = 1.0, SPACING_MAX = 10.0, SPACING_DEFAULT = 3.0;
uniform float LightDiv < ui_type = "slider"; ui_label = "Light Spacing"; ui_tooltip = "Distance between repeating light patterns"; ui_min = SPACING_MIN; ui_max = SPACING_MAX; ui_category = "Glow"; > = SPACING_DEFAULT;

// Post Effects
uniform float VignetteStrength < ui_type = "slider"; ui_label = "Edge Darkening"; ui_tooltip = "How much the screen edges are darkened"; ui_min = 0.0; ui_max = 0.1; ui_category = "Post Effects"; > = 0.02;
uniform float3 VignetteColor < ui_type = "color"; ui_label = "Edge Color"; ui_tooltip = "Color tint for the darkened edges"; ui_category = "Post Effects"; > = float3(2.0, 3.0, 1.0);
uniform float NoiseInfluence < ui_type = "slider"; ui_label = "Film Grain"; ui_tooltip = "Adds subtle texture for a retro film look"; ui_min = 0.0; ui_max = 1.0; ui_category = "Post Effects"; > = 0.2;

// Audio Reactivity
uniform int AudioSource < ui_type = "combo"; ui_label = "Audio Source"; ui_tooltip = "Which audio frequency to react to"; ui_items = "Volume\0Beat\0Bass\0Mid\0Treble\0"; ui_category = "Audio"; > = 0;
uniform float AudioMult < ui_type = "slider"; ui_label = "Audio Strength"; ui_tooltip = "How strongly audio affects the parameters"; ui_min = 0.0; ui_max = 2.0; ui_category = "Audio"; > = 0.5;
uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target"; ui_tooltip = "Which parameter reacts to audio"; ui_items = "None\0Wall Brightness\0Wall Color\0Pattern Edges (Inverted)\0Specular Reflection (Inverted)\0"; ui_category = "Audio"; > = 0;

// Position & Mixing
AS_ROTATION_UI(SnapRotation, FineRotation)
AS_STAGEDEPTH_UI(StageDepth)
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// Expert Settings
uniform float3 AbsorptionColorHSV < ui_type = "color"; ui_label = "Reflection Tint"; ui_tooltip = "Color absorbed on each light bounce"; ui_category = "Expert"; ui_category_closed = true; > = float3(0.75, 0.33, 0.6);
uniform float ReflectionSharpness1 < ui_type = "slider"; ui_label = "Surface Reflection"; ui_tooltip = "Sharpness of surface reflections"; ui_min = 1.0; ui_max = 10.0; ui_category = "Expert"; > = 2.0;
uniform float ReflectionSharpness2 < ui_type = "slider"; ui_label = "Specular Reflection"; ui_tooltip = "Sharpness of bright reflections"; ui_min = 20.0; ui_max = 120.0; ui_category = "Expert"; > = 40.0;
uniform float PatternSharpness < ui_type = "slider"; ui_label = "Pattern Edges"; ui_tooltip = "How sharp the surface pattern edges appear"; ui_min = 20.0; ui_max = 120.0; ui_category = "Expert"; > = 80.0;

// ============================================================================
// CONSTANTS & HELPER FUNCTIONS
// ============================================================================

static const float MaxDistance = 10.0;
static const float Tolerance = 3e-3;
static const float NormalEpsilon = 1e-3;
static const float SimplexOff = 1.4142135623730950488016887242097f / 3.0f; // sqrt(2) / 3

// HSV to RGB conversion from original shader
// License: WTFPL, author: sam hocevar
static const float4 hsv2rgb_K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
float3 hsv2rgb(float3 c) {
    float3 p = abs(frac(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
    return c.z * lerp(hsv2rgb_K.xxx, saturate(p - hsv2rgb_K.xxx), c.y);
}

// Globals to mimic GLSL behavior
static float2 g_h;
static float3 g_gd;
static float2 g_d;
static float3 g_lp;
static float3 g_pp;
static float2 g_c;

float2x2 rot(float a) {
    float s = sin(a), c = cos(a);
    return float2x2(c, s, -s, c);
}

// License: MIT, author: Inigo Quilez
float3 aces_approx(float3 v) {
    const float a = 2.51, b = 0.03, c = 2.43, d = 0.59, e = 0.14;
    v = max(v, 0.0) * 0.6;
    return saturate((v * (a * v + b)) / (v * (c * v + d) + e));
}

// License: MIT, author: Inigo Quilez
float sdf_box(float2 p, float2 b) {
    float2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float2 shash2(float2 p) {
    p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
    return frac(sin(p) * 43758.5453123) * 2.0 - 1.0;
}

// License: MIT, author: Inigo Quilez
float sdf_xor(float a, float b) {
    return max(min(a, b), -max(a, b));
}

float boxPattern(float2 p, float hh, float2 sz) {
    const float zz = 2.0;
    float d = 1e3, z = 2.0;
    p /= z;
    [unroll]
    for (float i = 0.; i < 3.; ++i) {
        float2 n = round(p);
        float2 h = shash2(n + i + hh);
        float2 c = p - n;
        d = sdf_xor(d, sdf_box(c - h * 0.4, sz) / z);
        z *= zz;
        p *= zz;
        p += float2(3.14, 2.71);
    }
    return d;
}

float modPolar3(inout float2 p) {
    const float2 r = normalize(float2(sqrt(3.0), -1.0));
    float n = p.y < 0.0 ? -1.0 : 1.0;
    float2 ap = float2(p.x, abs(p.y));
    float d = dot(ap, r);
    if (d > 0.0) return 0.0;
    ap -= 2.0 * d * r;
    ap.y *= -n;
    p = ap;
    return n;
}

float df(float3 p, float time) {
    const float2x2 R1 = rot(AS_PI / 3.0);
    const float2 off2 = mul(R1, float2(SimplexOff, 0.0));

    float loff = -2.0 * g_h.x * time;
    float3 op = p;
    p.z -= loff;
    float R = round(p.z / LightDiv) * LightDiv;
    g_lp = float3(0, 0, loff + round((p.z + LightDiv * 0.47) / LightDiv) * LightDiv);
    p.z -= R;
    p.xy = -p.yx;

    float n = modPolar3(p.xy);
    float d0 = SimplexOff * 0.5 - p.x;
    float d1 = length(p.xz - 0.44 * float2(SimplexOff, 0.0)) - 0.001;
    
    float d5 = length(op.xy - float2(0, -0.1) + 0.1 * sin(-AS_TWO_PI * g_h * time + 2.0 * op.z * float2(1, sqrt(2.0))))
             + smoothstep(-sqrt(0.5), -0.5, sin((op.z + time + g_h.y * (time + 123.)) / AS_TWO_PI)) * 0.2;

    float d = d0;
    float d3 = 1e3;
    float d4 = 1e3;
    
    // Orb control - matches original GLSL logic
    if (EnableOrbs && g_h.x > 0.0) {
        d3 = d5;
        d4 = d5 * 0.25;
    }

    d = min(d, d1);
    g_pp = float3(p.y, op.z, n);
    p.y = abs(p.y);
    float d2 = length(p.xy - off2) - 0.01;
    d = min(d, d2);
    d = min(d, d3);

    g_gd = min(g_gd, float3(d1, d2, d4));
    g_d = float2(d0, d3);
    g_c = float2(n, floor((op.z - 0.05) / LightDiv));
    return d;
}

float rayMarch(float3 ro, float3 rd, float init, float time, out float i) {
    float t = init;
    for (i = 0.; i < MaxIter; ++i) {
        float3 p = ro + t * rd;
        float d = df(p, time);
        if (t > MaxDistance) return MaxDistance;
        if (d < Tolerance) return t;
        t += d;
    }
    return t;
}

float3 normal(float3 pos, float time) {
    const float2 eps = float2(NormalEpsilon, 0.0);
    return normalize(float3(
        df(pos + eps.xyy, time) - df(pos - eps.xyy, time),
        df(pos + eps.yxy, time) - df(pos - eps.yxy, time),
        df(pos + eps.yyx, time) - df(pos - eps.yyx, time)
    ));
}

float3 render(float3 ro, float3 rd, float noise, float time) {
    // Use UI controls for colors
    const float3 sunCol = hsv2rgb(SunColorHSV);
    const float3 absCol = hsv2rgb(AbsorptionColorHSV);

    // Audio reactivity - map AudioSource to AS constants
    int mappedAudioSource;
    switch(AudioSource) {
        case 0: mappedAudioSource = AS_AUDIO_VOLUME; break;
        case 1: mappedAudioSource = AS_AUDIO_BEAT; break;
        case 2: mappedAudioSource = AS_AUDIO_BASS; break;
        case 3: mappedAudioSource = AS_AUDIO_MID; break;
        case 4: mappedAudioSource = AS_AUDIO_TREBLE; break;
        default: mappedAudioSource = AS_AUDIO_SOLID; break;
    }
    
    float audioValue = AS_applyAudioReactivity(1.0, mappedAudioSource, AudioMult, true) - 1.0;
    
    // Apply audio to targeted parameters
    float wallBrightness_final = WallBrightness;
    float wallColorHue_final = WallColorHue;
    float patternSharpness_final = PatternSharpness;
    float reflectionSharpness2_final = ReflectionSharpness2;
    
    if (AudioTarget == 1) { // Wall Brightness
        wallBrightness_final = WallBrightness + (WallBrightness * audioValue * 2.0);
        wallBrightness_final = saturate(wallBrightness_final);
    }
    else if (AudioTarget == 2) { // Wall Color
        wallColorHue_final = WallColorHue + (audioValue * 0.5);
        wallColorHue_final = frac(wallColorHue_final); // Keep in 0-1 range with wrapping
    }
    else if (AudioTarget == 3) { // Pattern Edges (Inverted)
        float inverted_audio = -audioValue;
        patternSharpness_final = PatternSharpness + (PatternSharpness * inverted_audio * 0.5);
        patternSharpness_final = clamp(patternSharpness_final, 20.0, 120.0);
    }
    else if (AudioTarget == 4) { // Specular Reflection (Inverted)
        float inverted_audio = -audioValue;
        reflectionSharpness2_final = ReflectionSharpness2 + (ReflectionSharpness2 * inverted_audio * 0.5);
        reflectionSharpness2_final = clamp(reflectionSharpness2_final, 20.0, 120.0);
    }

    const float aa = 0.00025;
    float nn = 0.0;
    float initt = NoiseInfluence * noise;
    float3 col = 0.0;
    float3 cabs = 1.0;

    [loop]
    for (float l = 0.; l < MaxBounces; ++l) {
        if (dot(1.0.xxx, cabs) < 0.01) break;

        float h0 = AS_hash11(nn);
        float h1 = frac(8667.0 * h0);
        g_h = float2(h0, h1);
        g_gd = 1e3;

        float i;
        float t = rayMarch(ro, rd, initt, time, i);
        
        float2 d2 = g_d;
        float2 c = g_c;
        float3 gd = g_gd;
        float3 pp = g_pp;
        float3 lp = g_lp;
        float3 p = ro + rd * t;

        float d = df(p, time); // Final call to populate globals
        float3 n = normal(p, time);
        float3 ld = normalize(lp - p);
        float3 r = reflect(rd, n);

        float2 sz = 0.5 * sqrt(AS_hash21(c + 1.23));
        if (c.x + c.y < 3.0) sz = -1.0;

        float pd = boxPattern(pp.xy, h0, sz);
        float tol = Tolerance * 3.0;
        float phit = d2.x <= tol ? 1.0 : 0.0;
        float pf = smoothstep(aa, -aa, pd) * phit;
        float mgd = min(min(gd.x, gd.y), gd.z);

        if (t < MaxDistance) {
            float3 ccol = 0.0;
            float3 difCol0 = hsv2rgb(float3(wallColorHue_final + WallColorVariation * (3.0 * p.y - p.x), WallSaturation, wallBrightness_final));
            float3 glowCol0 = GlowIntensity * 2e-4 * difCol0;
            float3 glowCol1 = hsv2rgb(float3(OrbGlowHue + OrbGlowVariation * h1, 0.9, GlowIntensity * 2e-4));
            
            ccol += difCol0 * pow(max(dot(n, ld), 0.0), lerp(ReflectionSharpness1, ReflectionSharpness1 * 2.0, pf));
            ccol += difCol0 * pow(max(dot(reflect(rd, n), ld), 0.0), lerp(reflectionSharpness2_final, patternSharpness_final, pf));
            ccol += glowCol0 / max(gd.x * gd.x, 5e-6);
            ccol += glowCol0 / max(gd.y * gd.y, 5e-5) * (1.0 + sin(1e2 * p.z));
            ccol += glowCol1 / max(gd.z * gd.z, 5e-6);
            ccol *= cabs;

            col += ccol;
            rd = r;
            cabs *= absCol * pf;
            nn += pp.z * 1.2 + 1.23;
            ro = p + n * 0.02;
            initt = NoiseInfluence * noise * 0.02;

            if (mgd < tol) cabs = 0.0;
        } else {
            break;
        }
    }
    col += sunCol / (1.00001 + dot(abs(rd), normalize(float3(0, 0, -1))));
    return col;
}

float3 effect(float2 p, float noise, float time) {
    const float3 up = float3(0, 1, 0);
    const float3 ww = normalize(float3(0, 0, 1));
    const float3 uu = normalize(cross(up, ww));
    const float3 vv = cross(ww, uu);

    float3 ro = float3(0, 0, time * CameraSpeed);
    float3 rd = normalize(p.y * vv - p.x * uu + FOV * ww);
    float3 col = render(ro, rd, noise, time);

    col -= VignetteStrength * VignetteColor * (length(p) + 0.25);
    col = aces_approx(col);
    col = sqrt(col);
    return col;
}


// ============================================================================
// Pixel Shader & Technique
// ============================================================================

float4 PS_Synthwave(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    
    // Get animation time using AS controls
    float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);
    
    // Apply rotation using AS controls
    float rotation = AS_getRotationRadians(SnapRotation, FineRotation);
    float2 p = (2.0 * texcoord - 1.0) * float2(ReShade::AspectRatio, 1.0);
    if (abs(rotation) > AS_EPSILON) {
        p = AS_rotate2D(p, rotation);
    }
    
    // Generate noise for the effect
    float noise = AS_hash11(dot(texcoord, sin(texcoord)));
    
    // Apply stage depth masking
    float depth = ReShade::GetLinearizedDepth(texcoord);
    float depthMask = step(StageDepth, depth);
    
    // Render the effect
    float3 effectColor = effect(p, noise, time);
    float4 finalEffect = float4(effectColor, depthMask);
    
    // Apply blending using AS controls
    return AS_applyBlend(finalEffect, originalColor, BlendMode, BlendAmount);
}

technique AS_BGX_Synthwave <
    ui_label = "[AS] BGX: Synthwave";
    ui_tooltip = "Renders a synthwave-style flight through a triangular corridor with neon lights and reflective surfaces.\n"
                 "Features procedural geometry, multiple light bounces, and full AS-StageFX integration.\n"
                 "Performance: Raymarching-based effect with adjustable quality settings.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Synthwave;
    }
}

#endif // __AS_BGX_Synthwave_1_fx