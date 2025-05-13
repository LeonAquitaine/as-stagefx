///////////////////////////////////////////////////////////////////////////////////
// Fluttering Petals Shader for ReShade
// - New Base from "Fire Particles"
// - Using Texture for Petal Shape (Randomly selects between two textures)
// - Version: Unique Names, FracFix, PointFix, SwayCorrected, AspectCorrect, DualTextureShape
///////////////////////////////////////////////////////////////////////////////////

#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_getTime()

// --- Textures ---
texture PetalFlutter_NoiseSourceTexture < source = "perlin512x8Noise.png"; > { Width = 512; Height = 512; Format = R8; };
sampler PetalFlutter_samplerNoiseSource { Texture = PetalFlutter_NoiseSourceTexture; AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };

// *** Petal Shape Textures ***
texture PetalShape_Texture1 < source = "AS_RedRosePetal1.png"; >
{
    Width = 512;
    Height = 512;
    Format = RGBA8;
};
sampler PetalShape_Sampler1
{
    Texture = PetalShape_Texture1;
    AddressU = CLAMP; AddressV = CLAMP;
    MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR;
};

texture PetalShape_Texture2 < source = "AS_RedRosePetal2.png"; >
{
    Width = 512;
    Height = 512;
    Format = RGBA8;
};
sampler PetalShape_Sampler2
{
    Texture = PetalShape_Texture2;
    AddressU = CLAMP; AddressV = CLAMP;
    MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR;
};


// --- Constants ---
#define PI 3.14159265359
#define TWO_PI (2.0 * PI)

// --- UI Uniforms ---
uniform float3 PetalColor < ui_type = "color"; ui_label = "Petal Tint Color"; ui_tooltip = "Modulates the petal texture's color. White = original texture color."; > = float3(1.0, 1.0, 1.0);
uniform float PetalBaseAlpha < ui_type = "slider"; ui_label = "Petal Base Alpha"; ui_min = 0.0; ui_max = 1.0; > = 0.8;
uniform float DensityThreshold < ui_type = "slider"; ui_label = "Overall Density Threshold (Noise Tex)"; ui_min = 0.0; ui_max = 1.0; ui_tooltip = "Lower = More Dense overall."; > = 0.4;
uniform float DensityFadeRange < ui_type = "slider"; ui_label = "Density Fade Range"; ui_min = 0.01; ui_max = 0.5; > = 0.15;

uniform float PetalBaseSize < ui_type = "slider"; ui_label = "Petal Base Size"; ui_min = 0.001; ui_max = 0.5; ui_step=0.001; > = 0.05; 
uniform float PetalSizeVariation < ui_type = "slider"; ui_label = "Petal Size Variation"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; > = 0.3;

uniform float SimulationSpeed < ui_type = "slider"; ui_label = "Lifecycle/Animation Speed"; ui_min = 0.0; ui_max = 2.0; > = 0.5;
uniform float BasePetalSpinSpeed < ui_type = "slider"; ui_label = "Base Petal Spin Speed"; ui_min = 0.0; ui_max = 10.0; > = 1.5;
uniform float BaseDriftSpeed < ui_type = "slider"; ui_label = "Base Layer Drift Speed"; ui_min = 0.0; ui_max = 2.0; ui_step=0.01; > = 0.1;
uniform float2 UserDirection < ui_type = "slider"; ui_label = "General Drift Direction (X, Y)"; ui_min = -1.0; ui_max = 1.0; > = float2(0.1, -0.3);
uniform float BaseFlutterStrength < ui_type = "slider"; ui_label = "Flutter Strength (UV Noise)"; ui_min = 0.0; ui_max = 0.2; ui_step = 0.005; > = 0.02;

uniform float NoiseTexScale < ui_type = "slider"; ui_label = "Density Noise Texture Scale"; ui_min = 0.1; ui_max = 10.0; > = 2.5;
uniform float Lifetime < ui_type = "slider"; ui_label = "Petal Lifetime (seconds)"; ui_min = 1.0; ui_max = 20.0; > = 10.0;

// Layering controls
uniform int NumLayers < ui_type = "slider"; ui_label = "Number of Petal Layers"; ui_min = 1; ui_max = 30; > = 15;
uniform float LayerSizeMod < ui_type = "slider"; ui_label = "Layer Size Modifier (Perspective)"; ui_min = 0.8; ui_max = 1.2; ui_step=0.01; > = 1.05;
uniform float LayerAlphaMod < ui_type = "slider"; ui_label = "Layer Alpha Modifier (Depth Fade)"; ui_min = 0.7; ui_max = 1.0; ui_step=0.01; > = 0.85;

// Voronoi animation control
uniform float VoronoiPointSpinSpeed < ui_type = "slider"; ui_label = "Voronoi Point Spin Speed"; ui_min = 0.0; ui_max = 5.0; > = 0.3;

// Sway uniform
uniform float SwayMagnitude < ui_type = "slider"; ui_label = "Sway Magnitude"; ui_min = 0.0; ui_max = 0.05; ui_step = 0.001; > = 0.005;


uniform int DebugMode <
    ui_type = "combo"; ui_label = "Debug View";
    ui_items = "0: Normal Effect\0"
               "1: Density Factor (Noise Tex)\0"
               "2: Voronoi Cells (rootUV hash)\0"
               "3: Single Petal Alpha (Layer 0)\0"
               "4: Layer 0 Flutter Offset UVs\0"
               "5: Show Petal Texture Alpha (Test)\0"; 
    ui_tooltip = "Show intermediate calculation results.";
> = 0;


// --- Procedural Noise Functions ---
float hash1_2(float2 x) { float val = sin(dot(x, float2(52.127, 61.2871))) * 521.582; return val - floor(val); }
float2 hash2_2(float2 p) { float2 m_col0 = float2(20.52, 70.291); float2 m_col1 = float2(24.1994, 80.171); float2 transformed_p = float2(dot(p, m_col0), dot(p, m_col1)); float2 val = sin(transformed_p) * 492.194; return val - floor(val); }
float2 procNoise2_2(float2 uv) { float2 fract_uv = uv - floor(uv); float2 f = smoothstep(0.0, 1.0, fract_uv); float2 uv00 = floor(uv); float2 v00 = hash2_2(uv00); float2 v01 = hash2_2(uv00 + float2(0,1)); float2 v10 = hash2_2(uv00 + float2(1,0)); float2 v11 = hash2_2(uv00 + float2(1,1)); float2 v0 = lerp(v00, v01, f.y); float2 v1 = lerp(v10, v11, f.y); return lerp(v0, v1, f.x); }

// --- Helper Functions ---
float2 ps_rotate(float2 p_to_rotate, float rad) { float s = sin(rad); float c = cos(rad); return float2(p_to_rotate.x * c - p_to_rotate.y * s, p_to_rotate.x * s + p_to_rotate.y * c); }

// --- SDF Functions (Kept for reference/fallback, but not used by default) ---
// float sdHeart_User(float2 p) { ... }
// float sdRosePetal(float2 p) { ... }


// --- Voronoi and Particle Drawing ---
float degToRad(float deg) { return deg * PI / 180.0; }
float calcVoronoiPointRotRad(float2 rootUV, float time) { return time * VoronoiPointSpinSpeed * (hash1_2(rootUV) - 0.5) * 2.0 * TWO_PI; }
float2 getVoronoiPoint(float2 rootUV, float rad) { float2 calculatedPt = hash2_2(rootUV) - 0.5; calculatedPt = ps_rotate(calculatedPt, rad) * 0.66; calculatedPt += rootUV + float2(0.5, 0.5); return calculatedPt; }

float4 DrawPetalInstance(float2 uvForVoronoiLookup, float2 originalScreenUV, float instanceSeed, float currentTime, float currentLayerAlphaMod, float2 driftVelocityForSway) { 
    float2 rootUV = floor(uvForVoronoiLookup);
    float voronoiPointRotRad = calcVoronoiPointRotRad(rootUV, currentTime);
    float2 petalInstanceCenter_NoSway = getVoronoiPoint(rootUV, voronoiPointRotRad);

    float swayTime = currentTime * SimulationSpeed * 0.7 + instanceSeed * 5.0;
    float swayAngle_calc = swayTime * (1.5 + hash1_2(rootUV + 0.3) * 1.5) + hash1_2(rootUV + instanceSeed * 0.7) * TWO_PI;
    float2 swayDirVec = float2(driftVelocityForSway.y, -driftVelocityForSway.x); 
    if (length(swayDirVec) < 0.001) swayDirVec = float2(1.0, 0.0); 
    else swayDirVec = normalize(swayDirVec);
    float2 swayOffset = swayDirVec * sin(swayAngle_calc) * SwayMagnitude;
    float2 finalPetalInstanceCenter = petalInstanceCenter_NoSway + swayOffset;

    float timeOffset = hash1_2(rootUV + instanceSeed) * Lifetime;
    float instanceTimeRaw = (currentTime * SimulationSpeed + timeOffset);
    float time_val = instanceTimeRaw / Lifetime;
    float normalizedTime = time_val - floor(time_val); 

    float fadeIn = smoothstep(0.0, 0.20, normalizedTime); 
    float fadeOut = smoothstep(1.0, 0.80, normalizedTime); 
    float lifetimeAlpha = fadeIn * fadeOut;

    if (lifetimeAlpha <= 0.001) {
        return float4(0.0, 0.0, 0.0, 0.0);
    }

    float2 petalSpaceUV_raw = uvForVoronoiLookup - finalPetalInstanceCenter;
    float petalRandomFactor = hash1_2(rootUV + instanceSeed * 0.31); 
    
    float spinAngle = instanceTimeRaw * BasePetalSpinSpeed * (0.75 + petalRandomFactor * 0.5);
    spinAngle += petalRandomFactor * TWO_PI; 
    float2 rotatedPetalSpaceUV = ps_rotate(petalSpaceUV_raw, spinAngle);

    float sizeVariation = (petalRandomFactor - 0.5) * 2.0 * PetalSizeVariation;
    float currentPetalVisualSize = PetalBaseSize * (1.0 + sizeVariation); 
    if (currentPetalVisualSize <= 0.0001) currentPetalVisualSize = 0.0001;
    
    float2 texLookupUV = (rotatedPetalSpaceUV / currentPetalVisualSize) + 0.5;

    // *** Randomly select petal texture ***
    float4 petalTextureSample;
    if (petalRandomFactor < 0.5) { // Use petalRandomFactor (0-1) to choose
        petalTextureSample = tex2D(PetalShape_Sampler1, texLookupUV);
    } else {
        petalTextureSample = tex2D(PetalShape_Sampler2, texLookupUV);
    }
    
    float3 colorFromTexture = petalTextureSample.rgb;
    float petalShapeAlpha = petalTextureSample.a;

    float screenFade = 1.0; 

    float finalAlpha = petalShapeAlpha * lifetimeAlpha * PetalBaseAlpha * currentLayerAlphaMod * screenFade;
    float3 finalPetalRgb = colorFromTexture * PetalColor.rgb;

    return float4(finalPetalRgb, finalAlpha);
}

float4 RenderPetalLayers(float2 baseCenteredAspectUV, float2 originalScreenUV, float currentTime) { 
    float4 accumulatedColor = float4(0.0, 0.0, 0.0, 0.0);
    float currentLayerSizeFactor = 1.0; 
    float currentLayerAlphaFactor = 1.0; 
    float2 layerGlobalOffset = float2(0.0, 0.0); 
    
    for (int i = 0; i < NumLayers; i++) {
        float2 flutterOffset = (procNoise2_2(baseCenteredAspectUV * currentLayerSizeFactor * 2.0 + currentTime * 0.2 + float(i)*0.1) - 0.5) * BaseFlutterStrength * currentLayerSizeFactor;
        float2 driftVelocity = UserDirection * BaseDriftSpeed * (1.0 / currentLayerSizeFactor); 
        float2 driftOffset = currentTime * driftVelocity;
        
        float2 uvForVoronoiLookup = (baseCenteredAspectUV * currentLayerSizeFactor) + driftOffset + layerGlobalOffset + flutterOffset;
        
        float4 petalLayerColor = DrawPetalInstance(uvForVoronoiLookup, originalScreenUV, float(i) * 0.123, currentTime, currentLayerAlphaFactor, driftVelocity);

        accumulatedColor.rgb = lerp(accumulatedColor.rgb, petalLayerColor.rgb, petalLayerColor.a);
        accumulatedColor.a += petalLayerColor.a * (1.0 - accumulatedColor.a);

        currentLayerAlphaFactor *= LayerAlphaMod;
        currentLayerSizeFactor *= LayerSizeMod; 
        layerGlobalOffset += hash2_2(float2(currentLayerAlphaFactor, currentLayerSizeFactor)) * 0.3; 
    }
    
    return accumulatedColor;
}

// --- Main Pixel Shader ---
float4 PS_Main(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, uv);
    float currentTime = AS_getTime();

    float2 centeredAspectUV = uv - 0.5;
    centeredAspectUV.x *= ReShade::ScreenSize.x / ReShade::ScreenSize.y;

    switch(DebugMode) {
        case 1: 
            float densityNoise = tex2D(PetalFlutter_samplerNoiseSource, uv * NoiseTexScale + currentTime * 0.01).r;
            float dFactor = smoothstep(DensityThreshold - DensityFadeRange * 0.5, DensityThreshold + DensityFadeRange * 0.5, densityNoise);
            return float4(dFactor.rrr, 1.0);
        case 2: 
            float voronoiGridScale = 10.0; 
            float2 rootVis = floor(centeredAspectUV * voronoiGridScale); 
            float h1 = hash1_2(rootVis);
            float h2 = hash1_2(rootVis + float2(17.3, 3.7));
            return float4(h1, h2, hash1_2(rootVis + h1), 1.0);
        case 3: 
            float4 singlePetal = DrawPetalInstance(centeredAspectUV, uv, 0.0, currentTime, 1.0, UserDirection * BaseDriftSpeed); 
            return float4(singlePetal.aaa, 1.0);
        case 4: 
             float Layer0SizeFactor = 1.0; 
             float2 pNoiseOffset = (procNoise2_2(centeredAspectUV * Layer0SizeFactor * 2.0 + currentTime * 0.2) - 0.5) * BaseFlutterStrength * Layer0SizeFactor; 
             return float4(pNoiseOffset.x + 0.5, pNoiseOffset.y + 0.5, 0.0, 1.0); 
        case 5: // Show Petal Texture Alpha (Test for a single instance)
            float4 texPetal = DrawPetalInstance(centeredAspectUV, uv, 0.0, currentTime, 1.0, UserDirection * BaseDriftSpeed);
            // Display the RGB of the texture multiplied by its alpha to see the actual colored shape
            return float4(texPetal.rgb * texPetal.a, texPetal.a); 

        case 0: 
        default:
            float4 layeredPetalColor = RenderPetalLayers(centeredAspectUV, uv, currentTime); 
            float densityTexNoiseVal = tex2D(PetalFlutter_samplerNoiseSource, uv * NoiseTexScale + currentTime * 0.01).r; 
            float globalDensityFactor = smoothstep(DensityThreshold - DensityFadeRange * 0.5, DensityThreshold + DensityFadeRange * 0.5, densityTexNoiseVal);
            layeredPetalColor.a *= globalDensityFactor;
            originalColor.rgb = lerp(originalColor.rgb, layeredPetalColor.rgb, layeredPetalColor.a);
            return originalColor;
    }
}

// --- Technique Definition ---
technique FlutteringPetals_NewBase_DualTexture < 
    ui_tooltip = "Petal effect - New Base using two Petal Textures randomly.";
> {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_Main;
    }
}