/**
 * AS_BGX_StudioBackdrop.1.fx - Versatile Studio Backdrop Generator
 * Author: Aquitaine Studio (AI Assisted)
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a customizable studio-style backdrop that can be placed behind scene elements.
 * Offers multiple material presets including flat colors, gradients, procedural textures (like velvet, canvas),
 * and user-supplied image textures. Designed for virtual photography and video production.
 *
 * FEATURES:
 * - Multiple material presets: Flat Color, Gradients, Velvet, Canvas, Plastic, Metal, Concrete, Custom Texture, Chroma Key.
 * - Depth-aware placement using standard AS_StageFX depth controls.
 * - Customizable colors, surface properties (scale, detail, smoothness), and lighting interaction.
 * - Simulated light source for specular highlights and sheen.
 * - Optional overlay vignette and blending options.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Performs a depth check to only draw on pixels further than a specified depth.
 * 2. A "Material Type" combo box selects the core rendering logic.
 * 3. Colors are applied based on 'Main Color', 'Accent Color', or an optional palette.
 * 4. Surface properties like pattern scale, detail, and smoothness modify the material's base appearance.
 * 5. A simulated light source interacts with the surface to produce highlights and sheen, influenced by smoothness and material type.
 * 6. Optional optical distortion (like CA) can be applied to highlights.
 * 7. Custom image textures can be used, with tiling, scrolling, and fit mode options.
 * 8. An optional vignette can be overlaid on the final backdrop.
 * 9. Standard AS_StageFX blending is applied.
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD
// ============================================================================
#ifndef __AS_BGX_StudioBackdrop_1_fx
#define __AS_BGX_StudioBackdrop_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "ReShadeUI.fxh" 
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"
#include "AS_Noise.1.fxh"

// ============================================================================
// DEFINES & CONSTANTS FOR UI
// ============================================================================

static const int MAT_PRESET_OFF = 0;
static const int MAT_PRESET_FLAT_COLOR = 1;
static const int MAT_PRESET_LINEAR_GRADIENT = 2;
static const int MAT_PRESET_RADIAL_GRADIENT = 3;
static const int MAT_PRESET_THIN_VELVET = 4;
static const int MAT_PRESET_THICK_VELOUR = 5;
static const int MAT_PRESET_COTTON_CANVAS = 6;
static const int MAT_PRESET_SILK_FABRIC = 7;
static const int MAT_PRESET_GLOSSY_PLASTIC = 8;
static const int MAT_PRESET_MATTE_PLASTIC = 9;
static const int MAT_PRESET_BRUSHED_METAL = 10;
static const int MAT_PRESET_ROUGH_CONCRETE = 11;
static const int MAT_PRESET_CUSTOM_TEXTURE = 12;
static const int MAT_PRESET_CHROMA_GREEN = 13;
static const int MAT_PRESET_CHROMA_BLUE = 14;

static const float3 COLOR_DEFAULT_BASE_VAL = float3(0.2f, 0.2f, 0.25f);
static const float3 COLOR_DEFAULT_ACCENT_VAL = float3(0.4f, 0.4f, 0.5f);
static const float3 COLOR_DEFAULT_HIGHLIGHT_VAL = float3(1.0f, 1.0f, 1.0f);
static const float3 COLOR_CHROMA_GREEN_VAL = float3(0.0f, 1.0f, 0.0f);
static const float3 COLOR_CHROMA_BLUE_VAL = float3(0.0f, 0.0f, 1.0f);

static const float DETAIL_SCALE_MIN = 0.1f; static const float DETAIL_SCALE_MAX = 100.0f; static const float DETAIL_SCALE_DEFAULT = 10.0f; static const float DETAIL_SCALE_STEP = 0.1f;
static const float DETAIL_INTENSITY_MIN = 0.0f; static const float DETAIL_INTENSITY_MAX = 1.0f; static const float DETAIL_INTENSITY_DEFAULT = 0.5f; static const float DETAIL_INTENSITY_STEP = 0.01f;
static const float SURFACE_SMOOTHNESS_MIN = 0.0f; static const float SURFACE_SMOOTHNESS_MAX = 1.0f; static const float SURFACE_SMOOTHNESS_DEFAULT = 0.5f; static const float SURFACE_SMOOTHNESS_STEP = 0.01f;
static const float ANIMATION_SPEED_MIN = 0.0f; static const float ANIMATION_SPEED_MAX = 2.0f; static const float ANIMATION_SPEED_DEFAULT = 0.1f; static const float ANIMATION_SPEED_STEP = 0.01f;

static const float GRADIENT_ANGLE_MIN = -180.0f; static const float GRADIENT_ANGLE_MAX = 180.0f; static const float GRADIENT_ANGLE_DEFAULT = 0.0f; static const float GRADIENT_ANGLE_STEP = 0.1f;
static const float GRADIENT_POS_MIN = -1.0f; static const float GRADIENT_POS_MAX = 1.0f; static const float GRADIENT_POS_DEFAULT = 0.0f; static const float GRADIENT_POS_STEP = 0.01f;

static const float LIGHT_DIR_MIN = -1.0f; static const float LIGHT_DIR_MAX = 1.0f; static const float LIGHT_DIR_DEFAULT_X = 0.4f; static const float LIGHT_DIR_DEFAULT_Y = 0.6f; static const float LIGHT_DIR_DEFAULT_Z = 0.8f; static const float LIGHT_DIR_STEP = 0.01f;
static const float HIGHLIGHT_INTENSITY_MIN = 0.0f; static const float HIGHLIGHT_INTENSITY_MAX = 2.0f; static const float HIGHLIGHT_INTENSITY_DEFAULT = 0.7f; static const float HIGHLIGHT_INTENSITY_STEP = 0.01f;
static const float EDGE_LIGHT_MIN = 0.0f; static const float EDGE_LIGHT_MAX = 1.0f; static const float EDGE_LIGHT_DEFAULT = 0.1f; static const float EDGE_LIGHT_STEP = 0.01f;
static const float OPTICAL_DIST_MIN = 0.0f; static const float OPTICAL_DIST_MAX = 0.05f; static const float OPTICAL_DIST_DEFAULT = 0.005f; static const float OPTICAL_DIST_STEP = 0.0005f;

static const float IMG_TILING_MIN = 0.01f; static const float IMG_TILING_MAX = 10.0f; static const float IMG_TILING_DEFAULT = 1.0f; static const float IMG_TILING_STEP = 0.01f;
static const float IMG_SCROLL_MIN = -1.0f; static const float IMG_SCROLL_MAX = 1.0f; static const float IMG_SCROLL_DEFAULT = 0.0f; static const float IMG_SCROLL_STEP = 0.01f;
static const int IMG_FIT_STRETCH = 0; static const int IMG_FIT_COVER = 1; static const int IMG_FIT_CONTAIN = 2;

static const float VIGNETTE_INT_MIN = 0.0f; static const float VIGNETTE_INT_MAX = 2.0f; static const float VIGNETTE_INT_DEFAULT = 0.5f; static const float VIGNETTE_INT_STEP = 0.01f;
static const float VIGNETTE_SIZE_MIN = 0.0f; static const float VIGNETTE_SIZE_MAX = 1.0f; static const float VIGNETTE_SIZE_DEFAULT = 0.85f; static const float VIGNETTE_SIZE_STEP = 0.01f;
static const float VIGNETTE_SOFT_MIN = 0.01f; static const float VIGNETTE_SOFT_MAX = 1.0f; static const float VIGNETTE_SOFT_DEFAULT = 0.3f; static const float VIGNETTE_SOFT_STEP = 0.01f;
static const float3 VIGNETTE_COLOR_DEFAULT = float3(0.0f, 0.0f, 0.0f);

// ============================================================================
// UNIFORM DECLARATIONS
// ============================================================================

uniform int BackdropMaterialPreset < ui_type = "combo"; ui_label = "1. Choose Material Type"; ui_tooltip = "Select the base material for your backdrop. Further settings will customize this material."; ui_items = "Off\0Flat Color\0Soft Linear Gradient\0Soft Radial Gradient\0Thin Velvet\0Thick Velour\0Cotton Canvas\0Silk Fabric\0Glossy Plastic\0Matte Plastic\0Brushed Metal\0Rough Concrete\0Custom Image Texture\0Chroma Key Green\0Chroma Key Blue\0"; ui_category = "Backdrop Setup"; > = MAT_PRESET_FLAT_COLOR;
AS_STAGEDEPTH_UI(BackdropDepth)

uniform float3 BaseColor < ui_type = "color"; ui_label = "Main Color"; ui_tooltip = "Primary color of the backdrop material."; ui_category = "Material Colors"; > = COLOR_DEFAULT_BASE_VAL;
uniform float3 AccentColor < ui_type = "color"; ui_label = "Accent / Gradient End Color"; ui_tooltip = "Secondary color for gradients, fabric undertones, or other material effects. Not used by all material types."; ui_category = "Material Colors"; > = COLOR_DEFAULT_ACCENT_VAL;
AS_PALETTE_SELECTION_UI(MaterialPalette, "Color Palette (Optional)", AS_PALETTE_CUSTOM, "Material Colors")
AS_DECLARE_CUSTOM_PALETTE(StudioBackdrop_Palette_, "Material Colors")

uniform float DetailScale < ui_type = "slider"; ui_label = "Pattern / Detail Scale"; ui_tooltip = "Adjusts the size of procedural patterns like velvet grain, canvas weave, or noise. Also affects gradient transitions."; ui_min = DETAIL_SCALE_MIN; ui_max = DETAIL_SCALE_MAX; ui_step = DETAIL_SCALE_STEP; ui_category = "Surface Properties"; > = DETAIL_SCALE_DEFAULT;
uniform float DetailIntensity < ui_type = "slider"; ui_label = "Pattern / Detail Intensity"; ui_tooltip = "Controls how pronounced the material's inherent texture, pattern, or gradient transition is."; ui_min = DETAIL_INTENSITY_MIN; ui_max = DETAIL_INTENSITY_MAX; ui_step = DETAIL_INTENSITY_STEP; ui_category = "Surface Properties"; > = DETAIL_INTENSITY_DEFAULT;
uniform float SurfaceSmoothness < ui_type = "slider"; ui_label = "Surface Smoothness (Gloss)"; ui_tooltip = "How smooth and reflective the surface is. Higher values are glossier and have sharper highlights; lower values are more matte/diffuse."; ui_min = SURFACE_SMOOTHNESS_MIN; ui_max = SURFACE_SMOOTHNESS_MAX; ui_step = SURFACE_SMOOTHNESS_STEP; ui_category = "Surface Properties"; > = SURFACE_SMOOTHNESS_DEFAULT;
uniform float AnimationSpeed < ui_type = "slider"; ui_label = "Subtle Animation Speed"; ui_tooltip = "Adds slow, subtle animation to procedural textures if supported by the material (e.g., velvet shimmer, flowing gradients). 0 for static."; ui_min = ANIMATION_SPEED_MIN; ui_max = ANIMATION_SPEED_MAX; ui_step = ANIMATION_SPEED_STEP; ui_category = "Surface Properties"; > = ANIMATION_SPEED_DEFAULT;
uniform float GradientAngle < ui_type = "slider"; ui_label = "Gradient Angle"; ui_tooltip = "For linear gradients, sets the direction of the color transition."; ui_min = GRADIENT_ANGLE_MIN; ui_max = GRADIENT_ANGLE_MAX; ui_step = GRADIENT_ANGLE_STEP; ui_category = "Surface Properties"; > = GRADIENT_ANGLE_DEFAULT;
uniform float2 GradientPosition < ui_type = "slider"; ui_label = "Gradient Center / Start Point"; ui_tooltip = "For radial gradients, sets the center. For linear, can influence the transition's origin."; ui_min = GRADIENT_POS_MIN; ui_max = GRADIENT_POS_MAX; ui_step = GRADIENT_POS_STEP; ui_category = "Surface Properties"; > = float2(GRADIENT_POS_DEFAULT, GRADIENT_POS_DEFAULT);

uniform float3 LightSourceDirection < ui_type = "slider"; ui_label = "Light Source Direction (XYZ)"; ui_tooltip = "Simulates a key light affecting the backdrop. Influences shading and highlights. X: Left/Right, Y: Up/Down, Z: Towards/Away from surface."; ui_min = LIGHT_DIR_MIN; ui_max = LIGHT_DIR_MAX; ui_step = LIGHT_DIR_STEP; ui_category = "Lighting Interaction"; > = float3(LIGHT_DIR_DEFAULT_X, LIGHT_DIR_DEFAULT_Y, LIGHT_DIR_DEFAULT_Z);
uniform float3 HighlightTint < ui_type = "color"; ui_label = "Highlight / Sheen Color"; ui_tooltip = "Color tint of the reflections or sheen on the material."; ui_category = "Lighting Interaction"; > = COLOR_DEFAULT_HIGHLIGHT_VAL;
uniform float HighlightIntensity < ui_type = "slider"; ui_label = "Highlight / Sheen Intensity"; ui_tooltip = "Brightness of reflections or sheen. Depends on Surface Smoothness."; ui_min = HIGHLIGHT_INTENSITY_MIN; ui_max = HIGHLIGHT_INTENSITY_MAX; ui_step = HIGHLIGHT_INTENSITY_STEP; ui_category = "Lighting Interaction"; > = HIGHLIGHT_INTENSITY_DEFAULT;
uniform float EdgeLightEffect < ui_type = "slider"; ui_label = "Edge Light / Fresnel Effect"; ui_tooltip = "Adds a subtle lighting effect to edges facing away from the camera, common on fabrics or for a rim light effect."; ui_min = EDGE_LIGHT_MIN; ui_max = EDGE_LIGHT_MAX; ui_step = EDGE_LIGHT_STEP; ui_category = "Lighting Interaction"; > = EDGE_LIGHT_DEFAULT;
uniform bool EnableOpticalDistortion < ui_label = "Enable Optical Distortion (e.g., CA)"; ui_tooltip = "For materials like glossy plastic, adds subtle optical effects like color fringing (chromatic aberration) to highlights."; ui_category = "Lighting Interaction"; > = false;
uniform float OpticalDistortionAmount < ui_type = "slider"; ui_label = "Optical Distortion Amount"; ui_tooltip = "Strength of the optical distortion effect. Use small values."; ui_min = OPTICAL_DIST_MIN; ui_max = OPTICAL_DIST_MAX; ui_step = OPTICAL_DIST_STEP; ui_category = "Lighting Interaction"; > = OPTICAL_DIST_DEFAULT;

#ifndef StudioBackdrop_UserTexture_Source
    #define StudioBackdrop_UserTexture_Source "AS_DefaultBlack.png"
#endif
uniform texture StudioBackdrop_UserTexture < source = StudioBackdrop_UserTexture_Source; ui_label = "Your Image File"; ui_tooltip = "Select your custom image to use as a backdrop."; ui_category = "Custom Image Texture"; > { Width = 256; Height = 256; Format = RGBA8; };
sampler StudioBackdrop_UserSampler { Texture = StudioBackdrop_UserTexture; AddressU = REPEAT; AddressV = REPEAT; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
uniform float2 ImageTiling < ui_type = "slider"; ui_label = "Image Tiling (Horizontal, Vertical)"; ui_tooltip = "How many times the image repeats across the backdrop."; ui_min = IMG_TILING_MIN; ui_max = IMG_TILING_MAX; ui_step = IMG_TILING_STEP; ui_category = "Custom Image Texture"; > = float2(IMG_TILING_DEFAULT, IMG_TILING_DEFAULT);
uniform float2 ImageScroll < ui_type = "slider"; ui_label = "Image Scroll (Horizontal, Vertical)"; ui_tooltip = "Offsets the image position on the backdrop."; ui_min = IMG_SCROLL_MIN; ui_max = IMG_SCROLL_MAX; ui_step = IMG_SCROLL_STEP; ui_category = "Custom Image Texture"; > = float2(IMG_SCROLL_DEFAULT, IMG_SCROLL_DEFAULT);
uniform int ImageFitMode < ui_type = "combo"; ui_label = "Image Fit Mode"; ui_items = "Stretch to Fill\0Cover (Keep Aspect, May Crop)\0Contain (Keep Aspect, May Letterbox)\0"; ui_tooltip = "Determines how the image scales to fit the screen, especially if not tiling significantly."; ui_category = "Custom Image Texture"; > = IMG_FIT_COVER;
uniform float ImageOpacity < ui_type = "slider"; ui_label = "Image Opacity"; ui_min = AS_OP_MIN; ui_max = AS_OP_MAX; ui_step = 0.01f; ui_category = "Custom Image Texture"; > = AS_OP_DEFAULT;

uniform bool EnableOverlayVignette < ui_label = "Enable Vignette Overlay"; ui_tooltip = "Adds a darkening/coloring effect to the edges of the backdrop itself, for focus."; ui_category = "Final Adjustments"; > = false;
uniform float3 OverlayVignetteColor < ui_type = "color"; ui_label = "Vignette Color"; ui_tooltip = "Color of the vignette overlay."; ui_category = "Final Adjustments"; > = VIGNETTE_COLOR_DEFAULT;
uniform float OverlayVignetteIntensity < ui_type = "slider"; ui_label = "Vignette Intensity"; ui_tooltip = "Strength of the vignette overlay."; ui_min = VIGNETTE_INT_MIN; ui_max = VIGNETTE_INT_MAX; ui_step = VIGNETTE_INT_STEP; ui_category = "Final Adjustments"; > = VIGNETTE_INT_DEFAULT;
uniform float OverlayVignetteSize < ui_type = "slider"; ui_label = "Vignette Size"; ui_tooltip = "Controls the extent of the vignette from the edges. 1.0 is edges only, 0.0 covers more of the screen."; ui_min = VIGNETTE_SIZE_MIN; ui_max = VIGNETTE_SIZE_MAX; ui_step = VIGNETTE_SIZE_STEP; ui_category = "Final Adjustments"; > = VIGNETTE_SIZE_DEFAULT;
uniform float OverlayVignetteSoftness < ui_type = "slider"; ui_label = "Vignette Softness"; ui_tooltip = "Controls the feathering of the vignette edge."; ui_min = VIGNETTE_SOFT_MIN; ui_max = VIGNETTE_SOFT_MAX; ui_step = VIGNETTE_SOFT_STEP; ui_category = "Final Adjustments"; > = VIGNETTE_SOFT_DEFAULT;
AS_BLENDMODE_UI_DEFAULT(BackdropBlendMode, AS_BLEND_NORMAL)
AS_BLENDAMOUNT_UI(BackdropBlendAmount)

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================
float getDiffuseFactor(float3 normal, float3 lightDir)
{
    return saturate(dot(normal, lightDir));
}

float getSpecularFactor(float3 normal, float3 lightDir, float3 viewDir, float shininess_power)
{
    float3 halfVec = normalize(lightDir + viewDir);
    return pow(saturate(dot(normal, halfVec)), shininess_power);
}

float getFresnelFactor(float3 normal, float3 viewDir, float bias, float power)
{
    float fresnel = bias + (1.0f - bias) * pow(1.0f - saturate(dot(normal, viewDir)), power);
    return fresnel;
}

float2x2 getRotationMatrix2D(float angle_rad)
{
    float s = sin(angle_rad);
    float c = cos(angle_rad);
    return float2x2(c, -s, 
                    s,  c);
}


// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_StudioBackdrop(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // --- Step 1: Original Color Fetch ---
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);

    // --- Step 2: All Other Local Declarations ---
    float3 ps_finalBackdropColor;
    float ps_backdropAlpha;
    float time;
    float2 ps_uv;
    float2 ps_scaled_uv;
    float3 N, L, V;
    float ps_shininess_power;
    float2 img_uv_calc; 
    float4 texSample;   
    float2 vig_uv_local; 
    float vig_dist_local; 
    float vignetteFactor_local; 
    bool forceReplace_local;
    float3 ps_baseColor_derived;
    float3 ps_accentColor_derived;
    float sceneDepth; // Moved declaration here

    // --- Step 3: Initializations ---
    ps_backdropAlpha = 1.0f; // Default alpha
    ps_baseColor_derived = BaseColor; // Initialize with UI values first
    ps_accentColor_derived = AccentColor;
    ps_finalBackdropColor = ps_baseColor_derived; // Initialize with the (potentially palette-derived) base color

    time = AS_getTime() * AnimationSpeed;
    ps_uv = texcoord;
    ps_scaled_uv = ps_uv * DetailScale;
    N = float3(0.0f, 0.0f, 1.0f);
    L = normalize(LightSourceDirection);
    V = float3(0.0f, 0.0f, 1.0f);
    ps_shininess_power = pow(2.0f, (SurfaceSmoothness * 10.0f) + 2.0f);
    if (SurfaceSmoothness < 0.01f) ps_shininess_power = 4.0f;
    if (SurfaceSmoothness > 0.99f) ps_shininess_power = 4096.0f;
    sceneDepth = ReShade::GetLinearizedDepth(texcoord); // Initialize sceneDepth after its declaration
    // --- End Initializations ---

    // --- Step 4: Early Exits/Logic ---
    if (BackdropMaterialPreset == MAT_PRESET_OFF)
    {
        return originalColor;
    }

    if (sceneDepth < BackdropDepth - AS_DEPTH_EPSILON && BackdropDepth < (1.0f - AS_DEPTH_EPSILON))
    {
        return originalColor;
    }    // --- Palette Integration: Optionally override ps_baseColor_derived and ps_accentColor_derived ---
    if (MaterialPalette != AS_PALETTE_CUSTOM) 
    {
        // Use built-in palette colors
        ps_baseColor_derived = AS_getPaletteColor(MaterialPalette, 0);
        ps_accentColor_derived = AS_getPaletteColor(MaterialPalette, 1);
    }    else // MaterialPalette IS AS_PALETTE_CUSTOM
    {
        // For custom palette, we need to use the custom colors defined with the StudioBackdrop_Palette_ prefix
        if (MaterialPalette == AS_PALETTE_CUSTOM)
        {
            // Use the custom color UI variables directly
            ps_baseColor_derived = BaseColor; // Take from the direct UI color picker
            ps_accentColor_derived = AccentColor; // Take from the direct UI color picker
            
            // Alternative approach would be to use the custom palette colors:
            // ps_baseColor_derived = StudioBackdrop_Palette_CustomPaletteColor0;
            // ps_accentColor_derived = StudioBackdrop_Palette_CustomPaletteColor1;
        }
    }
    ps_finalBackdropColor = ps_baseColor_derived; // Update with potentially palette-derived color


    switch (BackdropMaterialPreset)
    {
        case MAT_PRESET_FLAT_COLOR:
            ps_finalBackdropColor = ps_baseColor_derived;
            break;
        case MAT_PRESET_LINEAR_GRADIENT:
        {
            float2 p = ps_uv - 0.5f;
            float angleRad = GradientAngle * AS_PI / 180.0f;
            float2 dir = float2(cos(angleRad), sin(angleRad));
            float gradientFactor = dot(p, dir) * (2.0f / DetailScale) + 0.5f + GradientPosition.x;
            gradientFactor = saturate(gradientFactor);
            ps_finalBackdropColor = lerp(ps_baseColor_derived, ps_accentColor_derived, gradientFactor);
            break;
        }
        case MAT_PRESET_RADIAL_GRADIENT:
        {
            float2 p = ps_uv - 0.5f - GradientPosition;
            float dist = length(p);
            float gradientFactor = smoothstep(0.0f, DetailScale * 0.1f, dist);
            gradientFactor = saturate(gradientFactor);
            ps_finalBackdropColor = lerp(ps_baseColor_derived, ps_accentColor_derived, gradientFactor);
            break;
        }
        case MAT_PRESET_THIN_VELVET:
        case MAT_PRESET_THICK_VELOUR:
        {
            float noiseFactor = (BackdropMaterialPreset == MAT_PRESET_THIN_VELVET) ? 0.15f : 0.3f;
            float baseNoiseTime = time * 0.1f; 
            float baseNoise = AS_PerlinNoise2DA(ps_scaled_uv * float2(1.0f, 0.5f), baseNoiseTime) * noiseFactor * DetailIntensity;
            ps_finalBackdropColor = ps_baseColor_derived * (1.0f - baseNoise) + ps_accentColor_derived * baseNoise;

            float fiberAngle = (ps_uv.x + ps_uv.y) * AS_PI * 2.0f * (5.0f + DetailScale * 0.1f);
            float3 fiberDir = normalize(float3(sin(fiberAngle), cos(fiberAngle), 0.1f));
            float sheenDot = pow(saturate(dot(N, normalize(L + V*0.5f))) * 0.5f + saturate(dot(fiberDir,L))*0.5f , 2.0f);
            
            float fresnel = getFresnelFactor(N, V, 0.1f, 3.0f + EdgeLightEffect * 5.0f);
            float sheen = (sheenDot * (1.0f - SurfaceSmoothness*0.8f) + fresnel * SurfaceSmoothness * 1.5f) * HighlightIntensity;
            
            ps_finalBackdropColor = lerp(ps_finalBackdropColor, HighlightTint, saturate(sheen * DetailIntensity));
            ps_finalBackdropColor += HighlightTint * getSpecularFactor(N, L, V, ps_shininess_power *0.2f) * HighlightIntensity * SurfaceSmoothness * 0.5f;
            break;
        }
        case MAT_PRESET_COTTON_CANVAS:
        {
            float weaveX = AS_Fbm2DA(ps_scaled_uv * float2(1.0f, 0.2f), time * 0.01f, 3, 2.0f, 0.5f) * DetailIntensity;
            float weaveY = AS_Fbm2DA(ps_scaled_uv * float2(0.2f, 1.0f), time * 0.01f + 0.5f, 3, 2.0f, 0.5f) * DetailIntensity;
            float weave = (weaveX + weaveY) * 0.5f;
            ps_finalBackdropColor = lerp(ps_baseColor_derived, ps_accentColor_derived, saturate(weave));
            ps_finalBackdropColor *= (0.8f + 0.2f * getDiffuseFactor(N,L));
            ps_finalBackdropColor += HighlightTint * getSpecularFactor(N, L, V, ps_shininess_power * 0.05f) * HighlightIntensity * SurfaceSmoothness * 0.1f;
            break;
        }
        case MAT_PRESET_SILK_FABRIC:
        {
            float2 sheen_uv = ps_scaled_uv + AS_PerlinNoise2DA(ps_scaled_uv * 0.1f, time) * 0.5f * DetailIntensity; 
            float baseNoise = AS_PerlinNoise2D(sheen_uv * float2(1.0f, 0.1f)); 
            float sheen = pow(saturate(baseNoise * 0.8f + 0.2f), 20.0f * (SurfaceSmoothness + 0.1f)) * HighlightIntensity;
            ps_finalBackdropColor = ps_baseColor_derived * (0.7f + 0.3f * getDiffuseFactor(N,L));
            ps_finalBackdropColor = lerp(ps_finalBackdropColor, HighlightTint, sheen);
            ps_finalBackdropColor += HighlightTint * getFresnelFactor(N,V, 0.05f, 5.0f + EdgeLightEffect * 5.0f) * HighlightIntensity * 0.7f;
            break;
        }
        case MAT_PRESET_GLOSSY_PLASTIC:
        case MAT_PRESET_MATTE_PLASTIC:
        {
            float current_shininess_power = (BackdropMaterialPreset == MAT_PRESET_GLOSSY_PLASTIC) ? ps_shininess_power : ps_shininess_power * 0.1f;
            float diffuse = getDiffuseFactor(N,L);
            ps_finalBackdropColor = ps_baseColor_derived * (0.6f + 0.4f * diffuse);
            
            float3 specularColor = HighlightTint;
            float specFactorG = getSpecularFactor(N, L, V, current_shininess_power);
            float3 specular = specularColor * specFactorG * HighlightIntensity;

            if (EnableOpticalDistortion)
            {
                float2 ca_dir = normalize(L.xy); 
                if(length(ca_dir) < AS_EPSILON) ca_dir = float2(1.0, 0.0); 
                float2 ca_offset_xy = ca_dir * OpticalDistortionAmount * 0.1f;

                float3 L_r = normalize(L + float3(ca_offset_xy, 0.0f));
                float3 L_b = normalize(L - float3(ca_offset_xy, 0.0f));
                specular.r = specularColor.r * getSpecularFactor(N, L_r, V, current_shininess_power) * HighlightIntensity;
                specular.b = specularColor.b * getSpecularFactor(N, L_b, V, current_shininess_power) * HighlightIntensity;
            }
            ps_finalBackdropColor += specular;
            ps_finalBackdropColor += HighlightTint * getFresnelFactor(N,V, 0.02f * SurfaceSmoothness, 5.0f + EdgeLightEffect * 3.0f) * HighlightIntensity * 0.5f;
            break;
        }
        case MAT_PRESET_BRUSHED_METAL:
        {
            float angle_rad = DetailScale * 0.1f * AS_PI;
            float2x2 rotMat = getRotationMatrix2D(angle_rad);
            float2x2 invRotMat = getRotationMatrix2D(-angle_rad);

            float2 brushed_uv_local_rot = AS_mul_float2x2_float2(rotMat, ps_scaled_uv);
            brushed_uv_local_rot.y *= 0.05f;
            float noise = AS_Fbm2DA(brushed_uv_local_rot, time * 0.05f, 4, 2.0f, 0.4f) * DetailIntensity;
            ps_finalBackdropColor = lerp(ps_baseColor_derived, ps_accentColor_derived, noise);
            
            float2 L_xy_brush = AS_mul_float2x2_float2(rotMat, L.xy);
            float2 V_xy_brush = AS_mul_float2x2_float2(rotMat, V.xy);

            L_xy_brush.y *= 0.2f; 
            V_xy_brush.y *= 0.2f;

            float2 L_xy_aniso = AS_mul_float2x2_float2(invRotMat, L_xy_brush);
            float2 V_xy_aniso = AS_mul_float2x2_float2(invRotMat, V_xy_brush);
            
            float3 anisoL = normalize(float3(L_xy_aniso, L.z));
            float3 anisoV = normalize(float3(V_xy_aniso, V.z));

            ps_finalBackdropColor *= (0.5f + 0.5f * getDiffuseFactor(N,L));
            ps_finalBackdropColor += HighlightTint * getSpecularFactor(N, anisoL, anisoV, ps_shininess_power * 0.7f) * HighlightIntensity * 1.2f;
            ps_finalBackdropColor += HighlightTint * getFresnelFactor(N,V, 0.1f + EdgeLightEffect * 0.2f, 6.0f) * HighlightIntensity;
            break;
        }
        case MAT_PRESET_ROUGH_CONCRETE:
        {
            float concreteNoise1 = AS_Fbm2DA(ps_scaled_uv * 0.5f, time * 0.01f, 5, 2.1f, 0.55f) * DetailIntensity;
            float concreteNoise2 = AS_VoronoiNoise2DA(ps_scaled_uv * 2.0f, time * 0.005f) * 0.3f * DetailIntensity; 
            float concreteNoise = concreteNoise1 + concreteNoise2;
            ps_finalBackdropColor = lerp(ps_baseColor_derived, ps_accentColor_derived, saturate(concreteNoise));
            ps_finalBackdropColor *= (0.7f + 0.3f * getDiffuseFactor(N,L));
            ps_finalBackdropColor += HighlightTint * getSpecularFactor(N, L, V, ps_shininess_power * 0.01f) * HighlightIntensity * 0.05f * DetailIntensity;
            break;
        }
        case MAT_PRESET_CUSTOM_TEXTURE:
        {
            img_uv_calc = ps_uv; 
            if (ImageFitMode == IMG_FIT_COVER || ImageFitMode == IMG_FIT_CONTAIN)
            {
                float2 texSize = float2(512, 512);
                if(texSize.x > 0.0f && texSize.y > 0.0f)
                {
                    float texAspect = texSize.x / texSize.y;
                    float screenAspect = ReShade::AspectRatio;
                    float2 scaleFactor = float2(1.0f, 1.0f);
                    if (ImageFitMode == IMG_FIT_COVER)
                    {
                        if (screenAspect > texAspect) scaleFactor = float2(screenAspect / texAspect, 1.0f);
                        else scaleFactor = float2(1.0f, texAspect / screenAspect);
                    }
                    else // IMG_FIT_CONTAIN
                    {
                        if (screenAspect > texAspect) scaleFactor = float2(1.0f, texAspect / screenAspect);
                        else scaleFactor = float2(screenAspect / texAspect, 1.0f);
                    }
                    img_uv_calc = (ps_uv - 0.5f) * scaleFactor + 0.5f;
                }
            }
            img_uv_calc = img_uv_calc * ImageTiling + ImageScroll;
            texSample = tex2D(StudioBackdrop_UserSampler, img_uv_calc); 
            ps_finalBackdropColor = texSample.rgb;
            ps_backdropAlpha = texSample.a * ImageOpacity;
            break; 
        }
        case MAT_PRESET_CHROMA_GREEN:
            ps_finalBackdropColor = COLOR_CHROMA_GREEN_VAL;
            break; 
        case MAT_PRESET_CHROMA_BLUE:
            ps_finalBackdropColor = COLOR_CHROMA_BLUE_VAL;
            break; 
    } // End Switch

    if (EnableOverlayVignette)
    {
        vig_uv_local = ps_uv - 0.5f; 
        vig_dist_local = length(vig_uv_local * float2(ReShade::AspectRatio, 1.0f));
        vignetteFactor_local = smoothstep(OverlayVignetteSize * 0.5f, OverlayVignetteSize * 0.5f - OverlayVignetteSoftness * 0.5f, vig_dist_local);
        ps_finalBackdropColor = lerp(ps_finalBackdropColor, OverlayVignetteColor, vignetteFactor_local * OverlayVignetteIntensity);
    }

    float4 finalCombinedColorOut = float4(ps_finalBackdropColor, ps_backdropAlpha); 
    forceReplace_local = BackdropDepth >= (1.0f - AS_DEPTH_EPSILON); 

    return AS_applyBlend(finalCombinedColorOut, originalColor, BackdropBlendMode, BackdropBlendAmount);
} // End PS_StudioBackdrop


// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_BGX_StudioBackdrop < ui_tooltip = "Generates a versatile studio-style backdrop with multiple configurable material presets like flat colors, gradients, procedural textures (velvet, canvas, plastic, metal), or user-supplied images. Includes depth placement, simulated lighting, and vignette options."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_StudioBackdrop;
    }
}

#endif // __AS_BGX_StudioBackdrop_1_fx