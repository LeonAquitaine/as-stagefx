/////////////////////////////////////////////////////////////////////////////////////////////////
// Digital Brain - Translated to ReShade FX
// Original GLSL by srtuss (2013) - https://www.shadertoy.com/view/4sl3Dr
// Translated for ReShade.
//
// Assumptions:
//  - AS_Utils.1.fxh (or a similar accessible version) provides:
//      - float AS_getTime() (returns seconds)
//  - Uses "perlin512x8Noise.png" for iChannel0.
/////////////////////////////////////////////////////////////////////////////////////////////////

#include "AS_Utils.1.fxh" // For AS_getTime() and other utilities. Ensure path is correct.

//--------------------------------------------------------------------------------------
// Textures & Samplers
//--------------------------------------------------------------------------------------
texture NoiseTex < source = "perlin512x8Noise.png"; > // Define the noise texture
{
    Width = 512;
    Height = 512;
    Format = RGBA8; // Assuming a common format, adjust if needed
};

sampler sNoiseTex
{
    Texture = NoiseTex;
    AddressU = REPEAT; // ShaderToy iChannels default to REPEAT
    AddressV = REPEAT;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR; // Or NONE if no mipmaps
};

//--------------------------------------------------------------------------------------
// Helper Functions
//--------------------------------------------------------------------------------------

// rotate position around axis
float2 rotate(float2 p, float a)
{
    float s = sin(a);
    float c = cos(a);
    return float2(p.x * c - p.y * s, p.x * s + p.y * c);
}

// 1D random numbers
float rand_1d(float n) // Renamed to avoid conflict if "rand" is a keyword/macro
{
    return frac(sin(n) * 43758.5453123f);
}

// 2D random numbers
float2 rand_2d(float2 p) // Renamed
{
    return frac(float2(sin(p.x * 591.32f + p.y * 154.077f), cos(p.x * 391.32f + p.y * 49.077f)));
}

// 1D noise
float noise1(float p)
{
    float fl = floor(p);
    float fc = frac(p);
    return lerp(rand_1d(fl), rand_1d(fl + 1.0f), fc); // mix -> lerp
}

// voronoi distance noise, based on iq's articles
float voronoi(float2 x)
{
    float2 p = floor(x);
    float2 f = frac(x);

    float2 res = float2(8.0f, 8.0f); // HLSL requires explicit .0 for floats in constructors sometimes
    for (int j = -1; j <= 1; j++)
    {
        for (int i = -1; i <= 1; i++)
        {
            float2 b = float2(i, j);
            float2 r = b - f + rand_2d(p + b);

            // chebyshev distance, one of many ways to do this
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

//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS_DigitalBrain(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float currentTime = AS_getTime(); // Get time from AS_Utils

    float flicker = noise1(currentTime * 2.0f) * 0.8f + 0.4f;

    // UV setup: texcoord is (0,0) top-left. ShaderToy fragCoord is (0,0) bottom-left.
    // 1. Make texcoord behave like ShaderToy's (fragCoord.xy / iResolution.xy)
    float2 uv_norm = float2(texcoord.x, 1.0f - texcoord.y); // uv_norm is now 0-1, (0,0) at bottom-left

    // 2. Transform to -1 to 1 range, with (0,0) at center
    float2 uv = (uv_norm - 0.5f) * 2.0f;
    float2 suv = uv; // Store screen-space UVs for vignetting (already -1 to 1 centered)

    // 3. Apply aspect ratio correction
    uv.x *= ReShade::ScreenSize.x / ReShade::ScreenSize.y;


    float v = 0.0f;

    // that looks highly interesting:
    // v = 1.0f - length(uv) * 1.3f;


    // a bit of camera movement
    uv *= 0.6f + sin(currentTime * 0.1f) * 0.4f;
    uv = rotate(uv, sin(currentTime * 0.3f) * 1.0f);
    uv += currentTime * 0.4f;


    // add some noise octaves
    float a = 0.6f, f = 1.0f;

    for (int i = 0; i < 3; i++) // 4 octaves also look nice, its getting a bit slow though
    {
        float v1 = voronoi(uv * f + 5.0f);
        float v2 = 0.0f;

        // make the moving electrons-effect for higher octaves
        if (i > 0)
        {
            // of course everything based on voronoi
            v2 = voronoi(uv * f * 0.5f + 50.0f + currentTime);

            float va = 0.0f, vb = 0.0f;
            va = 1.0f - smoothstep(0.0f, 0.1f, v1);
            vb = 1.0f - smoothstep(0.0f, 0.08f, v2);
            v += a * pow(va * (0.5f + vb), 2.0f);
        }

        // make sharp edges
        v1 = 1.0f - smoothstep(0.0f, 0.3f, v1);

        // noise is used as intensity map
        v2 = a * (noise1(v1 * 5.5f + 0.1f));

        // octave 0's intensity changes a bit
        if (i == 0)
            v += v2 * flicker;
        else
            v += v2;

        f *= 3.0f;
        a *= 0.7f;
    }

    // slight vignetting
    v *= exp(-0.6f * length(suv)) * 1.2f;

    // use texture channel0 for color? why not.
    // tex2D(sampler, float2 coords)
    float3 cexp = tex2D(sNoiseTex, uv * 0.001f).xyz * 3.0f + tex2D(sNoiseTex, uv * 0.01f).xyz;
    cexp *= 1.4f;

    // old blueish color set (from original shader)
    // float3 cexp = float3(6.0f, 4.0f, 2.0f);

    float3 col = float3(pow(v, cexp.x), pow(v, cexp.y), pow(v, cexp.z)) * 2.0f;

    return float4(col, 1.0f);
}

//--------------------------------------------------------------------------------------
// Technique
//--------------------------------------------------------------------------------------
technique DigitalBrain_Tech <
    ui_label = "[AS] Digital Brain";
    ui_tooltip = "Visualizes an abstract 'digital brain' effect with evolving Voronoi patterns.\n"
                 "Original GLSL by srtuss on ShaderToy.\n"
                 "Uses 'perlin512x8Noise.png' or other noise texture selected for 'NoiseTex'."; >
{
    pass
    {
        VertexShader = PostProcessVS; // Standard ReShade pass-through VS
        PixelShader = PS_DigitalBrain;
    }
}