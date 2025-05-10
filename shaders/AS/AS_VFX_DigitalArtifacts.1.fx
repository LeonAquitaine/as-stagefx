/**
 * AS_VFX_DigitalArtifacts.1.fx - Digital Effect Generator for Glitches and Holograms
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader creates stylized digital artifacts, glitch effects, and hologram visuals
 * that can be positioned in 3D space. It produces various digital corruption effects 
 * and holographic illusions common in modern media and games.
 *
 * FEATURES:
 * - Multiple effect types (hologram, blocks, scanlines, RGB shifts, noise patterns)
 * - Audio-reactive intensity and parameters
 * - Depth-controlled positioning for precise placement
 * - Customizable colors, intensity, and timing
 * - Blend modes for integrating with the scene
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Uses depth buffer to isolate the layer where effects will appear
 * 2. Generates various digital artifacts based on selected types and parameters
 * 3. Applies audio reactivity to animate the effects in sync with music
 * 4. Blends the result with the scene using configurable blend modes
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_DigitalArtifacts_1_fx
#define __AS_VFX_DigitalArtifacts_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "AS_Noise.1.fxh"

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
static const int MAX_GLITCH_TYPES = 5;

static const float EFFECT_INTENSITY_MIN = 0.0;
static const float EFFECT_INTENSITY_MAX = 1.0;
static const float EFFECT_INTENSITY_DEFAULT = 0.5;

static const float EFFECT_SPEED_MIN = 0.0;
static const float EFFECT_SPEED_MAX = 5.0;
static const float EFFECT_SPEED_DEFAULT = 1.0;

static const float BLOCK_SIZE_MIN = 1.0;
static const float BLOCK_SIZE_MAX = 50.0;
static const float BLOCK_SIZE_DEFAULT = 10.0;

static const float BLOCK_DENSITY_MIN = 0.0;
static const float BLOCK_DENSITY_MAX = 1.0;
static const float BLOCK_DENSITY_DEFAULT = 0.5;

static const float SCANLINE_FREQ_MIN = 10.0;
static const float SCANLINE_FREQ_MAX = 100.0;
static const float SCANLINE_FREQ_DEFAULT = 50.0;

static const float RGB_SPLIT_MIN = 0.0;
static const float RGB_SPLIT_MAX = 0.05;
static const float RGB_SPLIT_DEFAULT = 0.01;

static const float COLOR_INFLUENCE_MIN = 0.0;
static const float COLOR_INFLUENCE_MAX = 1.0;
static const float COLOR_INFLUENCE_DEFAULT = 0.3;

static const float EFFECT_DEPTH_MIN = 0.0;
static const float EFFECT_DEPTH_MAX = 1.0;
static const float EFFECT_DEPTH_DEFAULT = 0.05;

static const float DEPTH_FALLOFF_MIN = 0.5;
static const float DEPTH_FALLOFF_MAX = 5.0;
static const float DEPTH_FALLOFF_DEFAULT = 2.0;

static const float BLEND_AMOUNT_MIN = 0.0;
static const float BLEND_AMOUNT_MAX = 1.0;
static const float BLEND_AMOUNT_DEFAULT = 1.0;

// ============================================================================
// UI DECLARATIONS
// ============================================================================
// --- Main Effect Type ---
uniform int EffectType < ui_type = "combo"; ui_label = "Effect Type"; ui_items = "Hologram\0RGB Shift\0Block Corruption\0Scanlines\0Noise & Static\0"; ui_category = "Main"; > = 0;

// --- Effect-Specific Appearance ---
uniform float EffectIntensity < ui_type = "slider"; ui_label = "Effect Intensity"; ui_tooltip = "Overall strength of the visual effect."; ui_min = EFFECT_INTENSITY_MIN; ui_max = EFFECT_INTENSITY_MAX; ui_step = 0.01; ui_category = "Effect-Specific Appearance"; > = EFFECT_INTENSITY_DEFAULT;
uniform float EffectSpeed < ui_type = "slider"; ui_label = "Animation Speed"; ui_tooltip = "Speed of effect animations and transitions."; ui_min = EFFECT_SPEED_MIN; ui_max = EFFECT_SPEED_MAX; ui_step = 0.1; ui_category = "Effect-Specific Appearance"; > = EFFECT_SPEED_DEFAULT;
uniform float BlockSize < ui_type = "slider"; ui_label = "Block/Line Size"; ui_tooltip = "Size of blocks, scanlines, or pattern elements."; ui_min = BLOCK_SIZE_MIN; ui_max = BLOCK_SIZE_MAX; ui_step = 1.0; ui_category = "Effect-Specific Appearance"; > = BLOCK_SIZE_DEFAULT;
uniform float BlockDensity < ui_type = "slider"; ui_label = "Block Density"; ui_tooltip = "Controls how many glitch blocks/elements appear. Higher values = more glitches."; ui_min = BLOCK_DENSITY_MIN; ui_max = BLOCK_DENSITY_MAX; ui_step = 0.01; ui_category = "Effect-Specific Appearance"; > = BLOCK_DENSITY_DEFAULT;
uniform float3 EffectColor < ui_type = "color"; ui_label = "Effect Color"; ui_category = "Effect-Specific Appearance"; > = float3(1.0, 0.2, 0.2);
uniform float ColorInfluence < ui_type = "slider"; ui_label = "Color Influence"; ui_tooltip = "How much the tint color affects the effect appearance."; ui_min = COLOR_INFLUENCE_MIN; ui_max = COLOR_INFLUENCE_MAX; ui_step = 0.01; ui_category = "Effect-Specific Appearance"; > = COLOR_INFLUENCE_DEFAULT;

// --- Hologram-Specific Parameters ---
uniform float ScanlineFrequency < ui_type = "slider"; ui_label = "Scanline Frequency"; ui_tooltip = "Controls the frequency of scanlines in hologram effect."; ui_min = SCANLINE_FREQ_MIN; ui_max = SCANLINE_FREQ_MAX; ui_step = 1.0; ui_category = "Hologram Parameters"; ui_category_closed = true; > = SCANLINE_FREQ_DEFAULT;
uniform float RGBSplitAmount < ui_type = "slider"; ui_label = "RGB Split Amount"; ui_tooltip = "Controls the amount of RGB channel separation."; ui_min = RGB_SPLIT_MIN; ui_max = RGB_SPLIT_MAX; ui_step = 0.001; ui_category = "Hologram Parameters"; ui_category_closed = true; > = RGB_SPLIT_DEFAULT;

// --- Audio Reactivity: General ---
AS_AUDIO_SOURCE_UI(IntensitySource, "Intensity Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(IntensityMult, "Intensity Impact", 2.0, 5.0, "Audio Reactivity")

// --- Audio Reactivity: Parameters ---
AS_AUDIO_SOURCE_UI(ParameterSource, "Parameter Source", AS_AUDIO_BASS, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(ParameterMult, "Parameter Impact", 1.0, 3.0, "Audio Reactivity")

// --- Audio Reactivity: Hologram Specific ---
AS_AUDIO_SOURCE_UI(ScanlineSource, "Scanline Source", AS_AUDIO_BEAT, "Audio Reactivity") 
AS_AUDIO_MULTIPLIER_UI(ScanlineIntensity, "Scanline Intensity", 0.35, 1.0, "Audio Reactivity") 

AS_AUDIO_SOURCE_UI(RGBSplitSource, "RGB Split Source", AS_AUDIO_BEAT, "Audio Reactivity") 
AS_AUDIO_MULTIPLIER_UI(RGBSplitMult, "RGB Split Intensity", 1.0, 3.0, "Audio Reactivity") 

// --- Audio Reactivity: Block Density ---
AS_AUDIO_SOURCE_UI(BlockDensitySource, "Block Density Source", AS_AUDIO_MID, "Audio Reactivity") 
AS_AUDIO_MULTIPLIER_UI(BlockDensityMult, "Block Density Impact", 1.0, 3.0, "Audio Reactivity") 

// --- Stage Distance ---
uniform float EffectDepth < ui_type = "slider"; ui_label = "Effect Depth"; ui_tooltip = "Adjusts where effects appear in relation to scene depth. Lower values = closer to camera."; ui_min = EFFECT_DEPTH_MIN; ui_max = EFFECT_DEPTH_MAX; ui_step = 0.01; ui_category = "Stage Distance"; > = EFFECT_DEPTH_DEFAULT;
uniform float DepthFalloff < ui_type = "slider"; ui_label = "Depth Falloff"; ui_tooltip = "Controls how quickly the effect fades with distance."; ui_min = DEPTH_FALLOFF_MIN; ui_max = DEPTH_FALLOFF_MAX; ui_step = 0.1; ui_category = "Stage Distance"; > = DEPTH_FALLOFF_DEFAULT;

// --- Final Mix ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug ---
AS_DEBUG_MODE_UI("Off\0Depth Mask\0Effect Only\0Audio\0")

// --- System Uniforms ---
uniform float2 mousePosition < source = "mousepoint"; >;

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================
namespace AS_DigitalArtifacts {
    // Block corruption glitch effect
    float3 blockCorruption(float2 uv, float time, float intensity, float blockSize, float blockDensity) {
        float2 block = floor(uv * blockSize) / blockSize;
        float2 blockUV = frac(uv * blockSize);
        
        // Generate random values for each block
        float rnd = AS_hash11(block.x + block.y * 64.0 + floor(time * 0.1) * 128.0);
        float rnd2 = AS_hash11(block.x + block.y * 64.0 + floor(time * 2.0) * 128.0 + 1337.0);
        
        // Determine if this block should glitch - use blockDensity to control threshold
        float blockThreshold = 1.0 - intensity * 0.5 - blockDensity * 0.4;
        float shift = step(blockThreshold, rnd) * intensity;
        
        // Create UV distortion for this block
        float2 shiftUV = uv;
        if (shift > 0.0) {
            float shiftX = (rnd2 - 0.5) * intensity * 0.5;
            shiftUV.x += shiftX;
        }
        
        // Create color distortion
        float3 color = tex2D(ReShade::BackBuffer, shiftUV).rgb;
        
        // Color corruption for some blocks - also affected by blockDensity
        float colorCorrupt = step(blockThreshold + 0.1, rnd) * intensity;
        if (colorCorrupt > 0.0) {
            float3 corruptColor;
            if (rnd2 < 0.33) {
                corruptColor = float3(color.r, 0.0, 0.0); // Red channel only
            } else if (rnd2 < 0.66) {
                corruptColor = float3(0.0, color.g, 0.0); // Green channel only
            } else {
                corruptColor = float3(0.0, 0.0, color.b); // Blue channel only
            }
            color = lerp(color, corruptColor, intensity);
        }
        
        return color;
    }
      // RGB shift glitch effect
    float3 rgbShift(float2 uv, float time, float intensity, float speed) {
        // Random shifts for R, G, B channels
        float timeShift = time * speed;
        float randShift = AS_hash11(floor(timeShift * 4.0) * AS_HALF);
        float offsetX = (randShift - AS_HALF) * 0.01 * intensity;
        float offsetY = (AS_hash11(floor(timeShift * 8.0) * AS_HALF) - AS_HALF) * 0.01 * intensity;
        
        // Sample channels with offsets
        float r = tex2D(ReShade::BackBuffer, float2(uv.x + offsetX, uv.y)).r;
        float g = tex2D(ReShade::BackBuffer, uv).g;
        float b = tex2D(ReShade::BackBuffer, float2(uv.x - offsetX, uv.y + offsetY)).b;
        
        return float3(r, g, b);
    }
    
    // Scanline glitch effect
    float3 scanlineGlitch(float2 uv, float time, float intensity, float blockSize) {
        float scanlineSize = 1.0 / blockSize;
        float scanline = floor(uv.y * blockSize) / blockSize;
        
        // Generate random values for each scanline
        float rnd = AS_hash11(scanline + floor(time * 1.3) * 64.0);
        float rnd2 = AS_hash11(scanline + floor(time * 5.7) * 64.0 + 1337.0);
        
        // Determine if this scanline should glitch
        float lineThreshold = 1.0 - intensity * 0.5;
        float shift = step(lineThreshold, rnd) * intensity;
        
        // Create UV distortion for this scanline
        float2 shiftUV = uv;
        if (shift > 0.0) {
            float shiftX = (rnd2 - 0.5) * intensity * 0.1;
            shiftUV.x += shiftX;
            
            // Additional vertical shift for some scanlines
            if (rnd2 > 0.7) {
                shiftUV.y += scanlineSize * 0.5 * intensity;
            }
        }
        
        // Create color distortion
        float3 color = tex2D(ReShade::BackBuffer, shiftUV).rgb;
        
        // Scanline darkening
        float scanlineDark = 0.9 + 0.1 * sin(uv.y * blockSize * AS_PI * 2.0);
        color *= scanlineDark;
        
        // Color corruption for some scanlines
        float colorCorrupt = step(lineThreshold + 0.1, rnd) * intensity;
        if (colorCorrupt > 0.0) {
            // Random horizontal white flickering
            if (rnd2 > 0.9) {
                color = lerp(color, float3(1.0, 1.0, 1.0), intensity * rnd2 * sin(time * 50.0 + scanline * 20.0) * 0.5 + 0.5);
            }
            
            // Occasional hue shift
            if (rnd2 < 0.3) {
                color.rgb = color.gbr; // Swap channels
            }
        }
        
        return color;
    }
    
    // Noise and static glitch effect
    float3 noiseGlitch(float2 uv, float time, float intensity, float speed) {
        // Static noise pattern
        float2 noiseUV = uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT) / 8.0;
        float staticNoise = AS_hash11(floor(noiseUV.x) + floor(noiseUV.y) * 300.0 + time * 100.0 * speed);
        
        // Dynamic noise pattern
        float dynamicNoise = AS_hash11(uv.x + uv.y * 100.0 + time * 10.0 * speed);
        
        // VHS-style distortion bands
        float band = sin(uv.y * 100.0 + time * speed) * 0.1 * intensity;
        band += sin(uv.y * 200.0 - time * 0.5 * speed) * 0.05 * intensity;
        
        // Combine noise types
        float combinedNoise = staticNoise * dynamicNoise;
        float noiseInfluence = intensity * 0.2;
        
        // Original color with distortion
        float2 distortUV = uv;
        distortUV.x += band;
        float3 color = tex2D(ReShade::BackBuffer, distortUV).rgb;
        
        // Apply noise
        float3 noiseColor = lerp(color, combinedNoise.xxx, noiseInfluence);
        float3 result = lerp(color, noiseColor, intensity);
        
        // Add occasional white sparkles
        if (dynamicNoise > 0.97) {
            result = lerp(result, float3(1.0, 1.0, 1.0), intensity * dynamicNoise * 0.5);
        }
        
        return result;
    }
    
    // Hologram effect (from HologramGlitch)
    float3 hologramEffect(float2 uv, float time, float intensity, float scanlineFreq, float rgbSplitAmount, 
                           float scanlineAudio, float rgbAudio, float speed) {
        // Scanline effect
        float scanline = sin((uv.y + time * speed * (0.5 + scanlineAudio)) * scanlineFreq) * 0.5 + 0.5;
        float scanlineMask = lerp(1.0, scanline, ScanlineIntensity * scanlineAudio);
        
        // RGB split effect
        float angle = time * AS_PI; // Rotate over time
        float2 rgbOffset = float2(cos(angle), sin(angle)) * (rgbSplitAmount * rgbAudio);
        
        // Glitch/jitter effect
        float glitchPhase = time * speed * 7.0 * (0.5 + rgbAudio);
        float2 jitter = float2(
            (AS_hash11(uv * 100.0 + glitchPhase) - 0.5) * 0.05 * intensity,
            (AS_hash11(uv * 100.0 + glitchPhase + 1.0) - 0.5) * 0.05 * intensity
        );
        
        // Apply offsets to sample RGB channels
        float2 rCoord = uv + rgbOffset + jitter;
        float2 gCoord = uv + jitter;
        float2 bCoord = uv - rgbOffset + jitter;
        
        float3 color = float3(0, 0, 0);
        color.r = tex2D(ReShade::BackBuffer, rCoord).r;
        color.g = tex2D(ReShade::BackBuffer, gCoord).g;
        color.b = tex2D(ReShade::BackBuffer, bCoord).b;
        
        // Combine with scanline
        color.rgb *= scanlineMask;
        
        return color;
    }
}

// --- Main Effect ---
float4 PS_DigitalArtifacts(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Get original color
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    
    // Calculate depth mask
    float depth = ReShade::GetLinearizedDepth(texcoord);
    float depthMask = smoothstep(EffectDepth - 0.05, EffectDepth + 0.05, depth);
    depthMask = pow(depthMask, DepthFalloff);
    
    // Early return if outside the depth range
    if (depthMask <= 0.001) {
        return originalColor;
    }
    
    // Audio-reactive parameters
    float time = AS_getTime();
    float audioIntensity = AS_getAudioSource(IntensitySource) * IntensityMult;
    float audioParameter = AS_getAudioSource(ParameterSource) * ParameterMult;
    
    // Hologram-specific audio parameters
    float scanlineAudio = AS_getAudioSource(ScanlineSource) * ScanlineIntensity;
    float rgbSplitAudio = AS_getAudioSource(RGBSplitSource) * RGBSplitMult;
    
    // Apply audio reactivity to effect parameters
    float intensity = EffectIntensity * (1.0 + audioIntensity);
    float speed = EffectSpeed * (1.0 + audioParameter * 0.2);
    float blockSizeValue = BlockSize * (1.0 + audioParameter * 0.3);
    
    // Add audio reactivity to block density
    float blockDensityAudio = AS_getAudioSource(BlockDensitySource) * BlockDensityMult;
    float blockDensityValue = BlockDensity * (1.0 + blockDensityAudio);
    blockDensityValue = clamp(blockDensityValue, 0.0, 1.0); // Keep within valid range
    
    // Apply selected effect
    float3 effectColor;
    
    if (EffectType == 0) {
        // Hologram effect
        effectColor = AS_DigitalArtifacts::hologramEffect(
            texcoord, time, intensity, ScanlineFrequency, RGBSplitAmount, 
            scanlineAudio, rgbSplitAudio, speed
        );
    }
    else if (EffectType == 1) {
        // RGB Shift
        effectColor = AS_DigitalArtifacts::rgbShift(texcoord, time, intensity, speed);
    }
    else if (EffectType == 2) {
        // Block Corruption
        effectColor = AS_DigitalArtifacts::blockCorruption(texcoord, time, intensity, blockSizeValue, blockDensityValue);
    }
    else if (EffectType == 3) {
        // Scanlines
        effectColor = AS_DigitalArtifacts::scanlineGlitch(texcoord, time, intensity, blockSizeValue);
    }
    else { // 4
        // Noise & Static
        effectColor = AS_DigitalArtifacts::noiseGlitch(texcoord, time, intensity, speed);
    }
    
    // Apply color tint
    effectColor = lerp(effectColor, effectColor * EffectColor, ColorInfluence);
    
    // Debug modes
    if (DebugMode == 1) {
        return float4(depthMask.xxx, 1.0); // Show depth mask
    }
    else if (DebugMode == 2) {
        return float4(effectColor, 1.0); // Show effect only
    }
    else if (DebugMode == 3) {
        // Show audio values
        if (EffectType == 0) { // Hologram
            return float4(audioIntensity, scanlineAudio, rgbSplitAudio, 1.0);
        }
        else {
            return float4(audioIntensity, audioParameter, 0.0, 1.0);
        }
    }
    
    // Apply blend mode and depth mask
    float3 result = AS_blendResult(originalColor.rgb, effectColor, BlendMode);
    return float4(lerp(originalColor.rgb, result, depthMask * BlendAmount), originalColor.a);
}

technique AS_DigitalArtifacts < ui_label = "[AS] VFX: Digital Artifacts"; ui_tooltip = "Creates digital artifacts, glitches, and holographic effects that can be positioned in 3D space."; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_DigitalArtifacts;
    }
}

#endif // __AS_VFX_DigitalArtifacts_1_fx