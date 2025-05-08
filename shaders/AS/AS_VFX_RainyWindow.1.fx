/**
 * AS_VFX_RainyWindow.1.fx - Dynamic rain droplet distortion effect for windows
 * Author: Leon Aquitaine (Adapted from Godot shader by FencerDevLog)
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * Original inspiration: "Godot 4: Rainy window shader (tutorial)" by FencerDevLog
 * Source: https://www.youtube.com/watch?v=QAOt24qV98c
 * FencerDevLog's Patreon: https://www.patreon.com/c/FencerDevLog/posts
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a realistic rainy window effect with multi-layered droplets that
 * distort the scene behind them. Includes customizable rain density, speed, and droplet size.
 * Attempts to closely match the logic of a specific Godot CanvasItem shader.
 *
 * FEATURES:
 * - Multi-layered raindrops with variable scale and speed
 * - Texture-based noise for droplet pattern
 * - Sharp droplet shape
 * - Adjustable rain density and droplet grid size
 * - Audio reactivity for dynamic rain intensity
 * - Aspect ratio independent rendering
 * - Resolution scaling to maintain consistent appearance across displays
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Generates a raindrop grid pattern using hash functions and texture noise
 * 2. Applies multi-scale layers with different speeds and sizes
 * 3. Uses uv displacement calculated from aspect-corrected coordinates to create the distortion effect
 * 4. Blends with the original image using configurable blend mode
 * 
 * ===================================================================================
 */

#ifndef __AS_VFX_RainyWindow_1_fx
#define __AS_VFX_RainyWindow_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // Assumes AS_hash11, AS_getTime, audio/blend/UI helpers are here

// ============================================================================
// TEXTURES
// ============================================================================
#ifndef NOISE_TEXTURE_PATH
#define NOISE_TEXTURE_PATH "perlin512x8Noise.png" // Default texture if none specified
#endif

uniform int ___ < ui_type = "radio"; ui_label = " "; ui_text = "== Noise Texture Settings =="; ui_category = "Texture Settings"; >;
uniform int NoiseTextureWarning < ui_type = "radio"; ui_label = " "; ui_text = "You need to set a noise texture below:"; ui_category = "Texture Settings"; >;

#ifndef NOISE_TEXTURE_HELP
#define NOISE_TEXTURE_HELP "Grayscale noise texture for randomized droplet pattern. R/G/B channel used as noise source."
#endif

uniform bool NeedTexture < source = "key"; keycode = 13; mode = "toggle"; ui_label = " "; ui_text = "If texture not showing: Press Enter!"; ui_tooltip = "If you don't see a texture path option below, press Enter key to refresh UI"; ui_category = "Texture Settings"; ui_category_closed = false; >;

texture NoiseTex < source = NOISE_TEXTURE_PATH; ui_label = "Noise Texture"; ui_tooltip = NOISE_TEXTURE_HELP; > { Width = 256; Height = 256; Format = R8; };
sampler NoiseSampler { Texture = NoiseTex; AddressU = REPEAT; AddressV = REPEAT; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR; };

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
static const float GRID_X_MIN = 1.0;
static const float GRID_X_MAX = 30.0;
static const float GRID_X_DEFAULT = 10.0; // Matches Godot default
static const float GRID_Y_MIN = 1.0;
static const float GRID_Y_MAX = 15.0;
static const float GRID_Y_DEFAULT = 5.0;  // Matches Godot default
static const float SPEED_MIN = 0.0;
static const float SPEED_MAX = 4.0;
static const float SPEED_DEFAULT = 1.0;   // Matches Godot default
static const float DROP_SIZE_MIN = 0.001;
static const float DROP_SIZE_MAX = 0.1;
static const float DROP_SIZE_DEFAULT = 0.03; // Default matches Godot's smoothstep edge
static const float IMPACT_MIN = 0.1;
static const float IMPACT_MAX = 2.0;
static const float IMPACT_DEFAULT = 1.0;
static const float RESOLUTION_SCALE_MIN = 0.2;
static const float RESOLUTION_SCALE_MAX = 2.0;
static const float RESOLUTION_SCALE_DEFAULT = 1.0;
static const float GLASS_ROUGHNESS_MIN = 0.0;
static const float GLASS_ROUGHNESS_MAX = 1.0;
static const float GLASS_ROUGHNESS_DEFAULT = 0.5;

// ============================================================================
// EFFECT-SPECIFIC APPEARANCE
// ============================================================================
uniform float GridSizeX < ui_type = "slider"; ui_label = "Rain Grid X"; ui_tooltip = "Controls how many raindrops appear horizontally."; ui_min = GRID_X_MIN; ui_max = GRID_X_MAX; ui_step = 1.0; ui_category = "Rain Pattern"; > = GRID_X_DEFAULT;

uniform float GridSizeY < ui_type = "slider"; ui_label = "Rain Grid Y"; ui_tooltip = "Controls how many raindrops appear vertically."; ui_min = GRID_Y_MIN; ui_max = GRID_Y_MAX; ui_step = 1.0; ui_category = "Rain Pattern"; > = GRID_Y_DEFAULT;

uniform float DropSize < ui_type = "slider"; ui_label = "Drop Size"; ui_tooltip = "Controls the size of individual rain droplets."; ui_min = DROP_SIZE_MIN; ui_max = DROP_SIZE_MAX; ui_step = 0.001; ui_category = "Rain Pattern"; > = DROP_SIZE_DEFAULT;

uniform float DropImpact < ui_type = "slider"; ui_label = "Distortion Strength"; ui_tooltip = "Controls how much the raindrops distort the image behind them."; ui_min = IMPACT_MIN; ui_max = IMPACT_MAX; ui_step = 0.05; ui_category = "Rain Pattern"; > = IMPACT_DEFAULT;

uniform float ResolutionScale < ui_type = "slider"; ui_label = "Resolution Scale"; ui_tooltip = "Adjusts the scale of the effect grid relative to resolution."; ui_min = RESOLUTION_SCALE_MIN; ui_max = RESOLUTION_SCALE_MAX; ui_step = 0.05; ui_category = "Rain Pattern"; > = RESOLUTION_SCALE_DEFAULT;

uniform float GlassRoughness < ui_type = "slider"; ui_label = "Glass Roughness"; ui_tooltip = "Controls the surface texture of the glass (0=smooth glass, 1=rough glass)."; ui_min = GLASS_ROUGHNESS_MIN; ui_max = GLASS_ROUGHNESS_MAX; ui_step = 0.01; ui_category = "Rain Pattern"; > = GLASS_ROUGHNESS_DEFAULT;

// ============================================================================
// ANIMATION
// ============================================================================
uniform float RainSpeed < ui_type = "slider"; ui_label = "Rain Speed"; ui_tooltip = "Controls the speed of the falling rain."; ui_min = SPEED_MIN; ui_max = SPEED_MAX; ui_step = 0.05; ui_category = "Animation"; > = SPEED_DEFAULT;

// ============================================================================
// AUDIO REACTIVITY
// ============================================================================
AS_AUDIO_SOURCE_UI(Rain_AudioSource, "Audio Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(Rain_AudioMultiplier, "Intensity", 1.0, 2.0, "Audio Reactivity")

uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter"; ui_tooltip = "Select which parameter will be affected by audio reactivity"; ui_items = "None\0Drop Size\0Glass Roughness\0"; ui_category = "Audio Reactivity"; > = 0;

// ============================================================================
// STAGE DISTANCE
// ============================================================================
AS_STAGEDEPTH_UI(EffectDepth, "Effect Depth", "Stage")
AS_ROTATION_UI(GlobalSnapRotation, GlobalFineRotation, "Stage")  // Added rotation controls

// ============================================================================
// FINAL MIX
// ============================================================================
AS_BLENDMODE_UI(BlendMode, "Final Mix")
AS_BLENDAMOUNT_UI(BlendAmount, "Final Mix")

// ============================================================================
// DEBUG
// ============================================================================
AS_DEBUG_MODE_UI("Normal\0Raindrops Offset Viz\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================
namespace AS_RainyWindow {

float2 drop_layer(float2 uv, float time, float2 grid, float dropSizeRef, float roughness) {
    float noise = tex2D(NoiseSampler, uv).r;

    float noiseInfluence = lerp(0.1, 1.0, roughness);
    
    float fallSpeed = (AS_hash11(floor(uv.x * grid.x)) + 1.0) * 0.1;

    uv.y += fallSpeed * time;

    float2 drop_uv = frac(uv * grid + float2(noise * 0.5 * noiseInfluence, noise * 0.1 * noiseInfluence));
    drop_uv = 2.0 * drop_uv - 1.0;

    float2 drop_size = drop_uv / grid;

    float outerEdge = dropSizeRef;
    float innerEdge = dropSizeRef * (2.0/3.0);

    float drop_shape = smoothstep(outerEdge, innerEdge, length(drop_size));

    return drop_size * drop_shape;
}

} // namespace AS_RainyWindow

// ============================================================================
// MAIN PIXEL SHADER
// ============================================================================
float4 PS_RainyWindow(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Get original pixel and check depth
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth - 0.0005)
        return orig;

    // --- Setup ---
    float resolutionScale = (float)BUFFER_HEIGHT / 1080.0 * ResolutionScale;
    float aspectRatio = ReShade::AspectRatio;
    float globalRotation = AS_getRotationRadians(GlobalSnapRotation, GlobalFineRotation);
    
    // --- Step 1: Transform screen UVs to centered coordinate system for rotation ---
    // Use AS_Utils aspectCorrect for proper aspect ratio handling
    float2 centered_uv = texcoord - 0.5;
    float2 screen_coords = AS_aspectCorrect(centered_uv, BUFFER_WIDTH, BUFFER_HEIGHT);
    
    // --- Step 2: Apply inverse rotation using standard rotation matrix ---
    float2 rotated_coords;
    float sinRot = sin(-globalRotation);
    float cosRot = cos(-globalRotation);
    rotated_coords.x = screen_coords.x * cosRot - screen_coords.y * sinRot;
    rotated_coords.y = screen_coords.x * sinRot + screen_coords.y * cosRot;
    
    // --- Step 3: Convert back to UV space for rain calculation ---
    float2 rotated_uv = rotated_coords + 0.5;

    // --- Create calculation UVs for rain pattern ---
    float2 calc_uv = rotated_uv;
    calc_uv.y = 1.0 - calc_uv.y; // Flip Y for rain calculation
    calc_uv.x *= aspectRatio;    // Apply aspect ratio correction for grid calculations

    // --- Audio Reactivity ---
    float time = AS_getTime() * RainSpeed;
    float dropSizeFinal = DropSize;
    float dropImpactFinal = DropImpact;
    float glassRoughnessFinal = GlassRoughness;

    if (AudioTarget > 0) {
        float audioValue = AS_applyAudioReactivity(1.0, Rain_AudioSource, Rain_AudioMultiplier, true) - 1.0;
        if (AudioTarget == 1) { // Drop Size
            dropSizeFinal = saturate(DropSize + (DropSize * audioValue * 0.5));
        } else if (AudioTarget == 2) { // Glass Roughness
            glassRoughnessFinal = saturate(GlassRoughness + (GlassRoughness * audioValue * 0.8));
        }
    }

    // --- Calculate rain distortion vector ---
    float2 gridSize = float2(GridSizeX, GridSizeY) * resolutionScale;
    float2 drops = float2(0.0, 0.0);
    
    // Multi-layer approach with scaling factors
    drops =  AS_RainyWindow::drop_layer(calc_uv,       time,         gridSize, dropSizeFinal, glassRoughnessFinal);
    drops += AS_RainyWindow::drop_layer(calc_uv * 2.0, time * 1.5,   gridSize, dropSizeFinal, glassRoughnessFinal) * 0.5;
    drops += AS_RainyWindow::drop_layer(calc_uv * 4.0, time * 2.0,   gridSize, dropSizeFinal, glassRoughnessFinal) * 0.25;

    // Correct aspect ratio of the distortion vector
    drops.x /= aspectRatio;

    // --- Apply the distortion to the original texcoord, not the rotated one ---
    // This ensures we sample from the non-rotated backbuffer
    float2 distortedUV = texcoord + drops * dropImpactFinal;
    
    // Ensure distortedUV stays within bounds
    distortedUV = clamp(distortedUV, 0.0, 1.0);
    
    // Sample the original (non-rotated) backbuffer with the distortion offset
    float4 result = tex2D(ReShade::BackBuffer, distortedUV);

    // --- Debug visualization ---
    if (DebugMode == 1) {
        return float4(0.5 + drops * 10.0, 0.5, 1.0); // Visualization of displacement vectors
    }

    // --- Final blend ---
    result.rgb = AS_blendResult(orig.rgb, result.rgb, BlendMode);
    return float4(lerp(orig.rgb, result.rgb, BlendAmount), orig.a);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_VFX_RainyWindow < ui_label = "[AS] VFX: Rainy Window"; ui_tooltip = "Realistic rainy window distortion effect (Godot Port Attempt). Requires noise texture."; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_RainyWindow;
    }
}

#endif // __AS_VFX_RainyWindow_1_fx