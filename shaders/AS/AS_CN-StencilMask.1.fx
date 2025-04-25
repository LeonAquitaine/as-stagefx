/**
 * AS_CN-StencilMask.1.fx - Creates a stencil mask effect with borders and shadows.
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Isolates foreground subjects based on depth and applies customizable borders
 * and projected shadows around them. Includes options for various border styles,
 * shadow appearance, and audio reactivity for dynamic effects.
 *
 * FEATURES:
 * - Depth-based subject isolation.
 * - Multiple border styles (Solid, Glow, Pulse, Dash, Double Line).
 * - Customizable border color, opacity, thickness, and smoothing.
 * - Optional projected shadow with customizable color, opacity, offset, and blur (blur/expand not yet implemented).
 * - Audio reactivity via Listeningway for border thickness, pulse, and shadow movement.
 * - Debug modes for visualizing masks.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Create a binary mask based on depth (ForegroundPlane).
 * 2. Dilate the mask based on BorderThickness and BorderSmoothing settings.
 * 3. Apply optional smoothing (MeltStrength) to the dilated mask.
 * 4. Apply selected BorderStyle, potentially using audio input (Pulse).
 * 5. Calculate a similar mask for the shadow at an offset (ShadowOffset), potentially moved by audio.
 * 6. Composite the shadow, border, and original subject color.
 * 
 * ===================================================================================
 */

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "AS_Utils.1.fxh"

// --- Tunable Constants ---
static const float PI = 3.14159265359;
static const int MAX_SHADOW_SAMPLES = 16; // Note: Not currently used, consider removing if final
static const float MAX_EDGE_BIAS = 10.0; // Note: Not currently used, consider removing if final
static const float FOREGROUNDPLANE_MIN = 0.0;
static const float FOREGROUNDPLANE_MAX = 1.0;
static const float FOREGROUNDPLANE_DEFAULT = 0.05;
static const float BORDEROPACITY_MIN = 0.0;
static const float BORDEROPACITY_MAX = 1.0;
static const float BORDEROPACITY_DEFAULT = 1.0;
static const float BORDERTHICKNESS_MIN = 0.0;
static const float BORDERTHICKNESS_MAX = 0.25;
static const float BORDERTHICKNESS_DEFAULT = 0.02;
static const float MELTSTRENGTH_MIN = 0.0;
static const float MELTSTRENGTH_MAX = 1.0;
static const float MELTSTRENGTH_DEFAULT = 0.0;
static const float SHADOWOPACITY_MIN = 0.0;
static const float SHADOWOPACITY_MAX = 1.0;
static const float SHADOWOPACITY_DEFAULT = 0.5;
static const float SHADOWOFFSET_MIN = -0.05;
static const float SHADOWOFFSET_MAX = 0.05;
static const float SHADOWOFFSET_DEFAULT_X = 0.003;
static const float SHADOWOFFSET_DEFAULT_Y = 0.003;
static const float SHADOWBLUR_MIN = 0.0;
static const float SHADOWBLUR_MAX = 20.0;
static const float SHADOWBLUR_DEFAULT = 4.0;
static const float SHADOWEXPAND_MIN = 0.0;
static const float SHADOWEXPAND_MAX = 5.0;
static const float SHADOWEXPAND_DEFAULT = 1.5;

// --- Subject Detection ---
uniform float ForegroundPlane < ui_type = "slider"; ui_label = "Foreground Plane"; ui_tooltip = "Depth threshold for foreground subjects."; ui_min = FOREGROUNDPLANE_MIN; ui_max = FOREGROUNDPLANE_MAX; ui_step = 0.01; ui_category = "Effect-Specific Appearance"; > = FOREGROUNDPLANE_DEFAULT;

// --- Border Settings ---
uniform int BorderStyle < ui_type = "combo"; ui_label = "Border Style"; ui_items = "Solid\\0Glow\\0Pulse\\0Dash\\0Double Line\\0"; ui_category = "Effect-Specific Appearance"; > = 0; // Category updated
uniform float3 BorderColor < ui_type = "color"; ui_label = "Border Color"; ui_category = "Effect-Specific Appearance"; > = float3(1.0, 1.0, 1.0); // Category updated
uniform float BorderOpacity < ui_type = "slider"; ui_label = "Border Opacity"; ui_min = BORDEROPACITY_MIN; ui_max = BORDEROPACITY_MAX; ui_step = 0.01; ui_category = "Effect-Specific Appearance"; > = BORDEROPACITY_DEFAULT; // Renamed, Label updated, Category updated
uniform float BorderThickness < ui_type = "slider"; ui_label = "Border Thickness"; ui_min = BORDERTHICKNESS_MIN; ui_max = BORDERTHICKNESS_MAX; ui_step = 0.001; ui_category = "Effect-Specific Appearance"; > = BORDERTHICKNESS_DEFAULT; // Category updated
uniform float MeltStrength < ui_type = "slider"; ui_label = "Border Melt"; ui_tooltip = "Smooths/melts jagged border ends. 0 = off, higher = more smoothing."; ui_min = MELTSTRENGTH_MIN; ui_max = MELTSTRENGTH_MAX; ui_step = 0.01; ui_category = "Effect-Specific Appearance"; > = MELTSTRENGTH_DEFAULT; // Category updated
// 0: 4 dir, 1: 8 dir, 2: 16 dir, 3: 32 dir, 4: 64 dir
uniform int BorderSmoothing < ui_type = "combo"; ui_label = "Border Smoothing"; ui_items = "4 directions\\0" "8 directions\\0" "16 directions\\0" "32 directions\\0" "64 directions\\0"; ui_category = "Effect-Specific Appearance"; > = 2; // Category updated

// --- Shadow Settings ---
uniform bool EnableShadow < ui_label = "Enable Shadow"; ui_category = "Effect-Specific Appearance"; > = true; // Category updated
uniform float3 ShadowColor < ui_type = "color"; ui_label = "Shadow Color"; ui_category = "Effect-Specific Appearance"; > = float3(0.0, 0.0, 0.0); // Category updated
uniform float ShadowOpacity < ui_type = "slider"; ui_label = "Shadow Opacity"; ui_min = SHADOWOPACITY_MIN; ui_max = SHADOWOPACITY_MAX; ui_step = 0.01; ui_category = "Effect-Specific Appearance"; > = SHADOWOPACITY_DEFAULT; // Renamed, Label updated, Category updated
uniform float2 ShadowOffset < ui_type = "slider"; ui_min = SHADOWOFFSET_MIN; ui_max = SHADOWOFFSET_MAX; ui_step = 0.001; ui_label = "Shadow Offset"; ui_category = "Effect-Specific Appearance"; > = float2(SHADOWOFFSET_DEFAULT_X, SHADOWOFFSET_DEFAULT_Y); // Category updated
uniform float ShadowBlur < ui_type = "slider"; ui_label = "Shadow Blur"; ui_min = SHADOWBLUR_MIN; ui_max = SHADOWBLUR_MAX; ui_step = 0.1; ui_category = "Effect-Specific Appearance"; > = SHADOWBLUR_DEFAULT; // Category updated // Note: Not currently used, consider implementing or removing
uniform float ShadowExpand < ui_type = "slider"; ui_label = "Shadow Expand"; ui_min = SHADOWEXPAND_MIN; ui_max = SHADOWEXPAND_MAX; ui_step = 0.1; ui_category = "Effect-Specific Appearance"; > = SHADOWEXPAND_DEFAULT; // Category updated // Note: Not currently used, consider implementing or removing

// --- Audio Reactivity ---
AS_LISTENINGWAY_UI_CONTROLS("Audio Reactivity") // Adds EnableListeningway uniform
AS_AUDIO_SOURCE_UI(BorderThicknessSource, "Border Thickness Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(BorderThicknessMult, "Border Thickness Impact", 0.5, 1.0, "Audio Reactivity")
AS_AUDIO_SOURCE_UI(BorderPulseSource, "Border Pulse Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(BorderPulseMult, "Border Pulse Impact", 1.0, 3.0, "Audio Reactivity")
AS_AUDIO_SOURCE_UI(ShadowOffsetSource, "Shadow Movement Source", AS_AUDIO_BASS, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(ShadowOffsetMult, "Shadow Movement Impact", 1.0, 3.0, "Audio Reactivity")

// --- Debug ---
AS_DEBUG_MODE_UI("Off\\0Subject Mask\\0Border Only\\0Shadow Only\\0")

// --- Helper Functions ---
namespace AS_StencilMask {

    // Create subject mask (1.0 for subject, 0.0 for background)
    float subjectMask(float2 texcoord) {
        float depth = ReShade::GetLinearizedDepth(texcoord);
        return depth < ForegroundPlane ? 1.0 : 0.0;
    }

    // Helper to get minimum screen dimension
    float minScreenDim() {
        return min(ReShade::ScreenSize.x, ReShade::ScreenSize.y);
    }

    // 2D Dilation with variable directions
    float dilateMask_2D(float2 texcoord, float thicknessNorm, int directions) {
        float2 pixelSize = ReShade::PixelSize;
        float minDim = minScreenDim();
        float radius = thicknessNorm * minDim;
        float maxMask = 0.0;
        for (int i = 0; i < directions; i++) {
            float angle = (PI * 2.0 / directions) * i;
            float2 offset = float2(cos(angle), sin(angle)) * pixelSize * radius;
            float mask = subjectMask(texcoord + offset);
            maxMask = max(maxMask, mask);
        }
        maxMask = max(maxMask, subjectMask(texcoord));
        return maxMask;
    }

    // Smoothing (melt) for the dilated mask only
    float smoothDilatedMask(float2 texcoord, float thicknessNorm, int smoothingMode, float meltStrength) {
        int directions = 4;
        if (smoothingMode == 1) directions = 8;
        else if (smoothingMode == 2) directions = 16;
        else if (smoothingMode == 3) directions = 32;
        else if (smoothingMode == 4) directions = 64;
        if (meltStrength <= 0.0) {
            return dilateMask_2D(texcoord, thicknessNorm, directions);
        }
        float2 pixelSize = ReShade::PixelSize;
        float sum = 0.0;
        float weightSum = 0.0;
        for (int x = -1; x <= 1; x++) {
            for (int y = -1; y <= 1; y++) {
                float2 offset = float2(x, y) * pixelSize * meltStrength;
                float sampleValue = dilateMask_2D(texcoord + offset, thicknessNorm, directions);
                float weight = 1.0;
                sum += sampleValue * weight;
                weightSum += weight;
            }
        }
        return sum / weightSum;
    }

    // Animated border styles
    float applyBorderStyle(float borderMask, float time, int style, float audioPulse, float2 texcoord) {
        if (style == 0) return borderMask; // Solid
        if (style == 1) return borderMask * (0.75 + 0.25 * sin(time * 2.0)); // Glow
        if (style == 2) return borderMask * (1.0 + audioPulse * 0.5); // Pulse (uses BorderPulseSource)
        if (style == 3) { // Dash
            float dash = sin(texcoord.x * 50.0 + time * 2.0) * 0.5 + 0.5;
            return borderMask * smoothstep(0.4, 0.6, dash);
        }
        if (style == 4) { // Double Line
            float inner = smoothstep(0.4, 0.6, borderMask);
            float outer = smoothstep(0.8, 1.0, borderMask);
            return (inner - outer) * 2.0; // This might need adjustment based on desired look
        }
        return borderMask;
    }

    // Note: meltBorder function was complex and potentially inefficient for single-pass.
    // The smoothDilatedMask function with MeltStrength achieves a similar goal more directly.
    // Removing meltBorder to simplify.

} // end namespace AS_StencilMask

// --- Main Effect ---
float4 PS_StencilMask(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float time = AS_getTime(); // Use utility function for time

    // --- Audio Reactivity Values ---
    float audioPulse = 0.0;
    float shadowMovement = 0.0;
    float borderThicknessAudio = 0.0;

    if (EnableListeningway) { // Check the UI toggle
        audioPulse = AS_getAudioSource(BorderPulseSource) * BorderPulseMult;
        shadowMovement = AS_getAudioSource(ShadowOffsetSource) * ShadowOffsetMult;
        // Only calculate border thickness audio if source is selected
        if (BorderThicknessSource > 0) {
            borderThicknessAudio = AS_getAudioSource(BorderThicknessSource);
        }
    }

    // --- Subject Mask ---
    float subjectMask = AS_StencilMask::subjectMask(texcoord);

    // --- Border Calculation ---
    float borderMask = 0.0;
    // Calculate reactive border thickness: Base + (Audio * Multiplier)
    float borderThicknessReactive = BorderThickness;
    if (EnableListeningway && BorderThicknessSource > 0) {
        float additionalThickness = borderThicknessAudio * BorderThicknessMult;
        borderThicknessReactive += additionalThickness;
    }
    // Ensure thickness doesn't go below zero if base is small and audio/mult are negative (though mult UI prevents this)
    borderThicknessReactive = max(0.0, borderThicknessReactive);

    // Dilate and smooth the mask
    float dilatedMask = AS_StencilMask::smoothDilatedMask(texcoord, borderThicknessReactive, BorderSmoothing, MeltStrength);
    // Apply border style (pulse uses audioPulse calculated earlier)
    borderMask = AS_StencilMask::applyBorderStyle(dilatedMask, time, BorderStyle, audioPulse, texcoord);

    // --- Shadow Calculation ---
    float shadowMask = 0.0;
    float2 dynamicOffset = ShadowOffset; // Start with base offset

    if (EnableShadow) {
        // Apply audio-reactive movement if enabled
        if (EnableListeningway && ShadowOffsetSource > 0 && shadowMovement > 0.01) {
            dynamicOffset += float2(
                sin(time * 2.0) * shadowMovement * 0.01, // Scale movement effect
                cos(time * 1.7) * shadowMovement * 0.01
            );
        }

        float2 shadowCoord = texcoord + dynamicOffset;
        // Use the same reactive thickness for the shadow dilation
        float dilatedMaskShadow = AS_StencilMask::smoothDilatedMask(shadowCoord, borderThicknessReactive, BorderSmoothing, MeltStrength);
        // Apply border style to shadow mask (using shadowCoord for texture-dependent styles like Dash)
        shadowMask = AS_StencilMask::applyBorderStyle(dilatedMaskShadow, time, BorderStyle, audioPulse, shadowCoord);
    }

    // --- Debug Modes ---
    if (DebugMode == 1) return float4(subjectMask.xxx, 1.0); // Subject Mask
    if (DebugMode == 2) { // Border Only
        // Apply alpha directly for debug view
        return float4(BorderColor, borderMask * BorderOpacity); // Updated uniform name
    }
    if (DebugMode == 3 && EnableShadow) { // Shadow Only
        // Apply alpha directly for debug view
        return float4(ShadowColor, shadowMask * ShadowOpacity); // Updated uniform name
    }

    // --- Compositing ---
    float4 result = originalColor;

    // 1. Apply Shadow (underneath everything else)
    if (EnableShadow && shadowMask > 0.01) {
        // Lerp original color towards shadow color based on shadow mask and alpha
        result.rgb = lerp(result.rgb, ShadowColor, saturate(shadowMask * ShadowOpacity)); // Updated uniform name
    }

    // 2. Apply Border (over shadow, under subject)
    if (borderMask > 0.01) {
        // Lerp current result towards border color based on border mask and alpha
        result.rgb = lerp(result.rgb, BorderColor, saturate(borderMask * BorderOpacity)); // Updated uniform name
    }

    // 3. Re-apply original subject color where subject mask is high
    // This ensures the subject itself isn't tinted by border/shadow
    // We lerp towards originalColor based on the subject mask.
    // Using smoothstep can help create a slightly softer edge between subject and border/shadow.
    // float subjectBlendFactor = smoothstep(0.0, 0.1, subjectMask); // Optional softening
    float subjectBlendFactor = subjectMask; // Hard edge
    result.rgb = lerp(result.rgb, originalColor.rgb, subjectBlendFactor);

    // Preserve original alpha if needed, or set to 1.0
    result.a = originalColor.a;

    return result;
}

technique AS_StencilMask < ui_label = "[AS] Cinematic: Stencil Mask"; ui_tooltip = "Creates a stencil mask effect that isolates subjects with customizable borders and projected shadows."; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_StencilMask;
    }
}