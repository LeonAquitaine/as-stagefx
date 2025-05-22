/**
 * AS_VFX_ColorBalancer.1.fx - Cinematic Color Theory Shader for ReShade
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International (CC-BY 4.0)
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Enables colorists and videographers to apply classic cinematic color harmony models 
 * (complementary, analogous, triadic, split-complementary, tetradic) to live visuals 
 * or video production. It offers flexible color manipulation across shadows, 
 * midtones, and highlights.
 *
 * FEATURES:
 * - Luminance-based tone segmentation (Shadows, Midtones, Highlights) with soft falloff.
 * - Multiple color harmony schemes: Complementary, Analogous, Triadic, Split-Complementary, Tetradic, Manual.
 * - Per-region adjustments: Hue, Saturation, Lightness, Enable/Disable.
 * - Optional skin tone protection to preserve natural skin hues.
 * - Preset system for quick cinematic looks (e.g., Amélie, Fight Club).
 * - Debug view for visualizing tonal masks.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. The input image is converted to HSL color space.
 * 2. Luminance is used to segment the image into shadows, midtones, and highlights using user-defined thresholds and softness.
 * 3. Based on the selected color scheme and base hue, target hues are determined for each tonal region.
 *    In Manual mode, user-defined hue shifts are applied directly.
 * 4. Saturation and lightness adjustments are applied per region.
 * 5. Optional skin tone protection preserves hues within a specified range.
 * 6. The modified HSL color is converted back to RGB.
 * 7. Presets can override scheme, base hue, and other parameters for specific looks.
 * 8. A debug view can show the calculated tonal masks.
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_ColorBalancer_1_fx
#define __AS_VFX_ColorBalancer_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_PI, AS_applyBlendMode, etc.

// ============================================================================
// CONSTANTS
// ============================================================================

// Base Hue
static const float BASE_HUE_MIN = 0.0;
static const float BASE_HUE_MAX = 360.0;
static const float BASE_HUE_DEFAULT = 0.0;

// Hue Shift (for Manual mode)
static const float HUE_SHIFT_MIN = -180.0;
static const float HUE_SHIFT_MAX = 180.0;
static const float HUE_SHIFT_DEFAULT = 0.0;

// Saturation
static const float SATURATION_MIN = 0.0;
static const float SATURATION_MAX = 2.0;
static const float SATURATION_DEFAULT = 1.0;

// Lightness
static const float LIGHTNESS_MIN = 0.0;
static const float LIGHTNESS_MAX = 2.0;
static const float LIGHTNESS_DEFAULT = 1.0;

// Tone Separation
static const float TONE_THRESHOLD_MIN = 0.01;
static const float TONE_THRESHOLD_MAX = 0.99;
static const float TONE_SHADOW_THRESHOLD_DEFAULT = 0.33;
static const float TONE_HIGHLIGHT_THRESHOLD_DEFAULT = 0.66;
static const float TONE_SOFT_SPLIT_MIN = 0.01;
static const float TONE_SOFT_SPLIT_MAX = 0.3;
static const float TONE_SOFT_SPLIT_DEFAULT = 0.1;

// Skin Protect Hue
static const float SKIN_PROTECT_HUE_MIN_RANGE = 0.0;
static const float SKIN_PROTECT_HUE_MAX_RANGE = 360.0;
static const float SKIN_PROTECT_HUE_DEFAULT_MIN = 20.0;
static const float SKIN_PROTECT_HUE_DEFAULT_MAX = 45.0;
static const float SKIN_PROTECT_FALLOFF_MIN = 0.0;
static const float SKIN_PROTECT_FALLOFF_MAX = 45.0;
static const float SKIN_PROTECT_FALLOFF_DEFAULT = 10.0;

// Preset IDs
static const int PRESET_CUSTOM = 0;
static const int PRESET_AMELIE = 1;
static const int PRESET_FIGHT_CLUB = 2;
static const int PRESET_MAMMA_MIA = 3;
static const int PRESET_MOONLIGHT = 4;
static const int PRESET_DRIVE = 5;

// Color Scheme IDs
static const int SCHEME_COMPLEMENTARY = 0;
static const int SCHEME_ANALOGOUS = 1;
static const int SCHEME_TRIADIC = 2;
static const int SCHEME_SPLIT_COMPLEMENTARY = 3;
static const int SCHEME_TETRADIC = 4; // Square Tetradic
static const int SCHEME_MANUAL = 5;

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Palette & Style ---
uniform int PresetSelector < ui_type = "combo"; ui_label = "Cinematic Preset";
    ui_items = "Custom\0Amélie (Comp. Red/Green)\0Fight Club (Comp. Teal/Orange)\0Mamma Mia! (Tetradic Cyan-based)\0Moonlight (Triadic Blue-based)\0Drive (Analogous Teal-based)\0";
    ui_tooltip = "Select a preconfigured cinematic color palette or choose Custom to set manually.";
    ui_category = "Palette & Style"; > = PRESET_CUSTOM;

uniform int ColorScheme < ui_type = "combo"; ui_label = "Color Harmony Scheme";
    ui_items = "Complementary\0Analogous (30° spread)\0Triadic (120° spread)\0Split-Complementary\0Tetradic (Square, 90° spread)\0* Manual Hue Shifts\0";
    ui_tooltip = "Select the color harmony model to apply. Manual mode uses direct hue shifts per region.";
    ui_category = "Palette & Style"; > = SCHEME_COMPLEMENTARY;

uniform float BaseHue < ui_type = "slider"; ui_label = "Base Hue";
    ui_min = BASE_HUE_MIN; ui_max = BASE_HUE_MAX; ui_step = 0.1;
    ui_tooltip = "Primary color anchor for the harmony scheme (in degrees).";
    ui_category = "Palette & Style"; > = BASE_HUE_DEFAULT;

// --- Tone Segmentation ---
uniform float ShadowThreshold < ui_type = "slider"; ui_label = "Shadows Upper Threshold";
    ui_min = TONE_THRESHOLD_MIN; ui_max = TONE_THRESHOLD_MAX; ui_step = 0.01;
    ui_tooltip = "Luminance value below which pixels are primarily shadows.";
    ui_category = "Tone Segmentation"; > = TONE_SHADOW_THRESHOLD_DEFAULT;

uniform float HighlightThreshold < ui_type = "slider"; ui_label = "Highlights Lower Threshold";
    ui_min = TONE_THRESHOLD_MIN; ui_max = TONE_THRESHOLD_MAX; ui_step = 0.01;
    ui_tooltip = "Luminance value above which pixels are primarily highlights.";
    ui_category = "Tone Segmentation"; > = TONE_HIGHLIGHT_THRESHOLD_DEFAULT;

uniform float LuminanceSoftSplit < ui_type = "slider"; ui_label = "Tone Separation Softness";
    ui_min = TONE_SOFT_SPLIT_MIN; ui_max = TONE_SOFT_SPLIT_MAX; ui_step = 0.01;
    ui_tooltip = "Controls the softness (transition width) between shadow, midtone, and highlight regions.";
    ui_category = "Tone Segmentation"; > = TONE_SOFT_SPLIT_DEFAULT;

// --- Shadow Adjustments ---
uniform bool EnableShadows < ui_type = "checkbox"; ui_label = "Enable";
    ui_tooltip = "Enable color adjustments for the shadow region.";
    ui_category = "Shadow Adjustments"; ui_category_closed = true; > = true;

uniform float HueShift_Shadows < ui_type = "slider"; ui_label = "* Manual Hue Shift";
    ui_min = HUE_SHIFT_MIN; ui_max = HUE_SHIFT_MAX; ui_step = 0.1;
    ui_tooltip = "Manual Hue Shift for shadows (degrees). Only active if Color Scheme is \'* Manual Hue Shifts\'.";
    ui_category = "Shadow Adjustments"; ui_category_closed = true; > = HUE_SHIFT_DEFAULT;

uniform float Saturation_Shadows < ui_type = "slider"; ui_label = "Saturation";
    ui_min = SATURATION_MIN; ui_max = SATURATION_MAX; ui_step = 0.01;
    ui_tooltip = "Saturation adjustment for shadows.";
    ui_category = "Shadow Adjustments"; ui_category_closed = true; > = SATURATION_DEFAULT;

uniform float Lightness_Shadows < ui_type = "slider"; ui_label = "Lightness";
    ui_min = LIGHTNESS_MIN; ui_max = LIGHTNESS_MAX; ui_step = 0.01;
    ui_tooltip = "Lightness adjustment for shadows.";
    ui_category = "Shadow Adjustments"; ui_category_closed = true; > = LIGHTNESS_DEFAULT;

// --- Midtone Adjustments ---
uniform bool EnableMidtones < ui_type = "checkbox"; ui_label = "Enable";
    ui_tooltip = "Enable color adjustments for the midtone region.";
    ui_category = "Midtone Adjustments"; ui_category_closed = true; > = true;

uniform float HueShift_Midtones < ui_type = "slider"; ui_label = "* Manual Hue Shift";
    ui_min = HUE_SHIFT_MIN; ui_max = HUE_SHIFT_MAX; ui_step = 0.1;
    ui_tooltip = "Manual Hue Shift for midtones (degrees). Only active if Color Scheme is \'* Manual Hue Shifts\'.";
    ui_category = "Midtone Adjustments"; ui_category_closed = true; > = HUE_SHIFT_DEFAULT;

uniform float Saturation_Midtones < ui_type = "slider"; ui_label = "Saturation";
    ui_min = SATURATION_MIN; ui_max = SATURATION_MAX; ui_step = 0.01;
    ui_tooltip = "Saturation adjustment for midtones.";
    ui_category = "Midtone Adjustments"; ui_category_closed = true; > = SATURATION_DEFAULT;

uniform float Lightness_Midtones < ui_type = "slider"; ui_label = "Lightness";
    ui_min = LIGHTNESS_MIN; ui_max = LIGHTNESS_MAX; ui_step = 0.01;
    ui_tooltip = "Lightness adjustment for midtones.";
    ui_category = "Midtone Adjustments"; ui_category_closed = true; > = LIGHTNESS_DEFAULT;

// --- Highlight Adjustments ---
uniform bool EnableHighlights < ui_type = "checkbox"; ui_label = "Enable";
    ui_tooltip = "Enable color adjustments for the highlight region.";
    ui_category = "Highlight Adjustments"; ui_category_closed = true; > = true;

uniform float HueShift_Highlights < ui_type = "slider"; ui_label = "* Manual Hue Shift";
    ui_min = HUE_SHIFT_MIN; ui_max = HUE_SHIFT_MAX; ui_step = 0.1;
    ui_tooltip = "Manual Hue Shift for highlights (degrees). Only active if Color Scheme is \'* Manual Hue Shifts\'.";
    ui_category = "Highlight Adjustments"; ui_category_closed = true; > = HUE_SHIFT_DEFAULT;

uniform float Saturation_Highlights < ui_type = "slider"; ui_label = "Saturation";
    ui_min = SATURATION_MIN; ui_max = SATURATION_MAX; ui_step = 0.01;
    ui_tooltip = "Saturation adjustment for highlights.";
    ui_category = "Highlight Adjustments"; ui_category_closed = true; > = SATURATION_DEFAULT;

uniform float Lightness_Highlights < ui_type = "slider"; ui_label = "Lightness";
    ui_min = LIGHTNESS_MIN; ui_max = LIGHTNESS_MAX; ui_step = 0.01;
    ui_tooltip = "Lightness adjustment for highlights.";
    ui_category = "Highlight Adjustments"; ui_category_closed = true; > = LIGHTNESS_DEFAULT;

// --- Skin Tone Protection ---
uniform bool EnableSkinToneProtection < ui_type = "checkbox"; ui_label = "Enable";
    ui_tooltip = "Protect skin tones from hue shifts. Assumes skin tones are in the defined range.";
    ui_category = "Skin Tone Protection"; ui_category_closed = true; > = false;

uniform float SkinProtect_HueMin < ui_type = "slider"; ui_label = "Hue Min";
    ui_min = SKIN_PROTECT_HUE_MIN_RANGE; ui_max = SKIN_PROTECT_HUE_MAX_RANGE; ui_step = 0.1;
    ui_tooltip = "Minimum hue for skin tone protection range (degrees). Ensure Min < Max for non-wrapping range.";
    ui_category = "Skin Tone Protection"; ui_category_closed = true; > = SKIN_PROTECT_HUE_DEFAULT_MIN;

uniform float SkinProtect_HueMax < ui_type = "slider"; ui_label = "Hue Max";
    ui_min = SKIN_PROTECT_HUE_MIN_RANGE; ui_max = SKIN_PROTECT_HUE_MAX_RANGE; ui_step = 0.1;
    ui_tooltip = "Maximum hue for skin tone protection range (degrees).";
    ui_category = "Skin Tone Protection"; ui_category_closed = true; > = SKIN_PROTECT_HUE_DEFAULT_MAX;

uniform float SkinProtect_Falloff < ui_type = "slider"; ui_label = "Falloff";
    ui_min = SKIN_PROTECT_FALLOFF_MIN; ui_max = SKIN_PROTECT_FALLOFF_MAX; ui_step = 0.1;
    ui_tooltip = "Softness of the transition for skin tone protection (degrees).";
    ui_category = "Skin Tone Protection"; ui_category_closed = true; > = SKIN_PROTECT_FALLOFF_DEFAULT;

// --- Final Mix ---
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug Controls ---
uniform bool DebugShowToneMasks < ui_type = "checkbox"; ui_label = "Show Tone Masks";
    ui_tooltip = "Visualize the shadow (Red), midtone (Green), and highlight (Blue) regions.";
    ui_category = "Debug"; ui_category_closed = true; > = false;

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Normalize hue to 0-360 range
float norm_hue(float h) {
    return fmod(fmod(h, 360.0) + 360.0, 360.0);
}

// RGB to HSL conversion
float3 rgb_to_hsl(float3 c) {
    float max_c = max(c.r, max(c.g, c.b));
    float min_c = min(c.r, min(c.g, c.b));
    float h = 0.0, s = 0.0, l = (max_c + min_c) / 2.0;

    if (max_c == min_c) {
        h = s = 0.0; // achromatic
    } else {
        float d = max_c - min_c;
        s = l > 0.5 ? d / (2.0 - max_c - min_c) : d / (max_c + min_c);
        if (max_c == c.r) h = (c.g - c.b) / d + (c.g < c.b ? 6.0 : 0.0);
        else if (max_c == c.g) h = (c.b - c.r) / d + 2.0;
        else if (max_c == c.b) h = (c.r - c.g) / d + 4.0;
        h /= 6.0; // h is now 0-1
        h *= 360.0; // h is now 0-360
    }
    return float3(h, s, l);
}

// HSL to RGB conversion helper
float hue_to_rgb_component(float p, float q, float t) {
    if (t < 0.0) t += 1.0;
    if (t > 1.0) t -= 1.0;
    if (t < 1.0/6.0) return p + (q - p) * 6.0 * t;
    if (t < 1.0/2.0) return q;
    if (t < 2.0/3.0) return p + (q - p) * (2.0/3.0 - t) * 6.0;
    return p;
}

// HSL to RGB conversion
float3 hsl_to_rgb(float3 hsl) {
    float h = hsl.x / 360.0; // h from 0-360 to 0-1
    float s = hsl.y;
    float l = hsl.z;
    float r, g, b;

    if (s == 0.0) {
        r = g = b = l; // achromatic
    } else {
        float q = l < 0.5 ? l * (1.0 + s) : l + s - l * s;
        float p = 2.0 * l - q;
        r = hue_to_rgb_component(p, q, h + 1.0/3.0);
        g = hue_to_rgb_component(p, q, h);
        b = hue_to_rgb_component(p, q, h - 1.0/3.0);
    }
    return float3(r, g, b);
}

// Calculate tonal masks
void get_tonal_weights(float lum, float shadow_T, float highlight_T, float softness, out float Ws, out float Wm, out float Wh)
{
    // Ensure shadow_T is less than highlight_T for correct calculations
    shadow_T = min(shadow_T, highlight_T - 0.01); // Ensure some gap

    Ws = 1.0 - smoothstep(shadow_T - softness, shadow_T + softness, lum);
    Wh = smoothstep(highlight_T - softness, highlight_T + softness, lum);
    Wm = saturate(1.0 - Ws - Wh); // What's left, ensuring it's not negative due to wide softness
    
    // Normalize weights if softness causes overlap sum > 1
    float totalWeight = Ws + Wm + Wh;
    if (totalWeight > 1.0) {
        Ws /= totalWeight;
        Wm /= totalWeight;
        Wh /= totalWeight;
    }
}


// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_ColorBalancer(float4 pos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 original_color_rgb = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float3 current_hsl = rgb_to_hsl(original_color_rgb);
    float original_hue = current_hsl.x;
    float original_sat = current_hsl.y;
    float original_lum = current_hsl.z;

    // --- Apply Presets ---
    int active_scheme = ColorScheme;
    float active_base_hue = BaseHue;
    
    float S_sat = Saturation_Shadows, S_light = Lightness_Shadows;
    float M_sat = Saturation_Midtones, M_light = Lightness_Midtones;
    float H_sat = Saturation_Highlights, H_light = Lightness_Highlights;

    if (PresetSelector != PRESET_CUSTOM) {
        if (PresetSelector == PRESET_AMELIE) { // Comp. Red/Green
            active_scheme = SCHEME_COMPLEMENTARY; active_base_hue = 0.0; // Red
            S_sat = 0.8; S_light = 0.9; M_sat = 1.1; M_light = 1.0; H_sat = 1.1; H_light = 1.05;
        } else if (PresetSelector == PRESET_FIGHT_CLUB) { // Comp. Teal/Orange
            active_scheme = SCHEME_COMPLEMENTARY; active_base_hue = 180.0; // Teal
            S_sat = 1.2; S_light = 0.85; M_sat = 0.9; M_light = 1.0; H_sat = 0.85; H_light = 1.0;
        } else if (PresetSelector == PRESET_MAMMA_MIA) { // Tetradic Cyan-based
            active_scheme = SCHEME_TETRADIC; active_base_hue = 180.0; // Cyan
            S_sat = 1.1; S_light = 0.95; M_sat = 1.2; M_light = 1.0; H_sat = 1.15; H_light = 1.05;
        } else if (PresetSelector == PRESET_MOONLIGHT) { // Triadic Blue-based
            active_scheme = SCHEME_TRIADIC; active_base_hue = 240.0; // Blue
            S_sat = 0.9; S_light = 0.8; M_sat = 1.0; M_light = 0.9; H_sat = 1.1; H_light = 1.0;
        } else if (PresetSelector == PRESET_DRIVE) { // Analogous Teal-based
            active_scheme = SCHEME_ANALOGOUS; active_base_hue = 180.0; // Teal
            S_sat = 1.0; S_light = 0.9; M_sat = 1.1; M_light = 1.0; H_sat = 0.95; H_light = 1.05;
        }
    }

    // --- Tone Segmentation ---
    // Use pixel's original luminance for segmentation, not potentially adjusted lightness
    float scene_lum = dot(original_color_rgb, float3(0.299, 0.587, 0.114)); 
    float Ws, Wm, Wh; // Shadow, Midtone, Highlight weights
    get_tonal_weights(scene_lum, ShadowThreshold, HighlightThreshold, LuminanceSoftSplit, Ws, Wm, Wh);

    if (DebugShowToneMasks) {
        return float4(Ws, Wm, Wh, 1.0); // R=Shadows, G=Midtones, B=Highlights
    }

    // --- Determine Target Hues based on Scheme ---
    float target_hue_S = original_hue, target_hue_M = original_hue, target_hue_H = original_hue;

    if (active_scheme != SCHEME_MANUAL) {
        float H1 = active_base_hue;
        float H_comp = norm_hue(H1 + 180.0);
        
        if (active_scheme == SCHEME_COMPLEMENTARY) {
            target_hue_S = H_comp; target_hue_M = H1; target_hue_H = H1;
        } else if (active_scheme == SCHEME_ANALOGOUS) {
            target_hue_S = norm_hue(H1 - 30.0); target_hue_M = H1; target_hue_H = norm_hue(H1 + 30.0);
        } else if (active_scheme == SCHEME_TRIADIC) {
            target_hue_S = norm_hue(H1 + 120.0); target_hue_M = H1; target_hue_H = norm_hue(H1 + 240.0);
        } else if (active_scheme == SCHEME_SPLIT_COMPLEMENTARY) {
            target_hue_S = norm_hue(H_comp - 30.0); target_hue_M = H1; target_hue_H = norm_hue(H_comp + 30.0);
        } else if (active_scheme == SCHEME_TETRADIC) { // Square: H, H+90, H+180, H+270
            target_hue_S = norm_hue(H1 + 90.0); target_hue_M = H1; target_hue_H = norm_hue(H1 + 270.0); 
            // Example: S=H2(Base+90), M=H1(Base), H=H4(Base+270). H3(Base+180) is unused or could be for another region.
        }
    }

    // --- Apply Adjustments Per Region ---
    float3 final_hsl = current_hsl;

    // Shadows
    if (EnableShadows && Ws > 0.001) {
        float h_s = (active_scheme == SCHEME_MANUAL) ? norm_hue(original_hue + HueShift_Shadows) : target_hue_S;
        float s_s = original_sat * S_sat;
        float l_s = original_lum * S_light;
        
        if (EnableSkinToneProtection) {
            if (SkinProtect_HueMin < SkinProtect_HueMax && original_hue >= SkinProtect_HueMin && original_hue <= SkinProtect_HueMax) {
                 float factor = 1.0 - smoothstep(0.0, SkinProtect_Falloff, min(original_hue - SkinProtect_HueMin, SkinProtect_HueMax - original_hue));
                 h_s = lerp(h_s, original_hue, factor);
            } // Basic non-wrapping skin protection for now
        }
        final_hsl = lerp(final_hsl, float3(h_s, s_s, l_s), Ws);
    }

    // Midtones
    if (EnableMidtones && Wm > 0.001) {
        float h_m = (active_scheme == SCHEME_MANUAL) ? norm_hue(original_hue + HueShift_Midtones) : target_hue_M;
        float s_m = original_sat * M_sat;
        float l_m = original_lum * M_light;

        if (EnableSkinToneProtection) {
             if (SkinProtect_HueMin < SkinProtect_HueMax && original_hue >= SkinProtect_HueMin && original_hue <= SkinProtect_HueMax) {
                 float factor = 1.0 - smoothstep(0.0, SkinProtect_Falloff, min(original_hue - SkinProtect_HueMin, SkinProtect_HueMax - original_hue));
                 h_m = lerp(h_m, original_hue, factor);
            }
        }
        // When lerping HSL, ensure it's done carefully if regions fully replace.
        // Here, we are blending the final HSL based on weights.
        // This requires careful thought: are we blending HSL values, or RGB results of HSL adjustments?
        // Blending HSL values is simpler to implement first.
        float3 mid_hsl_adjusted = float3(h_m, s_m, l_m);
        if (Ws < 0.999) { // If not fully shadow
             final_hsl = lerp(final_hsl, mid_hsl_adjusted, Wm / (Wm + Wh + 0.00001)); // Weighted average for remaining part
        } else { // If only midtones contribute after shadows (unlikely with current weight calc)
            final_hsl = mid_hsl_adjusted;
        }
    }
    
    // Highlights
    if (EnableHighlights && Wh > 0.001) {
        float h_h = (active_scheme == SCHEME_MANUAL) ? norm_hue(original_hue + HueShift_Highlights) : target_hue_H;
        float s_h = original_sat * H_sat;
        float l_h = original_lum * H_light;

        if (EnableSkinToneProtection) {
             if (SkinProtect_HueMin < SkinProtect_HueMax && original_hue >= SkinProtect_HueMin && original_hue <= SkinProtect_HueMax) {
                 float factor = 1.0 - smoothstep(0.0, SkinProtect_Falloff, min(original_hue - SkinProtect_HueMin, SkinProtect_HueMax - original_hue));
                 h_h = lerp(h_h, original_hue, factor);
            }
        }
        float3 high_hsl_adjusted = float3(h_h, s_h, l_h);
         if (Ws + Wm < 0.999) { // If not fully shadow/mid
            final_hsl = lerp(final_hsl, high_hsl_adjusted, Wh / (Wh + 0.00001)); // Only highlight contribution to remaining part
        } else {
            final_hsl = high_hsl_adjusted;
        }
    }
    
    // The HSL blending logic above is a bit naive. A better approach is to calculate the adjusted HSL for each component
    // (S, M, H) and then combine them using the weights.
    float final_h = original_hue;
    float final_s = original_sat;
    float final_l = original_lum;

    // Shadow Contribution
    float h_s_target = (active_scheme == SCHEME_MANUAL) ? norm_hue(original_hue + HueShift_Shadows) : target_hue_S;
    if (EnableSkinToneProtection && SkinProtect_HueMin < SkinProtect_HueMax && original_hue >= SkinProtect_HueMin && original_hue <= SkinProtect_HueMax) {
        float factor = 1.0 - smoothstep(0.0, SkinProtect_Falloff, min(original_hue - SkinProtect_HueMin, SkinProtect_HueMax - original_hue));
        h_s_target = lerp(h_s_target, original_hue, factor);
    }
    final_h = lerp(final_h, EnableShadows ? h_s_target : original_hue, Ws);
    final_s = lerp(final_s, EnableShadows ? original_sat * S_sat : original_sat, Ws);
    final_l = lerp(final_l, EnableShadows ? original_lum * S_light : original_lum, Ws);

    // Midtone Contribution
    float h_m_target = (active_scheme == SCHEME_MANUAL) ? norm_hue(original_hue + HueShift_Midtones) : target_hue_M;
     if (EnableSkinToneProtection && SkinProtect_HueMin < SkinProtect_HueMax && original_hue >= SkinProtect_HueMin && original_hue <= SkinProtect_HueMax) {
        float factor = 1.0 - smoothstep(0.0, SkinProtect_Falloff, min(original_hue - SkinProtect_HueMin, SkinProtect_HueMax - original_hue));
        h_m_target = lerp(h_m_target, original_hue, factor);
    }
    final_h = lerp(final_h, EnableMidtones ? h_m_target : original_hue, Wm);
    final_s = lerp(final_s, EnableMidtones ? original_sat * M_sat : original_sat, Wm);
    final_l = lerp(final_l, EnableMidtones ? original_lum * M_light : original_lum, Wm);
    
    // Highlight Contribution
    float h_h_target = (active_scheme == SCHEME_MANUAL) ? norm_hue(original_hue + HueShift_Highlights) : target_hue_H;
    if (EnableSkinToneProtection && SkinProtect_HueMin < SkinProtect_HueMax && original_hue >= SkinProtect_HueMin && original_hue <= SkinProtect_HueMax) {
        float factor = 1.0 - smoothstep(0.0, SkinProtect_Falloff, min(original_hue - SkinProtect_HueMin, SkinProtect_HueMax - original_hue));
        h_h_target = lerp(h_h_target, original_hue, factor);
    }
    final_h = lerp(final_h, EnableHighlights ? h_h_target : original_hue, Wh);
    final_s = lerp(final_s, EnableHighlights ? original_sat * H_sat : original_sat, Wh);
    final_l = lerp(final_l, EnableHighlights ? original_lum * H_light : original_lum, Wh);
    
    final_hsl = float3(norm_hue(final_h), saturate(final_s), saturate(final_l));

    // --- Convert back to RGB and apply final mix ---
    float3 final_color_rgb = hsl_to_rgb(final_hsl);
    
    // Corrected blend function call
    return AS_applyBlend(float4(final_color_rgb, 1.0), float4(original_color_rgb, 1.0), BlendMode, BlendAmount);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_VFX_ColorBalancer < ui_tooltip = "Applies cinematic color harmony models across tonal ranges."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_ColorBalancer;
    }
}

#endif // __AS_VFX_ColorBalancer_1_fx
