#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_getTime(), AS_getAnimationTime, AS_PI constants, etc.

static const float EPSILON = 0.00001f; // Local epsilon

//--------------------------------------------------------------------------------------
// UI UNIFORMS
//--------------------------------------------------------------------------------------

// Master Animation Control using AS_Utils macro
// This will define MasterAnimSpeed_Slider and MasterAnimKeyframe_Slider uniforms
AS_ANIMATION_UI(MasterAnimSpeed_Slider, MasterAnimKeyframe_Slider, "Animation - Overall")

uniform int KaleidoscopeSectors < ui_category="Kaleidoscope";
    ui_type = "slider"; ui_min = 1; ui_max = 24; ui_step = 1;
    ui_label = "Mirrors";
    ui_tooltip = "Number of kaleidoscope sectors. 1 means no effect. Even numbers often look best.";
> = 6;

// --- Fractal Pattern Animation & Control ---
uniform float FractalZoomBase < ui_category="Animation - Fractal Pattern";
    ui_type = "drag"; ui_min = 1.01; ui_max = 3.0; ui_step = 0.01;
    ui_label = "Base Zoom Factor";
    ui_tooltip = "Base zoom for the fractal UV transformation. Original: 1.5";
> = 1.5f;

uniform float FractalZoomPulseStrength < ui_category="Animation - Fractal Pattern";
    ui_type = "drag"; ui_min = 0.0; ui_max = 0.5; ui_step = 0.01;
    ui_label = "Zoom Pulse Strength";
    ui_tooltip = "Amount the fractal zoom pulses over time. Added to Base Zoom.";
> = 0.0f; 

uniform float FractalZoomPulseSpeed < ui_category="Animation - Fractal Pattern";
    ui_type = "drag"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01;
    ui_label = "Zoom Pulse Speed";
    ui_tooltip = "Speed of the fractal zoom pulsation (relative to Master Animation Time).";
> = 0.5f;

// --- Wave Animation in Tendrils ---
uniform float PaletteCycleSpeedFactor < ui_category="Animation - Colors & Waves";
    ui_type = "drag"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01;
    ui_label = "Palette Cycle Speed Factor";
    ui_tooltip = "Additional speed control for how fast colors cycle. Multiplies Master Animation Time. Original GLSL factor for time: 0.4";
> = 0.4f;

uniform float WaveMotionSpeedFactor < ui_category="Animation - Colors & Waves";
    ui_type = "drag"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01;
    ui_label = "Wave Motion Speed Factor";
    ui_tooltip = "Additional speed control for how fast the 'tendril' waves move. Multiplies Master Animation Time. Original GLSL factor for time: 1.0";
> = 1.0f;

uniform float WaveFrequency < ui_category="Animation - Colors & Waves";
    ui_type = "drag"; ui_min = 1.0; ui_max = 32.0; ui_step = 0.1;
    ui_label = "Wave Frequency";
    ui_tooltip = "Frequency of the sine wave creating the tendrils. Original GLSL: 8.0";
> = 8.0f;

uniform float WaveAmplitudeDivisor < ui_category="Animation - Colors & Waves";
    ui_type = "drag"; ui_min = 1.0; ui_max = 32.0; ui_step = 0.1;
    ui_label = "Wave Amplitude Divisor";
    ui_tooltip = "Controls wave amplitude (Effective Amplitude = 1 / Divisor). Larger value = smaller waves. Original GLSL: 8.0";
> = 8.0f;

// --- Base Pattern Motion Animation ---
uniform float BasePatternRotationSpeed < ui_category="Animation - Base Pattern Motion";
    ui_type = "drag"; ui_min = -10.0; ui_max = 10.0; ui_step = 0.1;
    ui_label = "Pattern Rotation Speed";
    ui_tooltip = "Speed of rotation for the base pattern *inside* the kaleidoscope mirrors (relative to Master Animation Time).";
> = 0.1f; 

uniform float GlobalPulsingZoomStrength < ui_category="Animation - Base Pattern Motion";
    ui_type = "drag"; ui_min = 0.0; ui_max = 0.5; ui_step = 0.01;
    ui_label = "Pattern Pulsing Zoom Strength";
    ui_tooltip = "Strength of the pulsing zoom effect applied to the base pattern (after kaleidoscope, before fractal).";
> = 0.0f;

uniform float GlobalPulsingZoomSpeed < ui_category="Animation - Base Pattern Motion";
    ui_type = "drag"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01;
    ui_label = "Pattern Pulsing Zoom Speed";
    ui_tooltip = "Speed of the pulsing zoom effect (relative to Master Animation Time).";
> = 0.5f;


// --- Palette Controls ---
uniform float3 PaletteA < ui_category="Palette Colors"; ui_label="A (Offset)"; ui_type="color"; > = float3(0.5, 0.5, 0.5);
uniform float3 PaletteB < ui_category="Palette Colors"; ui_label="B (Amplitude)"; ui_type="color"; > = float3(0.5, 0.5, 0.5);
uniform float3 PaletteC < ui_category="Palette Colors"; ui_label="C (Frequency)"; ui_type="color"; > = float3(1.0, 1.0, 1.0);
uniform float3 PaletteD < ui_category="Palette Colors"; ui_label="D (Phase)"; ui_type="color"; > = float3(0.263,0.416,0.557);


//--------------------------------------------------------------------------------------
// HELPER FUNCTIONS
//--------------------------------------------------------------------------------------
float3 palette(float t) {
    return PaletteA + PaletteB * cos(AS_TWO_PI * (PaletteC * t + PaletteD));
}

float2 kaleidoscope_transform(float2 uv, int sectors) {
    if (sectors <= 1) { 
        return uv;
    }
    float angle = atan2(uv.y, uv.x);
    float radius = length(uv);
    float num_sectors_float = (float)sectors;
    float slice_angle_rad = AS_PI / num_sectors_float; 
    
    angle = fmod(angle, 2.0 * slice_angle_rad);
    if (angle < 0.0) {
        angle += 2.0 * slice_angle_rad;
    }
    angle = abs(angle - slice_angle_rad);
    return float2(radius * cos(angle), radius * sin(angle));
}

//--------------------------------------------------------------------------------------
// PIXEL SHADER
//--------------------------------------------------------------------------------------
float4 PS_KaleidoscopePattern(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {
    // Correctly get master animated time using AS_Utils and UI-defined speed/keyframe
    // MasterAnimSpeed_Slider and MasterAnimKeyframe_Slider are defined by the AS_ANIMATION_UI macro.
    float master_anim_time = AS_getAnimationTime(MasterAnimSpeed_Slider, MasterAnimKeyframe_Slider);

    float2 fragCoord = texcoord * float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float2 iResolution_xy = float2(BUFFER_WIDTH, BUFFER_HEIGHT);

    // 1. Initial Screen UV setup
    float2 current_uv = (fragCoord * 2.0 - iResolution_xy) / iResolution_xy.y;

    // 2. Apply Kaleidoscope transformation FIRST (mirrors stay fixed relative to screen)
    if (KaleidoscopeSectors > 1) {
        current_uv = kaleidoscope_transform(current_uv, KaleidoscopeSectors);
    }
    
    // 3. This 'current_uv' is now the coordinate within a single kaleidoscope wedge.
    //    Now, apply the base pattern rotation to this wedge's coordinate space.
    if (abs(BasePatternRotationSpeed) > EPSILON) {
        float base_rot_angle = master_anim_time * BasePatternRotationSpeed;
        float s_rot = sin(base_rot_angle);
        float c_rot = cos(base_rot_angle);
        float2x2 base_rot_matrix = float2x2(c_rot, s_rot, -s_rot, c_rot); 
        current_uv = mul(current_uv, base_rot_matrix);
    }

    // 4. Apply Pattern Pulsing Zoom to the (kaleidoscoped and then internally rotated) pattern UV
    if (abs(GlobalPulsingZoomStrength) > EPSILON) {
        float zoom_factor = 1.0 + sin(master_anim_time * GlobalPulsingZoomSpeed) * GlobalPulsingZoomStrength;
        current_uv *= zoom_factor;
    }
    
    // This fully transformed UV is the base for the fractal pattern
    float2 uv0 = current_uv; 
    float3 finalColor = float3(0.0, 0.0, 0.0);
    
    // Fractal zoom calculation, also animated by master_anim_time
    float current_fractal_zoom = FractalZoomBase;
    if (abs(FractalZoomPulseStrength) > EPSILON) {
        current_fractal_zoom += sin(master_anim_time * FractalZoomPulseSpeed) * FractalZoomPulseStrength;
    }
    current_fractal_zoom = max(1.01f, current_fractal_zoom); 

    // Assign current_uv to loop_uv to be modified by fractal logic
    float2 loop_uv = current_uv; 

    [loop] 
    for (int i_loop = 0; i_loop < 4; ++i_loop) {
        float i = (float)i_loop; 
        loop_uv = frac(loop_uv * current_fractal_zoom) - 0.5; 
        float d = length(loop_uv) * exp(-length(uv0)); 

        float t_palette = length(uv0) + i * 0.4f + master_anim_time * PaletteCycleSpeedFactor; 
        float3 col = palette(t_palette);

        d = sin(d * WaveFrequency + master_anim_time * WaveMotionSpeedFactor) / max(EPSILON, WaveAmplitudeDivisor); 
        d = abs(d);
        d = pow(0.01f / (d + EPSILON), 1.2f);
        finalColor += col * d;
    }
        
    return float4(saturate(finalColor), 1.0); 
}

//--------------------------------------------------------------------------------------
// TECHNIQUE DEFINITION
//--------------------------------------------------------------------------------------
technique AnimatedPsychedelicKaleidoscope_V5 // Incremented version name
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_KaleidoscopePattern;
    }
}