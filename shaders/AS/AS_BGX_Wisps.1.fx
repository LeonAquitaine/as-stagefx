#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_getTime() and AS_EPSILON

//--------------------------------------------------------------------------------------
// DEFINES
//--------------------------------------------------------------------------------------
// static const float FAR_CLIP_WISPS = 20.0f; // Replaced by FarClip uniform

//--------------------------------------------------------------------------------------
// UI UNIFORMS
//--------------------------------------------------------------------------------------

// --- Animation Control ---
uniform float WispAnimationSpeed < ui_category="Animation";
    ui_type="slider"; ui_min=0.0; ui_max=10.0; ui_step=0.01; 
    ui_label="Wisps Flowing Speed";
    ui_tooltip="Controls the speed at which the wisp pattern flows/scrolls.";
> = 1.0; 

// --- Raymarching Quality ---
uniform int RaymarchSteps < ui_category="Quality";
    ui_type="slider"; ui_min=30; ui_max=200; ui_step=1;
    ui_label="Steps";
    ui_tooltip="Number of steps for raymarching. Higher values for more detail but less performance. Original: 100";
> = 100;

uniform float FarClip < ui_category="Quality";
    ui_type="slider"; ui_min=5.0; ui_max=100.0; ui_step=0.1;
    ui_label="Far Clip";
    ui_tooltip="Maximum distance rays will travel. Original: 20.0";
> = 20.0;

// --- Camera & View ---
uniform float FOVFactor < ui_category="Camera";
    ui_type="slider"; ui_min=0.1; ui_max=3.0; ui_step=0.01;
    ui_label="Perspective Factor (FOV)";
    ui_tooltip="Adjusts field of view. Smaller values zoom in (stronger perspective). Original reference: 1.0";
> = 1.0;

uniform float3 RayOriginOffset < ui_category="Camera"; // Corrected from RayOriginOffsetXYZ to match usage
    ui_type="slider"; ui_min=-2.0; ui_max=2.0; ui_step=0.01;
    ui_label="Ray Origin Offset";
    ui_tooltip="Offset for the raymarching starting point relative to screen center. Original: (0.5, 0.5, 0.5) effectively.";
> = float3(0.5, 0.5, 0.5);


// --- Wisp Shape & Detail ---
uniform bool EnableYReflection < ui_category="Wisp Shape";
    ui_label="Enable Y-Axis Reflection";
    ui_tooltip="Toggles the Y-axis reflection of the pattern space.";
> = true;

uniform float PatternDetail < ui_category="Wisp Shape";
    ui_type="slider"; ui_min=0.1; ui_max=20.0; ui_step=0.1;
    ui_label="Pattern Detail";
    ui_tooltip="Influences the sin(p.xy) contribution to step distance, affecting wisp complexity. Original: 5.0";
> = 5.0;

uniform float ReflectionDampening < ui_category="Wisp Shape";
    ui_type="slider"; ui_min=0.01; ui_max=2.0; ui_step=0.01;
    ui_label="Reflection Dampening";
    ui_tooltip="Dampens the effect of reflected Y on step distance (if Y-reflection is enabled). Original: 0.5";
> = 0.5;

uniform float StepSizeDivisor < ui_category="Wisp Shape";
    ui_type="slider"; ui_min=10.0; ui_max=500.0; ui_step=1.0; ui_logarithmic=true;
    ui_label="Step Size Divisor";
    ui_tooltip="Overall divisor for raymarch step size. Smaller values = larger steps, potentially faster but less detail. Original: 100.0";
> = 100.0;

uniform int TurbulenceIterations < ui_category="Wisp Shape";
    ui_type="slider"; ui_min=0; ui_max=8; ui_step=1;
    ui_label="Turbulence Iterations";
    ui_tooltip="Number of iterations for fractal turbulence. Original: 5";
> = 5;

uniform float TurbulenceDepthInfluence < ui_category="Wisp Shape & Detail"; // Corrected category to match others, ensures it's declared
    ui_type="slider"; ui_min=0.0; ui_max=1.0; ui_step=0.01;
    ui_label="Turbulence Depth Influence";
    ui_tooltip="How much ray depth influences turbulence phase. Original: 0.1";
> = 0.1;

uniform float TurbulenceStrength < ui_category="Wisp Shape";
    ui_type="slider"; ui_min=0.0; ui_max=2.0; ui_step=0.01;
    ui_label="Turbulence Strength";
    ui_tooltip="General multiplier for turbulence displacement.";
> = 1.0;

uniform float PatternFrequency < ui_category="Wisp Shape";
    ui_type="slider"; ui_min=0.1; ui_max=5.0; ui_step=0.01;
    ui_label="Pattern Frequency";
    ui_tooltip="Frequency of the sin(p.xy) component that shapes wisps. Higher = finer details.";
> = 1.0; 


// --- Wisp Appearance & Tonemapping ---
uniform float WispIntensity < ui_category="Appearance"; 
    ui_type="slider"; ui_min=0.001; ui_max=1000.0; ui_step=0.001; ui_logarithmic=true; 
    ui_label="Intensity / Accumulation"; 
    ui_tooltip="Scales the raw color accumulation per step, affecting wisp brightness/strength.";
> = 1.0; 

uniform float TonemapExposure < ui_category="Appearance"; 
    ui_type="slider"; ui_min=1.0; ui_max=10000.0; ui_step=1.0; ui_logarithmic=true;
    ui_label="Tonemap Exposure"; 
    ui_tooltip="Divisor for the accumulated color before tanh tonemapping. Adjusts overall brightness/contrast. Original: 1000.0";
> = 1000.0;

uniform float3 WispColor < ui_category="Appearance"; 
    ui_type="color"; ui_label="Wisp Color";
    ui_tooltip="Color tint for the bright wisps when composited against the background.";
> = float3(1.0, 1.0, 1.0);

uniform float WispBrightness < ui_category="Appearance"; 
    ui_type="slider"; ui_min=0.0; ui_max=5.0; ui_step=0.01;
    ui_label="Wisp Brightness";
    ui_tooltip="How bright the wisps appear against the colorful background.";
> = 1.5;

uniform float WispMaskSharpness < ui_category="Appearance"; 
    ui_type="slider"; ui_min=0.1; ui_max=5.0; ui_step=0.01;
    ui_label="Wisp Mask Sharpness";
    ui_tooltip="Boosts/sharpens the wisp mask created from accumulation. Higher = more defined wisps. Original factor: 1.5";
> = 1.5f;

// --- Background Color ---
uniform float BG_Intensity < ui_category="Background Color"; 
    ui_type="slider"; ui_min=0.0; ui_max=1.0; ui_step=0.01;
    ui_label="Intensity";
    ui_tooltip="Controls the overall intensity/saturation of the procedural background color.";
> = 0.4f;

uniform float BG_AnimSpeed < ui_category="Background Color"; 
    ui_type="slider"; ui_min=0.0; ui_max=1.0; ui_step=0.01;
    ui_label="Animation Speed";
    ui_tooltip="Speed for animating the background palette colors.";
> = 0.1f;

uniform float3 BG_Base < ui_category="Background Color"; 
    ui_type="color"; ui_label="Base Additive";
    ui_tooltip="Base additive color component. Original: 0.4";
> = float3(0.4,0.4,0.4);

uniform float3 BG_RayFactor < ui_category="Background Color"; 
    ui_type="color"; ui_label="Ray Direction Factor";
    ui_tooltip="How much ray direction (yzx) influences BG color. Original: 0.3";
> = float3(0.3,0.3,0.3);

uniform float3 BG_SinewFactor < ui_category="Background Color"; 
    ui_type="color"; ui_label="Sinew Ray Factor";
    ui_tooltip="How much sin(ray direction) (zxy) influences BG color. Original: 0.2";
> = float3(0.2,0.2,0.2);

uniform float BG_SinewFrequency < ui_category="Background Color"; 
    ui_type="slider"; ui_min=0.1; ui_max=10.0; ui_step=0.1;
    ui_label="Sinew Frequency";
    ui_tooltip="Frequency of the sine wave in BG color. Original: 5.0";
> = 5.0;


// --- Debugging Uniforms ---
uniform int Debug_OutputSelector < ui_category="Debug";
    ui_type="combo";
    ui_items="0: Final Output\0"
             "1: Accumulated Color (Pre-Tanh)\0"
             "2: Step Color Base\0"
             "3: Raymarch Step (iter 50)\0"
             "4: Accumulated Depth (iter 50)\0"
             "5: Reflection Value (iter 50)\0"
             "6: Sample XY (iter 50)\0"
             "7: Sample Z (iter 50)\0"
             "8: Wisp Mask\0"; 
    ui_label="View"; 
    ui_tooltip="Selects which intermediate value to output for debugging.";
> = 0;

uniform float3 Debug_NaN_Color < ui_category="Debug"; ui_label="NaN/Inf Color"; ui_type="color"; 
    ui_tooltip="Color to display if NaN or Inf values are detected in the output.";
> = float3(1.0, 0.0, 1.0); 


//--------------------------------------------------------------------------------------
// PIXEL SHADER
//--------------------------------------------------------------------------------------
float4 PS_Wisps(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float iTime_sec_animated = AS_getTime() * WispAnimationSpeed; 
    float iTime_sec_raw = AS_getTime(); 

    float2 fragCoord = vpos.xy; 
    float2 R_screen = float2(BUFFER_WIDTH, BUFFER_HEIGHT);

    float z_depth_current = 0.0f; 
    float r_reflect_val_current = 0.0f;         
    float d_step_val_current = 0.0f;            
    float3 p_sample_capture = 0.0f.xxx; 

    float4 OutputColor = float4(0.0f, 0.0f, 0.0f, 0.0f); 
    float3 D_ray = normalize(float3(fragCoord.x * 2.0f - R_screen.x, fragCoord.y * 2.0f - R_screen.y, -R_screen.y * FOVFactor));

    float captured_d_step_val = 0.0f;
    float captured_z_depth = 0.0f;
    float captured_r_reflect_val = 0.0f;

    [loop] 
    for (int i_iter = 0; i_iter < RaymarchSteps; ++i_iter) 
    {
        float3 p_sample = z_depth_current * D_ray + RayOriginOffset; 
        p_sample.z -= iTime_sec_animated; 

        float p_y_before_abs_reflect = p_sample.y;
        if (EnableYReflection) {
            r_reflect_val_current = max(-p_y_before_abs_reflect, 0.0f);
            p_sample.y = abs(p_y_before_abs_reflect); 
        } else {
            r_reflect_val_current = 0.0f; 
        }

        float d_turbulence = 1.0f;
        for (int turb_idx = 0; turb_idx < TurbulenceIterations; ++turb_idx) 
        {
            if (abs(d_turbulence) < AS_EPSILON) d_turbulence = AS_EPSILON; 
            p_sample += cos(p_sample * d_turbulence - z_depth_current * TurbulenceDepthInfluence).yzx / d_turbulence * TurbulenceStrength; // Use TurbulenceStrength
            d_turbulence *= 2.0f; 
        }
        
        if (i_iter == 50) { p_sample_capture = p_sample; }

        float r_denom = ReflectionDampening + r_reflect_val_current + AS_EPSILON;
        d_step_val_current = (r_reflect_val_current + PatternDetail * length(sin(p_sample.xy * PatternFrequency)) / r_denom) / StepSizeDivisor; // Use PatternFrequency, StepSizeDivisor
        d_step_val_current = max(d_step_val_current, AS_EPSILON * 10.0f); 

        if (i_iter == 50) { 
            captured_d_step_val = d_step_val_current;
            captured_z_depth = z_depth_current; 
            captured_r_reflect_val = r_reflect_val_current;
        }
        
        float3 step_color_base = 0.5f + 0.5f * D_ray; 
        float accumulation_denominator = d_step_val_current * (z_depth_current + d_step_val_current) + AS_EPSILON;
      
        if (abs(accumulation_denominator) > AS_EPSILON) {
            OutputColor.rgb -= step_color_base / accumulation_denominator * WispIntensity; 
        }
                                                                                          
        z_depth_current += d_step_val_current; 
        if (z_depth_current > FarClip) break; 
    }

    // --- Final Output Selection based on Debug Mode ---
    float4 debug_final_color = float4(0.0f, 0.0f, 0.0f, 1.0f); 
    float3 tanned_accumulation; 
    float wisp_mask;         

    if (Debug_OutputSelector == 0 || Debug_OutputSelector == 8) { 
        if (any(isnan(OutputColor.rgb)) || any(isinf(OutputColor.rgb))) {
            if (Debug_OutputSelector == 0) debug_final_color.rgb = Debug_NaN_Color; 
            if (Debug_OutputSelector == 8) debug_final_color.rgb = Debug_NaN_Color; 
            tanned_accumulation = float3(0.0,0.0,0.0); 
            wisp_mask = 0.0;
        } else {
            tanned_accumulation = tanh(OutputColor.rgb / TonemapExposure); 
            wisp_mask = saturate(length(-tanned_accumulation * WispMaskSharpness)); 
            wisp_mask = wisp_mask * wisp_mask; 
        }

        if (Debug_OutputSelector == 0) { 
            float3 background_color = (BG_Base + 
                                       BG_RayFactor * D_ray.yzx + 
                                       BG_SinewFactor * sin(D_ray.zxy * BG_SinewFrequency + iTime_sec_raw * BG_AnimSpeed * 0.5f));
            background_color = saturate(background_color * BG_Intensity);
            
            float3 final_wisp_color = WispColor * WispBrightness;
            debug_final_color.rgb = lerp(background_color, final_wisp_color, wisp_mask);
        } else if (Debug_OutputSelector == 8) { 
            debug_final_color.rgb = wisp_mask.xxx;
        }
    } else if (Debug_OutputSelector == 1) { 
        if (any(isnan(OutputColor.rgb)) || any(isinf(OutputColor.rgb))) {
            debug_final_color.rgb = Debug_NaN_Color;
        } else {
            debug_final_color.rgb = saturate(OutputColor.rgb * 0.02f + 0.5f); 
        }
    } else if (Debug_OutputSelector == 2) { 
        debug_final_color.rgb = 0.5f + 0.5f * D_ray;
    } else if (Debug_OutputSelector == 3) { 
        debug_final_color.rgb = saturate(captured_d_step_val * 100.0f).xxx; 
    } else if (Debug_OutputSelector == 4) { 
        debug_final_color.rgb = frac(captured_z_depth * 0.1f).xxx; 
    } else if (Debug_OutputSelector == 5) { 
        debug_final_color.rgb = frac(captured_r_reflect_val * 0.1f).xxx;
    } else if (Debug_OutputSelector == 6) { 
        debug_final_color.rgb = frac((p_sample_capture.xy / R_screen.xy).xyx * 5.0f); 
    } else if (Debug_OutputSelector == 7) { 
        debug_final_color.rgb = frac(p_sample_capture.zzz * 0.1f);
    }
    
    debug_final_color.a = 1.0f;
    return debug_final_color;
}

//--------------------------------------------------------------------------------------
// Technique Definition
//--------------------------------------------------------------------------------------
technique Wisps_Artistic_V6_Corrected
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Wisps;
    }
}