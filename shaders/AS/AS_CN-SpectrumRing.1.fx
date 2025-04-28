/**
 * AS_CN-SpectrumRing.1.fx - Audio-Reactive Circular Frequency Visualizer
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader creates a stylized, audio-reactive circular frequency spectrum visualization that maps
 * all available Listeningway audio bands to a ring display. The spectrum is colored from blue (low) 
 * through red to orange/yellow (high), with customizable patterns and styles.
 *
 * FEATURES:
 * - Uses all Listeningway audio bands (up to 32) for a full-spectrum visualizer
 * - Color gradient from blue (low) to yellow (high) based on band intensity
 * - User-selectable number of repetitions (2-16)
 * - Pattern style: linear or mirrored
 * - Centered, circular visualization with smooth animation
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Divides a circle into segments, with each segment representing an audio frequency band
 * 2. Maps audio band values to the radius and thickness of each segment
 * 3. Colors segments based on their intensity using configurable color palettes
 * 4. Blends the result with the scene based on depth and configured blend mode
 * 
 * ===================================================================================
 */

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "AS_Utils.1.fxh"

// --- Tunable Constants ---
static const int REPETITIONS_MIN = 1;
static const int REPETITIONS_MAX = 8;
static const int REPETITIONS_DEFAULT = 3;
static const float RADIUS_MIN = 0.1;
static const float RADIUS_MAX = 0.5;
static const float RADIUS_DEFAULT = 0.25;
static const float THICKNESS_MIN = 0.01;
static const float THICKNESS_MAX = 0.15;
static const float THICKNESS_DEFAULT = 0.05;
static const float FADE_MIN = 0.0;
static const float FADE_MAX = 0.2;
static const float FADE_DEFAULT = 0.08;
static const float BANDMULT_MIN = 0.0;
static const float BANDMULT_MAX = 3.0;
static const float BANDMULT_DEFAULT = 1.0;
static const float EFFECTDEPTH_MIN = 0.0;
static const float EFFECTDEPTH_MAX = 1.0;
static const float EFFECTDEPTH_DEFAULT = 0.05;
static const float BLENDSTRENGTH_MIN = 0.0;
static const float BLENDSTRENGTH_MAX = 1.0;
static const float BLENDSTRENGTH_DEFAULT = 1.0;

// --- Palette & Style ---
uniform int ColorPattern < ui_type = "combo"; ui_label = "Color Pattern"; ui_items = "Rainbow\0Intensity Reds\0Intensity Blues\0Blue-White\0Black-White\0Fire\0Aqua\0Pastel\0Neon\0Viridis\0Transparent-White\0Transparent-Black\0"; ui_category = "Palette & Style"; > = 0;
uniform bool InvertColors < ui_label = "Invert Colors"; ui_tooltip = "Invert the color pattern (reverse gradient direction)."; ui_category = "Palette & Style"; > = false;

// --- Effect-Specific Appearance ---
uniform int Repetitions < ui_type = "slider"; ui_label = "Repetitions"; ui_tooltip = "Number of spectrum repetitions (actual repetitions = 2^value)."; ui_min = REPETITIONS_MIN; ui_max = REPETITIONS_MAX; ui_step = 1; ui_category = "Effect-Specific Appearance"; > = REPETITIONS_DEFAULT;
uniform int PatternStyle < ui_type = "combo"; ui_label = "Pattern Style"; ui_items = "Linear\0Mirrored\0"; ui_category = "Effect-Specific Appearance"; > = 0;
uniform float Radius < ui_type = "slider"; ui_label = "Radius"; ui_tooltip = "Base radius of the spectrum ring."; ui_min = RADIUS_MIN; ui_max = RADIUS_MAX; ui_step = 0.01; ui_category = "Effect-Specific Appearance"; > = RADIUS_DEFAULT;
uniform float Thickness < ui_type = "slider"; ui_label = "Thickness"; ui_tooltip = "Thickness of the spectrum ring pattern."; ui_min = THICKNESS_MIN; ui_max = THICKNESS_MAX; ui_step = 0.005; ui_category = "Effect-Specific Appearance"; > = THICKNESS_DEFAULT;
uniform float Fade < ui_type = "slider"; ui_label = "Fade"; ui_tooltip = "Edge fade for the spectrum ring pattern."; ui_min = FADE_MIN; ui_max = FADE_MAX; ui_step = 0.01; ui_category = "Effect-Specific Appearance"; > = FADE_DEFAULT;
uniform int Shape < ui_type = "combo"; ui_label = "Shape"; ui_items = "Screen-Relative\0Circular\0"; ui_category = "Effect-Specific Appearance"; > = 0;

// --- Audio Reactivity ---
AS_AUDIO_SOURCE_UI(AlphaSource, "Transparency Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_SOURCE_UI(RadiusSource, "Radius Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(RadiusMult, "Radius Impact", 0.5, 2.0, "Audio Reactivity")
uniform int BandTarget < ui_type = "combo"; ui_label = "Band Target"; ui_tooltip = "What property to adjust based on band intensity"; ui_items = "Radius\0Thickness\0"; ui_category = "Audio Reactivity"; > = 0;
uniform float BandMult < ui_type = "slider"; ui_label = "Band Impact"; ui_tooltip = "How strongly the selected frequency band affects the target property."; ui_min = BANDMULT_MIN; ui_max = BANDMULT_MAX; ui_step = 0.1; ui_category = "Audio Reactivity"; > = BANDMULT_DEFAULT;

// --- Stage Distance ---
uniform float EffectDepth < ui_type = "slider"; ui_label = "Effect Depth"; ui_tooltip = "Controls the reference depth for the spectrum ring effect. Lower values bring the effect closer to the camera, higher values push it further back."; ui_min = EFFECTDEPTH_MIN; ui_max = EFFECTDEPTH_MAX; ui_step = 0.01; ui_category = "Stage Distance"; > = EFFECTDEPTH_DEFAULT;

// --- Final Mix ---
uniform int BlendMode < ui_type = "combo"; ui_label = "Blend Mode"; ui_items = "Normal\0Lighter Only\0Darker Only\0Additive\0Multiply\0Screen\0"; ui_category = "Final Mix"; > = 0;
uniform float BlendStrength < ui_type = "slider"; ui_label = "Blend Strength"; ui_tooltip = "How strongly the spectrum ring effect is blended with the scene."; ui_min = BLENDSTRENGTH_MIN; ui_max = BLENDSTRENGTH_MAX; ui_step = 0.01; ui_category = "Final Mix"; > = BLENDSTRENGTH_DEFAULT;

// --- Debug ---
AS_DEBUG_MODE_UI("Off\0Bands\0")

// --- Helper Functions ---
namespace AS_SpectrumRing {
    // Color gradient helper
    float3 bandColor(float t) {
        if (InvertColors) t = 1.0 - t;
        if (ColorPattern == 0) {
            // Rainbow
            float3 c0 = float3(0.2, 0.4, 1.0);   // Blue
            float3 c1 = float3(0.0, 0.8, 1.0);   // Cyan
            float3 c2 = float3(0.0, 1.0, 0.4);   // Aqua-Green
            float3 c3 = float3(0.0, 1.0, 0.0);   // Green
            float3 c4 = float3(1.0, 1.0, 0.0);   // Yellow
            float3 c5 = float3(1.0, 0.6, 0.0);   // Orange
            float3 c6 = float3(1.0, 0.2, 0.0);   // Red-Orange
            float3 c7 = float3(1.0, 0.0, 0.0);   // Red
            float3 c8 = float3(1.0, 0.5, 0.2);   // Orange-Yellow (high)
            float seg = t * 7.0;
            if (seg < 1.0) return lerp(c0, c1, seg);
            else if (seg < 2.0) return lerp(c1, c2, seg - 1.0);
            else if (seg < 3.0) return lerp(c2, c3, seg - 2.0);
            else if (seg < 4.0) return lerp(c3, c4, seg - 3.0);
            else if (seg < 5.0) return lerp(c4, c5, seg - 4.0);
            else if (seg < 6.0) return lerp(c5, c6, seg - 5.0);
            else if (seg < 7.0) return lerp(c6, c7, seg - 6.0);
            else return lerp(c7, c8, (t - 1.0) * 8.0 + 1.0);
        } else if (ColorPattern == 1) {
            // Intensity Reds
            float3 c0 = float3(0.2, 0.0, 0.0); // Dark red
            float3 c1 = float3(0.6, 0.1, 0.1); // Medium red
            float3 c2 = float3(1.0, 0.2, 0.2); // Bright red
            float3 c3 = float3(1.0, 0.5, 0.2); // Orange
            float seg = t * 3.0;
            if (seg < 1.0) return lerp(c0, c1, seg);
            else if (seg < 2.0) return lerp(c1, c2, seg - 1.0);
            else return lerp(c2, c3, seg - 2.0);
        } else if (ColorPattern == 2) {
            // Intensity Blues
            float3 c0 = float3(0.0, 0.0, 0.2); // Dark blue
            float3 c1 = float3(0.0, 0.2, 0.6); // Medium blue
            float3 c2 = float3(0.2, 0.4, 1.0); // Bright blue
            float3 c3 = float3(0.6, 0.8, 1.0); // Light blue
            float seg = t * 3.0;
            if (seg < 1.0) return lerp(c0, c1, seg);
            else if (seg < 2.0) return lerp(c1, c2, seg - 1.0);
            else return lerp(c2, c3, seg - 2.0);
        } else if (ColorPattern == 3) {
            // Blue to White
            return lerp(float3(0.2, 0.4, 1.0), float3(1.0, 1.0, 1.0), t);
        } else if (ColorPattern == 4) {
            // Black to White
            return lerp(float3(0.0, 0.0, 0.0), float3(1.0, 1.0, 1.0), t);
        } else if (ColorPattern == 5) {
            // Fire (dark red -> orange -> yellow -> white)
            float3 c0 = float3(0.2, 0.0, 0.0);
            float3 c1 = float3(0.8, 0.2, 0.0);
            float3 c2 = float3(1.0, 0.6, 0.0);
            float3 c3 = float3(1.0, 1.0, 0.2);
            float3 c4 = float3(1.0, 1.0, 1.0);
            float seg = t * 4.0;
            if (seg < 1.0) return lerp(c0, c1, seg);
            else if (seg < 2.0) return lerp(c1, c2, seg - 1.0);
            else if (seg < 3.0) return lerp(c2, c3, seg - 2.0);
            else return lerp(c3, c4, seg - 3.0);
        } else if (ColorPattern == 6) {
            // Aqua (deep blue -> cyan -> aqua -> white)
            float3 c0 = float3(0.0, 0.2, 0.4);
            float3 c1 = float3(0.0, 0.8, 1.0);
            float3 c2 = float3(0.2, 1.0, 0.8);
            float3 c3 = float3(1.0, 1.0, 1.0);
            float seg = t * 3.0;
            if (seg < 1.0) return lerp(c0, c1, seg);
            else if (seg < 2.0) return lerp(c1, c2, seg - 1.0);
            else return lerp(c2, c3, seg - 2.0);
        } else if (ColorPattern == 7) {
            // Pastel (soft blue -> pink -> yellow -> mint)
            float3 c0 = float3(0.7, 0.8, 1.0);
            float3 c1 = float3(1.0, 0.7, 0.9);
            float3 c2 = float3(1.0, 1.0, 0.7);
            float3 c3 = float3(0.7, 1.0, 0.8);
            float seg = t * 3.0;
            if (seg < 1.0) return lerp(c0, c1, seg);
            else if (seg < 2.0) return lerp(c1, c2, seg - 1.0);
            else return lerp(c2, c3, seg - 2.0);
        } else if (ColorPattern == 8) {
            // Neon (magenta -> blue -> green -> yellow)
            float3 c0 = float3(1.0, 0.0, 1.0);
            float3 c1 = float3(0.2, 0.2, 1.0);
            float3 c2 = float3(0.0, 1.0, 0.2);
            float3 c3 = float3(1.0, 1.0, 0.0);
            float seg = t * 3.0;
            if (seg < 1.0) return lerp(c0, c1, seg);
            else if (seg < 2.0) return lerp(c1, c2, seg - 1.0);
            else return lerp(c2, c3, seg - 2.0);
        } else if (ColorPattern == 9) {
            // Viridis (dark blue -> green -> yellow)
            float3 c0 = float3(0.2, 0.2, 0.4);
            float3 c1 = float3(0.2, 0.8, 0.4);
            float3 c2 = float3(0.9, 0.9, 0.2);
            float seg = t * 2.0;
            if (seg < 1.0) return lerp(c0, c1, seg);
            else return lerp(c1, c2, seg - 1.0);
        } else if (ColorPattern == 10) {
            // Transparent to White (color is always white, but alpha is t)
            return float3(1.0, 1.0, 1.0);
        } else if (ColorPattern == 11) {
            // Transparent to Black (color is always black, but alpha is t)
            return float3(0.0, 0.0, 0.0);
        }
        return float3(1.0, 1.0, 1.0);
    }
} // End namespace AS_SpectrumRing

// --- Main Effect ---
float4 PS_SpectrumRing(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Get original color and apply depth cutoff
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    
    if (sceneDepth < EffectDepth - 0.0005)
        return orig;
    
    // Calculate spectrum ring position and coordinates
    float2 center = float2(0.5, 0.5);
    float2 uv = texcoord - center;
    float2 screen = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float aspect = screen.x / screen.y;
    float dist;
    
    // Always show at least something in debug mode, even without Listeningway
    bool debugMode = (DebugMode == 1);
    
    // Handle different shape modes
    if (Shape == 1) {
        // Circular mode - adjust for aspect ratio
        float minDim = min(screen.x, screen.y);
        float2 uv_circ = float2(uv.x * screen.x / minDim, uv.y * screen.y / minDim);
        dist = length(uv_circ);
    } else {
        // Screen-relative mode - use raw distance
        dist = length(uv);
    }
    
    // Calculate angle and map to frequency band
    float angle = atan2(uv.y, uv.x);
    
    // Calculate repetitions and total number of bars
    int realRepetitions = 1 << Repetitions;
    
    // Map angle to bar index
    float barStep = AS_TWO_PI / float(realRepetitions * max(1, AS_getNumFrequencyBands()));
    float barIdxF = AS_mod(angle + AS_PI, AS_TWO_PI) / barStep;
    int barIdx = int(floor(barIdxF));
    
    // Calculate frequency index based on pattern type
    int freqIdx;
    int numBands = max(1, min(AS_getNumFrequencyBands(), 32)); // Ensure at least 1 band
    
    if (PatternStyle == 0) {
        // Linear pattern - simple modulo
        freqIdx = barIdx % numBands;
    } else {
        // Mirrored pattern - reflect indices
        int mirrorLen = numBands * 2;
        int mirroredIdx = barIdx % mirrorLen;
        if (mirroredIdx < numBands) {
            freqIdx = mirroredIdx;
        } else {
            freqIdx = mirrorLen - 1 - mirroredIdx;
        }
    }
    
    // Get audio band value, fallback to 0.5 in debug mode if no Listeningway
    float bandValue = 0.0;
    
    // Fallback for debugging
    if (debugMode) {
        // Generate a simple pattern for debugging
        bandValue = sin(freqIdx * 0.5 + AS_getTime() * 2.0) * 0.5 + 0.5;
    } else {
        // Use standardized frequency band access function from AS_Utils
        // This will automatically handle different band sizes and provide graceful fallback
        bandValue = AS_getFrequencyBand(freqIdx);
    }
    
    // Apply audio reactivity to radius
    float audioRadius = max(0.1, AS_getAudioSource(RadiusSource));
    float radius = Radius * (1.0 + audioRadius * RadiusMult);
    
    // Apply band intensity to selected target property for this specific band
    float thickness = Thickness;
    if (BandTarget == 0) {
        // Apply to radius - each band affects its own segment
        radius *= (1.0 + bandValue * BandMult);
    } else if (BandTarget == 1) {
        // Apply to thickness - each band affects its own segment
        thickness *= (1.0 + bandValue * BandMult);
    }
    
    // Create ring shape with smooth edges
    float edge = smoothstep(radius, radius + thickness, dist) * 
                (1.0 - smoothstep(radius + thickness, radius + thickness + Fade, dist));
    
    // Apply shape mask if in circular mode
    float mask = 1.0;
    if (Shape == 1) {
        float maxR = Radius + 0.18 + Thickness + Fade;
        mask = 1.0 - smoothstep(maxR, maxR + 0.05, dist);
    }
    
    // Get color based on band value
    float3 color = AS_SpectrumRing::bandColor(bandValue);
    
    // Handle audio-reactive transparency - ensure minimum value for visibility
    float alpha = max(0.5, AS_getAudioSource(AlphaSource));
    
    // Special handling for transparent color patterns
    if (ColorPattern == 10 || ColorPattern == 11) {
        alpha *= max(0.3, bandValue);
    }
    
    // Debug mode - show band value with color
    if (debugMode) {
        return float4(color * bandValue, 1.0);
    }
    
    // Apply blend mode and blend amount
    float3 blended = AS_blendResult(orig.rgb, color, BlendMode);
    float blendAlpha = edge * mask * alpha * BlendStrength;
    
    return float4(lerp(orig.rgb, blended, blendAlpha), 1.0);
}

technique AS_SpectrumRing < ui_label = "[AS] Cinematic: Spectrum Ring"; ui_tooltip = "Audio-reactive spectrum ring UV meter using all audio bands."; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_SpectrumRing;
    }
}
