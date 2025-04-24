/**
 * AS_MV-MotionTrails.1.fx - Music-Reactive Depth-Based Trail Effect
 * Author: Leon Aquitaine (based on original code)
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader creates striking motion trails that persist over time, perfect for music videos.
 * Objects within a specified depth threshold leave behind colored trails that slowly fade,
 * creating dynamic visual paths ideal for dramatic footage and creative compositions.
 *
 * FEATURES:
 * - Depth-based subject tracking for dynamic trail effects
 * - User-definable trail color, strength, and persistence
 * - Audio-reactive trail timing, intensity and colors through Listeningway
 * - Multiple blend modes for scene integration
 * - Optional real-time subject highlight for better visualization
 * - Precise depth control for targeting specific scene elements
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. The shader uses Listeningway's timing system to capture scene snapshots at regular intervals
 * 2. Objects within a customizable depth threshold are isolated and stored
 * 3. These captured images are accumulated over time with a controllable fade rate
 * 4. Audio can modulate capture timing, trail intensity and colors for dynamic effects
 * 
 * ===================================================================================
 */

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "ListeningwayUniforms.fxh"
#include "AS_Utils.1.fxh"

// --- Helper Functions and Namespace ---
namespace AS_DepthEcho {
    // Get audio source value directly using AS_getAudioSource
    float getAudioSource(int source) {
        #if defined(LISTENINGWAY_INSTALLED)
            return AS_getAudioSource(source);
        #else
            return source == 1 ? 1.0 : 0.0; // Return 1.0 for "Solid" option when Listeningway not installed
        #endif
    }
}

// --- UI Uniforms - Main Design Controls ---
uniform float fEcho_DepthCutoff < ui_type = "slider"; ui_min = 0.01; ui_max = 0.5; ui_step = 0.01; ui_label = "Subject Focus"; ui_tooltip = "Objects closer than this depth value will create trails"; ui_category = "Trail Design"; > = 0.04;
uniform float fEcho_FadeRate < ui_type = "slider"; ui_min = 0.8; ui_max = 0.99; ui_step = 0.01; ui_label = "Trail Persistence"; ui_tooltip = "How slowly trails fade away (higher = longer lasting)"; ui_category = "Trail Design"; > = 0.95;
uniform float3 fEcho_Color < ui_type = "color"; ui_label = "Trail Hue"; ui_tooltip = "Color of the trail effect"; ui_category = "Trail Design"; > = float3(0.2, 0.5, 1.0);
uniform float fEcho_Strength < ui_type = "slider"; ui_min = 0.1; ui_max = 2.0; ui_step = 0.1; ui_label = "Trail Intensity"; ui_tooltip = "Intensity of the trail effect"; ui_category = "Trail Design"; > = 0.8;
uniform int iEcho_SubjectOverlay < ui_type = "combo"; ui_label = "Subject Overlay"; ui_tooltip = "How to display the subject in front of the trail effect."; ui_items = "Show Character\0Pulse Character\0Show Silhouette\0"; ui_category = "Trail Design"; > = 0;
uniform float3 fEcho_SilhouetteColor < ui_type = "color"; ui_label = "Silhouette Color"; ui_tooltip = "Color to use for the subject silhouette when 'Show Silhouette' is selected."; ui_category = "Trail Design"; > = float3(0.0, 0.0, 0.0);
uniform bool bEcho_ForceClear < ui_type = "bool"; ui_label = "Clear All Trails"; ui_tooltip = "Set this to true and toggle once to force-clear all trails."; ui_category = "Trail Design"; > = false;

// --- Trail Timing ---
uniform int iEcho_CaptureMode < ui_type = "combo"; ui_label = "Timing Method"; ui_tooltip = "Controls how frequently trail markers are created"; ui_items = "Tempo-Based\0Every N Frames\0On Audio Beat\0Manual Trigger\0"; ui_category = "Trail Timing"; > = 0;
uniform float fEcho_TimeInterval < ui_type = "slider"; ui_min = 0; ui_max = 5000; ui_step = 25; ui_label = "Beat Interval (ms)"; ui_tooltip = "Time between trail markers in milliseconds when using Tempo-Based mode (0 = continuous)"; ui_category = "Trail Timing"; > = 1000.0;
uniform int iEcho_FrameInterval < ui_type = "slider"; ui_min = 1; ui_max = 60; ui_step = 1; ui_label = "Frame Spacing"; ui_tooltip = "Create a trail marker every N frames when using frame-based mode"; ui_category = "Trail Timing"; > = 15;
uniform bool bEcho_ManualCapture < ui_type = "bool"; ui_label = "Drop Trail Marker"; ui_tooltip = "Toggle this to manually create a trail marker when in Manual Trigger mode"; ui_category = "Trail Timing"; > = false;

// --- Beat Synchronization ---
AS_LISTENINGWAY_UI_CONTROLS("Beat Synchronization")
AS_AUDIO_SOURCE_UI(Echo_TimingSource, "Rhythm Source", AS_AUDIO_BEAT, "Beat Synchronization")
AS_AUDIO_MULTIPLIER_UI(Echo_TimingMult, "Beat Impact", 0.5, 1.0, "Beat Synchronization")
AS_AUDIO_SOURCE_UI(Echo_IntensitySource, "Energy Source", AS_AUDIO_BEAT, "Beat Synchronization")
AS_AUDIO_MULTIPLIER_UI(Echo_IntensityMult, "Energy Boost", 0.5, 2.0, "Beat Synchronization")

// --- Final Composition and Debug (moved to end) ---
uniform int BlendMode < ui_type = "combo"; ui_label = "Mix Style"; ui_tooltip = "How the trail effect blends with the original scene."; ui_items = "Normal\0Lighter Only\0Darker Only\0Additive\0Multiply\0Screen\0"; ui_category = "Final Composition"; > = 0;
uniform float BlendAmount < ui_type = "slider"; ui_label = "Effect Opacity"; ui_tooltip = "How strongly the effect is blended with the scene."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Final Composition"; > = 1.0;

// --- Debug Mode Uniform ---
AS_DEBUG_MODE_UI("Off\0Depth Mask\0Echo Buffer\0Linear Depth\0")

// Add frame counter for frame-based capture mode
uniform int frameCount < source = "framecount"; >;

// --- Variables to track beat detection ---
uniform float PrevBeatValue < source = "frametime"; >;

// --- Textures and Samplers ---
texture EchoAccumBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler sEchoAccumBuffer { Texture = EchoAccumBuffer; };

texture EchoAccumTempBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler sEchoAccumTempBuffer { Texture = EchoAccumTempBuffer; };

texture EchoTimingBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG32F; };
sampler sEchoTimingBuffer { Texture = EchoTimingBuffer; };

texture EchoTimingPrevBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG32F; }; 
sampler sEchoTimingPrevBuffer { Texture = EchoTimingPrevBuffer; };

// --- Pixel Shader: Pass 1 (Timing and Capture State Update) ---
void PS_TimingCaptureUpdate(
    float4 vpos : SV_Position,
    float2 texcoord : TEXCOORD,
    out float2 out_TimingCapture : SV_Target0 // Output RG float to EchoTimingBuffer
) {
    // --- Read Previous Frame's State ---
    float2 prevTimingCapture = tex2D(sEchoTimingPrevBuffer, texcoord).rg;
    float lastCapturePhase = prevTimingCapture.r; // Phase stored at the end of the last frame
    float captureStoredLastFrame = prevTimingCapture.g; // Previous capture state
    
    // Define variables
    float currentPhase = Listeningway_TotalPhases60Hz; // Phase at the start of *this* frame
    bool capture = false;
    
    // Determine if we should capture based on the selected capture mode
    switch (iEcho_CaptureMode)
    {
        case 0: // Tempo-Based Mode
            // Special case: if interval is 0, capture every frame (continuous)
            if (fEcho_TimeInterval <= 0.0) {
                capture = true;
                break;
            }
            
            // Apply audio reactivity to the interval timing
            float baseInterval = fEcho_TimeInterval;
            float audioValue = AS_DepthEcho::getAudioSource(Echo_TimingSource);
            // Shorter intervals when audio is high (faster captures)
            baseInterval = max(25.0, fEcho_TimeInterval * (1.0 - audioValue * Echo_TimingMult));
            
            float intervalInPhases = baseInterval * (60.0 / 1000.0);
            
            // Force initialization if needed
            if (lastCapturePhase < 0.001f) {
                // Initialize with a value that will immediately trigger a capture
                lastCapturePhase = currentPhase - (intervalInPhases * 2.0f);
            }

            // --- Timing Check using Previous Frame's Phase ---
            float phaseDifference = currentPhase - lastCapturePhase;
            if (lastCapturePhase > 1.0f && phaseDifference < -100.0f) {
                phaseDifference += 65536.0f;
            }
            
            // Capture if phaseDifference exceeds our interval threshold
            capture = (phaseDifference >= intervalInPhases);
            break;
            
        case 1: // Frame-Based Mode
            // Capture every N frames where N is iEcho_FrameInterval
            capture = (frameCount % iEcho_FrameInterval == 0);
            break;
            
        case 2: // On Audio Beat Mode
            #if defined(LISTENINGWAY_INSTALLED)
                // Use a static variable to track the on-beat flag
                static bool onBeat = false;
                float currentBeatValue = Listeningway_Beat;
                // If not on beat and beat is high, trigger and set flag
                if (!onBeat && currentBeatValue >= 1.0) {
                    capture = true;
                    onBeat = true;
                }
                // If on beat and beat drops below 0.8, unset flag
                else if (onBeat && currentBeatValue < 0.8) {
                    onBeat = false;
                }
            #else
                // Fallback when Listeningway isn't installed - use frame-based approach
                capture = (frameCount % 30 == 0); // Default to every 30 frames (about twice per second at 60fps)
            #endif
            break;
            
        case 3: // Manual Trigger Mode
            // Capture only when manually triggered
            capture = bEcho_ManualCapture;
            break;
    }

    // --- Determine values to store for *next* frame ---
    float phaseToStore = capture ? currentPhase : lastCapturePhase;
    float captureStateToStore = capture ? 1.0 : 0.0; // Store raw capture state (0 or 1)

    // --- Write Output ---
    out_TimingCapture = float2(phaseToStore, captureStateToStore);
}

// --- Pixel Shader: Pass 2 (Accumulation Update) ---
void PS_EchoAccum(
    float4 vpos : SV_Position,
    float2 texcoord : TEXCOORD,
    out float4 out_Accum : SV_Target0 // Output RGBA8 to EchoAccumTempBuffer
) {
    // Check if we should force-clear the buffer
    if (bEcho_ForceClear) {
        // If force clear is active, reset everything to black
        out_Accum = float4(0.0, 0.0, 0.0, 0.0);
        return;
    }
    
    // --- Read Previous State from main buffer ---
    float4 prevAccum = tex2D(sEchoAccumBuffer, texcoord);
    // Read the capture state calculated and stored in Pass 1 of *this* frame.
    float captureState = tex2D(sEchoTimingBuffer, texcoord).g; // Read Green channel

    // --- Calculate Current Mask ---
    float linearDepth = ReShade::GetLinearizedDepth(texcoord);
    float currMask = step(linearDepth, fEcho_DepthCutoff);

    // --- Determine capture based on the state from timing pass ---
    bool capture = (captureState > 0.5);
    
    // --- Apply audio reactivity to echo strength ---
    float effectiveStrength = fEcho_Strength;
    float audioValue = AS_DepthEcho::getAudioSource(Echo_IntensitySource);
    effectiveStrength *= (1.0 + audioValue * Echo_IntensityMult);

    // --- Accumulation Logic ---
    float4 fadedAccum = prevAccum * fEcho_FadeRate;
    float4 newEcho = float4(fEcho_Color * currMask * effectiveStrength, currMask * effectiveStrength);
    float4 finalAccum = fadedAccum + (capture ? newEcho : 0.0);

    out_Accum = saturate(finalAccum);
}

// --- Pixel Shader: Pass 3 (Copy Back) ---
void PS_CopyBackAccum(
    float4 vpos : SV_Position,
    float2 texcoord : TEXCOORD,
    out float4 out_Accum : SV_Target0 // Output RGBA8 to EchoAccumBuffer
) {
    // Simply copy from temp buffer back to main buffer
    out_Accum = tex2D(sEchoAccumTempBuffer, texcoord);
}

// --- Pixel Shader: Pass 4 (Compositing) ---
void PS_EchoComposite(
    float4 vpos : SV_Position,
    float2 texcoord : TEXCOORD,
    out float4 out_Color : SV_Target0
) {
    // Read necessary buffers
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float4 echoColor = tex2D(sEchoAccumBuffer, texcoord);

    // --- Create the base echo effect ---
    float3 echoEffect = echoColor.rgb;
    
    // --- Apply blend mode using AS_Utils helper ---
    float3 blendedResult = AS_blendResult(originalColor.rgb, echoEffect, BlendMode);
    
    // --- Final blend with original using user-defined strength ---
    float3 finalResult = lerp(originalColor.rgb, blendedResult, BlendAmount * echoColor.a);

    // --- Debug Modes ---
    if (DebugMode > 0)
    {
        float linearDepth = ReShade::GetLinearizedDepth(texcoord);
        float currMask = step(linearDepth, fEcho_DepthCutoff);

        // Simplified debug options
        if (DebugMode == 1) { finalResult = currMask.xxx; }
        else if (DebugMode == 2) { finalResult = echoColor.rgb; }
        else if (DebugMode == 3) { finalResult = linearDepth.xxx; }
    }

    // --- Subject Overlay Modes ---
    float linearDepth = ReShade::GetLinearizedDepth(texcoord);
    float currMask = step(linearDepth, fEcho_DepthCutoff);
    if (iEcho_SubjectOverlay == 0) {
        // Show Character: overlay the original color where masked
        finalResult = lerp(finalResult, originalColor.rgb, currMask);
    } else if (iEcho_SubjectOverlay == 1) {
        // Pulse Character: do nothing, just show the effect
        // (No overlay)
    } else if (iEcho_SubjectOverlay == 2) {
        // Show Silhouette: overlay the selected color where masked
        finalResult = lerp(finalResult, fEcho_SilhouetteColor, currMask);
    }

    out_Color = float4(saturate(finalResult), originalColor.a);
}

// --- Pixel Shader: Pass 5 (Copy Timing Buffer) ---
void PS_CopyTimingBuffer(
    float4 vpos : SV_Position,
    float2 texcoord : TEXCOORD,
    out float2 out_TimingCapture : SV_Target0 // Output RG float to EchoTimingPrevBuffer
) {
    // Simply copy the current frame's timing data to the previous frame buffer
    out_TimingCapture = tex2D(sEchoTimingBuffer, texcoord).rg;
}

// --- Technique ---
technique AS_MV_MotionTrails_1 <
    ui_label = "[AS] Music Video: Motion Trails";
    ui_tooltip = "Creates dynamic motion trails perfect for music videos and creative compositions.";
>
{
    pass TimingCapturePass {
        VertexShader = PostProcessVS;
        PixelShader = PS_TimingCaptureUpdate;
        RenderTarget0 = EchoTimingBuffer;
        ClearRenderTargets = false;
    }
    pass AccumPass {
        VertexShader = PostProcessVS;
        PixelShader = PS_EchoAccum;
        RenderTarget0 = EchoAccumTempBuffer;
        ClearRenderTargets = false;
    }
    pass CopyBackPass {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyBackAccum;
        RenderTarget0 = EchoAccumBuffer;
        ClearRenderTargets = false;
    }
    pass CompositePass {
        VertexShader = PostProcessVS;
        PixelShader = PS_EchoComposite;
    }
    pass CopyTimingBufferPass {
        VertexShader = PostProcessVS;
        PixelShader = PS_CopyTimingBuffer;
        RenderTarget0 = EchoTimingPrevBuffer;
        ClearRenderTargets = false;
    }
}