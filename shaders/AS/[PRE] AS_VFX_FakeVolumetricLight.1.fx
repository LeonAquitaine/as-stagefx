/**
 * AS_VFX_FakeVolumetricLight.1.fx - 2D Volumetric Light Shafts with Depth Occlusion
 * Author: Leon Aquitaine (Adapted from GLSL shader by an unknown author)
 * License: Creative Commons Attribution 4.0 International
 * Original Shadertoy: https://www.shadertoy.com/view/XdGfRR (assumed based on common source for this effect)
 *
 * DESCRIPTION:
 * Simulates 2D volumetric light shafts (god rays) emanating from a user-defined light source.
 * The light source is considered to be at the specified 'EffectDepth'.
 * Rays and direct light contributions are occluded by scene geometry closer to the camera than 'EffectDepth'.
 *
 * FEATURES:
 * - Interactive light source positioning.
 * - Adjustable light brightness, ray length, and number of ray samples.
 * - Depth-based occlusion: Light source is at 'EffectDepth'; objects in front of this depth block light.
 * - Optional direct lighting on scene elements (only if they are at/behind EffectDepth).
 * - Standard blending options for final composite.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Threshold Pass:
 * - Calculates per-pixel distance to the light source in an aspect-corrected coordinate space.
 * - Retrieves scene depth and compares it to 'EffectDepth' (depth of the light source).
 * - Calculates a depth_occlusion_factor (0 if surface is in front of EffectDepth, 1 if at/behind).
 * - Base light attenuation (f_atten) is modulated by this depth_occlusion_factor. If surface is in front, f_atten becomes 0.
 * - Stores a thresholded light intensity (derived from the now depth-occluded f_atten) into the alpha channel
 * of a dedicated render target texture. This value is used by the blur pass to generate rays.
 * 2. Blur & Composite Pass:
 * - (No change from previous version) For each pixel, it samples along a line towards the light source in the previously generated
 * light intensity texture. Since this texture now has occlusion baked in, rays will appear correctly blocked.
 * - Accumulates these samples with an attenuation factor to create the light shaft effect.
 * - The resulting rays are then blended with the original scene.
 */

#ifndef __AS_VFX_FakeVolumetricLight_1_fx
#define __AS_VFX_FakeVolumetricLight_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Noise.1.fxh"

// ============================================================================
// Render Target Textures & Samplers
// ============================================================================
texture FakeVolumetricLight_ThresholdBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler FakeVolumetricLight_ThresholdSampler { Texture = FakeVolumetricLight_ThresholdBuffer; };

// ============================================================================
// Tunable Constants & UI Definitions
// ============================================================================

// Light Source Settings
AS_POS_UI(LightSourcePos)
static const float LIGHT_BRIGHTNESS_MIN = 0.01; static const float LIGHT_BRIGHTNESS_MAX = 0.5; static const float LIGHT_BRIGHTNESS_DEFAULT = 0.1;
uniform float LightBrightness < ui_type = "slider"; ui_label = "Light Source Brightness"; ui_tooltip = "Intensity of the light source for rays."; ui_min = LIGHT_BRIGHTNESS_MIN; ui_max = LIGHT_BRIGHTNESS_MAX; ui_category = "Light Source"; > = LIGHT_BRIGHTNESS_DEFAULT;

static const float OBJECT_LIGHT_MIN = 0.0; static const float OBJECT_LIGHT_MAX = 0.2; static const float OBJECT_LIGHT_DEFAULT = 0.05;
uniform float ObjectLightFactor < ui_type = "slider"; ui_label = "Object Direct Light Factor"; ui_tooltip = "How much direct light illuminates objects close to the source (if they are not in front of the light's depth plane)."; ui_min = OBJECT_LIGHT_MIN; ui_max = OBJECT_LIGHT_MAX; ui_category = "Light Source"; > = OBJECT_LIGHT_DEFAULT;

static const float LIGHT_THRESHOLD_MIN_VAL = 0.0; static const float LIGHT_THRESHOLD_MAX_VAL = 1.0; static const float LIGHT_THRESHOLD_DEFAULT_MIN = 0.5; static const float LIGHT_THRESHOLD_DEFAULT_MAX = 0.51;
uniform float LightThresholdMin < ui_type = "slider"; ui_label = "Ray Visibility Threshold Min"; ui_min = LIGHT_THRESHOLD_MIN_VAL; ui_max = LIGHT_THRESHOLD_MAX_VAL; ui_category = "Light Source"; > = LIGHT_THRESHOLD_DEFAULT_MIN;
uniform float LightThresholdMax < ui_type = "slider"; ui_label = "Ray Visibility Threshold Max"; ui_min = LIGHT_THRESHOLD_MIN_VAL; ui_max = LIGHT_THRESHOLD_MAX_VAL; ui_category = "Light Source"; > = LIGHT_THRESHOLD_DEFAULT_MAX;

// Ray Casting Settings
static const int RAY_STEPS_MIN = 5; static const int RAY_STEPS_MAX = 60; static const int RAY_STEPS_DEFAULT = 30;
uniform int RaySteps < ui_type = "slider"; ui_label = "Ray Sample Steps"; ui_tooltip = "Number of samples along each ray. Higher is smoother but more expensive."; ui_min = RAY_STEPS_MIN; ui_max = RAY_STEPS_MAX; ui_category = "Ray Properties"; > = RAY_STEPS_DEFAULT;

static const float RAY_LENGTH_MIN = 0.05; static const float RAY_LENGTH_MAX = 0.5; static const float RAY_LENGTH_DEFAULT = 0.25;
uniform float RayLength < ui_type = "slider"; ui_label = "Ray Length Multiplier"; ui_tooltip = "Controls the length of the light rays."; ui_min = RAY_LENGTH_MIN; ui_max = RAY_LENGTH_MAX; ui_category = "Ray Properties"; > = RAY_LENGTH_DEFAULT;

static const float RAY_TIME_SCALE_MIN = 0.0; static const float RAY_TIME_SCALE_MAX = 2000.0; static const float RAY_TIME_SCALE_DEFAULT = 1000.0;
uniform float RayRandomTimeScale < ui_type = "slider"; ui_label = "Ray Jitter Animation Speed"; ui_tooltip = "Speed of the random jitter animation for rays."; ui_min = RAY_TIME_SCALE_MIN; ui_max = RAY_TIME_SCALE_MAX; ui_category = "Ray Properties"; > = RAY_TIME_SCALE_DEFAULT;

// Stage Controls
AS_STAGEDEPTH_UI(EffectDepth) 

// Final Mix
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_LIGHTEN) 
AS_BLENDAMOUNT_UI(BlendAmount)

// ============================================================================
// Helper Functions
// ============================================================================
float2 GetAspectCorrectedCenteredUV(float2 tc)
{
    float2 uv = tc - 0.5;
    if (ReShade::AspectRatio >= 1.0) 
    {
        uv.x *= ReShade::AspectRatio;
    }
    else 
    {
        uv.y /= ReShade::AspectRatio;
    }
    return uv;
}

// ============================================================================
// Pixel Shader: Threshold Pass
// ============================================================================
float4 PS_FakeVolumetricLight_Threshold(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target0
{
    float2 uvn = GetAspectCorrectedCenteredUV(texcoord);

    float2 light_pos_centered = LightSourcePos * 0.5;
    if (ReShade::AspectRatio >= 1.0) light_pos_centered.x *= ReShade::AspectRatio;
    else light_pos_centered.y /= ReShade::AspectRatio;

    // Depth Occlusion: Light source is at EffectDepth.
    // Objects in front of EffectDepth block all light from this source.
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    // depth_occlusion_factor is 1 if sceneDepth is >= EffectDepth (at or behind light source plane), 
    // 0 if sceneDepth < EffectDepth (in front of light source plane).
    float depth_occlusion_factor = saturate(smoothstep(EffectDepth - AS_DEPTH_EPSILON, EffectDepth + AS_DEPTH_EPSILON, sceneDepth));

    float dist_sq = dot(uvn - light_pos_centered, uvn - light_pos_centered);
    float base_f_atten = LightBrightness / (dist_sq + AS_EPSILON);
    // Modulate light attenuation by depth: if surface is in front of light plane, f_atten is 0.
    float f_atten = base_f_atten * depth_occlusion_factor;
    
    float4 scene_sample = tex2D(ReShade::BackBuffer, texcoord); // Using ReShade::BackBuffer as per user confirmation

    // Face lighting only applies if f_atten is non-zero (i.e., surface is not in front of light plane)
    // Clamping min to 0.0, as f_atten might be 0.
    float3 face_lighting_contribution = clamp(ObjectLightFactor * f_atten, 0.0, ObjectLightFactor * 0.5) * scene_sample.rgb;
    
    float background_heuristic = 1.0 - saturate(scene_sample.a + dot(scene_sample.rgb, float3(0.33,0.33,0.33)));
    
    // The color stored in RGB of the buffer. If f_atten is 0, this simplifies significantly.
    // If an object is in front (f_atten=0), its face_lighting_contribution is 0.
    // Then final_color becomes lerp(0, 0, background_heuristic) = 0 if it's background,
    // or lerp(0, scene_sample.rgb (if face_lighting was defined as additive), ...)
    // The original lerp was: lerp(face_lighting_direct_color, color_of_light_on_background, heuristic)
    // Let's keep the original structure, f_atten being 0 handles occlusion naturally.
    float3 final_color_rgb_part = lerp(face_lighting_contribution, float3(f_atten, f_atten, f_atten), background_heuristic);
    
    // Store thresholded light intensity in alpha channel.
    // Since f_atten already includes depth_occlusion_factor, ray_alpha_base will be 0 if occluded.
    float ray_alpha_base = lerp(0.0, smoothstep(LightThresholdMin, LightThresholdMax, f_atten), background_heuristic);
    
    return float4(final_color_rgb_part, ray_alpha_base);
}

// ============================================================================
// Pixel Shader: Radial Blur & Composite Pass
// ============================================================================
float4 PS_FakeVolumetricLight_Composite(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target0
{
    float2 uvn = GetAspectCorrectedCenteredUV(texcoord); 

    float2 light_pos_centered = LightSourcePos * 0.5;
    if (ReShade::AspectRatio >= 1.0) light_pos_centered.x *= ReShade::AspectRatio;
    else light_pos_centered.y /= ReShade::AspectRatio;

    float4 accumulated_rays = float4(0.0, 0.0, 0.0, 0.0);
    float current_time_seed = AS_mod(AS_getTime() * RayRandomTimeScale, 200.0);

    float2 dir_to_light = normalize(light_pos_centered - uvn); 

    for (int i = 0; i < RaySteps; i++)
    {
        float ray_progress = (float(i) / float(RaySteps));
        float2 sample_offset_along_ray = dir_to_light * ray_progress * RayLength;
        
        // Using AS_hash22 as confirmed by user for their AS_Noise.1.fxh
        float2 random_jitter = (AS_hash22(pos.xy + current_time_seed + float(i)) - 0.5) * 0.01 * RayLength;

        float2 sample_pos_centered = uvn + sample_offset_along_ray + random_jitter;
        
        float2 sample_tc = sample_pos_centered;
        if (ReShade::AspectRatio >= 1.0) 
        {
            sample_tc.x /= ReShade::AspectRatio;
        }
        else 
        {
            sample_tc.y *= ReShade::AspectRatio;
        }
        sample_tc += 0.5;

        if (all(sample_tc >= 0.0) && all(sample_tc <= 1.0)) 
        {
            float light_intensity_at_sample = tex2D(FakeVolumetricLight_ThresholdSampler, sample_tc).a;
            float attenuation_along_ray = 1.0 - pow(ray_progress, 0.45); 
            
            accumulated_rays.rgb += light_intensity_at_sample * attenuation_along_ray;
            accumulated_rays.a += attenuation_along_ray; 
        }
    }

    if (accumulated_rays.a > AS_EPSILON)
    {
        accumulated_rays.rgb /= accumulated_rays.a;
    }
    
    float4 original_scene_color = tex2D(ReShade::BackBuffer, texcoord); // Using ReShade::BackBuffer
    return AS_applyBlend(float4(accumulated_rays.rgb, 1.0), original_scene_color, BlendMode, BlendAmount);
}

// ============================================================================
// Technique Definition
// ============================================================================
technique AS_VFX_FakeVolumetricLight < ui_tooltip = "Simulates 2D volumetric light shafts. Light source at 'EffectDepth'; objects in front block light."; >
{
    pass ThresholdPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_FakeVolumetricLight_Threshold;
        RenderTarget = FakeVolumetricLight_ThresholdBuffer;
    }
    pass BlurAndCompositePass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_FakeVolumetricLight_Composite;
    }
}

#endif // __AS_VFX_FakeVolumetricLight_1_fx