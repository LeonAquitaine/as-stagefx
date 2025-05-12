/**
 * AS_VFX_DustMotes.1.fx - Floating dust motes with depth and audio reactivity
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Simulates static, sharp-bordered dust motes using two independent particle layers.
 * A blur effect is applied to the final image in areas covered by particles.
 * Supports depth masking, rotation, audio reactivity and standard AS blending modes.
 *
 * FEATURES:
 * - Two independent layers of particles with separate controls
 * - Fine and large particle systems with customizable parameters
 * - Backlit effect for realistic light interaction
 * - Optional blur in particle areas for enhanced realism
 * - Full depth masking, rotation and audio reactivity support
 * - Standard AS blending modes and controls
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Generates procedural particles using a grid-based system for stability
 * 2. Calculates particle properties including color, alpha, and position
 * 3. Samples the opposite side of the screen for backlit effects
 * 4. Applies optional blur in areas covered by particles
 * 5. Blends with original scene based on selected blend mode
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_DustMotes_1_fx
#define __AS_VFX_DustMotes_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Noise.1.fxh"

// ============================================================================
// NAMESPACE
// ============================================================================
namespace ASDustMotes {

// ============================================================================
// CONSTANTS
// ============================================================================
static const float3 AS_LUMINANCE_NTSC = float3(0.299, 0.587, 0.114); // NTSC luminance vector

// --- General Particle Behavior ---
static const int MAX_NEIGHBORHOOD_RADIUS_CLAMP = 7;
static const float DEPTH_SIZE_FACTOR = 0.7;
static const float DEPTH_OPACITY_FACTOR = 0.6;
static const float DEPTH_BRIGHTNESS_FACTOR = 0.2;
static const float AA_PIXEL_WIDTH = 1.5;
static const float HASH_SEED_MODIFIER = 0.12345;
static const float SIZE_BIAS_POWER_FACTOR = 3.0;

// --- Layer Specific Seeds ---
static const float LAYER1_SEED_OFFSET = 0.0;
static const float LAYER2_SEED_OFFSET = 10.0;

// --- Thresholds & Minimums ---
static const float MIN_GRID_CELL_UV_SIZE = 0.00001f;
static const float PARTICLE_ALPHA_DRAW_THRESHOLD = 0.001f;
static const float ACCUMULATED_ALPHA_BLEND_THRESHOLD = 0.0001f;
static const float MIN_BLUR_AMOUNT_THRESHOLD = 0.00001f;
static const float MIN_TOTAL_ALPHA_FOR_BLUR_THRESHOLD = 0.001f;

// --- Debug ---
static const float DEBUG_PARTICLE_VISIBILITY_FACTOR = 5.0f;

// --- UI Default Values ---

// Appearance Defaults
static const float3 DEFAULT_COLOR1_BRIGHT = float3(1.0, 0.9, 0.7);
static const float3 DEFAULT_COLOR2_DARK = float3(0.7, 0.4, 0.1);
static const float DEFAULT_COLOR_VARIANCE = 0.8;
static const float DEFAULT_BRIGHTNESS_VARIANCE = 0.5;
static const float DEFAULT_DEPTH_INFLUENCE = 0.6;
static const float DEFAULT_BIAS_LARGE_PARTICLES = 0.1;

// Layer 1 (Fine Motes) Defaults
static const float DEFAULT_L1_DENSITY_THRESHOLD = 0.02;
static const float DEFAULT_L1_GRID_CELL_SIZE = 10.0;
static const float DEFAULT_L1_MIN_SIZE = 0.0005;
static const float DEFAULT_L1_MAX_SIZE = 0.01;
static const float DEFAULT_L1_MIN_ALPHA = 0.05;
static const float DEFAULT_L1_MAX_ALPHA = 0.15;

// Layer 2 (Large Features) Defaults
static const float DEFAULT_L2_DENSITY_THRESHOLD = 0.05;
static const float DEFAULT_L2_GRID_CELL_SIZE = 64.0;
static const float DEFAULT_L2_MIN_SIZE = 0.01;
static const float DEFAULT_L2_MAX_SIZE = 0.1;
static const float DEFAULT_L2_MIN_ALPHA = 0.02;
static const float DEFAULT_L2_MAX_ALPHA = 0.1;

// Common Distribution Map Offset Defaults
static const float DEFAULT_DIST_MAP_OFFSET_X = 0.0;
static const float DEFAULT_DIST_MAP_OFFSET_Y = 0.0;

// Distribution Map Offset UI Limits
static const float MIN_DIST_MAP_OFFSET = -100.0;
static const float MAX_DIST_MAP_OFFSET = 100.0;
static const float STEP_DIST_MAP_OFFSET = 0.1;

// Backlight Defaults
static const float DEFAULT_LIGHT_INTENSITY_INFLUENCE = 0.5;
static const float DEFAULT_LIGHT_COLOR_INFLUENCE = 0.3;

// Effects Defaults
static const float DEFAULT_OVERALL_PARTICLE_BLUR_AMOUNT = 0.0;

// Audio Reactivity Defaults
static const int DEFAULT_AUDIO_TARGET = 0; // Particle Size

//------------------------------------------------------------------------------------------------
// Uniforms (UI Elements)
//------------------------------------------------------------------------------------------------

// --- Appearance ---
uniform float3 ParticleColorBright < ui_type = "color"; ui_label = "Particle Color: Bright"; ui_category = "Appearance"; > = DEFAULT_COLOR1_BRIGHT;
uniform float3 ParticleColorDark < ui_type = "color"; ui_label = "Particle Color: Dark"; ui_category = "Appearance"; > = DEFAULT_COLOR2_DARK;
uniform float ParticleColorVariation < ui_type = "slider"; ui_label = "Particle Color: Variation"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Appearance"; > = DEFAULT_COLOR_VARIANCE;
uniform float ParticleBrightnessVariation < ui_type = "slider"; ui_label = "Particle Brightness: Variation"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Appearance"; > = DEFAULT_BRIGHTNESS_VARIANCE;
uniform float DepthPerspectiveAmount < ui_type = "slider"; ui_label = "Depth: Haze & Perspective"; ui_tooltip = "How particles appear smaller/fainter with distance (pseudo-depth)."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Appearance"; > = DEFAULT_DEPTH_INFLUENCE;
uniform float SizeBiasTowardLarge < ui_type = "slider"; ui_label = "Size Distribution: Bias to Large"; ui_tooltip = "Skews random size generation towards larger particles within min/max range for each layer."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Appearance"; > = DEFAULT_BIAS_LARGE_PARTICLES;

// --- Layer 1 Controls (Fine Detail Layer) ---
uniform float FineMotesDensity < ui_type = "slider"; ui_label = "Density"; ui_tooltip = "Controls the amount of fine motes. Lower values = more motes."; ui_min = 0.001; ui_max = 0.5; ui_step = 0.001; ui_category = "Fine Motes"; > = DEFAULT_L1_DENSITY_THRESHOLD;
uniform float FineMotesCellSize < ui_type = "slider"; ui_label = "Distribution Scale"; ui_tooltip = "Spatial scale for fine mote distribution. Smaller values group them tighter."; ui_min = 2.0; ui_max = 48.0; ui_step = 1.0; ui_category = "Fine Motes"; > = DEFAULT_L1_GRID_CELL_SIZE;
uniform float2 FineMotesSeedOffset < ui_type = "slider"; ui_label = "Distribution Offset (X, Y)"; ui_tooltip = "Shifts the particle distribution pattern. Different values create completely different particle arrangements."; ui_min = MIN_DIST_MAP_OFFSET; ui_max = MAX_DIST_MAP_OFFSET; ui_step = STEP_DIST_MAP_OFFSET; ui_category = "Fine Motes"; > = float2(DEFAULT_DIST_MAP_OFFSET_X, DEFAULT_DIST_MAP_OFFSET_Y);
uniform float FineMotesSizeMin < ui_type = "slider"; ui_label = "Min Size"; ui_tooltip = "Smallest size for fine motes (fraction of screen height)."; ui_min = 0.0001; ui_max = 0.01; ui_step = 0.0001; ui_category = "Fine Motes"; > = DEFAULT_L1_MIN_SIZE;
uniform float FineMotesSizeMax < ui_type = "slider"; ui_label = "Max Size"; ui_tooltip = "Largest size for fine motes (fraction of screen height)."; ui_min = 0.0005; ui_max = 0.03; ui_step = 0.0001; ui_category = "Fine Motes"; > = DEFAULT_L1_MAX_SIZE;
uniform float FineMoteOpacityMin < ui_type = "slider"; ui_label = "Min Opacity"; ui_tooltip = "Minimum opacity for fine motes."; ui_min = 0.01; ui_max = 0.5; ui_step = 0.01; ui_category = "Fine Motes"; > = DEFAULT_L1_MIN_ALPHA;
uniform float FineMoteOpacityMax < ui_type = "slider"; ui_label = "Max Opacity"; ui_tooltip = "Maximum opacity for fine motes."; ui_min = 0.01; ui_max = 0.75; ui_step = 0.01; ui_category = "Fine Motes"; > = DEFAULT_L1_MAX_ALPHA;

// --- Layer 2 Controls (Large Feature Layer) ---
uniform float LargeFeaturesDensity < ui_type = "slider"; ui_label = "Density"; ui_tooltip = "Controls the amount of large features/bokeh. Lower values = more features."; ui_min = 0.001; ui_max = 0.5; ui_step = 0.001; ui_category = "Large Features"; > = DEFAULT_L2_DENSITY_THRESHOLD;
uniform float LargeFeaturesCellSize < ui_type = "slider"; ui_label = "Distribution Scale"; ui_tooltip = "Spatial scale for large feature distribution. Smaller values group them tighter."; ui_min = 16.0; ui_max = 128.0; ui_step = 1.0; ui_category = "Large Features"; > = DEFAULT_L2_GRID_CELL_SIZE;
uniform float2 LargeFeaturesSeedOffset < ui_type = "slider"; ui_label = "Distribution Offset (X, Y)"; ui_tooltip = "Shifts the particle distribution pattern. Different values create completely different particle arrangements."; ui_min = MIN_DIST_MAP_OFFSET; ui_max = MAX_DIST_MAP_OFFSET; ui_step = STEP_DIST_MAP_OFFSET; ui_category = "Large Features"; > = float2(DEFAULT_DIST_MAP_OFFSET_X, DEFAULT_DIST_MAP_OFFSET_Y);
uniform float LargeFeaturesSizeMin < ui_type = "slider"; ui_label = "Min Size"; ui_tooltip = "Smallest size for large features/bokeh (fraction of screen height)."; ui_min = 0.005; ui_max = 0.05; ui_step = 0.001; ui_category = "Large Features"; > = DEFAULT_L2_MIN_SIZE;
uniform float LargeFeaturesSizeMax < ui_type = "slider"; ui_label = "Max Size"; ui_tooltip = "Largest size for large features/bokeh (fraction of screen height)."; ui_min = 0.01; ui_max = 0.20; ui_step = 0.001; ui_category = "Large Features"; > = DEFAULT_L2_MAX_SIZE;
uniform float LargeFeatureOpacityMin < ui_type = "slider"; ui_label = "Min Opacity"; ui_tooltip = "Minimum opacity for large features."; ui_min = 0.01; ui_max = 0.3; ui_step = 0.01; ui_category = "Large Features"; > = DEFAULT_L2_MIN_ALPHA;
uniform float LargeFeatureOpacityMax < ui_type = "slider"; ui_label = "Max Opacity"; ui_tooltip = "Maximum opacity for large features."; ui_min = 0.01; ui_max = 0.5; ui_step = 0.01; ui_category = "Large Features"; > = DEFAULT_L2_MAX_ALPHA;

// --- Backlit Effect Controls ---
uniform float BacklightFlareIntensity < ui_type = "slider"; ui_label = "Flare Intensity"; ui_tooltip = "How much bright background areas make opposite particles flare (increase opacity)."; ui_min = 0.0; ui_max = 4.0; ui_step = 0.01; ui_category = "Backlight"; > = DEFAULT_LIGHT_INTENSITY_INFLUENCE;
uniform float BacklightColorBleed < ui_type = "slider"; ui_label = "Color Bleed"; ui_tooltip = "How much color from bright background areas bleeds into opposite particles."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Backlight"; > = DEFAULT_LIGHT_COLOR_INFLUENCE;

// --- Post-Pass Particle Blur Control ---
uniform float ParticleAreaBlurAmount < ui_type = "slider"; ui_label = "Particle Area: Blur Amount (UV)"; ui_tooltip = "Blurs the final image in areas covered by particles (0=none). Small UV offsets like 0.001-0.005."; ui_min = 0.0; ui_max = 0.01; ui_step = 0.0001; ui_category = "Effects"; > = DEFAULT_OVERALL_PARTICLE_BLUR_AMOUNT;

// --- Audio Reactivity ---
AS_AUDIO_SOURCE_UI(DustMotes_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(DustMotes_AudioMultiplier, "Audio Intensity", 1.0, 2.0, "Audio Reactivity")
uniform int DustMotes_AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter"; ui_tooltip = "Select which parameter will be affected by audio reactivity"; ui_items = "Particle Size\0Particle Opacity\0Blur Amount\0"; ui_category = "Audio Reactivity"; > = DEFAULT_AUDIO_TARGET;

// --- Stage Controls ---
AS_STAGEDEPTH_UI(EffectDepth)

// --- Final Mix ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug ---
AS_DEBUG_MODE_UI("Off\0Audio\0Depth\0Particles Only\0")


//------------------------------------------------------------------------------------------------
// Helper Functions
//------------------------------------------------------------------------------------------------

// drawSharpParticle function - Internal blur logic removed
float4 drawSharpParticle(
    float2 screenUV, 
    float2 particleCenterUV, 
    float particleRadius, 
    float3 particleCalculatedColor, 
    float particleZ_norm, 
    float particleVisibleAlpha, 
    float aspectRatio) 
{
    float2 diff = (screenUV - particleCenterUV) * float2(aspectRatio, 1.0);
    float dist = length(diff);
    
    float radiusAtZ = particleRadius * (1.0 - particleZ_norm * DepthPerspectiveAmount * DEPTH_SIZE_FACTOR); 

    float screenPixelHeight = ReShade::ScreenSize.y;
    float AA_width_norm = (1.0 / screenPixelHeight) * AA_PIXEL_WIDTH; 
    float shapeAlpha = 1.0 - smoothstep(radiusAtZ - AA_width_norm, radiusAtZ + AA_width_norm, dist);
    
    float opacityDepthFactor = (1.0 - particleZ_norm * DepthPerspectiveAmount * DEPTH_OPACITY_FACTOR); 
    float finalOpacity = shapeAlpha * particleVisibleAlpha * opacityDepthFactor;
    
    return float4(particleCalculatedColor, saturate(finalOpacity)); // Return particle's own color
}


// Function to process one layer of particles
float3 processParticleLayer(
    float2 texcoord,
    float aspectRatio,
    out float outLayerTotalAlpha, 
    float layerGridCellSize,
    float layerDensityThreshold,
    float layerMinSize,
    float layerMaxSize,
    float layerMinAlpha,
    float layerMaxAlpha,
    float layerSeedOffset,
    float2 distMapOffset // New parameter for distribution map offset
) {
    float3 accumulatedActualLayerColor = float3(0.0, 0.0, 0.0); 
    float accumulatedLayerAlpha = 0.0; 

    float2 gridCellSizeUV = layerGridCellSize / ReShade::ScreenSize.xy;
    gridCellSizeUV.x = max(gridCellSizeUV.x, MIN_GRID_CELL_UV_SIZE);
    gridCellSizeUV.y = max(gridCellSizeUV.y, MIN_GRID_CELL_UV_SIZE);
    
    float2 invGridCellSizeUV = 1.0 / gridCellSizeUV; 
    float2 currentCellCoord_float = texcoord * invGridCellSizeUV;
    
    int dynamic_R;
    if (layerMaxSize < 0.0001f) {
        dynamic_R = 0; 
    } else {
        float cells_spanned_radius_y = layerMaxSize / gridCellSizeUV.y;
        float particleRadiusUV_X = layerMaxSize / aspectRatio; 
        float cells_spanned_radius_x = particleRadiusUV_X / gridCellSizeUV.x;
        float max_radial_span_in_cells = max(cells_spanned_radius_x, cells_spanned_radius_y);
        dynamic_R = int(ceil(max_radial_span_in_cells));
    }
    
    dynamic_R = min(dynamic_R, MAX_NEIGHBORHOOD_RADIUS_CLAMP);

    [loop] 
    for (int y_loop_var = -dynamic_R; y_loop_var <= dynamic_R; ++y_loop_var)
    {
        [loop] 
        for (int x_loop_var = -dynamic_R; x_loop_var <= dynamic_R; ++x_loop_var)
        {
            float2 cellToCheck_coord = floor(currentCellCoord_float) + float2(x_loop_var, y_loop_var); 
            // Incorporate distMapOffset into particleBaseSeed calculation
            float2 particleBaseSeed = (cellToCheck_coord + layerSeedOffset + distMapOffset) * HASH_SEED_MODIFIER; 
            float spawnCheckRand = AS_hash21(particleBaseSeed);

            if (spawnCheckRand < layerDensityThreshold)
            {
                float particleZ = AS_hash21(particleBaseSeed + 0.1);
                float2 randomJitterInCell = float2(AS_hash21(particleBaseSeed + 0.21), AS_hash21(particleBaseSeed + 0.31));
                float2 particleCenterUV = (cellToCheck_coord + randomJitterInCell) * gridCellSizeUV;

                float2 oppositeScreenPos = 1.0 - particleCenterUV;
                float4 sampleCoordLOD = float4(oppositeScreenPos, 0.0, 0.0);
                float3 oppositePixelColor = tex2Dlod(ReShade::BackBuffer, sampleCoordLOD).rgb;
                float oppositePixelIntensity = dot(oppositePixelColor, AS_LUMINANCE_NTSC);

                float colorMixFactor = clamp(AS_hash21(particleBaseSeed + 0.5) * (1.0 + ParticleColorVariation) - (ParticleColorVariation * 0.5), 0.0, 1.0);
                float3 proceduralColor = lerp(ParticleColorDark, ParticleColorBright, colorMixFactor); 
                float brightnessFactor = 1.0 - ParticleBrightnessVariation * 0.5 + AS_hash21(particleBaseSeed + 0.55) * ParticleBrightnessVariation;
                brightnessFactor *= (1.0 - particleZ * DepthPerspectiveAmount * DEPTH_BRIGHTNESS_FACTOR); 
                proceduralColor *= brightnessFactor;
                float3 particleCalculatedColor = lerp(proceduralColor, oppositePixelColor, BacklightColorBleed);

                float proceduralBaseAlpha = lerp(layerMinAlpha, layerMaxAlpha, AS_hash21(particleBaseSeed + 0.9));
                float alphaBoostFactor = oppositePixelIntensity * BacklightFlareIntensity;
                float particleVisibleAlpha = saturate(proceduralBaseAlpha * (1.0 + alphaBoostFactor));
                
                float sizeRand = AS_hash21(particleBaseSeed + 0.4);
                float t_size = pow(sizeRand, 1.0 / (1.0 + SizeBiasTowardLarge * SIZE_BIAS_POWER_FACTOR)); 
                float particleScreenRadius = lerp(layerMinSize, layerMaxSize, t_size); 

                float4 drawnParticle = drawSharpParticle(texcoord, particleCenterUV, particleScreenRadius, particleCalculatedColor, particleZ, particleVisibleAlpha, aspectRatio);

                if (drawnParticle.a > PARTICLE_ALPHA_DRAW_THRESHOLD) 
                {
                    float A_new = drawnParticle.a;
                    float3 C_new = drawnParticle.rgb; 

                    float A_old = accumulatedLayerAlpha;
                    float3 C_old = accumulatedActualLayerColor;

                    accumulatedLayerAlpha = A_new + A_old * (1.0 - A_new);
                    accumulatedLayerAlpha = saturate(accumulatedLayerAlpha);

                    if (accumulatedLayerAlpha > ACCUMULATED_ALPHA_BLEND_THRESHOLD) { 
                        accumulatedActualLayerColor = (C_new * A_new + C_old * A_old * (1.0 - A_new)) / accumulatedLayerAlpha;
                    } else { // If accumulatedLayerAlpha is very small (e.g., only A_new contributed and it's small)
                        accumulatedActualLayerColor = C_new; // Default to the new particle's color as it's the main recent contributor
                    } 
                }
            }
        }
    }
    
    outLayerTotalAlpha = accumulatedLayerAlpha;
    return accumulatedActualLayerColor * accumulatedLayerAlpha; 
}


//------------------------------------------------------------------------------------------------
// Pixel Shader
//------------------------------------------------------------------------------------------------
float4 FloatingParticlesPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    // Get depth and handle depth-based masking
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth) {
        return tex2D(ReShade::BackBuffer, texcoord);
    }

    float3 baseSceneColor = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float3 colorWithParticles = baseSceneColor; // Start with the original scene
    float aspectRatio = ReShade::ScreenSize.x / ReShade::ScreenSize.y;

    // Get audio reactivity values
    float audioReactivity = AS_applyAudioReactivity(1.0, DustMotes_AudioSource, DustMotes_AudioMultiplier, true);

    // Coordinates to use for particle processing (no rotation)
    float2 rotatedCoord = texcoord;

    // Apply audio reactivity to parameters
    float currentMaxSize_L1 = FineMotesSizeMax;
    float currentMaxSize_L2 = LargeFeaturesSizeMax;
    float currentParticleAlpha_L1 = FineMoteOpacityMax;
    float currentParticleAlpha_L2 = LargeFeatureOpacityMax;
    float currentBlurAmount = ParticleAreaBlurAmount;
    
    if (DustMotes_AudioTarget == 0) { // Particle Size
        currentMaxSize_L1 *= audioReactivity;
        currentMaxSize_L2 *= audioReactivity;
    }
    else if (DustMotes_AudioTarget == 1) { // Particle Opacity
        currentParticleAlpha_L1 *= audioReactivity;
        currentParticleAlpha_L2 *= audioReactivity;
    }
    else if (DustMotes_AudioTarget == 2) { // Blur Amount
        currentBlurAmount *= audioReactivity;
    }

    // --- Process Layer 1 ---
    float alpha_L1;
    float3 premultipliedColor_L1 = processParticleLayer(
        rotatedCoord, aspectRatio, alpha_L1,
        FineMotesCellSize, FineMotesDensity,
        FineMotesSizeMin, currentMaxSize_L1,
        FineMoteOpacityMin, currentParticleAlpha_L1,
        LAYER1_SEED_OFFSET, // Layer 1 seed offset
        FineMotesSeedOffset // Updated to use renamed float2 uniform
    );
    // Blend Layer 1 (pre-multiplied) onto current color (initially baseSceneColor)
    colorWithParticles = premultipliedColor_L1 + colorWithParticles * (1.0 - alpha_L1);
    float totalParticleAlpha = alpha_L1;


    // --- Process Layer 2 ---
    float alpha_L2;
    float3 premultipliedColor_L2 = processParticleLayer(
        rotatedCoord, aspectRatio, alpha_L2,
        LargeFeaturesCellSize, LargeFeaturesDensity,
        LargeFeaturesSizeMin, currentMaxSize_L2,
        LargeFeatureOpacityMin, currentParticleAlpha_L2,
        LAYER2_SEED_OFFSET, // Layer 2 seed offset
        LargeFeaturesSeedOffset // Updated to use renamed float2 uniform
    );
    // Blend Layer 2 (pre-multiplied) onto current color (scene + L1)
    colorWithParticles = premultipliedColor_L2 + colorWithParticles * (1.0 - alpha_L2);
    // Accumulate total alpha: A_out = A_new + A_old*(1-A_new)
    totalParticleAlpha = alpha_L2 + totalParticleAlpha * (1.0 - alpha_L2);
    totalParticleAlpha = saturate(totalParticleAlpha);
    

    // --- Apply Post-Particle Pass Blur ---
    float3 finalOutputColor = colorWithParticles; // Default to the scene with sharp particles

    if (currentBlurAmount > MIN_BLUR_AMOUNT_THRESHOLD && totalParticleAlpha > MIN_TOTAL_ALPHA_FOR_BLUR_THRESHOLD)
    {
        float3 blurredSceneForParticles = float3(0,0,0);
        float2 blurOffset = currentBlurAmount; // This is a UV offset

        // Manually unrolled 4-tap box blur on the original scene (ReShade::BackBuffer)
        blurredSceneForParticles += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(-blurOffset.x, -blurOffset.y), 0.0, 0.0)).rgb;
        blurredSceneForParticles += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2( blurOffset.x, -blurOffset.y), 0.0, 0.0)).rgb;
        blurredSceneForParticles += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(-blurOffset.x,  blurOffset.y), 0.0, 0.0)).rgb;
        blurredSceneForParticles += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2( blurOffset.x,  blurOffset.y), 0.0, 0.0)).rgb;
        blurredSceneForParticles /= 4.0;

        // Blend between the sharp (scene + particles) and the blurred scene, based on total particle alpha
        finalOutputColor = lerp(colorWithParticles, blurredSceneForParticles, totalParticleAlpha);
    }
    
    // Apply final blend based on chosen blend mode
    float3 finalColor = finalOutputColor;
    if (BlendAmount < 1.0) {
        finalColor = lerp(baseSceneColor, finalOutputColor, BlendAmount);
    }
    
    // Handle debug modes
    if (DebugMode == 1) { // Audio
        return float4(audioReactivity.xxx, 1.0);
    }
    else if (DebugMode == 2) { // Depth
        return float4(depth.xxx, 1.0);
    }
    else if (DebugMode == 3) { // Particles Only
        float3 particlesOnly = finalOutputColor - baseSceneColor;
        return float4(particlesOnly * DEBUG_PARTICLE_VISIBILITY_FACTOR, 1.0);
    }
    
    return float4(finalColor, 1.0);
}

//------------------------------------------------------------------------------------------------
// Technique Definition
//------------------------------------------------------------------------------------------------
technique AS_VFX_DustMotes < ui_label = "[AS] VFX: Dust Motes"; ui_tooltip = "Simulates floating dust motes with customizable density, size and appearance."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = ASDustMotes::FloatingParticlesPS;
    }
}

} // namespace ASDustMotes

#endif // __AS_VFX_DustMotes_1_fx
