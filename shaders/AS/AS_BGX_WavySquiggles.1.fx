/**
 * AS_BGX_WavySquiggles.1.fx - Wavy Squiggles Background
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Based on "Interactive 2.5D Squiggles" by SnoopethDuckDuck
 * Shadertoy: https://www.shadertoy.com/view/7sBfDD
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a mesmerizing pattern of adaptive wavy lines that follow the mouse or fixed position.
 * The lines create intricate patterns that look like dynamic squiggly lines arranged around
 * a central point, with rotation applied based on direction.
 *
 * FEATURES:
 * - Position-reactive wavy line patterns
 * - Customizable line parameters (rotation influence, thickness, distance, smoothness)
 * - Optional color palettes with control over hue, saturation, and value
 * - Pattern displacement for off-center effects
 * - Audio reactivity with multiple target parameters
 * - Depth-aware rendering
 * - Adjustable rotation
 * - Standard position, scale, and blending options
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Calculates vector direction from center position to current pixel
 * 2. Applies optional displacement for off-center effects
 * 3. Uses angle and distance to create rotation patterns
 * 4. Generates fractal-like wave patterns using fractional coordinates
 * 5. Controls line appearance with adjustable smoothness from hard edges to gradients
 * 6. Applies standard AS palette system for coloring
 * 
 * ===================================================================================
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_WavySquiggles_1_fx
#define __AS_BGX_WavySquiggles_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"     
#include "AS_Palette.1.fxh"  

namespace ASWavySquiggles {

// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================

// --- Pattern Parameters ---
static const float ROTATION_INFLUENCE_MIN = -2.0;
static const float ROTATION_INFLUENCE_MAX = 2.0;
static const float ROTATION_INFLUENCE_STEP = 0.1;
static const float ROTATION_INFLUENCE_DEFAULT = 1.0;

static const float LINE_DISTANCE_MIN = 0.0;
static const float LINE_DISTANCE_MAX = 1.0;
static const float LINE_DISTANCE_STEP = 0.01;
static const float LINE_DISTANCE_DEFAULT = 0.3;

static const float LINE_THICKNESS_MIN = 0.001;
static const float LINE_THICKNESS_MAX = 0.2;
static const float LINE_THICKNESS_STEP = 0.001;
static const float LINE_THICKNESS_DEFAULT = 0.02;

static const float LINE_SMOOTHING_MIN = 0.0;
static const float LINE_SMOOTHING_MAX = 1.0;
static const float LINE_SMOOTHING_STEP = 0.01;
static const float LINE_SMOOTHING_DEFAULT = 0.0;

static const float PATTERN_ITERATIONS_MIN = 1;
static const float PATTERN_ITERATIONS_MAX = 40;
static const float PATTERN_ITERATIONS_STEP = 1;
static const float PATTERN_ITERATIONS_DEFAULT = 20;

// --- Displacement ---
static const float DISPLACEMENT_ANGLE_MIN = 0.0;
static const float DISPLACEMENT_ANGLE_MAX = 360.0;
static const float DISPLACEMENT_ANGLE_STEP = 1.0;
static const float DISPLACEMENT_ANGLE_DEFAULT = 0.0;

static const float DISPLACEMENT_STRENGTH_MIN = 0.0;
static const float DISPLACEMENT_STRENGTH_MAX = 1.0;
static const float DISPLACEMENT_STRENGTH_STEP = 0.01;
static const float DISPLACEMENT_STRENGTH_DEFAULT = 0.0;

// --- Animation ---
static const float ANIMATION_SPEED_MIN = 0.0;
static const float ANIMATION_SPEED_MAX = 5.0;
static const float ANIMATION_SPEED_STEP = 0.01;
static const float ANIMATION_SPEED_DEFAULT = 1.0;

static const float ANIMATION_KEYFRAME_MIN = 0.0;
static const float ANIMATION_KEYFRAME_MAX = 100.0;
static const float ANIMATION_KEYFRAME_STEP = 0.1;
static const float ANIMATION_KEYFRAME_DEFAULT = 0.0;

// --- Audio ---
static const int AUDIO_TARGET_DEFAULT = 0;
static const float AUDIO_MULTIPLIER_DEFAULT = 1.0;
static const float AUDIO_MULTIPLIER_MAX = 2.0;

// --- Palette & Style ---
static const float ORIG_COLOR_INTENSITY_DEFAULT = 1.0;
static const float ORIG_COLOR_INTENSITY_MAX = 3.0;
static const float ORIG_COLOR_SATURATION_DEFAULT = 1.0;
static const float ORIG_COLOR_SATURATION_MAX = 2.0;
static const float COLOR_CYCLE_SPEED_DEFAULT = 0.1;
static const float COLOR_CYCLE_SPEED_MAX = 2.0;

// --- Internal Constants ---
static const float ATTENUATION_FACTOR = 0.865; // Line intensity attenuation per iteration
static const float INTENSITY_SCALE = 0.1;      // Scale for final intensity
static const float INTENSITY_BASE = 0.72;      // Base intensity offset
static const float DISTANCE_DAMPEN = 0.23;     // Distance-based damping factor
static const float DISTANCE_POWER = 0.25;      // Power for distance effect
static const float DEFAULT_KERNEL_WIDTH = 6.0; // Default smoothstep kernel width scalar
static const float SMOOTH_GRADIENT_SCALE = 1.0; // Scaling factor for smooth gradient transitions

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Pattern Parameters ---











uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nBased on 'Interactive 2.5D Squiggles' by SnoopethDuckDuck\nLink: https://www.shadertoy.com/view/7sBfDD\nLicence: CC Share-Alike Non-Commercial\n\n";>;

uniform float RotationInfluence < ui_type = "slider"; ui_label = "Rotation Influence"; ui_tooltip = "Controls how angle affects the pattern rotation."; ui_min = ROTATION_INFLUENCE_MIN; ui_max = ROTATION_INFLUENCE_MAX; ui_step = ROTATION_INFLUENCE_STEP; ui_category = "Pattern"; > = ROTATION_INFLUENCE_DEFAULT;
uniform float LineTargetDistance < ui_type = "slider"; ui_label = "Target Distance"; ui_tooltip = "Distance at which lines will form patterns."; ui_min = LINE_DISTANCE_MIN; ui_max = LINE_DISTANCE_MAX; ui_step = LINE_DISTANCE_STEP; ui_category = "Pattern"; > = LINE_DISTANCE_DEFAULT;
uniform float LineThickness < ui_type = "slider"; ui_label = "Line Thickness"; ui_tooltip = "Controls the thickness of the pattern lines."; ui_min = LINE_THICKNESS_MIN; ui_max = LINE_THICKNESS_MAX; ui_step = LINE_THICKNESS_STEP; ui_category = "Pattern"; > = LINE_THICKNESS_DEFAULT;
uniform float LineSmoothing < ui_type = "slider"; ui_label = "Line Smoothing"; ui_tooltip = "Controls how smooth the pattern lines appear. 0 = hard edges, 1 = fully blended gradients."; ui_min = LINE_SMOOTHING_MIN; ui_max = LINE_SMOOTHING_MAX; ui_step = LINE_SMOOTHING_STEP; ui_category = "Pattern"; > = LINE_SMOOTHING_DEFAULT;
uniform int PatternIterations < ui_type = "slider"; ui_label = "Pattern Iterations"; ui_tooltip = "Number of pattern iterations. Higher values create more intricate patterns."; ui_min = PATTERN_ITERATIONS_MIN; ui_max = PATTERN_ITERATIONS_MAX; ui_step = PATTERN_ITERATIONS_STEP; ui_category = "Pattern"; > = PATTERN_ITERATIONS_DEFAULT;

// --- Displacement ---
uniform float DisplacementAngle < ui_type = "slider"; ui_label = "Displacement Angle"; ui_tooltip = "Angle in degrees for displacement from pattern center."; ui_min = DISPLACEMENT_ANGLE_MIN; ui_max = DISPLACEMENT_ANGLE_MAX; ui_step = DISPLACEMENT_ANGLE_STEP; ui_category = "Displacement"; > = DISPLACEMENT_ANGLE_DEFAULT;
uniform float DisplacementStrength < ui_type = "slider"; ui_label = "Displacement Strength"; ui_tooltip = "How far from center the pattern is displaced."; ui_min = DISPLACEMENT_STRENGTH_MIN; ui_max = DISPLACEMENT_STRENGTH_MAX; ui_step = DISPLACEMENT_STRENGTH_STEP; ui_category = "Displacement"; > = DISPLACEMENT_STRENGTH_DEFAULT;

// --- Palette & Style ---
uniform bool UseOriginalColors < ui_label = "Use Original Math Colors"; ui_tooltip = "When enabled, uses the mathematically calculated RGB colors instead of palettes."; ui_category = "Palette & Style"; > = true;
uniform float OriginalColorIntensity < ui_type = "slider"; ui_label = "Original Color Intensity"; ui_tooltip = "Adjusts the intensity of original colors when enabled."; ui_min = 0.1; ui_max = ORIG_COLOR_INTENSITY_MAX; ui_step = 0.01; ui_category = "Palette & Style"; ui_spacing = 0; > = ORIG_COLOR_INTENSITY_DEFAULT;
uniform float OriginalColorSaturation < ui_type = "slider"; ui_label = "Original Color Saturation"; ui_tooltip = "Adjusts the saturation of original colors when enabled."; ui_min = 0.0; ui_max = ORIG_COLOR_SATURATION_MAX; ui_step = 0.01; ui_category = "Palette & Style"; > = ORIG_COLOR_SATURATION_DEFAULT;
AS_PALETTE_SELECTION_UI(PalettePreset, "Color Palette", AS_PALETTE_NEON, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(WavySquiggles_, "Palette & Style")
uniform float ColorCycleSpeed < ui_type = "slider"; ui_label = "Color Cycle Speed"; ui_tooltip = "Controls how fast palette colors cycle. 0 = static."; ui_min = -COLOR_CYCLE_SPEED_MAX; ui_max = COLOR_CYCLE_SPEED_MAX; ui_step = 0.1; ui_category = "Palette & Style"; > = COLOR_CYCLE_SPEED_DEFAULT;

// --- Animation ---
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")

// --- Audio Reactivity ---
AS_AUDIO_UI(WavySquiggles_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(WavySquiggles_AudioMultiplier, "Audio Intensity", AUDIO_MULTIPLIER_DEFAULT, AUDIO_MULTIPLIER_MAX, "Audio Reactivity")
uniform int WavySquiggles_AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter"; ui_items = "None\0Animation Speed\0Rotation Influence\0Line Distance\0Line Thickness\0Line Smoothing\0Displacement Strength\0"; ui_category = "Audio Reactivity"; > = AUDIO_TARGET_DEFAULT;

// --- Stage/Position ---
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation)
AS_POSITION_SCALE_UI(Position, Scale)

// --- Final Mix ---
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

// --- Debug ---
AS_DEBUG_UI("Off\0Show Audio Reactivity\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Standard 2D rotation matrix, assuming pre-multiplication with a column vector
float2x2 Rot(float a) {
    float c = cos(a), s = sin(a);
    return float2x2(c, -s, s, c); // [row0: c, -s] [row1: s, c]
}

// Get color from the currently selected palette
float3 getWavySquigglesColor(float t, float time) {
    if (ColorCycleSpeed != 0.0) {
        float cycleRate = ColorCycleSpeed * 0.1;
        t = frac(t + cycleRate * time);
    }    t = saturate(t); 
    
    if (PalettePreset == AS_PALETTE_CUSTOM) { // Use custom palette
        return AS_GET_INTERPOLATED_CUSTOM_COLOR(WavySquiggles_, t);    }
    return AS_getInterpolatedColor(PalettePreset, t); // Use preset palette
}

// Original color function from the SnoopethDuckDuck Shadertoy shader
// Source: https://www.shadertoy.com/view/7sBfDD "Interactive 2.5D Squiggles"
float3 pal(float t, float3 a, float3 b, float3 c, float3 d) {
    return a + b * cos(AS_TWO_PI * (c * t + d));
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 WavySquigglesPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD) : SV_TARGET {
    // Get original pixel color and depth
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);

    // Apply depth test
    if (depth < EffectDepth) {
        return originalColor;
    }    // Apply audio reactivity to selected parameters
    float animSpeed = AnimationSpeed;
    float rotationInf = RotationInfluence;
    float lineDistance = LineTargetDistance;
    float lineThick = LineThickness;
    float lineSmooth = LineSmoothing;
    float dispStrength = DisplacementStrength;
    
    float audioReactivity = AS_applyAudioReactivity(1.0, WavySquiggles_AudioSource, WavySquiggles_AudioMultiplier, true);
    
    // Map audio target combo index to parameter adjustment
    if (WavySquiggles_AudioTarget == 1) animSpeed *= audioReactivity;
    else if (WavySquiggles_AudioTarget == 2) rotationInf *= audioReactivity;
    else if (WavySquiggles_AudioTarget == 3) lineDistance *= audioReactivity;
    else if (WavySquiggles_AudioTarget == 4) lineThick *= audioReactivity;
    else if (WavySquiggles_AudioTarget == 5) lineSmooth *= audioReactivity;
    else if (WavySquiggles_AudioTarget == 6) dispStrength *= audioReactivity;

    // Calculate animation time with the standardized helper function
    float time = AS_getAnimationTime(animSpeed, AnimationKeyframe);

    // Get rotation in radians from snap and fine controls
    float rotationRadians = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
    
    // --- POSITION HANDLING ---
    // Step 1: Center and correct for aspect ratio
    float2 p_centered = (texcoord - AS_HALF) * 2.0;          // Center coordinates (-1 to 1)
    p_centered.x *= ReShade::AspectRatio;                // Correct for aspect ratio
    
    // Step 2: Apply rotation around center FIRST (negative rotation for clockwise)
    float sinRot, cosRot;
    sincos(-rotationRadians, sinRot, cosRot); // Negative sign for clockwise rotation
    float2 p_rotated = float2(
        p_centered.x * cosRot - p_centered.y * sinRot,
        p_centered.x * sinRot + p_centered.y * cosRot
    );
      // Step 3: Apply position and scale AFTER rotation
    float2 uv = p_rotated / Scale - Position;
    
    // Calculate displacement vector based on angle and strength
    float2 displacementVector = float2(0.0, 0.0);
    if (dispStrength > 0.0) {
        float displacementRadians = radians(DisplacementAngle);
        displacementVector.x = cos(displacementRadians) * dispStrength;
        displacementVector.y = sin(displacementRadians) * dispStrength;
    }
    
    // Apply displacement to create an off-center effect
    float2 patternCenter = displacementVector;
    
    // Calculate vector from pattern center to current pixel
    float2 dir = uv - patternCenter;
    
    // Calculate angle of this vector
    float a = atan2(dir.x, dir.y);
    
    // Initialize accumulator for line intensity
    float s = 0.0;
    
    // Get pattern iterations from UI
    float n = (float)PatternIterations;
    
    // Kernel width for smoothstep, related to pixel size
    float k = DEFAULT_KERNEL_WIDTH / BUFFER_SCREEN_SIZE.y;  
    
    // Generate pattern
    for (float i = n; i > 0.; i--) {
        // Calculate angle offset for this iteration, modulated by rotation influence
        float io = rotationInf * AS_TWO_PI * i / n;        // Calculate scaling factor for this iteration
        float sc = -4.0 - 0.5 * i + 0.9 * cos(io - 9.0 * length(dir) + time);
        
        // Calculate pattern coordinates, centered
        float2 fpos = frac(sc * uv + 0.5 * i * patternCenter) - 0.5;
        
        // Apply rotation based on angle of direction vector
        fpos = mul(Rot(a), fpos);
        
        // Use x-component of rotated pattern for distance calculation
        float d = abs(fpos.x);
        
        // Apply attenuation
        s *= ATTENUATION_FACTOR;
        
        // Create a smooth transition based on lineSmooth parameter:
        // - At lineSmooth = 0: Use hard step transitions (original behavior)
        // - At lineSmooth = 1: Use fully smooth gradient transitions
        float lineEdge = abs(d - lineDistance);
        float hardTransition = step(0.0, s) * smoothstep(-k, k, -lineEdge + lineThick);
        float softTransition = step(0.0, s) * (1.0 - saturate(lineEdge / max(lineThick, 0.001)));
        
        // Blend between hard and soft transitions
        s += lerp(hardTransition, softTransition, lineSmooth);
    }
    
    // Calculate final value, with distance-based damping
    float val = s * INTENSITY_SCALE + INTENSITY_BASE - DISTANCE_DAMPEN * pow(dot(dir, dir), DISTANCE_POWER);
    val = clamp(val, 0.4, 1.0);
    
    // Calculate final color
    float3 finalRGB;
    
    if (UseOriginalColors) {
        // Original color calculation using mathematical palette
        float3 e = float3(1.0, 1.0, 1.0);
        float3 rawColor = 0.5 * pal(val, e, e, e, 0.24 * float3(0.0, 1.0, 2.0) / 3.0);
        rawColor = smoothstep(0.0, 1.0, rawColor); // Ensure color components are in [0,1]
        
        // Apply user intensity and saturation controls
        finalRGB = rawColor * OriginalColorIntensity;
        
        // Apply saturation adjustment
        float3 grayColor = dot(finalRGB, float3(0.299, 0.587, 0.114)); // Luma calculation
        finalRGB = lerp(grayColor, finalRGB, OriginalColorSaturation);
    } else {
        // Use palette-based colors
        float3 paletteColor = getWavySquigglesColor(val, time);
        finalRGB = paletteColor;
    }
    
    // Ensure final color is valid
    finalRGB = saturate(finalRGB);
    
    float4 effectColor = float4(finalRGB, 1.0);
    
    // --- Final Blending & Debug ---
    float4 finalColor = float4(AS_applyBlend(effectColor.rgb, originalColor.rgb, BlendMode), 1.0);
    finalColor = lerp(originalColor, finalColor, BlendStrength);
    
    // Show debug overlay if enabled
    if (DebugMode != AS_DEBUG_OFF) {
        float4 debugMask = float4(0, 0, 0, 0);
        if (DebugMode == 1) { // Show Audio Reactivity
             debugMask = float4(audioReactivity, audioReactivity, audioReactivity, 1.0);
        }
        
        float2 debugCenter = float2(0.1, 0.1); // Example position
        float debugRadius = 0.08;
        if (length(texcoord - debugCenter) < debugRadius) {
            return debugMask;
        }
    }
    
    return finalColor;
}

} // namespace ASWavySquiggles

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_WavySquiggles < ui_label="[AS] BGX: Wavy Squiggles"; ui_tooltip="Dynamic wavy line patterns emanating from a center point."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = ASWavySquiggles::WavySquigglesPS;
    }
}

#endif // __AS_BGX_WavySquiggles_1_fx















