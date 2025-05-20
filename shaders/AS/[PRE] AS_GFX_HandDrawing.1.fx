#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_getTime()

//--------------------------------------------------------------------------------------
// Texture Definition (User can change NOISE_TEXTURE_PATH_HANDDRAWN before compilation or in UI)
//--------------------------------------------------------------------------------------
#ifndef NOISE_TEXTURE_PATH_HANDDRAWN
#define NOISE_TEXTURE_PATH_HANDDRAWN "perlin512x8CNoise.png" // Example default noise texture
#endif

texture PencilDrawing_NoiseTex < source = NOISE_TEXTURE_PATH_HANDDRAWN; ui_label = "Noise Pattern Texture"; ui_tooltip = "Texture used for randomizing strokes and fills (e.g., Perlin, Blue Noise)."; >
{
    // Default attributes if texture not found or specified, actual size is less critical with defines below
    Width = 512; Height = 512; Format = RGBA8;
};
sampler PencilDrawing_NoiseSampler { Texture = PencilDrawing_NoiseTex; AddressU = REPEAT; AddressV = REPEAT; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };

//--------------------------------------------------------------------------------------
// Global Defines & Constants
//--------------------------------------------------------------------------------------
// Define Noise Texture Dimensions (User should adjust these if NOISE_TEXTURE_PATH_HANDDRAWN points to a texture of different size)
#define NOISE_TEX_WIDTH 512.0f
#define NOISE_TEX_HEIGHT 512.0f

// Resolution Macros (used by helper functions)
#define Res1 float2(NOISE_TEX_WIDTH, NOISE_TEX_HEIGHT) // Noise Texture Resolution
#define Res_Screen float2(BUFFER_WIDTH, BUFFER_HEIGHT)    // Screen Resolution (iResolution)
#define Res_Source float2(BUFFER_WIDTH, BUFFER_HEIGHT)  // Source Image Resolution (iChannel0 / BackBuffer)

static const float PI2 = 6.28318530717959f;

//--------------------------------------------------------------------------------------
// UI Uniforms for Artistic Control
//--------------------------------------------------------------------------------------

uniform bool EnablePaperPattern < ui_category="Background & Paper";
    ui_label="Enable Paper Pattern";
    ui_tooltip="Toggles the underlying paper-like grid pattern.";
> = true;

// --- Overall Effect & Animation ---
uniform float AnimationWobbleStrength < ui_category="Animation & Jitter";
    ui_type="drag"; ui_min=0.0; ui_max=20.0; ui_step=0.1;
    ui_label="Animation Wobble Strength";
    ui_tooltip="Overall strength of the coordinate jitter effect, making the image 'wobble'. Original: 4.0";
> = 4.0;

uniform float AnimationWobbleSpeed < ui_category="Animation & Jitter";
    ui_type="drag"; ui_min=0.0; ui_max=5.0; ui_step=0.01;
    ui_label="Animation Wobble Speed";
    ui_tooltip="Speed of the wobble animation. Original: 1.0";
> = 1.0;

uniform float2 AnimationWobbleFrequency < ui_category="Animation & Jitter";
    ui_type="drag"; ui_min=0.1; ui_max=5.0; ui_step=0.01;
    ui_label="Animation Wobble Pattern (X, Y Freq)";
    ui_tooltip="Frequency of sine waves for X and Y axis wobble. Original: (1.0, 1.7)";
> = float2(1.0, 1.7);

uniform float EffectScaleReferenceHeight < ui_category="Animation & Jitter";
    ui_type="drag"; ui_min=100.0; ui_max=2160.0; ui_step=10.0;
    ui_label="Effect Scale Reference Height";
    ui_tooltip="Reference screen height for scaling effects like jitter and stroke length. Original: 400.0px";
> = 400.0;

// --- Line Work & Strokes ---
uniform int NumberOfStrokeDirections < ui_category="Line Work & Strokes";
    ui_type="slider"; ui_min=1; ui_max=10; ui_step=1;
    ui_label="Number of Stroke Directions";
    ui_tooltip="Number of different angles for hatching/strokes. Affects density and performance. Original: 3.";
> = 3;

uniform int LineLengthSamples < ui_category="Line Work & Strokes";
    ui_type="slider"; ui_min=1; ui_max=32; ui_step=1;
    ui_label="Line Length (Samples per Direction)";
    ui_tooltip="Number of samples along each stroke direction, effectively line length. Affects detail and performance. Original: 16.";
> = 16;

uniform float MaxIndividualLineOpacity < ui_category="Line Work & Strokes";
    ui_type="drag"; ui_min=0.0; ui_max=0.2; ui_step=0.001;
    ui_label="Max Individual Line Opacity";
    ui_tooltip="Clamps the maximum opacity/intensity of a single calculated stroke fragment. Original: 0.05";
> = 0.05;

uniform float OverallLineLengthScale < ui_category="Line Work & Strokes";
    ui_type="drag"; ui_min=0.1; ui_max=5.0; ui_step=0.01;
    ui_label="Overall Line Length Scale";
    ui_tooltip="General multiplier for the length of stroke sampling lines.";
> = 1.0;

// --- Line Shading & Texture ---
uniform float LineDarknessCurve < ui_category="Line Shading & Texture";
    ui_type="drag"; ui_min=1.0; ui_max=5.0; ui_step=0.1;
    ui_label="Line Darkness Curve (Exponent)";
    ui_tooltip="Exponent applied to the accumulated line color for darkening. Higher values = darker, sharper lines. Original: 3.0";
> = 3.0;

uniform float LineWorkDensity < ui_category="Line Shading & Texture"; // Inverted meaning from "OverallStrokeDensityFactor"
    ui_type="drag"; ui_min=0.5; ui_max=4.0; ui_step=0.01;
    ui_label="Line Work Density";
    ui_tooltip="Adjusts the overall density of lines. Higher values = denser/darker strokes. Inverse of original 0.75 normalization factor.";
> = 1.0 / 0.75; // Default based on original 0.75 (1/0.75 approx 1.33)

uniform float LineTextureInfluence < ui_category="Line Shading & Texture";
    ui_type="drag"; ui_min=0.0; ui_max=2.0; ui_step=0.01;
    ui_label="Line Texture Influence";
    ui_tooltip="Scales the effect of noise on line darkness variation. Original: 0.8";
> = 0.8;

uniform float LineTextureBaseBrightness < ui_category="Line Shading & Texture";
    ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_step=0.01;
    ui_label="Line Texture Base Brightness";
    ui_tooltip="Base value added to noise for line darkness variation. Original: 0.6";
> = 0.6;

uniform float LineTextureNoiseScale < ui_category="Line Shading & Texture";
    ui_type="drag"; ui_min=0.1; ui_max=2.0; ui_step=0.01;
    ui_label="Line Texture Noise UV Scale";
    ui_tooltip="Scales UVs for the noise lookup that affects line darkness variation. Original: 0.7";
> = 0.7;

// --- Color Processing & Fill ---
uniform float MainColorDesaturationMix < ui_category="Color Processing & Fill";
    ui_type="drag"; ui_min=0.0; ui_max=5.0; ui_step=0.01;
    ui_label="Main Color Desaturation Mix";
    ui_tooltip="Mixing factor towards gray for the main colors extracted from the image. Original: 1.8";
> = 1.8;

uniform float MainColorBrightnessCap < ui_category="Color Processing & Fill";
    ui_type="drag"; ui_min=0.1; ui_max=1.0; ui_step=0.01;
    ui_label="Main Color Brightness Cap";
    ui_tooltip="Maximum brightness after initial color filtering (getCol). Original: 0.7";
> = 0.7;

uniform float FillTextureEdgeSoftnessMin < ui_category="Color Processing & Fill";
    ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_step=0.01;
    ui_label="Fill Texture Edge Softness (Min)";
    ui_tooltip="Lower edge for smoothstep creating the textured fill (getColHT). Original: 0.95";
> = 0.95;

uniform float FillTextureEdgeSoftnessMax < ui_category="Color Processing & Fill";
    ui_type="drag"; ui_min=0.5; ui_max=1.5; ui_step=0.01;
    ui_label="Fill Texture Edge Softness (Max)";
    ui_tooltip="Upper edge for smoothstep creating the textured fill (getColHT). Original: 1.05";
> = 1.05;

uniform float FillColorBaseFactor < ui_category="Color Processing & Fill";
    ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_step=0.01;
    ui_label="Fill Color Base Factor";
    ui_tooltip="Base color multiplier for the textured fill. Original: 0.8";
> = 0.8;

uniform float FillColorOffsetFactor < ui_category="Color Processing & Fill";
    ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_step=0.01;
    ui_label="Fill Color Offset Factor";
    ui_tooltip="Color offset added to the textured fill. Original: 0.2";
> = 0.2;

uniform float FillTextureNoiseStrength < ui_category="Color Processing & Fill";
    ui_type="drag"; ui_min=0.0; ui_max=2.0; ui_step=0.01;
    ui_label="Fill Texture Noise Strength";
    ui_tooltip="Scales the noise contribution to the textured fill. Original: 1.0 (implicit)";
> = 1.0;

uniform float FillTextureNoiseScale < ui_category="Color Processing & Fill";
    ui_type="drag"; ui_min=0.1; ui_max=2.0; ui_step=0.01;
    ui_label="Fill Texture Noise UV Scale";
    ui_tooltip="Scales UVs for the noise lookup affecting the textured fill. Original: 0.7";
> = 0.7;

uniform float NoiseLookupOverallScale < ui_category="Color Processing & Fill";
    ui_type="drag"; ui_min=100.0; ui_max=4000.0; ui_step=10.0;
    ui_label="Noise Lookup Overall Scale Reference";
    ui_tooltip="Reference value for noise UV scaling (related to original 1080p factor in getRand). Larger means noise samples are smaller/denser.";
> = 1080.0;


// --- Paper & Background ---
uniform float PaperPatternFrequency < ui_category="Background & Paper";
    ui_type="drag"; ui_min=0.01; ui_max=0.5; ui_step=0.001;
    ui_label="Paper Pattern Frequency";
    ui_tooltip="Frequency of the 'karo' paper pattern. Original: 0.1";
> = 0.1;

uniform float PaperPatternIntensity < ui_category="Background & Paper";
    ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_step=0.01;
    ui_label="Paper Pattern Intensity";
    ui_tooltip="Intensity of the 'karo' paper pattern. Original: 0.5";
> = 0.5;

uniform float3 PaperPatternTint < ui_category="Background & Paper";
    ui_type="color";
    ui_label="Paper Pattern Color Tint";
    ui_tooltip="Color tint of the paper pattern. Original: (0.25, 0.1, 0.1)";
> = float3(0.25, 0.1, 0.1);

uniform float PaperPatternSharpness < ui_category="Background & Paper";
    ui_type="drag"; ui_min=10.0; ui_max=200.0; ui_step=1.0;
    ui_label="Paper Pattern Sharpness";
    ui_tooltip="Sharpness of the paper pattern lines (exponent in exp(-s*s*SHARPNESS)). Original: 80.0";
> = 80.0;

//--------------------------------------------------------------------------------------
// Helper Functions (Now using global #define Res, Res0, Res1)
//--------------------------------------------------------------------------------------

float4 getRand(float2 pos_param) {
    float2 uv_noise = pos_param / Res1 / Res_Screen.y * NoiseLookupOverallScale;
    return tex2Dlod(PencilDrawing_NoiseSampler, float4(uv_noise, 0.0, 0.0));
}

float4 getCol(float2 pos_param) {
    // Since Res_Source (BackBuffer) and Res_Screen are both BUFFER_WIDTH/HEIGHT,
    // the original complex UV formula simplifies to:
    float2 uv = pos_param / Res_Screen; 
    
    float4 c1 = tex2D(ReShade::BackBuffer, uv);
    // Border fade (using fixed values from original, could be parameterized)
    float4 border_fade_edges = smoothstep(float4(-0.05f, -0.05f, -0.05f, -0.05f), float4(0.0f, 0.0f, 0.0f, 0.0f), float4(uv.x, uv.y, 1.0f - uv.x, 1.0f - uv.y));
    c1 = lerp(float4(1.0f, 1.0f, 1.0f, 0.0f), c1, border_fade_edges.x * border_fade_edges.y * border_fade_edges.z * border_fade_edges.w); 
    
    // Color filtering (original weights: -0.5, 1.0, -0.5 for R,G,B)
    float d = clamp(dot(c1.xyz, float3(-0.5f, 1.0f, -0.5f)), 0.0f, 1.0f); 
    float4 c2 = MainColorBrightnessCap.xxxx; // Target gray color for mixing
    
    return min(lerp(c1, c2, MainColorDesaturationMix * d), MainColorBrightnessCap.xxxx);
}

float4 getColHT(float2 pos_param) {
    float4 col_val = getCol(pos_param);
    float4 rand_val = getRand(pos_param * FillTextureNoiseScale);
    return smoothstep(FillTextureEdgeSoftnessMin, FillTextureEdgeSoftnessMax, col_val * FillColorBaseFactor + FillColorOffsetFactor + rand_val * FillTextureNoiseStrength);
}

float getVal(float2 pos_param) {
    float4 c = getCol(pos_param);
    // Luminance calculation (original had pow 1 and mult 1)
    return pow(dot(c.xyz, 0.333f.xxx), 1.0f) * 1.0f; 
}

float2 getGrad(float2 pos_param, float eps) {
    float2 d_offset = float2(eps, 0.0f); 
    return float2(
        getVal(pos_param + d_offset.xy) - getVal(pos_param - d_offset.xy),
        getVal(pos_param + d_offset.yx) - getVal(pos_param - d_offset.yx)
    ) / eps / 2.0f;
}

//--------------------------------------------------------------------------------------
// Main Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS_HandDrawn(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float time_s = AS_getTime() / 1000.0f;

    float norm_height_factor = Res_Screen.y / EffectScaleReferenceHeight;
    float2 pos_main = vpos.xy + AnimationWobbleStrength * sin(time_s * AnimationWobbleSpeed * AnimationWobbleFrequency) * norm_height_factor;
    
    float3 col_accum = 0.0f.xxx;
    float3 col2_accum = 0.0f.xxx;
    float sum_factor = 0.0f;

    float stroke_len_normalized_scale = OverallLineLengthScale * norm_height_factor;

    [loop] // Main loops should generally be marked if complex or many iterations
    for (int i = 0; i < NumberOfStrokeDirections; i++)
    {
        float ang = PI2 / (float)NumberOfStrokeDirections * ((float)i + 0.8f);
        float2 v_stroke_dir = float2(cos(ang), sin(ang)); // Renamed v
        
        [loop]
        for (int j = 0; j < LineLengthSamples; j++)
        {
            float j_float = (float)j;
            float2 dpos = v_stroke_dir.yx * float2(1.0f, -1.0f) * j_float * stroke_len_normalized_scale;
            // Original dpos2 factor was 0.5, can be tuned with a "StrokeCurvatureFactor" uniform if desired
            float stroke_curve_factor = (j_float * j_float) / (float)LineLengthSamples * 0.5f; 
            float2 dpos2 = v_stroke_dir.xy * stroke_curve_factor * stroke_len_normalized_scale;
            
            float2 g;
            float fact;
            float fact2;

            // This inner loop is only 2 iterations, usually unrolled fine by compiler
            for (float s_loop = -1.0f; s_loop <= 1.0f; s_loop += 2.0f)
            {
                float2 pos2 = pos_main + s_loop * dpos + dpos2;
                float2 pos3 = pos_main + (s_loop * dpos + dpos2).yx * float2(1.0f, -1.0f) * 2.0f;
                
                g = getGrad(pos2, 0.4f); // Gradient epsilon (0.4) could be a uniform
                // PerpendicularGradientInfluence could scale 0.5f
                fact = dot(g, v_stroke_dir) - 0.5f * abs(dot(g, v_stroke_dir.yx * float2(1.0f, -1.0f)));
                fact2 = dot(normalize(g + 0.0001f.xx), v_stroke_dir.yx * float2(1.0f, -1.0f));
                
                fact = clamp(fact, 0.0f, MaxIndividualLineOpacity);
                fact2 = abs(fact2);
                
                fact *= 1.0f - j_float / (float)LineLengthSamples;
                col_accum += fact;
                col2_accum += fact2 * getColHT(pos3).xyz;
                sum_factor += fact2;
            }
        }
    }

    if (sum_factor > 1e-5f) col2_accum /= sum_factor; else col2_accum = 0.0f.xxx;
    
    // Apply LineWorkDensity (original was 0.75 in denominator, so multiply by 1/0.75 = 1.333)
    col_accum /= (float)(LineLengthSamples * NumberOfStrokeDirections) / LineWorkDensity / sqrt(Res_Screen.y); 
    
    float rand_for_line = getRand(pos_main * LineTextureNoiseScale).x;
    col_accum.x *= (LineTextureBaseBrightness + LineTextureInfluence * rand_for_line);
    col_accum.x = 1.0f - col_accum.x; // Invert
    col_accum.x = pow(col_accum.x, LineDarknessCurve); // Apply darkness curve

    float3 karo_pattern = 1.0f.xxx; // Default to plain white paper
    if (EnablePaperPattern) {
        float2 s_karo = sin(pos_main.xy * PaperPatternFrequency / sqrt(Res_Screen.y / EffectScaleReferenceHeight));
        // karo_pattern variable already initialized to 1.0f.xxx
        karo_pattern -= PaperPatternIntensity * PaperPatternTint * dot(exp(-s_karo * s_karo * PaperPatternSharpness), 1.0f.xx);
    }
    
    float3 final_col = col_accum.x * col2_accum * karo_pattern; // Vignette removed

    return float4(final_col, 1.0f);
}

// --- Technique Definition ---
technique HandDrawnStyle_Tunable
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_HandDrawn;
    }
}