/**
 * AS_BGX_DigitalBrain.1.fx - Abstract digital brain visualization with animated Voronoi patterns
 * Author: Leon Aquitaine (shader port), Original GLSL by srtuss (2013)
 * Original ShaderToy: https://www.shadertoy.com/view/4sl3Dr
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates an abstract visualization of a "digital brain" with evolving Voronoi patterns and neural-like
 * connections. The effect simulates an organic electronic network with dynamic light paths that mimic
 * neural activity in a stylized, technological manner.
 * * FEATURES: * - Dynamic Voronoi-based pattern generation that mimics neural networks
 * - Animated "electrical" pulses that simulate synaptic activity
 * - Color modulation based on noise texture for organic variation
 * - Advanced vignette controls with shape adjustment
 * - Pre-optimized pattern stretching with manual fine-tuning capability
 * - Classic and texture-based coloring options
 * - Extensive animation and pattern controls for artistic expression
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
static const float DEFAULT_OCTAVE_COUNT = 3.0; // Number of Voronoi octaves to render (3-4 recommended)
static const float DEFAULT_VIGNETTE_STRENGTH = 0.6; // Strength of the vignetting effect
static const float DEFAULT_EDGE_SHARPNESS = 0.3f; // Default edge sharpness value for Voronoi patterns
static const float DEFAULT_FREQ_MULTIPLIER = 3.0f; // Default frequency multiplier between octaves
static const float DEFAULT_AMPLITUDE_DECAY = 0.7f; // Default amplitude decay per octave
static const float2 DEFAULT_PATTERN_STRETCH = float2(0.7f, 1.22f); // Hidden stretch values for optimal pattern appearance

// Animation constants
static const float ANIMATION_KEYFRAME_MIN = 0.0;
static const float ANIMATION_KEYFRAME_MAX = 100.0;
static const float ANIMATION_KEYFRAME_STEP = 0.1;
static const float ANIMATION_KEYFRAME_DEFAULT = 0.0;

static const float CAMERA_SPEED_MIN = 0.0;
static const float CAMERA_SPEED_MAX = 1.0;
static const float CAMERA_SPEED_STEP = 0.01;
static const float CAMERA_SPEED_DEFAULT = 0.4;

static const float SYNAPSE_SPEED_MIN = 0.1;
static const float SYNAPSE_SPEED_MAX = 2.0;
static const float SYNAPSE_SPEED_STEP = 0.01;
static const float SYNAPSE_SPEED_DEFAULT = 1.0;

// Audio constants
static const float AUDIO_MULTIPLIER_DEFAULT = 1.0;
static const float AUDIO_MULTIPLIER_MAX = 5.0;

// ============================================================================
// TEXTURE CONFIGURATION
// ============================================================================
#ifndef NOISE_TEXTURE_PATH
#define NOISE_TEXTURE_PATH "perlin512x8CNoise.png" // Default noise texture
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

// Animation Controls
uniform float CameraSpeed < ui_type = "slider"; ui_label = "Camera Speed"; ui_tooltip = "Controls how fast the camera moves through the pattern."; ui_min = CAMERA_SPEED_MIN; ui_max = CAMERA_SPEED_MAX; ui_step = CAMERA_SPEED_STEP; ui_category = "Animation Controls"; > = CAMERA_SPEED_DEFAULT;
uniform float CameraMovementAmount < ui_type = "slider"; ui_label = "Camera Movement"; ui_tooltip = "Controls amplitude of camera movement animation."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Animation Controls"; > = 0.4;
uniform float CameraRotationAmount < ui_type = "slider"; ui_label = "Camera Rotation"; ui_tooltip = "Controls amplitude of camera rotation animation."; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Animation Controls"; > = 1.0;
uniform float SynapseSpeed < ui_type = "slider"; ui_label = "Synapse Speed"; ui_tooltip = "Controls how fast the neurons/synapses move in the pattern."; ui_min = SYNAPSE_SPEED_MIN; ui_max = SYNAPSE_SPEED_MAX; ui_step = SYNAPSE_SPEED_STEP; ui_category = "Animation Controls"; > = SYNAPSE_SPEED_DEFAULT;
uniform float FlickerIntensity < ui_type = "slider"; ui_label = "Flicker Intensity"; ui_tooltip = "Controls the intensity of the flickering effect."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Animation Controls"; > = 0.8;
uniform float FlickerFrequency < ui_type = "slider"; ui_label = "Flicker Frequency"; ui_tooltip = "Controls how rapidly the flicker effect changes."; ui_min = 0.5; ui_max = 5.0; ui_step = 0.1; ui_category = "Animation Controls"; > = 2.0;

// Pattern Controls
uniform float ZoomFactor < ui_type = "slider"; ui_label = "Zoom Factor"; ui_tooltip = "Adjusts the zoom level of the pattern."; ui_min = 0.2; ui_max = 2.0; ui_step = 0.01; ui_category = "Pattern Controls"; > = 0.6;
uniform float PatternDensity < ui_type = "slider"; ui_label = "Pattern Density"; ui_tooltip = "Controls density of the Voronoi patterns."; ui_min = 0.5; ui_max = 5.0; ui_step = 0.1; ui_category = "Pattern Controls"; > = 1.0;
uniform int OctaveCount < ui_type = "slider"; ui_label = "Octave Count"; ui_tooltip = "Number of Voronoi detail layers (higher = more detail but slower)."; ui_min = 1; ui_max = 4; ui_category = "Pattern Controls"; > = 3;
uniform float EdgeSharpness < ui_type = "slider"; ui_label = "Edge Sharpness"; ui_tooltip = "Controls the sharpness of pattern edges."; ui_min = 0.05; ui_max = 0.5; ui_step = 0.01; ui_category = "Pattern Controls"; > = DEFAULT_EDGE_SHARPNESS;
uniform float FrequencyMultiplier < ui_type = "slider"; ui_label = "Frequency Multiplier"; ui_tooltip = "Controls how much detail increases with each octave."; ui_min = 1.5; ui_max = 5.0; ui_step = 0.1; ui_category = "Pattern Controls"; > = DEFAULT_FREQ_MULTIPLIER;
uniform float AmplitudeDecay < ui_type = "slider"; ui_label = "Amplitude Decay"; ui_tooltip = "Controls how quickly higher octaves diminish in influence."; ui_min = 0.3; ui_max = 0.9; ui_step = 0.01; ui_category = "Pattern Controls"; > = DEFAULT_AMPLITUDE_DECAY;
uniform float2 PatternStretch < ui_type = "slider"; ui_label = "Pattern Stretch (X/Y)"; ui_tooltip = "Fine-tune the pattern aspect ratio if needed (default 1.0/1.0 is already optimized for most displays)."; ui_min = 0.5; ui_max = 2.0; ui_step = 0.01; ui_category = "Pattern Controls"; > = float2(1.0, 1.0);

// Vignette Controls
uniform float VignetteStrength < ui_type = "slider"; ui_label = "Vignette Strength"; ui_tooltip = "Controls the strength of the vignette effect."; ui_min = 0.0; ui_max = 1.5; ui_step = 0.01; ui_category = "Vignette Controls"; > = DEFAULT_VIGNETTE_STRENGTH;
uniform float VignetteRadius < ui_type = "slider"; ui_label = "Vignette Radius"; ui_tooltip = "Controls the size of the vignette effect."; ui_min = 0.5; ui_max = 1.5; ui_step = 0.01; ui_category = "Vignette Controls"; > = 1.2;
uniform float VignetteRoundness < ui_type = "slider"; ui_label = "Vignette Roundness"; ui_tooltip = "Adjusts the shape of the vignette between elliptical and rectangular."; ui_min = 1.0; ui_max = 4.0; ui_step = 0.1; ui_category = "Vignette Controls"; > = 2.0;

// Texture Sampling
uniform float TextureSamplingScale < ui_type = "slider"; ui_label = "Texture Sampling Scale"; ui_tooltip = "Controls the scale of noise texture sampling."; ui_min = 0.0005; ui_max = 0.02; ui_step = 0.0005; ui_category = "Texture Controls"; > = 0.1;
uniform float ColorNoiseInfluence < ui_type = "slider"; ui_label = "Color Noise Influence"; ui_tooltip = "Controls how much the noise texture affects coloring."; ui_min = 0.5; ui_max = 5.0; ui_step = 0.1; ui_category = "Texture Controls"; > = 3.0;
uniform float ColorVariationScale < ui_type = "slider"; ui_label = "Color Variation Scale"; ui_tooltip = "Controls scaling of the secondary color variation sampling."; ui_min = 0.005; ui_max = 0.05; ui_step = 0.001; ui_category = "Texture Controls"; > = 0.01;

// Color Settings
uniform float3 ColorMultiplier < ui_type = "color"; ui_label = "Color Multiplier"; ui_tooltip = "Adjusts the color balance of the effect."; ui_category = "Color Settings"; > = float3(1.0, 1.0, 1.0);
uniform float ColorIntensity < ui_type = "slider"; ui_label = "Color Intensity"; ui_tooltip = "Overall brightness of the effect."; ui_min = 0.5; ui_max = 4.0; ui_step = 0.1; ui_category = "Color Settings"; > = 2.0;
uniform bool UseClassicColors < ui_label = "Use Classic Blue Colors"; ui_tooltip = "Use the original blue-colored version instead of texture-based colors."; ui_category = "Color Settings"; > = false;
uniform float3 ClassicColorBalance < ui_type = "slider"; ui_label = "Classic Color Balance"; ui_tooltip = "RGB balance for classic mode colors (higher values = stronger color)."; ui_min = 0.5; ui_max = 8.0; ui_step = 0.1; ui_category = "Color Settings"; > = float3(6.0, 4.0, 2.0);


// Audio Reactivity
AS_AUDIO_SOURCE_UI(DigitalBrain_AudioSource, "Audio Source", AS_AUDIO_BASS, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(DigitalBrain_AudioMultiplier, "Audio Multiplier", AUDIO_MULTIPLIER_DEFAULT, AUDIO_MULTIPLIER_MAX, "Audio Reactivity")
uniform int DigitalBrain_AudioTarget < ui_type = "combo"; ui_label = "Audio Target"; ui_items = "None\0Pattern Intensity\0Camera Movement\0Synapse Speed\0Camera Speed\0"; ui_category = "Audio Reactivity"; > = 0;

AS_ANIMATION_SPEED_UI(AnimationSpeed, "Animation")
AS_ANIMATION_KEYFRAME_UI(AnimationKeyframe, "Animation")

// Position & Stage Controls
AS_STAGEDEPTH_UI(StageDepth)
AS_POSITION_SCALE_UI(PositionOffset, Scale)
AS_ROTATION_UI(SnapRotation, ManualRotation)

// Final Mix
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

// Debug
AS_DEBUG_MODE_UI("Off\0Pattern\0UV Coords\0Vignette\0Audio Reactivity\0")

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
    float depth = ReShade::GetLinearizedDepth(texcoord);
      // Skip processing if pixel is beyond stage depth
    if (depth < StageDepth - AS_DEPTH_EPSILON)
        return originalColor;
    
    // Apply position offset and scaling
    // We'll do this directly while maintaining aspect ratio
    float2 positionAdjustedUV = texcoord;
    
    // Calculate normalized offset (centered around 0.5)
    float2 centeredUV = texcoord - 0.5;
      // Apply proper aspect ratio compensation for positioning
    if (ReShade::AspectRatio > 1.0)
        centeredUV.x *= ReShade::AspectRatio;
    else
        centeredUV.y *= ReShade::AspectRatio;
        
    // Apply scale
    centeredUV *= Scale;
      // Apply offset and recenter
    centeredUV += PositionOffset * 0.5; // Convert from [-1,1] to [-0.5,0.5] range
    positionAdjustedUV = centeredUV + 0.5;
    
    // Calculate animation time with keyframe handling
    float currentTime;
    if (AnimationSpeed <= 0.0001f) {
        // When animation speed is effectively zero, use keyframe directly
        currentTime = AnimationKeyframe;
    } else {
        // Otherwise use animated time plus keyframe offset
        currentTime = (AS_getTime() * AnimationSpeed) + AnimationKeyframe;
    }    // Enhanced flicker control with separate frequency and intensity
    float flicker = noise1(currentTime * FlickerFrequency) * FlickerIntensity + (1.0 - FlickerIntensity / 2.0);

    // Apply audio reactivity if enabled
    float audioReactivity = AS_applyAudioReactivity(1.0, DigitalBrain_AudioSource, DigitalBrain_AudioMultiplier, true);
    
    // Pattern intensity and camera speeds will be modified by audio if selected
    float patternIntensity = 1.0;
    float cameraMovementValue = CameraMovementAmount;
    float synapseSpeedValue = SynapseSpeed;
    float cameraSpeedValue = CameraSpeed;
    
    if (DigitalBrain_AudioTarget == 1) { // Pattern Intensity
        patternIntensity = audioReactivity;
    }
    else if (DigitalBrain_AudioTarget == 2) { // Camera Movement
        cameraMovementValue *= audioReactivity;
    }
    else if (DigitalBrain_AudioTarget == 3) { // Synapse Speed
        synapseSpeedValue *= audioReactivity;
    }
    else if (DigitalBrain_AudioTarget == 4) { // Camera Speed
        cameraSpeedValue *= audioReactivity;
    }

    // UV setup: texcoord is (0,0) top-left. ShaderToy fragCoord is (0,0) bottom-left.
    // 1. Make texcoord behave like ShaderToy's (fragCoord.xy / iResolution.xy)
    float2 uv_norm = float2(positionAdjustedUV.x, 1.0f - positionAdjustedUV.y); // uv_norm is now 0-1, (0,0) at bottom-left    // 2. Transform to -1 to 1 range, with (0,0) at center
    float2 uv = (uv_norm - 0.5f) * 2.0f;
    float2 suv = uv; // Store screen-space UVs for vignetting (already -1 to 1 centered)
    float v = 0.0f; // Accumulated pattern value    // ===== Resolution-Independent Coordinate Handling =====
    // Important: We apply zoom and rotation BEFORE aspect ratio correction to avoid distortion
    // This ensures the effect looks the same on all screen aspect ratios and rotates properly    // Apply zoom and animation with user-controlled amounts (but not aspect ratio yet)
    float zoomAmount = ZoomFactor + sin(currentTime * cameraSpeedValue * 0.1f) * cameraMovementValue;
    uv *= zoomAmount;
      // Apply both manual and animated rotation in non-stretched space for proper circular movement
    float rotationAmount = sin(currentTime * cameraSpeedValue * 0.3f) * CameraRotationAmount;
    float totalRotation = rotationAmount + AS_getRotationRadians(SnapRotation, ManualRotation);
    uv = rotate(uv, totalRotation);
    
    // NOW apply aspect ratio correction to the rotated coordinates
    uv.x *= ReShade::AspectRatio;    // Apply pattern stretching control to compensate for compression
    // This is applied after all transformations to directly affect the pattern appearance
    // Multiply by the optimal hidden values and then by the user-controlled values
    uv.x *= DEFAULT_PATTERN_STRETCH.x * PatternStretch.x;
    uv.y *= DEFAULT_PATTERN_STRETCH.y * PatternStretch.y;
    
    // Apply time-based movement
    uv += currentTime * cameraSpeedValue * 0.4f;

    // Add some noise octaves
    float a = 0.6f, f = PatternDensity;    for (int i = 0; i < OctaveCount; i++)
    {
        float v1 = voronoi(uv * f + 5.0f);
        float v2 = 0.0f;
        
        // Make the moving electrons-effect for higher octaves
        if (i > 0)
        {
            // Of course everything based on voronoi - use currentTime with SynapseSpeed
            // so that neuron movement can be controlled independently from camera movement
            v2 = voronoi(uv * f * 0.5f + 50.0f + currentTime * synapseSpeedValue);

            float va = 0.0f, vb = 0.0f;
            va = 1.0f - smoothstep(0.0f, 0.1f, v1);
            vb = 1.0f - smoothstep(0.0f, 0.08f, v2);
            v += a * pow(va * (0.5f + vb), 2.0f);
        }

        // Make sharp edges with user-controlled sharpness
        v1 = 1.0f - smoothstep(0.0f, EdgeSharpness, v1);

        // Noise is used as intensity map
        v2 = a * (noise1(v1 * 5.5f + 0.1f));

        // Octave 0's intensity changes a bit
        if (i == 0)
            v += v2 * flicker;
        else
            v += v2;

        // Use user-controlled frequency multiplier and amplitude decay
        f *= FrequencyMultiplier;
        a *= AmplitudeDecay;
    }// Apply advanced vignette with user controls
    // Adjust for aspect ratio to ensure circular vignette regardless of screen dimensions
    float2 vignetteUV = suv;
    if (ReShade::AspectRatio > 1.0)
        vignetteUV.x /= ReShade::AspectRatio; // Correct for wider screens
    else
        vignetteUV.y *= ReShade::AspectRatio; // Correct for taller screens
        
    float vignetteX = abs(vignetteUV.x);
    float vignetteY = abs(vignetteUV.y);
    float vignetteFactor = pow(pow(vignetteX, VignetteRoundness) + pow(vignetteY, VignetteRoundness), 1.0/VignetteRoundness);
    v *= exp(-VignetteStrength * vignetteFactor) * VignetteRadius;    // Color calculation with options for classic or texture-based coloring
    float3 cexp;
    
    if (UseClassicColors)
    {
        // Use the original blue-colored version with adjustable color balance
        cexp = ClassicColorBalance * ColorMultiplier;
    }
    else 
    {
        // Use texture channel for color with enhanced controls
        cexp = tex2D(DigitalBrain_NoiseSampler, uv * TextureSamplingScale).xyz * ColorNoiseInfluence 
             + tex2D(DigitalBrain_NoiseSampler, uv * ColorVariationScale).xyz;
        cexp *= 1.4f * ColorMultiplier;
    }    
    
    // Calculate final color with pattern intensity affected by audio if selected
    float3 col = float3(pow(v * patternIntensity, cexp.x), pow(v * patternIntensity, cexp.y), pow(v * patternIntensity, cexp.z)) * ColorIntensity;
      // Debug mode display options
    if (DebugMode == 1)
    {
        // Show the raw pattern without color processing
        return float4(v.xxx, originalColor.a);
    }
    else if (DebugMode == 2)
    {
        // Show the UV coordinates (helps debug positioning/rotation)
        return float4(frac(uv.x), frac(uv.y), 0.0, originalColor.a);
    }
    else if (DebugMode == 3)
    {
        // Show the vignette mask
        float2 vignetteUV = suv;
        if (ReShade::AspectRatio > 1.0)
            vignetteUV.x /= ReShade::AspectRatio;
        else
            vignetteUV.y *= ReShade::AspectRatio;
        
        float vignetteX = abs(vignetteUV.x);
        float vignetteY = abs(vignetteUV.y);
        float vignetteFactor = pow(pow(vignetteX, VignetteRoundness) + pow(vignetteY, VignetteRoundness), 1.0/VignetteRoundness);
        float vignetteMask = exp(-VignetteStrength * vignetteFactor) * VignetteRadius;
        return float4(vignetteMask.xxx, originalColor.a);
    }
    else if (DebugMode == 4) 
    {
        // Show Audio Reactivity
        float2 debugCenter = float2(0.1f, 0.1f);
        float debugRadius = 0.08f;
        if (length(texcoord - debugCenter) < debugRadius) {
            return float4(audioReactivity, audioReactivity, audioReactivity, 1.0);
        }
    }
    
    // Apply the standard blend function for final output
    float3 blendedColor = AS_ApplyBlend(col, originalColor.rgb, BlendMode);
    return float4(lerp(originalColor.rgb, blendedColor, BlendStrength), originalColor.a);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_DigitalBrain <
    ui_label = "[AS] BGX: Digital Brain";
    ui_tooltip = "Creates an abstract visualization of a 'digital brain' with evolving Voronoi patterns and neural-like connections.\n"
                "Features extensive controls for pattern complexity, animation, coloring, and vignette effects.\n"
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