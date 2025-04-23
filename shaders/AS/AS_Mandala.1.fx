/**
 * AS_Mandala.1.fx - Audio-Reactive Mandala UV Meter Shader
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader creates a stylized, audio-reactive mandala effect that acts as a UV meter using all available
 * Listeningway audio bands. The mandala is colored from blue (low) through red to orange/yellow (high),
 * and can be repeated and mirrored for various visual styles.
 *
 * FEATURES:
 * - Uses all Listeningway audio bands for a full-spectrum visualizer
 * - Color gradient from blue (low) to yellow (high) based on band intensity
 * - User-selectable number of repetitions (2-16)
 * - Pattern style: linear or mirrored
 * - Centered, circular mandala with smooth animation
 *
 * ===================================================================================
 */

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "ListeningwayUniforms.fxh"
#include "AS_Utils.fxh"

// --- Palette & Style ---
uniform int MandalaColorPattern < ui_type = "combo"; ui_label = "Color Pattern"; ui_items = "Rainbow\0Intensity Reds\0Intensity Blues\0Blue-White\0Black-White\0Fire\0Aqua\0Pastel\0Neon\0Viridis\0Transparent-White\0Transparent-Black\0"; ui_category = "Palette & Style"; > = 0;
uniform bool MandalaInvertColors < ui_label = "Invert Colors"; ui_tooltip = "Invert the color pattern (reverse gradient direction)."; ui_category = "Palette & Style"; > = false;

// --- Mandala Appearance ---
uniform int MandalaRepetitions < ui_type = "slider"; ui_label = "Repetitions"; ui_tooltip = "Number of mandala repetitions (actual repetitions = 2^value)."; ui_min = 1; ui_max = 8; ui_step = 1; ui_category = "Mandala Appearance"; > = 3;
uniform int MandalaPattern < ui_type = "combo"; ui_label = "Pattern"; ui_items = "Linear\0Mirrored\0"; ui_category = "Mandala Appearance"; > = 0;
uniform float MandalaRadius < ui_type = "slider"; ui_label = "Radius"; ui_tooltip = "Base radius of the mandala."; ui_min = 0.1; ui_max = 0.5; ui_step = 0.01; ui_category = "Mandala Appearance"; > = 0.25;
uniform float MandalaThickness < ui_type = "slider"; ui_label = "Thickness"; ui_tooltip = "Thickness of the mandala pattern."; ui_min = 0.01; ui_max = 0.15; ui_step = 0.005; ui_category = "Mandala Appearance"; > = 0.05;
uniform float MandalaFade < ui_type = "slider"; ui_label = "Fade"; ui_tooltip = "Edge fade for the mandala pattern."; ui_min = 0.0; ui_max = 0.2; ui_step = 0.01; ui_category = "Mandala Appearance"; > = 0.08;

// --- Mandala Shape & Transparency ---
uniform int MandalaShape < ui_type = "combo"; ui_label = "Shape"; ui_items = "Screen-Relative\0Circular\0"; ui_category = "Shape & Transparency"; > = 0;
uniform int MandalaAlphaSource < ui_type = "combo"; ui_label = "Transparency Source"; ui_items = "Off\0Solid\0Volume\0Beat\0Bass\0Treble\0"; ui_category = "Shape & Transparency"; > = 3;

// --- Depth & Debug ---
uniform float MandalaDepth < ui_type = "slider"; ui_label = "Depth"; ui_tooltip = "Controls the reference depth for the mandala effect. Lower values bring the effect closer to the camera, higher values push it further back."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Cut-off Distance"; > = 0.05;

uniform int BlendMode < ui_type = "combo"; ui_label = "Mode"; ui_items = "Normal\0Lighter Only\0Darker Only\0Additive\0Multiply\0Screen\0"; ui_category = "Blend"; > = 0;
uniform float BlendAmount < ui_type = "slider"; ui_label = "Amount"; ui_tooltip = "How strongly the mandala effect is blended with the scene."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Blend"; > = 1.0;

uniform int DebugMode < ui_type = "combo"; ui_label = "Debug Mode"; ui_tooltip = "Show debug visualizations."; ui_items = "Off\0Bands\0"; ui_category = "Debug"; > = 0;

// --- Frame Count ---
uniform int frameCount < source = "framecount"; >;

// --- Listeningway Integration ---
uniform bool EnableListeningway < ui_label = "Enable Listeningway"; ui_tooltip = "Enable audio-reactive controls using the Listeningway addon. When enabled, effects will respond to music and sound. [Learn more](https://github.com/gposingway/Listeningway)"; ui_category = "Listeningway Integration"; > = false;

// --- Color Gradient Helper ---
float3 bandColor(float t) {
    if (MandalaInvertColors) t = 1.0 - t;
    if (MandalaColorPattern == 0) {
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
    } else if (MandalaColorPattern == 1) {
        // Intensity Reds
        float3 c0 = float3(0.2, 0.0, 0.0); // Dark red
        float3 c1 = float3(0.6, 0.1, 0.1); // Medium red
        float3 c2 = float3(1.0, 0.2, 0.2); // Bright red
        float3 c3 = float3(1.0, 0.5, 0.2); // Orange
        float seg = t * 3.0;
        if (seg < 1.0) return lerp(c0, c1, seg);
        else if (seg < 2.0) return lerp(c1, c2, seg - 1.0);
        else return lerp(c2, c3, seg - 2.0);
    } else if (MandalaColorPattern == 2) {
        // Intensity Blues
        float3 c0 = float3(0.0, 0.0, 0.2); // Dark blue
        float3 c1 = float3(0.0, 0.2, 0.6); // Medium blue
        float3 c2 = float3(0.2, 0.4, 1.0); // Bright blue
        float3 c3 = float3(0.6, 0.8, 1.0); // Light blue
        float seg = t * 3.0;
        if (seg < 1.0) return lerp(c0, c1, seg);
        else if (seg < 2.0) return lerp(c1, c2, seg - 1.0);
        else return lerp(c2, c3, seg - 2.0);
    } else if (MandalaColorPattern == 3) {
        // Blue to White
        return lerp(float3(0.2, 0.4, 1.0), float3(1.0, 1.0, 1.0), t);
    } else if (MandalaColorPattern == 4) {
        // Black to White
        return lerp(float3(0.0, 0.0, 0.0), float3(1.0, 1.0, 1.0), t);
    } else if (MandalaColorPattern == 5) {
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
    } else if (MandalaColorPattern == 6) {
        // Aqua (deep blue -> cyan -> aqua -> white)
        float3 c0 = float3(0.0, 0.2, 0.4);
        float3 c1 = float3(0.0, 0.8, 1.0);
        float3 c2 = float3(0.2, 1.0, 0.8);
        float3 c3 = float3(1.0, 1.0, 1.0);
        float seg = t * 3.0;
        if (seg < 1.0) return lerp(c0, c1, seg);
        else if (seg < 2.0) return lerp(c1, c2, seg - 1.0);
        else return lerp(c2, c3, seg - 2.0);
    } else if (MandalaColorPattern == 7) {
        // Pastel (soft blue -> pink -> yellow -> mint)
        float3 c0 = float3(0.7, 0.8, 1.0);
        float3 c1 = float3(1.0, 0.7, 0.9);
        float3 c2 = float3(1.0, 1.0, 0.7);
        float3 c3 = float3(0.7, 1.0, 0.8);
        float seg = t * 3.0;
        if (seg < 1.0) return lerp(c0, c1, seg);
        else if (seg < 2.0) return lerp(c1, c2, seg - 1.0);
        else return lerp(c2, c3, seg - 2.0);
    } else if (MandalaColorPattern == 8) {
        // Neon (magenta -> blue -> green -> yellow)
        float3 c0 = float3(1.0, 0.0, 1.0);
        float3 c1 = float3(0.2, 0.2, 1.0);
        float3 c2 = float3(0.0, 1.0, 0.2);
        float3 c3 = float3(1.0, 1.0, 0.0);
        float seg = t * 3.0;
        if (seg < 1.0) return lerp(c0, c1, seg);
        else if (seg < 2.0) return lerp(c1, c2, seg - 1.0);
        else return lerp(c2, c3, seg - 2.0);
    } else if (MandalaColorPattern == 9) {
        // Viridis (dark blue -> green -> yellow)
        float3 c0 = float3(0.2, 0.2, 0.4);
        float3 c1 = float3(0.2, 0.8, 0.4);
        float3 c2 = float3(0.9, 0.9, 0.2);
        float seg = t * 2.0;
        if (seg < 1.0) return lerp(c0, c1, seg);
        else return lerp(c1, c2, seg - 1.0);
    } else if (MandalaColorPattern == 10) {
        // Transparent to White (color is always white, but alpha is t)
        return float3(1.0, 1.0, 1.0);
    } else if (MandalaColorPattern == 11) {
        // Transparent to Black (color is always black, but alpha is t)
        return float3(0.0, 0.0, 0.0);
    }
    return float3(1.0, 1.0, 1.0);
}

// --- Main Effect ---
float4 PS_Mandala(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float2 center = float2(0.5, 0.5);
    float2 uv = texcoord - center;
    float2 screen = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float aspect = screen.x / screen.y;
    float dist;
    float time = AS_getTime(frameCount);
    if (MandalaShape == 1) {
        float minDim = min(screen.x, screen.y);
        float2 uv_circ = float2(uv.x * screen.x / minDim, uv.y * screen.y / minDim);
        dist = length(uv_circ);
    } else {
        dist = length(uv);
    }
    float angle = AS_radians(atan2(uv.y, uv.x));
    int bands = 8;
#ifdef Listeningway_FreqBands
    bands = 8;
#endif
    int realRepetitions = 1 << MandalaRepetitions;
    int totalBars = bands * realRepetitions;
    float barStep = 6.2831853 / float(totalBars);
    float barIdxF = AS_mymod(angle + 3.1415926, 6.2831853) / barStep;
    int barIdx = int(floor(barIdxF));
    int freqIdx;
    if (MandalaPattern == 0) {
        freqIdx = barIdx % bands;
    } else {
        int mirrorLen = bands * 2;
        int mirroredIdx = barIdx % mirrorLen;
        if (mirroredIdx < bands) {
            freqIdx = mirroredIdx;
        } else {
            freqIdx = mirrorLen - 1 - mirroredIdx;
        }
    }
    freqIdx = clamp(freqIdx, 0, bands - 1);
    float bandValue = Listeningway_FreqBands[freqIdx];
    float radius = MandalaRadius + bandValue * 0.18;
    float thickness = MandalaThickness + bandValue * 0.04;
    float fade = MandalaFade;
    float edge = smoothstep(radius, radius + thickness, dist) * (1.0 - smoothstep(radius + thickness, radius + thickness + fade, dist));
    float mask = 1.0;
    if (MandalaShape == 1) {
        float maxR = MandalaRadius + 0.18 + MandalaThickness + MandalaFade;
        mask = 1.0 - smoothstep(maxR, maxR + 0.05, dist);
    }
    float3 color = bandColor(bandValue);
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    float effectDepth = MandalaDepth;
    if (sceneDepth < effectDepth - 0.0005)
        return orig;
    float alpha = 1.0;
#if defined(LISTENINGWAY_INSTALLED)
    if (MandalaAlphaSource == 0) alpha = 0.0;
    else if (MandalaAlphaSource == 1) alpha = 1.0;
    else if (MandalaAlphaSource == 2) alpha = Listeningway_Volume;
    else if (MandalaAlphaSource == 3) alpha = Listeningway_Beat;
    else if (MandalaAlphaSource == 4) alpha = Listeningway_FreqBands[0];
    else if (MandalaAlphaSource == 5) alpha = Listeningway_FreqBands[7];
#endif
    if (MandalaColorPattern == 10 || MandalaColorPattern == 11) {
        alpha *= bandValue;
    }
    if (DebugMode == 1) return float4(bandValue.xxx, 1.0);
    float3 blended = AS_blendResult(orig.rgb, color, BlendMode);
    float blendAlpha = edge * mask * alpha * BlendAmount;
    return float4(lerp(orig.rgb, blended, blendAlpha), 1.0);
}

technique AS_Mandala < ui_label = "[AS] Mandala"; ui_tooltip = "Audio-reactive mandala UV meter using all audio bands."; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_Mandala;
    }
}
