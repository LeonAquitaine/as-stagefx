/**
 * AS_VFX_BrokenGlass.1.fx - Floating broken glass shards effect
 * Author: Leon Aquitaine (Concept by user, Gemini assistance)
 * Date: 2025-05-05
 * License: Creative Commons Attribution 4.0 International
 *
 * DESCRIPTION:
 * Creates an effect simulating floating shards of broken glass using Voronoi noise.
 * Shards distort the background, have varying pseudo-depths for occlusion,
 * and feature glints/sparkles along their edges.
 *
 * FEATURES:
 * - Voronoi noise for shard pattern generation.
 * - Pseudo-random depth assigned per shard for floating effect & occlusion.
 * - Screen-space distortion (refraction simulation) through shards.
 * - Edge detection with animated glints/sparkles.
 * - Optional parallax effect to enhance floating appearance.
 * - Standard AS framework integration (UI, Blending, Audio, Debug).
 */

#ifndef __AS_VFX_BrokenGlass_1_fx
#define __AS_VFX_BrokenGlass_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // Includes Voronoi, Hashes, UI, etc.

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
static const float NOISE_SCALE_MIN = 1.0;
static const float NOISE_SCALE_MAX = 50.0;
static const float NOISE_SCALE_DEFAULT = 10.0;

static const float BASE_DEPTH_MIN = 0.0;
static const float BASE_DEPTH_MAX = 1.0;
static const float BASE_DEPTH_DEFAULT = 0.05; // Slightly in front of screen

static const float DEPTH_RANGE_MIN = 0.0;
static const float DEPTH_RANGE_MAX = 0.2; // Max depth variation between shards
static const float DEPTH_RANGE_DEFAULT = 0.05;

static const float PARALLAX_MIN = 0.0;
static const float PARALLAX_MAX = 0.1;
static const float PARALLAX_DEFAULT = 0.02;

static const float DISTORTION_MIN = 0.0;
static const float DISTORTION_MAX = 0.1;
static const float DISTORTION_DEFAULT = 0.01;

static const float CHROMATIC_ABERRATION_MIN = 0.0;
static const float CHROMATIC_ABERRATION_MAX = 0.01;
static const float CHROMATIC_ABERRATION_DEFAULT = 0.002;

static const float EDGE_THRESHOLD_MIN = 0.01;
static const float EDGE_THRESHOLD_MAX = 1.0;
static const float EDGE_THRESHOLD_DEFAULT = 0.1; // Lower = thicker edges detected

static const float GLINT_INTENSITY_MIN = 0.0;
static const float GLINT_INTENSITY_MAX = 10.0;
static const float GLINT_INTENSITY_DEFAULT = 2.0;

static const float SPARKLE_SPEED_MIN = 0.1;
static const float SPARKLE_SPEED_MAX = 5.0;
static const float SPARKLE_SPEED_DEFAULT = 1.0;

// ============================================================================
// UI DECLARATIONS (ORDERED)
// ============================================================================
// --- Shard Pattern ---
uniform float NoiseScale < ui_type = "slider"; ui_label = "Shard Density/Scale"; ui_tooltip = "Controls the size and number of glass shards."; ui_min = NOISE_SCALE_MIN; ui_max = NOISE_SCALE_MAX; ui_step = 0.1; ui_category = "Shard Pattern"; > = NOISE_SCALE_DEFAULT;
uniform float ParallaxScale < ui_type = "slider"; ui_label = "Parallax Scale"; ui_tooltip = "Amount of parallax offset for floating effect."; ui_min = 0.0; ui_max = 0.1; ui_step = 0.001; ui_category = "Shard Pattern"; > = 0.02;
uniform float GlassThickness < ui_type = "slider"; ui_label = "Glass Thickness"; ui_tooltip = "Darkens the interior of the shard opposite to the glint direction."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Shard Pattern"; > = 0.5;

// --- Distortion ---
uniform float DistortionStrength < ui_type = "slider"; ui_label = "Distortion Strength"; ui_tooltip = "Amount of refraction/distortion through shards."; ui_min = DISTORTION_MIN; ui_max = DISTORTION_MAX; ui_step = 0.0005; ui_category = "Distortion"; > = DISTORTION_DEFAULT;
uniform float ChromaticAberration < ui_type = "slider"; ui_label = "Chromatic Aberration"; ui_tooltip = "Color fringing effect on distortion."; ui_min = CHROMATIC_ABERRATION_MIN; ui_max = CHROMATIC_ABERRATION_MAX; ui_step = 0.0001; ui_category = "Distortion"; > = CHROMATIC_ABERRATION_DEFAULT;
uniform float NormalStrength < ui_type = "slider"; ui_label = "Fake Normal Strength"; ui_tooltip = "Influence of the calculated normal on distortion direction."; ui_min = 0.0; ui_max = 2.0; ui_step = 0.05; ui_category = "Distortion"; > = 1.0;

// --- Edge Glints ---
uniform float EdgeThreshold < ui_type = "slider"; ui_label = "Edge Detection Threshold"; ui_tooltip = "Sensitivity for detecting shard edges (lower = thicker)."; ui_min = EDGE_THRESHOLD_MIN; ui_max = EDGE_THRESHOLD_MAX; ui_step = 0.01; ui_category = "Edge Glints"; > = EDGE_THRESHOLD_DEFAULT;
uniform float3 GlintColor < ui_type = "color"; ui_label = "Glint Color"; ui_tooltip = "Color of the edge glints."; ui_category = "Edge Glints"; > = float3(1.0, 1.0, 1.0);
uniform float GlintIntensity < ui_type = "slider"; ui_label = "Glint Intensity"; ui_tooltip = "Brightness multiplier for glints."; ui_min = GLINT_INTENSITY_MIN; ui_max = GLINT_INTENSITY_MAX; ui_step = 0.1; ui_category = "Edge Glints"; > = GLINT_INTENSITY_DEFAULT;
uniform float SparkleSpeed < ui_type = "slider"; ui_label = "Sparkle Speed"; ui_tooltip = "Speed of the glint animation/twinkle."; ui_min = SPARKLE_SPEED_MIN; ui_max = SPARKLE_SPEED_MAX; ui_step = 0.05; ui_category = "Edge Glints"; > = SPARKLE_SPEED_DEFAULT;
uniform float LightDirection < ui_type = "slider"; ui_label = "Light Direction"; ui_tooltip = "Direction of the light in degrees (-180 to 180)."; ui_min = -180.0; ui_max = 180.0; ui_step = 1.0; ui_category = "Edge Glints"; > = 0.0;
uniform float LightSpread < ui_type = "slider"; ui_label = "Light Spread"; ui_tooltip = "Spread angle for glint highlight (0-90)."; ui_min = 0.0; ui_max = 90.0; ui_step = 1.0; ui_category = "Edge Glints"; > = 45.0;
uniform float GlintThickness < ui_type = "slider"; ui_label = "Glint Thickness"; ui_tooltip = "Width of the glint highlight on glass borders."; ui_min = 0.001; ui_max = 0.1; ui_step = 0.001; ui_category = "Edge Glints"; > = 0.03;

// --- Animation ---
uniform float NoiseAnimationSpeed < ui_type = "slider"; ui_label = "Noise Animation Speed"; ui_tooltip = "Speed at which the noise pattern subtly shifts."; ui_min = 0.0; ui_max = 0.5; ui_step = 0.01; ui_category = "Animation"; > = 0.05;

// --- Audio Reactivity ---
AS_AUDIO_SOURCE_UI(Glass_AudioSource, "Audio Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(Glass_AudioMultiplier, "Intensity", 1.0, 2.0, "Audio Reactivity")
uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter"; ui_tooltip = "Select parameter affected by audio"; ui_items = "None\0Noise Scale\0Depth Variation\0Distortion\0Glint Intensity\0Sparkle Speed\0"; ui_category = "Audio Reactivity"; > = 0;

// --- Stage/Rotation ---
uniform float BaseDepth < ui_type = "slider"; ui_label = "Base Depth"; ui_tooltip = "Base depth plane for shards (0=Near, 1=Far)."; ui_min = BASE_DEPTH_MIN; ui_max = BASE_DEPTH_MAX; ui_step = 0.001; ui_category = "Stage"; > = BASE_DEPTH_DEFAULT;
uniform float DepthRange < ui_type = "slider"; ui_label = "Depth Variation"; ui_tooltip = "Amount of random depth variation between shards."; ui_min = DEPTH_RANGE_MIN; ui_max = DEPTH_RANGE_MAX; ui_step = 0.001; ui_category = "Stage"; > = DEPTH_RANGE_DEFAULT;
AS_ROTATION_UI(SnapRotation, FineRotation, "Stage")

// --- Final Mix ---
AS_BLENDMODE_UI(BlendMode, "Final Mix")
AS_BLENDAMOUNT_UI(BlendAmount, "Final Mix")

// --- Debug ---
AS_DEBUG_MODE_UI("Normal\0Voronoi Cells (ID)\0Voronoi Distance (F1)\0Shard Depth\0Edge Factor\0Fake Normals\0Distortion Offset\0Glint Mask\0")

// ============================================================================
// MAIN PIXEL SHADER
// ============================================================================
float4 PS_BrokenGlass(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // --- Initial Setup ---
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    float time = AS_getTime();

    // --- Apply Audio Reactivity ---
    float noiseScaleFinal = NoiseScale;
    float depthRangeFinal = DepthRange;
    float distortionFinal = DistortionStrength;
    float glintIntensityFinal = GlintIntensity;
    float sparkleSpeedFinal = SparkleSpeed;
    // Add other params if needed

    if (AudioTarget > 0) {
        float audioLevel = AS_getAudioSource(Glass_AudioSource);
        float multiplier = Glass_AudioMultiplier;
        float audioFactor = (1.0 + audioLevel * multiplier); // Multiplicative base

        if      (AudioTarget == 1) noiseScaleFinal *= audioFactor;
        else if (AudioTarget == 2) depthRangeFinal *= audioFactor;
        else if (AudioTarget == 3) distortionFinal *= audioFactor;
        else if (AudioTarget == 4) glintIntensityFinal *= audioFactor;
        else if (AudioTarget == 5) sparkleSpeedFinal *= audioFactor;

        // Add clamping if needed
        noiseScaleFinal = max(noiseScaleFinal, NOISE_SCALE_MIN);
        // ... etc ...
    }

    // --- Calculate Rotated, Centered, Aspect-Corrected Coordinates ---
    float2 uv = texcoord - 0.5;
    float aspect = ReShade::AspectRatio;
    if (aspect >= 1.0) uv.x *= aspect;
    else uv.y /= aspect;
    float rotation = AS_getRotationRadians(SnapRotation, FineRotation);
    float sinR = sin(rotation);
    float cosR = cos(rotation);
    float2 rotatedUV;
    rotatedUV.x = uv.x * cosR - uv.y * sinR;
    rotatedUV.y = uv.x * sinR + uv.y * cosR;
    // Undo aspect correction after rotation
    if (aspect >= 1.0) rotatedUV.x /= aspect;
    else rotatedUV.y *= aspect;
    rotatedUV += 0.5;

    // --- Calculate Noise Coordinates ---
    float2 baseCoord = rotatedUV * ReShade::ScreenSize.y * 0.01 * noiseScaleFinal;
    float2 parallaxOffset = (rotatedUV - 0.5) * ParallaxScale * BaseDepth * 10.0;
    float2 noisyCoord = baseCoord + parallaxOffset;
    float noiseTimeOffset = time * NoiseAnimationSpeed;

    // --- Calculate Voronoi Noise ---
    // AS_voronoi_F1_ID returns float2(distance_to_nearest_center, random_cell_id_hash)
    float2 voronoiResult = AS_voronoi_F1_ID(noisyCoord, noiseTimeOffset);
    float voronoiF1 = voronoiResult.x;
    float cellIDHash = voronoiResult.y; // Use this for random properties

    // --- Calculate Shard Depth ---
    // Assign a pseudo-random depth based on cell ID hash
    float shardDepth = saturate(BaseDepth + (AS_hash11(cellIDHash * 17.3) - 0.5) * 2.0 * depthRangeFinal); // Hash -> [-1, 1] * range

    // --- Depth Check ---
    bool shardVisible = shardDepth <= sceneDepth + 0.0001; // Epsilon for precision

    // --- Default to Original Color ---
    float3 finalColor = orig.rgb;
    float3 debugNormal = float3(0.5, 0.5, 1.0); // For debug view
    float2 debugOffset = float2(0.0, 0.0);    // For debug view
    float debugEdgeFactor = 0.0;             // For debug view
    float debugGlintMask = 0.0;              // For debug view

    // --- If Shard is Visible ---
    if (shardVisible)
    {
        // --- Edge Detection ---
        // Calculate gradient of Voronoi F1 distance field
        float2 gradF1 = float2(ddx(voronoiF1), ddy(voronoiF1));
        float edgeFactor = length(gradF1);
        debugEdgeFactor = edgeFactor;
        
        // Normalize the gradient for direction calculations (with safety check)
        float2 borderNormal = length(gradF1) > 0.0001 ? normalize(gradF1) : float2(0, 1);

        // --- Calculate resolution-independent anti-aliasing width ---
        float resolutionScale = ReShade::ScreenSize.y / 1080.0; // Base scale on 1080p reference
        float pixelWidth = max(ReShade::PixelSize.y * 4.0, 0.001 / resolutionScale);
        
        // --- Light Direction Vector ---
        float lightAngleRad = LightDirection * (AS_PI / 180.0);
        float2 lightDir = float2(cos(lightAngleRad), sin(lightAngleRad));
        float cosAngle = dot(borderNormal, lightDir);
        float angleDiff = acos(saturate(cosAngle)) * (180.0 / AS_PI);
        
        // Calculate light angle attenuation based on spread
        float spread = max(LightSpread, 0.01);
        float glintAtten = pow(saturate(1.0 - (angleDiff / spread)), 1.2);
        
        // --- Edge Proximity Factor with resolution-aware anti-aliasing ---
        // Higher edge quality through proper scaling
        float edgeThresholdScaled = EdgeThreshold / resolutionScale;
        float edgeProximity = smoothstep(0.0, edgeThresholdScaled * 2.0, edgeFactor);
        
        // --- Distance from Edge to Center ---
        // Create a gradient that's 1.0 at edges and 0.0 at center
        // We create this using both the edge detection and voronoiF1
        float edgeDistance = saturate(edgeProximity + (1.0 - voronoiF1 * 2.0));
        
        // --- Glint Calculation with resolution-aware thickness ---
        float glintWidth = GlintThickness / resolutionScale; // Scale thickness with resolution
        // Create a glint that only appears near edges and fades quickly
        float glintMask = smoothstep(0.0, glintWidth * 5.0, edgeProximity);
        // Apply light direction attenuation
        float glint = glintMask * glintAtten;
        
        // --- Sparkle Animation ---
        float sparklePhase = time * sparkleSpeedFinal + AS_hash11(cellIDHash * 9.7) * AS_TWO_PI;
        float sparkle = saturate(0.6 + 0.4 * sin(sparklePhase));
        glint *= sparkle;
        debugGlintMask = glint;
        
        // --- Glass Thickness: Darkening FROM EDGE TOWARD CENTER ---
        // Calculate the darkening on opposite side from light direction
        float2 oppositeDir = -lightDir;
        float cosOpposite = dot(borderNormal, oppositeDir);
        float angleOppositeDeg = acos(saturate(cosOpposite)) * (180.0 / AS_PI);
        float thicknessAtten = pow(saturate(1.0 - (angleOppositeDeg / spread)), 2.0);
        
        // Modify the gradient to ONLY extend from edge toward center
        // Start with edge proximity and extend inward based on thickness
        float gradientDepth = max(0.2, GlassThickness) * 5.0;
        
        // Create gradient with range determined by GlassThickness
        // 1.0 at edge, fading toward 0.0 at center based on thickness
        float distanceFromEdge = 1.0 - smoothstep(0.0, gradientDepth, voronoiF1 * 3.0);
        
        // Only darken areas:
        // 1. Away from edges (to avoid conflicting with glint)
        // 2. Only on the side opposite to light direction
        // 3. With strength controlled by GlassThickness
        float darken = distanceFromEdge * (1.0 - edgeProximity) * thicknessAtten * GlassThickness * 0.75;

        // --- Fake Normal Calculation ---
        // Option 1: Based on gradient (can be noisy)
        // float2 grad = normalize(float2(dFdx, dFdy));
        // float3 fakeNormal = float3(grad * NormalStrength, sqrt(1.0 - saturate(dot(grad, grad))));

        // Option 2: Based on cell ID hash (simpler, more stable)
        float3 fakeNormal = normalize(AS_hash33(float3(cellIDHash * 12.3, cellIDHash * 45.6, cellIDHash * 78.9)));
        debugNormal = fakeNormal * 0.5 + 0.5; // Store for debug [0, 1] range

        // --- Distortion / Refraction ---
        // Calculate offset based on fake normal (XY components)
        // Scale offset by distortion strength and pseudo-depth (less distortion further away)
        float2 baseOffset = fakeNormal.xy * distortionFinal * NormalStrength * (1.0 - shardDepth);
        debugOffset = baseOffset * 100.0; // Scale for debug visibility

        // Apply chromatic aberration
        float3 distortedColor;
        float ca = ChromaticAberration;
        distortedColor.r = tex2D(ReShade::BackBuffer, texcoord + baseOffset * (1.0 - ca)).r;
        distortedColor.g = tex2D(ReShade::BackBuffer, texcoord + baseOffset).g;
        distortedColor.b = tex2D(ReShade::BackBuffer, texcoord + baseOffset * (1.0 + ca)).b;

        // --- Glint and Glass Thickness (Interior Darkening Opposite to Glint) ---
        // Apply glint to the distorted color - make sure to use the glint with sparkle here
        float3 glintedColor = lerp(distortedColor, GlintColor, saturate(glint * glintIntensityFinal));
        finalColor = lerp(glintedColor, float3(0,0,0), darken);

        // --- Blending ---
        // Blend the final shard color with the original background
        finalColor = AS_blendResult(orig.rgb, finalColor, BlendMode);
        finalColor = lerp(orig.rgb, finalColor, BlendAmount);
    }
    // Else (shard not visible), finalColor remains orig.rgb

    // --- Debug Modes ---
    if (DebugMode > 0) {
        if (DebugMode == 1) return float4(frac(cellIDHash * float3(1.0, 13.7, 41.1)), 1.0); // Voronoi Cells (ID hash colorized)
        if (DebugMode == 2) return float4(saturate(voronoiF1 * 5.0).xxx, 1.0); // Voronoi Distance F1 (scaled)
        if (DebugMode == 3) return float4(shardDepth.xxx, 1.0); // Shard Depth
        if (DebugMode == 4) return float4(saturate(debugEdgeFactor * 5.0).xxx, 1.0); // Edge Factor (scaled)
        if (DebugMode == 5) return float4(debugNormal, 1.0); // Fake Normals
        if (DebugMode == 6) return float4(debugOffset * 0.5 + 0.5, 0.0, 1.0); // Distortion Offset XY mapped to RG
        if (DebugMode == 7) return float4(debugGlintMask.xxx, 1.0); // Glint Mask (including sparkle)
        return float4(1.0, 0.0, 1.0, 1.0); // Magenta error for invalid debug mode
    }

    // --- Final Output ---
    return float4(finalColor, orig.a);
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_VFX_BrokenGlass < ui_label = "[AS] VFX: Broken Glass"; ui_tooltip = "Simulates floating shards of broken glass with distortion and glints."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_BrokenGlass;
    }
}

#endif // __AS_VFX_BrokenGlass_1_fx