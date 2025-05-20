#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_getTime(), AS_getAudioSource(), UI macros, AS_PI etc.

//--------------------------------------------------------------------------------------
// Texture Definition
//--------------------------------------------------------------------------------------
#ifndef NOISE_TEXTURE_PATH_HANDDRAWN
#define NOISE_TEXTURE_PATH_HANDDRAWN "perlin512x8CNoise.png" 
#endif

texture PencilDrawing_NoiseTex < source = NOISE_TEXTURE_PATH_HANDDRAWN; ui_label = "Noise Pattern Texture"; ui_tooltip = "Texture used for randomizing strokes and fills (e.g., Perlin, Blue Noise)."; >
{
    Width = 512; Height = 512; Format = RGBA8;
};
sampler PencilDrawing_NoiseSampler { Texture = PencilDrawing_NoiseTex; AddressU = REPEAT; AddressV = REPEAT; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };

//--------------------------------------------------------------------------------------
// Global Defines & Constants
//--------------------------------------------------------------------------------------
#define NOISE_TEX_WIDTH 512.0f
#define NOISE_TEX_HEIGHT 512.0f

#define Res1 float2(NOISE_TEX_WIDTH, NOISE_TEX_HEIGHT) 
#define Res_Screen float2(BUFFER_WIDTH, BUFFER_HEIGHT)    

// Using AS_PI from AS_Utils.1.fxh, so local PI define is not strictly needed
// static const float PI2 = 6.28318530717959f; // Can use AS_TWO_PI

//--------------------------------------------------------------------------------------
// UI UNIFORMS
//--------------------------------------------------------------------------------------

// --- Animation Control ---
AS_ANIMATION_UI(TimeSpeed, TimeKeyframe, "Animation & Time")

// --- Audio Reactivity (Consolidated) ---
AS_AUDIO_SOURCE_UI(MasterAudioSource, "Master Audio Source", AS_AUDIO_BASS, "Audio Reactivity")

uniform float AudioGain_GradientEffect < ui_category="Audio Reactivity";
    ui_label = "Gradient Effect Audio Gain"; ui_tooltip = "How much audio affects the color gradient subtraction.";
    ui_type = "slider"; ui_min = 0.0; ui_max = 5.0; ui_step = 0.01; 
> = 1.0f;

uniform float AudioGain_LineBrightness < ui_category="Audio Reactivity";
    ui_label = "Line Brightness Audio Gain"; ui_tooltip = "How much audio affects overall line brightness.";
    ui_type = "slider"; ui_min = 0.0; ui_max = 2.0f; ui_step = 0.01; 
> = 0.0f; // Default to off

uniform float AudioGain_LineFalloff < ui_category="Audio Reactivity";
    ui_label = "Line Falloff Audio Gain"; ui_tooltip = "How much audio affects line falloff width (can make lines appear thinner/softer).";
    ui_type = "slider"; ui_min = 0.0; ui_max = 2.0f; ui_step = 0.01; 
> = 0.0f; // Default to off

uniform float AudioGain_SparkleMagnitude < ui_category="Audio Reactivity";
    ui_label = "Sparkle Magnitude Audio Gain"; ui_tooltip = "How much audio affects sparkle twinkle strength.";
    ui_type = "slider"; ui_min = 0.0; ui_max = 3.0f; ui_step = 0.01; 
> = 0.0f; // Default to off


// --- Constellation Lines --- (Defaults from your last provided version)
uniform float LineCoreThickness < ui_category="Constellation Lines"; ui_type="drag"; ui_min=0.001; ui_max=0.05; ui_step=0.001; ui_label="Line Core Thickness"; > = 0.01f;
uniform float LineFalloffWidth < ui_category="Constellation Lines"; ui_type="drag"; ui_min=0.001; ui_max=0.1; ui_step=0.001; ui_label="Line Falloff Width"; > = 0.02f;
uniform float LineOverallBrightness < ui_category="Constellation Lines"; ui_type="drag"; ui_min=0.0; ui_max=10.0; ui_step=0.1; ui_label="Line Overall Brightness"; > = 1.0f;
uniform float LineLengthModStrength < ui_category="Constellation Lines"; ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_step=0.01; ui_label="Line Length Brightness Modulation"; > = 1.0f;

// --- Star Sparkles --- (Defaults from your last provided version)
uniform float SparkleSharpness < ui_category="Star Sparkles"; ui_type="drag"; ui_min=1.0; ui_max=50.0; ui_step=0.1; ui_label="Sparkle Sharpness / Area Divisor"; > = 10.0f;
uniform float SparkleBaseIntensity < ui_category="Star Sparkles"; ui_type="drag"; ui_min=0.0; ui_max=5.0; ui_step=0.01; ui_label="Sparkle Base Intensity"; > = 1.0f;
uniform float SparkleTwinkleSpeed < ui_category="Star Sparkles"; ui_type="drag"; ui_min=0.0; ui_max=50.0; ui_step=0.1; ui_label="Sparkle Twinkle Speed"; > = 10.0f;
uniform float SparkleTwinkleMagnitude < ui_category="Star Sparkles"; ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_step=0.01; ui_label="Sparkle Twinkle Magnitude"; > = 1.0f;
uniform float SparklePhaseVariation < ui_category="Star Sparkles"; ui_type="drag"; ui_min=0.0; ui_max=50.0; ui_step=0.1; ui_label="Sparkle Twinkle Phase Variation"; > = 10.0f;

// --- Color Palette --- (Defaults from your last provided version)
uniform float PaletteTimeScale < ui_category="Color Palette"; ui_type="drag"; ui_min=0.0; ui_max=100.0; ui_step=0.1; ui_label="Palette Animation Speed"; > = 20.0f;
uniform float3 PaletteColorPhaseFactors < ui_category="Color Palette"; ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_step=0.001; ui_label="Palette Color Phase Factors (RGB)"; > = float3(0.345f, 0.543f, 0.682f);
uniform float PaletteColorAmplitude < ui_category="Color Palette"; ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_step=0.01; ui_label="Palette Color Amplitude"; > = 0.25f;
uniform float PaletteColorBias < ui_category="Color Palette"; ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_step=0.01; ui_label="Palette Color Bias (Brightness)"; > = 0.75f;

// --- Animation & Jitter --- (Defaults from your last provided version)
uniform float AnimationWobbleStrength < ui_category="Animation & Jitter"; ui_type="drag"; ui_min=0.0; ui_max=20.0; ui_step=0.1; ui_label="Animation Wobble Strength"; > = 0.0; 
uniform float2 AnimationWobbleFrequency < ui_category="Animation & Jitter"; ui_type = "drag"; ui_label = "Animation Wobble Pattern (X, Y Freq)"; ui_min = 0.1; ui_max = 5.0; ui_step = 0.01; > = float2(2.56, 1.78); 
uniform float EffectScaleReferenceHeight < ui_category="Animation & Jitter"; ui_type = "slider"; ui_label = "Effect Scale Reference Height"; ui_min = 100.0; ui_max = 2160.0; ui_step = 10.0; > = 1287.0; 

// --- Line Work & Strokes (cont.) --- (Defaults from your last provided version)
uniform int NumberOfStrokeDirections < ui_category="Line Work & Strokes"; ui_type = "slider"; ui_label = "Number of Stroke Directions"; ui_min = 1; ui_max = 10; ui_step = 1; > = 7; 
uniform int LineLengthSamples < ui_category="Line Work & Strokes"; ui_type = "slider"; ui_label = "Line Length (Samples per Direction)"; ui_min = 1; ui_max = 32; ui_step = 1; > = 16; 
uniform float MaxIndividualLineOpacity < ui_category="Line Work & Strokes"; ui_type = "slider"; ui_label = "Max Individual Line Opacity"; ui_min = 0.0; ui_max = 0.2; ui_step = 0.001; > = 0.069; 
uniform float OverallLineLengthScale < ui_category="Line Work & Strokes"; ui_type = "slider"; ui_label = "Overall Line Length Scale"; ui_min = 0.1; ui_max = 5.0; ui_step = 0.01; > = 1.10; 

// --- Line Shading & Texture (cont.) --- (Defaults from your last provided version)
uniform float LineDarknessCurve < ui_category="Line Shading & Texture"; ui_type = "slider"; ui_label = "Line Darkness Curve (Exponent)"; ui_min = 1.0; ui_max = 5.0; ui_step = 0.1; > = 3.0; 
uniform float LineWorkDensity < ui_category="Line Shading & Texture"; ui_type = "slider"; ui_label = "Line Work Density"; ui_min = 0.5; ui_max = 4.0; ui_step = 0.01; > = 1.33; 
uniform float LineTextureInfluence < ui_category="Line Shading & Texture"; ui_type = "slider"; ui_label = "Line Texture Influence"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; > = 0.0; 
uniform float LineTextureBaseBrightness < ui_category="Line Shading & Texture"; ui_type = "slider"; ui_label = "Line Texture Base Brightness"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; > = 0.6; 
uniform float LineTextureNoiseScale < ui_category="Line Shading & Texture"; ui_type = "slider"; ui_label = "Line Texture Noise UV Scale"; ui_min = 0.1; ui_max = 2.0; ui_step = 0.01; > = 0.7; 

// --- Color Processing & Fill (cont.) --- (Defaults from your last provided version)
uniform float MainColorDesaturationMix < ui_category="Color Processing & Fill"; ui_type = "slider"; ui_label = "Main Color Desaturation Mix"; ui_min = 0.0; ui_max = 5.0; ui_step = 0.01; > = 1.0; 
uniform float MainColorBrightnessCap < ui_category="Color Processing & Fill"; ui_type = "slider"; ui_label = "Main Color Brightness Cap"; ui_min = 0.1; ui_max = 1.0; ui_step = 0.01; > = 0.62; 
uniform float FillTextureEdgeSoftnessMin < ui_category="Color Processing & Fill"; ui_type = "slider"; ui_label = "Fill Texture Edge Softness (Min)"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; > = 0.65; 
uniform float FillTextureEdgeSoftnessMax < ui_category="Color Processing & Fill"; ui_type = "slider"; ui_label = "Fill Texture Edge Softness (Max)"; ui_min = 0.5; ui_max = 1.5; ui_step = 0.01; > = 0.88; 
uniform float FillColorBaseFactor < ui_category="Color Processing & Fill"; ui_type = "slider"; ui_label = "Fill Color Base Factor"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; > = 0.37; 
uniform float FillColorOffsetFactor < ui_category="Color Processing & Fill"; ui_type = "slider"; ui_label = "Fill Color Offset Factor"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; > = 0.29; 
uniform float FillTextureNoiseStrength < ui_category="Color Processing & Fill"; ui_type = "slider"; ui_label = "Fill Texture Noise Strength"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; > = 0.96; 
uniform float FillTextureNoiseScale < ui_category="Color Processing & Fill"; ui_type = "slider"; ui_label = "Fill Texture Noise UV Scale"; ui_min = 0.1; ui_max = 2.0; ui_step = 0.01; > = 1.79; 
uniform float NoiseLookupOverallScale < ui_category="Color Processing & Fill"; ui_type = "slider"; ui_label = "Noise Lookup Overall Scale Reference"; ui_min = 100.0; ui_max = 4000.0; ui_step = 10.0; > = 2500.0; 

// --- Paper & Background Style --- (Defaults from your last provided version)
uniform bool EnablePaperPattern < ui_category="Background & Paper Style"; ui_label = "Enable Paper Pattern"; > = true; 
uniform float PaperPatternFrequency < ui_category="Background & Paper Style"; ui_type = "slider"; ui_label = "Paper Pattern Frequency"; ui_min = 0.01; ui_max = 0.5; ui_step = 0.001; > = 0.01; 
uniform float PaperPatternIntensity < ui_category="Background & Paper Style"; ui_type = "slider"; ui_label = "Paper Pattern Intensity"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; > = 0.36; 
uniform float3 PaperPatternTint < ui_category="Background & Paper Style"; ui_type = "color"; ui_label = "Paper Pattern Color Tint"; > = float3(64.0/255.0, 26.0/255.0, 26.0/255.0); 
uniform float PaperPatternSharpness < ui_category="Background & Paper Style"; ui_type = "slider"; ui_label = "Paper Pattern Sharpness"; ui_min = 10.0; ui_max = 200.0; ui_step = 1.0; > = 80.0; 


//--------------------------------------------------------------------------------------
// DEFINES
//--------------------------------------------------------------------------------------
#define iResolution float2(BUFFER_WIDTH, BUFFER_HEIGHT)

//--------------------------------------------------------------------------------------
// HELPER FUNCTIONS
//--------------------------------------------------------------------------------------
float dist_line(float2 p, float2 a, float2 b) {
    float2 pa = p - a;
    float2 ba = b - a;
    float t = saturate(dot(pa, ba) / (dot(ba, ba) + AS_EPSILON)); 
    return length(pa - ba * t);   
}

float n21(float2 p) {
    p = frac(p * float2(233.24f, 851.73f));
    p += dot(p, p + 23.45f);
    return frac(p.x * p.y);
}

float2 n22(float2 p) {
    float n = n21(p);
    return float2(n, n21(p + n)); 
}

float2 get_pos(float2 id, float2 offs, float current_time_local) { 
    float2 n = n22(id + offs) * current_time_local; 
    return offs + sin(n) * 0.4f; 
}

float line(float2 p, float2 a, float2 b, float current_LineCoreThickness, float current_LineFalloffWidth_audio_mod) {
    float d = dist_line(p, a, b);
    float line_fade_end = current_LineCoreThickness + current_LineFalloffWidth_audio_mod; // Use audio-modulated falloff
    float m = smoothstep(line_fade_end, current_LineCoreThickness, d); 
    float d2 = length(a - b); 
    float d2_modulation_original = smoothstep(1.6f, 0.5f, d2) * 0.5f + smoothstep(0.05f, 0.03f, abs(d2 - 0.75f));
    m *= lerp(1.0f, saturate(d2_modulation_original), LineLengthModStrength); 
    return m;
}

float layer(float2 uv, float current_time_local, float current_LineCoreThickness, float current_LineFalloffWidth_audio_mod, float current_SparkleTwinkleMagnitude_audio_mod) { 
    float m = 0.0f;
    float2 gv = frac(uv) - 0.5f; 
    float2 id = floor(uv);      
    float2 p_arr[9]; 
    int idx = 0; 
    for (float y_offset = -1.0f; y_offset <= 1.0f; y_offset += 1.0f) {
        for (float x_offset = -1.0f; x_offset <= 1.0f; x_offset += 1.0f) {
            if (idx < 9) p_arr[idx++] = get_pos(id, float2(x_offset, y_offset), current_time_local);
        }
    }
    float t_sparkle_anim = current_time_local * SparkleTwinkleSpeed; 
    for (int k = 0; k < 9; k++) { 
        m += line(gv, p_arr[4], p_arr[k], current_LineCoreThickness, current_LineFalloffWidth_audio_mod); 
        float2 j_sparkle = (p_arr[k] - gv) * SparkleSharpness; 
        float sparkle_intensity_base = SparkleBaseIntensity / (dot(j_sparkle, j_sparkle) + AS_EPSILON); 
        float twinkle_effect = (sin(t_sparkle_anim + frac(p_arr[k].x) * SparklePhaseVariation) * 0.5f + 0.5f);
        m += sparkle_intensity_base * twinkle_effect * current_SparkleTwinkleMagnitude_audio_mod; // Use audio-modulated magnitude
    }
    m += line(gv, p_arr[1], p_arr[3], current_LineCoreThickness, current_LineFalloffWidth_audio_mod); 
    m += line(gv, p_arr[1], p_arr[5], current_LineCoreThickness, current_LineFalloffWidth_audio_mod); 
    m += line(gv, p_arr[5], p_arr[7], current_LineCoreThickness, current_LineFalloffWidth_audio_mod); 
    m += line(gv, p_arr[3], p_arr[7], current_LineCoreThickness, current_LineFalloffWidth_audio_mod);
    return m;
}

//--------------------------------------------------------------------------------------
// PIXEL SHADER
//--------------------------------------------------------------------------------------
float4 PS_ArtOfCodeLines(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float current_iTime = AS_getAnimationTime(TimeSpeed, TimeKeyframe);
    float2 fragCoord = texcoord * iResolution; 
    float2 uv = (fragCoord - 0.5f * iResolution) / iResolution.y;
    float gradient_base = uv.y; 
    float2 mouse_offset_replacement = float2(0.0f, 0.0f); 
    float m_accum = 0.0f; 
    float t_anim_main = current_iTime * 0.1f; 
    float s_rot = sin(t_anim_main * 2.0f);
    float c_rot = cos(t_anim_main * 5.0f); 
    float2x2 rot_matrix = float2x2(c_rot, s_rot, -s_rot, c_rot); 
    float2 uv_rotated = mul(uv, rot_matrix); 

    // Get master audio level once
    float master_audio_level = AS_getAudioSource(MasterAudioSource);

    // Apply audio reactivity to parameters using master audio level and specific gains
    float active_LineOverallBrightness = LineOverallBrightness * (1.0f + master_audio_level * AudioGain_LineBrightness);
    float active_SparkleTwinkleMagnitude = SparkleTwinkleMagnitude * (1.0f + master_audio_level * AudioGain_SparkleMagnitude);
    float active_LineFalloffWidth = LineFalloffWidth * (1.0f + master_audio_level * AudioGain_LineFalloff);
    active_LineFalloffWidth = max(0.001f, active_LineFalloffWidth); 

    // FFT simulated value for gradient effect, also using master audio level
    float fft_simulated = master_audio_level * AudioGain_GradientEffect;


    const float step_val = 1.0f / 4.0f;
    for (float i_layer = 0.0f; i_layer < (1.0f - step_val / 2.0f); i_layer += step_val) { 
        float z_phase = frac(i_layer + t_anim_main);    
        float size_mix = lerp(10.0f, 0.5f, z_phase);  
        float fade_mix = smoothstep(0.0f, 0.5f, z_phase) * smoothstep(1.0f, 0.8f, z_phase); 
        
        m_accum += layer(uv_rotated * size_mix + i_layer * 20.0f - mouse_offset_replacement, 
                         current_iTime, 
                         LineCoreThickness, // Base thickness
                         active_LineFalloffWidth, // Audio-modulated falloff
                         active_SparkleTwinkleMagnitude // Audio-modulated sparkle magnitude
                        ) * fade_mix;
    }
    
    float3 base_color_palette = sin(t_anim_main * PaletteTimeScale * PaletteColorPhaseFactors) * PaletteColorAmplitude + PaletteColorBias;
    
    float3 col_final = m_accum * active_LineOverallBrightness * base_color_palette; // Use audio-modulated brightness
    
    float gradient_eff = gradient_base * fft_simulated * 2.0f; 
    col_final -= gradient_eff * base_color_palette; 
    
    return float4(saturate(col_final), 1.0f); 
}

//--------------------------------------------------------------------------------------
// TECHNIQUE
//--------------------------------------------------------------------------------------
technique ArtOfCodeLines_FullyAudioReactive <
    ui_tooltip = "Abstract animated line patterns with extensive artistic and simplified, powerful audio-reactive controls.\n"
                 "Based on a shader from 'Art of The Code'. Uses AS_Utils for time and audio.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_ArtOfCodeLines;
    }
}