/**
 * AS_VFX_RadiantFire.1.fx - Reactive fire simulation that radiates from subject edges
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * A GPU-based fire simulation that generates flames radiating from subject edges.
 * Uses edge detection on the depth buffer to identify subjects and simulate fire
 * that reacts to the scene's composition with realistic fluid dynamics.
 *
 * FEATURES:
 * - Edge-based fire simulation that radiates from subject contours
 * - Physically-inspired fluid dynamics with buoyancy, advection, and turbulence
 * - Customizable flame appearance with core, mid, and outer color controls
 * - Multiple debug visualization options for analyzing simulation components
 * - Optional subject overlay to maintain visibility of foreground elements
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Uses buffer ping-pong technique for stable fluid simulation
 * 2. Employs advection and displacement from GLSL Turbulence algorithm
 * 3. Processes depth buffer for edge detection and subject masking
 * 4. Simulates velocity fields with physical properties like buoyancy and diffusion
 * 5. Renders with multi-stage color mapping for realistic flame appearance
 * 
 * ===================================================================================
 */

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh" 

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_RadiantFire_1_fx__
#define __AS_VFX_RadiantFire_1_fx__

// ============================================================================
// TEXTURES & SAMPLERS for Flame Buffer (Ping-Pong Style)
// ============================================================================

texture FlameStateBuffer_A < ui_label = "Flame State Buffer A (Persistent)"; >
{
    Width = BUFFER_WIDTH; 
    Height = BUFFER_HEIGHT; 
    Format = RGBA16F;
};
sampler SamplerFlameState_A
{
    Texture = FlameStateBuffer_A;
    AddressU = CLAMP; 
    AddressV = CLAMP;
    MinFilter = LINEAR; 
    MagFilter = LINEAR; 
    MipFilter = NONE;
};

texture FlameStateBuffer_B < ui_label = "Flame State Buffer B (Temporary)"; >
{
    Width = BUFFER_WIDTH; 
    Height = BUFFER_HEIGHT; 
    Format = RGBA16F;
};
sampler SamplerFlameState_B
{
    Texture = FlameStateBuffer_B;
    AddressU = CLAMP; 
    AddressV = CLAMP;
    MinFilter = LINEAR; 
    MagFilter = LINEAR; 
    MipFilter = NONE;
};

// ============================================================================
// NAMESPACE
// ============================================================================
namespace ASRadiantFire {

// ============================================================================
// CONSTANTS
// ============================================================================

// We're using math constants from AS_Utils.1.fxh
// (AS_PI, AS_TWO_PI, AS_HALF_PI, AS_EPSILON, etc.)

// --- GLSL Turbulence Constants ---
static const float TURBULENCE_START_FREQ = 11.0f;
static const float TURBULENCE_MAX_FREQ = 50.0f;
static const float TURBULENCE_FREQ_MULTIPLIER = 1.2f;
static const float TURBULENCE_VEC_INCREMENT_X = 1.07f;
static const float TURBULENCE_VEC_INCREMENT_Y = 0.83f;
static const float TURBULENCE_WAVE_AMPLITUDE = 0.4f;
static const float TURBULENCE_TIME_SCALE = 6.0f;
static const float TURBULENCE_DISTORTION_THRESHOLD = 0.001f;
static const float TURBULENCE_DISTORTION_AMOUNT = 0.5f;
static const float TURBULENCE_START_Y_COMPONENT = 7.0f;

// --- Simulation Constants ---
static const float ADVECTION_PIXEL_SCALE = 20.0f;
static const float MIN_LENGTH_FOR_NORMALIZATION = 0.0001f;
static const float KERNEL_SIZE = 9.0f; // 3x3 kernel
static const float DIFFUSION_BLEND_FACTOR = 0.5f;
static const float INJECTION_THRESHOLD = 0.1f;
static const float INJECTION_VELOCITY_SCALE = 0.1f;
static const float EDGE_THRESHOLD_BASE = 0.5f;
static const float TEMP_THRESHOLD = 0.01f;
static const float NORMALIZATION_TERM = 0.001f; // Used to avoid division by zero

// --- Debug Constants ---
static const float DEBUG_VECTOR_SCALE = 5.0f;
static const float DEBUG_VECTOR_OFFSET = 0.5f;

// --- Animation & Time Constants ---
static const float MS_TO_SEC_CONVERSION = 0.001f;
static const float TIME_SCALE_NORMAL = 1.0f;
static const float TIME_SCALE_SLOW = 0.5f;
static const float TIME_SCALE_FAST = 2.0f;

// --- Default Values ---
static const float DEFAULT_SUBJECT_DEPTH_CUTOFF = 0.1f;
static const float DEFAULT_EDGE_DETECTION_SENSITIVITY = 50.0f;
static const float DEFAULT_EDGE_SOFTNESS = 0.02f;
static const bool DEFAULT_OVERLAY_SUBJECT = true;
static const float2 DEFAULT_FIRE_REPULSION_CENTER_POS = float2(0.5f, 1.0f);
static const float DEFAULT_SOURCE_INJECTION_STRENGTH = 0.5f;
static const float DEFAULT_ADVECTION_STRENGTH = 1.0f;
static const float DEFAULT_REPULSION_STRENGTH = 0.002f;
static const float DEFAULT_GENERAL_BUOYANCY = 0.0005f;
static const float DEFAULT_DRAFT_SPEED = 0.0f;
static const float DEFAULT_DIFFUSION = 0.0005f;
static const float DEFAULT_DISSIPATION = 0.01f;
static const float DEFAULT_VELOCITY_DAMPING = 0.02f;
static const float DEFAULT_GLSL_TURBULENCE_ADVECTION_INFLUENCE = 0.005f;
static const float DEFAULT_FLAME_INTENSITY = 1.5f;
static const float3 DEFAULT_FLAME_COLOR_CORE = float3(1.0f, 0.8f, 0.2f);
static const float3 DEFAULT_FLAME_COLOR_MID = float3(1.0f, 0.4f, 0.0f);
static const float3 DEFAULT_FLAME_COLOR_OUTER = float3(0.5f, 0.1f, 0.0f);
static const float DEFAULT_FLAME_COLOR_THRESHOLD_CORE = 1.0f;
static const float DEFAULT_FLAME_COLOR_THRESHOLD_MID = 0.5f;

// ============================================================================
// UNIFORMS
// ============================================================================

// Using standard AS_Utils time function instead of Timer

// --- Palette & Style ---
uniform float3 FlameColorCore < ui_type = "color"; ui_label = "Render: Core Color"; ui_category = "Palette & Style"; > = DEFAULT_FLAME_COLOR_CORE;
uniform float3 FlameColorMid < ui_type = "color"; ui_label = "Render: Mid Color"; ui_category = "Palette & Style"; > = DEFAULT_FLAME_COLOR_MID;
uniform float3 FlameColorOuter < ui_type = "color"; ui_label = "Render: Outer Color"; ui_category = "Palette & Style"; > = DEFAULT_FLAME_COLOR_OUTER;

// --- Effect-Specific Parameters ---
uniform float SubjectDepthCutoff < ui_type = "slider"; ui_label = "Subject Depth Cutoff"; ui_min = 0.001; ui_max = 1.0; ui_step = 0.001; ui_category = "Effect-Specific Parameters"; > = DEFAULT_SUBJECT_DEPTH_CUTOFF;
uniform float EdgeDetectionSensitivity < ui_type = "slider"; ui_label = "Edge Sensitivity"; ui_min = 1.0; ui_max = 200.0; ui_step = 1.0; ui_category = "Effect-Specific Parameters"; > = DEFAULT_EDGE_DETECTION_SENSITIVITY;
uniform float EdgeSoftness < ui_type = "slider"; ui_label = "Edge Softness"; ui_min = 0.001; ui_max = 0.5; ui_step = 0.001; ui_category = "Effect-Specific Parameters"; > = DEFAULT_EDGE_SOFTNESS;
uniform bool OverlaySubject < ui_type = "bool"; ui_label = "Overlay Subject on Fire"; ui_tooltip = "If checked, the original subject (defined by depth cutoff) will be drawn on top of the fire effect."; ui_category = "Effect-Specific Parameters"; > = DEFAULT_OVERLAY_SUBJECT;
uniform float SourceInjectionStrength < ui_type = "slider"; ui_label = "Source: Injection Strength"; ui_tooltip = "Amount of \'heat\' injected at subject edges."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Effect-Specific Parameters"; > = DEFAULT_SOURCE_INJECTION_STRENGTH;
uniform float AdvectionStrength < ui_type = "slider"; ui_label = "Advection: Velocity Influence"; ui_tooltip = "How strongly flames move based on their existing velocity."; ui_min = 0.0; ui_max = 5.0; ui_step = 0.01; ui_category = "Effect-Specific Parameters"; > = DEFAULT_ADVECTION_STRENGTH;
uniform float RepulsionStrength < ui_type = "slider"; ui_label = "Physics: Repulsion Strength"; ui_tooltip = "How strongly flames are pushed from the repulsion center."; ui_min = 0.0; ui_max = 0.01; ui_step = 0.0001; ui_category = "Effect-Specific Parameters"; > = DEFAULT_REPULSION_STRENGTH;
uniform float GeneralBuoyancy < ui_type = "slider"; ui_label = "Physics: General Buoyancy"; ui_tooltip = "Constant upwards drift for all flames (screen space)."; ui_min = 0.0; ui_max = 0.005; ui_step = 0.00001; ui_category = "Effect-Specific Parameters"; > = DEFAULT_GENERAL_BUOYANCY;
uniform float DraftSpeed < ui_type = "slider"; ui_label = "Physics: Draft Speed"; ui_tooltip = "Constant vertical draft. Positive = up, Negative = down."; ui_min = -0.005; ui_max = 0.005; ui_step = 0.00001; ui_category = "Effect-Specific Parameters"; > = DEFAULT_DRAFT_SPEED;
uniform float Diffusion < ui_type = "slider"; ui_label = "Physics: Diffusion (Spread/Blur)"; ui_tooltip = "How much the flame spreads/blurs out. Uses UV offset."; ui_min = 0.0; ui_max = 0.005; ui_step = 0.0001; ui_category = "Effect-Specific Parameters"; > = DEFAULT_DIFFUSION;
uniform float Dissipation < ui_type = "slider"; ui_label = "Physics: Dissipation (Cooling/Fade)"; ui_tooltip = "Rate at which flame intensity fades over time (0=no fade, 1=instant fade)."; ui_min = 0.0; ui_max = 0.1; ui_step = 0.001; ui_category = "Effect-Specific Parameters"; > = DEFAULT_DISSIPATION;
uniform float VelocityDamping < ui_type = "slider"; ui_label = "Physics: Velocity Damping"; ui_tooltip = "How quickly flame velocity fades (0=no damping, 1=instant stop)."; ui_min = 0.0; ui_max = 0.1; ui_step = 0.001; ui_category = "Effect-Specific Parameters"; > = DEFAULT_VELOCITY_DAMPING;
uniform float GLSLTurbulenceAdvectionInfluence < ui_type = "slider"; ui_label = "GLSL Turbulence: Advection Influence"; ui_tooltip = "Scales the displacement applied to advection lookups by the GLSL turbulence pattern."; ui_min = 0.0; ui_max = 0.1; ui_step = 0.001; ui_category = "Effect-Specific Parameters"; > = DEFAULT_GLSL_TURBULENCE_ADVECTION_INFLUENCE;
uniform float FlameIntensity < ui_type = "slider"; ui_label = "Render: Flame Intensity"; ui_min = 0.0; ui_max = 10.0; ui_step = 0.01; ui_category = "Effect-Specific Parameters"; > = DEFAULT_FLAME_INTENSITY;
uniform float FlameColorThresholdCore < ui_type = "slider"; ui_label = "Render: Core Temp Threshold"; ui_min = 0.5; ui_max = 2.0; ui_step = 0.01; ui_category = "Effect-Specific Parameters"; > = DEFAULT_FLAME_COLOR_THRESHOLD_CORE;
uniform float FlameColorThresholdMid < ui_type = "slider"; ui_label = "Render: Mid Temp Threshold"; ui_min = 0.1; ui_max = 1.0; ui_step = 0.01; ui_category = "Effect-Specific Parameters"; > = DEFAULT_FLAME_COLOR_THRESHOLD_MID;

// --- Animation Controls ---
uniform float AnimationSpeed < ui_type = "slider"; ui_label = "Animation Speed"; ui_tooltip = "Controls the overall speed of the fire animation."; ui_min = 0.1f; ui_max = 3.0f; ui_step = 0.05f; ui_category = "Animation Controls"; > = TIME_SCALE_NORMAL;

// --- Stage/Position Controls ---
uniform float2 FireRepulsionCenterPos < ui_type = "drag"; ui_label = "Fire Repulsion Center (Screen XY)"; ui_tooltip = "Normalized screen position (0-1) the fire radiates AWAY from."; ui_min = 0.0; ui_max = 1.0; ui_speed = 0.01; ui_category = "Stage/Position Controls"; > = DEFAULT_FIRE_REPULSION_CENTER_POS;

// --- Final Mix (Blend) ---
AS_BLENDMODE_UI_DEFAULT(OutputBlendMode, AS_BLEND_ADDITIVE)
AS_BLENDAMOUNT_UI(OutputBlendAmount)

// --- Debug Controls ---
AS_DEBUG_MODE_UI("Off\\0Subject Mask\\0Edge Factor\\0Flame Buffer Temp (R)\\0Flame Buffer Vel (GB)\\0Turbulence Displacement (RG)\\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Gets time in seconds with applied animation speed
float GetTimeWithSpeed()
{
    // Use AnimationSpeed as a time multiplier for full animation control
    float baseTime = AS_getTime();
    return baseTime * AnimationSpeed;
}

// --- Animation Helper Functions ---
// These functions help maintain consistent animation across different frame rates and systems
float GetAnimatedValue(float freq, float phase)
{
    // Gets a normalized animated value (0-1) based on time, frequency and phase
    return 0.5f + 0.5f * sin(GetTimeWithSpeed() * freq + phase);
}

float GetAnimatedValueBipolar(float freq, float phase)
{
    // Gets a bipolar animated value (-1 to 1) based on time, frequency and phase
    return sin(GetTimeWithSpeed() * freq + phase);
}

// --- GLSL Fire Turbulence Coordinate Displacement ---
float2 GetGLSLTurbulenceDisplacement(float2 screen_uv, float time_sec)
{
    float2 r_screensize = ReShade::ScreenSize.xy;
    float2 p_centered_ndc = screen_uv * 2.0f - 1.0f; 
    p_centered_ndc.y *= -1.0f; 
    float2 p_initial = p_centered_ndc * float2(r_screensize.x / r_screensize.y, 1.0f); 
      float2 p_distorted = p_initial;
    if (abs(p_initial.y) > TURBULENCE_DISTORTION_THRESHOLD) {
         p_distorted *= 1.0f - TURBULENCE_DISTORTION_AMOUNT / float2(1.0f / p_initial.y, 1.0f + dot(p_initial, p_initial)); 
    }
    
    float2 p_scrolled = p_distorted;
    p_scrolled.y -= time_sec; // Animation speed already applied in GetTimeWithSpeed()

    float2 p_loop = p_scrolled;
    float f_freq = TURBULENCE_START_FREQ;
    float2 r_vec = float2(f_freq, TURBULENCE_START_Y_COMPONENT); 

    [loop]
    for ( ; f_freq < TURBULENCE_MAX_FREQ; f_freq *= TURBULENCE_FREQ_MULTIPLIER )
    {
        r_vec.x += TURBULENCE_VEC_INCREMENT_X; 
        r_vec.y += TURBULENCE_VEC_INCREMENT_Y;
        float2 sin_r = sin(r_vec);
        float2 cos_r = cos(r_vec);
        p_loop += TURBULENCE_WAVE_AMPLITUDE * sin(f_freq * dot(p_loop, sin_r) + TURBULENCE_TIME_SCALE * time_sec) * cos_r / f_freq;
    }
    
    float2 displacement_in_p_space = p_loop - p_scrolled;
    float2 displacement_uv = displacement_in_p_space;
    displacement_uv.x /= (r_screensize.x / r_screensize.y);
    displacement_uv.y *= -1.0f; 

    return displacement_uv;
}

// ============================================================================
// PIXEL SHADERS
// ============================================================================

// --- Flame Simulation Update ---
float4 UpdateFlameStatePS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float4 prevState = tex2D(SamplerFlameState_A, texcoord);
    float prevTemp = prevState.r; 
    float2 prevVel = prevState.gb;   

    float newTemp = prevTemp;    float2 newVel = prevVel;

    float2 pixelSize = ReShade::PixelSize;
    float time_sec = GetTimeWithSpeed(); // Using our custom time function with animation speed

    float2 turbulent_uv_offset = GetGLSLTurbulenceDisplacement(texcoord, time_sec);
    
    // 1. Advection
    float2 baseAdvectLookup = texcoord - prevVel * AdvectionStrength * pixelSize * ADVECTION_PIXEL_SCALE; 
    float2 finalAdvectLookup = baseAdvectLookup + turbulent_uv_offset * GLSLTurbulenceAdvectionInfluence;
    
    float4 advectedState = tex2D(SamplerFlameState_A, finalAdvectLookup);
    newTemp = advectedState.r;
    newVel  = advectedState.gb;

    // 2. Repulsion, Buoyancy, and Draft
    float2 repulsionDir = float2(0.0f, 0.0f);
    if (length(texcoord - FireRepulsionCenterPos) > MIN_LENGTH_FOR_NORMALIZATION) {
        repulsionDir = normalize(texcoord - FireRepulsionCenterPos); 
    }
    newVel += repulsionDir * RepulsionStrength;
    newVel.y -= GeneralBuoyancy; 
    newVel.y -= DraftSpeed;      

    // 3. Diffusion
    if (Diffusion > AS_EPSILON)
    {
        float tempSum = 0.0f;
        [loop] for (int y = -1; y <= 1; ++y) {
            [loop] for (int x = -1; x <= 1; ++x) {
                tempSum += tex2D(SamplerFlameState_A, texcoord + float2(x, y) * Diffusion).r;
            }
        }
        newTemp = lerp(newTemp, tempSum / KERNEL_SIZE, DIFFUSION_BLEND_FACTOR); 
    }

    // 4. Dissipation & Damping
    newTemp *= (1.0f - Dissipation);
    newVel  *= (1.0f - VelocityDamping);
    newTemp = max(0.0f, newTemp); 

    // 5. Source Injection
    float linearDepth = ReShade::GetLinearizedDepth(texcoord);
    float subjectMask = (linearDepth < SubjectDepthCutoff) ? 1.0f : 0.0f;
    float depth_l = ReShade::GetLinearizedDepth(texcoord - float2(pixelSize.x, 0.0f));
    float depth_r = ReShade::GetLinearizedDepth(texcoord + float2(pixelSize.x, 0.0f));
    float depth_u = ReShade::GetLinearizedDepth(texcoord - float2(0.0f, pixelSize.y));
    float depth_d = ReShade::GetLinearizedDepth(texcoord + float2(0.0f, pixelSize.y));
    float sobel_x = -depth_l + depth_r;
    float sobel_y = -depth_u + depth_d; 
    float edgeFactorRaw = length(float2(sobel_x, sobel_y)) * EdgeDetectionSensitivity;
    float edgeFactor = smoothstep(EDGE_THRESHOLD_BASE - EdgeSoftness, EDGE_THRESHOLD_BASE + EdgeSoftness, edgeFactorRaw) * subjectMask;

    if (edgeFactor > INJECTION_THRESHOLD) {
        newTemp += SourceInjectionStrength * edgeFactor; 
        newVel += repulsionDir * SourceInjectionStrength * edgeFactor * INJECTION_VELOCITY_SCALE; 
    }
    
    newTemp = saturate(newTemp); 

    return float4(newTemp, newVel, 1.0f); 
}

// --- Copy State Buffer ---
float4 CopyStatePS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    return tex2D(SamplerFlameState_B, texcoord); 
}

// --- Render Flame Buffer to Screen ---
float4 RenderFlamePS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 baseSceneColor = tex2D(ReShade::BackBuffer, texcoord).rgb; // Original scene
    float4 flameState = tex2D(SamplerFlameState_A, texcoord); 

    float temp = flameState.r; 
    float3 flameVisualColor = float3(0.0f, 0.0f, 0.0f);
    if (temp > TEMP_THRESHOLD) {
        float midThresholdHalf = FlameColorThresholdMid * 0.5f;
        float3 colorLerp1 = lerp(FlameColorOuter, FlameColorMid, 
                                 saturate((temp - midThresholdHalf) / (midThresholdHalf + NORMALIZATION_TERM)));
        flameVisualColor = lerp(colorLerp1, FlameColorCore, 
                               saturate((temp - FlameColorThresholdMid) / (FlameColorThresholdCore - FlameColorThresholdMid + NORMALIZATION_TERM)));
    }
    
    float flameAlpha = saturate(temp * FlameIntensity); 
    float3 premultipliedFlame = flameVisualColor * flameAlpha; 
    
    // Blend flame onto the scene
    float3 colorWithFlame = premultipliedFlame + baseSceneColor * (1.0f - flameAlpha); 
    
    // --- Subject Overlay ---
    float linearDepth = ReShade::GetLinearizedDepth(texcoord); 
    float subjectMask = (linearDepth < SubjectDepthCutoff) ? 1.0f : 0.0f;
    
    float3 finalOutputColor = colorWithFlame;
    if (OverlaySubject) {
        finalOutputColor = lerp(colorWithFlame, baseSceneColor, subjectMask);
    }
    
    // --- Debug Views ---
    // Note: Debug views will show state *before* subject overlay for clarity of effect stages
    float2 pixelSize_dbg = ReShade::PixelSize; 
    float depth_l_dbg = ReShade::GetLinearizedDepth(texcoord - float2(pixelSize_dbg.x, 0.0f)); 
    float depth_r_dbg = ReShade::GetLinearizedDepth(texcoord + float2(pixelSize_dbg.x, 0.0f));
    float depth_u_dbg = ReShade::GetLinearizedDepth(texcoord - float2(0.0f, pixelSize_dbg.y));
    float depth_d_dbg = ReShade::GetLinearizedDepth(texcoord + float2(0.0f, pixelSize_dbg.y));
    float sobel_x_dbg = -depth_l_dbg + depth_r_dbg;
    float sobel_y_dbg = -depth_u_dbg + depth_d_dbg; 
    float edgeFactorRaw_dbg = length(float2(sobel_x_dbg, sobel_y_dbg)) * EdgeDetectionSensitivity;    if (DebugMode > 0) {
        if (DebugMode == 1) return float4(subjectMask.xxx, 1.0f);       
        if (DebugMode == 2) return float4(saturate(edgeFactorRaw_dbg).xxx, 1.0f); 
        if (DebugMode == 3) return float4(temp.xxx, 1.0f); 
        if (DebugMode == 4) return float4(flameState.g * DEBUG_VECTOR_OFFSET + DEBUG_VECTOR_OFFSET, 
                                          flameState.b * DEBUG_VECTOR_OFFSET + DEBUG_VECTOR_OFFSET, 0.0f, 1.0f); 
        if (DebugMode == 5) { 
            float2 turb_disp = GetGLSLTurbulenceDisplacement(texcoord, GetTimeWithSpeed());
            return float4(turb_disp.x * DEBUG_VECTOR_SCALE + DEBUG_VECTOR_OFFSET, 
                          turb_disp.y * DEBUG_VECTOR_SCALE + DEBUG_VECTOR_OFFSET, 0.0f, 1.0f);
        }
    }    // Apply blend mode using the standard AS_Utils blend function
    float4 finalColorWithAlpha = float4(finalOutputColor, 1.0f);
    float4 baseSceneColorWithAlpha = float4(baseSceneColor, 1.0f);
    
    // Use the AS_ApplyBlend utility for consistent blending across all shaders
    return AS_ApplyBlend(finalColorWithAlpha, baseSceneColorWithAlpha, OutputBlendMode, OutputBlendAmount);
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_VFX_RadiantFire < 
    ui_label = "[AS] VFX: Radiant Fire"; 
    ui_tooltip = "Edge-based fire simulation with fluid dynamics that radiates from subject contours.";
>
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

} // namespace ASRadiantFire

#endif // __AS_VFX_RadiantFire_1_fx__
