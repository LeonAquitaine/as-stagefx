/**
 * AS_BGX_WavySquares.1.fx - Wavy Squares Background
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Based on "Square Tiling Example E" by SnoopethDuckDuck
 * Shadertoy: https://www.shadertoy.com/view/NdfBzn
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a hypnotic pattern of wavy, animated square tiles that shift and transform.
 * The squares follow a wave-like motion and feature dynamic size changes that create
 * a flowing, organic grid pattern.
 *
 * FEATURES:
 * - Wavy, undulating square tiling patterns
 * - Customizable wave parameters (amplitude, frequency, speed)
 * - Variable tile size and scaling
 * - Shape smoothness and box roundness controls
 * - Audio reactivity with multiple target parameters
 * - Depth-aware rendering
 * - Adjustable rotation
 * - Standard position, scale, and blending options
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Applies wave distortion to the coordinate space
 * 2. Creates a tiling pattern with varied square arrangements
 * 3. Modulates square sizes with time and position
 * 4. Uses signed distance fields to render rounded squares * 5. Applies color based on position and time
 * 6. Integrates with standard AS palette system for coloring
 * 
 * ===================================================================================
 * (https://www.shadertoy.com/view/NdfBzn), adapted for ReShade with additional features
 * and standard AS StageFX framework integration.
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_WavySquares_1_fx
#define __AS_BGX_WavySquares_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"     
#include "AS_Palette.1.fxh"  
#include "AS_Noise.1.fxh"  

namespace ASWavySquares {

// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================

// --- Pattern Parameters ---
static const float WAVE_AMPLITUDE_MIN = 0.0;
static const float WAVE_AMPLITUDE_MAX = 0.2;
static const float WAVE_AMPLITUDE_STEP = 0.001;
static const float WAVE_AMPLITUDE_DEFAULT = 0.06;

static const float WAVE_FREQUENCY_MIN = 1.0;
static const float WAVE_FREQUENCY_MAX = 10.0;
static const float WAVE_FREQUENCY_STEP = 0.1;
static const float WAVE_FREQUENCY_DEFAULT = 4.0;

static const float TILE_SCALE_MIN = 10.0;
static const float TILE_SCALE_MAX = 100.0;
static const float TILE_SCALE_STEP = 1.0;
static const float TILE_SCALE_DEFAULT = 42.0;

static const float SCALE_VARIATION_MIN = 0.0;
static const float SCALE_VARIATION_MAX = 0.1;
static const float SCALE_VARIATION_STEP = 0.001;
static const float SCALE_VARIATION_DEFAULT = 0.025;

static const float BOX_SIZE_MIN = 0.05;
static const float BOX_SIZE_MAX = 0.2;
static const float BOX_SIZE_STEP = 0.01;
static const float BOX_SIZE_DEFAULT = 0.1;

static const float BOX_ROUNDNESS_MIN = 0.1;
static const float BOX_ROUNDNESS_MAX = 0.5;
static const float BOX_ROUNDNESS_STEP = 0.01;
static const float BOX_ROUNDNESS_DEFAULT = 0.28;

static const float SHAPE_VARIATION_MIN = 0.0;
static const float SHAPE_VARIATION_MAX = 0.2;
static const float SHAPE_VARIATION_STEP = 0.01;
static const float SHAPE_VARIATION_DEFAULT = 0.1;

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
static const float EDGE_SMOOTHING_FACTOR = 10.0; // Factor for edge smoothing related to screen resolution
static const float TH_SCALING = 20.0;           // Scaling factor for the tanh function in shape modulation
static const float COLOR_OFFSET = 0.1;          // Base color offset to brighten the final output
static const float COLOR_NORMALIZATION = 0.75;  // Normalization factor for color value based on position

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Pattern Parameters ---
uniform float WaveAmplitude < ui_type = "slider"; ui_label = "Wave Amplitude"; ui_tooltip = "Controls the height of the wave distortion."; ui_min = WAVE_AMPLITUDE_MIN; ui_max = WAVE_AMPLITUDE_MAX; ui_step = WAVE_AMPLITUDE_STEP; ui_category = "Pattern"; > = WAVE_AMPLITUDE_DEFAULT;
uniform float WaveFrequency < ui_type = "slider"; ui_label = "Wave Frequency"; ui_tooltip = "Controls how many waves appear across the pattern."; ui_min = WAVE_FREQUENCY_MIN; ui_max = WAVE_FREQUENCY_MAX; ui_step = WAVE_FREQUENCY_STEP; ui_category = "Pattern"; > = WAVE_FREQUENCY_DEFAULT;
uniform float TileScale < ui_type = "slider"; ui_label = "Tile Scale"; ui_tooltip = "Base scale for the tile pattern. Higher values create smaller tiles."; ui_min = TILE_SCALE_MIN; ui_max = TILE_SCALE_MAX; ui_step = TILE_SCALE_STEP; ui_category = "Pattern"; > = TILE_SCALE_DEFAULT;
uniform float ScaleVariation < ui_type = "slider"; ui_label = "Scale Variation"; ui_tooltip = "How much the scale varies across the pattern."; ui_min = SCALE_VARIATION_MIN; ui_max = SCALE_VARIATION_MAX; ui_step = SCALE_VARIATION_STEP; ui_category = "Pattern"; > = SCALE_VARIATION_DEFAULT;
uniform float BoxSize < ui_type = "slider"; ui_label = "Box Size"; ui_tooltip = "Size of the square elements in the pattern."; ui_min = BOX_SIZE_MIN; ui_max = BOX_SIZE_MAX; ui_step = BOX_SIZE_STEP; ui_category = "Pattern"; > = BOX_SIZE_DEFAULT;
uniform float BoxRoundness < ui_type = "slider"; ui_label = "Box Roundness"; ui_tooltip = "How rounded the corners of the boxes appear."; ui_min = BOX_ROUNDNESS_MIN; ui_max = BOX_ROUNDNESS_MAX; ui_step = BOX_ROUNDNESS_STEP; ui_category = "Pattern"; > = BOX_ROUNDNESS_DEFAULT;
uniform float ShapeVariation < ui_type = "slider"; ui_label = "Shape Variation"; ui_tooltip = "How much the box shapes vary over time."; ui_min = SHAPE_VARIATION_MIN; ui_max = SHAPE_VARIATION_MAX; ui_step = SHAPE_VARIATION_STEP; ui_category = "Pattern"; > = SHAPE_VARIATION_DEFAULT;

// --- Palette & Style ---
uniform bool UseOriginalColors < ui_label = "Use Original Math Colors"; ui_tooltip = "When enabled, uses the mathematically calculated RGB colors instead of palettes."; ui_category = "Palette & Style"; > = true;
uniform float OriginalColorIntensity < ui_type = "slider"; ui_label = "Original Color Intensity"; ui_tooltip = "Adjusts the intensity of original colors when enabled."; ui_min = 0.1; ui_max = ORIG_COLOR_INTENSITY_MAX; ui_step = 0.01; ui_category = "Palette & Style"; ui_spacing = 0; > = ORIG_COLOR_INTENSITY_DEFAULT;
uniform float OriginalColorSaturation < ui_type = "slider"; ui_label = "Original Color Saturation"; ui_tooltip = "Adjusts the saturation of original colors when enabled."; ui_min = 0.0; ui_max = ORIG_COLOR_SATURATION_MAX; ui_step = 0.01; ui_category = "Palette & Style"; > = ORIG_COLOR_SATURATION_DEFAULT;
AS_PALETTE_SELECTION_UI(PalettePreset, "Color Palette", AS_PALETTE_NEON, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(WavySquares_, "Palette & Style")
uniform float ColorCycleSpeed < ui_type = "slider"; ui_label = "Color Cycle Speed"; ui_tooltip = "Controls how fast palette colors cycle. 0 = static."; ui_min = -COLOR_CYCLE_SPEED_MAX; ui_max = COLOR_CYCLE_SPEED_MAX; ui_step = 0.1; ui_category = "Palette & Style"; > = COLOR_CYCLE_SPEED_DEFAULT;

// --- Animation ---
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")

// --- Audio Reactivity ---
AS_AUDIO_UI(WavySquares_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(WavySquares_AudioMultiplier, "Audio Intensity", AUDIO_MULTIPLIER_DEFAULT, AUDIO_MULTIPLIER_MAX, "Audio Reactivity")
uniform int WavySquares_AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter"; ui_items = "None\0Animation Speed\0Wave Amplitude\0Wave Frequency\0Tile Scale\0Box Size\0Box Roundness\0Shape Variation\0"; ui_category = "Audio Reactivity"; > = AUDIO_TARGET_DEFAULT;

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

// Safe hyperbolic tangent to prevent division by zero
float safe_tanh(float x, float a) {
    if (abs(a) < 0.0001) return 0.0;
    return tanh(a * x) / tanh(a);
}

// Get color from the currently selected palette
float3 getWavySquaresColor(float t, float time) {
    if (ColorCycleSpeed != 0.0) {
        float cycleRate = ColorCycleSpeed * 0.1;
        t = frac(t + cycleRate * time);
    }
    t = saturate(t); 
    
    if (PalettePreset == AS_PALETTE_CUSTOM) { // Use custom palette
        return AS_GET_INTERPOLATED_CUSTOM_COLOR(WavySquares_, t);
    }
    return AS_getInterpolatedColor(PalettePreset, t); // Use preset palette
}

// Original color function from the SnoopethDuckDuck Shadertoy shader
// Source: https://www.shadertoy.com/view/NdfBzn "Square Tiling Example E"
float3 pal(float t, float3 a, float3 b, float3 c, float3 d) {
    return a + b * cos(AS_TWO_PI * (c * t + d));
}

// Signed distance function for a box
float sdBox(float2 p, float2 b) {
    float2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 WavySquaresPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD) : SV_TARGET {
    // Get original pixel color and depth
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);

    // Apply depth test
    if (depth < EffectDepth) {
        return originalColor;
    }
    
    // Apply audio reactivity to selected parameters
    float animSpeed = AnimationSpeed;
    float waveAmp = WaveAmplitude;
    float waveFreq = WaveFrequency;
    float tileScale = TileScale;
    float boxSz = BoxSize;
    float boxRound = BoxRoundness;
    float shapeVar = ShapeVariation;
    
    float audioReactivity = AS_applyAudioReactivity(1.0, WavySquares_AudioSource, WavySquares_AudioMultiplier, true);
    
    // Map audio target combo index to parameter adjustment
    if (WavySquares_AudioTarget == 1) animSpeed *= audioReactivity;
    else if (WavySquares_AudioTarget == 2) waveAmp *= audioReactivity;
    else if (WavySquares_AudioTarget == 3) waveFreq *= audioReactivity;
    else if (WavySquares_AudioTarget == 4) tileScale *= audioReactivity;
    else if (WavySquares_AudioTarget == 5) boxSz *= audioReactivity;
    else if (WavySquares_AudioTarget == 6) boxRound *= audioReactivity;
    else if (WavySquares_AudioTarget == 7) shapeVar *= audioReactivity;

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
    
    // Adjust coordinates for the pattern
    uv.x -= 1.0 + 0.25 * AS_PI * 0.2 * time;
    uv.y += waveAmp * cos(waveFreq * uv.x + AS_PI * 0.2 * time);
    
    // Calculate scaling factor with variation
    float sc = tileScale + ScaleVariation * (1.0 + safe_tanh(cos(4.0 * uv.x + uv.y + time), 1.0));
    
    // Calculate integer and fractional positions
    float2 ipos = floor(sc * uv);
    float2 fpos = frac(sc * uv);
    
    // Determine pattern variation based on position
    float m = AS_mod(2.0 * ipos.x - ipos.y, 5.0);
    
    float id_val = 2.0;
    float2 o = float2(0.0, 0.0);
    
    // Create different square arrangements based on pattern variation
    if (m != 3.0) { 
        fpos *= 0.5; 
        id_val = 1.0; 
    }
    
    if (m == 2.0)      o = float2(1.0, 0.0);
    else if (m == 4.0) o = float2(0.0, 1.0);
    else if (m == 1.0) o = float2(1.0, 1.0);
    
    fpos += 0.5 * o - 0.5;
    ipos -= o;
    
    // Get hash value for pseudo-random variation
    float h = AS_hash11(dot(ipos, float2(12.9898, 78.233)));
    
    // Calculate time-varying value for animation
    float v = 0.3 * ipos.x / sc + 0.25 * h + 0.2 * time;
    
    // Calculate shape using signed distance function with temporal variation
    float d_shape = sdBox(fpos, float2(boxSz, boxSz)) - boxRound - shapeVar * safe_tanh(cos(2.0 * AS_PI * v), TH_SCALING);
    
    // Apply anti-aliasing edge smoothing
    float k = EDGE_SMOOTHING_FACTOR / BUFFER_SCREEN_SIZE.y;
    float s = smoothstep(-k, k, -d_shape);
    
    // Calculate color value based on position
    float c_val = (COLOR_NORMALIZATION / sc) * ipos.y + 0.5 + 0.5 * h;
    c_val *= s;
    
    // Calculate final color
    float3 finalRGB;
    
    if (UseOriginalColors) {
        // Original color calculation using mathematical palette
        float3 e = float3(1.0, 1.0, 1.0);
        float f = smoothstep(-0.5, 0.5, fpos.x);
        float3 rawColor = c_val * pal(v, 0.6 * f * e, e, 0.8 * e, (COLOR_NORMALIZATION / sc) * ipos.y * float3(0.0, 0.33, 0.66));
        
        // Apply user intensity and saturation controls
        finalRGB = rawColor * OriginalColorIntensity;
        
        // Apply saturation adjustment
        float3 grayColor = dot(finalRGB, float3(0.299, 0.587, 0.114)); // Luma calculation
        finalRGB = lerp(grayColor, finalRGB, OriginalColorSaturation);
    } else {
        // Use palette-based colors
        float3 paletteColor = getWavySquaresColor(c_val, time);
        finalRGB = paletteColor;
    }
    
    // Ensure final color is valid and add base brightness
    finalRGB = saturate(finalRGB);
    finalRGB += COLOR_OFFSET;
    
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

} // namespace ASWavySquares

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_WavySquares < ui_label="[AS] BGX: Wavy Squares"; ui_tooltip="Dynamic wavy square patterns with undulating grid animation."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = ASWavySquares::WavySquaresPS;
    }
}

#endif // __AS_BGX_WavySquares_1_fx


