/**
 * AS_BGX_MistyGrid.1.fx - Abstract Fractal Grid Background
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Based on "Misty Grid" by NuSan
 * Shadertoy: https://www.shadertoy.com/view/wl2Szd
 * Created: 2019-08-26
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates an abstract fractal-based grid background with a misty, ethereal appearance.
 * This shader uses raymarching techniques to generate complex 3D structures with depth.
 *
 * FEATURES:
 * - Dynamic fractal-based grid environment
 * - Customizable colors with palette system
 * - Position, scale and rotation controls
 * - Audio reactivity for dynamic visual performance
 * - Animation speed and camera controls
 * 
 * IMPLEMENTATION OVERVIEW:
 * 1. Uses raymarching against a signed distance field (SDF) to create 3D structure
 * 2. Applies domain folding and repetition for complex fractal patterns
 * 3. Implements camera movement simulation with smooth rotations
 * 4. Combines multiple SDFs using boolean operations for varied visual effects
 * 5. Applies color grading with customizable palette system
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_MistyGrid_1_fx
#define __AS_BGX_MistyGrid_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"      // Basic ReShade utilities
#include "AS_Utils.1.fxh"   // AS common utilities
#include "AS_Palette.1.fxh" // AS palette system
#include "AS_Noise.1.fxh"   // AS noise utilities

//------------------------------------------------------------------------------------------------
// CONSTANTS
//------------------------------------------------------------------------------------------------
static const int MAX_MARCHING_STEPS = 80;       // Maximum number of raymarch steps
static const float SURFACE_DISTANCE = 0.001;   // Distance considered close enough to surface
static const float MAX_DISTANCE = 100.0;       // Maximum raymarch distance
static const float DOMAIN_FOLDING_SCALE = 10.0; // Scale for domain folding

// Domain transformation constants
static const float ROT_SPEED_XY = 0.3;         // Rotation speed for XY plane
static const float ROT_SPEED_YZ = 0.4;         // Rotation speed for YZ plane
static const float ROT_Z_FACTOR = 0.023;       // Z-dependent rotation factor
static const float ROT_TIME_FACTOR = 0.1;      // Time-dependent rotation factor
static const float ROT_X_FACTOR = 0.087;       // X-dependent rotation factor

// Fractal constants
static const float FR1_TIME_FACTOR = 0.2;      // Time factor for first fractal
static const float FR2_TIME_FACTOR = 0.23;     // Time factor for second fractal
static const float FR2_OFFSET_X = 5.0;         // X offset for second fractal

// Box dimension constants
static const float3 BOX1_SIZE = float3(1.0, 1.3, 4.0);  // Size for first box
static const float3 BOX2_SIZE = float3(3.0, 0.7, 0.4);  // Size for second box
static const float3 BOX3_SIZE = float3(0.4, 0.4, 0.4);  // Size for third box
static const float3 BOUNDARY_BOX_SIZE = float3(4.0, 4.0, 4.0); // Size for boundary box

// Boolean operation constants
static const float BOOLEAN_OFFSET = 0.2;       // Offset for boolean operation
static const float BOOLEAN_FACTOR = 0.4;       // Factor for boolean subtraction

// Accumulator constants
static const float AT1_FACTOR = 0.13;          // Factor for first accumulator
static const float AT2_FACTOR = 0.2;           // Factor for second accumulator
static const float AT2_DENOMINATOR = 0.15;     // Denominator for second accumulator
static const float AT3_FACTOR = 0.2;           // Factor for third accumulator
static const float AT3_DENOMINATOR = 0.5;      // Denominator for third accumulator

// Camera and scene constants
static const float CAMERA_Z_DISTANCE = -15.0;  // Initial Z distance for camera
static const float CAM_TIME_FACTOR = 0.1;      // Time factor for camera animation
static const float CAM_ZX_TIME_FACTOR = 1.2;   // Time factor for ZX plane camera rotation
static const float STEP_MIN_FACTOR = 0.01;     // Minimum step factor
static const float STEP_DISTANCE_LIMIT = 6.0;  // Distance limit for step calculation

// Color and visualization constants
static const float COLOR_EXPONENT = 8.0;       // Exponent for color interpolation
static const float COLOR_BLEND = 0.5;          // Blend factor between primary and secondary colors
static const float3 LUMA_WEIGHTS = float3(0.2126, 0.7152, 0.0722); // Standard Rec. 709 luma weights
static const float COLOR_BRIGHTNESS_MULT = 15.0; // Multiplier for brightness adjustment
static const float DEBUG_SCALE = 0.05;         // Scale factor for debug visualization

// Final color processing constants
static const float ACCUMULATOR2_SCALE = 0.008; // Scale for second accumulator in final color
static const float ACCUMULATOR3_SCALE = 0.072; // Scale for third accumulator in final color
static const float ACCUMULATOR3_EXPONENT = 2.0; // Exponent for third accumulator
static const float3 ACCUMULATOR3_TINT = float3(0.7, 0.3, 1.0); // Tint for third accumulator
static const float ACCUMULATOR3_BRIGHTNESS = 2.0; // Brightness multiplier for third accumulator
static const float VIGNETTE_SIZE = 1.2;        // Size factor for vignette

//------------------------------------------------------------------------------------------------
// UNIFORMS - Following AS StageFX standards
//------------------------------------------------------------------------------------------------

// Fractal Parameters











uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nBased on '[twitch] Misty Grid' by NuSan\nLink: https://www.shadertoy.com/view/wl2Szd\nLicence: CC Share-Alike Non-Commercial\n\n";>;

uniform float FractalScale < ui_type = "slider"; ui_label = "Fractal Scale"; ui_tooltip = "Controls the overall scale of the fractal pattern"; ui_category = "Fractal Parameters"; ui_min = 0.1; ui_max = 2.0; > = 0.7;
uniform float FractalIterations < ui_type = "slider"; ui_label = "Detail Level"; ui_tooltip = "Controls the amount of detail in the fractal pattern"; ui_category = "Fractal Parameters"; ui_min = 1.0; ui_max = 5.0; ui_step = 1.0; > = 5.0;
uniform float FoldingAmount < ui_type = "slider"; ui_label = "Folding Intensity"; ui_tooltip = "Controls how tightly the pattern folds on itself"; ui_category = "Fractal Parameters"; ui_min = 5.0; ui_max = 15.0; > = 10.0;

// Color Controls
AS_PALETTE_SELECTION_UI(ColorPalette, "Color Palette", AS_PALETTE_CUSTOM, "Color Settings")
AS_DECLARE_CUSTOM_PALETTE(MistyGrid_, "Color Settings")
uniform float ColorSaturation < ui_type = "slider"; ui_label = "Saturation"; ui_tooltip = "Adjusts the saturation of the colors"; ui_category = "Color Settings"; ui_min = 0.0; ui_max = 2.0; > = 1.0;
uniform float ColorBrightness < ui_type = "slider"; ui_label = "Brightness"; ui_tooltip = "Adjusts the brightness of the effect"; ui_category = "Color Settings"; ui_min = 0.0; ui_max = 2.0; > = 1.0;

// Camera Controls
uniform float CameraSpeed < ui_type = "slider"; ui_label = "Camera Speed"; ui_tooltip = "Controls how fast the camera moves through the scene"; ui_category = "Camera"; ui_min = 0.0; ui_max = 2.0; > = 0.5;
uniform float CameraZoom < ui_type = "slider"; ui_label = "Camera Zoom"; ui_tooltip = "Adjusts the camera field of view"; ui_category = "Camera"; ui_min = 0.5; ui_max = 2.0; > = 1.0;

// Audio Reactivity
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_VOLUME, "Audio Reactivity")
AS_AUDIO_MULT_UI(AudioMultiplier, "Audio Multiplier", 1.0, 2.0, "Audio Reactivity")
uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target"; ui_tooltip = "Select which parameter will react to audio"; ui_items = "Fractal Scale\0Folding Intensity\0Saturation\0Brightness\0Camera Zoom\0Animation Speed\0All\0"; ui_category = "Audio Reactivity"; > = 0;

// Animation Controls
AS_ANIMATION_UI(AnimSpeed, AnimKeyframe, "Animation")

// Standard AS Controls
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation)
AS_POSITION_SCALE_UI(EffectPosition, EffectScale)

// Final Mix (Blend) Controls
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// Debug Controls  
AS_DEBUG_UI("Off\0Show Accumulator 1\0Show Accumulator 2\0Show Accumulator 3\0Show Raw Distance\0Show Audio Reactivity\0")

//------------------------------------------------------------------------------------------------
// Helper Functions
//------------------------------------------------------------------------------------------------

// Standard rotation matrix function
float2x2 rot_hlsl(float a) {
    float ca = cos(a);
    float sa = sin(a);
    return float2x2(ca, sa, -sa, ca);
}

// Box signed distance function (SDF)
float box_hlsl(float3 p, float3 s) {
    p = abs(p) - s;
    return max(p.x, max(p.y, p.z));
}

/**
 * Fractal iteration function. * @param p Input point.
 * @param t_param Time-dependent parameter for this iteration step
 * @param effect_time Overall animation time (from MainPS's 'local_time').
 * @param fold_amount Folding intensity value, possibly modified by audio reactivity.
 */
float3 fr_hlsl(float3 p, float t_param, float effect_time, float fold_amount) {
    // Scale factor animation that pulses based on time
    float s_factor = FractalScale - smoothstep(0.0, 1.0, abs(frac(effect_time * 0.1) - 0.5) * 2.0) * 0.3;
    
    // Process audio reactivity if enabled for Fractal Scale
    if (AudioSource != AS_AUDIO_OFF && (AudioTarget == 0 || AudioTarget == 6)) { // Fractal Scale or All
        float audioValue = AS_applyAudioReactivity(1.0, AudioSource, AudioMultiplier, true) - 1.0;
        s_factor += audioValue * 0.3;
    }
    
    // The loop should be unrollable by the compiler as it's small and fixed.
    int iterations = clamp((int)FractalIterations, 1, 5);
    for (int i = 0; i < iterations; ++i) {
        float t2 = t_param + (float)i;        p.xy = mul(p.xy, rot_hlsl(t2));
        p.yz = mul(p.yz, rot_hlsl(t2 * 0.7));

        float fold_dist = fold_amount;
        p = (frac(p / fold_dist - 0.5) - 0.5) * fold_dist; // Domain folding
        p = abs(p);
        p -= s_factor; // Apply scaling/offset
    }
    return p;
}

/**
 * Main distance estimator function (SDF map).
 * @param p Point in space to sample. * @param effect_time Overall animation time.
 * @param at_acc Accumulator 1 (passed by reference).
 * @param at2_acc Accumulator 2 (passed by reference).
 * @param at3_acc Accumulator 3 (passed by reference).
 * @param fold_amount Folding intensity value, possibly modified by audio reactivity.
 * @return Signed distance to the surface.
 */
float map_hlsl(float3 p, float effect_time, inout float at_acc, inout float at2_acc, inout float at3_acc, float foldingAmountFinal) {
    float3 initial_p = p; // Store original p for some calculations (bp in GLSL)
    
    // Get rotation angle from UI controls
    float rotationAngle = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);

    // Apply rotation to the initial space
    float2x2 rotMat = rot_hlsl(rotationAngle);
    p.xy = mul(p.xy, rotMat);
      // Initial rotations based on p's components and time
    p.xy = mul(p.xy, rot_hlsl((p.z * ROT_Z_FACTOR + effect_time * ROT_TIME_FACTOR) * ROT_SPEED_XY));
    p.yz = mul(p.yz, rot_hlsl((p.x * ROT_X_FACTOR) * ROT_SPEED_YZ));

    float t_map_internal = effect_time * 0.5; // Corresponds to 't' inside GLSL map
    float3 p_fr1 = fr_hlsl(p, t_map_internal * FR1_TIME_FACTOR, effect_time, foldingAmountFinal);
    float3 p_fr2 = fr_hlsl(p + float3(FR2_OFFSET_X, 0.0, 0.0), t_map_internal * FR2_TIME_FACTOR, effect_time, foldingAmountFinal);

    float d1 = box_hlsl(p_fr1, BOX1_SIZE);
    float d2 = box_hlsl(p_fr2, BOX2_SIZE);

    // Combine distances and apply further modifications
    float d = max(abs(d1), abs(d2)) - BOOLEAN_OFFSET; // Note: abs(d1), abs(d2) used here.
    
    float fold_dist_map = 1.0;
    float3 p_box3 = (frac(p_fr1 / fold_dist_map - 0.5) - 0.5) * fold_dist_map; // Using p_fr1 for this box
    float d3 = box_hlsl(p_box3, BOX3_SIZE);
    d = d - d3 * BOOLEAN_FACTOR; // Subtracting another SDF (boolean subtraction or erosion)    // Accumulate 'at_acc' based on proximity to the current surface 'd'
    at_acc += AT1_FACTOR / (AT1_FACTOR + abs(d));

    // Further SDF operations using the initial point 'initial_p'
    float d5_box_boundary = box_hlsl(initial_p, BOUNDARY_BOX_SIZE);
    
    float fold_dist2_map = 8.0;
    float3 p_sphere_like = initial_p;
    p_sphere_like.z = abs(p_sphere_like.z) - 13.0;
    p_sphere_like.x = (frac(p_sphere_like.x / fold_dist2_map - 0.5) - 0.5) * fold_dist2_map;
    float d6_sphere_like = length(p_sphere_like.xz) - 1.0;

    // Accumulate 'at2_acc' and 'at3_acc'
    at2_acc += AT2_FACTOR / (AT2_DENOMINATOR + abs(d5_box_boundary));
    at3_acc += AT3_FACTOR / (AT3_DENOMINATOR + abs(d6_sphere_like));
    
    return d; // Return the final distance estimate for this point
}

// Camera transformation function
void cam_hlsl(inout float3 p, float effect_time, float rotationAngle) {
    float t_cam_internal = effect_time * CAM_TIME_FACTOR * CameraSpeed; // Apply camera speed

    // Apply standard rotation
    float2x2 baseCamRot = rot_hlsl(rotationAngle);
    p.xy = mul(p.xy, baseCamRot);
    
    // Apply animated rotations
    p.yz = mul(p.yz, rot_hlsl(t_cam_internal));
    p.zx = mul(p.zx, rot_hlsl(t_cam_internal * CAM_ZX_TIME_FACTOR));
}

// Note: Using AS_randomNoise21 from AS_Noise.1.fxh instead of a custom implementation
//------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------
// Note: We're using the standard AS_applyBlend function from AS_Utils.1.fxh instead of a custom implementation
//------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------
// Pixel Shader
//------------------------------------------------------------------------------------------------
float4 MainPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{    // Get original background color
    float4 background = tex2D(ReShade::BackBuffer, texcoord);
      // Get depth and apply depth test
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth) {
        return background;
    }
    
    // Process audio reactivity for parameters other than Fractal Scale
    float audioReactiveMultiplier = 1.0;
    float foldingAmountFinal = FoldingAmount;
    float colorSaturationFinal = ColorSaturation;
    float colorBrightnessFinal = ColorBrightness;
    float cameraZoomFinal = CameraZoom;
    float animSpeedFinal = AnimSpeed;
    
    if (AudioSource != AS_AUDIO_OFF) {
        float audioValue = AS_applyAudioReactivity(1.0, AudioSource, AudioMultiplier, true);
        
        // Apply audio reactivity based on target
        if (AudioTarget == 1 || AudioTarget == 6) { // Folding Intensity or All
            foldingAmountFinal *= audioValue;
        }
        if (AudioTarget == 2 || AudioTarget == 6) { // Saturation or All
            colorSaturationFinal *= audioValue;
        }
        if (AudioTarget == 3 || AudioTarget == 6) { // Brightness or All
            colorBrightnessFinal *= audioValue;
        }
        if (AudioTarget == 4 || AudioTarget == 6) { // Camera Zoom or All
            cameraZoomFinal *= audioValue;
        }
        if (AudioTarget == 5 || AudioTarget == 6) { // Animation Speed or All
            animSpeedFinal *= audioValue;
        }
    }    // Calculate local_time using AS_getAnimationTime with animation speed and keyframe
    float local_time = AS_getAnimationTime(animSpeedFinal, AnimKeyframe);

    // Apply standard AS coordinate transformations
    float2 centerCoord = texcoord - 0.5; // Center coords
    centerCoord.x *= ReShade::AspectRatio; // Correct aspect ratio
    centerCoord = AS_applyPosScale(centerCoord, EffectPosition, EffectScale);

    // Initialize accumulators for this pixel
    float at_accumulator = 0.0;
    float at2_accumulator = 0.0;
    float at3_accumulator = 0.0;

    // Factor for raymarching step modification
    float factor = 0.9 + 0.1 * AS_randomNoise21(texcoord);     // Get rotation angle from UI controls
    float rotationAngle = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);    // Ray setup
    float3 ray_origin = float3(0.0, 0.0, CAMERA_Z_DISTANCE * cameraZoomFinal);
    float3 ray_direction = normalize(float3(centerCoord, 1.0));

    // Apply camera transformations
    cam_hlsl(ray_origin, local_time, rotationAngle);
    cam_hlsl(ray_direction, local_time, rotationAngle);

    float3 current_ray_pos = ray_origin;
    int iteration_count = 0;    [loop]
    for (int i = 0; i < MAX_MARCHING_STEPS; ++i) {
        iteration_count = i;
        float dist_to_surface = map_hlsl(current_ray_pos, local_time, at_accumulator, at2_accumulator, at3_accumulator, foldingAmountFinal);
        
        // Step logic
        float d_abs_map = abs(dist_to_surface);
        float d_step = abs(max(d_abs_map, -(length(current_ray_pos - ray_origin) - STEP_DISTANCE_LIMIT)));
        d_step *= factor;

        if (d_step < SURFACE_DISTANCE) {
            d_step = STEP_MIN_FACTOR;
        }
        
        current_ray_pos += ray_direction * d_step;

        // Far plane escape condition
        if (length(current_ray_pos - ray_origin) > MAX_DISTANCE) {
            break;
        }
    }    // Color calculation based on accumulators
    float3 final_color = float3(0.0, 0.0, 0.0);

    // Base sky color calculation
    float3 sky_color_primary, sky_color_secondary, sky_color;
    
    // Get interpolation parameters
    float primary_t = pow(abs(ray_direction.z), COLOR_EXPONENT);
    float secondary_t = pow(abs(ray_direction.y), COLOR_EXPONENT);
    
    if (ColorPalette == AS_PALETTE_CUSTOM) {
        // Use custom palette colors with the AS_GET_INTERPOLATED_CUSTOM_COLOR macro
        sky_color_primary = AS_GET_INTERPOLATED_CUSTOM_COLOR(MistyGrid_, primary_t);
        sky_color_secondary = AS_GET_INTERPOLATED_CUSTOM_COLOR(MistyGrid_, secondary_t);
    } else {
        // Use standard palette colors
        sky_color_primary = AS_getInterpolatedColor(ColorPalette, primary_t);
        sky_color_secondary = AS_getInterpolatedColor(ColorPalette, secondary_t);
    }
    
    // Blend primary and secondary colors
    sky_color = lerp(sky_color_primary, sky_color_secondary, COLOR_BLEND);

    // Apply the accumulators to create the final color
    final_color += pow(at2_accumulator * ACCUMULATOR2_SCALE, 1.0) * sky_color;
    final_color += pow(at3_accumulator * ACCUMULATOR3_SCALE, ACCUMULATOR3_EXPONENT) * sky_color * ACCUMULATOR3_TINT * ACCUMULATOR3_BRIGHTNESS;
    
    // Apply vignette
    final_color *= (VIGNETTE_SIZE - length(texcoord - 0.5));

    // Apply color adjustments with audio reactivity
    final_color = 1.0 - exp(-final_color * COLOR_BRIGHTNESS_MULT * colorBrightnessFinal);
    
    // Apply saturation adjustment with audio reactivity
    float luma = dot(final_color, LUMA_WEIGHTS);
    final_color = lerp(float3(luma, luma, luma), final_color, colorSaturationFinal);
      // Debug View handling
    if (DebugMode == 1) { // Show Accumulator 1
        return float4(at_accumulator * DEBUG_SCALE, 0, 0, 1);
    } 
    else if (DebugMode == 2) { // Show Accumulator 2
        return float4(0, at2_accumulator * DEBUG_SCALE, 0, 1);
    }
    else if (DebugMode == 3) { // Show Accumulator 3
        return float4(0, 0, at3_accumulator * DEBUG_SCALE, 1);
    }    
    else if (DebugMode == 4) { // Show Raw Distance
        float dist = map_hlsl(ray_origin, local_time, at_accumulator, at2_accumulator, at3_accumulator, foldingAmountFinal);
        return float4(abs(dist) * 0.1, 0, 0, 1);
    }
    else if (DebugMode == 5) { // Show Audio Reactivity
        if (AudioSource != AS_AUDIO_OFF) {
            float audioValue = AS_applyAudioReactivity(1.0, AudioSource, AudioMultiplier, true);
            float audioVisualization = pow(audioValue, 2.0) * 5.0; // Exaggerate for visibility
            
            // Create a small meter in the corner
            float2 debugCenter = float2(0.1, 0.9);
            float debugRadius = 0.05;
            float debugWidth = 0.2;
            float debugHeight = 0.05;
            
            // Draw meter background
            if (texcoord.x >= debugCenter.x - debugWidth/2 && 
                texcoord.x <= debugCenter.x + debugWidth/2 &&
                texcoord.y >= debugCenter.y - debugHeight/2 &&
                texcoord.y <= debugCenter.y + debugHeight/2) {
                
                // Create meter fill based on audio value
                float normalizedX = (texcoord.x - (debugCenter.x - debugWidth/2)) / debugWidth;
                if (normalizedX <= audioValue) {
                    // Gradient color based on intensity
                    float3 meterColor = lerp(float3(0.0, 1.0, 0.0), float3(1.0, 0.0, 0.0), normalizedX);
                    return float4(meterColor, 1.0);
                }
                else {
                    // Meter background
                    return float4(0.2, 0.2, 0.2, 1.0);
                }
            }
            
            // Show which parameter is affected
            float textY = debugCenter.y + debugHeight;
            float textHeight = 0.02;
            if (texcoord.x >= debugCenter.x - debugWidth/2 && 
                texcoord.x <= debugCenter.x + debugWidth/2 &&
                texcoord.y >= textY &&
                texcoord.y <= textY + textHeight) {
                
                float3 targetColor;
                switch(AudioTarget) {
                    case 0: targetColor = float3(1.0, 0.0, 0.0); break; // Fractal Scale
                    case 1: targetColor = float3(0.0, 1.0, 0.0); break; // Folding Intensity
                    case 2: targetColor = float3(0.0, 0.0, 1.0); break; // Saturation
                    case 3: targetColor = float3(1.0, 1.0, 0.0); break; // Brightness
                    case 4: targetColor = float3(1.0, 0.0, 1.0); break; // Camera Zoom
                    case 5: targetColor = float3(0.0, 1.0, 1.0); break; // Animation Speed
                    default: targetColor = float3(1.0, 1.0, 1.0); break; // All
                }
                return float4(targetColor, 1.0);
            }
        }
    }    // Final composition
    float4 result = float4(final_color, 1.0);
    result = AS_applyBlend(result, background, BlendMode, BlendAmount);
    
    return result;
}

//------------------------------------------------------------------------------------------------
// Technique Definition
//------------------------------------------------------------------------------------------------
technique AS_BGX_MistyGrid <
    ui_label = "[AS] BGX: Misty Grid";
    ui_tooltip = "Abstract fractal grid background for creating ethereal 3D spaces.";
>
{
    pass
    {
        VertexShader = PostProcessVS; // Standard ReShade fullscreen vertex shader
        PixelShader = MainPS;       // Our raymarching pixel shader
    }
}

#endif // __AS_BGX_MistyGrid_1_fx
















