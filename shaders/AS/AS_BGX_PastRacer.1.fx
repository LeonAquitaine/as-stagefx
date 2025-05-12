/**
 * AS_BGX_PastRacer.1.fx - Abstract procedural raymarching with audio reactivity
 * Author: Leon Aquitaine (original GLSL by jetlab)
 * Based on: "Outline 2020 Freestyle Live code" by NuSan (2020-05-23) - https://www.shadertoy.com/view/tsBBzG
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * A ray marching shader that generates one of two selectable abstract procedural scenes.
 * Features domain repetition, custom transformations, and pseudo-random patterns.
 * Scene geometry and flare effects can be reactive to audio frequency bands.
 *
 * FEATURES:
 * - Two distinct procedural scenes with unique visual styles
 * - Audio-reactive geometry that responds to frequency bands
 * - Beat-triggered flare effects for dynamic visual impact
 * - Comprehensive camera controls for both automated and manual positioning
 * - Extensive customization options for colors, lighting, and scene details
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Uses signed distance functions and ray marching to render 3D procedural scenes
 * 2. Implements domain repetition for infinite pattern generation
 * 3. Applies audio frequency data to modulate geometry and visual effects
 * 4. Features automated and manual camera control systems
 * 5. Renders with dynamic lighting, shadows, and post-processing effects
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_PastRacer_1_fx
#define __AS_BGX_PastRacer_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For time, audio, UI utilities, and constants

namespace ASPastRacer {

// ============================================================================
// CONSTANTS
// ============================================================================

// --- Scene Constants ---
static const float AS_PI = 3.1415926535f;
static const int DEFAULT_SCENE_SELECTION = 0;
static const float DEFAULT_GLOBAL_TIME_SCALE = 1.0f;

// --- Ray Marching Constants ---
static const int DEFAULT_RAY_MARCH_STEPS = 100;
static const float DEFAULT_MAX_TRACE_DISTANCE = 300.0f;
static const float DEFAULT_HIT_EPSILON = 0.01f;
static const float DEFAULT_FIELD_OF_VIEW = 0.4f;

// --- Audio Constants ---
static const float DEFAULT_FFT_MULTIPLIER = 50.0f;
static const int DEFAULT_AUDIO_SOURCE = AS_AUDIO_BEAT;
static const float DEFAULT_AUDIO_MULTIPLIER = 1.0f;

// --- Post-Processing Constants ---
static const float DEFAULT_VIGNETTE_STRENGTH = 1.2f;
static const float DEFAULT_GAMMA = 2.2f;

// --- Color Constants ---
static const float3 DEFAULT_SCENE0_PRIMARY_COLOR = float3(0.3f, 0.4f, 1.0f);  
static const float3 DEFAULT_SCENE0_SECONDARY_COLOR = float3(1.0f, 0.4f, 0.6f);
static const float3 DEFAULT_SCENE1_PRIMARY_COLOR = float3(1.0f, 0.3f, 0.8f);
static const float3 DEFAULT_DIFFUSE_COLOR = float3(1.0f, 1.0f, 1.0f);
static const float3 DEFAULT_SKY_HORIZON_COLOR = float3(1.0f, 0.6f, 0.7f);
static const float3 DEFAULT_SKY_ZENITH_COLOR = float3(1.0f, 0.9f, 0.3f);

// --- Lighting & Effects Constants ---
static const float DEFAULT_LIGHT_INTENSITY = 10.0f;
static const float DEFAULT_SPECULAR_POWER = 10.0f;
static const float DEFAULT_SPECULAR_INTENSITY = 1.0f;
static const float DEFAULT_GLOW_INTENSITY = 1.0f;

// --- Scene-Specific Constants ---
// Scene 0
static const float DEFAULT_S0_BOX_SIZE = 1.0f;
static const float DEFAULT_S0_FLARE_SCALE = 1.0f;
static const float DEFAULT_S0_ANIM_SPEED = 1.0f;
// Scene 1
static const float DEFAULT_S1_TUNNEL_SIZE = 20.0f;
static const float DEFAULT_S1_GRID_PATTERN_INTENSITY = 12.7f;
static const float DEFAULT_S1_ANIM_SPEED = 1.0f;

// --- Camera Constants ---
static const float DEFAULT_CAMERA_SHAKE_AMOUNT = 0.3f;
static const float3 DEFAULT_LIGHT_DIRECTION = float3(-1.0f, -1.3f, -2.0f);
static const float DEFAULT_CAMERA_DISTANCE = 50.0f;
static const float2 DEFAULT_CAMERA_POSITION_XZ = float2(0.0f, 0.0f);
static const float DEFAULT_CAMERA_POSITION_Y = 0.0f;
static const bool DEFAULT_DISABLE_CAMERA_AUTOMATION = false;
static const float3 DEFAULT_LOOK_AT_POSITION = float3(0.0f, 0.0f, 0.0f);

// ============================================================================
// UNIFORMS
// ============================================================================

// --- Animation ---
uniform float GlobalTimeScale < ui_type = "drag"; ui_min = 0.0; ui_max = 3.0; ui_step = 0.01; ui_label = "Global Animation Speed"; ui_tooltip = "Multiplies the master time for all animations."; ui_category = "Animation"; > = DEFAULT_GLOBAL_TIME_SCALE;

// --- Quality & Performance ---
uniform int RayMarchSteps < ui_type = "drag"; ui_min = 10; ui_max = 200; ui_step = 1; ui_label = "Ray March Steps"; ui_tooltip = "Maximum steps for ray marching. Higher is more accurate but slower."; ui_category = "Quality & Performance"; > = DEFAULT_RAY_MARCH_STEPS;
uniform float MaxTraceDistance < ui_type = "drag"; ui_min = 50.0; ui_max = 1000.0; ui_step = 10.0; ui_label = "Max Trace Distance"; ui_tooltip = "Maximum distance a ray will travel."; ui_category = "Quality & Performance"; > = DEFAULT_MAX_TRACE_DISTANCE;
uniform float HitEpsilon < ui_type = "drag"; ui_min = 0.001; ui_max = 0.1; ui_step = 0.001; ui_label = "Hit Precision (Epsilon)"; ui_tooltip = "Threshold for considering a ray to have hit a surface."; ui_category = "Quality & Performance"; > = DEFAULT_HIT_EPSILON;

// --- Camera ---
uniform float FieldOfView < ui_type = "drag"; ui_min = 0.1; ui_max = 2.0; ui_step = 0.01; ui_label = "Field of View"; ui_tooltip = "Controls the camera's field of view. Smaller is more zoomed in (larger value for fov parameter in code)."; ui_category = "Camera"; > = DEFAULT_FIELD_OF_VIEW;
uniform float CameraShakeAmount < ui_type = "drag"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.05; ui_label = "Camera Shake"; ui_tooltip = "Amount of procedural camera shake"; ui_category = "Camera"; > = DEFAULT_CAMERA_SHAKE_AMOUNT;
uniform float3 LightDirection < ui_type = "drag"; ui_min = -1.0; ui_max = 1.0; ui_step = 0.1; ui_label = "Light Direction"; ui_tooltip = "Direction of the main light source"; ui_category = "Camera"; > = DEFAULT_LIGHT_DIRECTION;
uniform float CameraDistance < ui_type = "drag"; ui_min = 10.0; ui_max = 100.0; ui_step = 1.0; ui_label = "Camera Distance"; ui_tooltip = "Base distance of the camera from the center of the scene"; ui_category = "Camera"; > = DEFAULT_CAMERA_DISTANCE;
uniform float2 CameraPositionXZ < ui_type = "drag"; ui_min = -50.0; ui_max = 50.0; ui_step = 1.0; ui_label = "Camera Position XZ"; ui_tooltip = "Horizontal position offset of the camera"; ui_category = "Camera"; > = DEFAULT_CAMERA_POSITION_XZ;
uniform float CameraPositionY < ui_type = "drag"; ui_min = -50.0; ui_max = 50.0; ui_step = 1.0; ui_label = "Camera Height Y"; ui_tooltip = "Vertical position offset of the camera"; ui_category = "Camera"; > = DEFAULT_CAMERA_POSITION_Y;
uniform bool DisableCameraAutomation < ui_label = "Manual Camera Mode"; ui_tooltip = "When enabled, disables automatic camera movement and uses only the manual settings"; ui_category = "Camera"; > = DEFAULT_DISABLE_CAMERA_AUTOMATION;
uniform float3 LookAtPosition < ui_type = "drag"; ui_min = -50.0; ui_max = 50.0; ui_step = 1.0; ui_label = "Look At Position"; ui_tooltip = "Position the camera is looking at"; ui_category = "Camera"; > = DEFAULT_LOOK_AT_POSITION;

// --- Palette & Style ---
uniform float3 Scene0PrimaryColor < ui_type = "color"; ui_label = "Scene 0: Primary Color"; ui_tooltip = "Primary color for audio-reactive boxes in Scene 0"; ui_category = "Palette & Style"; > = DEFAULT_SCENE0_PRIMARY_COLOR;
uniform float3 Scene0SecondaryColor < ui_type = "color"; ui_label = "Scene 0: Secondary Color"; ui_tooltip = "Secondary color for flare effects in Scene 0"; ui_category = "Palette & Style"; > = DEFAULT_SCENE0_SECONDARY_COLOR;
uniform float3 Scene1PrimaryColor < ui_type = "color"; ui_label = "Scene 1: Primary Color"; ui_tooltip = "Primary color for corridor structure in Scene 1"; ui_category = "Palette & Style"; > = DEFAULT_SCENE1_PRIMARY_COLOR;
uniform float3 DiffuseColor < ui_type = "color"; ui_label = "Diffuse Light Color"; ui_tooltip = "Color of the diffuse lighting"; ui_category = "Palette & Style"; > = DEFAULT_DIFFUSE_COLOR;
uniform float3 SkyTintHorizon < ui_type = "color"; ui_label = "Sky Color (Horizon)"; ui_tooltip = "Color of the sky at the horizon"; ui_category = "Palette & Style"; > = DEFAULT_SKY_HORIZON_COLOR;
uniform float3 SkyTintZenith < ui_type = "color"; ui_label = "Sky Color (Zenith)"; ui_tooltip = "Color of the sky at its brightest point"; ui_category = "Palette & Style"; > = DEFAULT_SKY_ZENITH_COLOR;

// --- Effect-Specific Parameters (Scene 0) ---
uniform float S0BoxSize < ui_type = "drag"; ui_min = 0.1; ui_max = 5.0; ui_step = 0.1; ui_label = "Box Size (Scene 0)"; ui_tooltip = "Size of the audio-reactive boxes"; ui_category = "Effect 1: Audio Boxes"; ui_category_closed = true; > = DEFAULT_S0_BOX_SIZE;
uniform float S0FlareScale < ui_type = "drag"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.05; ui_label = "Flare Effect Scale (Scene 0)"; ui_tooltip = "Scale of the flare visual effect"; ui_category = "Effect 1: Audio Boxes"; > = DEFAULT_S0_FLARE_SCALE;
uniform float S0AnimSpeed < ui_type = "drag"; ui_min = 0.1; ui_max = 5.0; ui_step = 0.1; ui_label = "Animation Speed (Scene 0)"; ui_tooltip = "Speed multiplier for scene-specific animations"; ui_category = "Effect 1: Audio Boxes"; > = DEFAULT_S0_ANIM_SPEED;

// --- Effect-Specific Parameters (Scene 1) ---
uniform float S1TunnelSize < ui_type = "drag"; ui_min = 5.0; ui_max = 50.0; ui_step = 1.0; ui_label = "Tunnel Size (Scene 1)"; ui_tooltip = "Size of the main tunnel structure"; ui_category = "Effect 2: Corridor"; ui_category_closed = true; > = DEFAULT_S1_TUNNEL_SIZE;
uniform float S1GridPatternIntensity < ui_type = "drag"; ui_min = 0.0; ui_max = 20.0; ui_step = 0.1; ui_label = "Grid Pattern Intensity (Scene 1)"; ui_tooltip = "Intensity of the grid pattern displacement"; ui_category = "Effect 2: Corridor"; > = DEFAULT_S1_GRID_PATTERN_INTENSITY;
uniform float S1AnimSpeed < ui_type = "drag"; ui_min = 0.1; ui_max = 5.0; ui_step = 0.1; ui_label = "Animation Speed (Scene 1)"; ui_tooltip = "Speed multiplier for scene-specific animations"; ui_category = "Effect 2: Corridor"; > = DEFAULT_S1_ANIM_SPEED;

// --- Audio Reactivity ---
uniform float FFTMultiplier < ui_type = "drag"; ui_min = 0.0; ui_max = 100.0; ui_step = 1.0; ui_label = "Box Height Audio Strength"; ui_tooltip = "Multiplies the audio frequency band value, affecting Scene 0's box heights."; ui_category = "Audio Reactivity"; > = DEFAULT_FFT_MULTIPLIER;
AS_AUDIO_SOURCE_UI(S0FlareAudioSource, "Flare Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(S0FlareAudioMultiplier, "Flare Audio Intensity", AS_RANGE_AUDIO_MULT_DEFAULT, AS_RANGE_AUDIO_MULT_MAX, "Audio Reactivity")

// --- Lighting & Effects ---
uniform float LightIntensity < ui_type = "drag"; ui_min = 0.1; ui_max = 20.0; ui_step = 0.1; ui_label = "Light Intensity"; ui_tooltip = "Brightness multiplier for the main light source"; ui_category = "Lighting & Effects"; > = DEFAULT_LIGHT_INTENSITY;
uniform float SpecularPower < ui_type = "drag"; ui_min = 1.0; ui_max = 50.0; ui_step = 1.0; ui_label = "Specular Hardness"; ui_tooltip = "Controls the size of specular highlights (higher = smaller, sharper)"; ui_category = "Lighting & Effects"; > = DEFAULT_SPECULAR_POWER;
uniform float SpecularIntensity < ui_type = "drag"; ui_min = 0.0; ui_max = 5.0; ui_step = 0.1; ui_label = "Specular Intensity"; ui_tooltip = "Brightness of specular highlights"; ui_category = "Lighting & Effects"; > = DEFAULT_SPECULAR_INTENSITY;
uniform float GlowIntensity < ui_type = "drag"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.05; ui_label = "Glow Intensity"; ui_tooltip = "Intensity of the post-glow effect (bloom-like)"; ui_category = "Lighting & Effects"; > = DEFAULT_GLOW_INTENSITY;

// --- Final Mix (Blend) ---
uniform float VignetteStrength < ui_type = "drag"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_label = "Vignette Strength"; ui_tooltip = "Strength of the screen-edge darkening effect."; ui_category = "Final Mix"; > = DEFAULT_VIGNETTE_STRENGTH;
uniform float Gamma < ui_type = "drag"; ui_min = 1.0; ui_max = 3.0; ui_step = 0.01; ui_label = "Gamma Correction"; ui_tooltip = "Final gamma adjustment. Standard is often 2.2."; ui_category = "Final Mix"; > = DEFAULT_GAMMA;

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// --- Domain Manipulation ---
float RepeatCentered(float val, float period) { return (frac(val / period + 0.5f) - 0.5f) * period; }
float2 RepeatCentered2(float2 val, float2 period) { return (frac(val / period + 0.5f) - 0.5f) * period; }
float3 RepeatCentered3(float3 val, float3 period) { return (frac(val / period + 0.5f) - 0.5f) * period; }
float GetRepeatID(float val, float period) { return floor(val / period + 0.5f); }
float2 GetRepeatID2(float2 val, float2 period) { return floor(val / period + 0.5f); }

// --- Audio Analysis ---
float GetFFTValue(float2 audioUV) {
    float fftSampleCoord = (frac(audioUV.x * 10.0f) + frac(audioUV.y)) * 0.1f; 
    int numBands = AS_getNumFrequencyBands();
    if (numBands <= 0) return 0.0f * FFTMultiplier;
    float normalizedBandSelector = saturate(fftSampleCoord / 0.2f); 
    int bandIndex = (int)floor(normalizedBandSelector * (float)(numBands - 1)); 
    bandIndex = clamp(bandIndex, 0, numBands - 1); 
    float fftAmplitude = AS_getFrequencyBand(bandIndex);
    return fftAmplitude * FFTMultiplier; 
}

// --- Math Utilities ---
float2 Hash2DTo2D(float2 pHash){ return frac(sin(pHash * float2(425.522f, 847.554f) + pHash.yx * float2(847.554f, 425.522f)) * 352.742f); }
float Hash1D(float aHash) { return frac(sin(aHash * 254.574f) * 652.512f); }

float GetCurveValue(float tCurve, float dCurve, float timeValUnused, float transitionPower) { 
    tCurve /= dCurve;
    return lerp(Hash1D(floor(tCurve)), Hash1D(floor(tCurve) + 1.0f), pow(smoothstep(0.0f, 1.0f, frac(tCurve)), transitionPower));
}

float GetTickedValue(float tTick, float dTick, float transitionPower) {
    tTick /= dTick;
    return (floor(tTick) + pow(smoothstep(0.0f, 1.0f, frac(tTick)), transitionPower)) * dTick;
}

// --- Ray Marching Primitives ---
float SDF_Box(float3 pBox, float3 sBox) { pBox = abs(pBox) - sBox; return max(pBox.x, max(pBox.y, pBox.z));}

// --- Transformation Utilities ---
float2x2 GetRotationMatrix(float angleRot) {
    float ca = cos(angleRot); float sa = sin(angleRot); return float2x2(ca, -sa, sa, ca); 
}

// --- Scene-Specific Effects ---
float SDE_GridPattern(float3 pGrid, float timeVal) {
    float vGrid = 0.0f;
    pGrid *= 0.004f; 
    for(int iGrid = 0; iGrid < 3; ++iGrid) {
        float iGridF = (float)iGrid;
        pGrid *= 1.7f; 
        pGrid.xz = mul(pGrid.xz, GetRotationMatrix(0.3f + iGridF)); 
        pGrid.xy = mul(pGrid.xy, GetRotationMatrix(0.4f + iGridF * 1.3f)); 
        pGrid += float3(0.1f, 0.3f, -0.13f) * (iGridF + 1.0f); 
        float3 gComp = abs(frac(pGrid) - 0.5f) * 2.0f;
        vGrid -= min(gComp.x, min(gComp.y, gComp.z)) * 0.7f;
    }
    return vGrid;
}

// --- Scene Description Functions ---
float SDE_DescribeWorld_Scene0(float3 pWorld, float timeVal, inout float accAt, inout float accAt2)
{
    float dWorld = 1e10; 
    
    // Apply scene-specific animation speed
    float animatedTime = timeVal * S0AnimSpeed;
    
    pWorld.xz = mul(pWorld.xz, GetRotationMatrix(sin(-length(pWorld.xz) * 0.07f + animatedTime * 1.0f) * 1.0f));
    pWorld.y += pow(smoothstep(0.0f, 1.0f, sin(-pow(length(pWorld.xz), 2.0f) * 0.001f + animatedTime * 4.0f)), 3.0f) * 4.0f;
    dWorld = -pWorld.y; 
    for(int iMap0 = 0; iMap0 < 4; ++iMap0) {
        float iMap0F = (float)iMap0;
        float3 p2Map0 = pWorld;
        p2Map0.xz = mul(p2Map0.xz, GetRotationMatrix(iMap0F + 0.7f));
        p2Map0.xz -= 7.0f; 
        float2 repIdVec = GetRepeatID2(p2Map0.xz, float2(10.0f, 10.0f));
        float2 rndForFft = Hash2DTo2D(repIdVec); 
        float fftVal = GetFFTValue(rndForFft); 
        p2Map0.xz = RepeatCentered2(p2Map0.xz, float2(10.0f, 10.0f));
        
        // Apply box size uniform to the audio-reactive boxes
        dWorld = min(dWorld, SDF_Box(p2Map0, float3(S0BoxSize, 0.3f * fftVal, S0BoxSize)));
    }
    float3 p3Map0 = pWorld; float t3Map0 = animatedTime * 0.13f;
    p3Map0.xz = mul(p3Map0.xz, GetRotationMatrix(t3Map0));
    p3Map0.xy = mul(p3Map0.xy, GetRotationMatrix(t3Map0 * 1.3f));
    p3Map0 = RepeatCentered3(p3Map0, float3(5.0f, 5.0f, 5.0f));
    float d2Map0 = SDF_Box(p3Map0, float3(1.7f, 1.7f, 1.7f)); 
    dWorld = min(dWorld, dWorld - d2Map0 * 0.1f);
    float3 p4Map0 = pWorld; float t4Map0Rot = animatedTime * 1.33f;
    p4Map0.xz = RepeatCentered2(p4Map0.xz, float2(200.0f, 200.0f));
    p4Map0.yz = mul(p4Map0.yz, GetRotationMatrix(t4Map0Rot));
    p4Map0.xz = mul(p4Map0.xz, GetRotationMatrix(t4Map0Rot * 1.3f));
    
    // Apply flare scale to the first flare accumulator
    accAt += 0.04f * S0FlareScale / (1.2f + abs(length(p4Map0.xz) - 17.0f));
    
    float3 p5Map0 = pWorld; float t5Map0 = animatedTime * 1.23f;
    p5Map0.xz = RepeatCentered2(p5Map0.xz, float2(200.0f, 200.0f));
    p5Map0.yz = mul(p5Map0.yz, GetRotationMatrix(t5Map0 * 0.7f));
    p5Map0.xy = mul(p5Map0.xy, GetRotationMatrix(t5Map0));
    
    // Apply flare scale to the second flare accumulator
    accAt2 += 0.04f * S0FlareScale / (1.2f + abs(SDF_Box(p5Map0, float3(37.0f, 37.0f, 37.0f))));
    return dWorld * 0.7f;
}

float SDE_DescribeWorld_Scene1(float3 pWorld, float timeVal, inout float accAt, inout float accAt2)
{
    float dWorld = 1e10;
    // Apply scene-specific animation speed
    float animatedTime = timeVal * S1AnimSpeed;
    
    float ppyMap1 = pWorld.y;
    pWorld.y = RepeatCentered(pWorld.y, 300.0f);
    pWorld.xz = mul(pWorld.xz, GetRotationMatrix(sin(-length(pWorld.xz) * 0.0007f + animatedTime * 0.5f + ppyMap1 * 0.005f) * 1.0f));
    float3 p4Map1 = pWorld;
    
    // Apply tunnel size uniform
    dWorld = SDF_Box(p4Map1, float3(S1TunnelSize, S1TunnelSize, S1TunnelSize));
    float ssMap1 = S1TunnelSize * 0.5f; // Halving the size makes the tunnels more proportional
    dWorld = max(dWorld, -SDF_Box(p4Map1, float3(ssMap1, ssMap1, 100.0f)));
    dWorld = max(dWorld, -SDF_Box(p4Map1, float3(ssMap1, 100.0f, ssMap1)));
    dWorld = max(dWorld, -SDF_Box(p4Map1, float3(100.0f, ssMap1, ssMap1)));
    float3 p3Map1 = pWorld;
    p3Map1.xz = mul(p3Map1.xz, GetRotationMatrix(sin(animatedTime * 3.0f + pWorld.y * 0.01f) * 0.3f));
    p3Map1.xz = abs(p3Map1.xz) - 30.0f;
    p3Map1.xz = abs(p3Map1.xz) - 10.0f * (sin(animatedTime + pWorld.y * 0.05f) * 0.5f + 0.5f);
    dWorld = min(dWorld, length(p3Map1.xz) - 5.0f);
    float gMap1 = SDE_GridPattern(pWorld, animatedTime);
    
    // Apply grid pattern intensity uniform
    float d2Map1 = dWorld - 5.0f - gMap1 * S1GridPatternIntensity; 
    dWorld = min(dWorld + 4.3f, d2Map1); 
    
    float3 p6Map1 = pWorld; float t6Map1 = animatedTime * 1.33f;
    p6Map1.xz = RepeatCentered2(p6Map1.xz, float2(40.0f, 40.0f));
    p6Map1.yz = mul(p6Map1.yz, GetRotationMatrix(t6Map1));
    p6Map1.xz = mul(p6Map1.xz, GetRotationMatrix(t6Map1 * 1.3f));
    accAt += 0.04f / (1.2f + abs(length(p6Map1.xz) - 17.0f));
    float3 p5Map1 = pWorld; float t5Map1 = animatedTime * 1.23f;
    p5Map1.yz = mul(p5Map1.yz, GetRotationMatrix(t5Map1 * 0.7f));
    p5Map1.xy = mul(p5Map1.xy, GetRotationMatrix(t5Map1));
    accAt2 += 0.04f / (0.7f + abs(SDF_Box(p5Map1, float3(37.0f, 37.0f, 37.0f))));
    float3 p7Map1 = pWorld; float t3Map1 = animatedTime * 0.13f;
    p7Map1.xz = mul(p7Map1.xz, GetRotationMatrix(t3Map1));
    p7Map1.xy = mul(p7Map1.xy, GetRotationMatrix(t3Map1 * 1.3f));
    p7Map1 = RepeatCentered3(p7Map1, float3(5.0f, 5.0f, 5.0f));
    float d7Map1 = SDF_Box(p7Map1, float3(1.7f, 1.7f, 1.7f)); 
    dWorld = min(dWorld, dWorld * 0.7f - d7Map1 * 0.7f); 
    return dWorld * 0.7f;
}

// ============================================================================
// PIXEL SHADERS
// ============================================================================

// --- Common ray marching function ---
float4 PS_PastRacer_Common(float4 vpos, float2 texcoord, bool isScene0)
{
    // Time calculation
    float masterTime = AS_getTime() * GlobalTimeScale;
    float currentTime = AS_mod(masterTime, 300.0f); 
      // UV Setup - applying resolution-independent aspect ratio correction
    float2 uv = texcoord - 0.5f; 
    uv.x *= ReShade::AspectRatio; 
    uv.y *= -1.0f;
    
    // Calculate a resolution scale factor to ensure consistent sizing across different resolutions
    float resolutionScale = (float)BUFFER_HEIGHT / 1080.0;
    
    // Accumulators for flare effects
    float atAccumulator = 0.0f;
    float at2Accumulator = 0.0f;
    
    // Initialize base camera position with user-defined distance
    float3 initialRayOrigin = float3(CameraPositionXZ.x, CameraPositionY, -CameraDistance);
    
    // Apply automatic camera movement if not disabled
    if (!DisableCameraAutomation) {
        initialRayOrigin.xz += (GetCurveValue(currentTime, 1.6f, currentTime, 10.0f) - 0.5f) * 30.0f;
    }
    
    float3 lookAtTarget = LookAtPosition;
    
    // --- Calculate lightingPart and flareIntensityMod based on audio ---
    float baseLightingPart = smoothstep(-0.1f, 0.1f, sin(currentTime));
    float actualLightingPart = baseLightingPart;
    float flareIntensityMod = 1.0f;

    if (isScene0)
    {
        if (S0FlareAudioSource == AS_AUDIO_BEAT)
        {
            float beatLevel = AS_getAudioSource(AS_AUDIO_BEAT); // This is a pulse [0,1] that decays
            actualLightingPart = beatLevel; // Flare "mood" (at/at2 dominance) pulses with the beat
            flareIntensityMod = S0FlareAudioMultiplier; // Control brightness of the beat-triggered flare
        }
        else if (S0FlareAudioSource != AS_AUDIO_OFF) // Other audio sources (Volume, Bands, Solid)
        {
            // actualLightingPart remains baseLightingPart (slow sine wave for mood timing)
            float audioLevel = AS_getAudioSource(S0FlareAudioSource);
            flareIntensityMod = audioLevel * S0FlareAudioMultiplier; // Flare intensity continuously modulated
        }
        // If S0FlareAudioSource is AS_AUDIO_OFF, actualLightingPart is baseLightingPart, 
        // and flareIntensityMod is 1.0f (original non-audio behavior for flare intensity).
    }    // If not Scene 0, actualLightingPart and flareIntensityMod keep their default:
    // baseLightingPart and 1.0f respectively.
    
    // Apply automatic camera rotation and shake if enabled
    float camAdv = currentTime * 0.1f; 
    if (!DisableCameraAutomation) {
        // Apply camera shake scaled by the user's setting
        initialRayOrigin.yz = mul(initialRayOrigin.yz, GetRotationMatrix(sin(camAdv * 0.3f) * CameraShakeAmount + 0.5f));
        initialRayOrigin.xz = mul(initialRayOrigin.xz, GetRotationMatrix(camAdv));
    }
 
    // Scene-specific camera adjustments
    if (!isScene0) {  // SCENE 1
        // For Scene 1, apply initial offsets if in automatic mode
        if (!DisableCameraAutomation) {
            initialRayOrigin.y -= 100.0f;
            initialRayOrigin.x += 100.0f;
            float pushOffset = GetTickedValue(currentTime, 0.5f, 10.0f) * 100.0f; 
            initialRayOrigin.y += pushOffset;
            lookAtTarget.y += pushOffset;
        } else {
            // In manual mode, keep the lookAtTarget slightly ahead of camera
            lookAtTarget.y = initialRayOrigin.y;
            lookAtTarget.z = initialRayOrigin.z + 50.0f;
        }
    }
    
    // Camera setup
    float3 camDirZ = normalize(lookAtTarget - initialRayOrigin);
    float3 camDirX = normalize(cross(float3(0.0f, 1.0f, 0.0f), camDirZ)); 
    float3 camDirY = normalize(cross(camDirX, camDirZ));
    float3 rayDirection = normalize(uv.x * camDirX + uv.y * camDirY + FieldOfView * camDirZ);
    
    // Ray marching setup
    float3 accumulatedColor = float3(0.0f, 0.0f, 0.0f); // This will be the base for the flare mood
    float3 currentRayPos = initialRayOrigin;

    // Ray marching loop
    for(int k = 0; k < RayMarchSteps; ++k) {
        float distToScene;
        if (isScene0) {
            distToScene = abs(SDE_DescribeWorld_Scene0(currentRayPos, currentTime, atAccumulator, at2Accumulator));
        } else {
            distToScene = abs(SDE_DescribeWorld_Scene1(currentRayPos, currentTime, atAccumulator, at2Accumulator));
        }
        
        if(distToScene < HitEpsilon) { break; }
        if(distToScene > MaxTraceDistance) break; 
        currentRayPos += rayDirection * distToScene;
    }
    
    // Flare effect calculation
    float atCurveVal = 1.0f + GetCurveValue(currentTime, 0.3f, currentTime, 10.0f);
    float at2CurveVal = 1.0f + GetCurveValue(currentTime, 0.4f, currentTime, 10.0f);

    float3 flareComponentColor = 0.0f;
    flareComponentColor += atAccumulator  * Scene0PrimaryColor * atCurveVal;
    flareComponentColor += at2Accumulator * Scene0SecondaryColor * at2CurveVal;
    
    flareComponentColor *= flareIntensityMod; // Apply audio/static intensity mod
    
    // This 'accumulatedColor' will primarily be the flare component, mixed by actualLightingPart
    accumulatedColor = flareComponentColor * actualLightingPart; 
    
    // --- Calculate lighting_color2 (the "other" lighting mood) ---
    float fogDist = length(currentRayPos - initialRayOrigin);
    float fogFactor = 1.0f - clamp(fogDist / MaxTraceDistance, 0.0f, 1.0f);
    float2 normOff = float2(0.01f, 0.0f); 
    float atNormDummy = 0.0f, at2NormDummy = 0.0f; 
    float mapP, mapPx, mapPy, mapPz;
    
    if (isScene0) {
        mapP  = SDE_DescribeWorld_Scene0(currentRayPos, currentTime, atNormDummy, at2NormDummy); atNormDummy=0.0f; at2NormDummy=0.0f;
        mapPx = SDE_DescribeWorld_Scene0(currentRayPos - normOff.xyy, currentTime, atNormDummy, at2NormDummy); atNormDummy=0.0f; at2NormDummy=0.0f;
        mapPy = SDE_DescribeWorld_Scene0(currentRayPos - normOff.yxy, currentTime, atNormDummy, at2NormDummy); atNormDummy=0.0f; at2NormDummy=0.0f;
        mapPz = SDE_DescribeWorld_Scene0(currentRayPos - normOff.yyx, currentTime, atNormDummy, at2NormDummy);
    } else {
        mapP  = SDE_DescribeWorld_Scene1(currentRayPos, currentTime, atNormDummy, at2NormDummy); atNormDummy=0.0f; at2NormDummy=0.0f;
        mapPx = SDE_DescribeWorld_Scene1(currentRayPos - normOff.xyy, currentTime, atNormDummy, at2NormDummy); atNormDummy=0.0f; at2NormDummy=0.0f;
        mapPy = SDE_DescribeWorld_Scene1(currentRayPos - normOff.yxy, currentTime, atNormDummy, at2NormDummy); atNormDummy=0.0f; at2NormDummy=0.0f;
        mapPz = SDE_DescribeWorld_Scene1(currentRayPos - normOff.yyx, currentTime, atNormDummy, at2NormDummy);
    }
    
    float3 surfaceNormal = normalize(float3(mapP - mapPx, mapP - mapPy, mapP - mapPz) / normOff.x); 
    float3 lightDirection = normalize(LightDirection);
    float3 halfwayVector = normalize(lightDirection - rayDirection);
    
    // Shadow calculation
    float softShadowOcclusion = 0.0f;
    for(int sIdx = 1; sIdx < 20; ++sIdx) { 
        float sIdxF = (float)sIdx; float shadowRayDist = sIdxF * 5.2f; 
        atNormDummy=0.0f; at2NormDummy=0.0f;
        
        if (isScene0) {
            softShadowOcclusion += smoothstep(0.0f, 1.0f, SDE_DescribeWorld_Scene0(currentRayPos + lightDirection * shadowRayDist + surfaceNormal * 0.01f, currentTime, atNormDummy, at2NormDummy) / shadowRayDist); 
        } else {
            softShadowOcclusion += smoothstep(0.0f, 1.0f, SDE_DescribeWorld_Scene1(currentRayPos + lightDirection * shadowRayDist + surfaceNormal * 0.01f, currentTime, atNormDummy, at2NormDummy) / shadowRayDist); 
        }
    }
    if (19 > 0) softShadowOcclusion /= 19.0f; 
    
    // Secondary lighting calculation (non-flare components)
    float3 lightingColor2 = float3(0.0f, 0.0f, 0.0f);
    lightingColor2 += softShadowOcclusion * Scene1PrimaryColor * 0.15f * fogFactor;
    atNormDummy=0.0f; at2NormDummy=0.0f;
    float aoFactor;
    
    if (isScene0) {
        aoFactor = smoothstep(0.0f, 1.0f, SDE_DescribeWorld_Scene0(currentRayPos + surfaceNormal * 0.1f, currentTime, atNormDummy, at2NormDummy)); 
    } else {
        aoFactor = smoothstep(0.0f, 1.0f, SDE_DescribeWorld_Scene1(currentRayPos + surfaceNormal * 0.1f, currentTime, atNormDummy, at2NormDummy)); 
    }
    
    float3 skyColor = lerp(SkyTintHorizon * 0.1f, SkyTintZenith * LightIntensity, pow(max(0.0f, dot(rayDirection, lightDirection)), 20.0f));
    float diffuseTerm = max(0.0f, dot(surfaceNormal, lightDirection));
    float specularTerm = pow(max(0.0f, dot(halfwayVector, surfaceNormal)), SpecularPower); 
    lightingColor2 += diffuseTerm * (DiffuseColor + specularTerm * SpecularIntensity) * fogFactor * aoFactor; 
    lightingColor2 += pow(1.0f - fogFactor, 2.0f) * skyColor;
    
    // Mix lighting components
    accumulatedColor += lightingColor2 * (1.0f - actualLightingPart); // Mix in the "other" lighting based on the part not taken by flare mood
    
    // Apply post-processing
    // Vignette
    accumulatedColor *= (VignetteStrength - length(uv));
    
    // Glow
    accumulatedColor += max(accumulatedColor.yzx - 1.0f, 0.0f) * GlowIntensity;
    accumulatedColor += max(accumulatedColor.zxy - 1.0f, 0.0f) * GlowIntensity;    // Final tone mapping and gamma correction
    accumulatedColor = smoothstep(0.0f, 1.0f, accumulatedColor); 
    accumulatedColor = pow(accumulatedColor, 1.0f / Gamma); 
        
    return float4(accumulatedColor, 1.0f);
}

// --- Scene 0: Audio Boxes ---
float4 PS_PastRacer_Scene0(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    return PS_PastRacer_Common(vpos, texcoord, true);
}

// --- Scene 1: Corridor Structure ---
float4 PS_PastRacer_Scene1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    return PS_PastRacer_Common(vpos, texcoord, false);
}

} // namespace ASPastRacer

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_BGX_PastRacer_AudioBoxes < 
    ui_label = "[AS] BGX: Past Racer (Audio Boxes)"; 
    ui_tooltip = "Abstract procedural raymarching shader with audio reactivity.\nThis is Scene 0 with audio-reactive boxes and flare effects.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = ASPastRacer::PS_PastRacer_Scene0;
    }
}

technique AS_BGX_PastRacer_Corridor < 
    ui_label = "[AS] BGX: Past Racer (Corridor)"; 
    ui_tooltip = "Abstract procedural raymarching shader with audio reactivity.\nThis is Scene 1 with the corridor structure effect.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = ASPastRacer::PS_PastRacer_Scene1;
    }
}
#endif