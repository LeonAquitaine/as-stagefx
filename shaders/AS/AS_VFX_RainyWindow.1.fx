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
 * - Glass roughness for realistic texture variation
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

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_RainyWindow_1_fx
#define __AS_VFX_RainyWindow_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "AS_Noise.1.fxh"

// ============================================================================
// TEXTURES
// ============================================================================
#ifndef NOISE_TEXTURE_PATH
#define NOISE_TEXTURE_PATH "perlin512x8Noise.png" // Default texture if none specified
#endif

texture RainNoiseTex < source = NOISE_TEXTURE_PATH; ui_label = "Noise Texture"; ui_tooltip = "Grayscale noise texture for randomized droplet pattern. R channel used as noise source."; > { Width = 512; Height = 512; Format = R8; };
sampler RainNoiseSampler { Texture = RainNoiseTex; AddressU = REPEAT; AddressV = REPEAT; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR; };

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

// Rain layer constants
static const float LAYER2_SCALE = 2.0;     // Scale factor for second layer
static const float LAYER3_SCALE = 4.0;     // Scale factor for third layer
static const float LAYER2_ALPHA = 0.5;     // Alpha multiplier for second layer
static const float LAYER3_ALPHA = 0.25;    // Alpha multiplier for third layer
static const float LAYER2_TIME_SCALE = 1.5; // Time multiplier for second layer
static const float LAYER3_TIME_SCALE = 2.0; // Time multiplier for third layer

// Noise sampling constants
static const float HIGH_FREQ_NOISE_SCALE = 2.5;  // Scale for higher frequency noise sampling
static const float SHAPE_NOISE_SCALE = 3.0;      // Scale for shape-specific noise
static const float SHAPE_NOISE_OFFSET = 0.5;     // Offset for shape noise sampling
static const float EDGE_NOISE_SCALE = 8.0;       // Scale for edge noise sampling

// Fall speed constants
static const float FALL_SPEED_MULTIPLIER = 0.1;  // Base fall speed multiplier

// Edge transition constants
static const float SMOOTH_EDGE_SHARPNESS = 0.98; // Edge sharpness for smooth glass
static const float ROUGH_EDGE_SHARPNESS = 0.8;   // Edge sharpness for rough glass

// Roughness threshold constants
static const float MIN_ROUGHNESS_THRESHOLD = 0.001; // Minimum roughness to apply effects
static const float SHAPE_ROUGHNESS_THRESHOLD = 0.1; // Threshold for shape distortion
static const float EDGE_ROUGHNESS_THRESHOLD = 0.3;  // Threshold for edge noise
static const float ASYM_ROUGHNESS_THRESHOLD = 0.5;  // Threshold for asymmetric distortion

// Distortion strength constants
static const float POS_DISTORT_X = 0.5;     // X position distortion factor
static const float POS_DISTORT_Y = 0.4;     // Y position distortion factor
static const float CENTER_DISTORT_X = 0.4;  // X center distortion factor
static const float CENTER_DISTORT_Y = 0.5;  // Y center distortion factor
static const float STRETCH_FACTOR = 0.7;    // X stretch factor
static const float COMPRESS_FACTOR = 0.3;   // Y compression factor
static const float SIZE_VARIATION = 0.75;   // Size variation factor
static const float EDGE_NOISE_STRENGTH = 0.4; // Edge noise strength
static const float ASYM_DISTORT_STRENGTH = 0.2; // Asymmetric distortion strength

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Effect Settings ---
uniform float DropSize < ui_type = "slider"; ui_label = "Drop Size"; ui_tooltip = "Controls the size of individual rain droplets."; ui_min = DROP_SIZE_MIN; ui_max = DROP_SIZE_MAX; ui_step = 0.001; ui_category = "Effect Settings"; > = DROP_SIZE_DEFAULT;
uniform float DropImpact < ui_type = "slider"; ui_label = "Distortion Strength"; ui_tooltip = "Controls how much the raindrops distort the image behind them."; ui_min = IMPACT_MIN; ui_max = IMPACT_MAX; ui_step = 0.05; ui_category = "Effect Settings"; > = IMPACT_DEFAULT;
uniform float ResolutionScale < ui_type = "slider"; ui_label = "Resolution Scale"; ui_tooltip = "Adjusts the scale of the effect grid relative to resolution."; ui_min = RESOLUTION_SCALE_MIN; ui_max = RESOLUTION_SCALE_MAX; ui_step = 0.05; ui_category = "Effect Settings"; > = RESOLUTION_SCALE_DEFAULT;
uniform float GlassRoughness < ui_type = "slider"; ui_label = "Glass Roughness"; ui_tooltip = "Controls the surface texture of the glass (0=smooth glass, 1=rough glass)."; ui_min = GLASS_ROUGHNESS_MIN; ui_max = GLASS_ROUGHNESS_MAX; ui_step = 0.01; ui_category = "Effect Settings"; > = GLASS_ROUGHNESS_DEFAULT;

// --- Rain Pattern ---
uniform float GridSizeX < ui_type = "slider"; ui_label = "Rain Grid X"; ui_tooltip = "Controls how many raindrops appear horizontally."; ui_min = GRID_X_MIN; ui_max = GRID_X_MAX; ui_step = 1.0; ui_category = "Rain Pattern"; > = GRID_X_DEFAULT;
uniform float GridSizeY < ui_type = "slider"; ui_label = "Rain Grid Y"; ui_tooltip = "Controls how many raindrops appear vertically."; ui_min = GRID_Y_MIN; ui_max = GRID_Y_MAX; ui_step = 1.0; ui_category = "Rain Pattern"; > = GRID_Y_DEFAULT;

// --- Animation Controls ---
uniform float RainSpeed < ui_type = "slider"; ui_label = "Rain Speed"; ui_tooltip = "Controls the speed of the falling rain."; ui_min = SPEED_MIN; ui_max = SPEED_MAX; ui_step = 0.05; ui_category = "Animation"; > = SPEED_DEFAULT;

// --- Audio Reactivity ---
AS_AUDIO_SOURCE_UI(Rain_AudioSource, "Audio Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(Rain_AudioMultiplier, "Intensity", 1.0, 2.0, "Audio Reactivity")
uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter"; ui_tooltip = "Select which parameter will be affected by audio reactivity"; ui_items = "None\0Drop Size\0Glass Roughness\0"; ui_category = "Audio Reactivity"; > = 0;

// --- Stage Controls ---
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(GlobalSnapRotation, GlobalFineRotation)

// --- Final Mix ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug ---
AS_DEBUG_MODE_UI("Normal\0Raindrops Offset Viz\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================
namespace AS_RainyWindow {

float2 drop_layer(float2 uv, float time, float2 grid, float dropSizeRef, float roughness) {
    // Sample noise texture at two different scales for more variation
    float noise1 = tex2D(RainNoiseSampler, uv).r;
    float noise2 = tex2D(RainNoiseSampler, uv * HIGH_FREQ_NOISE_SCALE).r; // Higher frequency noise
    
    // Blend noises based on roughness for more organic variation
    float noise = lerp(noise1, noise2, roughness * 0.5);
    
    // Calculate fall speed with slight randomization
    float fallSpeed = (AS_hash11(floor(uv.x * grid.x)) + 1.0) * FALL_SPEED_MULTIPLIER;
    uv.y += fallSpeed * time;

    // Calculate base drop UV (grid cell position)
    float2 drop_uv = frac(uv * grid);
    
    // Apply rough glass distortion to the droplet position
    if (roughness > MIN_ROUGHNESS_THRESHOLD) {
        drop_uv = frac(uv * grid + float2(
            noise * roughness * POS_DISTORT_X, 
            noise * roughness * POS_DISTORT_Y
        ));
    }
    
    // Convert to [-1, 1] space for droplet shape calculation
    drop_uv = 2.0 * drop_uv - 1.0;
    
    // Generate shape-specific noise for this droplet cell
    // This creates unique distortion for each droplet
    float2 drop_center = float2(0.0, 0.0);
    float2 cell_uv = frac(uv * grid);
    float shape_noise = tex2D(RainNoiseSampler, cell_uv * SHAPE_NOISE_SCALE + SHAPE_NOISE_OFFSET).r;
    
    // Create non-circular shape when roughness is applied
    if (roughness > MIN_ROUGHNESS_THRESHOLD) {
        // Apply noise-based distortion to the droplet center point
        // This creates irregular, non-circular droplets
        drop_center = float2(
            (shape_noise - 0.5) * roughness * CENTER_DISTORT_X,
            (noise2 - 0.5) * roughness * CENTER_DISTORT_Y
        );
    }
    
    // Calculate distance from distorted center for shape determination
    float2 drop_size = (drop_uv - drop_center) / grid;
    
    // For rough glass, create non-circular droplet shapes
    float dist;
    if (roughness > SHAPE_ROUGHNESS_THRESHOLD) {
        // Create elongated droplet using a custom distance function
        // Distorts the circular shape into more of an ellipse or irregular blob
        float angle = shape_noise * AS_TWO_PI; // Random angle based on noise
        float2 stretch = float2(
            1.0 + roughness * shape_noise * STRETCH_FACTOR,  // X stretch
            1.0 - roughness * noise2 * COMPRESS_FACTOR       // Y compress
        );
        
        // Create a rotated, stretched coordinate space
        float sinA = sin(angle);
        float cosA = cos(angle);
        float2 rotated = float2(
            drop_size.x * cosA - drop_size.y * sinA,
            drop_size.x * sinA + drop_size.y * cosA
        );
        
        // Apply stretch in the rotated space
        rotated /= stretch;
        
        // Use this stretched distance for the droplet shape
        dist = length(rotated);
    }
    else {
        // Use regular circular distance when roughness is low
        dist = length(drop_size);
    }
    
    // Modify the droplet radius based on noise and roughness
    float droplet_radius = dropSizeRef;
    if (roughness > MIN_ROUGHNESS_THRESHOLD) {
        // Vary the droplet size based on noise
        droplet_radius *= (1.0 + (noise - 0.5) * roughness * SIZE_VARIATION);
    }
    
    // Calculate edge transition parameters - vary the sharpness with roughness
    float edgeSharpness = lerp(SMOOTH_EDGE_SHARPNESS, ROUGH_EDGE_SHARPNESS, roughness * 0.5);
    
    // Create droplet with smoothstep for soft edges
    float drop_shape = smoothstep(droplet_radius, droplet_radius * edgeSharpness, dist);
    
    // Add subtle noise to the edge for rough glass
    if (roughness > EDGE_ROUGHNESS_THRESHOLD) {
        float edge_noise = (tex2D(RainNoiseSampler, cell_uv * EDGE_NOISE_SCALE).r - 0.5) * roughness * EDGE_NOISE_STRENGTH;
        drop_shape = saturate(drop_shape + edge_noise);
    }
    
    // Final displacement scaled by drop shape with slight roughness-based variation
    float2 displacement = drop_size * drop_shape;
    if (roughness > ASYM_ROUGHNESS_THRESHOLD) {
        // Add subtle asymmetric distortion for very rough glass
        displacement *= float2(1.0 + roughness * (noise - 0.5) * ASYM_DISTORT_STRENGTH, 1.0);
    }
    
    return displacement;
}

} // namespace AS_RainyWindow

// ============================================================================
// PIXEL SHADER
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
    float2 centered_uv = texcoord - 0.5;
    
    // --- Step 2: Apply aspect ratio correction ---
    centered_uv.x *= aspectRatio;
    
    // --- Step 3: Apply inverse rotation using standard rotation matrix ---
    float sinRot = sin(-globalRotation);
    float cosRot = cos(-globalRotation);
    float2 rotated_coords = float2(
        centered_uv.x * cosRot - centered_uv.y * sinRot,
        centered_uv.x * sinRot + centered_uv.y * cosRot
    );
    
    // --- Step 4: Convert back to UV space for rain calculation ---
    float2 rotated_uv = rotated_coords;
    
    // --- Step 5: Undo aspect ratio correction for proper circular droplets ---
    rotated_uv.x /= aspectRatio;
    
    // --- Step 6: Convert back to 0-1 UV space ---
    rotated_uv += 0.5;

    // --- Create calculation UVs for rain pattern ---
    float2 calc_uv = rotated_uv;
    calc_uv.y = 1.0 - calc_uv.y; // Flip Y for rain calculation
    calc_uv.x *= aspectRatio;    // Apply aspect ratio correction for grid calculations

    // --- Audio Reactivity ---
    float time = AS_getTime() * RainSpeed;
    float dropSizeFinal = DropSize;
    float glassRoughnessFinal = GlassRoughness;

    if (AudioTarget > 0 && Rain_AudioSource != AS_AUDIO_OFF) {
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
    drops += AS_RainyWindow::drop_layer(calc_uv * LAYER2_SCALE, time * LAYER2_TIME_SCALE,   gridSize, dropSizeFinal, glassRoughnessFinal) * LAYER2_ALPHA;
    drops += AS_RainyWindow::drop_layer(calc_uv * LAYER3_SCALE, time * LAYER3_TIME_SCALE,   gridSize, dropSizeFinal, glassRoughnessFinal) * LAYER3_ALPHA;

    // Correct aspect ratio of the distortion vector
    drops.x /= aspectRatio;

    // --- Apply the distortion to the original texcoord, not the rotated one ---
    float2 distortedUV = texcoord + drops * DropImpact;
    
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
technique AS_VFX_RainyWindow <ui_label="[AS] VFX: Rainy Window"; ui_tooltip = "Realistic rainy window distortion effect with customizable droplet patterns and Glass Roughness controls.";
>
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_RainyWindow;
    }
}

#endif // __AS_VFX_RainyWindow_1_fx