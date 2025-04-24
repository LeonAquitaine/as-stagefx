/**
 * AS_LavaLamp.1.fx - Audio-Reactive Lava Lamp Shader
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Audio-reactive lava lamp visualization with smooth, merging blobs. Blob size, movement, and color are modulated by audio.
 *
 * FEATURES:
 * - Adjustable blob count, size, blend strength, and movement
 * - Audio-reactive size and movement (Listeningway integration)
 * - Color controls for blobs and background
 * - Gravity/buoyancy and blend strength controls
 * - Depth occlusion (effect depth)
 * - Debug modes for mask/audio
 * 
 * IMPLEMENTATION OVERVIEW:
 * 1. Creates multiple metaball-like blobs with varying sizes and positions
 * 2. Applies color palettes to blobs and background
 * 3. Blends result with the scene based on depth and configured blend mode
 * 4. Optionally applies audio-reactive modulation to blend strength and movement
 * 
 * ===================================================================================
 */

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "ListeningwayUniforms.fxh"
#include "AS_Utils.1.fxh"

// --- Tunable Constants ---
static const float MIN_GRAVITY = -1.0;
static const float MAX_GRAVITY = 1.0;
static const float MIN_BLEND_STRENGTH = 1.0;
static const float MAX_BLEND_STRENGTH = 8.0;

// --- Palette & Style ---
uniform int Palette < ui_type = "combo"; ui_label = "Color Palette"; ui_items = "Lava\0Ice\0Forest\0Neon\0Pastel\0Goth\0Metal\0Midnight\0Bloodmoon\0Obsidian\0"; ui_category = "Palette & Style"; > = 0;

// --- Blob Appearance ---
uniform int BlobCount < ui_type = "slider"; ui_label = "Blob Count"; ui_tooltip = "Number of blobs."; ui_min = 2; ui_max = 8; ui_step = 1; ui_category = "Blob Appearance"; > = 4;
uniform float BlobMinSize < ui_type = "slider"; ui_label = "Min Size"; ui_tooltip = "Minimum blob size."; ui_min = 0.03; ui_max = 0.2; ui_step = 0.01; ui_category = "Blob Appearance"; > = 0.07;
uniform float BlobMaxSize < ui_type = "slider"; ui_label = "Max Size"; ui_tooltip = "Maximum blob size."; ui_min = 0.05; ui_max = 0.3; ui_step = 0.01; ui_category = "Blob Appearance"; > = 0.13;
uniform float BlendStrength < ui_type = "slider"; ui_label = "Blob Blend"; ui_tooltip = "How liquidy/merging the blobs look."; ui_min = 1.0; ui_max = 8.0; ui_step = 0.1; ui_category = "Blob Appearance"; > = 3.0;
uniform float PulseSpeed < ui_type = "slider"; ui_label = "Pulse Speed"; ui_tooltip = "How quickly blobs pulse in size."; ui_min = 0.05; ui_max = 2.0; ui_step = 0.01; ui_category = "Blob Appearance"; > = 0.4;

// --- Motion & Buoyancy ---
uniform float Gravity < ui_type = "slider"; ui_label = "Buoyancy"; ui_tooltip = "Vertical movement speed of blobs."; ui_min = -1.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Motion & Buoyancy"; > = 0.2;

// --- Audio Integration ---
AS_LISTENINGWAY_UI_CONTROLS("Audio Reactivity")
AS_AUDIO_SOURCE_UI(BlendAudioSource, "Blend Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(BlendAudioMult, "Blend Strength", 1.0, 4.0, "Audio Reactivity")
AS_AUDIO_SOURCE_UI(GravityAudioSource, "Buoyancy Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(GravityAudioMult, "Buoyancy Strength", 1.0, 4.0, "Audio Reactivity")

// --- Stage Distance ---
uniform float EffectDepth < ui_type = "slider"; ui_label = "Distance"; ui_tooltip = "Reference depth for the effect. Lower = closer, higher = further."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Stage Distance"; > = 0.05;

// --- Final Mix ---
uniform int BlendMode < ui_type = "combo"; ui_label = "Mode"; ui_items = "Normal\0Lighter Only\0Darker Only\0Additive\0Multiply\0Screen\0"; ui_category = "Final Mix"; > = 0;
uniform float BlendAmount < ui_type = "slider"; ui_label = "Strength"; ui_tooltip = "How strongly the lava lamp effect is blended with the scene."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Final Mix"; > = 1.0;

// --- Debug ---
AS_DEBUG_MODE_UI("Off\0Mask\0Audio\0")

// --- System Uniforms ---
uniform int frameCount < source = "framecount"; >;

// --- Color Palettes ---
static const float3 LavaPalette[4]     = { float3(1.0,0.4,0.1), float3(1.0,0.7,0.2), float3(0.8,0.1,0.0), float3(1.0,0.2,0.2) };
static const float3 IcePalette[4]      = { float3(0.5,0.8,1.0), float3(0.7,1.0,1.0), float3(0.2,0.6,1.0), float3(0.8,0.9,1.0) };
static const float3 ForestPalette[4]   = { float3(0.2,0.6,0.2), float3(0.4,0.8,0.3), float3(0.1,0.3,0.1), float3(0.6,0.8,0.4) };
static const float3 NeonPalette[4]     = { float3(0.0,1.0,0.8), float3(1.0,0.0,1.0), float3(1.0,1.0,0.0), float3(0.0,0.5,1.0) };
static const float3 PastelPalette[4]   = { float3(1.0,0.8,0.9), float3(0.7,1.0,0.9), float3(0.8,0.9,1.0), float3(0.9,1.0,0.7) };
static const float3 GothPalette[4]     = { float3(0.1,0.1,0.15), float3(0.3,0.0,0.2), float3(0.6,0.0,0.2), float3(0.2,0.2,0.3) };
static const float3 MetalPalette[4]    = { float3(0.2,0.2,0.25), float3(0.5,0.5,0.5), float3(0.8,0.8,0.8), float3(0.3,0.3,0.35) };
static const float3 MidnightPalette[4] = { float3(0.05,0.05,0.10), float3(0.15,0.10,0.20), float3(0.10,0.10,0.25), float3(0.20,0.15,0.30) };
static const float3 BloodmoonPalette[4]= { float3(0.2,0.0,0.0), float3(0.5,0.0,0.1), float3(0.8,0.1,0.2), float3(0.4,0.0,0.1) };
static const float3 ObsidianPalette[4] = { float3(0.05,0.05,0.07), float3(0.15,0.10,0.12), float3(0.10,0.10,0.13), float3(0.20,0.15,0.18) };
static const float3 PaletteBackground[10] = {
    float3(0.08,0.04,0.02), // Lava
    float3(0.10,0.13,0.18), // Ice
    float3(0.08,0.12,0.08), // Forest
    float3(0.02,0.02,0.08), // Neon
    float3(0.98,0.98,0.98), // Pastel
    float3(0.05,0.02,0.08), // Goth
    float3(0.10,0.10,0.12), // Metal
    float3(0.01,0.01,0.03), // Midnight
    float3(0.08,0.01,0.02), // Bloodmoon
    float3(0.01,0.01,0.02)  // Obsidian
};

// --- Helper Functions ---
namespace AS_LavaLamp {
    float3 getBlobColor(int idx) {
        int c = idx % 4;
        if (Palette == 0) return LavaPalette[c];
        if (Palette == 1) return IcePalette[c];
        if (Palette == 2) return ForestPalette[c];
        if (Palette == 3) return NeonPalette[c];
        if (Palette == 4) return PastelPalette[c];
        if (Palette == 5) return GothPalette[c];
        if (Palette == 6) return MetalPalette[c];
        if (Palette == 7) return MidnightPalette[c];
        if (Palette == 8) return BloodmoonPalette[c];
        if (Palette == 9) return ObsidianPalette[c];
        return float3(1,1,1);
    }

    float3 getBackgroundColor() {
        return PaletteBackground[clamp(Palette,0,9)];
    }
}

// --- Main Effect ---
float4 PS_LavaLamp(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Get original color and apply depth cutoff
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    if (sceneDepth < EffectDepth - 0.0005)
        return orig;
    
    // Calculate time and apply audio reactivity
    float time = AS_getTime(frameCount);
    float blendAudio = AS_getAudioSource(BlendAudioSource) * BlendAudioMult;
    float gravityAudioRaw = abs(AS_getAudioSource(GravityAudioSource));
    
    // Slow modulation for gravity
    float slowMod = 0.5 + 0.5 * sin(time * 0.25 + gravityAudioRaw * 2.0);
    float gravityAudio = GravityAudioMult * slowMod;
    float gravityFinal = Gravity * (1.0 + gravityAudio);
    gravityFinal = clamp(gravityFinal, MIN_GRAVITY * 1.5, MAX_GRAVITY * 1.5);
    
    // Initialize blob rendering
    float mask = 0.0;
    float3 blendedColor = 0.0;
    float totalWeight = 0.0;
    
    // Render each blob
    for (int i = 0; i < BlobCount; ++i) {
        // Get random parameters for this blob
        float2 rand = AS_hash21(float(i));
        float phase = AS_hash11(float(i) * 13.7);
        float baseSpeed = lerp(0.08, 0.22, rand.y);
        float dir = lerp(-1.0, 1.0, rand.x);
        
        // Calculate position based on gravity/buoyancy
        float yStart = gravityFinal >= 0.0 ? -0.2 : 1.2;
        float yEnd   = gravityFinal >= 0.0 ? 1.2  : -0.2;
        float y = lerp(yStart, yEnd, frac(time * abs(gravityFinal) * (0.5) * baseSpeed + phase));
        float x = 0.2 + 0.6 * rand.x + 0.1 * sin(time * (0.3 + 0.2 * dir) + i + phase);
        float2 center = float2(x, y);
        
        // Calculate size with pulsing
        float size = lerp(BlobMinSize, BlobMaxSize, 0.5 + 0.5 * sin(time * PulseSpeed * (0.7 + rand.y) + i));
        size *= 1.0;
        
        // Calculate blob contribution with audio-reactive blend strength
        float d = length(texcoord - center);
        float blendFinal = BlendStrength + blendAudio;
        float w = size / (d * max(blendFinal, 0.01) + 1e-4);
        
        // Apply fade in/out at screen boundaries
        float fade = smoothstep(-0.1, 0.1, y) * (1.0 - smoothstep(0.9, 1.1, y));
        w *= fade;
        
        // Accumulate blob colors and weights
        mask += w;
        blendedColor += AS_LavaLamp::getBlobColor(i) * w;
        totalWeight += w;
    }
    
    // Normalize result
    mask = saturate(mask);
    float3 color = lerp(AS_LavaLamp::getBackgroundColor(), blendedColor / max(totalWeight, 1e-4), mask);
    
    // Debug modes
    if (DebugMode == 1) return float4(mask.xxx, 1.0);
    if (DebugMode == 2) return float4(0.0.xxx, 1.0);
    
    // Apply blend mode and strength
    float3 finalColor = AS_blendResult(orig.rgb, color, BlendMode);
    finalColor = lerp(orig.rgb, finalColor, BlendAmount);
    
    return float4(finalColor, 1.0);
}

technique AS_LavaLamp < ui_label = "[AS] Lava Lamp"; ui_tooltip = "Audio-reactive lava lamp visualization with smooth, merging blobs."; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_LavaLamp;
    }
}
