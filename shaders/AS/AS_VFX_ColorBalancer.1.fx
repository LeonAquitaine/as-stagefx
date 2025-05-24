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
#include "AS_Utils.1.fxh" // For AS_PI, AS_applyBlend, etc.

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

// Harmony Role Assignment IDs
static const int ROLE_ORIGINAL_HUE = 0;
static const int ROLE_HARMONY_1 = 1; // Typically Base Hue
static const int ROLE_HARMONY_2 = 2; // Typically second harmony color
static const int ROLE_HARMONY_3 = 3; // Typically third harmony color
static const int ROLE_HARMONY_4 = 4; // Typically fourth harmony color (for Tetradic)

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
    ui_tooltip = "Select the color harmony model. Manual mode uses direct hue shifts. For schemes, 'Harmony Color X' assignments map as follows:\n"
                 "Complementary: C1=Base, C2=Complement (Base+180°)\n"
                 "Analogous: C1=Base, C2=Base-30°, C3=Base+30°\n"
                 "Triadic: C1=Base, C2=Base+120°, C3=Base+240°\n"
                 "Split-Complementary: C1=Base, C2=Complement-30°, C3=Complement+30°\n"
                 "Tetradic (Square): C1=Base, C2=Base+90°, C3=Base+180°, C4=Base+270°";
    ui_text = "Defines the color relationship rule. See tooltip for 'Harmony Color X' details per scheme.";
    ui_category = "Palette & Style"; > = SCHEME_COMPLEMENTARY;

uniform float BaseHue < ui_type = "slider"; ui_label = "Base Hue";
    ui_min = BASE_HUE_MIN; ui_max = BASE_HUE_MAX; ui_step = 0.1;
    ui_tooltip = "Primary color anchor for the harmony scheme (in degrees).";
    ui_text = "The main hue (0-360°) that anchors the selected color scheme calculations.";
    ui_category = "Palette & Style"; > = BASE_HUE_DEFAULT;

uniform bool UseCustomHarmonyAssignment < ui_type = "checkbox"; ui_label = "Use Custom Harmony Color Assignment";
    ui_tooltip = "OFF: All tonal regions primarily target the Base Hue (Harmony Color 1 from the selected scheme), with individual Hue Shifts applied as offsets. ON: Enables detailed assignment of any calculated harmony color (or original hue) to each tonal region using the 'Harmony Color Assignment' dropdowns below.";
    ui_text = "Toggle between simple (Base Hue for all regions + offsets) and advanced (per-region selection of scheme colors) modes.";
    ui_category = "Palette & Style"; > = false;

// --- Harmony Color Assignment ---
uniform int ShadowsHarmonyRoleAssignment < ui_type = "combo"; ui_label = "Shadows Use";
    ui_items = "Original Pixel Hue\0Harmony Color 1\0Harmony Color 2\0Harmony Color 3\0Harmony Color 4\0";
    ui_tooltip = "Assigns a calculated harmony color (or original pixel hue) to the Shadows region. The meaning of 'Harmony Color X' depends on the selected Color Harmony Scheme.";
    ui_text = "Maps a harmony color (from selected scheme) or original hue to shadows.";
    ui_category = "Harmony Color Assignment"; ui_category_closed = true; > = ROLE_HARMONY_2; // Default for Complementary: Shadows = Complement

uniform int MidtonesHarmonyRoleAssignment < ui_type = "combo"; ui_label = "Midtones Use";
    ui_items = "Original Pixel Hue\0Harmony Color 1\0Harmony Color 2\0Harmony Color 3\0Harmony Color 4\0";
    ui_tooltip = "Assigns a calculated harmony color (or original pixel hue) to the Midtones region. The meaning of 'Harmony Color X' depends on the selected Color Harmony Scheme.";
    ui_text = "Maps a harmony color (from selected scheme) or original hue to midtones.";
    ui_category = "Harmony Color Assignment"; ui_category_closed = true; > = ROLE_HARMONY_1; // Default for Complementary: Midtones = Base

uniform int HighlightsHarmonyRoleAssignment < ui_type = "combo"; ui_label = "Highlights Use";
    ui_items = "Original Pixel Hue\0Harmony Color 1\0Harmony Color 2\0Harmony Color 3\0Harmony Color 4\0";
    ui_tooltip = "Assigns a calculated harmony color (or original pixel hue) to the Highlights region. The meaning of 'Harmony Color X' depends on the selected Color Harmony Scheme.";
    ui_text = "Maps a harmony color (from selected scheme) or original hue to highlights.";
    ui_category = "Harmony Color Assignment"; ui_category_closed = true; > = ROLE_HARMONY_1; // Default for Complementary: Highlights = Base

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
    ui_text = "Adjusts the smoothness of transitions between tonal regions. Higher values = softer blends.";
    ui_category = "Tone Segmentation"; > = TONE_SOFT_SPLIT_DEFAULT;

// --- Shadow Adjustments ---
uniform bool EnableShadows < ui_type = "checkbox"; ui_label = "Enable Shadow Adjustments";
    ui_tooltip = "Enable color adjustments for the shadow region.";
    ui_category = "Shadow Adjustments"; ui_category_closed = true; > = true;

uniform float HueShift_Shadows < ui_type = "slider"; ui_label = "* Manual Hue Shift";
    ui_min = HUE_SHIFT_MIN; ui_max = HUE_SHIFT_MAX; ui_step = 0.1;
    ui_tooltip = "Hue Shift for shadows. If Scheme is Manual, this is a direct shift from original. Otherwise, it's an additional offset to the harmony target hue.";
    ui_text = "Shift hue for shadows. Behavior depends on Color Scheme (direct if Manual, offset if scheme-based).";
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
uniform bool EnableMidtones < ui_type = "checkbox"; ui_label = "Enable Midtone Adjustments";
    ui_tooltip = "Enable color adjustments for the midtone region.";
    ui_category = "Midtone Adjustments"; ui_category_closed = true; > = true;

uniform float HueShift_Midtones < ui_type = "slider"; ui_label = "* Manual Hue Shift";
    ui_min = HUE_SHIFT_MIN; ui_max = HUE_SHIFT_MAX; ui_step = 0.1;
    ui_tooltip = "Hue Shift for midtones. If Scheme is Manual, this is a direct shift from original. Otherwise, it's an additional offset to the harmony target hue.";
    ui_text = "Shift hue for midtones. Behavior depends on Color Scheme (direct if Manual, offset if scheme-based).";
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
uniform bool EnableHighlights < ui_type = "checkbox"; ui_label = "Enable Highlight Adjustments";
    ui_tooltip = "Enable color adjustments for the highlight region.";
    ui_category = "Highlight Adjustments"; ui_category_closed = true; > = true;

uniform float HueShift_Highlights < ui_type = "slider"; ui_label = "* Manual Hue Shift";
    ui_min = HUE_SHIFT_MIN; ui_max = HUE_SHIFT_MAX; ui_step = 0.1;
    ui_tooltip = "Hue Shift for highlights. If Scheme is Manual, this is a direct shift from original. Otherwise, it's an additional offset to the harmony target hue.";
    ui_text = "Shift hue for highlights. Behavior depends on Color Scheme (direct if Manual, offset if scheme-based).";
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
uniform bool EnableSkinToneProtection < ui_type = "checkbox"; ui_label = "Enable Skin Tone Protection";
    ui_tooltip = "Protect skin tones from hue shifts. Assumes skin tones are in the defined range.";
    ui_category = "Skin Tone Protection"; ui_category_closed = true; > = false;

uniform float SkinProtect_HueMin < ui_type = "slider"; ui_label = "Hue Min";
    ui_min = SKIN_PROTECT_HUE_MIN_RANGE; ui_max = SKIN_PROTECT_HUE_MAX_RANGE; ui_step = 0.1;
    ui_tooltip = "Minimum hue for skin tone protection range (degrees). If Min > Max, the range wraps around 360/0.";
    ui_text = "Start of protected hue range. If Min > Max, range wraps around 0/360 (e.g., 350 to 20).";
    ui_category = "Skin Tone Protection"; ui_category_closed = true; > = SKIN_PROTECT_HUE_DEFAULT_MIN;

uniform float SkinProtect_HueMax < ui_type = "slider"; ui_label = "Hue Max";
    ui_min = SKIN_PROTECT_HUE_MIN_RANGE; ui_max = SKIN_PROTECT_HUE_MAX_RANGE; ui_step = 0.1;
    ui_tooltip = "Maximum hue for skin tone protection range (degrees).";
    ui_text = "End of protected hue range. See 'Hue Min' for wrap-around behavior.";
    ui_category = "Skin Tone Protection"; ui_category_closed = true; > = SKIN_PROTECT_HUE_DEFAULT_MAX;

uniform float SkinProtect_Falloff < ui_type = "slider"; ui_label = "Falloff";
    ui_min = SKIN_PROTECT_FALLOFF_MIN; ui_max = SKIN_PROTECT_FALLOFF_MAX; ui_step = 0.1;
    ui_tooltip = "Distance (in degrees) from the Hue Min/Max boundaries inwards, over which skin protection transitions from full strength (at the boundary) to no strength (further inside).";
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

// Helper function to convert sRGB to linear RGB (approximate)
// Could be part of AS_Utils.fxh
float3 AS_srgb_to_linear(float3 c_srgb) {
    return pow(abs(c_srgb), 2.2); // abs to handle potential negative inputs, though color usually isn't
}

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

// Helper function for robust weighted averaging of HSL values, especially hue.
// Could be part of AS_Utils.fxh
float3 blend_hsl_weighted(float3 hsl1, float w1, float3 hsl2, float w2, float3 hsl3, float w3) {
    // Convert hues to vectors for robust averaging
    float h1_rad = radians(hsl1.x);
    float h2_rad = radians(hsl2.x);
    float h3_rad = radians(hsl3.x);

    // Weighted sum of vectors
    float avg_cos = w1 * cos(h1_rad) + w2 * cos(h2_rad) + w3 * cos(h3_rad);
    float avg_sin = w1 * sin(h1_rad) + w2 * sin(h2_rad) + w3 * sin(h3_rad);

    // Convert average vector back to hue angle
    float final_h = degrees(atan2(avg_sin, avg_cos));
    final_h = norm_hue(final_h); // Ensure 0-360

    // Average saturation and lightness directly using weights
    float final_s = w1 * hsl1.y + w2 * hsl2.y + w3 * hsl3.y;
    float final_l = w1 * hsl1.z + w2 * hsl2.z + w3 * hsl3.z;
    
    return float3(final_h, final_s, final_l);
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

// Helper function for skin tone protection
float apply_skin_tone_protection(float original_pixel_hue, float current_effective_hue, 
                                 bool protection_enabled, float protect_min_hue, float protect_max_hue, float protect_falloff)
{
    if (!protection_enabled) {
        return current_effective_hue;
    }

    bool is_hue_in_protected_range = (protect_min_hue <= protect_max_hue) ?
                                     (original_pixel_hue >= protect_min_hue && original_pixel_hue <= protect_max_hue) :
                                     (original_pixel_hue >= protect_min_hue || original_pixel_hue <= protect_max_hue);

    if (is_hue_in_protected_range) {
        float dist_val;
        if (protect_min_hue <= protect_max_hue) { // Non-wrapped range
            dist_val = min(original_pixel_hue - protect_min_hue, protect_max_hue - original_pixel_hue);
        } else { // Wrapped range
            if (original_pixel_hue >= protect_min_hue) { // e.g., hue is 355, range 350-10. dist to 350.
                dist_val = original_pixel_hue - protect_min_hue;
            } else { // e.g., hue is 5, range 350-10. dist to 10.
                dist_val = protect_max_hue - original_pixel_hue;
            }
        }
        float protection_blend_factor = 1.0 - smoothstep(0.0, protect_falloff, dist_val);
        return lerp(current_effective_hue, original_pixel_hue, protection_blend_factor);
    }
    return current_effective_hue;
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
    float original_lum = current_hsl.z; // This is L from sRGB HSL, used for direct L adjustments

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
    // Convert sRGB to Linear for perceptually accurate luminance calculation
    float3 linear_color_rgb = AS_srgb_to_linear(original_color_rgb);
    float scene_lum = dot(linear_color_rgb, float3(0.2126, 0.7152, 0.0722)); // Luminance from linear RGB for segmentation
    
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
        float H_analog_minus = norm_hue(H1 - 30.0);
        float H_analog_plus = norm_hue(H1 + 30.0);
        float H_triad_1 = norm_hue(H1 + 120.0);
        float H_triad_2 = norm_hue(H1 + 240.0);
        float H_split_comp_minus = norm_hue(H_comp - 30.0);
        float H_split_comp_plus = norm_hue(H_comp + 30.0);
        float H_tetra_1 = norm_hue(H1 + 90.0);
        float H_tetra_2 = H_comp; // same as norm_hue(H1 + 180.0)
        float H_tetra_3 = norm_hue(H1 + 270.0);

        float harmony_colors[4]; // Max 4 harmony colors needed for Tetradic
        harmony_colors[0] = H1; // Harmony Color 1 is always BaseHue

        if (active_scheme == SCHEME_COMPLEMENTARY) {
            harmony_colors[1] = H_comp; // Harmony Color 2
        } else if (active_scheme == SCHEME_ANALOGOUS) {
            harmony_colors[1] = H_analog_minus; // Harmony Color 2
            harmony_colors[2] = H_analog_plus;  // Harmony Color 3
        } else if (active_scheme == SCHEME_TRIADIC) {
            harmony_colors[1] = H_triad_1;      // Harmony Color 2
            harmony_colors[2] = H_triad_2;      // Harmony Color 3
        } else if (active_scheme == SCHEME_SPLIT_COMPLEMENTARY) {
            harmony_colors[1] = H_split_comp_minus; // Harmony Color 2
            harmony_colors[2] = H_split_comp_plus;  // Harmony Color 3
        } else if (active_scheme == SCHEME_TETRADIC) { // Square: H, H+90, H+180, H+270
            harmony_colors[1] = H_tetra_1;      // Harmony Color 2
            harmony_colors[2] = H_tetra_2;      // Harmony Color 3
            harmony_colors[3] = H_tetra_3;      // Harmony Color 4
        }

        if (UseCustomHarmonyAssignment) { // If ON, use the detailed dropdowns
            // Assign to Shadows
            if (ShadowsHarmonyRoleAssignment == ROLE_ORIGINAL_HUE) target_hue_S = original_hue;
            else if (ShadowsHarmonyRoleAssignment == ROLE_HARMONY_1) target_hue_S = harmony_colors[0];
            else if (ShadowsHarmonyRoleAssignment == ROLE_HARMONY_2) target_hue_S = harmony_colors[1];
            else if (ShadowsHarmonyRoleAssignment == ROLE_HARMONY_3) target_hue_S = harmony_colors[2];
            else if (ShadowsHarmonyRoleAssignment == ROLE_HARMONY_4) target_hue_S = harmony_colors[3];

            // Assign to Midtones
            if (MidtonesHarmonyRoleAssignment == ROLE_ORIGINAL_HUE) target_hue_M = original_hue;
            else if (MidtonesHarmonyRoleAssignment == ROLE_HARMONY_1) target_hue_M = harmony_colors[0];
            else if (MidtonesHarmonyRoleAssignment == ROLE_HARMONY_2) target_hue_M = harmony_colors[1];
            else if (MidtonesHarmonyRoleAssignment == ROLE_HARMONY_3) target_hue_M = harmony_colors[2];
            else if (MidtonesHarmonyRoleAssignment == ROLE_HARMONY_4) target_hue_M = harmony_colors[3];

            // Assign to Highlights
            if (HighlightsHarmonyRoleAssignment == ROLE_ORIGINAL_HUE) target_hue_H = original_hue;
            else if (HighlightsHarmonyRoleAssignment == ROLE_HARMONY_1) target_hue_H = harmony_colors[0];
            else if (HighlightsHarmonyRoleAssignment == ROLE_HARMONY_2) target_hue_H = harmony_colors[1];
            else if (HighlightsHarmonyRoleAssignment == ROLE_HARMONY_3) target_hue_H = harmony_colors[2]; 
            else if (HighlightsHarmonyRoleAssignment == ROLE_HARMONY_4) target_hue_H = harmony_colors[3];
        } else { // UseCustomHarmonyAssignment is OFF: All regions target Harmony Color 1 (BaseHue)
            target_hue_S = harmony_colors[0];
            target_hue_M = harmony_colors[0];
            target_hue_H = harmony_colors[0];
        }
    }

    // --- Apply Adjustments Per Region (Weighted Sum Method) ---
    float eff_h_S, eff_s_S, eff_l_S; // Effective HSL for Shadows
    float eff_h_M, eff_s_M, eff_l_M; // Effective HSL for Midtones
    float eff_h_H, eff_s_H, eff_l_H; // Effective HSL for Highlights

    // Shadow region
    eff_h_S = (active_scheme == SCHEME_MANUAL) ? norm_hue(original_hue + HueShift_Shadows) : norm_hue(target_hue_S + HueShift_Shadows);
    eff_h_S = apply_skin_tone_protection(original_hue, eff_h_S, EnableSkinToneProtection, SkinProtect_HueMin, SkinProtect_HueMax, SkinProtect_Falloff);
    eff_s_S = original_sat * S_sat;
    eff_l_S = original_lum * S_light;
    if (!EnableShadows) {
        eff_h_S = original_hue; eff_s_S = original_sat; eff_l_S = original_lum;
    }

    // Midtone region
    eff_h_M = (active_scheme == SCHEME_MANUAL) ? norm_hue(original_hue + HueShift_Midtones) : norm_hue(target_hue_M + HueShift_Midtones);
    eff_h_M = apply_skin_tone_protection(original_hue, eff_h_M, EnableSkinToneProtection, SkinProtect_HueMin, SkinProtect_HueMax, SkinProtect_Falloff);
    eff_s_M = original_sat * M_sat;
    eff_l_M = original_lum * M_light;
    if (!EnableMidtones) {
        eff_h_M = original_hue; eff_s_M = original_sat; eff_l_M = original_lum;
    }

    // Highlight region
    eff_h_H = (active_scheme == SCHEME_MANUAL) ? norm_hue(original_hue + HueShift_Highlights) : norm_hue(target_hue_H + HueShift_Highlights);
    eff_h_H = apply_skin_tone_protection(original_hue, eff_h_H, EnableSkinToneProtection, SkinProtect_HueMin, SkinProtect_HueMax, SkinProtect_Falloff);
    eff_s_H = original_sat * H_sat;
    eff_l_H = original_lum * H_light;
    if (!EnableHighlights) {
        eff_h_H = original_hue; eff_s_H = original_sat; eff_l_H = original_lum;
    }

    // Combine using weights (Ws, Wm, Wh are normalized in get_tonal_weights to sum to 1.0)
    // Store effective HSL per region before blending
    float3 hsl_S_eff = float3(eff_h_S, eff_s_S, eff_l_S);
    float3 hsl_M_eff = float3(eff_h_M, eff_s_M, eff_l_M);
    float3 hsl_H_eff = float3(eff_h_H, eff_s_H, eff_l_H);

    float3 blended_hsl_values = blend_hsl_weighted(hsl_S_eff, Ws, hsl_M_eff, Wm, hsl_H_eff, Wh);
    
    float3 blended_hsl = float3(blended_hsl_values.x, saturate(blended_hsl_values.y), saturate(blended_hsl_values.z));

    // --- Convert back to RGB and apply final mix ---
    float3 final_color_rgb = hsl_to_rgb(blended_hsl); // Use the new blended_hsl
    
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
