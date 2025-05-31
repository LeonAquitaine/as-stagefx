/**
 * AS_VFX_MotionFocus.1.fx - Automatic Motion-Based Camera Focus & Zoom
 * Author: Leon Aquitaine
 * License: CC BY 4.0
 * * DESCRIPTION:
 * This shader analyzes inter-frame motion differences to dynamically adjust the viewport,
 * zooming towards and centering on areas of detected movement. It uses a multi-pass
 * approach to capture frames, detect motion, analyze motion distribution in quadrants,
 * and apply a corresponding camera transformation with motion-centered zoom.
 *
 * FEATURES:
 * - Multi-pass motion analysis for robust detection.
 * - Half-resolution processing for performance.
 * - Temporal smoothing to prevent jittery camera movements.
 * - Adaptive decay for responsive adjustments to changing motion patterns.
 * - Quadrant-based motion aggregation to determine the center of activity.
 * - Dynamic zoom and focus centered on detected motion areas.
 * - Motion-weighted zoom center calculation for natural camera movement.
 * - Generous zoom limits for dramatic effect possibilities.
 * - Edge correction to prevent sampling outside screen bounds.
 * - User-configurable strength for focus and zoom, plus many advanced tunables.
 * - Debug mode to visualize motion data.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Pass 1 (PS_MotionFocusNorm): Captures the current frame at half resolution.
 * 2. Pass 2 (PS_MotionFocusQuadFull): Calculates per-pixel motion intensity using frame
 * differencing, exponential smoothing, and an adaptive decay system. All key parameters
 * of this stage are tunable via the UI.
 * 3. Pass 3 (PS_MotionFocus): Aggregates motion data from Pass 2 into four screen
 * quadrants by sampling on a grid. * 4. Pass 4 (PS_MotionFocusDisplay): Calculates the motion-weighted center and zoom level based
 * on quadrant motion data, then applies a motion-centered zoom transformation to the current frame.
 * The zoom dynamically centers around detected motion areas rather than screen center.
 * 5. Pass 5 (PS_MotionFocusStorage): Stores the processed current frame and motion data
 * from Pass 1 and Pass 2 for use in the next frame's analysis.
 */

#ifndef __AS_VFX_MotionFocus_1_fx
#define __AS_VFX_MotionFocus_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// TEXTURES & SAMPLERS
// ============================================================================

texture NormTex { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA8; };
texture PrevFrameTex { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA8; };

texture QuadFullTex { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = R32F; }; // Store motion intensity (single channel)
texture PrevMotionTex { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = R32F; };

texture FocusTex { Width = 1; Height = 1; Format = RGBA32F; }; // Stores float4 quadrant motion intensity sums

sampler NormSampler { Texture = NormTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler PrevFrameSampler { Texture = PrevFrameTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };

sampler QuadFullSampler { Texture = QuadFullTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler PrevMotionSampler { Texture = PrevMotionTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };

sampler FocusSampler { Texture = FocusTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; }; // Point for 1x1

// ============================================================================
// UI UNIFORMS
// ============================================================================

// Category: Motion Focus - Main Controls
// Basic strength controls for the overall effect.
uniform float FocusStrength < ui_type = "slider"; ui_label = "Focus Strength"; ui_tooltip = "Controls how aggressively the camera follows areas of motion."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Motion Focus - Main Controls"; > = 0.5;
uniform float ZoomStrength < ui_type = "slider"; ui_label = "Zoom Strength"; ui_tooltip = "Controls the overall intensity of zooming towards areas of motion."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Motion Focus - Main Controls"; > = 0.5;

// Category: Motion Focus - Detection Tuning
// Fine-tune the sensitivity and responsiveness of the motion detection algorithm.
uniform float MotionSmoothness < ui_type = "slider"; ui_label = "Motion Smoothness"; ui_tooltip = "Controls temporal smoothing of motion. Higher = smoother, less responsive (more history). Lower = more responsive, potentially jittery."; ui_min = 0.800; ui_max = 0.999; ui_step = 0.001; ui_category = "Motion Focus - Detection Tuning"; > = 0.968;

uniform float MotionFadeRate < ui_type = "slider"; ui_label = "Motion Fade Rate"; ui_tooltip = "Base rate at which detected motion intensity fades over time."; ui_min = 0.800; ui_max = 0.999; ui_step = 0.001; ui_category = "Motion Focus - Detection Tuning"; > = 0.978;

uniform float FadeSensitivity < ui_type = "slider"; ui_label = "Fade Sensitivity"; ui_tooltip = "How strongly motion changes affect the decay rate. Higher = more adaptive decay."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Motion Focus - Detection Tuning"; > = 0.2;

uniform float ChangeSensitivity < ui_type = "slider"; ui_label = "Change Sensitivity"; ui_tooltip = "Sensitivity to motion changes for adapting the decay rate. Higher = adapts to smaller changes."; ui_min = 1000.0; ui_max = 1000000.0; ui_step = 1000.0; ui_category = "Motion Focus - Detection Tuning"; > = 100000.0;

// Category: Motion Focus - Zoom Dynamics
// Control the behavior and limits of the zooming function.
uniform float MaxZoomLevel < ui_type = "slider"; ui_label = "Max Zoom Level"; ui_tooltip = "Limits how much the view can zoom in (e.g., 0.8 means the content will fill at least 1-0.8 = 20% of its original dimension)."; ui_min = 0.05; ui_max = 0.85; ui_step = 0.01; ui_category = "Motion Focus - Zoom Dynamics"; > = 0.6;

uniform float ZoomIntensity < ui_type = "slider"; ui_label = "Zoom Intensity"; ui_tooltip = "Overall scaling factor for the calculated zoom amount, applied before strength and cap."; ui_min = 0.1; ui_max = 2.0; ui_step = 0.05; ui_category = "Motion Focus - Zoom Dynamics"; > = 0.5;

// Category: Motion Focus - Response & Shift Tuning
// Adjust how the camera responds to global motion and motion distribution.
uniform float GlobalMotionSensitivity < ui_type = "slider"; ui_label = "Global Motion Sensitivity"; ui_tooltip = "Scales overall motion input for zoom dampening. Higher = more sensitive to global motion for reducing zoom."; ui_min = 1.0; ui_max = 20.0; ui_step = 0.1; ui_category = "Motion Focus - Response & Shift Tuning"; > = 5.0;

uniform float FocusPrecision < ui_type = "slider"; ui_label = "Focus Precision"; ui_tooltip = "Exponent for the focus distribution factor. Higher = camera shifts more aggressively towards concentrated motion."; ui_min = 1.0; ui_max = 5.0; ui_step = 0.1; ui_category = "Motion Focus - Response & Shift Tuning"; > = 3.0;

// Category: Motion Focus - Debug
// Developer options for visualizing intermediate shader passes.
AS_DEBUG_UI("Off\0Motion Intensity (Mid-Pass)\0Quadrant Motion Data (Final)\0")

// ============================================================================
// PASS 1: Frame Capture (Half Resolution)
// ============================================================================
float4 PS_MotionFocusNorm(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    return tex2D(ReShade::BackBuffer, texcoord);
}

// ============================================================================
// PASS 2: Motion Detection (Temporal Smoothing & Adaptive Decay)
// ============================================================================
float PS_MotionFocusQuadFull(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float3 currentFrame = tex2D(NormSampler, texcoord).rgb;
    float3 prevFrame = tex2D(PrevFrameSampler, texcoord).rgb;

    float frameDiff = (abs(currentFrame.r - prevFrame.r) +
                       abs(currentFrame.g - prevFrame.g) +
                       abs(currentFrame.b - prevFrame.b)) / 3.0;

    float prevMotion = tex2D(PrevMotionSampler, texcoord).r;

    // Temporal Smoothing (Exponential Moving Average)
    float smoothedMotion = MotionSmoothness * prevMotion + (1.0 - MotionSmoothness) * frameDiff;

    // Adaptive Decay System
    float motionChange = abs(smoothedMotion - prevMotion);
    float decayFactor = MotionFadeRate - FadeSensitivity * max(1.0 - pow(1.0 - motionChange, 2.0) * ChangeSensitivity, 0.0);
    decayFactor = clamp(decayFactor, 0.0, 1.0); // Ensure decay factor is valid

    float finalMotion = decayFactor * prevMotion + (1.0 - decayFactor) * frameDiff;
    
    return finalMotion;
}

// ============================================================================
// PASS 3: Quadrant Analysis
// ============================================================================
#define SAMPLE_GRID_X_COUNT 72
#define SAMPLE_GRID_Y_COUNT 72
#define TOTAL_SAMPLES (SAMPLE_GRID_X_COUNT * SAMPLE_GRID_Y_COUNT)

float4 PS_MotionFocus(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target // Only runs for the first pixel (1x1 texture)
{
    // quadrantMotionSums: x=top-left, y=top-right, z=bottom-left, w=bottom-right
    float4 quadrantMotionSums = 0; 

    float centerX = 0.5;
    float centerY = 0.5;

    float stepX = 1.0 / SAMPLE_GRID_X_COUNT;
    float stepY = 1.0 / SAMPLE_GRID_Y_COUNT;

    for (int j = 0; j < SAMPLE_GRID_Y_COUNT; ++j)
    {
        for (int i = 0; i < SAMPLE_GRID_X_COUNT; ++i)
        {
            float2 sampleUV = float2((i + 0.5) * stepX, (j + 0.5) * stepY);
            float motionIntensity = tex2Dlod(QuadFullSampler, float4(sampleUV, 0, 0)).r;

            if (sampleUV.x < centerX && sampleUV.y < centerY)
                quadrantMotionSums.x += motionIntensity; // Top-left
            else if (sampleUV.x >= centerX && sampleUV.y < centerY)
                quadrantMotionSums.y += motionIntensity; // Top-right
            else if (sampleUV.x < centerX && sampleUV.y >= centerY)
                quadrantMotionSums.z += motionIntensity; // Bottom-left
            else
                quadrantMotionSums.w += motionIntensity; // Bottom-right
        }
    }

    quadrantMotionSums /= (float)TOTAL_SAMPLES; // Normalize by total samples

    return quadrantMotionSums;
}

// ============================================================================
// PASS 4: Focus Application & Display
// ============================================================================
float4 PS_MotionFocusDisplay(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 original_color = tex2D(ReShade::BackBuffer, texcoord);    // currentQuadrantMotion: .x=TL, .y=TR, .z=BL, .w=BR normalized motion intensity
    float4 currentQuadrantMotion = tex2D(FocusSampler, float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y));    if (DebugMode == 1) return tex2D(QuadFullSampler, texcoord).xxxx; // Show full motion detection pass
    if (DebugMode == 2) return currentQuadrantMotion; // Show the RGBA values representing quadrant motions

    // Dominant Quadrant Intensity: The motion intensity of the most active quadrant.
    float dominantQuadrantIntensity = max(currentQuadrantMotion.x, max(currentQuadrantMotion.y, max(currentQuadrantMotion.z, currentQuadrantMotion.w)));    // Focus Distribution Factor: How much the dominant quadrant stands out from the others. Higher if motion is concentrated.
    float focusDistributionFactor = 1.0;
    float sumAllQuadrantMotions = currentQuadrantMotion.x + currentQuadrantMotion.y + currentQuadrantMotion.z + currentQuadrantMotion.w;
    if (sumAllQuadrantMotions > AS_EPSILON) 
    {
        if (dominantQuadrantIntensity == currentQuadrantMotion.x) focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.y + currentQuadrantMotion.z + currentQuadrantMotion.w) * AS_THIRD;
        else if (dominantQuadrantIntensity == currentQuadrantMotion.y) focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.x + currentQuadrantMotion.z + currentQuadrantMotion.w) * AS_THIRD;
        else if (dominantQuadrantIntensity == currentQuadrantMotion.z) focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.x + currentQuadrantMotion.y + currentQuadrantMotion.w) * AS_THIRD;
        else focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.x + currentQuadrantMotion.y + currentQuadrantMotion.z) * AS_THIRD;
        focusDistributionFactor = max(0.0, focusDistributionFactor); 
    }    // Global Motion Influence: Factor that moderates zoom based on overall screen activity.
    float averageTotalMotion = sumAllQuadrantMotions * AS_QUARTER;
    float globalMotionInfluence = AS_HALF * max(1.0, min(2.0 - pow(saturate(averageTotalMotion * GlobalMotionSensitivity), 3.0), 2.0));// Final Transformation Calculation
    float2 finalZoomAmount = dominantQuadrantIntensity * focusDistributionFactor * globalMotionInfluence * ZoomStrength * ZoomIntensity; 
    finalZoomAmount = min(finalZoomAmount, MaxZoomLevel);    // Calculate weighted center of motion based on quadrant intensities
    float2 motionCenter = float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y); // Default to screen center
    
    if (sumAllQuadrantMotions > AS_EPSILON) {
        // Quadrant centers: TL(0.25,0.25), TR(0.75,0.25), BL(0.25,0.75), BR(0.75,0.75)
        motionCenter.x = (currentQuadrantMotion.x * 0.25 + currentQuadrantMotion.y * 0.75 + 
                          currentQuadrantMotion.z * 0.25 + currentQuadrantMotion.w * 0.75) / sumAllQuadrantMotions;
        motionCenter.y = (currentQuadrantMotion.x * 0.25 + currentQuadrantMotion.y * 0.25 + 
                          currentQuadrantMotion.z * 0.75 + currentQuadrantMotion.w * 0.75) / sumAllQuadrantMotions;
          // Blend motion center with screen center based on focus distribution
        // More concentrated motion = use motion center more, distributed motion = stay closer to screen center
        float centerBlendFactor = pow(focusDistributionFactor, 0.5) * FocusStrength;
        motionCenter = lerp(float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y), motionCenter, centerBlendFactor);
    }    float2 zoomScaleFactor = 1.0 - finalZoomAmount; 
    
    // Apply zoom transformation centered around the calculated motion center
    float2 transformedUv = (texcoord - motionCenter) * zoomScaleFactor + motionCenter;
    
    // Edge Correction - recalculated for motion-centered zoom
    float2 sourceUvAtScreenCorner00 = (float2(0.0, 0.0) - motionCenter) / zoomScaleFactor + motionCenter;
    float2 sourceUvAtScreenCorner11 = (float2(1.0, 1.0) - motionCenter) / zoomScaleFactor + motionCenter;

    float2 edgeCorrectionOffset = 0;
    if (sourceUvAtScreenCorner00.x < 0.0) edgeCorrectionOffset.x -= sourceUvAtScreenCorner00.x * zoomScaleFactor.x;
    if (sourceUvAtScreenCorner11.x > 1.0) edgeCorrectionOffset.x -= (sourceUvAtScreenCorner11.x - 1.0) * zoomScaleFactor.x;
    if (sourceUvAtScreenCorner00.y < 0.0) edgeCorrectionOffset.y -= sourceUvAtScreenCorner00.y * zoomScaleFactor.y;
    if (sourceUvAtScreenCorner11.y > 1.0) edgeCorrectionOffset.y -= (sourceUvAtScreenCorner11.y - 1.0) * zoomScaleFactor.y;
    
    transformedUv += edgeCorrectionOffset;
    transformedUv = clamp(transformedUv, AS_EPSILON, 1.0 - AS_EPSILON); 

    return tex2D(ReShade::BackBuffer, transformedUv);
}

// ============================================================================
// PASS 5: Data Storage
// ============================================================================
float4 PS_MotionFocusStorageNorm(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target 
{
    return tex2D(NormSampler, texcoord);
}

float PS_MotionFocusStorageMotion(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target 
{
    return tex2D(QuadFullSampler, texcoord).r;
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_VFX_MotionFocus < ui_tooltip = "Dynamically zooms towards detected motion areas with motion-centered zoom.\nRequires multiple frames to initialize.\nExposes advanced tuning parameters for fine control."; >
{
    pass MotionFocusNormPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusNorm;
        RenderTarget = NormTex;
    }
    pass MotionFocusQuadFullPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusQuadFull;
        RenderTarget = QuadFullTex;
    }
    pass MotionFocusCalcPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocus;
        RenderTarget = FocusTex;
    }
    pass MotionFocusDisplayPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusDisplay;
    }
    pass MotionFocusStorageNormPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusStorageNorm;
        RenderTarget = PrevFrameTex;
    }
    pass MotionFocusStorageMotionPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusStorageMotion;
        RenderTarget = PrevMotionTex;
    }
}

#endif // __AS_VFX_MotionFocus_1_fx