/**
 * AS_Glitter.1.fx - Dynamic Sparkle Effect Shader Version 1.0
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
#include "ListeningwayUniforms.fxh"
#include "AS_Utils.fxh"

/*---------------.
| :: Settings :: |
'---------------*/

// --- Sparkle Appearance ---
uniform float GlitterDensity <
	ui_type = "slider";
	ui_label = "Density";
	ui_tooltip = "Controls how many sparkles are generated on the screen. Higher values increase the number of sparkles.";
	ui_min = 0.1; ui_max = 20.0; ui_step = 0.1;
	ui_category = "Sparkle Appearance";
> = 10.0;
uniform float GlitterSize <
	ui_type = "slider";
	ui_label = "Size";
	ui_tooltip = "Adjusts the size of each individual sparkle. Larger values make sparkles appear bigger.";
	ui_min = 0.1; ui_max = 10.0; ui_step = 0.1;
	ui_category = "Sparkle Appearance";
> = 5.0;
uniform float GlitterBrightness <
	ui_type = "slider";
	ui_label = "Brightness";
	ui_tooltip = "Sets the overall brightness of the sparkles. Higher values make sparkles more intense and visible.";
	ui_min = 0.1; ui_max = 12.0; ui_step = 0.1;
	ui_category = "Sparkle Appearance";
> = 6.0;
uniform float GlitterSharpness <
	ui_type = "slider";
	ui_label = "Sharpness";
	ui_tooltip = "Controls how crisp or soft the edges of sparkles appear. Higher values make sparkles more defined.";
	ui_min = 0.1; ui_max = 2.1; ui_step = 0.05;
	ui_category = "Sparkle Appearance";
> = 1.1;

// --- Animation ---
uniform float GlitterSpeed <
	ui_type = "slider";
	ui_label = "Speed";
	ui_tooltip = "Sets how quickly sparkles animate and move. Higher values increase animation speed.";
	ui_min = 0.1; ui_max = 1.5; ui_step = 0.05;
	ui_category = "Animation";
> = 0.8;
uniform float GlitterLifetime <
	ui_type = "slider";
	ui_label = "Lifetime";
	ui_tooltip = "Determines how long each sparkle remains visible before fading out.";
	ui_min = 1.0; ui_max = 20.0; ui_step = 0.1;
	ui_category = "Animation";
> = 10.0;
uniform float TimeScale <
	ui_type = "slider";
	ui_label = "Time Scale";
	ui_tooltip = "Scales the overall animation timing for all sparkles. Use to speed up or slow down the effect globally.";
	ui_min = 1.0; ui_max = 17.0; ui_step = 0.5;
	ui_category = "Animation";
> = 9.0;
uniform int frameCount < source = "framecount"; >;

// --- Bloom Effect ---
uniform bool EnableBloom <
	ui_label = "Bloom";
	ui_tooltip = "Enables or disables the bloom (glow) effect around sparkles for a softer, more radiant look.";
	ui_category = "Bloom Effect";
> = true;
uniform float BloomIntensity <
	ui_type = "slider";
	ui_label = "Intensity";
	ui_tooltip = "Controls how strong the bloom (glow) effect appears around sparkles.";
	ui_min = 0.1; ui_max = 3.1; ui_step = 0.05;
	ui_category = "Bloom Effect"; ui_spacing = 1; ui_bind = "EnableBloom";
> = 1.6;
uniform float BloomRadius <
	ui_type = "slider";
	ui_label = "Radius";
	ui_tooltip = "Sets how far the bloom effect extends from each sparkle. Larger values create a wider glow.";
	ui_min = 1.0; ui_max = 10.2; ui_step = 0.2;
	ui_category = "Bloom Effect"; ui_bind = "EnableBloom";
> = 5.6;
uniform float BloomDispersion <
	ui_type = "slider";
	ui_label = "Dispersion";
	ui_tooltip = "Adjusts how quickly the bloom fades at the edges. Higher values make the glow softer and more gradual.";
	ui_min = 1.0; ui_max = 3.0; ui_step = 0.05;
	ui_category = "Bloom Effect"; ui_bind = "EnableBloom";
> = 2.0;
uniform int BloomQuality <
	ui_type = "combo";
	ui_label = "Quality";
	ui_tooltip = "Selects the quality level for the bloom effect. Higher quality reduces artifacts but may impact performance.";
	ui_items = "Potato\0Low\0Medium\0High\0Ultra\0AI Overlord\0";
	ui_category = "Bloom Effect"; ui_bind = "EnableBloom";
> = 2;
uniform bool BloomDither <
	ui_label = "Dither";
	ui_tooltip = "Adds subtle noise to the bloom to reduce color banding and grid patterns.";
	ui_category = "Bloom Effect"; ui_bind = "EnableBloom";
> = true;

// --- Listeningway Integration ---
uniform bool EnableListeningway <
	ui_label = "Enable Integration";
	ui_tooltip = "Enable audio-reactive controls using the Listeningway addon. When enabled, sparkles and bloom will respond to music and sound. [Learn more](https://github.com/gposingway/Listeningway)";
	ui_category = "Listeningway Integration";
> = false;
uniform int Listeningway_SparkleSource <
	ui_type = "combo";
	ui_label = "Sparkle Source";
	ui_items = "Off\0Solid\0Volume\0Beat\0Bass\0Treble\0";
	ui_category = "Listeningway Integration"; ui_bind = "EnableListeningway";
> = 3;
uniform float Listeningway_SparkleMultiplier <
	ui_type = "slider";
	ui_label = "Sparkle Intensity";
	ui_tooltip = "Controls how much the selected audio source increases sparkle brightness.";
	ui_min = 0.0; ui_max = 5.0; ui_step = 0.05;
	ui_category = "Listeningway Integration"; ui_bind = "EnableListeningway";
> = 1.5;
uniform int Listeningway_BloomSource <
	ui_type = "combo";
	ui_label = "Bloom Source";
	ui_items = "Off\0Solid\0Volume\0Beat\0Bass\0Treble\0";
	ui_category = "Listeningway Integration"; ui_bind = "EnableListeningway";
> = 3;
uniform float Listeningway_BloomMultiplier <
	ui_type = "slider";
	ui_label = "Bloom Intensity";
	ui_tooltip = "Controls how much the selected audio source increases bloom intensity.";
	ui_min = 0.0; ui_max = 10.0; ui_step = 0.1;
	ui_category = "Listeningway Integration"; ui_bind = "EnableListeningway";
> = 10.0;
uniform int Listeningway_TimeScaleSource <
	ui_type = "combo";
	ui_label = "Time Source";
	ui_items = "Off\0Solid\0Volume\0Beat\0Bass\0Treble\0";
	ui_category = "Listeningway Integration"; ui_bind = "EnableListeningway";
> = 3;
uniform float Listeningway_TimeScaleBand1Multiplier <
	ui_type = "slider";
	ui_label = "Time Intensity";
	ui_tooltip = "Controls how much the selected audio source increases animation speed.";
	ui_min = 0.0; ui_max = 5.0; ui_step = 0.05;
	ui_category = "Listeningway Integration"; ui_bind = "EnableListeningway";
> = 1.0;

// --- Color Settings ---
uniform float3 GlitterColor <
	ui_type = "color";
	ui_label = "Color";
	ui_tooltip = "Sets the base color of all sparkles.";
	ui_category = "Color Settings";
> = float3(1.0, 1.0, 1.0);
uniform bool DepthColoringEnable <
	ui_label = "Depth Color";
	ui_tooltip = "If enabled, sparkles will change color based on their distance from the camera.";
	ui_category = "Color Settings";
> = true;
uniform float3 NearColor <
	ui_type = "color";
	ui_label = "Near Color";
	ui_tooltip = "Color for sparkles close to the camera.";
	ui_category = "Color Settings";
> = float3(1.0, 204/255.0, 153/255.0);
uniform float3 FarColor <
	ui_type = "color";
	ui_label = "Far Color";
	ui_tooltip = "Color for sparkles far from the camera.";
	ui_category = "Color Settings";
> = float3(153/255.0, 204/255.0, 1.0);

// --- Depth Masking ---
uniform float NearPlane <
	ui_type = "slider";
	ui_label = "Near";
	ui_tooltip = "Controls the minimum distance from the camera where sparkles can appear. Lower values allow sparkles closer to the camera.";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
	ui_category = "Depth Masking";
> = 0.0;
uniform float FarPlane <
	ui_type = "slider";
	ui_label = "Far";
	ui_tooltip = "Controls the maximum distance from the camera where sparkles can appear. Lower values bring the cutoff closer.";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
	ui_category = "Depth Masking";
> = 1.0;
uniform float DepthCurve <
	ui_type = "slider";
	ui_label = "Curve";
	ui_tooltip = "Adjusts how quickly sparkles fade out with distance. Higher values make the fade sharper.";
	ui_min = 0.1; ui_max = 10.0; ui_step = 0.1;
	ui_category = "Depth Masking";
> = 1.0;
uniform bool AllowInfiniteCutoff <
	ui_label = "Infinite Cutoff";
	ui_tooltip = "If enabled, sparkles can appear all the way to the horizon. If disabled, sparkles beyond the cutoff distance are hidden.";
	ui_category = "Depth Masking";
> = true;

// --- Occlusion Control ---
uniform bool ObeyOcclusion <
	ui_label = "Occlusion";
	ui_tooltip = "If enabled, sparkles and bloom will be masked by scene depth, so they do not appear through objects.";
	ui_category = "Effect Control";
> = true;

// --- Blend ---
uniform int BlendMode <
	ui_type = "combo";
	ui_label = "Mode";
	ui_items = "Normal\0Lighter Only\0Darker Only\0Additive\0Multiply\0Screen\0";
	ui_category = "Blend";
> = 0;
uniform float BlendAmount <
	ui_type = "slider";
	ui_label = "Amount";
	ui_tooltip = "How strongly the effect is blended with the scene.";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
	ui_category = "Blend";
> = 1.0;

// --- Debug Mode ---
uniform int DebugMode <
	ui_type = "combo";
	ui_label = "Debug Mode";
	ui_tooltip = "Shows different debug visualizations to help diagnose issues with the effect.";
	ui_items = "Off\0Depth\0Normal\0Sparkle\0Mask\0Force On\0";
	ui_category = "Debug"; ui_spacing = 3;
> = 0;

/*-------------------------.
| :: Textures and Samplers |
'-------------------------*/

texture GlitterRT { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler GlitterSampler { Texture = GlitterRT; };
texture GlitterBloomRT { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA16F; };
sampler GlitterBloomSampler { Texture = GlitterBloomRT; };

/*-----------------------------.
| :: Helper Functions and Constants |
'-----------------------------*/

namespace AS_Glitter {
    static const float SPARKLE_LAYER_SIZES[3]   = {0.05, 0.03, 0.02};
    static const float SPARKLE_LAYER_WEIGHTS[3] = {1.0, 0.7, 0.3};
    static const float SPARKLE_LAYER_SPEEDS[3]  = {1.0, 1.2, 0.8};
    static const float SPARKLE_LAYER_POWS[3]    = {0.5, 0.7, 0.9};

    float Gaussian(float x, float sigma) {
        return (1.0 / (sqrt(2.0 * 3.14159265359) * sigma)) * exp(-(x * x) / (2.0 * sigma * sigma));
    }
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

    float hash21(float2 p) {
        p = frac(p * float2(123.34, 345.56));
        p += dot(p, p + 34.23);
        return frac(p.x * p.y);
    }
    float3 hash33(float3 p3) {
        p3 = frac(p3 * float3(0.1031, 0.11369, 0.13787));
        p3 += dot(p3, p3.yxz + 19.19);
        return -1.0 + 2.0 * frac(float3(
            (p3.x + p3.y) * p3.z,
            (p3.x + p3.z) * p3.y,
            (p3.y + p3.z) * p3.x
        ));
    }

    float2 calculateDitherNoise(float2 texcoord, float2 seeds, float stepSize) {
        float2 noise = frac(sin(dot(texcoord, seeds)) * 43758.5453);
        noise = noise * 2.0 - 1.0;
        noise *= 0.25 * stepSize;
        return noise;
    }
    float2 voronoi(float2 x, float offset) {
        float2 n = floor(x);
        float2 f = frac(x);
        float2 mg, mr;
        float md = 8.0;
        for(int j = -1; j <= 1; j++) {
            for(int i = -1; i <= 1; i++) {
                float2 g = float2(float(i), float(j));
                float2 o = hash33(float3(n + g, hash21(n + g) * 10.0 + offset)).xy * 0.5 + 0.5;
                float2 r = g + o - f;
                float d = dot(r, r);
                if(d < md) { md = d; mr = r; mg = g; }
            }
        }
        return float2(sqrt(md), AS_hash21(n + mg).x);
    }
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
    float star(float2 p, float size, float points, float angle) {
        float2 uv = p; float a = atan2(uv.y, uv.x) + angle; float r = length(uv);
        float f = cos(a * points) * 0.5 + 0.5;
        return 1.0 - smoothstep(f * size, f * size + 0.01, r);
    }
    float sparkle(float2 uv, float time) {
        float sparkleSum = 0.0;
        float2 voronoiResult;
        float sparkleScale = GlitterSize * 0.4;
        float sharpnessFactor = GlitterSharpness;
        float lifeDuration = 1.0 + GlitterLifetime * 0.2;
        for (int layer = 0; layer < 3; ++layer) {
            voronoiResult = voronoi(uv * GlitterDensity * (layer == 0 ? 0.5 : (layer == 1 ? 1.0 : 2.0)), time * (0.1 + 0.05 * layer));
            float sparkleID = voronoiResult.y;
            float dist = voronoiResult.x;
            float brightness = calculateSparkleLifecycle(time, sparkleID, SPARKLE_LAYER_SPEEDS[layer], lifeDuration);
            brightness = pow(brightness, SPARKLE_LAYER_POWS[layer]);
            float sparkleShape = (1.0 - smoothstep(0.0, SPARKLE_LAYER_SIZES[layer] * sparkleScale / sharpnessFactor, dist)) * brightness;
            if (layer == 0 && dist < SPARKLE_LAYER_SIZES[0] * sparkleScale / sharpnessFactor) {
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

/*-----------------------------------.
| :: First Pass - Sparkle Generation |
'-----------------------------------*/

float4 PS_RenderSparkles(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float4 color = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);
    bool forceEnable = (DebugMode == 5); if (forceEnable) { depth = 0.5; }
    float depthMask = smoothstep(NearPlane, FarPlane, depth); depthMask = 1.0 - pow(depthMask, DepthCurve); if (forceEnable) { depthMask = 1.0; }
    if (!AllowInfiniteCutoff && depth >= FarPlane) {
        return float4(0.0, 0.0, 0.0, 0.0);
    }
    float3 normal = float3(0, 0, 1);
    if (!forceEnable) {
         float3 offset = float3(ReShade::PixelSize.xy, 0.0);
         float2 posCenter = texcoord;
         float depthCenter = ReShade::GetLinearizedDepth(posCenter);
         float depthLeft = ReShade::GetLinearizedDepth(posCenter - offset.xz * 2.0); float depthRight = ReShade::GetLinearizedDepth(posCenter + offset.xz * 2.0);
         float depthTop = ReShade::GetLinearizedDepth(posCenter - offset.zy * 2.0); float depthBottom = ReShade::GetLinearizedDepth(posCenter + offset.zy * 2.0);
         float3 dx = float3(offset.x * 4.0, 0.0, depthRight - depthLeft); float3 dy = float3(0.0, offset.y * 4.0, depthBottom - depthTop);
         normal = normalize(cross(dx, dy)); normal = normal * 0.5 + 0.5; normal = normal * 2.0 - 1.0;
    }
    float actualTimeScale = TimeScale / 333.33;
    if (EnableListeningway) {
        actualTimeScale += GetAudioSource(Listeningway_TimeScaleSource) * Listeningway_TimeScaleBand1Multiplier / 333.33;
    }
    float time = AS_getTime(frameCount) * actualTimeScale;
    float positionHash = AS_hash21(floor(texcoord * 10.0)).x * 10.0;
    float2 noiseCoord = texcoord * ReShade::ScreenSize * 0.005;
    float sparkleIntensity = AS_Glitter::sparkle(noiseCoord, positionHash + time);
    if (EnableListeningway) {
        sparkleIntensity *= (1.0 + GetAudioSource(Listeningway_SparkleSource) * Listeningway_SparkleMultiplier);
    }
    float3 viewDir = float3(0.0, 0.0, 1.0); float fresnel = pow(1.0 - saturate(dot(normal, viewDir)), 5.0);
    if (!forceEnable && ObeyOcclusion) { sparkleIntensity *= fresnel * depthMask; }
    else if (!forceEnable && !ObeyOcclusion) { sparkleIntensity *= fresnel; }
    sparkleIntensity *= GlitterBrightness;
    if (DebugMode == 1) return float4(depth.xxx, 1.0); else if (DebugMode == 2) return float4(normal * 0.5 + 0.5, 1.0); else if (DebugMode == 3) return float4(sparkleIntensity.xxx, 1.0); else if (DebugMode == 4) return float4(depthMask.xxx, 1.0);
    float3 finalGlitterColor = GlitterColor;
    if (DepthColoringEnable && !forceEnable) { float depthFactor = smoothstep(NearPlane, FarPlane, depth); finalGlitterColor = lerp(NearColor, FarColor, depthFactor); }
    float3 sparkleContribution = finalGlitterColor * sparkleIntensity * 5.0;
    // Output only the sparkles (on black), alpha as mask
    return float4(sparkleContribution, sparkleIntensity > 0.05 ? 1.0 : 0.0);
}

/*-----------------------------------.
| :: Second Pass - Horizontal Bloom |
'-----------------------------------*/

float4 PS_BloomH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float4 color = 0.0; float weightSum = 0.0; if (DebugMode > 0 && DebugMode < 5) { return tex2D(GlitterSampler, texcoord); }
    float sigma = BloomRadius / BloomDispersion;
    float range = ceil(BloomRadius * 2.0); float stepSize = AS_Glitter::getBloomStepSize(BloomQuality);
    float2 noise = float2(1.0, 1.0); if (BloomDither) { noise = AS_Glitter::calculateDitherNoise(texcoord, float2(12.9898, 78.233), stepSize); }
    float bloomIntensity = BloomIntensity;
    if (EnableListeningway) {
        bloomIntensity += (GetAudioSource(Listeningway_BloomSource) * Listeningway_BloomMultiplier);
    }
    for(float x = -range; x <= range; x += stepSize) { float weight = AS_Glitter::Gaussian(x, sigma); weightSum += weight; float2 sampleOffset = float2(x / BUFFER_WIDTH, 0.0) * BloomRadius; if (BloomDither) { sampleOffset += float2(noise.x * 0.001, 0.0); } color += tex2D(GlitterSampler, texcoord + sampleOffset) * weight; }
    color /= max(weightSum, 1e-6);
    color *= bloomIntensity; return color;
}

/*-----------------------------------.
| :: Third Pass - Vertical Bloom and Final Blend |
'-----------------------------------*/

float4 PS_BloomV(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    if (DebugMode > 0 && DebugMode < 5) { return tex2D(GlitterSampler, texcoord); }
    float3 sparkles = tex2D(GlitterSampler, texcoord).rgb;
    float3 bloom = 0.0;
    if (EnableBloom) {
        float4 bloomColor = 0.0; float weightSum = 0.0; float sigma = BloomRadius / BloomDispersion;
        float range = ceil(BloomRadius * 2.0); float stepSize = AS_Glitter::getBloomStepSize(BloomQuality);
        float2 noise = float2(1.0, 1.0); if (BloomDither) { noise = AS_Glitter::calculateDitherNoise(texcoord, float2(78.233, 12.9898), stepSize); }
        for(float y = -range; y <= range; y += stepSize) {
            float weight = AS_Glitter::Gaussian(y, sigma); weightSum += weight;
            float2 sampleOffset = float2(0.0, y / BUFFER_HEIGHT) * BloomRadius;
            if (BloomDither) { sampleOffset += float2(0.0, noise.y * 0.001); }
            bloomColor += tex2D(GlitterBloomSampler, texcoord + sampleOffset) * weight;
        }
        bloomColor /= max(weightSum, 1e-6);
        bloom = bloomColor.rgb;
    }
    // Composite sparkles and bloom over the original scene
    float3 result = originalColor.rgb + sparkles + bloom;
    // Optionally apply BlendAmount for user control
    result = lerp(originalColor.rgb, result, DebugMode == 5 ? 1.0 : BlendAmount);
    return float4(result, originalColor.a);
}

/*-------------------------.
| :: Technique Definition |
'-------------------------*/

technique AS_Glitter < ui_label = "[AS] Glitter"; ui_tooltip = "Adds dynamic sparkles that pop in, glow, and fade out"; >
{
	pass RenderSparkles { VertexShader = PostProcessVS; PixelShader = PS_RenderSparkles; RenderTarget = GlitterRT; }
	pass BloomH { VertexShader = PostProcessVS; PixelShader = PS_BloomH; RenderTarget = GlitterBloomRT; }
	pass BloomV { VertexShader = PostProcessVS; PixelShader = PS_BloomV; }
}
