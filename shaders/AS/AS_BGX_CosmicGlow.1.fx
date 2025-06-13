/**
 * AS_BGX_CosmicGlow.1.fx - Abstract radiating arc background
 * Author: Leon Aquitaine | License: CC BY 4.0
 *
 * CREDITS:
 * Based on "Cosmic" by XorDev
 * Source: https://www.shadertoy.com/view/ls3XW8
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Renders an abstract, glowing background effect composed of hundreds of animated,
 * rotating arcs arranged in concentric rings. The effect has a distinct perspective
 * quality, giving it a sense of depth and motion.
 *
 * FEATURES:
 * - Animated, rotating arcs with customizable density and count.
 * - True perspective distortion with axis inclination for realistic 3D viewing angles.
 * - Two coloring modes: original mathematical formula or standard AS-StageFX palettes.
 * - Ping-pong palette interpolation to eliminate hard color breaks.
 * - Audio reactivity targeting Ring Brightness and Arc Intensity for dynamic effects.
 * - Full integration with AS-StageFX controls for animation, positioning, depth, and blending.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. A for-loop iterates to create a specified number of concentric rings.
 * 2. Inside the loop, the pixel's angle is calculated to form rotating arcs.
 * 3. A non-linear distance calculation creates the ring shapes and adds a
 * tunable perspective effect.
 * 4. Color is accumulated for each ring and arc, then blended with the scene.
 * 5. All transformations and calculations are resolution-independent.
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD
// ============================================================================
#ifndef __AS_BGX_CosmicGlow_1_fx
#define __AS_BGX_CosmicGlow_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Constants ---
static const int    RING_COUNT_MIN = 1;
static const int    RING_COUNT_MAX = 200;
static const int    RING_COUNT_DEFAULT = 30;
static const float  PERSPECTIVE_MIN = -2.0;
static const float  PERSPECTIVE_MAX = 5.0;
static const float  PERSPECTIVE_DEFAULT = -0.9;
static const float  RING_DENSITY_MIN = 1.0;
static const float  RING_DENSITY_MAX = 200.0;
static const float  RING_DENSITY_DEFAULT = 80.0;
static const float  RING_FALLOFF_MIN = 0.01;
static const float  RING_FALLOFF_MAX = 2.0;
static const float  RING_FALLOFF_DEFAULT = 1.0;
static const float  RING_BRIGHTNESS_MIN = 0.0;
static const float  RING_BRIGHTNESS_MAX = 1.0;
static const float  RING_BRIGHTNESS_DEFAULT = 0.2;
static const float  ARC_COUNT_MULT_MIN = 0.0;
static const float  ARC_COUNT_MULT_MAX = 2.0;
static const float  ARC_COUNT_MULT_DEFAULT = 0.1;
static const float  ARC_INTENSITY_MIN = 0.0;
static const float  ARC_INTENSITY_MAX = 1.0;
static const float  ARC_INTENSITY_DEFAULT = 0.6;
static const float  COLOR_PHASE_MIN = 0.0;
static const float  COLOR_PHASE_MAX = 5.0;
static const float  COLOR_PHASE_DEFAULT = 1.0;
static const float  PALETTE_CYCLE_COUNT_MIN = 0.1;
static const float  PALETTE_CYCLE_COUNT_MAX = 10.0;
static const float  PALETTE_CYCLE_COUNT_DEFAULT = 1.0;


// --- UI Uniforms ---
// Position & Transformation
AS_POS_UI(EffectCenter)
AS_SCALE_UI(EffectScale)

// Palette & Style
uniform bool UsePaletteColoring < ui_label = "Use Palette Coloring"; ui_tooltip = "If checked, uses the selected palette below. If unchecked, uses the original shader's mathematical coloring."; ui_category = "Palette & Style"; > = false;
AS_PALETTE_SELECTION_UI(PaletteSelection, "Effect Palette", AS_PALETTE_CUSTOM, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(CosmicGlow_, "Palette & Style")
uniform float PaletteCycleCount < ui_type = "slider"; ui_label = "Palette Cycle Count"; ui_tooltip = "Controls how many times the color gradient cycles back and forth (ping-pongs) per rotation."; ui_min = PALETTE_CYCLE_COUNT_MIN; ui_max = PALETTE_CYCLE_COUNT_MAX; ui_category = "Palette & Style"; > = PALETTE_CYCLE_COUNT_DEFAULT;
uniform float ColorPhase < ui_type = "slider"; ui_label = "Color Phase (Math Mode)"; ui_tooltip = "Adjusts the color separation when 'Use Palette Coloring' is off."; ui_min = COLOR_PHASE_MIN; ui_max = COLOR_PHASE_MAX; ui_category = "Palette & Style"; > = COLOR_PHASE_DEFAULT;

// Pattern
uniform int RingCount < ui_type = "slider"; ui_label = "Ring Count"; ui_tooltip = "Number of concentric rings to render."; ui_min = RING_COUNT_MIN; ui_max = RING_COUNT_MAX; ui_category = "Pattern"; > = RING_COUNT_DEFAULT;
uniform float Perspective < ui_type = "slider"; ui_label = "Perspective"; ui_tooltip = "Controls viewing angle inclination. 0 = flat view (no distortion), higher values create 3D perspective as if viewing rings from an angled position."; ui_min = PERSPECTIVE_MIN; ui_max = PERSPECTIVE_MAX; ui_category = "Pattern"; > = PERSPECTIVE_DEFAULT;
uniform float RingDensity < ui_type = "slider"; ui_label = "Ring Density"; ui_tooltip = "Controls the spacing and density of the rings."; ui_min = RING_DENSITY_MIN; ui_max = RING_DENSITY_MAX; ui_category = "Pattern"; > = RING_DENSITY_DEFAULT;
uniform float RingFalloff < ui_type = "slider"; ui_label = "Ring Falloff"; ui_tooltip = "Adjusts the sharpness of the rings. Lower values are sharper."; ui_min = RING_FALLOFF_MIN; ui_max = RING_FALLOFF_MAX; ui_category = "Pattern"; > = RING_FALLOFF_DEFAULT;
uniform float RingBrightness < ui_type = "slider"; ui_label = "Ring Brightness"; ui_tooltip = "Overall brightness of the effect."; ui_min = RING_BRIGHTNESS_MIN; ui_max = RING_BRIGHTNESS_MAX; ui_category = "Pattern"; > = RING_BRIGHTNESS_DEFAULT;
uniform float ArcCountMultiplier < ui_type = "slider"; ui_label = "Arc Count Multiplier"; ui_tooltip = "Controls how many arcs appear on each ring."; ui_min = ARC_COUNT_MULT_MIN; ui_max = ARC_COUNT_MULT_MAX; ui_step = 0.01; ui_category = "Pattern"; > = ARC_COUNT_MULT_DEFAULT;
uniform float ArcIntensity < ui_type = "slider"; ui_label = "Arc Intensity"; ui_tooltip = "Controls the visibility of the arcs."; ui_min = ARC_INTENSITY_MIN; ui_max = ARC_INTENSITY_MAX; ui_category = "Pattern"; > = ARC_INTENSITY_DEFAULT;

// Animation
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")

// Audio Reactivity
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULT_UI(AudioMultiplier, "Audio Intensity", 1.0, 4.0, "Audio Reactivity")
uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target"; ui_items = "Ring Brightness\0Arc Intensity\0"; ui_category = "Audio Reactivity"; > = 0;

// Stage Controls
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(SnapRotation, FineRotation)

// Final Mix
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_LIGHTEN)
AS_BLENDAMOUNT_UI(BlendAmount)

// Debug
AS_DEBUG_UI("Off\0Transformed UV\0")

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_CosmicGlow(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);

    // --- Standard Setup ---
    if (ReShade::GetLinearizedDepth(texcoord) < EffectDepth - AS_DEPTH_EPSILON)
        return orig;

    float animSpeed = AnimationSpeed;
    float ringBrightness = RingBrightness;
    float arcIntensity = ArcIntensity;

    if(AudioSource != AS_AUDIO_OFF)
    {
        float audioValue = AS_applyAudioReactivity(1.0, AudioSource, AudioMultiplier, true) - 1.0;
        if(AudioTarget == 0) ringBrightness += audioValue;
        if(AudioTarget == 1) arcIntensity += audioValue;
    }
    float time = AS_getAnimationTime(animSpeed, AnimationKeyframe);

    // --- Apply Stage Controls (Position, Scale, Rotation) ---
    float2 stageCoord = texcoord;
    
    stageCoord -= EffectCenter;
    
    stageCoord = (stageCoord - 0.5) / EffectScale + 0.5;

    float globalRotation = AS_getRotationRadians(SnapRotation, FineRotation);
    if (globalRotation != 0.0) {
        float s, c;
        sincos(-globalRotation, s, c);
        float2 rotCenter = stageCoord - 0.5;
        stageCoord = float2(rotCenter.x * c - rotCenter.y * s, rotCenter.x * s + rotCenter.y * c) + 0.5;
    }

    // --- Effect Coordinate System ---
    float2 p = stageCoord - 0.5;
    if (ReShade::AspectRatio > 1.0)
        p.x *= ReShade::AspectRatio;
    else
        p.y /= ReShade::AspectRatio;

    float perspectiveStrength = Perspective * 0.5;
    float perspectiveDivisor = 1.0 + p.y * perspectiveStrength;
    perspectiveDivisor = max(perspectiveDivisor, 0.1);
    p.x /= perspectiveDivisor;
    p.y = (p.y - perspectiveStrength) / perspectiveDivisor;

    p = p * float2x2(1, -1, 2, 2);

    // --- Main Effect Loop ---
    float3 finalColor = 0.0;
    for (float i = 1.0; i < RingCount; i += 1.0)
    {
        float2 uv_loop = p / (2.0 - p.y);
        
        float angle = atan2(uv_loop.y, uv_loop.x) * ceil(i * ArcCountMultiplier) + time * sin(i * i) + i * i;
        
        float ring_attenuation = ringBrightness / (abs(length(uv_loop) * RingDensity - i) + (RingFalloff / BUFFER_HEIGHT));
        
        float arc_mask = clamp(cos(angle), 0.0, arcIntensity);

        // --- Coloring ---
        float3 effectColor;
        if (UsePaletteColoring)
        {
            // Use a continuous triangle wave for smooth, multi-cycle ping-pong interpolation.
            float normalizedAngle = frac(angle / AS_TWO_PI);
            
            // Generate a continuous phase for the triangle wave
            float phase = normalizedAngle * PaletteCycleCount * AS_TWO_PI;
            
            // The acos(cos(x)) pattern creates a smooth triangle wave from 0 -> PI -> 0...
            // We normalize it by AS_PI to get a 0 -> 1 -> 0... range for the palette.
            float paletteValue = acos(cos(phase)) / AS_PI;
            
            if (PaletteSelection == AS_PALETTE_CUSTOM)
            {
                effectColor = AS_GET_INTERPOLATED_CUSTOM_COLOR(CosmicGlow_, paletteValue);
            }
            else
            {
                effectColor = AS_getInterpolatedColor(PaletteSelection, paletteValue);
            }
        }
        else // Original mathematical coloring
        {
            effectColor = (cos(angle - i + float3(0.0, ColorPhase, ColorPhase * 2.0)) + 1.0);
        }

        finalColor += ring_attenuation * arc_mask * effectColor;
    }
    
    // --- Debug View ---
    if (DebugMode == 1) return float4(stageCoord, 0.0, 1.0);

    // --- Final Blending ---
    return AS_applyBlend(float4(finalColor, 1.0), orig, BlendMode, BlendAmount);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_CosmicGlow <
    ui_tooltip = "Renders an abstract, glowing background effect composed of hundreds of animated, "
                 "rotating arcs arranged in concentric rings.\n\n"
                 "Credits:\n"
                 "Based on 'Cosmic' by XorDev\n"
                 "Source: https://www.shadertoy.com/view/ls3XW8\n"
                 "Adapted by Leon Aquitaine"; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CosmicGlow;
    }
}

#endif // __AS_BGX_CosmicGlow_1_fx