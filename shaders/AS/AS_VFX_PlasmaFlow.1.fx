/**
 * AS_VFX_PlasmaFlow.1.fx - Audio-Reactive Plasma/Flow Field Shader
 * Author: Leon Aquitaine (rewrite by Copilot)
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Sophisticated, gentle, and flexible plasma effect for groovy, atmospheric visuals. Generates smooth, swirling, organic patterns with customizable color gradients and strong audio reactivity. Ideal for music video backgrounds and overlays.
 *
 * FEATURES:
 * - Procedural plasma/noise with domain warping for fluid, swirling motion
 * - 2-4 user-defined colors with smooth gradient mapping
 * - Controls for speed, scale, complexity, stretch, and warp
 * - Audio-reactive modulation of movement, color, brightness, and turbulence
 * - Standard blend modes and debug views
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Generates fBm noise with domain warping for plasma base
 * 2. Maps noise to a user-defined color gradient
 * 3. Modulates parameters with audio (Listeningway)
 * 4. Blends with scene using standard blend modes
 *
 * ===================================================================================
 */



#include "AS_Utils.1.fxh"

// --- Tunable Constants ---
static const int PLASMA_COLORS = 6;

// Scale factors
static const float SCALE_MIN = 0.2;
static const float SCALE_MAX = 10.0;
static const float SCALE_DEFAULT = 1.2; // Balanced pattern size

// Animation speed
static const float SPEED_MIN = 0.01;
static const float SPEED_MAX = 2.0;
static const float SPEED_DEFAULT = 0.08; // Gentle flow speed

// Pattern complexity (octaves of noise)
static const float COMPLEXITY_MIN = 1.0;
static const float COMPLEXITY_MAX = 8.0; // Maximum octaves processed
static const float COMPLEXITY_DEFAULT = 4.0; // Good balance between detail and performance

// Domain warping intensity
static const float WARP_MIN = 0.0;
static const float WARP_MAX = 10.0;
static const float WARP_DEFAULT = 0.7; // Mild swirling effect

// Aspect ratio adjustment
static const float STRETCH_MIN = 0.5;
static const float STRETCH_MAX = 2.0;
static const float STRETCH_DEFAULT = 1.0; // No stretching

// Pattern bias/offset
static const float BIAS_MIN = -0.5;
static const float BIAS_MAX = 0.5;
static const float BIAS_DEFAULT = 0.0; // Centered in color distribution

// Pattern contrast
static const float CONTRAST_MIN = 0.1;
static const float CONTRAST_MAX = 3.0;
static const float CONTRAST_DEFAULT = 1.0; // Neutral contrast

// Effect blend strength
static const float BLEND_AMOUNT_MIN = 0.0;
static const float BLEND_AMOUNT_MAX = 1.0;
static const float BLEND_AMOUNT_DEFAULT = 1.0; // Full effect strength

// --- Palette & Style ---
// Palette selector
uniform int PlasmaPalette < ui_type = "combo"; ui_label = "Palette"; ui_items = "60s Groovy\0Vaporwave\0Inferno\0Aurora\0Neon Dream\0Psytrance\0Sunset\0Deep Ocean\0Electric Storm\0Pastel Flow\0Mystic Night\0Custom\0"; ui_category = "Palette & Style"; > = 10;
// 6 user colors for Custom
uniform float3 PlasmaColor0 < ui_type = "color"; ui_label = "Color 1"; ui_category = "Palette & Style"; > = float3(0.72, 0.82, 1.0); // Dreamy blue
uniform float3 PlasmaColor1 < ui_type = "color"; ui_label = "Color 2"; ui_category = "Palette & Style"; > = float3(0.93, 0.76, 1.0); // Lavender
uniform float3 PlasmaColor2 < ui_type = "color"; ui_label = "Color 3"; ui_category = "Palette & Style"; > = float3(0.98, 0.89, 0.98); // Soft pink
uniform float3 PlasmaColor3 < ui_type = "color"; ui_label = "Color 4"; ui_category = "Palette & Style"; > = float3(0.85, 0.98, 0.93); // Mint
uniform float3 PlasmaColor4 < ui_type = "color"; ui_label = "Color 5"; ui_category = "Palette & Style"; > = float3(0.98, 0.96, 0.82); // Cream
uniform float3 PlasmaColor5 < ui_type = "color"; ui_label = "Color 6"; ui_category = "Palette & Style"; > = float3(0.80, 0.90, 0.98); // Pale sky

// Palette presets (hardcoded)
float3 getPaletteColor(int idx, int colorIdx) {
    // Each palette: 6 colors
    // 10 = Custom (use user colors)
    if (idx == 0) { // 60s Groovy
        float3 c[6] = {float3(0.98,0.62,0.11), float3(0.98,0.11,0.36), float3(0.36,0.11,0.98), float3(0.11,0.98,0.62), float3(0.98,0.89,0.11), float3(0.11,0.62,0.98)};
        return c[colorIdx];
    } else if (idx == 1) { // Vaporwave
        float3 c[6] = {float3(0.58,0.36,0.98), float3(0.98,0.36,0.82), float3(0.36,0.98,0.98), float3(0.98,0.82,0.36), float3(0.36,0.58,0.98), float3(0.98,0.58,0.36)};
        return c[colorIdx];
    } else if (idx == 2) { // Inferno
        float3 c[6] = {float3(0.98,0.36,0.11), float3(0.98,0.62,0.11), float3(0.98,0.89,0.11), float3(0.98,0.36,0.36), float3(0.62,0.11,0.11), float3(0.36,0.11,0.11)};
        return c[colorIdx];
    } else if (idx == 3) { // Aurora
        float3 c[6] = {float3(0.11,0.98,0.62), float3(0.11,0.62,0.98), float3(0.36,0.98,0.36), float3(0.62,0.11,0.98), float3(0.36,0.36,0.98), float3(0.11,0.98,0.98)};
        return c[colorIdx];
    } else if (idx == 4) { // Neon Dream
        float3 c[6] = {float3(0.98,0.11,0.62), float3(0.11,0.98,0.36), float3(0.36,0.11,0.98), float3(0.98,0.36,0.98), float3(0.36,0.98,0.62), float3(0.98,0.98,0.36)};
        return c[colorIdx];
    } else if (idx == 5) { // Psytrance
        float3 c[6] = {float3(0.11,0.98,0.36), float3(0.36,0.98,0.11), float3(0.98,0.36,0.62), float3(0.62,0.11,0.98), float3(0.98,0.62,0.36), float3(0.36,0.62,0.98)};
        return c[colorIdx];
    } else if (idx == 6) { // Sunset
        float3 c[6] = {float3(0.98,0.62,0.36), float3(0.98,0.36,0.11), float3(0.98,0.89,0.36), float3(0.98,0.62,0.11), float3(0.62,0.36,0.11), float3(0.36,0.11,0.11)};
        return c[colorIdx];
    } else if (idx == 7) { // Deep Ocean
        float3 c[6] = {float3(0.11,0.36,0.98), float3(0.11,0.62,0.98), float3(0.36,0.98,0.98), float3(0.36,0.62,0.98), float3(0.11,0.98,0.62), float3(0.11,0.36,0.62)};
        return c[colorIdx];
    } else if (idx == 8) { // Electric Storm
        float3 c[6] = {float3(0.98,0.98,0.36), float3(0.36,0.98,0.98), float3(0.36,0.36,0.98), float3(0.98,0.36,0.98), float3(0.98,0.36,0.36), float3(0.36,0.98,0.36)};
        return c[colorIdx];
    } else if (idx == 9) { // Pastel Flow
        float3 c[6] = {float3(0.98,0.82,0.82), float3(0.82,0.98,0.98), float3(0.98,0.98,0.82), float3(0.82,0.82,0.98), float3(0.98,0.82,0.98), float3(0.82,0.98,0.82)};
        return c[colorIdx];
    } else if (idx == 10) { // Mystic Night
        float3 c[6] = {float3(0.11,0.11,0.36), float3(0.36,0.11,0.36), float3(0.11,0.36,0.36), float3(0.36,0.36,0.11), float3(0.11,0.11,0.11), float3(0.36,0.11,0.11)};
        return c[colorIdx];
    }
    // Custom
    if (colorIdx == 0) return PlasmaColor0;
    if (colorIdx == 1) return PlasmaColor1;
    if (colorIdx == 2) return PlasmaColor2;
    if (colorIdx == 3) return PlasmaColor3;
    if (colorIdx == 4) return PlasmaColor4;
    return PlasmaColor5;
}

// --- Plasma Appearance ---
uniform float PlasmaScale < ui_type = "slider"; ui_label = "Scale"; ui_tooltip = "Zoom/scale of the plasma pattern."; ui_min = SCALE_MIN; ui_max = SCALE_MAX; ui_step = 0.01; ui_category = "Plasma Appearance"; > = SCALE_DEFAULT;
uniform float PlasmaComplexity < ui_type = "slider"; ui_label = "Complexity"; ui_tooltip = "Number of noise octaves (detail)."; ui_min = COMPLEXITY_MIN; ui_max = COMPLEXITY_MAX; ui_step = 0.1; ui_category = "Plasma Appearance"; > = COMPLEXITY_DEFAULT;
uniform float PlasmaWarp < ui_type = "slider"; ui_label = "Warp Intensity"; ui_tooltip = "Strength of domain warping (swirliness)."; ui_min = WARP_MIN; ui_max = WARP_MAX; ui_step = 0.01; ui_category = "Plasma Appearance"; > = WARP_DEFAULT;
uniform float PlasmaStretch < ui_type = "slider"; ui_label = "Stretch"; ui_tooltip = "Horizontal/vertical stretch of the plasma."; ui_min = STRETCH_MIN; ui_max = STRETCH_MAX; ui_step = 0.01; ui_category = "Plasma Appearance"; > = STRETCH_DEFAULT;
uniform float PlasmaBias < ui_type = "slider"; ui_label = "Plasma Bias"; ui_tooltip = "Shifts the plasma pattern to use more of the color gradient (try 0.0 to 1.0)."; ui_min = BIAS_MIN; ui_max = BIAS_MAX; ui_step = 0.01; ui_category = "Plasma Appearance"; > = BIAS_DEFAULT;
uniform float PlasmaContrast < ui_type = "slider"; ui_label = "Plasma Contrast"; ui_tooltip = "Compresses or expands the color bands. Lower = more blended, Higher = more distinct bands."; ui_min = CONTRAST_MIN; ui_max = CONTRAST_MAX; ui_step = 0.01; ui_category = "Plasma Appearance"; > = CONTRAST_DEFAULT;

// --- Animation ---
uniform float PlasmaSpeed < ui_type = "slider"; ui_label = "Speed"; ui_tooltip = "How quickly the plasma flows."; ui_min = SPEED_MIN; ui_max = SPEED_MAX; ui_step = 0.01; ui_category = "Animation"; > = SPEED_DEFAULT;

// --- Audio Reactivity ---

AS_AUDIO_SOURCE_UI(AudioMoveSource, "Movement Source", AS_AUDIO_VOLUME, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(AudioMoveMult, "Movement Strength", 1.0, 4.0, "Audio Reactivity")
AS_AUDIO_SOURCE_UI(AudioColorSource, "Color Source", AS_AUDIO_BASS, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(AudioColorMult, "Color Strength", 1.0, 4.0, "Audio Reactivity")
AS_AUDIO_SOURCE_UI(AudioComplexitySource, "Complexity Source", AS_AUDIO_TREBLE, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(AudioComplexityMult, "Complexity Strength", 1.0, 4.0, "Audio Reactivity")

// --- Stage Distance ---
uniform float EffectDepth < ui_type = "slider"; ui_label = "Distance"; ui_tooltip = "Reference depth for the effect. Lower = closer, higher = further."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Stage Distance"; > = 0.05;

// --- Final Mix ---
uniform int BlendMode < ui_type = "combo"; ui_label = "Mode"; ui_items = "Normal\0Lighter Only\0Darker Only\0Additive\0Multiply\0Screen\0"; ui_category = "Final Mix"; > = 0;
uniform float BlendAmount < ui_type = "slider"; ui_label = "Strength"; ui_tooltip = "How strongly the plasma effect is blended with the scene."; ui_min = BLEND_AMOUNT_MIN; ui_max = BLEND_AMOUNT_MAX; ui_step = 0.01; ui_category = "Final Mix"; > = BLEND_AMOUNT_DEFAULT;

// --- Debug ---
AS_DEBUG_MODE_UI("Off\0Noise\0DomainWarp\0Audio\0")

// --- System Uniforms ---

// --- Helper Functions ---
namespace AS_PlasmaFlow {
    // Simple 2D value noise using AS_hash21
    float valueNoise(float2 p) {
        float2 i = floor(p);
        float2 f = frac(p);
        float2 u = f * f * (3.0 - 2.0 * f);
        float a = AS_hash11(dot(i, float2(127.1, 311.7)));
        float b = AS_hash11(dot(i + float2(1, 0), float2(127.1, 311.7)));
        float c = AS_hash11(dot(i + float2(0, 1), float2(127.1, 311.7)));
        float d = AS_hash11(dot(i + float2(1, 1), float2(127.1, 311.7)));
        return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
    }

    // Fractional Brownian Motion (fBm) with domain warping
    float fbm(float2 p, float time, float octaves, float warp, float stretch) {
        float2 q = p;
        float amp = 0.5;
        float freq = 1.0;
        float sum = 0.0;
        float2 warpAccum = 0.0;
        for (int i = 0; i < 8; ++i) {
            if (i >= octaves) break;
            float n = valueNoise(q + warpAccum);
            sum += n * amp;
            // Domain warp: accumulate offset for next octave
            float angle = n * 6.2831 + time * 0.2;
            float2 offset = float2(cos(angle), sin(angle)) * warp * amp;
            warpAccum += offset;
            q = float2(q.x * stretch, q.y);
            amp *= 0.5;
            freq *= 2.0;
            q *= 2.0;
        }
        return sum;
    }

    // Map normalized noise value to a 6-color gradient (palette aware)
    float3 plasmaGradient(float t) {
        t = saturate(t);
        float3 c0 = getPaletteColor(PlasmaPalette, 0);
        float3 c1 = getPaletteColor(PlasmaPalette, 1);
        float3 c2 = getPaletteColor(PlasmaPalette, 2);
        float3 c3 = getPaletteColor(PlasmaPalette, 3);
        float3 c4 = getPaletteColor(PlasmaPalette, 4);
        float3 c5 = getPaletteColor(PlasmaPalette, 5);
        if (t < 1.0/5.0) return lerp(c0, c1, t * 5.0);
        else if (t < 2.0/5.0) return lerp(c1, c2, (t - 1.0/5.0) * 5.0);
        else if (t < 3.0/5.0) return lerp(c2, c3, (t - 2.0/5.0) * 5.0);
        else if (t < 4.0/5.0) return lerp(c3, c4, (t - 3.0/5.0) * 5.0);
        else return lerp(c4, c5, (t - 4.0/5.0) * 5.0);
    }
}

// --- Main Effect ---
float4 PS_PlasmaFlow(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Get original color and apply depth cutoff
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    if (sceneDepth < EffectDepth - 0.0005)
        return orig;

    // --- Plasma Parameter Calculation ---
    float time = AS_getTime();
    // Audio-reactive speed
    float moveAudio = AS_getAudioSource(AudioMoveSource) * AudioMoveMult;
    float speed = PlasmaSpeed * (1.0 + moveAudio);
    // Audio-reactive complexity
    float complexityAudio = AS_getAudioSource(AudioComplexitySource) * AudioComplexityMult;
    float octaves = clamp(PlasmaComplexity + complexityAudio, COMPLEXITY_MIN, COMPLEXITY_MAX);
    // Audio-reactive warp
    float warpAudio = AS_getAudioSource(AudioMoveSource) * AudioMoveMult;
    float warp = PlasmaWarp * (1.0 + warpAudio);
    // Audio-reactive color shift
    float colorAudio = AS_getAudioSource(AudioColorSource) * AudioColorMult;

    // --- UV and Domain Warping ---
    float2 uv = texcoord;
    uv = AS_aspectCorrect(uv, BUFFER_WIDTH, BUFFER_HEIGHT);
    uv -= 0.5;
    uv.x *= PlasmaStretch;
    uv += 0.5;
    float2 p = uv * PlasmaScale;
    float t = time * speed;
    // Domain warp: use a secondary fbm to warp the main input
    float2 warpVec = float2(
        AS_PlasmaFlow::fbm(p + t, t * 0.25, octaves, warp, PlasmaStretch),
        AS_PlasmaFlow::fbm(p - t, t * 0.15, octaves, warp, PlasmaStretch)
    );
    p += warpVec * warp * 0.25;

    // --- Main Plasma Noise ---
    float n = AS_PlasmaFlow::fbm(p + t, t, octaves, warp, PlasmaStretch);
    n = 0.5 + (n - 0.5) * PlasmaContrast; // Contrast control
    n = saturate(n);
    n = saturate(n + PlasmaBias); // Bias for user control
    n = saturate(n + colorAudio * 0.15);

    // --- Color Mapping ---
    float3 plasmaColor = AS_PlasmaFlow::plasmaGradient(n);

    // --- Debug Modes ---
    if (DebugMode == 1) return float4(n.xxx, 1.0); // Noise
    if (DebugMode == 2) return float4((warpVec.x + 0.5) * 0.5, (warpVec.y + 0.5) * 0.5, 0.0, 1.0); // Domain warp
    if (DebugMode == 3) return float4(colorAudio.xxx, 1.0); // Audio

    // --- Blending ---
    float3 finalColor = AS_blendResult(orig.rgb, plasmaColor, BlendMode);
    finalColor = lerp(orig.rgb, finalColor, BlendAmount);

    return float4(finalColor, 1.0);
}

technique AS_PlasmaFlow_1 < ui_label = "[AS] VFX: Plasma Flow"; ui_tooltip = "Audio-reactive plasma/flow field for groovy, atmospheric visuals."; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_PlasmaFlow;
    }
}
