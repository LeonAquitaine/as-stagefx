/**
 * Floating Particles / Dust Motes (2-Layer Dynamic Grid - Post-Pass Particle Blur)
 *
 * Simulates static, sharp-bordered dust motes using two independent layers.
 * A blur effect is applied to the final image in areas covered by particles.
 * Full UI refinements and features are active.
 *
 * Change: Internal particle blur removed. A new post-pass blur is applied,
 * controlled by total particle alpha and a new blur amount uniform.
 */

#include "ReShade.fxh"

//------------------------------------------------------------------------------------------------
// Uniforms (UI Elements)
//------------------------------------------------------------------------------------------------

// --- Layer 1 Controls (Fine Detail Layer) ---
uniform float fParticleDensityThreshold_L1 <
    ui_type = "slider";
    ui_label = "Fine Motes: Density";
    ui_tooltip = "Controls the amount of fine motes. Lower values = more motes.";
    ui_min = 0.001; ui_max = 0.5; 
    ui_step = 0.001;
> = 0.02; 

uniform float fGridCellSize_L1 <
    ui_type = "slider";
    ui_label = "Fine Motes: Distribution Scale";
    ui_tooltip = "Spatial scale for fine mote distribution. Smaller values group them tighter.";
    ui_min = 2.0; ui_max = 48.0; 
    ui_step = 1.0;
> = 10.0; 

uniform float fMinSize_L1 <
    ui_type = "slider";
    ui_label = "Fine Motes: Min Size";
    ui_tooltip = "Smallest size for fine motes (fraction of screen height).";
    ui_min = 0.0001; ui_max = 0.01; 
    ui_step = 0.0001;
> = 0.0005;

uniform float fMaxSize_L1 <
    ui_type = "slider";
    ui_label = "Fine Motes: Max Size";
    ui_tooltip = "Largest size for fine motes (fraction of screen height).";
    ui_min = 0.0005; ui_max = 0.03;
    ui_step = 0.0001;
> = 0.01; 

uniform float fMinParticleAlpha_L1 <
    ui_type = "slider";
    ui_label = "Fine Motes: Min Opacity";
    ui_tooltip = "Minimum opacity for fine motes.";
    ui_min = 0.01; ui_max = 0.5; 
    ui_step = 0.01;
> = 0.05; 

uniform float fMaxParticleAlpha_L1 <
    ui_type = "slider";
    ui_label = "Fine Motes: Max Opacity";
    ui_tooltip = "Maximum opacity for fine motes.";
    ui_min = 0.01; ui_max = 0.75; 
    ui_step = 0.01;
> = 0.15; 


// --- Layer 2 Controls (Large Feature Layer) ---
uniform float fParticleDensityThreshold_L2 <
    ui_type = "slider";
    ui_label = "Large Features: Density";
    ui_tooltip = "Controls the amount of large features/bokeh. Lower values = more features.";
    ui_min = 0.001; ui_max = 0.5; 
    ui_step = 0.001;
> = 0.05; 

uniform float fGridCellSize_L2 <
    ui_type = "slider";
    ui_label = "Large Features: Distribution Scale";
    ui_tooltip = "Spatial scale for large feature distribution. Smaller values group them tighter.";
    ui_min = 16.0; ui_max = 128.0;
    ui_step = 1.0;
> = 64.0; 

uniform float fMinSize_L2 <
    ui_type = "slider";
    ui_label = "Large Features: Min Size";
    ui_tooltip = "Smallest size for large features/bokeh (fraction of screen height).";
    ui_min = 0.005; ui_max = 0.05; 
    ui_step = 0.001;
> = 0.01;

uniform float fMaxSize_L2 <
    ui_type = "slider";
    ui_label = "Large Features: Max Size";
    ui_tooltip = "Largest size for large features/bokeh (fraction of screen height).";
    ui_min = 0.01; ui_max = 0.20; 
    ui_step = 0.001;
> = 0.1; 

uniform float fMinParticleAlpha_L2 <
    ui_type = "slider";
    ui_label = "Large Features: Min Opacity";
    ui_tooltip = "Minimum opacity for large features.";
    ui_min = 0.01; ui_max = 0.3; 
    ui_step = 0.01;
> = 0.02; 

uniform float fMaxParticleAlpha_L2 <
    ui_type = "slider";
    ui_label = "Large Features: Max Opacity";
    ui_tooltip = "Maximum opacity for large features.";
    ui_min = 0.01; ui_max = 0.5; 
    ui_step = 0.01;
> = 0.1; 


// --- Shared Controls ---
uniform float3 fColor1 < ui_type = "color"; ui_label = "Particle Color: Bright"; > = float3(1.0, 0.9, 0.7);
uniform float3 fColor2 < ui_type = "color"; ui_label = "Particle Color: Dark"; > = float3(0.7, 0.4, 0.1);
uniform float fColorVariance < ui_type = "slider"; ui_label = "Particle Color: Variation"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; > = 0.8;
uniform float fBrightnessVariance < ui_type = "slider"; ui_label = "Particle Brightness: Variation"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; > = 0.5;
uniform float fDepthInfluence <
    ui_type = "slider";
    ui_label = "Depth: Haze & Perspective";
    ui_tooltip = "How particles appear smaller/fainter with distance (pseudo-depth).";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 0.6;
uniform float fBiasLargeParticles <
    ui_type = "slider";
    ui_label = "Size Distribution: Bias to Large";
    ui_tooltip = "Skews random size generation towards larger particles within min/max range for each layer.";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 0.1;

// --- Backlit Effect Controls ---
uniform float fLightIntensityInfluence <
    ui_type = "slider";
    ui_label = "Backlight: Flare Intensity";
    ui_tooltip = "How much bright background areas make opposite particles flare (increase opacity).";
    ui_min = 0.0; ui_max = 2.0;
    ui_step = 0.01;
> = 0.5;
uniform float fLightColorInfluence <
    ui_type = "slider";
    ui_label = "Backlight: Color Bleed";
    ui_tooltip = "How much color from bright background areas bleeds into opposite particles.";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 0.3;

// --- Post-Pass Particle Blur Control ---
uniform float fOverallParticleBlurAmount <
    ui_type = "slider";
    ui_label = "Particle Area: Blur Amount (UV)";
    ui_tooltip = "Blurs the final image in areas covered by particles (0=none). Small UV offsets like 0.001-0.005.";
    ui_min = 0.0; ui_max = 0.01; 
    ui_step = 0.0001;
> = 0.0;


//------------------------------------------------------------------------------------------------
// Helper Functions
//------------------------------------------------------------------------------------------------

// Pseudo-random number generator from a float2 seed
float rand(float2 co) {
    return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
}

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
    
    float radiusAtZ = particleRadius * (1.0 - particleZ_norm * fDepthInfluence * 0.7); 

    float screenPixelHeight = ReShade::ScreenSize.y;
    float AA_width_norm = (1.0 / screenPixelHeight) * 1.5; 
    float shapeAlpha = 1.0 - smoothstep(radiusAtZ - AA_width_norm, radiusAtZ + AA_width_norm, dist);
    
    float opacityDepthFactor = (1.0 - particleZ_norm * fDepthInfluence * 0.6); 
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
    float layerSeedOffset
) {
    float3 accumulatedActualLayerColor = float3(0.0, 0.0, 0.0); 
    float accumulatedLayerAlpha = 0.0; 

    float2 gridCellSizeUV = layerGridCellSize / ReShade::ScreenSize.xy;
    gridCellSizeUV.x = max(gridCellSizeUV.x, 0.00001f);
    gridCellSizeUV.y = max(gridCellSizeUV.y, 0.00001f);
    
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
    
    const int MAX_NEIGHBORHOOD_RADIUS_CLAMP = 7; 
    dynamic_R = min(dynamic_R, MAX_NEIGHBORHOOD_RADIUS_CLAMP);

    [loop] 
    for (int y_loop_var = -dynamic_R; y_loop_var <= dynamic_R; ++y_loop_var)
    {
        [loop] 
        for (int x_loop_var = -dynamic_R; x_loop_var <= dynamic_R; ++x_loop_var)
        {
            float2 cellToCheck_coord = floor(currentCellCoord_float) + float2(x_loop_var, y_loop_var); 
            float2 particleBaseSeed = (cellToCheck_coord + layerSeedOffset) * 0.12345; 
            float spawnCheckRand = rand(particleBaseSeed);

            if (spawnCheckRand < layerDensityThreshold)
            {
                float particleZ = rand(particleBaseSeed + 0.1); 
                float2 randomJitterInCell = float2(rand(particleBaseSeed + 0.21), rand(particleBaseSeed + 0.31));
                float2 particleCenterUV = (cellToCheck_coord + randomJitterInCell) * gridCellSizeUV;

                float2 oppositeScreenPos = 1.0 - particleCenterUV;
                float4 sampleCoordLOD = float4(oppositeScreenPos, 0.0, 0.0);
                float3 oppositePixelColor = tex2Dlod(ReShade::BackBuffer, sampleCoordLOD).rgb;
                float oppositePixelIntensity = dot(oppositePixelColor, float3(0.299, 0.587, 0.114));

                float colorMixFactor = clamp(rand(particleBaseSeed + 0.5) * (1.0 + fColorVariance) - (fColorVariance * 0.5), 0.0, 1.0);
                float3 proceduralColor = lerp(fColor2, fColor1, colorMixFactor); 
                float brightnessFactor = 1.0 - fBrightnessVariance * 0.5 + rand(particleBaseSeed + 0.55) * fBrightnessVariance;
                brightnessFactor *= (1.0 - particleZ * fDepthInfluence * 0.2); 
                proceduralColor *= brightnessFactor;
                float3 particleCalculatedColor = lerp(proceduralColor, oppositePixelColor, fLightColorInfluence);

                float proceduralBaseAlpha = lerp(layerMinAlpha, layerMaxAlpha, rand(particleBaseSeed + 0.9));
                float alphaBoostFactor = oppositePixelIntensity * fLightIntensityInfluence;
                float particleVisibleAlpha = saturate(proceduralBaseAlpha * (1.0 + alphaBoostFactor));
                
                float sizeRand = rand(particleBaseSeed + 0.4);
                float t_size = pow(sizeRand, 1.0 / (1.0 + fBiasLargeParticles * 3.0)); 
                float particleScreenRadius = lerp(layerMinSize, layerMaxSize, t_size); 

                float4 drawnParticle = drawSharpParticle(texcoord, particleCenterUV, particleScreenRadius, particleCalculatedColor, particleZ, particleVisibleAlpha, aspectRatio);

                if (drawnParticle.a > 0.001) 
                {
                    float A_new = drawnParticle.a;
                    float3 C_new = drawnParticle.rgb; 

                    float A_old = accumulatedLayerAlpha;
                    float3 C_old = accumulatedActualLayerColor;

                    accumulatedLayerAlpha = A_new + A_old * (1.0 - A_new);
                    accumulatedLayerAlpha = saturate(accumulatedLayerAlpha);

                    if (accumulatedLayerAlpha > 0.0001f) { 
                        accumulatedActualLayerColor = (C_new * A_new + C_old * A_old * (1.0 - A_new)) / accumulatedLayerAlpha;
                    } else if (A_new > 0.0001f) { 
                        accumulatedActualLayerColor = C_new;
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
    float3 baseSceneColor = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float3 colorWithParticles = baseSceneColor; // Start with the original scene
    float aspectRatio = ReShade::ScreenSize.x / ReShade::ScreenSize.y;

    // --- Process Layer 1 ---
    float alpha_L1;
    float3 premultipliedColor_L1 = processParticleLayer(
        texcoord, aspectRatio, alpha_L1,
        fGridCellSize_L1, fParticleDensityThreshold_L1,
        fMinSize_L1, fMaxSize_L1,
        fMinParticleAlpha_L1, fMaxParticleAlpha_L1,
        0.0 // Layer 1 seed offset
    );
    // Blend Layer 1 (pre-multiplied) onto current color (initially baseSceneColor)
    colorWithParticles = premultipliedColor_L1 + colorWithParticles * (1.0 - alpha_L1);
    float totalParticleAlpha = alpha_L1;


    // --- Process Layer 2 ---
    float alpha_L2;
    float3 premultipliedColor_L2 = processParticleLayer(
        texcoord, aspectRatio, alpha_L2,
        fGridCellSize_L2, fParticleDensityThreshold_L2,
        fMinSize_L2, fMaxSize_L2,
        fMinParticleAlpha_L2, fMaxParticleAlpha_L2,
        10.0 // Layer 2 seed offset
    );
    // Blend Layer 2 (pre-multiplied) onto current color (scene + L1)
    colorWithParticles = premultipliedColor_L2 + colorWithParticles * (1.0 - alpha_L2);
    // Accumulate total alpha: A_out = A_new + A_old*(1-A_new)
    totalParticleAlpha = alpha_L2 + totalParticleAlpha * (1.0 - alpha_L2);
    totalParticleAlpha = saturate(totalParticleAlpha);
    

    // --- Apply Post-Particle Pass Blur ---
    float3 finalOutputColor = colorWithParticles; // Default to the scene with sharp particles

    if (fOverallParticleBlurAmount > 0.00001f && totalParticleAlpha > 0.001f)
    {
        float3 blurredSceneForParticles = float3(0,0,0);
        float2 blurOffset = fOverallParticleBlurAmount; // This is a UV offset

        // Manually unrolled 4-tap box blur on the original scene (ReShade::BackBuffer)
        blurredSceneForParticles += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(-blurOffset.x, -blurOffset.y), 0.0, 0.0)).rgb;
        blurredSceneForParticles += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2( blurOffset.x, -blurOffset.y), 0.0, 0.0)).rgb;
        blurredSceneForParticles += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(-blurOffset.x,  blurOffset.y), 0.0, 0.0)).rgb;
        blurredSceneForParticles += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2( blurOffset.x,  blurOffset.y), 0.0, 0.0)).rgb;
        blurredSceneForParticles /= 4.0;

        // Blend between the sharp (scene + particles) and the blurred scene, based on total particle alpha
        finalOutputColor = lerp(colorWithParticles, blurredSceneForParticles, totalParticleAlpha);
    }
    
    return float4(finalOutputColor, 1.0);
}

//------------------------------------------------------------------------------------------------
// Technique Definition
//------------------------------------------------------------------------------------------------
technique FloatingDustParticles_NoiseGrid_Backlit
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = FloatingParticlesPS;
    }
}
