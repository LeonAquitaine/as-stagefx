#include "ReShade.fxh"
#include "AS_Utils.1.fxh" 

// ============================================================================
// TECHNIQUE GUARD
// ============================================================================
#ifndef __AS_VFX_RadiantFire_1_fx__ // Updated guard
#define __AS_VFX_RadiantFire_1_fx__

// ============================================================================
// TEXTURES & SAMPLERS for Flame Buffer (Ping-Pong Style)
// ============================================================================

texture FlameStateBuffer_A < ui_label = "Flame State Buffer A (Persistent)"; >
{
    Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F;
};
sampler SamplerFlameState_A
{
    Texture = FlameStateBuffer_A;
    AddressU = CLAMP; AddressV = CLAMP;
    MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = NONE;
};

texture FlameStateBuffer_B < ui_label = "Flame State Buffer B (Temporary)"; >
{
    Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F;
};
sampler SamplerFlameState_B
{
    Texture = FlameStateBuffer_B;
    AddressU = CLAMP; AddressV = CLAMP;
    MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = NONE;
};


// ============================================================================
// NAMESPACE
// ============================================================================
namespace ASRadiatingFire_Buffer {

//------------------------------------------------------------------------------------------------
// Uniforms
//------------------------------------------------------------------------------------------------
uniform float Timer < source = "timer"; ui_label = "Timer (ms)"; >;

// --- Subject Detection & Edges ---
uniform float uSubjectDepthCutoff < ui_type = "slider"; ui_label = "Subject Depth Cutoff"; ui_min = 0.001; ui_max = 1.0; ui_step = 0.001; ui_category = "Subject & Source"; > = 0.1;
uniform float uEdgeDetectionSensitivity < ui_type = "slider"; ui_label = "Edge Sensitivity"; ui_min = 1.0; ui_max = 200.0; ui_step = 1.0;  ui_category = "Subject & Source"; > = 50.0; 
uniform float uEdgeSoftness <  ui_type = "slider"; ui_label = "Edge Softness"; ui_min = 0.001; ui_max = 0.5; ui_step = 0.001;  ui_category = "Subject & Source"; > = 0.02;
uniform bool bOverlaySubject < // New Uniform
    ui_type = "bool";
    ui_label = "Overlay Subject on Fire";
    ui_tooltip = "If checked, the original subject (defined by depth cutoff) will be drawn on top of the fire effect.";
    ui_category = "Subject & Source"; // Or "Final Composition"
> = true;


// --- Flame Simulation Controls ---
uniform float2 uFireRepulsionCenterPos < ui_type = "drag"; ui_label = "Fire Repulsion Center (Screen XY)"; ui_tooltip = "Normalized screen position (0-1) the fire radiates AWAY from."; ui_min = 0.0; ui_max = 1.0; ui_speed = 0.01; ui_category = "Flame Simulation"; > = float2(0.5, 1.0); 
uniform float uSourceInjectionStrength < ui_type = "slider"; ui_label = "Source: Injection Strength"; ui_tooltip = "Amount of 'heat' injected at subject edges."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Flame Simulation"; > = 0.5;
uniform float uAdvectionStrength < ui_type = "slider"; ui_label = "Advection: Velocity Influence"; ui_tooltip = "How strongly flames move based on their existing velocity."; ui_min = 0.0; ui_max = 5.0; ui_step = 0.01; ui_category = "Flame Simulation"; > = 1.0;
uniform float uRepulsionStrength < ui_type = "slider"; ui_label = "Physics: Repulsion Strength"; ui_tooltip = "How strongly flames are pushed from the repulsion center."; ui_min = 0.0; ui_max = 0.01; ui_step = 0.0001; ui_category = "Flame Simulation"; > = 0.002;
uniform float uGeneralBuoyancy < ui_type = "slider"; ui_label = "Physics: General Buoyancy"; ui_tooltip = "Constant upwards drift for all flames (screen space)."; ui_min = 0.0; ui_max = 0.005; ui_step = 0.00001; ui_category = "Flame Simulation"; > = 0.0005;
uniform float uDraftSpeed < 
    ui_type = "slider";
    ui_label = "Physics: Draft Speed";
    ui_tooltip = "Constant vertical draft. Positive = up, Negative = down.";
    ui_min = -0.005; ui_max = 0.005; ui_step = 0.00001;
    ui_category = "Flame Simulation";
> = 0.0; 

uniform float uDiffusion < ui_type = "slider"; ui_label = "Physics: Diffusion (Spread/Blur)"; ui_tooltip = "How much the flame spreads/blurs out. Uses UV offset."; ui_min = 0.0; ui_max = 0.005; ui_step = 0.0001; ui_category = "Flame Simulation"; > = 0.0005;
uniform float uDissipation < ui_type = "slider"; ui_label = "Physics: Dissipation (Cooling/Fade)"; ui_tooltip = "Rate at which flame intensity fades over time (0=no fade, 1=instant fade)."; ui_min = 0.0; ui_max = 0.1; ui_step = 0.001; ui_category = "Flame Simulation"; > = 0.01;
uniform float uVelocityDamping < ui_type = "slider"; ui_label = "Physics: Velocity Damping"; ui_tooltip = "How quickly flame velocity fades (0=no damping, 1=instant stop)."; ui_min = 0.0; ui_max = 0.1; ui_step = 0.001; ui_category = "Flame Simulation"; > = 0.02;

uniform float uGLSLTurbulenceAdvectionInfluence < 
    ui_type = "slider";
    ui_label = "GLSL Turbulence: Advection Influence";
    ui_tooltip = "Scales the displacement applied to advection lookups by the GLSL turbulence pattern.";
    ui_min = 0.0; ui_max = 0.1; ui_step = 0.001; 
    ui_category = "Flame Simulation";
> = 0.005;


// --- Flame Rendering Controls ---
uniform float uFlameIntensity < ui_type = "slider"; ui_label = "Render: Flame Intensity"; ui_min = 0.0; ui_max = 10.0; ui_step = 0.01; ui_category = "Flame Rendering"; > = 1.5;
uniform float3 uFlameColorCore < ui_type = "color"; ui_label = "Render: Core Color"; ui_category = "Flame Rendering"; > = float3(1.0, 0.8, 0.2); 
uniform float3 uFlameColorMid < ui_type = "color"; ui_label = "Render: Mid Color"; ui_category = "Flame Rendering"; > = float3(1.0, 0.4, 0.0);  
uniform float3 uFlameColorOuter < ui_type = "color"; ui_label = "Render: Outer Color"; ui_category = "Flame Rendering"; > = float3(0.5, 0.1, 0.0); 
uniform float uFlameColorThresholdCore < ui_type = "slider"; ui_label = "Render: Core Temp Threshold"; ui_min = 0.5; ui_max = 2.0; ui_step = 0.01; ui_category = "Flame Rendering"; > = 1.0;
uniform float uFlameColorThresholdMid < ui_type = "slider"; ui_label = "Render: Mid Temp Threshold"; ui_min = 0.1; ui_max = 1.0; ui_step = 0.01; ui_category = "Flame Rendering"; > = 0.5;


AS_DEBUG_MODE_UI("Off\0Subject Mask\0Edge Factor\0Flame Buffer Temp (R)\0Flame Buffer Vel (GB)\0Turbulence Displacement (RG)\0") 
AS_BLENDMODE_UI_DEFAULT(OutputBlendMode, AS_BLEND_ADDITIVE)
AS_BLENDAMOUNT_UI(OutputBlendAmount)

//------------------------------------------------------------------------------------------------
// Helper Function: GLSL Fire Turbulence Coordinate Displacement
//------------------------------------------------------------------------------------------------
float2 GetGLSLTurbulenceDisplacement(float2 screen_uv, float time_sec)
{
    float2 r_screensize = ReShade::ScreenSize.xy;
    float2 p_centered_ndc = screen_uv * 2.0 - 1.0; 
    p_centered_ndc.y *= -1.0; 
    float2 p_initial = p_centered_ndc * float2(r_screensize.x / r_screensize.y, 1.0); 
    
    float2 p_distorted = p_initial;
    if (abs(p_initial.y) > 0.001) {
         p_distorted *= 1.0 - 0.5 / float2(1.0 / p_initial.y, 1.0 + dot(p_initial, p_initial)); 
    }

    float2 p_scrolled = p_distorted;
    p_scrolled.y -= time_sec; 

    float2 p_loop = p_scrolled; 
    float F_freq = 11.0;
    float2 R_vec = float2(F_freq, 7.0); 

    [loop]
    for ( ; F_freq < 50.0; F_freq *= 1.2 )
    {
        R_vec.x += 1.07; 
        R_vec.y += 0.83;
        float2 sin_R = sin(R_vec);
        float2 cos_R = cos(R_vec);
        p_loop += 0.4 * sin( F_freq * dot( p_loop, sin_R ) + 6.0 * time_sec ) * cos_R / F_freq;
    }
    
    float2 displacement_in_p_space = p_loop - p_scrolled;
    float2 displacement_uv = displacement_in_p_space;
    displacement_uv.x /= (r_screensize.x / r_screensize.y);
    displacement_uv.y *= -1.0; 

    return displacement_uv;
}


//------------------------------------------------------------------------------------------------
// Pixel Shader: Flame Simulation Update
//------------------------------------------------------------------------------------------------
float4 UpdateFlameStatePS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float4 prevState = tex2D(SamplerFlameState_A, texcoord);
    float prevTemp = prevState.r; 
    float2 prevVel = prevState.gb;   

    float newTemp = prevTemp;
    float2 newVel = prevVel;

    float2 pixelSize = ReShade::PixelSize;
    float time_sec = Timer / 1000.0;

    float2 turbulent_uv_offset = GetGLSLTurbulenceDisplacement(texcoord, time_sec);
    
    // 1. Advection
    float2 baseAdvectLookup = texcoord - prevVel * uAdvectionStrength * pixelSize * 20.0; 
    float2 finalAdvectLookup = baseAdvectLookup + turbulent_uv_offset * uGLSLTurbulenceAdvectionInfluence;
    
    float4 advectedState = tex2D(SamplerFlameState_A, finalAdvectLookup);
    newTemp = advectedState.r;
    newVel  = advectedState.gb;

    // 2. Repulsion, Buoyancy, and Draft
    float2 repulsionDir = float2(0.0, 0.0);
    if (length(texcoord - uFireRepulsionCenterPos) > 0.0001) {
        repulsionDir = normalize(texcoord - uFireRepulsionCenterPos); 
    }
    newVel += repulsionDir * uRepulsionStrength;
    newVel.y -= uGeneralBuoyancy; 
    newVel.y -= uDraftSpeed;      

    // 3. Diffusion
    if (uDiffusion > 0.00001)
    {
        float tempSum = 0;
        [loop] for (int y = -1; y <= 1; ++y) {
            [loop] for (int x = -1; x <= 1; ++x) {
                tempSum += tex2D(SamplerFlameState_A, texcoord + float2(x, y) * uDiffusion).r;
            }
        }
        newTemp = lerp(newTemp, tempSum / 9.0, 0.5); 
    }

    // 4. Dissipation & Damping
    newTemp *= (1.0 - uDissipation);
    newVel  *= (1.0 - uVelocityDamping);
    newTemp = max(0.0, newTemp); 

    // 5. Source Injection
    float linearDepth = ReShade::GetLinearizedDepth(texcoord);
    float subjectMask = (linearDepth < uSubjectDepthCutoff) ? 1.0 : 0.0;
    float depth_l = ReShade::GetLinearizedDepth(texcoord - float2(pixelSize.x, 0.0));
    float depth_r = ReShade::GetLinearizedDepth(texcoord + float2(pixelSize.x, 0.0));
    float depth_u = ReShade::GetLinearizedDepth(texcoord - float2(0.0, pixelSize.y));
    float depth_d = ReShade::GetLinearizedDepth(texcoord + float2(0.0, pixelSize.y));
    float sobel_x = -depth_l + depth_r;
    float sobel_y = -depth_u + depth_d; 
    float edgeFactorRaw = length(float2(sobel_x, sobel_y)) * uEdgeDetectionSensitivity;
    float edgeFactor = smoothstep(0.5 - uEdgeSoftness, 0.5 + uEdgeSoftness, edgeFactorRaw) * subjectMask;

    if (edgeFactor > 0.1) {
        newTemp += uSourceInjectionStrength * edgeFactor; 
        newVel += repulsionDir * uSourceInjectionStrength * edgeFactor * 0.1; 
    }
    
    newTemp = saturate(newTemp); 

    return float4(newTemp, newVel, 1.0); 
}

//------------------------------------------------------------------------------------------------
// Pixel Shader: Copy State Buffer
//------------------------------------------------------------------------------------------------
float4 CopyStatePS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    return tex2D(SamplerFlameState_B, texcoord); 
}


//------------------------------------------------------------------------------------------------
// Pixel Shader: Render Flame Buffer to Screen
//------------------------------------------------------------------------------------------------
float4 RenderFlamePS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 baseSceneColor = tex2D(ReShade::BackBuffer, texcoord).rgb; // Original scene
    float4 flameState = tex2D(SamplerFlameState_A, texcoord); 

    float temp = flameState.r; 
    float3 flameVisualColor = float3(0,0,0);
    if (temp > 0.01) {
        float3 colorLerp1 = lerp(uFlameColorOuter, uFlameColorMid, saturate((temp - uFlameColorThresholdMid*0.5) / (uFlameColorThresholdMid*0.5 + 0.001) ));
        flameVisualColor = lerp(colorLerp1, uFlameColorCore, saturate((temp - uFlameColorThresholdMid) / (uFlameColorThresholdCore - uFlameColorThresholdMid + 0.001)));
    }
    
    float flameAlpha = saturate(temp * uFlameIntensity); 
    float3 premultipliedFlame = flameVisualColor * flameAlpha; 
    
    // Blend flame onto the scene
    float3 colorWithFlame = premultipliedFlame + baseSceneColor * (1.0 - flameAlpha); 
    
    // --- Subject Overlay ---
    float linearDepth = ReShade::GetLinearizedDepth(texcoord); 
    float subjectMask = (linearDepth < uSubjectDepthCutoff) ? 1.0 : 0.0;
    
    float3 finalOutputColor = colorWithFlame;
    if (bOverlaySubject) {
        finalOutputColor = lerp(colorWithFlame, baseSceneColor, subjectMask);
    }
    
    // --- Debug Views ---
    // Note: Debug views will show state *before* subject overlay for clarity of effect stages
    float2 pixelSize_dbg = ReShade::PixelSize; 
    float depth_l_dbg = ReShade::GetLinearizedDepth(texcoord - float2(pixelSize_dbg.x, 0.0)); 
    float depth_r_dbg = ReShade::GetLinearizedDepth(texcoord + float2(pixelSize_dbg.x, 0.0));
    float depth_u_dbg = ReShade::GetLinearizedDepth(texcoord - float2(0.0, pixelSize_dbg.y));
    float depth_d_dbg = ReShade::GetLinearizedDepth(texcoord + float2(0.0, pixelSize_dbg.y));
    float sobel_x_dbg = -depth_l_dbg + depth_r_dbg;
    float sobel_y_dbg = -depth_u_dbg + depth_d_dbg; 
    float edgeFactorRaw_dbg = length(float2(sobel_x_dbg, sobel_y_dbg)) * uEdgeDetectionSensitivity;


    if (DebugMode > 0) {
        if (DebugMode == 1) return float4(subjectMask.xxx, 1.0);       
        if (DebugMode == 2) return float4(saturate(edgeFactorRaw_dbg).xxx, 1.0); 
        if (DebugMode == 3) return float4(temp.xxx, 1.0); 
        if (DebugMode == 4) return float4(flameState.g * 0.5 + 0.5, flameState.b * 0.5 + 0.5, 0.0, 1.0); 
        if (DebugMode == 5) { 
            float2 turb_disp = GetGLSLTurbulenceDisplacement(texcoord, Timer / 1000.0);
            return float4(turb_disp.x * 5.0 + 0.5, turb_disp.y * 5.0 + 0.5, 0.0, 1.0);
        }
    }
    
    return float4(finalOutputColor, 1.0);
}

//------------------------------------------------------------------------------------------------
// Technique Definition
//------------------------------------------------------------------------------------------------
technique AS_VFX_RadiatingFire_Buffered < ui_label = "[AS] VFX: Radiating Fire (Buffered)"; ui_enabled = true; >
{
    pass UpdateStatePass 
    {
        VertexShader = PostProcessVS;
        PixelShader = UpdateFlameStatePS;
        RenderTarget = FlameStateBuffer_B; 
        ClearRenderTargets = true; 
    }
    pass CopyStateToPersistentPass 
    {
        VertexShader = PostProcessVS;
        PixelShader = CopyStatePS;
        RenderTarget = FlameStateBuffer_A; 
        ClearRenderTargets = false; 
    }
    pass RenderFlameToScreenPass 
    {
        VertexShader = PostProcessVS;
        PixelShader = RenderFlamePS;
    }
}

} // end namespace ASRadiatingFire_Buffer

#endif // __AS_VFX_RadiantFire_1_fx__ // Updated guard
