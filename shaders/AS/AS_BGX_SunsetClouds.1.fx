/**
 * AS_BGX_SunsetClouds.1.fx - Animated Sunset Clouds with Raymarching
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader renders an animated scene of clouds at sunset. It uses raymarching
 * to create volumetric cloud effects with dynamic lighting and turbulence.
 * The colors shift and blend to simulate the hues of a sunset.
 *
 * FEATURES:
 * - Raymarched volumetric clouds.
 * - Animated turbulence effect on clouds.
 * - Dynamic sunset coloring that changes over time.
 * - Tunable parameters for iterations, animation speed, and visual details.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Sets up a ray direction based on screen coordinates.
 * 2. Iteratively marches a ray through the scene.
 * 3. For each step, calculates a sample point 'p'.
 * 4. Applies a turbulence effect to 'p' using multiple sine wave layers.
 * 5. Computes a signed distance function (SDF) based on 'p.y' to define cloud shapes.
 * 6. Adjusts the raymarch step distance based on the SDF (smaller steps inside clouds).
 * 7. Accumulates color based on the SDF, point 'p', and time, creating cloud lighting and sunset hues.
 * 8. Applies a tanh-based tonemapping to the final accumulated color.
 * 
 * Based on:
 * "Sunset [280]" by @XorDev
 * https://www.shadertoy.com/view/wXjSRt
 * Original tweet shader: https://x.com/XorDev/status/1918764164153049480
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_SUNSETCLOUDS_1_FX
#define __AS_BGX_SUNSETCLOUDS_1_FX

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh" 

// ============================================================================
// COMPATIBILITY MACROS
// ============================================================================
// Approximation of tanh for compatibility with Shader Model 5 and below
#define AS_TANH(x) ((2.0/(1.0+exp(-2.0*(x)))) - 1.0)

// ============================================================================
// TUNABLE CONSTANTS (for UI limits and defaults)
// ============================================================================

// --- Animation ---
static const float ANIMATION_SPEED_MIN = 0.0;
static const float ANIMATION_SPEED_MAX = 5.0;
static const float ANIMATION_SPEED_DEFAULT = 1.0;
static const float ANIMATION_KEYFRAME_MIN = 0.0;
static const float ANIMATION_KEYFRAME_MAX = 1000.0;
static const float ANIMATION_KEYFRAME_DEFAULT = 0.0;

// --- Cloud Shape & Detail ---
static const float CLOUD_ALTITUDE_MIN = 0.0;
static const float CLOUD_ALTITUDE_MAX = 1.0;
static const float CLOUD_ALTITUDE_DEFAULT = 0.3; // Was SdfCloudLevel
static const int CLOUD_DETAIL_MIN = 20;
static const int CLOUD_DETAIL_MAX = 200;
static const int CLOUD_DETAIL_DEFAULT = 100; // Was RaymarchIterations

// --- Cloud Dynamics (Turbulence) ---
static const float TURBULENCE_SCALE_START_MIN = 1.0;
static const float TURBULENCE_SCALE_START_MAX = 10.0;
static const float TURBULENCE_SCALE_START_DEFAULT = 5.0; // Was TurbulenceInitD
static const float TURBULENCE_SCALE_END_MIN = 50.0;
static const float TURBULENCE_SCALE_END_MAX = 400.0;
static const float TURBULENCE_SCALE_END_DEFAULT = 200.0; // Was TurbulenceMaxD
static const float TURBULENCE_INTENSITY_MIN = 0.0;
static const float TURBULENCE_INTENSITY_MAX = 2.0;
static const float TURBULENCE_INTENSITY_DEFAULT = 0.6; // Was TurbulenceStrength
static const float TURBULENCE_ANIM_FACTOR_MIN = 0.0;
static const float TURBULENCE_ANIM_FACTOR_MAX = 1.0;
static const float TURBULENCE_ANIM_FACTOR_DEFAULT = 0.2; // Was TurbulenceTimeFactor

// --- Raymarch Step (Advanced) ---
static const float MARCH_STEP_BASE_MIN = 0.001;
static const float MARCH_STEP_BASE_MAX = 0.1;
static const float MARCH_STEP_BASE_DEFAULT = 0.005;
static const float MARCH_SDF_INFLUENCE_MIN = 0.0;
static const float MARCH_SDF_INFLUENCE_MAX = 1.0;
static const float MARCH_SDF_INFLUENCE_DEFAULT = 0.2; // Was MarchSdfScale
static const float MARCH_SDF_DIVISOR_MIN = 1.0;
static const float MARCH_SDF_DIVISOR_MAX = 10.0;
static const float MARCH_SDF_DIVISOR_DEFAULT = 4.0;

// --- Sunset Colors ---
static const float COLOR_ANIM_FACTOR_MIN = 0.0;
static const float COLOR_ANIM_FACTOR_MAX = 2.0;
static const float COLOR_ANIM_FACTOR_DEFAULT = 0.5; // Was ColorTimeFactor
static const float COLOR_PHASE_R_MIN = 0.0;
static const float COLOR_PHASE_R_MAX = 10.0;
static const float COLOR_PHASE_R_DEFAULT = 3.0;
static const float COLOR_PHASE_G_MIN = 0.0;
static const float COLOR_PHASE_G_MAX = 10.0;
static const float COLOR_PHASE_G_DEFAULT = 4.0;
static const float COLOR_PHASE_B_MIN = 0.0;
static const float COLOR_PHASE_B_MAX = 10.0;
static const float COLOR_PHASE_B_DEFAULT = 5.0;
static const float COLOR_BRIGHTNESS_ADD_MIN = 0.0;
static const float COLOR_BRIGHTNESS_ADD_MAX = 3.0;
static const float COLOR_BRIGHTNESS_ADD_DEFAULT = 1.5; // Was ColorAdd
// Advanced Color Modulators
static const float COLOR_SDF_MOD_MIN = 0.01;
static const float COLOR_SDF_MOD_MAX = 0.5;
static const float COLOR_SDF_MOD_DEFAULT = 0.07; // Was ColorSdfDiv
static const float COLOR_EXP_SDF_MOD_MIN = 0.01;
static const float COLOR_EXP_SDF_MOD_MAX = 0.5;
static const float COLOR_EXP_SDF_MOD_DEFAULT = 0.1; // Was ColorExpSdfDiv

// --- Final Look (Tonemapping) ---
static const float TONEMAP_EXPOSURE_MIN = 1e7;
static const float TONEMAP_EXPOSURE_MAX = 1e9;
static const float TONEMAP_EXPOSURE_DEFAULT = 4e8; // Was TonemapStrength

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Animation Controls ---

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nBased on 'Sunset [280]' by Xor\nLink: https://www.shadertoy.com/view/wXjSRt\nLicence: CC Share-Alike Non-Commercial\n\n";>;

uniform float AnimationSpeed < ui_type = "slider"; ui_label = "Speed"; ui_tooltip = "Cloud and color animation speed."; ui_min = ANIMATION_SPEED_MIN; ui_max = ANIMATION_SPEED_MAX; ui_step = 0.01; ui_category = "Animation"; > = ANIMATION_SPEED_DEFAULT;
uniform float AnimationKeyframe < ui_type = "slider"; ui_label = "Time Offset"; ui_tooltip = "Scrub the animation timeline."; ui_min = ANIMATION_KEYFRAME_MIN; ui_max = ANIMATION_KEYFRAME_MAX; ui_step = 0.1; ui_category = "Animation"; > = ANIMATION_KEYFRAME_DEFAULT;

// --- Cloud Shape & Detail ---
uniform float CloudAltitude < ui_type = "slider"; ui_label = "Altitude"; ui_tooltip = "Cloud layer height."; ui_min = CLOUD_ALTITUDE_MIN; ui_max = CLOUD_ALTITUDE_MAX; ui_step = 0.01; ui_category = "Clouds"; > = CLOUD_ALTITUDE_DEFAULT;
uniform int CloudDetail < ui_type = "slider"; ui_label = "Detail"; ui_tooltip = "Raymarch steps (quality)."; ui_min = CLOUD_DETAIL_MIN; ui_max = CLOUD_DETAIL_MAX; ui_category = "Clouds"; > = CLOUD_DETAIL_DEFAULT;
uniform float EffectRaymarchDepth < ui_type = "slider"; ui_label = "Raymarch Depth"; ui_tooltip = "Scales the depth of the raymarching effect (legacy, not a true cutout)."; ui_min = 0.1; ui_max = 3.0; ui_step = 0.01; ui_category = "Clouds"; > = 1.0;

// --- Cloud Dynamics ---
uniform float TurbulenceIntensity < ui_type = "slider"; ui_label = "Turbulence"; ui_tooltip = "Cloud swirl amount."; ui_min = TURBULENCE_INTENSITY_MIN; ui_max = TURBULENCE_INTENSITY_MAX; ui_step = 0.01; ui_category = "Turbulence"; > = TURBULENCE_INTENSITY_DEFAULT;
uniform float TurbulenceAnimFactor < ui_type = "slider"; ui_label = "Turb. Speed"; ui_tooltip = "Turbulence animation speed."; ui_min = TURBULENCE_ANIM_FACTOR_MIN; ui_max = TURBULENCE_ANIM_FACTOR_MAX; ui_step = 0.01; ui_category = "Turbulence"; > = TURBULENCE_ANIM_FACTOR_DEFAULT;
uniform float TurbulenceScaleStart < ui_type = "slider"; ui_label = "Turb. Scale Start"; ui_tooltip = "Smallest swirl size."; ui_min = TURBULENCE_SCALE_START_MIN; ui_max = TURBULENCE_SCALE_START_MAX; ui_step = 0.1; ui_category = "Turbulence"; > = TURBULENCE_SCALE_START_DEFAULT;
uniform float TurbulenceScaleEnd < ui_type = "slider"; ui_label = "Turb. Scale End"; ui_tooltip = "Largest swirl size."; ui_min = TURBULENCE_SCALE_END_MIN; ui_max = TURBULENCE_SCALE_END_MAX; ui_step = 1.0; ui_category = "Turbulence"; > = TURBULENCE_SCALE_END_DEFAULT;

// --- Sunset Colors ---
uniform float3 ColorPhase < ui_type = "slider"; ui_label = "Hue Phases"; ui_tooltip = "Red, green, blue phase shifts."; ui_min = COLOR_PHASE_R_MIN; ui_max = COLOR_PHASE_B_MAX; ui_step = 0.1; ui_category = "Color"; > = float3(COLOR_PHASE_R_DEFAULT, COLOR_PHASE_G_DEFAULT, COLOR_PHASE_B_DEFAULT);
uniform float ColorAnimationSpeed < ui_type = "slider"; ui_label = "Color Speed"; ui_tooltip = "How fast sunset colors shift."; ui_min = COLOR_ANIM_FACTOR_MIN; ui_max = COLOR_ANIM_FACTOR_MAX; ui_step = 0.01; ui_category = "Color"; > = COLOR_ANIM_FACTOR_DEFAULT;
uniform float ColorBrightnessBoost < ui_type = "slider"; ui_label = "Glow"; ui_tooltip = "Cloud color brightness boost."; ui_min = COLOR_BRIGHTNESS_ADD_MIN; ui_max = COLOR_BRIGHTNESS_ADD_MAX; ui_step = 0.01; ui_category = "Color"; > = COLOR_BRIGHTNESS_ADD_DEFAULT;

// --- Output ---
uniform float Exposure < ui_type = "slider"; ui_label = "Exposure"; ui_tooltip = "Final image brightness."; ui_min = TONEMAP_EXPOSURE_MIN; ui_max = TONEMAP_EXPOSURE_MAX; ui_step = 1e6; ui_category = "Output"; > = TONEMAP_EXPOSURE_DEFAULT;

// --- Advanced (Closed) ---
uniform float AdvMarchStepBase < ui_type = "slider"; ui_label = "Step Base"; ui_tooltip = "Base raymarch step size."; ui_min = MARCH_STEP_BASE_MIN; ui_max = MARCH_STEP_BASE_MAX; ui_step = 0.001; ui_category = "Advanced"; ui_category_closed = true; > = MARCH_STEP_BASE_DEFAULT;
uniform float AdvMarchSDFInfluence < ui_type = "slider"; ui_label = "Step SDF"; ui_tooltip = "Cloud density effect on step size."; ui_min = MARCH_SDF_INFLUENCE_MIN; ui_max = MARCH_SDF_INFLUENCE_MAX; ui_step = 0.01; ui_category = "Advanced"; ui_category_closed = true; > = MARCH_SDF_INFLUENCE_DEFAULT;
uniform float AdvMarchSDFDivisor < ui_type = "slider"; ui_label = "Step Divisor"; ui_tooltip = "Divisor for SDF step influence."; ui_min = MARCH_SDF_DIVISOR_MIN; ui_max = MARCH_SDF_DIVISOR_MAX; ui_step = 0.1; ui_category = "Advanced"; ui_category_closed = true; > = MARCH_SDF_DIVISOR_DEFAULT;
uniform float AdvColorSDFMod < ui_type = "slider"; ui_label = "Color SDF"; ui_tooltip = "Density modulates color."; ui_min = COLOR_SDF_MOD_MIN; ui_max = COLOR_SDF_MOD_MAX; ui_step = 0.001; ui_category = "Advanced"; ui_category_closed = true; > = COLOR_SDF_MOD_DEFAULT;
uniform float AdvColorExpSDFMod < ui_type = "slider"; ui_label = "Color Exp SDF"; ui_tooltip = "Density modulates glow."; ui_min = COLOR_EXP_SDF_MOD_MIN; ui_max = COLOR_EXP_SDF_MOD_MAX; ui_step = 0.001; ui_category = "Advanced"; ui_category_closed = true; > = COLOR_EXP_SDF_MOD_DEFAULT;

// --- Stage/Transform ---
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation)

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 AS_BGX_SunsetClouds_PS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float time = AS_getTime() * AnimationSpeed + AnimationKeyframe;
    float2 iResolution = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float2 fragCoord = vpos.xy;

    // Apply Stage Rotation controls
    float2 uv = texcoord;
    float current_rotationRadians = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
    if (abs(current_rotationRadians) > 0.001f) {
        float s_rot = sin(current_rotationRadians);
        float c_rot = cos(current_rotationRadians);
        uv = float2(
            uv.x * c_rot - uv.y * s_rot,
            uv.x * s_rot + uv.y * c_rot
        );
    }
    float2 centeredCoord = uv * iResolution;

    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);
    // Apply depth test
    if (depth < EffectDepth) {
        return originalColor;
    }

    int i = 0;
    float depth_z = 0.0;
    float step_dist_d_loop;
    float current_march_step_d;
    float signed_dist_s;
    float4 outputColor = float4(0.0, 0.0, 0.0, 0.0);

    // Maintain consistent aspect ratio by using screen width for normalization of both X and Y components
    float aspectRatio = iResolution.x / iResolution.y;
    float3 rayDir = normalize(float3( (2.0 * centeredCoord.x - iResolution.x),
                                      (iResolution.x - 2.0 * centeredCoord.y * aspectRatio),
                                      -iResolution.x) );
    rayDir *= EffectRaymarchDepth;

    for (i = 0; i < CloudDetail; i++) // Using CloudDetail UI
    {
        float3 p = depth_z * rayDir;
        step_dist_d_loop = TurbulenceScaleStart; // Using TurbulenceScaleStart UI
        while(step_dist_d_loop < TurbulenceScaleEnd) // Using TurbulenceScaleEnd UI
        {
            p += TurbulenceIntensity * sin(p.yzx * step_dist_d_loop - TurbulenceAnimFactor * time) / step_dist_d_loop; // Using UI variables
            step_dist_d_loop *= 2.0;
        }

        signed_dist_s = CloudAltitude - abs(p.y); // Using CloudAltitude UI
        current_march_step_d = AdvMarchStepBase + max(signed_dist_s, -signed_dist_s * AdvMarchSDFInfluence) / AdvMarchSDFDivisor; // Using Advanced UI
        depth_z += current_march_step_d;

        float4 current_color_phases = float4(ColorPhase.r, ColorPhase.g, ColorPhase.b, 0.0); // Using ColorPhase UI
        outputColor += (cos(signed_dist_s / AdvColorSDFMod + p.x + ColorAnimationSpeed * time - current_color_phases) + ColorBrightnessBoost) // Using UI variables
                       * exp(signed_dist_s / AdvColorExpSDFMod) / current_march_step_d; // Using Advanced UI
    }

    outputColor = AS_TANH(outputColor * outputColor / Exposure); // Using Exposure UI with compatible tanh approximation
    outputColor.a = 1.0;

    return outputColor;
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_SunsetClouds <
    ui_label = "[AS] BGX: Sunset Clouds";
    ui_tooltip = "Renders animated volumetric clouds at sunset, ported from a GLSL shader by @XorDev. Uses raymarching for cloud rendering.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = AS_BGX_SunsetClouds_PS;
    }
}

#endif // __AS_BGX_SUNSETCLOUDS_1_FX
