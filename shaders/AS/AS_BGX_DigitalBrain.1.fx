/**
 * AS_BGX_DigitalBrain.1.fx - Abstract digital brain visualization with animated Voronoi patterns
 * Author: Leon Aquitaine (shader port), Original GLSL by srtuss (2013)
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates an abstract visualization of a "digital brain" with evolving Voronoi patterns and neural-like
 * connections. The effect simulates an organic electronic network with dynamic light paths that mimic
 * neural activity in a stylized, technological manner.
 *
 * FEATURES:
 * - Dynamic Voronoi-based pattern generation that mimics neural networks
 * - Animated "electrical" pulses that simulate synaptic activity
 * - Color modulation based on noise texture for organic variation
 * - Vignetting effect to enhance visual focus
 * - Customizable noise texture for different pattern styles
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Generates layered Voronoi patterns with multiple octaves
 * 2. Applies time-based animation to create "electrical" pulse effects
 * 3. Uses noise texture to modulate color expression
 * 4. Combines multiple layers with different frequencies for organic feel
 * 5. Applies vignetting and intensity modulation for final output
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_DigitalBrain_1_fx
#define __AS_BGX_DigitalBrain_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_getTime() and other utilities

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
static const float OCTAVE_COUNT = 3.0; // Number of Voronoi octaves to render (3-4 recommended)
static const float VIGNETTE_STRENGTH = 0.6; // Strength of the vignetting effect

// ============================================================================
// TEXTURE CONFIGURATION
// ============================================================================
#ifndef NOISE_TEXTURE_PATH
#define NOISE_TEXTURE_PATH "perlin512x8Noise.png" // Default noise texture
#endif

// ============================================================================
// TEXTURES AND SAMPLERS
// ============================================================================
texture DigitalBrain_NoiseTex < source = NOISE_TEXTURE_PATH; ui_label = "Noise Texture"; ui_category = "Effect-Specific Parameters"; >
{
    Width = 512; Height = 512; Format = RGBA8;
};
sampler DigitalBrain_NoiseSampler { Texture = DigitalBrain_NoiseTex; AddressU = REPEAT; AddressV = REPEAT; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// Effect-Specific Parameters
uniform float AnimationSpeed < ui_type = "slider"; ui_label = "Animation Speed"; ui_tooltip = "Controls how fast the digital brain patterns evolve."; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Effect-Specific Parameters"; > = 1.0;
uniform float ZoomFactor < ui_type = "slider"; ui_label = "Zoom Factor"; ui_tooltip = "Adjusts the zoom level of the pattern."; ui_min = 0.2; ui_max = 2.0; ui_step = 0.01; ui_category = "Effect-Specific Parameters"; > = 0.6;
uniform float PatternDensity < ui_type = "slider"; ui_label = "Pattern Density"; ui_tooltip = "Controls density of the Voronoi patterns."; ui_min = 0.5; ui_max = 5.0; ui_step = 0.1; ui_category = "Effect-Specific Parameters"; > = 1.0;

// Color Settings
uniform float3 ColorMultiplier < ui_type = "color"; ui_label = "Color Multiplier"; ui_tooltip = "Adjusts the color balance of the effect."; ui_category = "Color Settings"; > = float3(1.0, 1.0, 1.0);
uniform float ColorIntensity < ui_type = "slider"; ui_label = "Color Intensity"; ui_tooltip = "Overall brightness of the effect."; ui_min = 0.5; ui_max = 4.0; ui_step = 0.1; ui_category = "Color Settings"; > = 2.0;

// Final Mix
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Rotate position around axis
float2 rotate(float2 p, float a)
{
    float s = sin(a);
    float c = cos(a);
    return float2(p.x * c - p.y * s, p.x * s + p.y * c);
}

// 1D random numbers
float rand_1d(float n)
{
    return frac(sin(n) * 43758.5453123f);
}

// 2D random numbers
float2 rand_2d(float2 p)
{
    return frac(float2(sin(p.x * 591.32f + p.y * 154.077f), cos(p.x * 391.32f + p.y * 49.077f)));
}

// 1D noise
float noise1(float p)
{
    float fl = floor(p);
    float fc = frac(p);
    return lerp(rand_1d(fl), rand_1d(fl + 1.0f), fc);
}

// Voronoi distance noise, based on iq's articles
float voronoi(float2 x)
{
    float2 p = floor(x);
    float2 f = frac(x);

    float2 res = float2(8.0f, 8.0f);
    
    for (int j = -1; j <= 1; j++)
    {
        for (int i = -1; i <= 1; i++)
        {
            float2 b = float2(i, j);
            float2 r = b - f + rand_2d(p + b);

            // Chebyshev distance, one of many ways to do this
            float d = max(abs(r.x), abs(r.y));

            if (d < res.x)
            {
                res.y = res.x;
                res.x = d;
            }
            else if (d < res.y)
            {
                res.y = d;
            }
        }
    }
    return res.y - res.x;
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_DigitalBrain(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    
    // Get time with speed adjustment
    float currentTime = AS_getTime() * AnimationSpeed; 

    float flicker = noise1(currentTime * 2.0f) * 0.8f + 0.4f;

    // UV setup: texcoord is (0,0) top-left. ShaderToy fragCoord is (0,0) bottom-left.
    // 1. Make texcoord behave like ShaderToy's (fragCoord.xy / iResolution.xy)
    float2 uv_norm = float2(texcoord.x, 1.0f - texcoord.y); // uv_norm is now 0-1, (0,0) at bottom-left

    // 2. Transform to -1 to 1 range, with (0,0) at center
    float2 uv = (uv_norm - 0.5f) * 2.0f;
    float2 suv = uv; // Store screen-space UVs for vignetting (already -1 to 1 centered)

    // 3. Apply aspect ratio correction
    uv.x *= ReShade::AspectRatio;

    float v = 0.0f;

    // Apply zoom and animation
    uv *= ZoomFactor + sin(currentTime * 0.1f) * 0.4f;
    uv = rotate(uv, sin(currentTime * 0.3f) * 1.0f);
    uv += currentTime * 0.4f;

    // Add some noise octaves
    float a = 0.6f, f = PatternDensity;

    for (int i = 0; i < int(OCTAVE_COUNT); i++)
    {
        float v1 = voronoi(uv * f + 5.0f);
        float v2 = 0.0f;

        // Make the moving electrons-effect for higher octaves
        if (i > 0)
        {
            // Of course everything based on voronoi
            v2 = voronoi(uv * f * 0.5f + 50.0f + currentTime);

            float va = 0.0f, vb = 0.0f;
            va = 1.0f - smoothstep(0.0f, 0.1f, v1);
            vb = 1.0f - smoothstep(0.0f, 0.08f, v2);
            v += a * pow(va * (0.5f + vb), 2.0f);
        }

        // Make sharp edges
        v1 = 1.0f - smoothstep(0.0f, 0.3f, v1);

        // Noise is used as intensity map
        v2 = a * (noise1(v1 * 5.5f + 0.1f));

        // Octave 0's intensity changes a bit
        if (i == 0)
            v += v2 * flicker;
        else
            v += v2;

        f *= 3.0f;
        a *= 0.7f;
    }

    // Apply vignetting
    v *= exp(-VIGNETTE_STRENGTH * length(suv)) * 1.2f;

    // Use texture channel for color
    float3 cexp = tex2D(DigitalBrain_NoiseSampler, uv * 0.001f).xyz * 3.0f 
                + tex2D(DigitalBrain_NoiseSampler, uv * 0.01f).xyz;
    cexp *= 1.4f * ColorMultiplier;

    // Calculate final color
    float3 col = float3(pow(v, cexp.x), pow(v, cexp.y), pow(v, cexp.z)) * ColorIntensity;
    
    // Apply the standard blend function for final output
    float3 blendedColor = AS_ApplyBlend(col, originalColor.rgb, BlendMode);
    return float4(lerp(originalColor.rgb, blendedColor, BlendStrength), originalColor.a);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_DigitalBrain <
    ui_label = "[AS] BGX: Digital Brain";
    ui_tooltip = "Visualizes an abstract 'digital brain' effect with evolving Voronoi patterns.\n"
                "Part of AS StageFX shader collection by Leon Aquitaine.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_DigitalBrain;
    }
}

#endif // __AS_BGX_DigitalBrain_1_fx