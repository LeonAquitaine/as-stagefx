/**
 * AS_GFX_Hologram.1.fx - Depth-Based Holographic Field
 * Author: Leon Aquitaine (Adapted from Alexander Alekseev aka TDM)
 * License: Creative Commons Attribution 4.0 International
 * Original Source: "Protection hologram" by TDM (2014)
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader transforms the entire scene's depth buffer into a holographic field.
 * Unlike a sticker, this effect uses the 3D information of the scene as the source
 * for holographic parallax, color shifts, and lighting.
 *
 * FEATURES:
 * - Uses the scene's depth buffer as the holographic data source.
 * - A wavy, procedural noise pattern is warped by the scene's geometry.
 * - Produces shifting, spectral rainbow colors based on depth and view angle.
 * - "Hue Compression" adds more color detail to foreground objects with an exponential falloff.
 * - Optional background darkening to make the hologram pop.
 * - Support for color palettes to create themed holographic effects.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. A wavy, procedural noise pattern is generated to serve as the base texture.
 * 2. The gradient of this noise is calculated to create a base set of normals.
 * 3. The depth gradient (slope) of the scene geometry is also calculated.
 * 4. The noise normals are warped by the depth gradient, making the geometry
 * appear to distort the holographic field.
 * 5. Lighting and color are calculated based on this final warped normal.
 * 6. Color palettes can be applied to create themed holographic effects.
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD
// ============================================================================
#ifndef __AS_GFX_Hologram_1_fx
#define __AS_GFX_Hologram_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Noise.1.fxh"
#include "AS_Palette.1.fxh"

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Palette ---
AS_PALETTE_SELECTION_UI(HologramPalette, "Hologram Palette", AS_PALETTE_RAINBOW, "Palette & Style")

// --- View Angle ---
AS_POSITION_SCALE_UI(ViewAngle, ViewAngle_Scale)

// --- Hologram Appearance ---
static const float HOLO_EDGE_SENSITIVITY_MIN = 0.0;
static const float HOLO_EDGE_SENSITIVITY_MAX = 20.0;
static const float HOLO_EDGE_SENSITIVITY_DEFAULT = 5.0;
uniform float EdgeDistortion < ui_type = "slider"; ui_label = "Edge Distortion"; ui_tooltip = "Controls how strongly scene edges warp the holographic pattern."; ui_min = HOLO_EDGE_SENSITIVITY_MIN; ui_max = HOLO_EDGE_SENSITIVITY_MAX; ui_category = "Hologram Appearance"; > = HOLO_EDGE_SENSITIVITY_DEFAULT;

static const float HOLO_NOISE_STRENGTH_MIN = 0.0;
static const float HOLO_NOISE_STRENGTH_MAX = 5.0;
static const float HOLO_NOISE_STRENGTH_DEFAULT = 1.0;
uniform float PatternStrength < ui_type = "slider"; ui_label = "Pattern Strength"; ui_tooltip = "Controls the intensity of the holographic wave pattern."; ui_min = HOLO_NOISE_STRENGTH_MIN; ui_max = HOLO_NOISE_STRENGTH_MAX; ui_category = "Hologram Appearance"; > = HOLO_NOISE_STRENGTH_DEFAULT;

static const float HOLO_NOISE_SCALE_MIN = 1.0;
static const float HOLO_NOISE_SCALE_MAX = 100.0;
static const float HOLO_NOISE_SCALE_DEFAULT = 10.0;
uniform float PatternScale < ui_type = "slider"; ui_label = "Pattern Scale"; ui_tooltip = "Controls the size of the holographic wave pattern."; ui_min = HOLO_NOISE_SCALE_MIN; ui_max = HOLO_NOISE_SCALE_MAX; ui_category = "Hologram Appearance"; > = HOLO_NOISE_SCALE_DEFAULT;

uniform int NoiseOctaves < ui_type = "slider"; ui_label = "Pattern Octaves"; ui_tooltip = "Controls the level of detail in the wave pattern."; ui_min = 1; ui_max = 8; ui_category = "Hologram Appearance"; > = 4;

static const float HOLO_NOISE_LACUNARITY_MIN = 1.0;
static const float HOLO_NOISE_LACUNARITY_MAX = 4.0;
static const float HOLO_NOISE_LACUNARITY_DEFAULT = 2.0;
uniform float NoiseLacunarity < ui_type = "slider"; ui_label = "Pattern Lacunarity"; ui_tooltip = "Controls the frequency multiplier for pattern octaves."; ui_min = HOLO_NOISE_LACUNARITY_MIN; ui_max = HOLO_NOISE_LACUNARITY_MAX; ui_category = "Hologram Appearance"; > = HOLO_NOISE_LACUNARITY_DEFAULT;

static const float HOLO_NOISE_GAIN_MIN = 0.0;
static const float HOLO_NOISE_GAIN_MAX = 1.0;
static const float HOLO_NOISE_GAIN_DEFAULT = 0.5;
uniform float NoiseGain < ui_type = "slider"; ui_label = "Pattern Gain"; ui_tooltip = "Controls the amplitude multiplier for pattern octaves."; ui_min = HOLO_NOISE_GAIN_MIN; ui_max = HOLO_NOISE_GAIN_MAX; ui_category = "Hologram Appearance"; > = HOLO_NOISE_GAIN_DEFAULT;

// --- Depth Range ---
static const float HOLO_DEPTH_START_MIN = 0.0;
static const float HOLO_DEPTH_START_MAX = 1.0;
static const float HOLO_DEPTH_START_DEFAULT = 0.0;
uniform float DepthStart < ui_type = "slider"; ui_label = "Hologram Depth Start"; ui_tooltip = "The depth where the effect begins. Normalized (0.0=near, 1.0=far)."; ui_min = HOLO_DEPTH_START_MIN; ui_max = HOLO_DEPTH_START_MAX; ui_category = "Depth Range"; > = HOLO_DEPTH_START_DEFAULT;

static const float HOLO_DEPTH_END_MIN = 0.0;
static const float HOLO_DEPTH_END_MAX = 1.0;
static const float HOLO_DEPTH_END_DEFAULT = 1.0;
uniform float DepthEnd < ui_type = "slider"; ui_label = "Hologram Depth End"; ui_tooltip = "The depth where the effect ends. Normalized (0.0=near, 1.0=far)."; ui_min = HOLO_DEPTH_END_MIN; ui_max = HOLO_DEPTH_END_MAX; ui_category = "Depth Range"; > = HOLO_DEPTH_END_DEFAULT;

static const float HOLO_DEPTH_CONTRAST_MIN = 0.1;
static const float HOLO_DEPTH_CONTRAST_MAX = 5.0;
static const float HOLO_DEPTH_CONTRAST_DEFAULT = 1.0;
uniform float DepthContrast < ui_type = "slider"; ui_label = "Depth Contrast"; ui_tooltip = "Increases the visual impact of depth variations."; ui_min = HOLO_DEPTH_CONTRAST_MIN; ui_max = HOLO_DEPTH_CONTRAST_MAX; ui_category = "Depth Range"; > = HOLO_DEPTH_CONTRAST_DEFAULT;

static const float HOLO_BG_DARKEN_MIN = 0.0;
static const float HOLO_BG_DARKEN_MAX = 1.0;
static const float HOLO_BG_DARKEN_DEFAULT = 0.0;
uniform float BackgroundDarkening < ui_type = "slider"; ui_label = "Background Darkening"; ui_tooltip = "Darkens parts of the original scene that are far away."; ui_min = HOLO_BG_DARKEN_MIN; ui_max = HOLO_BG_DARKEN_MAX; ui_category = "Depth Range"; > = HOLO_BG_DARKEN_DEFAULT;

static const float HOLO_FALLOFF_MIN = 0.0;
static const float HOLO_FALLOFF_MAX = 1.0;
static const float HOLO_FALLOFF_DEFAULT = 0.8;
uniform float DarkeningFalloff < ui_type = "slider"; ui_label = "Darkening Falloff Start"; ui_tooltip = "The point within the depth range where background darkening begins (0.0=starts immediately, 1.0=never starts)."; ui_min = HOLO_FALLOFF_MIN; ui_max = HOLO_FALLOFF_MAX; ui_category = "Depth Range"; > = HOLO_FALLOFF_DEFAULT;

// --- Lighting & Color ---
static const float HOLO_HUE_STRETCH_MIN = 0.0;
static const float HOLO_HUE_STRENGTH_MAX = 50.0;
static const float HOLO_HUE_STRENGTH_DEFAULT = 10.0;
uniform float HueStretch < ui_type = "slider"; ui_label = "Hue Stretch"; ui_tooltip = "Controls the tiling/frequency of the rainbow colors."; ui_min = HOLO_HUE_STRETCH_MIN; ui_max = HOLO_HUE_STRENGTH_MAX; ui_category = "Lighting & Color"; > = HOLO_HUE_STRENGTH_DEFAULT;

static const float HOLO_HUE_COMPRESSION_MIN = 0.0;
static const float HOLO_HUE_COMPRESSION_MAX = 10.0;
static const float HOLO_HUE_COMPRESSION_DEFAULT = 1.0;
uniform float HueCompression < ui_type = "slider"; ui_label = "Hue Compression"; ui_tooltip = "Increases hue frequency on objects closer to the camera."; ui_min = HOLO_HUE_COMPRESSION_MIN; ui_max = HOLO_HUE_COMPRESSION_MAX; ui_category = "Lighting & Color"; > = HOLO_HUE_COMPRESSION_DEFAULT;

static const float HOLO_COLOR_SATURATION_MIN = 0.0;
static const float HOLO_COLOR_SATURATION_MAX = 2.0;
static const float HOLO_COLOR_SATURATION_DEFAULT = 0.5;
uniform float ColorSaturation < ui_type = "slider"; ui_label = "Color Saturation"; ui_min = HOLO_COLOR_SATURATION_MIN; ui_max = HOLO_COLOR_SATURATION_MAX; ui_category = "Lighting & Color"; > = HOLO_COLOR_SATURATION_DEFAULT;

static const float HOLO_AMBIENT_MIN = 0.0;
static const float HOLO_AMBIENT_MAX = 1.0;
static const float HOLO_AMBIENT_DEFAULT = 0.4;
uniform float AmbientLight < ui_type = "slider"; ui_label = "Ambient Light"; ui_tooltip = "The base brightness of the hologram in shadow."; ui_min = HOLO_AMBIENT_MIN; ui_max = HOLO_AMBIENT_MAX; ui_category = "Lighting & Color"; > = HOLO_AMBIENT_DEFAULT;

static const float HOLO_DIFFUSE_MIN = 0.0;
static const float HOLO_DIFFUSE_MAX = 2.0;
static const float HOLO_DIFFUSE_DEFAULT = 0.8;
uniform float DiffuseLight < ui_type = "slider"; ui_label = "Diffuse Light"; ui_tooltip = "The brightness of the hologram when facing the light."; ui_min = HOLO_DIFFUSE_MIN; ui_max = HOLO_DIFFUSE_MAX; ui_category = "Lighting & Color"; > = HOLO_DIFFUSE_DEFAULT;

static const float HOLO_HIGHLIGHT_POW_MIN = 1.0;
static const float HOLO_HIGHLIGHT_POW_MAX = 256.0;
static const float HOLO_HIGHLIGHT_POW_DEFAULT = 128.0;
uniform float HighlightPower < ui_type = "slider"; ui_label = "Highlight Sharpness"; ui_tooltip = "Controls the sharpness of the light highlights on edges."; ui_min = HOLO_HIGHLIGHT_POW_MIN; ui_max = HOLO_HIGHLIGHT_POW_MAX; ui_category = "Lighting & Color"; > = HOLO_HIGHLIGHT_POW_DEFAULT;

static const float HOLO_HIGHLIGHT_BRIGHTNESS_MIN = 0.0;
static const float HOLO_HIGHLIGHT_BRIGHTNESS_MAX = 5.0;
static const float HOLO_HIGHLIGHT_BRIGHTNESS_DEFAULT = 1.5;
uniform float HighlightBrightness < ui_type = "slider"; ui_label = "Highlight Brightness"; ui_min = HOLO_HIGHLIGHT_BRIGHTNESS_MIN; ui_max = HOLO_HIGHLIGHT_BRIGHTNESS_MAX; ui_category = "Lighting & Color"; > = HOLO_HIGHLIGHT_BRIGHTNESS_DEFAULT;

// --- Animation ---
AS_ANIMATION_UI(MasterTimeSpeed, MasterTimeKeyframe, "Global Animation")

// --- Stage/Position ---
AS_STAGEDEPTH_UI(EffectDepth)

// --- Final Mix ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_LIGHTEN)
AS_BLENDAMOUNT_UI(BlendAmount)

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_GFX_Hologram(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float rawDepth = ReShade::GetLinearizedDepth(texcoord);

    // Stage depth check - only apply effect to pixels at or behind EffectDepth
    if (rawDepth < EffectDepth) {
        return originalColor;
    }    // 1. Process Depth 
    float depthRange = max(AS_EPSILON, DepthEnd - DepthStart);
    float remappedDepth = saturate((rawDepth - DepthStart) / depthRange);

    // 2. Continue with Hologram effect logic
    remappedDepth = pow(remappedDepth, DepthContrast);

    float effectMask = smoothstep(0.0, 0.05, remappedDepth) * (1.0 - smoothstep(0.95, 1.0, remappedDepth));
    if (effectMask < AS_EPSILON) {
        return originalColor;
    }    // 3. Create base normal from procedural noise
    float2 noise_uv = texcoord * PatternScale;
    float n_c = AS_Fbm2D(noise_uv, NoiseOctaves, NoiseLacunarity, NoiseGain);
    float n_l = AS_Fbm2D(noise_uv - float2(ReShade::PixelSize.x, 0), NoiseOctaves, NoiseLacunarity, NoiseGain);
    float n_r = AS_Fbm2D(noise_uv + float2(ReShade::PixelSize.x, 0), NoiseOctaves, NoiseLacunarity, NoiseGain);
    float n_t = AS_Fbm2D(noise_uv - float2(0, ReShade::PixelSize.y), NoiseOctaves, NoiseLacunarity, NoiseGain);
    float n_b = AS_Fbm2D(noise_uv + float2(0, ReShade::PixelSize.y), NoiseOctaves, NoiseLacunarity, NoiseGain);
    float3 noise_normal;
    noise_normal.x = (n_r - n_l) * PatternStrength;
    noise_normal.y = (n_b - n_t) * PatternStrength;
    
    // 4. Get normal from depth gradient
    float depth_l = ReShade::GetLinearizedDepth(texcoord - float2(ReShade::PixelSize.x, 0));
    float depth_r = ReShade::GetLinearizedDepth(texcoord + float2(ReShade::PixelSize.x, 0));
    float depth_t = ReShade::GetLinearizedDepth(texcoord - float2(0, ReShade::PixelSize.y));
    float depth_b = ReShade::GetLinearizedDepth(texcoord + float2(0, ReShade::PixelSize.y));
    float3 depth_normal_component;
    depth_normal_component.x = (depth_r - depth_l) * (500.0 * EdgeDistortion);
    depth_normal_component.y = (depth_b - depth_t) * (500.0 * EdgeDistortion);    // 5. Combine noise and depth normals
    float3 final_normal = normalize(float3(noise_normal.xy + depth_normal_component.xy, 1.0));

    // 6. Define View Vector from UI controls
    float3 viewVector = normalize(float3(ViewAngle.x, -ViewAngle.y, -1.0));

    // 7. Calculate Final Color
    float3 reflection_vec = reflect(viewVector, final_normal);    // --- CORRECTED Hue Compression Logic with Exponential Falloff ---
    float depth_factor = 1.0 - remappedDepth;
    float compression_curve = pow(depth_factor, 2.0); // Using a fixed quadratic curve for a sharp falloff
    float compression_factor = 1.0 + (compression_curve * HueCompression);
    float effective_hue_stretch = HueStretch * compression_factor;
    
    // Add animation to color cycling
    float animTime = AS_getAnimationTime(MasterTimeSpeed, MasterTimeKeyframe);
    float hue_input = (reflection_vec.x + reflection_vec.y) * effective_hue_stretch + animTime;// Apply palette or generate rainbow colors
    float3 baseColor;
    if (HologramPalette == AS_PALETTE_RAINBOW) {
        // Rainbow mode - original logic
        float r = fmod(hue_input * 6.0 + 0.0, 6.0);
        float g = fmod(hue_input * 6.0 + 2.0, 6.0);
        float b = fmod(hue_input * 6.0 + 4.0, 6.0);
        float3 hue = clamp(abs(float3(r, g, b) - 3.0) - 1.0, 0.0, 1.0);
        
        float3 gray = 0.7;
        float sat = ColorSaturation * (0.5 + remappedDepth * 0.5);
        baseColor = lerp(gray, hue, sat);
    } else {
        // Palette mode
        float palettePosition = frac(hue_input);
        float3 paletteColor = AS_getInterpolatedColor(HologramPalette, palettePosition);
        
        float3 gray = 0.7;
        float sat = ColorSaturation * (0.5 + remappedDepth * 0.5);
        baseColor = lerp(gray, paletteColor, sat);
    }
      // New Lighting Model
    float lambert = saturate(dot(viewVector, -final_normal));
    float lighting = lerp(AmbientLight, DiffuseLight, lambert);
    float highlight = pow(lambert, HighlightPower) * HighlightBrightness;
    
    float3 holoColor = baseColor * lighting + highlight;    // 8. Apply background darkening and create final effect
    float darken_falloff = smoothstep(DarkeningFalloff, 1.0, remappedDepth);
    float darken_multiplier = 1.0 - (darken_falloff * BackgroundDarkening);
    float3 darkenedBackground = originalColor.rgb * darken_multiplier;
    float3 effectResult = lerp(darkenedBackground, darkenedBackground + holoColor, effectMask);
    
    float4 finalColor = float4(effectResult, 1.0);

    return AS_applyBlend(finalColor, originalColor, BlendMode, BlendAmount);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_GFX_Hologram <
    ui_label = "[AS] GFX: Hologram";
    ui_tooltip = "Transforms the scene's depth buffer into a holographic field.\n"
                 "Colors and parallax effects are generated from the 3D information of the scene.\n"
                 "Supports color palettes for themed holographic effects.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_GFX_Hologram;
    }
}

#endif // __AS_GFX_Hologram_1_fx