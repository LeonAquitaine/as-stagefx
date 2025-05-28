/**
 * AS_VFX_FocusedChaos.1.fx - Swirling Cosmic Vortex/Black Hole Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a visually complex and dynamic abstract effect resembling a focused point of
 * chaotic energy or a swirling cosmic vortex. The patterns are generated using 3D
 * Simplex noise and Fractional Brownian Motion (FBM), with colors evolving based on
 * noise patterns and spatial coordinates, and animated over time. This version allows
 * the game scene to show through transparent areas of the effect, features an
 * artistically revised UI, includes dithering, and adds subtle domain warping
 * to reduce structural artifacts in the noise pattern.
 *
 * FEATURES:
 * - Dynamic, animated vortex pattern using 3D Simplex Noise and FBM.
 * - Transparent background, blending with the game scene.
 * - Customizable animation speed and keyframing.
 * - Extensive artistic controls for swirl, noise, color, and alpha falloff with intuitive labels.
 * - Dithering option to reduce color banding artifacts.
 * - Subtle domain warping to improve noise pattern quality at low swirl intensities.
 * - Standard AS-StageFX depth and blending controls.
 *
 * IMPLEMENTATION OVERVIEW:
 * - Added subtle domain warping using 2D Perlin noise to perturb the input coordinates
 *   for the FBM function. This helps break up potential parallel banding or grain artifacts
 *   that can appear when the main swirl effect is minimal.
 *
 * Based on:
 * "BlackHole (swirl, portal)" by misterprada
 * https://www.shadertoy.com/view/lcfyDj
 * Additional credit: Based on celestianmaze's work (https://x.com/cmzw_/status/1787147460772864188)
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD
// ============================================================================
#ifndef __AS_VFX_FocusedChaos_1_fx
#define __AS_VFX_FocusedChaos_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh" 
#include "AS_Noise.1.fxh" // Added for AS_PerlinNoise2D used in domain warping

// ============================================================================
// TUNABLE CONSTANTS 
// ============================================================================

// --- Animation ---
static const float ANIMATION_SPEED_MIN = 0.0f; /* ... rest of constants from previous version ... */
static const float ANIMATION_SPEED_MAX = 5.0f;
static const float ANIMATION_SPEED_DEFAULT = 1.0f; 
static const float ANIMATION_KEYFRAME_MIN = 0.0f;
static const float ANIMATION_KEYFRAME_MAX = 100.0f;
static const float ANIMATION_KEYFRAME_DEFAULT = 0.0f; 

// --- Noise Parameters / Nebula Pattern ---
static const float NOISE_FREQUENCY_MIN = 0.1f; 
static const float NOISE_FREQUENCY_MAX = 5.0f;
static const float NOISE_FREQUENCY_DEFAULT = 1.4f; 
static const float NOISE_DISTORTION_MIN = 0.0f; 
static const float NOISE_DISTORTION_MAX = 0.5f;
static const float NOISE_DISTORTION_DEFAULT = 0.01f; 
static const int   FBM_ITERATIONS_MIN = 1; 
static const int   FBM_ITERATIONS_MAX = 10; 
static const int   FBM_ITERATIONS_DEFAULT = 5; 
static const float INITIAL_Z_BASE_MIN = -2.0f; 
static const float INITIAL_Z_BASE_MAX = 2.0f;
static const float INITIAL_Z_BASE_DEFAULT = 0.0f; 
static const float INITIAL_Z_OFFSET_MIN = -2.0f; 
static const float INITIAL_Z_OFFSET_MAX = 2.0f;
static const float INITIAL_Z_OFFSET_DEFAULT = 0.5f; 
static const float NOISE_CHANNEL_OFFSET_MIN = -5.0f; 
static const float NOISE_CHANNEL_OFFSET_MAX = 5.0f;

// --- Nebula Pattern - Static Domain Warp ---
static const float PATTERN_WARP_STRENGTH_MIN = 0.0f;
static const float PATTERN_WARP_STRENGTH_MAX = 0.5f;
static const float PATTERN_WARP_STRENGTH_DEFAULT = 0.1f;
static const float PATTERN_WARP_SCALE_MIN = 0.1f;
static const float PATTERN_WARP_SCALE_MAX = 10.0f;
static const float PATTERN_WARP_SCALE_DEFAULT = 2.0f;

// --- Vortex Shape ---
static const float SWIRL_FACTOR_MIN = -5.0f; 
static const float SWIRL_FACTOR_MAX = 5.0f;
static const float SWIRL_FACTOR_DEFAULT = 1.0f; 
static const float UV_LENGTH_POWER_FOR_ANGLE_MIN = 0.1f; 
static const float UV_LENGTH_POWER_FOR_ANGLE_MAX = 5.0f;
static const float UV_LENGTH_POWER_FOR_ANGLE_DEFAULT = 1.0f; 

// --- Color Parameters / Luminance & Glow / Color Dynamics ---
static const float TIME_COLOR_SHIFT_MIN = 0.0f; /* ... rest of color constants from previous version ... */
static const float TIME_COLOR_SHIFT_MAX = 1.0f;
static const float TIME_COLOR_SHIFT_DEFAULT = 0.37f; 
static const float NOISE_COLOR_SCALE1_MIN = 0.0f; 
static const float NOISE_COLOR_SCALE1_MAX = 5.0f;
static const float NOISE_COLOR_SCALE1_DEFAULT = 2.0f; 
static const float NOISE_COLOR_BIAS1_MIN = -1.0f; 
static const float NOISE_COLOR_BIAS1_MAX = 1.0f;
static const float NOISE_COLOR_BIAS1_DEFAULT = 0.1f; 
static const float NOISE_COLOR_SCALE2_MIN = 0.0f; 
static const float NOISE_COLOR_SCALE2_MAX = 1.0f;
static const float NOISE_COLOR_SCALE2_DEFAULT = 0.275f; 
static const float EMISSION_STRENGTH_FACTOR_MIN = 0.0f; 
static const float EMISSION_STRENGTH_FACTOR_MAX = 2.0f;
static const float EMISSION_STRENGTH_FACTOR_DEFAULT = 0.44f; 
static const float NOISE_LENGTH_OFFSET_MIN = 0.0f; 
static const float NOISE_LENGTH_OFFSET_MAX = 2.0f;
static const float NOISE_LENGTH_OFFSET_DEFAULT = 0.619f; 
static const float NOISE_LENGTH_SCALE_MIN = 0.0f; 
static const float NOISE_LENGTH_SCALE_MAX = 10.0f;
static const float NOISE_LENGTH_SCALE_DEFAULT = 5.09f; 
static const float NOISE_LENGTH_POW_MIN = 0.1f; 
static const float NOISE_LENGTH_POW_MAX = 5.0f;
static const float NOISE_LENGTH_POW_DEFAULT = 1.37f; 
static const float FRACTURE_COLOR_OFFSET_MIN = -1.0f; 
static const float FRACTURE_COLOR_OFFSET_MAX = 1.0f;
static const float FRACTURE_COLOR_OFFSET_DEFAULT = -0.34f; 
static const float FAC_BIAS_MIN = -1.0f; 
static const float FAC_BIAS_MAX = 1.0f;
static const float FAC_BIAS_DEFAULT = -0.90f; 
static const float FAC_SCALE_MIN = 0.0f; 
static const float FAC_SCALE_MAX = 10.0f;
static const float FAC_SCALE_DEFAULT = 4.79f; 
static const float EMISSION_CONTRAST_MIN = 0.1f; 
static const float EMISSION_CONTRAST_MAX = 5.0f;
static const float EMISSION_CONTRAST_DEFAULT = 3.31f; 

// --- Final Mix / Transparency ---
static const float FINAL_MIX_BIAS_MIN = -2.0f; 
static const float FINAL_MIX_BIAS_MAX = 2.0f;
static const float FINAL_MIX_BIAS_DEFAULT = 1.2f; 
static const float EFFECT_ALPHA_EXPONENT_MIN = 0.1f; 
static const float EFFECT_ALPHA_EXPONENT_MAX = 5.0f;
static const float EFFECT_ALPHA_EXPONENT_DEFAULT = 1.0f; 
static const float DITHER_STRENGTH_MIN = 0.0f;
static const float DITHER_STRENGTH_MAX = 2.0f;
static const float DITHER_STRENGTH_DEFAULT = 0.5f;

// ============================================================================
// UI DECLARATIONS 
// ============================================================================

// --- Animation Controls ---
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation") 

// --- Vortex Shape Controls ---
uniform float SwirlFactor           < ui_type = "slider"; ui_label = "Swirl Intensity"; ui_tooltip = "Controls the intensity and direction of the swirling effect."; ui_min = SWIRL_FACTOR_MIN; ui_max = SWIRL_FACTOR_MAX; ui_step = 0.01f; ui_category = "Vortex Shape"; > = SWIRL_FACTOR_DEFAULT;
uniform float UvLengthPowerForAngle < ui_type = "slider"; ui_label = "Swirl Falloff"; ui_tooltip = "Adjusts how the swirl tightness changes from the center outwards."; ui_min = UV_LENGTH_POWER_FOR_ANGLE_MIN; ui_max = UV_LENGTH_POWER_FOR_ANGLE_MAX; ui_step = 0.01f; ui_category = "Vortex Shape"; > = UV_LENGTH_POWER_FOR_ANGLE_DEFAULT;

// --- Nebula Pattern Controls ---
uniform float NoiseFrequency        < ui_type = "slider"; ui_label = "Pattern Scale"; ui_tooltip = "Overall scale of the nebula patterns (smaller value = larger patterns)."; ui_min = NOISE_FREQUENCY_MIN; ui_max = NOISE_FREQUENCY_MAX; ui_step = 0.01f; ui_category = "Nebula Pattern"; > = NOISE_FREQUENCY_DEFAULT;
uniform float NoiseDistortion       < ui_type = "slider"; ui_label = "Pattern Detail"; ui_tooltip = "Amount of fine distortion or detail in the noise patterns."; ui_min = NOISE_DISTORTION_MIN; ui_max = NOISE_DISTORTION_MAX; ui_step = 0.001f; ui_category = "Nebula Pattern"; > = NOISE_DISTORTION_DEFAULT;
uniform int   FBM_Iterations        < ui_type = "slider"; ui_label = "Pattern Complexity"; ui_tooltip = "Number of noise layers creating the pattern complexity."; ui_min = FBM_ITERATIONS_MIN; ui_max = FBM_ITERATIONS_MAX; ui_step = 1; ui_category = "Nebula Pattern"; > = FBM_ITERATIONS_DEFAULT;
uniform float InitialZBase          < ui_type = "slider"; ui_label = "Depth Origin"; ui_tooltip = "Base depth reference for the noise field."; ui_min = INITIAL_Z_BASE_MIN; ui_max = INITIAL_Z_BASE_MAX; ui_step = 0.01f; ui_category = "Nebula Pattern"; > = INITIAL_Z_BASE_DEFAULT;
uniform float InitialZOffset        < ui_type = "slider"; ui_label = "Depth Variation"; ui_tooltip = "Offset applied to the noise field's depth, influencing pattern generation."; ui_min = INITIAL_Z_OFFSET_MIN; ui_max = INITIAL_Z_OFFSET_MAX; ui_step = 0.01f; ui_category = "Nebula Pattern"; > = INITIAL_Z_OFFSET_DEFAULT;
uniform float3 NoiseOffsetR         < ui_type = "slider"; ui_label = "Red Channel Seed"; ui_tooltip = "3D offset for Red channel noise sampling, affecting color variations."; ui_min = NOISE_CHANNEL_OFFSET_MIN; ui_max = NOISE_CHANNEL_OFFSET_MAX; ui_step = 0.1f; ui_category = "Nebula Pattern"; > = float3(0.0f, 0.0f, 0.0f);
uniform float3 NoiseOffsetG         < ui_type = "slider"; ui_label = "Green Channel Seed"; ui_tooltip = "3D offset for Green channel noise sampling, affecting color variations."; ui_min = NOISE_CHANNEL_OFFSET_MIN; ui_max = NOISE_CHANNEL_OFFSET_MAX; ui_step = 0.1f; ui_category = "Nebula Pattern"; > = float3(1.0f, 1.0f, 1.0f);
uniform float3 NoiseOffsetB         < ui_type = "slider"; ui_label = "Blue Channel Seed"; ui_tooltip = "3D offset for Blue channel noise sampling, affecting color variations."; ui_min = NOISE_CHANNEL_OFFSET_MIN; ui_max = NOISE_CHANNEL_OFFSET_MAX; ui_step = 0.1f; ui_category = "Nebula Pattern"; > = float3(2.0f, 2.0f, 2.0f);

uniform bool  EnablePatternWarp     < ui_label = "Enable Pattern Warp"; ui_tooltip = "Enables a subtle distortion of the noise pattern to reduce visual artifacts when swirl is low."; ui_category = "Nebula Pattern"; > = true;
uniform float PatternWarpStrength   < ui_type = "slider"; ui_label = "Pattern Warp Strength"; ui_tooltip = "Strength of the subtle pattern distortion."; ui_min = PATTERN_WARP_STRENGTH_MIN; ui_max = PATTERN_WARP_STRENGTH_MAX; ui_step = 0.001f; ui_category = "Nebula Pattern"; > = PATTERN_WARP_STRENGTH_DEFAULT;
uniform float PatternWarpScale      < ui_type = "slider"; ui_label = "Pattern Warp Scale"; ui_tooltip = "Scale/frequency of the subtle pattern distortion."; ui_min = PATTERN_WARP_SCALE_MIN; ui_max = PATTERN_WARP_SCALE_MAX; ui_step = 0.01f; ui_category = "Nebula Pattern"; > = PATTERN_WARP_SCALE_DEFAULT;

// --- Luminance & Glow Controls ---
uniform float3 EmissionBaseColor    < ui_type = "color";  ui_label = "Glow Color"; ui_tooltip = "Base color for the bright emissive core of the vortex."; ui_category = "Luminance & Glow"; > = float3(0.960784f, 0.592157f, 0.078431f);
/* ... rest of Color Parameter UI from previous version, with updated category names ... */
uniform float EmissionStrengthFactor< ui_type = "slider"; ui_label = "Glow Strength"; ui_tooltip = "Overall intensity of the glow effect."; ui_min = EMISSION_STRENGTH_FACTOR_MIN; ui_max = EMISSION_STRENGTH_FACTOR_MAX; ui_step = 0.01f; ui_category = "Luminance & Glow"; > = EMISSION_STRENGTH_FACTOR_DEFAULT;
uniform float EmissionContrast      < ui_type = "slider"; ui_label = "Glow Contrast"; ui_tooltip = "Sharpness of the glow; higher values make highlights more intense."; ui_min = EMISSION_CONTRAST_MIN; ui_max = EMISSION_CONTRAST_MAX; ui_step = 0.01f; ui_category = "Luminance & Glow"; > = EMISSION_CONTRAST_DEFAULT;
uniform float NoiseLengthOffset     < ui_type = "slider"; ui_label = "Glow Threshold"; ui_tooltip = "Determines how much of the noise contributes to the glow; affects glow area size."; ui_min = NOISE_LENGTH_OFFSET_MIN; ui_max = NOISE_LENGTH_OFFSET_MAX; ui_step = 0.001f; ui_category = "Luminance & Glow"; > = NOISE_LENGTH_OFFSET_DEFAULT;
uniform float NoiseLengthScale      < ui_type = "slider"; ui_label = "Glow Spread"; ui_tooltip = "Controls the spread or extent of the glow based on noise characteristics."; ui_min = NOISE_LENGTH_SCALE_MIN; ui_max = NOISE_LENGTH_SCALE_MAX; ui_step = 0.01f; ui_category = "Luminance & Glow"; > = NOISE_LENGTH_SCALE_DEFAULT;
uniform float NoiseLengthPow        < ui_type = "slider"; ui_label = "Glow Falloff"; ui_tooltip = "Adjusts the falloff curve of the glow intensity."; ui_min = NOISE_LENGTH_POW_MIN; ui_max = NOISE_LENGTH_POW_MAX; ui_step = 0.01f; ui_category = "Luminance & Glow"; > = NOISE_LENGTH_POW_DEFAULT;

// --- Color Dynamics Controls ---
uniform float TimeColorShiftFactor  < ui_type = "slider"; ui_label = "Color Evolution"; ui_tooltip = "Controls how much time influences color changes in the nebula patterns."; ui_min = TIME_COLOR_SHIFT_MIN; ui_max = TIME_COLOR_SHIFT_MAX; ui_step = 0.01f; ui_category = "Color Dynamics"; > = TIME_COLOR_SHIFT_DEFAULT;
uniform float NoiseColorScale1      < ui_type = "slider"; ui_label = "Texture Color Scale A"; ui_tooltip = "First scaling factor for processing texture colors from noise."; ui_min = NOISE_COLOR_SCALE1_MIN; ui_max = NOISE_COLOR_SCALE1_MAX; ui_step = 0.01f; ui_category = "Color Dynamics"; > = NOISE_COLOR_SCALE1_DEFAULT;
uniform float NoiseColorBias1       < ui_type = "slider"; ui_label = "Texture Color Bias A"; ui_tooltip = "Bias applied after first scaling of texture colors."; ui_min = NOISE_COLOR_BIAS1_MIN; ui_max = NOISE_COLOR_BIAS1_MAX; ui_step = 0.01f; ui_category = "Color Dynamics"; > = NOISE_COLOR_BIAS1_DEFAULT;
uniform float NoiseColorScale2      < ui_type = "slider"; ui_label = "Texture Color Scale B"; ui_tooltip = "Second scaling factor for processing texture colors."; ui_min = NOISE_COLOR_SCALE2_MIN; ui_max = NOISE_COLOR_SCALE2_MAX; ui_step = 0.001f; ui_category = "Color Dynamics"; > = NOISE_COLOR_SCALE2_DEFAULT;
uniform float FractureColorOffset   < ui_type = "slider"; ui_label = "Shadow Tint Seed"; ui_tooltip = "Offsets the color input for shadow calculations, can tint darker areas."; ui_min = FRACTURE_COLOR_OFFSET_MIN; ui_max = FRACTURE_COLOR_OFFSET_MAX; ui_step = 0.01f; ui_category = "Color Dynamics"; > = FRACTURE_COLOR_OFFSET_DEFAULT;
uniform float FacBias               < ui_type = "slider"; ui_label = "Shadow Bias"; ui_tooltip = "Adjusts the threshold or bias for darker, outer areas of the effect."; ui_min = FAC_BIAS_MIN; ui_max = FAC_BIAS_MAX; ui_step = 0.01f; ui_category = "Color Dynamics"; > = FAC_BIAS_DEFAULT;
uniform float FacScale              < ui_type = "slider"; ui_label = "Shadow Intensity"; ui_tooltip = "Scales the intensity of the darker, outer areas of the effect."; ui_min = FAC_SCALE_MIN; ui_max = FAC_SCALE_MAX; ui_step = 0.01f; ui_category = "Color Dynamics"; > = FAC_SCALE_DEFAULT;

// --- Stage Controls ---
AS_STAGEDEPTH_UI(EffectDepth) 

// --- Final Mix ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0) 
AS_BLENDAMOUNT_UI(BlendAmount) 
uniform float FinalMixFactorBias    < ui_type = "slider"; ui_label = "Core/Edge Balance"; ui_tooltip = "Bias for the mix between the emissive core and outer effect areas."; ui_min = FINAL_MIX_BIAS_MIN; ui_max = FINAL_MIX_BIAS_MAX; ui_step = 0.01f; ui_category = "Final Mix"; > = FINAL_MIX_BIAS_DEFAULT;
uniform float EffectAlphaExponent   < ui_type = "slider"; ui_label = "Transparency Falloff"; ui_tooltip = "Controls the sharpness of the transparency falloff from core to edge."; ui_min = EFFECT_ALPHA_EXPONENT_MIN; ui_max = EFFECT_ALPHA_EXPONENT_MAX; ui_step = 0.01f; ui_category = "Final Mix"; > = EFFECT_ALPHA_EXPONENT_DEFAULT;
uniform bool  EnableDithering       < ui_label = "Enable Dithering"; ui_tooltip = "Adds a small amount of noise to reduce color banding."; ui_category = "Final Mix"; > = true;
uniform float DitherStrength        < ui_type = "slider"; ui_label = "Dither Strength"; ui_tooltip = "Strength of the dithering effect."; ui_min = DITHER_STRENGTH_MIN; ui_max = DITHER_STRENGTH_MAX; ui_step = 0.01f; ui_category = "Final Mix"; > = DITHER_STRENGTH_DEFAULT;


// ============================================================================
// HELPER FUNCTIONS (Noise Implementation from GLSL)
// ============================================================================
float4 permute_3d(float4 x) { return fmod(((x * 34.0f) + 1.0f) * x, 289.0f); }
float4 taylorInvSqrt3d(float4 r) { return 1.79284291400159f - 0.85373472095314f * r; }

float simplexNoise3d(float3 v)
{
    const float2 C = float2(1.0f/6.0f, 1.0f/3.0f); 
    static const float4 D = float4(0.0f, 0.5f, 1.0f, 2.0f);
    float3 i  = floor(v + dot(v, float3(C.y, C.y, C.y)) );
    float3 x0 =    v - i + dot(i, float3(C.x, C.x, C.x)) ;
    float3 g = step(x0.yzx, x0.xyz);
    float3 l = 1.0f - g;
    float3 i1 = min(g.xyz, l.zxy);
    float3 i2 = max(g.xyz, l.zxy);
    float3 x1 = x0 - i1 + float3(C.x, C.x, C.x);         
    float3 x2 = x0 - i2 + float3(C.y, C.y, C.y);         
    float3 x3 = x0 - 1.0f + float3(0.5f, 0.5f, 0.5f);      
    i = fmod(i, 289.0f);
    float4 p = permute_3d(permute_3d(permute_3d( i.z + float4(0.0f, i1.z, i2.z, 1.0f)) + i.y + float4(0.0f, i1.y, i2.y, 1.0f)) + i.x + float4(0.0f, i1.x, i2.x, 1.0f));
    float n_ = 1.0f/7.0f; 
    float3 ns = n_ * float3(D.w, D.y, D.z) - float3(D.x, D.z, D.x); 
    float4 j = p - 49.0f * floor(p * ns.z * ns.z); 
    float4 x_ = floor(j * ns.z);
    float4 y_ = floor(j - 7.0f * x_);   
    float4 x = x_ * ns.x + ns.yyyy;
    float4 y = y_ * ns.x + ns.yyyy;
    float4 h = 1.0f - abs(x) - abs(y);
    float4 b0 = float4(x.xy, y.xy);
    float4 b1 = float4(x.zw, y.zw);
    float4 s0 = floor(b0) * 2.0f + 1.0f;
    float4 s1 = floor(b1) * 2.0f + 1.0f;
    float4 sh = -step(h, float4(0.0f, 0.0f, 0.0f, 0.0f));
    float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
    float3 p0 = float3(a0.xy, h.x);
    float3 p1 = float3(a0.zw, h.y);
    float3 p2 = float3(a1.xy, h.z);
    float3 p3 = float3(a1.zw, h.w);
    float4 norm = taylorInvSqrt3d(float4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
    p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;
    float4 m = max(0.6f - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0f);
    m = m * m;
    return 42.0f * dot(m * m, float4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
}

float fbm3d(float3 x, const int it) {
    float v = 0.0f; float a = 0.5f;
    float3 shift = float3(100.0f, 100.0f, 100.0f); 
    for (int i = 0; i < 32; ++i) { 
        if (i < it) { v += a * simplexNoise3d(x); x = x * 2.0f + shift; a *= 0.5f; } 
        else { break; }
    } return v;
}

float3 rotateZ(float3 v, float angle) {
    float s = sin(angle); float c = cos(angle);
    return float3(v.x * c - v.y * s, v.x * s + v.y * c, v.z);
}

float facture(float3 vec_in) { 
    float3 normalizedVector = normalize(vec_in);
    return max(max(normalizedVector.x, normalizedVector.y), normalizedVector.z);
}

float3 calculate_emission(float3 c, float strength) { return c * strength; }

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 FocusedChaos_PS(float4 svpos : SV_POSITION, float2 texcoord : TEXCOORD) : SV_TARGET
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);

    if (sceneDepth < EffectDepth - AS_DEPTH_EPSILON && EffectDepth < 0.9999f) {
        return AS_applyBlend(originalColor, originalColor, BlendMode, BlendAmount); 
    }

    float2 uv = float2(texcoord.x, 1.0f - texcoord.y); 
    uv = (uv * 2.0f - 1.0f);                          
    uv.x *= ReShade::AspectRatio;                   

    float animTime = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);

    float3 current_color = float3(uv.xy, InitialZBase);
    current_color.z += InitialZOffset;
    current_color = normalize(current_color);
    current_color -= TimeColorShiftFactor * float3(0.0f, 0.0f, animTime);

    float angle_base = -log2(max(0.00001f, pow(length(uv), UvLengthPowerForAngle))); 
    float angle = angle_base * SwirlFactor;
    current_color = rotateZ(current_color, angle);

    float3 noise_input_base = current_color * NoiseFrequency;

    // Apply static domain warp for artifact reduction
    if (EnablePatternWarp && PatternWarpStrength > 0.0f) {
        float2 warp_uv = texcoord * PatternWarpScale; // Use texcoord for consistent screen-space warp
        float warp_x = AS_PerlinNoise2D(warp_uv + float2(17.3f, 3.7f)); // AS_PerlinNoise2D from AS_Noise.1.fxh
        float warp_y = AS_PerlinNoise2D(warp_uv + float2(11.1f, 28.9f));
        noise_input_base.xy += float2(warp_x, warp_y) * PatternWarpStrength;
    }

    float3 noisy_color;
    noisy_color.x = fbm3d(noise_input_base + NoiseOffsetR, FBM_Iterations) + NoiseDistortion;
    noisy_color.y = fbm3d(noise_input_base + NoiseOffsetG, FBM_Iterations) + NoiseDistortion;
    noisy_color.z = fbm3d(noise_input_base + NoiseOffsetB, FBM_Iterations) + NoiseDistortion;
    
    float3 facture_input_color = noisy_color; 

    noisy_color *= NoiseColorScale1;
    noisy_color = noisy_color - NoiseColorBias1; 
    noisy_color *= NoiseColorScale2;
    noisy_color += float3(uv.xy, 0.0f);

    float noiseColorLength = length(noisy_color);
    noiseColorLength = NoiseLengthOffset - noiseColorLength;
    noiseColorLength *= NoiseLengthScale;
    noiseColorLength = pow(abs(noiseColorLength), NoiseLengthPow); 
    noiseColorLength = max(0.0f, noiseColorLength); 

    float3 emissionCol = calculate_emission(EmissionBaseColor, noiseColorLength * EmissionStrengthFactor);
    emissionCol = pow(saturate(emissionCol), EmissionContrast); 

    float fac = length(uv) - facture(facture_input_color + FractureColorOffset);
    fac += FacBias;
    fac *= FacScale;
    
    float3 target_mix_color = float3(fac, fac, fac); 
    float internal_mix_alpha = saturate(fac + FinalMixFactorBias);   

    float3 effect_rgb = lerp(emissionCol, target_mix_color, internal_mix_alpha);
    
    // Dithering to reduce color banding
    if (EnableDithering && DitherStrength > 0.0f)
    {
        float dither_val = AS_hash21(texcoord * ReShade::ScreenSize.xy * 0.25f); // Using AS_hash21 from AS_Utils.1.fxh
        float dither_adjust = (dither_val - 0.5f) * (DitherStrength / 255.0f);
        effect_rgb += dither_adjust;
        effect_rgb = saturate(effect_rgb);
    }
    
    float effect_alpha_value = lerp(1.0f, 0.0f, internal_mix_alpha);
    effect_alpha_value = pow(saturate(effect_alpha_value), EffectAlphaExponent); 
    
    return AS_applyBlend(float4(effect_rgb, effect_alpha_value), originalColor, BlendMode, BlendAmount);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_VFX_FocusedChaos <
    ui_label = "[AS] VFX: Focused Chaos";
    ui_tooltip = "Abstract swirling chaotic vortex effect with transparency and artistic controls.\nOriginally by celestianmaze, adapted for AS-StageFX.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FocusedChaos_PS;
    }
}

#endif // __AS_VFX_FocusedChaos_1_fx