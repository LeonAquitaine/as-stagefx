/**
 * AS_VFX_ScreenRing.1.fx - Screen-space textured ring with depth occlusion
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Draws a textured ring/band on the screen at a specified screen position and depth.
 * The ring is occluded by scene geometry closer than the specified depth.
 *
 * FEATURES:
 * - Textured ring rendering in screen space.
 * - User-defined target position (Screen XY) and depth (Z).
 * - User-defined radius and thickness.
 * - Texture mapping around the ring circumference with rotation.
 * - Depth buffer occlusion.
 * - Blending modes and intensity control.
 * - Debug visualization modes.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Calculate pixel's angle and distance from the target screen position, correcting for aspect ratio.
 * 2. Apply rotation animation to the angle based on RotationSpeed and AS_timeSeconds().
 * 3. Determine if the pixel falls within the ring's radius and thickness band.
 * 4. Check depth buffer: If scene depth is closer than target depth, discard.
 * 5. Calculate texture UVs: U based on animated angle, V based on distance within the thickness band (flipped).
 * 6. Sample the ring texture.
 * 7. Apply color tint and intensity.
 * 8. Blend the result with the backbuffer using the selected blend mode and amount.
 * 
 * ===================================================================================
 */

#ifndef __AS_VFX_ScreenRing_1_fx
#define __AS_VFX_ScreenRing_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // Includes ReShadeUI.fxh, provides UI macros, helpers
#include "AS_Palette.1.fxh" // Color palette support

// ============================================================================
// TEXTURES
// ============================================================================
#ifndef RING_TEXTURE_FILENAME
#define RING_TEXTURE_FILENAME "Copyright4kH.png" // Default texture path
#endif

#ifndef RING_TEXTURE_SIZE_WIDTH
#define RING_TEXTURE_SIZE_WIDTH 1450
#endif

#ifndef RING_TEXTURE_SIZE_HEIGHT
#define RING_TEXTURE_SIZE_HEIGHT 100
#endif

#include "ReShadeUI.fxh" // Needed for texture UI element

texture ScreenRing_RingTexture < source = RING_TEXTURE_FILENAME; ui_label="Ring Texture"; ui_tooltip="Wide, short texture (e.g., 2048x60) to wrap around the ring."; > { Width=RING_TEXTURE_SIZE_WIDTH; Height=RING_TEXTURE_SIZE_HEIGHT; Format=RGBA8; };
sampler ScreenRing_RingSampler { Texture = ScreenRing_RingTexture; AddressU = WRAP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR; };

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
// Target Position Z (Depth) Range
static const float TARGET_DEPTH_MIN = 0.0; // Closest possible depth
static const float TARGET_DEPTH_MAX = 1.0; // Farthest possible depth (assuming linearized 0-1)
static const float TARGET_DEPTH_DEFAULT = 0.05; // Default relatively close

// Ring Geometry Range
static const float RING_RADIUS_MIN = 0.001; // 0.1% of screen height
static const float RING_RADIUS_MAX = 0.5;   // 50% of screen height
static const float RING_RADIUS_DEFAULT = 0.3;  // 20% of screen height

static const float RING_THICKNESS_MIN = 0.0;   // 0% of radius (invisible)
static const float RING_THICKNESS_MAX = 1.0;   // 100% of radius (filled circle)
static const float RING_THICKNESS_DEFAULT = 0.2;  // 20% of radius

// Internal Constants
static const float ROTATION_SPEED_SCALE = 0.1; // Multiplier for RotationSpeed UI value
// Use centralized epsilon from AS_Utils: AS_DEPTH_EPSILON

// ============================================================================
// EFFECT-SPECIFIC PARAMETERS
// ============================================================================

// --- Ring Appearance ---

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nOriginal work by Leon Aquitaine\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform float RingRadius < ui_type = "slider"; ui_label = "Ring Radius"; ui_tooltip = "Radius as percentage of screen height."; ui_min = RING_RADIUS_MIN; ui_max = RING_RADIUS_MAX; ui_step = 0.001; ui_category = "Ring Appearance"; > = RING_RADIUS_DEFAULT;
uniform float RingThickness < ui_type = "slider"; ui_label = "Ring Thickness"; ui_tooltip = "Thickness as percentage of Radius (0=thin, 1=filled)."; ui_min = RING_THICKNESS_MIN; ui_max = RING_THICKNESS_MAX; ui_step = 0.01; ui_category = "Ring Appearance"; > = RING_THICKNESS_DEFAULT;
uniform float4 RingColor < ui_type = "color"; ui_label = "Ring Tint & Intensity"; ui_tooltip = "RGB: Color Tint.\nA: Intensity Multiplier."; ui_category = "Ring Appearance"; > = float4(1.0, 1.0, 1.0, 1.0);

// ============================================================================
// PALETTE & STYLE
// ============================================================================
AS_PALETTE_SELECTION_UI(PalettePreset, "Palette", AS_PALETTE_RAINBOW, AS_CAT_PALETTE)
AS_DECLARE_CUSTOM_PALETTE(Ring_, AS_CAT_PALETTE)

AS_COLOR_CYCLE_UI(ColorCycleSpeed, AS_CAT_PALETTE)
uniform int CycleMode < ui_type = "combo"; ui_label = "Cycle Mode"; ui_tooltip = "How colors cycle through the palette"; ui_items = "Sweep\0Wave\0Full\0"; ui_category = AS_CAT_PALETTE; > = 0;
uniform float PaletteSaturation < ui_type = "slider"; ui_label = "Saturation"; ui_tooltip = "Palette color saturation"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = AS_CAT_PALETTE; > = 1.0;
uniform float PaletteBrightness < ui_type = "slider"; ui_label = "Brightness"; ui_tooltip = "Palette color brightness"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = AS_CAT_PALETTE; > = 1.0;
uniform int PaletteColorTarget < ui_type = "combo"; ui_label = "Target Colors"; ui_tooltip = "Which colors to replace with palette"; ui_items = "Black\0White\0All Non-transparent\0"; ui_category = AS_CAT_PALETTE; > = 1;

// ============================================================================
// ANIMATION CONTROLS
// ============================================================================
uniform float RotationSpeed < ui_type = "slider"; ui_label = "Rotation Speed"; ui_tooltip = "Speed and direction of texture rotation (-10 to +10)."; ui_min = -10.0; ui_max = 10.0; ui_step = 0.1; ui_category = AS_CAT_ANIMATION; > = -2.0;

// ============================================================================
// AUDIO REACTIVITY (Example Setup)
// ============================================================================
AS_AUDIO_UI(Ring_AudioSource, "Audio Source", AS_AUDIO_BEAT, AS_CAT_AUDIO) // Removed extra 'true' argument
AS_AUDIO_MULT_UI(Ring_AudioMultiplier, "Intensity", 0.1, 2.0, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(AudioTarget, "None\0Radius\0Thickness\0Color Intensity\0", 1)

// ============================================================================
// STAGE CONTROLS
// ============================================================================
uniform float TargetDepth < ui_type = "slider"; ui_label = "Target Depth"; ui_tooltip = "Depth in scene (0=Near, 1=Far)."; ui_min = TARGET_DEPTH_MIN; ui_max = TARGET_DEPTH_MAX; ui_step = 0.001; ui_category = AS_CAT_STAGE; > = TARGET_DEPTH_DEFAULT;
AS_ROTATION_UI(SnapRotation, FineRotation) // Add standard rotation controls

// ============================================================================
// POSITION CONTROLS
// ============================================================================
// Use centered coordinate system (-1.5 to 1.5 range, [-1,1] maps to central square)
uniform float2 TargetScreenXY < ui_type = "drag"; ui_label = "Position"; ui_tooltip = "Screen position (-1.5 to 1.5 range, 0,0 is center, [-1,1] maps to central square)."; ui_min = -1.5; ui_max = 1.5; ui_step = 0.001; ui_category = AS_CAT_STAGE; > = float2(0.0, 0.0);

// ============================================================================
// FINAL MIX
// ============================================================================
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// ============================================================================
// DEBUG
// ============================================================================
AS_DEBUG_UI("Normal\0Screen Distance\0Angle\0Texture UVs\0Depth Check\0Ring Alpha\0") // Removed extra 'true' argument

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================
// Get color from the currently selected palette
float3 getScreenRingPaletteColor(float t, float timer) {
    float cycleRate = ColorCycleSpeed * 0.1;
    
    if (ColorCycleSpeed != 0.0) {
        // Apply the appropriate cycling mode
        if (CycleMode == 0) { 
            // Sweep mode (the original mode) - colors cycle 1→2→3→4→5→1→...
            t = frac(t + cycleRate * timer);
        }        else if (CycleMode == 1) {
            // Wave mode - colors cycle 1→2→3→4→5→4→3→2→1→...
            float cyclePos = frac(cycleRate * timer * AS_HALF); // Half speed for ping-pong
            // Convert cyclePos to ping-pong pattern between 0-1
            cyclePos = cyclePos < AS_HALF ? cyclePos * 2.0 : 2.0 - cyclePos * 2.0;
            t = lerp(t, cyclePos, saturate(abs(cycleRate) * 2.0)); // Blend toward current cycle position
        }
        else if (CycleMode == 2) {
            // Full mode - all mapped points change to the same color
            float cyclePos = frac(cycleRate * timer);
            t = cyclePos; // Override t completely with current cycle position
        }
    }
      t = saturate(t); // Ensure t is within valid range [0, 1]
    
    return AS_GET_PALETTE_COLOR(Ring_, PalettePreset, t);
}

// ============================================================================
// MAIN PIXEL SHADER
// ============================================================================
float4 PS_ScreenRing(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // --- Initial Setup ---
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    float aspectRatio = ReShade::AspectRatio;
    float timer = AS_timeSeconds();

    // --- Get Target Info & Apply Audio Reactivity ---
    float radiusInput = RingRadius;
    float thicknessInput = RingThickness;
    float4 ringColorInput = RingColor;

    if (AudioTarget > 0) {        float audioLevel = AS_audioLevelFromSource(Ring_AudioSource);
        float multiplier = Ring_AudioMultiplier;
        float audioFactor = (1.0 + audioLevel * multiplier);

        if      (AudioTarget == 1) radiusInput *= audioFactor;
        else if (AudioTarget == 2) thicknessInput = saturate(thicknessInput * audioFactor); // Clamp thickness
        else if (AudioTarget == 3) ringColorInput.a *= audioFactor; // Modify intensity (alpha channel)
        radiusInput = max(radiusInput, RING_RADIUS_MIN);
    }

    // --- Get Stage/Position Info ---
    float targetDepthZ = TargetDepth;
    // UI Position [-1.5, 1.5] -> effect_screen_coords [-0.75, 0.75]
    float2 effect_screen_coords = TargetScreenXY * 0.5;
    float globalRotation = AS_getRotationRadians(SnapRotation, FineRotation); // Get rotation angle

    // --- Calculate Screen Geometry (Following AS Standards) ---
    // 1-2. Center and apply aspect ratio correction using shared helper
    float2 aspect_corrected_uv = AS_centeredUVWithAspect(texcoord, aspectRatio);

    // 3. Apply inverse global rotation to aspect_corrected_uv
    float sinRot = sin(-globalRotation);
    float cosRot = cos(-globalRotation);
    float2 rotated_uv;
    rotated_uv.x = aspect_corrected_uv.x * cosRot - aspect_corrected_uv.y * sinRot;
    rotated_uv.y = aspect_corrected_uv.x * sinRot + aspect_corrected_uv.y * cosRot;

    // 4. Calculate difference vector relative to the target position in the rotated, aspect-corrected space
    float2 diff = rotated_uv - effect_screen_coords;

    // 5. Calculate distance and base angle using the difference vector
    // Distance is now normalized relative to screen height
    float screenDistNorm = length(diff);
    // Angle is relative to the target position in the rotated, aspect-corrected space
    float baseAngle = atan2(diff.y, diff.x);

    // --- Apply Animation ---
    float rotationOffset = timer * (-RotationSpeed) * ROTATION_SPEED_SCALE; // Use constant
    float angle = baseAngle + rotationOffset;

    // --- Apply Radius/Thickness ---
    float radiusNorm = radiusInput;
    float thicknessNorm = radiusNorm * saturate(thicknessInput);

    float effectiveRadiusNorm = max(AS_MIN_NORM, radiusNorm);
    float effectiveThicknessNorm = max(AS_MIN_NORM, thicknessNorm);

    // --- Check if Pixel is on the Ring ---
    float distDelta = abs(screenDistNorm - effectiveRadiusNorm);
    float halfThicknessNorm = effectiveThicknessNorm * 0.5;

    float aa = ReShade::PixelSize.y;

    float ringFactor = AS_smoothEdge(distDelta, halfThicknessNorm, aa);

    float4 finalResult = orig;

    if (ringFactor > 0.0)
    {
        // Check depth using targetDepthZ (from TargetDepth uniform)
    bool visible = targetDepthZ <= sceneDepth + AS_DEPTH_EPSILON_SMALL;

        if (visible)
        {
            // --- Texture Mapping ---
            // Use the calculated angle and screenDistNorm
            float texU = frac(angle / AS_TWO_PI + 0.5);
            float texV = 1.0 - saturate(0.5 + (screenDistNorm - effectiveRadiusNorm) / (effectiveThicknessNorm + AS_DEPTH_EPSILON_SMALL));

            float4 texColor = tex2D(ScreenRing_RingSampler, float2(texU, texV));
            
            // Skip processing for fully transparent pixels in the texture
            if (texColor.a > 0.0)
            {
                float3 ringColor = texColor.rgb * ringColorInput.rgb * ringColorInput.a;
                
                // Apply palette colors if enabled
                // Get the palette color based on the texture coordinate
                // Use U coordinate (angle) as a good parameter for palette interpolation
                float3 paletteColor = getScreenRingPaletteColor(texU, timer);
                
                // Apply saturation and brightness adjustments
                paletteColor = AS_adjustSaturation(paletteColor, PaletteSaturation) * PaletteBrightness;
                
                // Apply palette based on target mode
                if (PaletteColorTarget == 0) { // Black
                    float blackness = 1.0 - max(max(texColor.r, texColor.g), texColor.b);
                    ringColor = lerp(ringColor, paletteColor * ringColorInput.a, blackness);
                }
                else if (PaletteColorTarget == 1) { // White
                    float whiteness = min(min(texColor.r, texColor.g), texColor.b);
                    ringColor = lerp(ringColor, paletteColor * ringColorInput.a, whiteness);
                }
                else if (PaletteColorTarget == 2) { // All Non-transparent
                    ringColor = paletteColor * ringColorInput.a;
                }

                // Incorporate the texture's alpha channel into the final alpha calculation
                float finalAlpha = ringFactor * texColor.a * BlendAmount;

                finalResult = AS_compositeRGBA(ringColor, orig, BlendMode, finalAlpha);
            }
        }
    }

    if (DebugMode > 0) {
        // Recalculate values using the new method for debug views
        float2 effect_screen_coords = TargetScreenXY * 0.5;
        float globalRotation = AS_getRotationRadians(SnapRotation, FineRotation);
    float2 aspect_corrected_uv = AS_centeredUVWithAspect(texcoord, aspectRatio);
        float sinRot = sin(-globalRotation);
        float cosRot = cos(-globalRotation);
        float2 rotated_uv;
        rotated_uv.x = aspect_corrected_uv.x * cosRot - aspect_corrected_uv.y * sinRot;
        rotated_uv.y = aspect_corrected_uv.x * sinRot + aspect_corrected_uv.y * cosRot;
        float2 diff = rotated_uv - effect_screen_coords;

        if (DebugMode == 1) { // Screen Distance
             float screenDistNorm = length(diff);
             return float4(screenDistNorm.xxx * 2.0, 1.0); // Scale for visibility
        }
        if (DebugMode == 2) { // Angle
             float baseAngle = atan2(diff.y, diff.x);
             float rotationOffset = timer * (-RotationSpeed) * ROTATION_SPEED_SCALE;
             float angle = baseAngle + rotationOffset;
             return float4(frac(angle/AS_TWO_PI + 0.5).xxx, 1.0);
        }
        if (DebugMode == 3) { // Texture UVs
             float screenDistNorm = length(diff);
             float baseAngle = atan2(diff.y, diff.x);
             float rotationOffset = timer * (-RotationSpeed) * ROTATION_SPEED_SCALE;
             float angle = baseAngle + rotationOffset;
             float texU = frac(angle / AS_TWO_PI + 0.5);

             // Recalculate effective radius/thickness based on inputs
             float radiusNorm = radiusInput;
             float thicknessNorm = radiusNorm * saturate(thicknessInput);
             float effectiveRadiusNorm = max(AS_MIN_NORM, radiusNorm);
             float effectiveThicknessNorm = max(AS_MIN_NORM, thicknessNorm);

             float texV = 1.0 - saturate(0.5 + (screenDistNorm - effectiveRadiusNorm) / (effectiveThicknessNorm + AS_DEPTH_EPSILON_SMALL));
             return float4(texU, texV, 0.0, 1.0);
        }
        if (DebugMode == 4) {
             // Check depth using targetDepthZ (from TargetDepth uniform)
             bool visible = targetDepthZ <= sceneDepth + AS_DEPTH_EPSILON_SMALL;
             float debugVal = visible ? 1.0 : 0.0;
             return float4(debugVal, debugVal, debugVal, 1.0);
        }
         if (DebugMode == 5) {
             float finalAlpha = ringFactor * BlendAmount;
             return float4(finalAlpha.xxx, 1.0);
         }
    }

    return finalResult;
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_VFX_ScreenRing < 
    ui_label = "[AS] VFX: Screen Ring"; 
    ui_tooltip = "Draws a textured ring in screen space with depth occlusion and artistic controls."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_ScreenRing;
    }
}

#endif // __AS_VFX_ScreenRing_1_fx
