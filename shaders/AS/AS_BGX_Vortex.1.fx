/**
 * AS_BGX_Vortex.1.fx - Swirling Vortex Pattern
 * Author: Leon Aquitaine
 * License: CC BY 4.0
 * Original Source: https://www.shadertoy.com/view/3fKGRd "Vortex__" by LonkDong
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a psychedelic swirling vortex pattern. The effect is animated and
 * features controls for color, animation speed, swirl characteristics, and brightness.
 * Suitable as a dynamic background.
 *
 * FEATURES:
 * - Animated vortex with customizable speed.
 * - Palette-based coloring, radiating from center to edges.
 * - Controls for swirl intensity, frequency, and sharpness.
 * - Brightness falloff and overall intensity controls.
 * - Standard AS-StageFX blending and positioning.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. UV coordinates are transformed based on UI controls (position, scale, rotation).
 * 2. Polar coordinates (radius 'r' and angle 'a') are calculated from the transformed UVs.
 * 3. Palette colors are mapped based on the normalized radial distance 'r'.
 * 4. A swirl effect is applied to the angle 'a', incorporating time, radius,
 * and a user-defined swirl factor.
 * 5. A sine wave pattern is generated based on the swirled angle and frequency.
 * 6. A smooth mask is created from this pattern.
 * 7. Brightness is calculated based on the radius and applied along with the mask
 * to the palette-derived color.
 *
 * ===================================================================================
 */

#ifndef __AS_BGX_Vortex_1_fx
#define __AS_BGX_Vortex_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

namespace ASVortex {

// ============================================================================
// CONSTANTS
// ============================================================================

// Animation Speed
static const float VORTEX_ANIM_SPEED_MIN = 0.0f;
static const float VORTEX_ANIM_SPEED_MAX = 5.0f;
static const float VORTEX_ANIM_SPEED_DEFAULT = 0.7f;

// Swirl Parameters
static const float VORTEX_SWIRL_FALLOFF_MIN = 0.01f;
static const float VORTEX_SWIRL_FALLOFF_MAX = 5.0f;
static const float VORTEX_SWIRL_FALLOFF_DEFAULT = 1.5f;
static const float VORTEX_SWIRL_FREQUENCY_MIN = 1.0f;
static const float VORTEX_SWIRL_FREQUENCY_MAX = 32.0f;
static const float VORTEX_SWIRL_FREQUENCY_DEFAULT = 8.0f;

// Mask Edges
static const float VORTEX_MASK_EDGE1_MIN = 0.0f;
static const float VORTEX_MASK_EDGE1_MAX = 1.0f;
static const float VORTEX_MASK_EDGE1_DEFAULT = 0.5f;
static const float VORTEX_MASK_EDGE2_MIN = 0.0f;
static const float VORTEX_MASK_EDGE2_MAX = 1.0f;
static const float VORTEX_MASK_EDGE2_DEFAULT = 0.43f;

// Brightness
static const float VORTEX_BRIGHTNESS_FALLOFF_MIN = 0.1f;
static const float VORTEX_BRIGHTNESS_FALLOFF_MAX = 3.0f;
static const float VORTEX_BRIGHTNESS_FALLOFF_DEFAULT = 1.3f;
static const float VORTEX_BRIGHTNESS_INTENSITY_MIN = 0.1f;
static const float VORTEX_BRIGHTNESS_INTENSITY_MAX = 5.0f;
static const float VORTEX_BRIGHTNESS_INTENSITY_DEFAULT = 2.0f;

// Color Mapping
static const float VORTEX_COLOR_FREQ_MIN = 0.1f;
static const float VORTEX_COLOR_FREQ_MAX = 10.0f;
static const float VORTEX_COLOR_FREQ_DEFAULT = 1.0f;
static const float VORTEX_COLOR_OFFSET_MIN = 0.0f;
static const float VORTEX_COLOR_OFFSET_MAX = 1.0f;
static const float VORTEX_COLOR_OFFSET_DEFAULT = 0.0f;


// ============================================================================
// UI DECLARATIONS
// ============================================================================

// Position & Transformation
AS_POSITION_SCALE_UI(EffectCenter, EffectScale)

// Palette & Style
AS_PALETTE_SELECTION_UI(Vortex_Palette, "Color Palette", AS_PALETTE_FIRE, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(Vortex_, "Palette & Style")
uniform float Vortex_ColorOffset < ui_type = "slider"; ui_label = "Palette Offset (Radial)"; ui_tooltip = "Shifts the start of the palette mapping along the radius."; ui_min = VORTEX_COLOR_OFFSET_MIN; ui_max = VORTEX_COLOR_OFFSET_MAX; ui_step = 0.01; ui_category = "Palette & Style"; > = VORTEX_COLOR_OFFSET_DEFAULT;
uniform float Vortex_ColorFrequency < ui_type = "slider"; ui_label = "Palette Frequency (Radial)"; ui_tooltip = "Controls how many times the palette repeats from center to edge."; ui_min = VORTEX_COLOR_FREQ_MIN; ui_max = VORTEX_COLOR_FREQ_MAX; ui_step = 0.1; ui_category = "Palette & Style"; > = VORTEX_COLOR_FREQ_DEFAULT;

// Effect-Specific Appearance
uniform float Vortex_SwirlFalloff < ui_type = "slider"; ui_label = "Swirl Falloff"; ui_tooltip = "Controls how much the swirl diminishes from the center"; ui_min = VORTEX_SWIRL_FALLOFF_MIN; ui_max = VORTEX_SWIRL_FALLOFF_MAX; ui_category = "Vortex Pattern"; > = VORTEX_SWIRL_FALLOFF_DEFAULT;
uniform float Vortex_SwirlFrequency < ui_type = "slider"; ui_label = "Swirl Frequency"; ui_tooltip = "Number of swirl arms/repetitions"; ui_step = 1.0; ui_min = VORTEX_SWIRL_FREQUENCY_MIN; ui_max = VORTEX_SWIRL_FREQUENCY_MAX; ui_category = "Vortex Pattern"; > = VORTEX_SWIRL_FREQUENCY_DEFAULT;
uniform float Vortex_MaskEdge1 < ui_type = "slider"; ui_label = "Mask Edge 1"; ui_tooltip = "Controls the sharpness of the vortex pattern"; ui_min = VORTEX_MASK_EDGE1_MIN; ui_max = VORTEX_MASK_EDGE1_MAX; ui_category = "Vortex Pattern"; > = VORTEX_MASK_EDGE1_DEFAULT;
uniform float Vortex_MaskEdge2 < ui_type = "slider"; ui_label = "Mask Edge 2"; ui_tooltip = "Controls the sharpness of the vortex pattern"; ui_min = VORTEX_MASK_EDGE2_MIN; ui_max = VORTEX_MASK_EDGE2_MAX; ui_category = "Vortex Pattern"; > = VORTEX_MASK_EDGE2_DEFAULT;
uniform float Vortex_BrightnessFalloff < ui_type = "slider"; ui_label = "Brightness Falloff / Palette Edge"; ui_tooltip = "Controls how quickly brightness fades from the center. Also defines the 'edge' for palette mapping (palette color 4)."; ui_min = VORTEX_BRIGHTNESS_FALLOFF_MIN; ui_max = VORTEX_BRIGHTNESS_FALLOFF_MAX; ui_category = "Vortex Pattern"; > = VORTEX_BRIGHTNESS_FALLOFF_DEFAULT;
uniform float Vortex_BrightnessIntensity < ui_type = "slider"; ui_label = "Overall Brightness Intensity"; ui_tooltip = "Final multiplier for the vortex brightness"; ui_min = VORTEX_BRIGHTNESS_INTENSITY_MIN; ui_max = VORTEX_BRIGHTNESS_INTENSITY_MAX; ui_category = "Vortex Pattern"; > = VORTEX_BRIGHTNESS_INTENSITY_DEFAULT;

// Animation Controls
AS_ANIMATION_UI(Vortex_AnimationSpeed, Vortex_AnimationKeyframe, "Animation")

// Stage Controls
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(SnapRotation, FineRotation)

// Final Mix
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0) // Defaulting to ADD as it's common for such effects
AS_BLENDAMOUNT_UI(BlendStrength)

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_AS_BGX_Vortex_1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 finalColor = tex2D(ReShade::BackBuffer, texcoord); // Get original scene color

    // --- Depth Check ---
    if (ReShade::GetLinearizedDepth(texcoord) < EffectDepth - AS_DEPTH_EPSILON)
    {
        return finalColor;
    }
    
    // --- Time ---
    // Vortex_AnimationSpeed and Vortex_AnimationKeyframe are directly used by AS_getAnimationTime
    float time = AS_getAnimationTime(Vortex_AnimationSpeed, Vortex_AnimationKeyframe);
    
    // --- Coordinate Transformation ---
    // Get global rotation from UI settings
    float globalRotation = AS_getRotationRadians(SnapRotation, FineRotation);
    
    // The vortex effect works best with properly normalized coordinates
    // First get normalized screen coordinates (0 to 1)
    float2 screenUV = texcoord;
    
    // Convert to centered coordinates (-0.5 to 0.5)
    float2 centered = screenUV - 0.5;
    
    // Apply aspect ratio correction to ensure the vortex is circular, not elliptical
    // This correction should make the 'centered' space visually square before other transforms.
    if (ReShade::AspectRatio >= 1.0) { // Wider than tall
        centered.x *= ReShade::AspectRatio;
    } else { // Taller than wide
        centered.y /= ReShade::AspectRatio;
    }
    
    // Apply position offset from UI
    // EffectCenter components are typically -1 to 1 for full screen span in the dominant axis.
    // The 'centered' space after aspect correction might span more than -0.5 to 0.5 in one dimension.
    // Example: 16:9 screen, centered.x ranges from -0.5*1.77 to 0.5*1.77.
    // To map EffectCenter.x of -1 to the left edge of this corrected space and +1 to the right:
    centered.x -= EffectCenter.x * (ReShade::AspectRatio >= 1.0 ? ReShade::AspectRatio * 0.5 : 0.5);
    centered.y += EffectCenter.y * (ReShade::AspectRatio < 1.0 ? (1.0/ReShade::AspectRatio) * 0.5 : 0.5); // Y is inverted
    
    // Apply scale from UI (higher value = zoomed out, smaller effect)
    // To make EffectScale=1.0 a neutral scale, and smaller values zoom in:
    float2 scaled = centered / max(EffectScale, 0.001f); 
    
    // Apply rotation
    float2 rotated_uv = scaled; // Renamed for clarity
    if (abs(globalRotation) > 0.001) { // Avoid sin/cos for zero rotation
        float s = sin(globalRotation);
        float c = cos(globalRotation);
        rotated_uv.x = scaled.x * c - scaled.y * s;
        rotated_uv.y = scaled.x * s + scaled.y * c;
    }
    
    float2 vortex_uv = rotated_uv;

    // --- Effect Logic (from original GLSL) ---
    float r = length(vortex_uv);
    float a = atan2(vortex_uv.y, vortex_uv.x); // HLSL atan2 takes (y,x)
    
    // Vortex Swirl Pattern
    float swirl_animation_time = time; // Use the time from AS_getAnimationTime
    float swirl = a + swirl_animation_time + Vortex_SwirlFalloff / (r + 0.01f);
    float pattern = sin(swirl * Vortex_SwirlFrequency);
    float mask = smoothstep(Vortex_MaskEdge1, Vortex_MaskEdge2, abs(pattern));

    // --- Palette Color Calculation (Radial) ---
    // Normalize radial distance 'r' using Vortex_BrightnessFalloff as the "edge"
    // This means at r = Vortex_BrightnessFalloff, palette_radial_map will be 1.0
    float palette_radial_map = saturate(r / max(Vortex_BrightnessFalloff, 0.001f));
    
    // Apply frequency and offset to this radial map to get the final palette lookup value
    float colorValue = frac(palette_radial_map * Vortex_ColorFrequency + Vortex_ColorOffset);
    
    // Get color from palette
    float3 baseColor;
    if (Vortex_Palette == AS_PALETTE_CUSTOM) {
        baseColor = AS_GET_INTERPOLATED_CUSTOM_COLOR(Vortex_, colorValue);
    } else {
        baseColor = AS_getInterpolatedColor(Vortex_Palette, colorValue);
    }
    
    // --- Final Appearance ---
    // Calculate brightness based on radius (falls off towards Vortex_BrightnessFalloff)
    float brightness_factor = smoothstep(Vortex_BrightnessFalloff, 0.0f, r); // Inverted smoothstep for falloff
    
    // Combine base color with swirl mask, brightness falloff, and overall intensity
    // The original also multiplied by 'r * Vortex_BrightnessIntensity', which can make center very dark.
    // Let's use brightness_factor for the falloff and keep Vortex_BrightnessIntensity for overall strength.
    // The mask applies the swirl pattern.
    float3 color = baseColor * mask * brightness_factor * Vortex_BrightnessIntensity;
    
    // --- Blending ---
    // Alpha for blending can also incorporate the mask and brightness
    float effect_alpha = mask * brightness_factor;
    float4 effectColor = float4(color, effect_alpha);
    
    finalColor = AS_applyBlend(effectColor, finalColor, BlendMode, BlendStrength);

    return finalColor;
}

} // namespace ASVortex

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_BGX_Vortex <
    ui_label = "[AS] BGX: Vortex";
    ui_tooltip = "Creates an animated psychedelic swirling vortex pattern with radial palette mapping.\n"
                 "Original Shadertoy by LonkDong, adapted by Leon Aquitaine.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = ASVortex::PS_AS_BGX_Vortex_1;
    }
}

#endif // __AS_BGX_Vortex_1_fx