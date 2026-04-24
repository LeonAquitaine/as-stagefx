// AS_BGX_LiquidChrome.1.fx
// Leon Aquitaine - CC BY 4.0

#ifndef __AS_BGX_LiquidChrome_1_fx
#define __AS_BGX_LiquidChrome_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform float coord_scale <
    ui_type = "drag";
    ui_category = "Pattern Shape";
    ui_label = "Pattern Detail Scale";
    ui_tooltip = "Adjusts the overall size of the psychedelic patterns. Higher values zoom in, revealing finer details and faster perceived motion.";
    ui_min = 1.0; ui_max = 50.0; ui_step = 0.1;
> = 10.0f;

uniform int warp_iterations <
    ui_type = "drag";
    ui_category = "Pattern Shape";
    ui_label = "Warp Complexity";
    ui_tooltip = "Increases the intricacy and 'folding' of the core warped pattern. More iterations lead to deeper, more detailed distortions.";
    ui_min = 1; ui_max = 20; ui_step = 1;
> = 5;

uniform float len_post_warp_cos_factor <
    ui_type = "drag";
    ui_category = "Color Pattern";
    ui_label = "Color Band Frequency";
    ui_tooltip = "Adjusts the density of color bands or concentric rings overlaying the pattern. Higher values create more, tighter bands.";
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.01;
> = 0.4f;

uniform float len_post_warp_subtract <
    ui_type = "drag";
    ui_category = "Color Pattern";
    ui_label = "Color Band Offset";
    ui_tooltip = "Shifts the phase or starting point of the color banding/ring pattern, affecting color distribution.";
    ui_min = -20.0; ui_max = 20.0; ui_step = 0.1;
> = 10.0f;

uniform int stripe_iterations <
    ui_type = "drag";
    ui_category = "Vertical Lines";
    ui_label = "Vertical Line Layers";
    ui_tooltip = "Number of overlaid vertical stripe patterns. Each layer adds more lines with different spacing. Set to 0 to disable stripes.";
    ui_min = 0; ui_max = 10; ui_step = 1;
> = 5;

uniform float stripe_period_base <
    ui_type = "drag";
    ui_category = "Vertical Lines";
    ui_label = "Vertical Line Spacing";
    ui_tooltip = "Controls the fundamental spacing of the vertical line patterns. Smaller values create denser, more frequent lines.";
    ui_min = 0.005; ui_max = 0.5; ui_step = 0.001;
> = 0.09f;

uniform float stripe_scale <
    ui_type = "drag";
    ui_category = "Vertical Lines";
    ui_label = "Vertical Line Sharpness";
    ui_tooltip = "Adjusts the sharpness or definition of the vertical lines. Higher values can make lines thinner and more pronounced.";
    ui_min = 10.0; ui_max = 1000.0; ui_step = 1.0;
> = 200.0f;

uniform float color_phase_r <
    ui_type = "drag";
    ui_category = "Color Tuning";
    ui_label = "Red Hue Cycle";
    ui_tooltip = "Shifts the color palette by adjusting the cycle for the red channel. Experiment for different color schemes.";
    ui_min = -AS_TWO_PI; ui_max = AS_TWO_PI; ui_step = 0.01;
> = 0.2f;

uniform float color_phase_g <
    ui_type = "drag";
    ui_category = "Color Tuning";
    ui_label = "Green Hue Cycle";
    ui_tooltip = "Shifts the color palette by adjusting the cycle for the green channel.";
    ui_min = -AS_TWO_PI; ui_max = AS_TWO_PI; ui_step = 0.01;
> = 0.1f;

uniform float color_phase_b <
    ui_type = "drag";
    ui_category = "Color Tuning";
    ui_label = "Blue Hue Cycle";
    ui_tooltip = "Shifts the color palette by adjusting the cycle for the blue channel.";
    ui_min = -AS_TWO_PI; ui_max = AS_TWO_PI; ui_step = 0.01;
> = -0.05f;

uniform float color_r_multiplier <
    ui_type = "drag";
    ui_category = "Color Tuning";
    ui_label = "Red Intensity";
    ui_tooltip = "Controls the overall intensity or brightness of the red color channel.";
    ui_min = 0.0; ui_max = 3.0; ui_step = 0.01;
> = 1.15f;

uniform float background_gradient_strength <
    ui_type = "drag";
    ui_category = "Color Tuning";
    ui_label = "Distortion Tint Strength";
    ui_tooltip = "Controls the intensity of a color tint that is mixed in based on the final warped coordinates.";
    ui_min = 0.0; ui_max = 0.1; ui_step = 0.001;
> = 0.01f;

uniform float4 background_base_color <
    ui_type = "color";
    ui_category = "Color Tuning";
    ui_label = "Distortion Tint Color";
    ui_tooltip = "Sets the color of the tint mixed in based on the final warped coordinates, affecting the overall image tone.";
> = float4(0.05, 0.07, 0.10, 0.0);

AS_ANIMATION_SPEED_UI(LiquidChrome_AnimationSpeed, AS_CAT_ANIMATION)
AS_ANIMATION_KEYFRAME_UI(LiquidChrome_AnimationKeyframe, AS_CAT_ANIMATION)

uniform float warp_time_factor_x <
    ui_type = "drag";
    ui_category = AS_CAT_ANIMATION;
    ui_label = "Horizontal Flow Speed";
    ui_tooltip = "Controls the speed of the horizontal animation or 'breathing' in the main warp pattern.";
    ui_min = 0.0; ui_max = 0.5; ui_step = 0.001;
> = 0.07f;

uniform float warp_offset_amp_x <
    ui_type = "drag";
    ui_category = AS_CAT_ANIMATION;
    ui_label = "Horizontal Flow Strength";
    ui_tooltip = "Determines how much the pattern animates or 'breathes' along the horizontal axis.";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
> = 0.2f;

uniform float warp_time_factor_y <
    ui_type = "drag";
    ui_category = AS_CAT_ANIMATION;
    ui_label = "Vertical Flow Speed";
    ui_tooltip = "Controls the speed of the vertical animation or 'undulation' in the main warp pattern.";
    ui_min = 0.0; ui_max = 0.5; ui_step = 0.001;
> = 0.1f;

AS_AUDIO_UI(LiquidChrome_AudioSource, "Audio Source", AS_AUDIO_BEAT, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(LiquidChrome_AudioMultiplier, "Audio Intensity", 1.0, 2.0, AS_CAT_AUDIO)

uniform int LiquidChrome_AudioTarget <
    ui_type = "combo";
    ui_category = AS_CAT_AUDIO;
    ui_label = "Audio Target";
    ui_tooltip = "Select which parameter will be modulated by audio";
    ui_items = "None\0Flow Speed\0Color Cycle\0Pattern Scale\0";
> = 2;

AS_STAGEDEPTH_UI(LiquidChrome_EffectDepth)
AS_ROTATION_UI(LiquidChrome_SnapRotation, LiquidChrome_FineRotation)
AS_POSITION_SCALE_UI(LiquidChrome_Position, LiquidChrome_Scale)

AS_BLENDMODE_UI(LiquidChrome_BlendMode)
AS_BLENDAMOUNT_UI(LiquidChrome_BlendAmount)

float4 PS_LiquidChrome(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    AS_DEPTH_EARLY_RETURN(texcoord, LiquidChrome_EffectDepth);

    float time = AS_getAnimationTime(LiquidChrome_AnimationSpeed, LiquidChrome_AnimationKeyframe);

    float audioMod = AS_audioModulate(1.0, LiquidChrome_AudioSource, LiquidChrome_AudioMultiplier, true, 0) - 1.0;

    float flowSpeedMod    = 1.0;
    float colorCycleMod   = 0.0;
    float patternScaleMod = 1.0;

    if (LiquidChrome_AudioTarget == 1)
    {
        flowSpeedMod = 1.0 + audioMod;
    }
    else if (LiquidChrome_AudioTarget == 2)
    {
        colorCycleMod = audioMod * 0.5;
    }
    else if (LiquidChrome_AudioTarget == 3)
    {
        patternScaleMod = 1.0 + audioMod;
    }

    float aspectRatio = ReShade::AspectRatio;
    float2 centered_coord = AS_centeredUVWithAspect(texcoord, aspectRatio);

    float angle = AS_getRotationRadians(LiquidChrome_SnapRotation, LiquidChrome_FineRotation);
    float sinA, cosA;
    sincos(-angle, sinA, cosA);
    float2 rot = float2(
        centered_coord.x * cosA - centered_coord.y * sinA,
        centered_coord.x * sinA + centered_coord.y * cosA
    );

    float safeScale = max(LiquidChrome_Scale, AS_STABILITY_EPSILON);
    float2 st = rot / safeScale;
    st -= LiquidChrome_Position;

    float2 coord = st * (coord_scale * patternScaleMod);

    float tx = time * warp_time_factor_x * flowSpeedMod;
    float ty = time * warp_time_factor_y * flowSpeedMod;

    int warpIters = clamp(warp_iterations, 1, 20);

    [loop]
    for (int i = 0; i < warpIters; ++i)
    {
        float fi = float(i) + 1.0;

        float ra = fi * 0.5 + tx * 0.25;
        float rs = sin(ra);
        float rc = cos(ra);
        float2 p = float2(
            coord.x * rc - coord.y * rs,
            coord.x * rs + coord.y * rc
        );

        float nx = sin(p.y + tx * fi) + warp_offset_amp_x * cos(p.y * 0.5 + tx * (fi + 1.0));
        float ny = cos(p.x + ty * fi) + 0.5 * sin(p.x * 0.5 + ty * (fi + 1.0));

        coord.x += nx;
        coord.y += ny;

        coord *= 0.97;
    }

    float len = length(coord);

    len = len * len_post_warp_cos_factor - len_post_warp_subtract;

    if (stripe_iterations > 0)
    {
        float2 stripe_coords = st;
        if (aspectRatio >= 1.0)
            stripe_coords.x /= aspectRatio;
        else
            stripe_coords.y *= aspectRatio;
        stripe_coords += 0.5;
        stripe_coords = saturate(stripe_coords);

        int stripeIters = clamp(stripe_iterations, 0, 10);

        [loop]
        for (int s = 0; s < stripeIters; ++s)
        {
            float current_stripe_period = stripe_period_base * (float(s) + 1.0);
            float m = abs(AS_mod(stripe_coords.x, current_stripe_period) * stripe_scale) + AS_STABILITY_EPSILON;
            len += 1.0 / m;
        }
    }

    float3 color;
    color.r = (cos(len + color_phase_r + colorCycleMod) * 0.5 + 0.5) * color_r_multiplier;
    color.g =  cos(len + color_phase_g + colorCycleMod) * 0.5 + 0.5;
    color.b =  cos(len - color_phase_b + colorCycleMod) * 0.5 + 0.5;

    float distanceFromCenter = length(st);
    color = lerp(color, background_base_color.rgb, saturate(distanceFromCenter * background_gradient_strength));

    return float4(AS_composite(color, _as_originalColor.rgb, LiquidChrome_BlendMode, LiquidChrome_BlendAmount), 1.0);
}

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

#endif
