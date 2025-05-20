#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_getTime(), AS_getAudioSource(), UI macros, AS_PI etc.

//--------------------------------------------------------------------------------------
// UI UNIFORMS
//--------------------------------------------------------------------------------------
uniform float2 MousePoint < source = "mousepoint"; ui_label = "Mouse Position (Pixels)"; >;

// Using AS_Utils standard UI for time control
AS_ANIMATION_UI(TimeSpeed, TimeKeyframe, "Animation Control")

// Using AS_Utils standard UI for audio input that replaces iChannel0's FFT sample
AS_AUDIO_SOURCE_UI(AudioDataSource, "Audio Data Source", AS_AUDIO_BASS, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(AudioDataGain, "Audio Data Gain", 1.0f, 5.0f, "Audio Reactivity")

//--------------------------------------------------------------------------------------
// DEFINES (using ReShade and AS_Utils equivalents)
//--------------------------------------------------------------------------------------
#define iResolution float2(BUFFER_WIDTH, BUFFER_HEIGHT)
// iMouse is MousePoint (pixels)
// iTime will be calculated from AS_getAnimationTime

//--------------------------------------------------------------------------------------
// HELPER FUNCTIONS (from GLSL, adapted to HLSL)
//--------------------------------------------------------------------------------------

// distance of the point p to the line that starts on the point a and ends on the point b
float dist_line(float2 p, float2 a, float2 b) {
    float2 pa = p - a;
    float2 ba = b - a;
    // Use AS_EPSILON from AS_Utils.1.fxh to prevent division by zero
    float t = saturate(dot(pa, ba) / (dot(ba, ba) + AS_EPSILON)); 
    return length(pa - ba * t);   
}

// pseudo random float
float n21(float2 p) {
    p = frac(p * float2(233.24f, 851.73f));
    p += dot(p, p + 23.45f);
    return frac(p.x * p.y);
}

// pseudo random float2
float2 n22(float2 p) {
    float n = n21(p);
    return float2(n, n21(p + n)); // Note: original GLSL was p+n, not p+n.x or similar
}

// Get animated position for a grid cell point
float2 get_pos(float2 id, float2 offs, float current_time_local) { 
    float2 n = n22(id + offs) * current_time_local; 
    return offs + sin(n) * 0.4f;
}

// Calculate line intensity based on distance and other factors
float line(float2 p, float2 a, float2 b) {
    float d = dist_line(p, a, b);
    float m = smoothstep(0.03f, 0.01f, d); 
    float d2 = length(a - b); 
    m *= smoothstep(1.6f, 0.5f, d2) * 0.5f + smoothstep(0.05f, 0.03f, abs(d2 - 0.75f));
    return m;
}

// Generate one layer of the pattern for a given UV coordinate
float layer(float2 uv, float current_time_local) { 
    float m = 0.0f;
    float2 gv = frac(uv) - 0.5f; 
    float2 id = floor(uv);      

    float2 p_arr[9]; // Renamed p to p_arr to avoid conflict if p is used later
    int idx = 0; // Renamed i to idx
    
    for (float y_offset = -1.0f; y_offset <= 1.0f; y_offset += 1.0f) {
        for (float x_offset = -1.0f; x_offset <= 1.0f; x_offset += 1.0f) {
            if (idx < 9) p_arr[idx++] = get_pos(id, float2(x_offset, y_offset), current_time_local);
        }
    }
    
    float t_sparkle = current_time_local * 10.0f; 
    for (int k = 0; k < 9; k++) { // Changed i to k
        m += line(gv, p_arr[4], p_arr[k]); 
        
        float2 j_sparkle = (p_arr[k] - gv) * 10.0f; // Renamed j to j_sparkle
        float sparkle_val = 1.0f / (dot(j_sparkle, j_sparkle) + AS_EPSILON); // Added epsilon
        m += sparkle_val * (sin(t_sparkle + frac(p_arr[k].x) * 10.0f) * 0.5f + 0.5f);
    }
    
    m += line(gv, p_arr[1], p_arr[3]); 
    m += line(gv, p_arr[1], p_arr[5]); 
    m += line(gv, p_arr[5], p_arr[7]); 
    m += line(gv, p_arr[3], p_arr[7]);
    
    return m;
}

//--------------------------------------------------------------------------------------
// PIXEL SHADER (mainImage)
//--------------------------------------------------------------------------------------
float4 PS_ArtOfCodeLines(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    // Calculate current effective time using AS_Utils animation controls
    float current_iTime = AS_getAnimationTime(TimeSpeed, TimeKeyframe);

    float2 fragCoord = texcoord * iResolution; 

    float2 uv = (fragCoord - 0.5f * iResolution) / iResolution.y;
    
    float gradient_base = uv.y; 
    
    float2 mouse_pixel_coords = MousePoint; // Already in pixels from ReShade
    float2 mouse_normalized_centered = (mouse_pixel_coords / iResolution) - 0.5f; 
    
    float m_accum = 0.0f; // Renamed m to m_accum
    
    float t_anim_main = current_iTime * 0.1f; 
    
    float s_rot = sin(t_anim_main * 2.0f);
    float c_rot = cos(t_anim_main * 5.0f); // Note: sin and cos use different time factors
    // GLSL mat2(c, -s, s, c) -> col0=(c,-s), col1=(s,c) -> [ c  s ]
    //                                                      [-s  c ]
    // HLSL float2x2(m00,m01,m10,m11) -> [m00 m01]
    //                                   [m10 m11]
    float2x2 rot_matrix = float2x2(c_rot, s_rot, -s_rot, c_rot); // Matches GLSL visual result for mul(uv, matrix)

    float2 uv_rotated = mul(uv, rot_matrix); 
    float2 mouse_rotated = mul(mouse_normalized_centered, rot_matrix);

    const float step_val = 1.0f / 4.0f;
    // This loop must have fixed iterations or be unrollable for some ReShade targets
    // It runs 4 times (i_layer = 0.0, 0.25, 0.5, 0.75)
    // A `[loop]` attribute might be good if it causes issues, or convert to int loop.
    // For now, direct translation:
    for (float i_layer = 0.0f; i_layer < (1.0f - step_val / 2.0f); i_layer += step_val) { // Loop 4 times
        float z_phase = frac(i_layer + t_anim_main);    
        float size_mix = lerp(10.0f, 0.5f, z_phase); 
        float fade_mix = smoothstep(0.0f, 0.5f, z_phase) * smoothstep(1.0f, 0.8f, z_phase); 
        
        m_accum += layer(uv_rotated * size_mix + i_layer * 20.0f - mouse_rotated, current_iTime) * fade_mix;
    }
    
    float3 base_color_palette = sin(t_anim_main * 20.0f * float3(0.345f, 0.543f, 0.682f)) * 0.25f + 0.75f;
    
    float3 col_final = m_accum * base_color_palette; 
    
    // Get audio data using AS_Utils
    float audio_value = AS_getAudioSource(AudioDataSource);
    float fft_simulated = audio_value * AudioDataGain;
    
    float gradient_eff = gradient_base * fft_simulated * 2.0f; 
    
    col_final -= gradient_eff * base_color_palette; 
    
    return float4(saturate(col_final), 1.0f); 
}

//--------------------------------------------------------------------------------------
// TECHNIQUE
//--------------------------------------------------------------------------------------
technique ArtOfCodeLines_AudioReactive <
    ui_tooltip = "Abstract line patterns animated and influenced by audio.\n"
                 "Based on a shader from 'Art of The Code'. Uses AS_Utils for time and audio.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_ArtOfCodeLines;
    }
}