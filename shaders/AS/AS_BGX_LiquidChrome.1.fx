/**
 * AS_BGX_LiquidChrome.1.fx - Psychedelic Liquid Chrome Flowing Background
 * Author: Leon Aquitaine (Original by iamsaitam)
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates dynamic, flowing psychedelic patterns reminiscent of liquid metal or chrome.
 * This shader iteratively distorts screen coordinates, creating complex, flowing patterns 
 * with optional vertical stripe overlays for additional visual texture.
 *
 * FEATURES:
 * - Procedurally generated flowing liquid-like patterns with metallic quality
 * - Fully customizable colors and intensity with RGB phase controls
 * - Dynamic animation with adjustable flow speeds and strengths
 * - Optional vertical stripe overlays with customizable density
 * - Audio reactivity with various target parameters
 * - Standard positioning, rotation, scale, and depth controls
 * - Resolution-independent rendering for consistent results at any aspect ratio
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Iteratively warps screen coordinates using sin/cos over time
 * 2. Calculates a color value based on warped coordinate lengths
 * 3. Optionally adds vertical stripe patterns through additional iterations
 * 4. Applies color phasing for psychedelic effects with fine-tune controls
 * 5. Modulates parameters with audio when enabled
 * 6. Provides standard rotation, position, scale, and blend features
 *
 * Original source: https://neort.io/art/bkm813c3p9f7drq1j86g - "liquid chrome" by iamsaitam
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_LiquidChrome_1_fx
#define __AS_BGX_LiquidChrome_1_fx

#include "ReShade.fxh" // Required for ReShade specific uniforms and functions
#include "AS_Utils.1.fxh" // For utilities, constants, and standard functions

// ============================================================================
// STANDARD CONTROLS
// ============================================================================


// --- Audio Reactivity Controls ---
AS_AUDIO_SOURCE_UI(LiquidChrome_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(LiquidChrome_AudioMultiplier, "Audio Intensity", 1.0, 2.0, "Audio Reactivity")

// --- Audio Target Selection ---
uniform int LiquidChrome_AudioTarget <
    ui_type = "combo";
    ui_label = "Audio Target";
    ui_tooltip = "Select which parameter will be modulated by audio";
    ui_items = "None\0Flow Speed\0Color Cycle\0Pattern Scale\0";
    ui_category = "Audio Reactivity";
> = 2;

// --- Tunable Uniforms with Artist-Friendly Labels ---
uniform float coord_scale <
    ui_type = "drag"; ui_min = 1.0; ui_max = 50.0; ui_step = 0.1;
    ui_label = "Pattern Detail Scale";
    ui_tooltip = "Adjusts the overall size of the psychedelic patterns. Higher values zoom in, revealing finer details and faster perceived motion.";
    ui_category = "Pattern Shape";
> = 10.0f;

uniform int warp_iterations <
    ui_type = "drag"; ui_min = 1; ui_max = 20; ui_step = 1;
    ui_label = "Warp Complexity";
    ui_tooltip = "Increases the intricacy and 'folding' of the core warped pattern. More iterations lead to deeper, more detailed distortions.";
    ui_category = "Pattern Shape";
> = 5;

uniform float warp_time_factor_x <
    ui_type = "drag"; ui_min = 0.0; ui_max = 0.5; ui_step = 0.001;
    ui_label = "Horizontal Flow Speed";
    ui_tooltip = "Controls the speed of the horizontal animation or 'breathing' in the main warp pattern.";
    ui_category = "Animation";
> = 0.07f;

uniform float warp_offset_amp_x <
    ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Horizontal Flow Strength";
    ui_tooltip = "Determines how much the pattern animates or 'breathes' along the horizontal axis.";
    ui_category = "Animation";
> = 0.2f;

uniform float warp_time_factor_y <
    ui_type = "drag"; ui_min = 0.0; ui_max = 0.5; ui_step = 0.001;
    ui_label = "Vertical Flow Speed";
    ui_tooltip = "Controls the speed of the vertical animation or 'undulation' in the main warp pattern.";
    ui_category = "Animation";
> = 0.1f;

uniform float len_post_warp_cos_factor <
    ui_type = "drag"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01;
    ui_label = "Color Band Frequency";
    ui_tooltip = "Adjusts the density of color bands or concentric rings overlaying the pattern. Higher values create more, tighter bands.";
    ui_category = "Color Pattern";
> = 0.4f;

uniform float len_post_warp_subtract <
    ui_type = "drag"; ui_min = -20.0; ui_max = 20.0; ui_step = 0.1; // Expanded range for more shift
    ui_label = "Color Band Offset";
    ui_tooltip = "Shifts the phase or starting point of the color banding/ring pattern, affecting color distribution.";
    ui_category = "Color Pattern";
> = 10.0f;

uniform int stripe_iterations <
    ui_type = "drag"; ui_min = 0; ui_max = 10; ui_step = 1;
    ui_label = "Vertical Line Layers";
    ui_tooltip = "Number of overlaid vertical stripe patterns. Each layer adds more lines with different spacing. Set to 0 to disable stripes.";
    ui_category = "Vertical Lines";
> = 5;

uniform float stripe_period_base <
    ui_type = "drag"; ui_min = 0.005; ui_max = 0.5; ui_step = 0.001; // Min slightly lower for very dense option
    ui_label = "Vertical Line Spacing";
    ui_tooltip = "Controls the fundamental spacing of the vertical line patterns. Smaller values create denser, more frequent lines.";
    ui_category = "Vertical Lines";
> = 0.09f;

uniform float stripe_scale <
    ui_type = "drag"; ui_min = 10.0; ui_max = 1000.0; ui_step = 1.0;
    ui_label = "Vertical Line Sharpness";
    ui_tooltip = "Adjusts the sharpness or definition of the vertical lines. Higher values can make lines thinner and more pronounced.";
    ui_category = "Vertical Lines";
> = 200.0f;

uniform float color_phase_r <
    ui_type = "drag"; ui_min = -6.28318; ui_max = 6.28318; ui_step = 0.01; // Approx -2PI to 2PI
    ui_label = "Red Hue Cycle";
    ui_tooltip = "Shifts the color palette by adjusting the cycle for the red channel. Experiment for different color schemes.";
    ui_category = "Color Tuning";
> = 0.2f;

uniform float color_phase_g <
    ui_type = "drag"; ui_min = -6.28318; ui_max = 6.28318; ui_step = 0.01;
    ui_label = "Green Hue Cycle";
    ui_tooltip = "Shifts the color palette by adjusting the cycle for the green channel.";
    ui_category = "Color Tuning";
> = 0.1f;

uniform float color_phase_b <
    ui_type = "drag"; ui_min = -6.28318; ui_max = 6.28318; ui_step = 0.01;
    ui_label = "Blue Hue Cycle";
    ui_tooltip = "Shifts the color palette by adjusting the cycle for the blue channel.";
    ui_category = "Color Tuning";
> = -0.05f;

uniform float color_r_multiplier <
    ui_type = "drag"; ui_min = 0.0; ui_max = 3.0; ui_step = 0.01;
    ui_label = "Red Intensity";
    ui_tooltip = "Controls the overall intensity or brightness of the red color channel.";
    ui_category = "Color Tuning";
> = 1.15f;

uniform float background_gradient_strength <
    ui_type = "drag"; ui_min = 0.0; ui_max = 0.1; ui_step = 0.001;
    ui_label = "Distortion Tint Strength";
    ui_tooltip = "Controls the intensity of a color tint that is mixed in based on the final warped coordinates.";
    ui_category = "Color Tuning";
> = 0.01f;

uniform float4 background_base_color <
    ui_type = "color";
    ui_label = "Distortion Tint Color";
    ui_tooltip = "Sets the color of the tint mixed in based on the final warped coordinates, affecting the overall image tone.";
    ui_category = "Color Tuning";
> = float4(0.05, 0.07, 0.10, 0.0);

// --- Animation Controls ---
AS_ANIMATION_SPEED_UI(LiquidChrome_AnimationSpeed, "Animation")
AS_ANIMATION_KEYFRAME_UI(LiquidChrome_AnimationKeyframe, "Animation")

// --- Stage Controls ---
AS_STAGEDEPTH_UI(LiquidChrome_EffectDepth)
AS_ROTATION_UI(LiquidChrome_SnapRotation, LiquidChrome_FineRotation)
AS_POSITION_SCALE_UI(LiquidChrome_Position, LiquidChrome_Scale)

// --- Blend Controls ---
AS_BLENDMODE_UI(LiquidChrome_BlendMode)
AS_BLENDAMOUNT_UI(LiquidChrome_BlendAmount)

// Internal constant for safety, not a UI tunable
static const float SAFE_DENOMINATOR_EPSILON = 1e-6f;

// --- Pixel Shader ---
float4 PS_LiquidChrome(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // Get original pixel color and perform depth check
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);
    
    // Early return based on depth
    if (depth < LiquidChrome_EffectDepth - AS_DEPTH_EPSILON)
        return orig;    // Get animation time with speed and keyframe support
    float time = AS_getAnimationTime(LiquidChrome_AnimationSpeed, LiquidChrome_AnimationKeyframe);
    
    // Apply audio reactivity to selected parameter based on audio target
    float audioMod = AS_applyAudioReactivity(1.0, LiquidChrome_AudioSource, LiquidChrome_AudioMultiplier, true) - 1.0;
    float flowSpeedMod = (LiquidChrome_AudioTarget == 1) ? 1.0 + audioMod : 1.0;
    float colorCycleMod = (LiquidChrome_AudioTarget == 2) ? audioMod * 0.5 : 0.0;
    float patternScaleMod = (LiquidChrome_AudioTarget == 3) ? 1.0 + audioMod : 1.0;
    
    // Apply standard coordinate transformation with proper aspect ratio handling
    // Step 1: Center coordinates and apply aspect ratio correction
    float aspectRatio = ReShade::AspectRatio;
    float2 centered_coord;
    
    if (aspectRatio >= 1.0) { // Wider or square
        centered_coord.x = (texcoord.x - 0.5) * aspectRatio;
        centered_coord.y = texcoord.y - 0.5;
    } else { // Taller
        centered_coord.x = texcoord.x - 0.5;
        centered_coord.y = (texcoord.y - 0.5) / aspectRatio;
    }
    
    // Step 2: Apply rotation
    float2 rotated_coord = centered_coord;
    float globalRotation = AS_getRotationRadians(LiquidChrome_SnapRotation, LiquidChrome_FineRotation);
    if (globalRotation != 0) {
        float sinRot, cosRot;
        sincos(-globalRotation, sinRot, cosRot); // Negative for clockwise rotation
        rotated_coord.x = centered_coord.x * cosRot - centered_coord.y * sinRot;
        rotated_coord.y = centered_coord.x * sinRot + centered_coord.y * cosRot;
    }
    
    // Step 3: Apply scale and position
    rotated_coord = rotated_coord / LiquidChrome_Scale;
    rotated_coord.x -= LiquidChrome_Position.x;
    rotated_coord.y -= LiquidChrome_Position.y;
    
    // Step 4: Transform back to UV space (still centered)
    float2 coord = rotated_coord;
    float2 st = coord; // Store original pattern coords for vertical stripes
    
    // Adjust pattern scale based on audio if selected
    float appliedCoordScale = coord_scale * patternScaleMod;
    coord *= appliedCoordScale;
      float len = 0.0f;
    
    // We already applied aspect ratio correction in the coordinate transformation
    // No need to apply it again here
    
    // First Loop: Iterative Coordinate Warping
    for (int i = 0; i < warp_iterations; i++) 
    {
        len = length(coord);
        coord.x += cos(coord.y + sin(len)) + cos(time * warp_time_factor_x * flowSpeedMod) * warp_offset_amp_x;
        coord.y += sin(coord.x + cos(len)) + sin(time * warp_time_factor_y * flowSpeedMod);
    }
    
    len *= cos(len * len_post_warp_cos_factor);
    len -= len_post_warp_subtract;
      // Second Loop: Adding Vertical Stripe Details
    if (stripe_iterations > 0)
    {
        // Get UV coords in normalized screen space for vertical stripes
        float2 stripe_coords;
        if (aspectRatio >= 1.0) {
            stripe_coords.x = st.x / aspectRatio + 0.5;
            stripe_coords.y = st.y + 0.5;
        } else {
            stripe_coords.x = st.x + 0.5;
            stripe_coords.y = st.y * aspectRatio + 0.5;
        }
        
        // Ensure we're in [0,1] range for proper modulo operation
        stripe_coords = clamp(stripe_coords, 0.0, 1.0);
        
        for (float i = 0.0f; i < (float)stripe_iterations; i += 1.0f) 
        {
            float period_multiplier = i + 1.0f;
            float current_stripe_period = stripe_period_base * period_multiplier;
            len += 1.0f / (abs(AS_mod(stripe_coords.x, current_stripe_period) * stripe_scale) + SAFE_DENOMINATOR_EPSILON);
        }
    }
      // Final Color Calculation with audio-reactive color cycling if selected
    float3 color = float3(
        cos(len + color_phase_r + colorCycleMod) * color_r_multiplier,
        cos(len + color_phase_g + colorCycleMod),
        cos(len - color_phase_b + colorCycleMod)
    );
    
    // For gradient mix - use the distance from the center in the centered coordinate system
    float distanceFromCenter = length(st);
    color = lerp(color, background_base_color.rgb, distanceFromCenter * background_gradient_strength);
      float4 result = float4(color, 1.0f);
    
    // Blend with original using selected blend mode and opacity
    float4 blended = float4(AS_ApplyBlend(result.rgb, orig.rgb, LiquidChrome_BlendMode), 1.0f);
    return lerp(orig, blended, LiquidChrome_BlendAmount);
}

// --- ReShade Technique Definition ---
technique AS_BGX_LiquidChrome <
    ui_label = "[AS] BGX: Liquid Chrome";
    ui_tooltip = "Creates dynamic, flowing psychedelic patterns reminiscent of liquid metal or chrome.";
>
{
    pass LiquidChrome_Pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_LiquidChrome;
    }
}

#endif // __AS_BGX_LiquidChrome_1_fx


