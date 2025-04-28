/**
 * AS_CN-Glitter.1.fx - Dynamic Sparkle Effect Shader Version 1.0
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader creates a realistic glitter/sparkle effect that dynamically responds to scene
 * lighting, depth, and camera movement. It simulates tiny reflective particles that pop in,
 * glow, and fade out, creating the appearance of sparkles on surfaces.
 *
 * FEATURES:
 * - Multi-layered voronoi noise for natural sparkle distribution
 * - Dynamic sparkle animation with customizable lifetime
 * - Depth-based masking for placement control
 * - High-quality bloom with adjustable quality settings
 * - Normal-based fresnel effect for realistic light interaction
 * - Multiple blend modes and color options
 * - Audio-reactive sparkle intensity and animation via Listeningway
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. The shader uses multiple layers of Voronoi noise at different scales to generate the base sparkle pattern
 * 2. Each sparkle has its own lifecycle (fade in, sustain, fade out) based on its position and the animation time
 * 3. Surface normals are reconstructed from the depth buffer to apply fresnel effects, making sparkles appear more prominently at glancing angles
 * 4. A two-pass gaussian bloom is applied for a soft, natural glow effect
 * 5. Multiple blend modes allow for different integration with the scene
 * 
 * ===================================================================================
 */

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "AS_Utils.1.fxh"

// --- Tunable Constants ---
static const float GLITTERDENSITY_MIN = 0.1;
static const float GLITTERDENSITY_MAX = 20.0;
static const float GLITTERDENSITY_DEFAULT = 10.0;
static const float GLITTERSIZE_MIN = 0.1;
static const float GLITTERSIZE_MAX = 10.0;
static const float GLITTERSIZE_DEFAULT = 5.0;
static const float GLITTERBRIGHTNESS_MIN = 0.1;
static const float GLITTERBRIGHTNESS_MAX = 12.0;
static const float GLITTERBRIGHTNESS_DEFAULT = 6.0;
static const float GLITTERSHARPNESS_MIN = 0.1;
static const float GLITTERSHARPNESS_MAX = 2.1;
static const float GLITTERSHARPNESS_DEFAULT = 1.1;
static const float GLITTERSPEED_MIN = 0.1;
static const float GLITTERSPEED_MAX = 1.5;
static const float GLITTERSPEED_DEFAULT = 0.8;
static const float GLITTERLIFETIME_MIN = 1.0;
static const float GLITTERLIFETIME_MAX = 20.0;
static const float GLITTERLIFETIME_DEFAULT = 10.0;
static const float BLOOMINTENSITY_MIN = 0.1;
static const float BLOOMINTENSITY_MAX = 3.1;
static const float BLOOMINTENSITY_DEFAULT = 1.6;
static const float BLOOMRADIUS_MIN = 1.0;
static const float BLOOMRADIUS_MAX = 10.2;
static const float BLOOMRADIUS_DEFAULT = 5.6;
static const float BLOOMDISPERSION_MIN = 1.0;
static const float BLOOMDISPERSION_MAX = 3.0;
static const float BLOOMDISPERSION_DEFAULT = 2.0;
static const float NEARPLANE_MIN = 0.0;
static const float NEARPLANE_MAX = 1.0;
static const float NEARPLANE_DEFAULT = 0.0;
static const float FARPLANE_MIN = 0.0;
static const float FARPLANE_MAX = 1.0;
static const float FARPLANE_DEFAULT = 1.0;
static const float DEPTHCURVE_MIN = 0.1;
static const float DEPTHCURVE_MAX = 10.0;
static const float DEPTHCURVE_DEFAULT = 1.0;
static const float BLENDAMOUNT_MIN = 0.0;
static const float BLENDAMOUNT_MAX = 1.0;
static const float BLENDAMOUNT_DEFAULT = 1.0;
static const float TIMESCALE_MIN = 1.0;
static const float TIMESCALE_DEFAULT = 9.0;
static const float TIMESCALE_MAX = 20.0;

// --- Sparkle Appearance ---
uniform float GlitterDensity < ui_type = "slider"; ui_label = "Density"; ui_tooltip = "Controls how many sparkles are generated on the screen. Higher values increase the number of sparkles."; ui_min = GLITTERDENSITY_MIN; ui_max = GLITTERDENSITY_MAX; ui_step = 0.1; ui_category = "Sparkle Appearance"; > = GLITTERDENSITY_DEFAULT;
uniform float GlitterSize < ui_type = "slider"; ui_label = "Size"; ui_tooltip = "Adjusts the size of each individual sparkle. Larger values make sparkles appear bigger."; ui_min = GLITTERSIZE_MIN; ui_max = GLITTERSIZE_MAX; ui_step = 0.1; ui_category = "Sparkle Appearance"; > = GLITTERSIZE_DEFAULT;
uniform float GlitterBrightness < ui_type = "slider"; ui_label = "Brightness"; ui_tooltip = "Sets the overall brightness of the sparkles. Higher values make sparkles more intense and visible."; ui_min = GLITTERBRIGHTNESS_MIN; ui_max = GLITTERBRIGHTNESS_MAX; ui_step = 0.1; ui_category = "Sparkle Appearance"; > = GLITTERBRIGHTNESS_DEFAULT;
uniform float GlitterSharpness < ui_type = "slider"; ui_label = "Sharpness"; ui_tooltip = "Controls how crisp or soft the edges of sparkles appear. Higher values make sparkles more defined."; ui_min = GLITTERSHARPNESS_MIN; ui_max = GLITTERSHARPNESS_MAX; ui_step = 0.05; ui_category = "Sparkle Appearance"; > = GLITTERSHARPNESS_DEFAULT;

// --- Animation ---
uniform float GlitterSpeed < ui_type = "slider"; ui_label = "Speed"; ui_tooltip = "Sets how quickly sparkles animate and move. Higher values increase animation speed."; ui_min = GLITTERSPEED_MIN; ui_max = GLITTERSPEED_MAX; ui_step = 0.05; ui_category = "Animation"; > = GLITTERSPEED_DEFAULT;
uniform float GlitterLifetime < ui_type = "slider"; ui_label = "Lifetime"; ui_tooltip = "Determines how long each sparkle remains visible before fading out."; ui_min = GLITTERLIFETIME_MIN; ui_max = GLITTERLIFETIME_MAX; ui_step = 0.1; ui_category = "Animation"; > = GLITTERLIFETIME_DEFAULT;
uniform float TimeScale < ui_type = "slider"; ui_label = "Time Scale"; ui_tooltip = "Scales the overall animation timing for all sparkles. Use to speed up or slow down the effect globally."; ui_min = TIMESCALE_MIN; ui_max = TIMESCALE_MAX; ui_step = 0.5; ui_category = "Animation"; > = TIMESCALE_DEFAULT;

// --- Bloom Effect ---
uniform bool EnableBloom < ui_label = "Bloom"; ui_tooltip = "Enables or disables the bloom (glow) effect around sparkles for a softer, more radiant look."; ui_category = "Bloom Effect"; > = true;
uniform float BloomIntensity < ui_type = "slider"; ui_label = "Intensity"; ui_tooltip = "Controls how strong the bloom (glow) effect appears around sparkles."; ui_min = BLOOMINTENSITY_MIN; ui_max = BLOOMINTENSITY_MAX; ui_step = 0.05; ui_category = "Bloom Effect"; ui_spacing = 1; ui_bind = "EnableBloom"; > = BLOOMINTENSITY_DEFAULT;
uniform float BloomRadius < ui_type = "slider"; ui_label = "Radius"; ui_tooltip = "Sets how far the bloom effect extends from each sparkle. Larger values create a wider glow."; ui_min = BLOOMRADIUS_MIN; ui_max = BLOOMRADIUS_MAX; ui_step = 0.2; ui_category = "Bloom Effect"; ui_bind = "EnableBloom"; > = BLOOMRADIUS_DEFAULT;
uniform float BloomDispersion < ui_type = "slider"; ui_label = "Dispersion"; ui_tooltip = "Adjusts how quickly the bloom fades at the edges. Higher values make the glow softer and more gradual."; ui_min = BLOOMDISPERSION_MIN; ui_max = BLOOMDISPERSION_MAX; ui_step = 0.05; ui_category = "Bloom Effect"; ui_bind = "EnableBloom"; > = BLOOMDISPERSION_DEFAULT;
uniform int BloomQuality < ui_type = "combo"; ui_label = "Quality"; ui_tooltip = "Selects the quality level for the bloom effect. Higher quality reduces artifacts but may impact performance."; ui_items = "Potato\0Low\0Medium\0High\0Ultra\0AI Overlord\0"; ui_category = "Bloom Effect"; ui_bind = "EnableBloom"; > = 2;
uniform bool BloomDither < ui_label = "Dither"; ui_tooltip = "Adds subtle noise to the bloom to reduce color banding and grid patterns."; ui_category = "Bloom Effect"; ui_bind = "EnableBloom"; > = true;

// --- Color Settings ---
uniform float3 GlitterColor < ui_type = "color"; ui_label = "Color"; ui_tooltip = "Sets the base color of all sparkles."; ui_category = "Color Settings"; > = float3(1.0, 1.0, 1.0);
uniform bool DepthColoringEnable < ui_label = "Depth Color"; ui_tooltip = "If enabled, sparkles will change color based on their distance from the camera."; ui_category = "Color Settings"; > = true;
uniform float3 NearColor < ui_type = "color"; ui_label = "Near Color"; ui_tooltip = "Color for sparkles close to the camera."; ui_category = "Color Settings"; > = float3(1.0, 204/255.0, 153/255.0);
uniform float3 FarColor < ui_type = "color"; ui_label = "Far Color"; ui_tooltip = "Color for sparkles far from the camera."; ui_category = "Color Settings"; > = float3(153/255.0, 204/255.0, 1.0);

// --- Audio Reactivity ---

AS_AUDIO_SOURCE_UI(Listeningway_SparkleSource, "Sparkle Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(Listeningway_SparkleMultiplier, "Sparkle Intensity", 1.5, 5.0, "Audio Reactivity")
AS_AUDIO_SOURCE_UI(Listeningway_BloomSource, "Bloom Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(Listeningway_BloomMultiplier, "Bloom Intensity", 10.0, 10.0, "Audio Reactivity")
AS_AUDIO_SOURCE_UI(Listeningway_TimeScaleSource, "Time Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(Listeningway_TimeScaleBand1Multiplier, "Time Intensity", 1.0, 5.0, "Audio Reactivity")

// --- Depth Masking ---
uniform float NearPlane < ui_type = "slider"; ui_label = "Near"; ui_tooltip = "Controls the minimum distance from the camera where sparkles can appear. Lower values allow sparkles closer to the camera."; ui_min = NEARPLANE_MIN; ui_max = NEARPLANE_MAX; ui_step = 0.01; ui_category = "Depth Masking"; > = NEARPLANE_DEFAULT;
uniform float FarPlane < ui_type = "slider"; ui_label = "Far"; ui_tooltip = "Controls the maximum distance from the camera where sparkles can appear. Lower values bring the cutoff closer."; ui_min = FARPLANE_MIN; ui_max = FARPLANE_MAX; ui_step = 0.01; ui_category = "Depth Masking"; > = FARPLANE_DEFAULT;
uniform float DepthCurve < ui_type = "slider"; ui_label = "Curve"; ui_tooltip = "Adjusts how quickly sparkles fade out with distance. Higher values make the fade sharper."; ui_min = DEPTHCURVE_MIN; ui_max = DEPTHCURVE_MAX; ui_step = 0.1; ui_category = "Depth Masking"; > = DEPTHCURVE_DEFAULT;
uniform bool AllowInfiniteCutoff < ui_label = "Infinite Cutoff"; ui_tooltip = "If enabled, sparkles can appear all the way to the horizon. If disabled, sparkles beyond the cutoff distance are hidden."; ui_category = "Depth Masking"; > = true;

// --- Occlusion Control ---
uniform bool ObeyOcclusion < ui_label = "Occlusion"; ui_tooltip = "If enabled, sparkles and bloom will be masked by scene depth, so they do not appear through objects."; ui_category = "Effect Control"; > = true;

// --- Performance ---
uniform int PerformancePreset < ui_type = "combo"; ui_label = "Performance Mode"; ui_tooltip = "Preset that balances quality and performance. Lower settings improve FPS at the cost of visual quality."; ui_items = "Ultra (Best Quality)\0High\0Medium\0Low\0Potato (Best Performance)\0"; ui_category = "Performance"; > = 2; // Medium default

uniform bool UseAdvancedPerformanceOptions < ui_label = "Show Advanced Options"; ui_tooltip = "Enable to fine-tune individual performance settings"; ui_category = "Performance"; > = false;

uniform int SparkleQuality < ui_type = "combo"; ui_label = " Sparkle Quality"; ui_tooltip = "Controls the complexity of sparkle generation. Lower settings reduce the number of calculation layers."; ui_items = "High (3 layers)\0Medium (2 layers)\0Low (1 layer)\0"; ui_category = "Performance"; ui_bind = "UseAdvancedPerformanceOptions"; > = 0;

uniform int BloomBufferQuality < ui_type = "combo"; ui_label = " Bloom Resolution"; ui_tooltip = "Controls the resolution of bloom buffers. Lower settings increase performance by reducing pixel count."; ui_items = "Full\0Half\0Quarter\0Eighth\0"; ui_category = "Performance"; ui_bind = "UseAdvancedPerformanceOptions"; > = 1; // Half resolution by default

uniform int SamplingQuality < ui_type = "combo"; ui_label = " Sampling Detail"; ui_tooltip = "Controls the number of samples for bloom calculations. Lower settings greatly improve performance by taking fewer samples."; ui_items = "Ultra\0High\0Medium\0Low\0Minimum\0"; ui_category = "Performance"; ui_bind = "UseAdvancedPerformanceOptions"; > = 2;

uniform bool EnableDither < ui_label = " Dithering"; ui_tooltip = "Adds subtle noise to reduce banding. Small performance cost but improves visual quality."; ui_category = "Performance"; ui_bind = "UseAdvancedPerformanceOptions"; > = true;

uniform bool EnableStarSparkles < ui_label = " Star Sparkles"; ui_tooltip = "When enabled, adds special star-shaped sparkles. Disable for better performance."; ui_category = "Performance"; ui_bind = "UseAdvancedPerformanceOptions"; > = true;

uniform bool SkipFresnel < ui_label = " Skip Normal Reconstruction"; ui_tooltip = "When enabled, skips normal reconstruction and fresnel calculations for a significant performance boost."; ui_category = "Performance"; ui_bind = "UseAdvancedPerformanceOptions"; > = false;

// --- Final Mix ---
uniform int BlendMode < ui_type = "combo"; ui_label = "Mode"; ui_items = "Normal\0Lighter Only\0Darker Only\0Additive\0Multiply\0Screen\0"; ui_category = "Final Mix"; > = 0;
uniform float BlendAmount < ui_type = "slider"; ui_label = "Strength"; ui_tooltip = "How strongly the effect is blended with the scene."; ui_min = BLENDAMOUNT_MIN; ui_max = BLENDAMOUNT_MAX; ui_step = 0.01; ui_category = "Final Mix"; > = BLENDAMOUNT_DEFAULT;

// --- Debug ---
AS_DEBUG_MODE_UI("Off\0Depth\0Normals\0Sparkle Intensity\0Depth Mask\0Force Enable\0")

// --- System Uniforms ---


// --- Textures and Samplers ---
texture GlitterRT { 
    Width = BUFFER_WIDTH; 
    Height = BUFFER_HEIGHT; 
    Format = RGBA16F; 
};
sampler GlitterSampler { Texture = GlitterRT; };

texture GlitterBloomRT { 
    Width = BUFFER_WIDTH * 0.5; 
    Height = BUFFER_HEIGHT * 0.5; 
    Format = RGBA16F; 
};
sampler GlitterBloomSampler { 
    Texture = GlitterBloomRT; 
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = LINEAR;
};

// --- Helper Functions ---
namespace AS_Glitter {
    // Layer properties
    static const float SPARKLE_LAYER_SIZES[3]   = {0.05, 0.03, 0.02};
    static const float SPARKLE_LAYER_WEIGHTS[3] = {1.0, 0.7, 0.3};
    static const float SPARKLE_LAYER_SPEEDS[3]  = {1.0, 1.2, 0.8};
    static const float SPARKLE_LAYER_POWS[3]    = {0.5, 0.7, 0.9};

    // Gaussian distribution function for bloom
    float Gaussian(float x, float sigma) {
        return (1.0 / (sqrt(2.0 * AS_PI) * sigma)) * exp(-(x * x) / (2.0 * sigma * sigma));
    }
    
    // Get bloom step size based on quality setting
    float getBloomStepSize(int quality) {
        switch(quality) {
            case 0: return 4.0;
            case 1: return 2.0;
            case 2: return 1.0;
            case 3: return 0.5;
            case 4: return 0.25;
            case 5: return 0.125;
            default: return 1.0;
        }
    }

    // Get number of layers based on performance setting
    int getVoronoiLayers(int perf) {
        if (perf >= 3) return 1; // Low/Potato: 1 layer
        if (perf == 2) return 2; // Medium: 2 layers
        return 3; // High/Ultra: 3 layers
    }
    
    // Get bloom buffer scale factor based on performance setting
    float getBloomBufferScale(int perf) {
        if (perf >= 3) return 0.25; // Low/Potato: quarter res
        if (perf == 2) return 0.5; // Medium: half res
        return 1.0; // High/Ultra: full res
    }
    
    // Adjust bloom step size based on performance preset
    float getBloomStepSizePerf(int perf, int quality) {
        float base = getBloomStepSize(quality);
        if (perf >= 3) return base * 2.0; // Fewer samples for low
        return base;
    }

    // Dither noise calculation for bloom
    float2 calculateDitherNoise(float2 texcoord, float2 seeds, float stepSize) {
        float2 noise = frac(sin(dot(texcoord, seeds)) * 43758.5453);
        noise = noise * 2.0 - 1.0;
        noise *= 0.25 * stepSize;
        return noise;
    }
    
    // Voronoi noise generation for sparkle patterns
    float2 voronoi(float2 x, float offset) {
        float2 n = floor(x);
        float2 f = frac(x);
        float2 mg, mr;
        float md = 8.0;
        
        [unroll]
        for(int j = -1; j <= 1; j++) {
            [unroll]
            for(int i = -1; i <= 1; i++) {
                float2 g = float2(float(i), float(j));
                float2 o = AS_hash33(float3(n + g, AS_hash21(n + g).x * 10.0 + offset)).xy * 0.5 + 0.5;
                float2 r = g + o - f;
                float d = dot(r, r);
                if(d < md) { md = d; mr = r; mg = g; }
            }
        }
        return float2(sqrt(md), AS_hash21(n + mg).x);
    }
    
    // Calculate sparkle lifecycle (fade in/out)
    float calculateSparkleLifecycle(float time, float sparkleID, float speedMod, float lifeDuration) {
        float cycle = frac((time * speedMod + sparkleID * (10.0 + 5.0 * speedMod)) / lifeDuration);
        float fadeInEnd = 0.2;
        float fadeOutStart = 0.8;
        float brightness = 1.0;
        if (cycle < fadeInEnd) {
            brightness = smoothstep(0.0, fadeInEnd, cycle) / fadeInEnd;
        } else if (cycle > fadeOutStart) {
            brightness = 1.0 - smoothstep(fadeOutStart, 1.0, cycle) / (1.0 - fadeOutStart);
        }
        return brightness;
    }
    
    // Star shape generator for high-quality sparkles
    float star(float2 p, float size, float points, float angle) {
        float2 uv = p; float a = atan2(uv.y, uv.x) + angle; float r = length(uv);
        float f = cos(a * points) * 0.5 + 0.5;
        return 1.0 - smoothstep(f * size, f * size + 0.01, r);
    }
    
    // Get effective sparkle quality based on preset or manual setting
    int getEffectiveSparkleQuality() {
        if (!UseAdvancedPerformanceOptions) {
            // Map from performance preset to sparkle quality
            if (PerformancePreset <= 1) return 0; // Ultra/High → 3 layers
            if (PerformancePreset == 2) return 1; // Medium → 2 layers
            return 2; // Low/Potato → 1 layer
        }
        return SparkleQuality;
    }
    
    // Get the effective bloom buffer scale factor
    float getEffectiveBloomBufferScale() {
        if (!UseAdvancedPerformanceOptions) {
            // Map from performance preset to bloom buffer scale
            if (PerformancePreset <= 1) return 1.0; // Ultra/High → Full res
            if (PerformancePreset == 2) return 0.5; // Medium → Half res
            if (PerformancePreset == 3) return 0.25; // Low → Quarter res
            return 0.125; // Potato → Eighth res
        }
        
        // Use the user-selected value from the advanced options
        switch (BloomBufferQuality) {
            case 0: return 1.0;   // Full
            case 1: return 0.5;   // Half
            case 2: return 0.25;  // Quarter
            case 3: return 0.125; // Eighth
            default: return 0.5;  // Default to half res
        }
    }
    
    // Get effective sampling quality
    float getEffectiveSamplingStep() {
        if (!UseAdvancedPerformanceOptions) {
            // Map from performance preset to sampling quality
            if (PerformancePreset == 0) return 0.125; // Ultra → Very dense sampling (8 samples per unit)
            if (PerformancePreset == 1) return 0.25;  // High → Dense sampling (4 samples per unit)
            if (PerformancePreset == 2) return 0.5;   // Medium → Normal sampling (2 samples per unit)
            if (PerformancePreset == 3) return 1.0;   // Low → Sparse sampling (1 sample per unit)
            return 2.0;  // Potato → Very sparse sampling (1 sample per 2 units)
        }
        
        // Use the user-selected value
        switch (SamplingQuality) {
            case 0: return 0.125; // Ultra
            case 1: return 0.25;  // High
            case 2: return 0.5;   // Medium
            case 3: return 1.0;   // Low
            case 4: return 2.0;   // Minimum
            default: return 0.5;  // Default
        }
    }
    
    // Get whether to use star-shaped sparkles
    bool getUseStarSparkles() {
        if (!UseAdvancedPerformanceOptions) {
            // Only use stars in Ultra and High quality
            return PerformancePreset <= 1;
        }
        return EnableStarSparkles;
    }
    
    // Get whether to skip fresnel/normal calculations
    bool getShouldSkipFresnel() {
        if (!UseAdvancedPerformanceOptions) {
            // Skip in low and potato modes
            return PerformancePreset >= 3;
        }
        return SkipFresnel;
    }
    
    // Get whether to use dithering
    bool getShouldUseDither() {
        if (!UseAdvancedPerformanceOptions) {
            // Use dither in all but potato mode
            return PerformancePreset < 4;
        }
        return EnableDither;
    }
    
    // Get number of voronoi layers to use
    int getVoronoiLayers() {
        int quality = getEffectiveSparkleQuality();
        return 3 - quality; // 3 layers for High, 2 for Medium, 1 for Low
    }
    
    // Simplified version of sparkle calculation for low-end devices
    float simpleSparkle(float2 uv, float time) {
        float2 n = floor(uv * GlitterDensity);
        float id = AS_hash21(n).x;
        float phase = frac(time * 0.5 + id * 10.0);
        float brightness = 1.0;
        
        // Simple fade-in/fade-out
        if (phase < 0.2) {
            brightness = phase / 0.2;
        } else if (phase > 0.8) {
            brightness = (1.0 - phase) / 0.2;
        }
        
        float2 f = frac(uv * GlitterDensity) - 0.5;
        float sparkle = (1.0 - smoothstep(0.0, 0.05 * GlitterSize, dot(f, f))) * brightness;
        return sparkle * GlitterDensity * 0.1;
    }
    
    // Choose which sparkle algorithm to use based on quality
    float sparkle(float2 uv, float time) {
        // For lowest quality setting, use the simplified algorithm
        if (PerformancePreset >= 4 && !UseAdvancedPerformanceOptions) {
            return simpleSparkle(uv, time);
        }
        
        float sparkleSum = 0.0;
        float2 voronoiResult;
        float sparkleScale = GlitterSize * 0.4;
        float sharpnessFactor = GlitterSharpness;
        float lifeDuration = 1.0 + GlitterLifetime * 0.2;
        
        // Use the effective layer count
        int layers = getVoronoiLayers();
        
        for (int layer = 0; layer < layers; ++layer) {
            voronoiResult = voronoi(uv * GlitterDensity * (layer == 0 ? 0.5 : (layer == 1 ? 1.0 : 2.0)), time * (0.1 + 0.05 * layer));
            float sparkleID = voronoiResult.y;
            float dist = voronoiResult.x;
            float brightness = calculateSparkleLifecycle(time, sparkleID, SPARKLE_LAYER_SPEEDS[layer], lifeDuration);
            brightness = pow(brightness, SPARKLE_LAYER_POWS[layer]);
            float sparkleShape = (1.0 - smoothstep(0.0, SPARKLE_LAYER_SIZES[layer] * sparkleScale / sharpnessFactor, dist)) * brightness;
            
            // Only add star shapes in higher quality modes
            if (layer == 0 && getUseStarSparkles() && dist < SPARKLE_LAYER_SIZES[0] * sparkleScale / sharpnessFactor) {
                float starMask = star(uv - (uv - voronoiResult.xy), SPARKLE_LAYER_SIZES[0] * sparkleScale / sharpnessFactor, 4.0, sparkleID * 6.28);
                sparkleShape = max(sparkleShape, starMask * brightness * 2.0);
            }
            
            sparkleSum += sparkleShape * SPARKLE_LAYER_WEIGHTS[layer];
        }
        
        sparkleSum *= GlitterDensity * 0.1;
        return saturate(sparkleSum);
    }
} // end namespace AS_Glitter

// --- Audio Source Helper ---
float GetAudioSource(int source) {
#if defined(LISTENINGWAY_INSTALLED)
    return AS_getAudioSource(source);
#else
    return 0.0;
#endif
}

// --- Main Effects ---
// First pass: Sparkle generation
float4 PS_RenderSparkles(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Get background color and depth
    float4 color = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);
    
    // Handle debug/force enable mode
    bool forceEnable = (DebugMode == 5);
    if (forceEnable) { depth = 0.5; }
    
    // Create depth mask
    float depthMask = AS_depthMask(depth, NearPlane, FarPlane, DepthCurve);
    if (forceEnable) { depthMask = 1.0; }
    
    // Skip if beyond far plane cutoff
    if (!AllowInfiniteCutoff && depth >= FarPlane) {
        return float4(0.0, 0.0, 0.0, 0.0);
    }
    
    // Calculate normals and fresnel if needed
    float3 normal = float3(0, 0, 1);
    float fresnel = 1.0;
    if (!forceEnable && !AS_Glitter::getShouldSkipFresnel()) {
        normal = AS_reconstructNormal(texcoord);
        float3 viewDir = float3(0.0, 0.0, 1.0);
        fresnel = AS_fresnel(normal, viewDir, 5.0);
    }
    
    // Calculate time with audio reactivity
    float actualTimeScale = TimeScale / 333.33;
    actualTimeScale = AS_applyAudioReactivityEx(TimeScale / 333.33, Listeningway_TimeScaleSource, 
                                             Listeningway_TimeScaleBand1Multiplier / 333.33, 
                                             true, 1); // Additive mode, always enable audio
    float time = AS_getTime() * actualTimeScale;
    
    // Generate sparkles
    float positionHash = AS_hash21(floor(texcoord * 10.0)).x * 10.0;
    float2 noiseCoord = texcoord * ReShade::ScreenSize * 0.005;
    float sparkleIntensity = AS_Glitter::sparkle(noiseCoord, positionHash + time);
    
    // Apply audio reactivity to sparkle intensity
    sparkleIntensity = AS_applyAudioReactivity(sparkleIntensity, Listeningway_SparkleSource, 
                                            Listeningway_SparkleMultiplier, true); // Always enable audio
    
    // Apply masking based on occlusion settings
    if (!forceEnable && ObeyOcclusion) { 
        sparkleIntensity *= fresnel * depthMask; 
    }
    else if (!forceEnable && !ObeyOcclusion) { 
        sparkleIntensity *= fresnel; 
    }
    
    // Apply brightness
    sparkleIntensity *= GlitterBrightness;
    
    // Debug visualizations
    if (DebugMode == 1) return float4(depth.xxx, 1.0);
    else if (DebugMode == 2) return float4(normal * 0.5 + 0.5, 1.0);
    else if (DebugMode == 3) return float4(sparkleIntensity.xxx, 1.0);
    else if (DebugMode == 4) return float4(depthMask.xxx, 1.0);
    
    // Calculate sparkle color
    float3 finalGlitterColor = GlitterColor;
    if (DepthColoringEnable && !forceEnable) {
        float depthFactor = smoothstep(NearPlane, FarPlane, depth);
        finalGlitterColor = lerp(NearColor, FarColor, depthFactor);
    }
    
    // Prepare final sparkle contribution
    float3 sparkleContribution = finalGlitterColor * sparkleIntensity * 5.0;
    return float4(sparkleContribution, sparkleIntensity > 0.05 ? 1.0 : 0.0);
}

// Second pass: Horizontal bloom
float4 PS_BloomH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Early return for debug mode
    if (DebugMode > 0 && DebugMode < 5) { 
        return tex2D(GlitterSampler, texcoord); 
    }
    
    // Skip bloom calculation if disabled
    if (!EnableBloom) {
        return float4(0.0, 0.0, 0.0, 0.0);
    }
    
    // Initialize bloom accumulation
    float4 color = float4(0.0, 0.0, 0.0, 0.0);
    float weightSum = 0.0;
    float sigma = BloomRadius / BloomDispersion;
    float bufferScale = AS_Glitter::getEffectiveBloomBufferScale();
    
    // Calculate the number of samples based on bloom radius
    const int MAX_SAMPLES = 9; // Reduced maximum samples
    float sampleStep = max(1.0, floor(BloomRadius * 2.0 / float(MAX_SAMPLES * 2 + 1)));
    
    // Determine if we should use dithering
    float2 noise = float2(1.0, 1.0);
    if (AS_Glitter::getShouldUseDither()) {
        noise = AS_Glitter::calculateDitherNoise(texcoord, float2(12.9898, 78.233), sampleStep);
    }
    
    // Calculate audio-reactive bloom intensity
    float bloomIntensity = BloomIntensity;
    bloomIntensity = AS_applyAudioReactivity(BloomIntensity, Listeningway_BloomSource, 
                                          Listeningway_BloomMultiplier, true); // Always enable audio
    
    // Sample in horizontal direction for Gaussian blur
    for(int i = -MAX_SAMPLES; i <= MAX_SAMPLES; i++) {
        float x = float(i) * sampleStep;
        
        float weight = AS_Glitter::Gaussian(x, sigma);
        weightSum += weight;
        
        float2 sampleOffset = float2(x / (BUFFER_WIDTH * bufferScale), 0.0) * BloomRadius;
        
        if (AS_Glitter::getShouldUseDither()) {
            sampleOffset += float2(noise.x * 0.001, 0.0);
        }
        
        color += tex2D(GlitterSampler, texcoord + sampleOffset) * weight;
    }
    
    // Normalize and apply intensity
    color /= max(weightSum, 1e-6);
    color *= bloomIntensity;
    
    return color;
}

// Third pass: Vertical bloom and final blend
float4 PS_BloomV(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Get original scene color
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    
    // Early return for debug mode
    if (DebugMode > 0 && DebugMode < 5) { 
        return tex2D(GlitterSampler, texcoord); 
    }
    
    // Get sparkles from the first pass
    float3 sparkles = tex2D(GlitterSampler, texcoord).rgb;
    float3 bloom = float3(0.0, 0.0, 0.0);
    
    // Only process bloom if enabled
    if (EnableBloom) {
        // Initialize bloom accumulation
        float4 bloomColor = float4(0.0, 0.0, 0.0, 0.0);
        float weightSum = 0.0;
        float sigma = BloomRadius / BloomDispersion;
        float bufferScale = AS_Glitter::getEffectiveBloomBufferScale();
        
        // Calculate the number of samples based on bloom radius
        const int MAX_SAMPLES = 9; // Reduced maximum samples
        float sampleStep = max(1.0, floor(BloomRadius * 2.0 / float(MAX_SAMPLES * 2 + 1)));
        
        // Determine if we should use dithering
        float2 noise = float2(1.0, 1.0);
        if (AS_Glitter::getShouldUseDither()) {
            noise = AS_Glitter::calculateDitherNoise(texcoord, float2(78.233, 12.9898), sampleStep);
        }
        
        // Sample in vertical direction for Gaussian blur
        for(int i = -MAX_SAMPLES; i <= MAX_SAMPLES; i++) {
            float y = float(i) * sampleStep;
            
            float weight = AS_Glitter::Gaussian(y, sigma);
            weightSum += weight;
            
            float2 sampleOffset = float2(0.0, y / (BUFFER_HEIGHT * bufferScale)) * BloomRadius;
            
            if (AS_Glitter::getShouldUseDither()) {
                sampleOffset += float2(0.0, noise.y * 0.001);
            }
            
            bloomColor += tex2D(GlitterBloomSampler, texcoord + sampleOffset) * weight;
        }
        
        // Normalize bloom contribution
        bloomColor /= max(weightSum, 1e-6);
        bloom = bloomColor.rgb;
    }
    
    // Composite sparkles and bloom over the original scene
    float3 result = originalColor.rgb + sparkles + bloom;
    
    // Apply blend amount
    result = lerp(originalColor.rgb, result, DebugMode == 5 ? 1.0 : BlendAmount);
    
    return float4(result, originalColor.a);
}

// --- Technique Definition ---
technique AS_Glitter < ui_label = "[AS] Cinematic: Glitter"; ui_tooltip = "Adds dynamic sparkles that pop in, glow, and fade out"; > {
    pass RenderSparkles { 
        VertexShader = PostProcessVS; 
        PixelShader = PS_RenderSparkles; 
        RenderTarget = GlitterRT; 
    }
    
    pass BloomH { 
        VertexShader = PostProcessVS; 
        PixelShader = PS_BloomH; 
        RenderTarget = GlitterBloomRT; 
    }
    
    pass BloomV { 
        VertexShader = PostProcessVS; 
        PixelShader = PS_BloomV; 
    }
}