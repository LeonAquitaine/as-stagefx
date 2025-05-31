/**
 * AS_VFX_Arabesque.1.fx - Generates intricate, arabesque-like geometric patterns.
 * Author: Leon Aquitaine
 * License: CC BY 4.0
 *
 * DESCRIPTION:
 * This shader creates complex, symmetrical, and tileable patterns reminiscent of
 * arabesque designs. It uses an iterative approach to generate a base pattern value,
 * which is then used to select and shade colors with precise, defined boundaries,
 * simulating a carved or inlaid appearance. The iterative core allows for fractal-like
 * richness and detail.
 *
 * FEATURES:
 * - Iterative pattern generation for complex geometric, organic-like, and fractal details.
 * - Precise color zone definition using multiple cosine waves.
 * - Simulation of 3D relief/carved appearance through shading (can be disabled for flat look).
 * - User-definable colors for different pattern zones.
 * - Controls for pattern scale, position, iteration count, and generation parameters.
 * - Optional tiling of the entire effect.
 * - Animation capabilities for pattern evolution.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. UV coordinates are transformed (position, scale, global aspect correction).
 * 2. An iterative function (`GetArabesquePatternValue_Iterative`) processes the UVs:
 * - It uses folding (abs), mirroring (uv.yx swaps), and feedback loops.
 * - The number of iterations is controllable (key for fractal detail).
 * - The final output is a scalar `pattern_value`.
 * 3. This `pattern_value` drives a multi-wave cosine function (`float3 waves = cos(pattern_value * TWO_PI * frequencies)`).
 * 4. The components of `waves` (waves.x, waves.y) are used in conditional logic
 * to select one of several user-defined base colors for the current pixel.
 * 5. A subtle relief effect is simulated by modulating the brightness of the base
 * color using another component of `waves`.
 * 6. The overall effect can be tiled across the screen.
 * 7. Animation can be introduced by varying pattern parameters or phases over time.
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_ARABESQUE_1_FX
#define __AS_VFX_ARABESQUE_1_FX

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // Utility functions, UI macros, audio, math
#include "AS_Palette.1.fxh" // Palette utilities (though not heavily used here yet)

// ============================================================================
// UI DECLARATIONS (Tunable Constants and Uniforms)
// ============================================================================

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Position & Scale
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
AS_POS_UI(Arabesque_Position_Val) // This macro from AS_Utils.1.fxh defines 'uniform float2 Arabesque_Position_Val'
AS_SCALE_UI(Arabesque_Scale_Val)  // This macro from AS_Utils.1.fxh defines 'uniform float Arabesque_Scale_Val'

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Pattern Definition
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
static const int ITERATIONS_MIN = 1; static const int ITERATIONS_MAX = 16; static const int ITERATIONS_DEFAULT = 8;
uniform int Arabesque_Iterations < ui_type = "slider"; ui_label = "Pattern Iterations"; ui_tooltip = "Number of iterations for pattern generation. Higher values create more fractal detail but are slower."; ui_min = ITERATIONS_MIN; ui_max = ITERATIONS_MAX; ui_category = "Pattern Definition"; > = ITERATIONS_DEFAULT;

static const float PATTERN_OFFSET_MIN = -1.0f; static const float PATTERN_OFFSET_MAX = 1.0f; static const float PATTERN_OFFSET_DEFAULT = 0.5f;
uniform float Arabesque_PatternOffset < ui_type = "slider"; ui_label = "Pattern Offset"; ui_tooltip = "Internal offset used in pattern generation. Affects starting shape."; ui_min = PATTERN_OFFSET_MIN; ui_max = PATTERN_OFFSET_MAX; ui_step = 0.01f; ui_category = "Pattern Definition"; > = PATTERN_OFFSET_DEFAULT;

static const float FEEDBACK_SCALE_MIN = -2.0f; static const float FEEDBACK_SCALE_MAX = 2.0f; static const float FEEDBACK_SCALE_DEFAULT = -1.0f;
uniform float Arabesque_FeedbackScale < ui_type = "slider"; ui_label = "Feedback Scale"; ui_tooltip = "Scale of the feedback variable. Influences branching and complexity."; ui_min = FEEDBACK_SCALE_MIN; ui_max = FEEDBACK_SCALE_MAX; ui_step = 0.01f; ui_category = "Pattern Definition"; > = FEEDBACK_SCALE_DEFAULT;

static const float FOLD_SCALE_MIN = 0.5f; static const float FOLD_SCALE_MAX = 3.0f; static const float FOLD_SCALE_DEFAULT = 1.5f;
uniform float Arabesque_FoldScale < ui_type = "slider"; ui_label = "Fold Scale"; ui_tooltip = "Scaling factor applied during UV folding. Affects pattern density and detail size."; ui_min = FOLD_SCALE_MIN; ui_max = FOLD_SCALE_MAX; ui_step = 0.01f; ui_category = "Pattern Definition"; > = FOLD_SCALE_DEFAULT;

uniform bool Arabesque_EnableTiling < ui_label = "Enable Screen Tiling"; ui_tooltip = "Repeats the entire arabesque pattern across the screen."; ui_category = "Pattern Definition"; > = false;

static const float TILE_FACTOR_MIN = 0.1f; static const float TILE_FACTOR_MAX = 4.0f; static const float TILE_FACTOR_DEFAULT = 1.0f;
uniform float Arabesque_TileFactor < ui_type = "slider"; ui_label = "Screen Tile Factor"; ui_tooltip = "How many times the pattern repeats across the screen if tiling is enabled."; ui_min = TILE_FACTOR_MIN; ui_max = TILE_FACTOR_MAX; ui_step = 0.01f; ui_category = "Pattern Definition"; > = TILE_FACTOR_DEFAULT;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Coloring
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
uniform float3 Arabesque_Color1 < ui_type = "color"; ui_label = "Primary Color"; ui_category = "Coloring"; > = float3(0.9f, 0.7f, 0.2f); 
uniform float3 Arabesque_Color2 < ui_type = "color"; ui_label = "Secondary Color"; ui_category = "Coloring"; > = float3(0.8f, 0.6f, 0.15f); 
uniform float3 Arabesque_Color3 < ui_type = "color"; ui_label = "Tertiary Color / Accent"; ui_category = "Coloring"; > = float3(1.0f, 0.9f, 0.5f); 
uniform float3 Arabesque_BackgroundColor < ui_type = "color"; ui_label = "Background Color (if no zone active)"; ui_category = "Coloring"; > = float3(0.05f, 0.05f, 0.05f); 

static const float FREQ1_MIN = 0.25f; static const float FREQ1_MAX = 8.0f; static const float FREQ1_DEFAULT = 1.0f;
static const float FREQ2_MIN = 0.25f; static const float FREQ2_MAX = 8.0f; static const float FREQ2_DEFAULT = 2.0f;
static const float FREQ3_MIN = 0.25f; static const float FREQ3_MAX = 8.0f; static const float FREQ3_DEFAULT = 3.0f; 
uniform float Arabesque_WaveFreq1 < ui_type = "slider"; ui_label = "Wave Frequency 1"; ui_tooltip = "Frequency of the first cosine wave for color zone 1."; ui_category = "Coloring"; ui_min=FREQ1_MIN; ui_max=FREQ1_MAX; ui_step=0.01f; > = FREQ1_DEFAULT;
uniform float Arabesque_WaveFreq2 < ui_type = "slider"; ui_label = "Wave Frequency 2"; ui_tooltip = "Frequency of the second cosine wave for color zone 2."; ui_category = "Coloring"; ui_min=FREQ2_MIN; ui_max=FREQ2_MAX; ui_step=0.01f; > = FREQ2_DEFAULT;
uniform float Arabesque_WaveFreq3 < ui_type = "slider"; ui_label = "Wave Frequency 3 (Relief)"; ui_tooltip = "Frequency of the cosine wave used for relief shading."; ui_category = "Coloring"; ui_min=FREQ3_MIN; ui_max=FREQ3_MAX; ui_step=0.01f; > = FREQ3_DEFAULT;

static const float THRESHOLD_MIN = -1.0f; static const float THRESHOLD_MAX = 1.0f; static const float THRESHOLD_DEFAULT1 = 0.0f; static const float THRESHOLD_DEFAULT2 = 0.0f;
uniform float Arabesque_ColorThreshold1 < ui_type = "slider"; ui_label = "Color Threshold 1 (Wave X)"; ui_tooltip = "Threshold for wave 1 to activate Primary Color."; ui_category = "Coloring"; ui_min=THRESHOLD_MIN; ui_max=THRESHOLD_MAX; ui_step=0.01f; > = THRESHOLD_DEFAULT1;
uniform float Arabesque_ColorThreshold2 < ui_type = "slider"; ui_label = "Color Threshold 2 (Wave Y)"; ui_tooltip = "Threshold for wave 2 to activate Secondary Color."; ui_category = "Coloring"; ui_min=THRESHOLD_MIN; ui_max=THRESHOLD_MAX; ui_step=0.01f; > = THRESHOLD_DEFAULT2;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Relief Shading
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
static const float RELIEF_STRENGTH_MIN = 0.0f; static const float RELIEF_STRENGTH_MAX = 1.0f; static const float RELIEF_STRENGTH_DEFAULT = 0.0f; 
uniform float Arabesque_ReliefStrength < ui_type = "slider"; ui_label = "Relief Strength"; ui_tooltip = "Strength of the simulated 3D relief effect. Set to 0 for a flat look."; ui_min = RELIEF_STRENGTH_MIN; ui_max = RELIEF_STRENGTH_MAX; ui_step = 0.01f; ui_category = "Relief Shading"; > = RELIEF_STRENGTH_DEFAULT;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Animation
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
AS_ANIMATION_UI(Arabesque_AnimationSpeed, Arabesque_AnimationKeyframe, "Animation") // Macro from AS_Utils.1.fxh

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Final Mix
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
AS_BLENDMODE_UI_DEFAULT(Arabesque_BlendMode, 1) // Defaulting to 1 (standard Alpha blend) instead of AS_BLEND_ALPHA
AS_BLENDAMOUNT_UI(Arabesque_BlendAmount) // Macro from AS_Utils.1.fxh

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

float2 AS_TriangleWave_Local(float2 a) 
{
    float2 a2 = float2(1.0f, 0.5f); 
    float2 a1 = a + a2;
    return abs(frac((a1) * (a2.x + a2.y)) - 0.5f);
}

float GetArabesquePatternValue_Iterative(float2 uv_in, float time, int iterations, float p_offset, float feedback_scale, float fold_scale, float anim_speed_param)
{
    float2 feedback_var = float2(0.0f, 0.0f);
    float2 current_uv = uv_in;

    float angle = time * 0.05f * anim_speed_param; 
    float s = sin(angle);
    float c = cos(angle);
    current_uv = float2(current_uv.x * c - current_uv.y * s, current_uv.x * s + current_uv.y * c);

    [loop] 
    for (int k = 0; k < iterations; k++)
    {
        current_uv = abs(p_offset + current_uv + feedback_var);

        if (current_uv.y < current_uv.x) current_uv = current_uv.yx;
        
        float time_k_mod = time * 0.1f * anim_speed_param + float(k) * 0.3f;
        feedback_var = AS_TriangleWave_Local(current_uv - 0.5f + sin(time_k_mod) * 0.1f) .yx * feedback_scale;
        
        float time_k_mod2 = time * 0.075f * anim_speed_param - float(k) * 0.2f;
        current_uv = (feedback_var - AS_TriangleWave_Local(current_uv.yx + (cos(time_k_mod2) * 0.1f))) / fold_scale;
        
        if (dot(current_uv, current_uv) > 1e4f || (dot(current_uv, current_uv) < 1e-4f && k > iterations / 2)) break; 
    }
    return length(current_uv) * 0.5f; 
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_Arabesque_VFX(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float time = AS_getAnimationTime(Arabesque_AnimationSpeed, Arabesque_AnimationKeyframe); // Uses uniforms from AS_ANIMATION_UI

    float2 ps_uv = texcoord;    if (Arabesque_EnableTiling)
    {
        ps_uv = AS_mod(ps_uv * Arabesque_TileFactor, 1.0); // AS_mod from AS_Utils.1.fxh
    }
    
    float ar = ReShade::AspectRatio; // ReShade built-in
    float2 centered_uv = (ps_uv - 0.5f);
    if (ar > 1.0f) centered_uv.x *= ar; else centered_uv.y /= ar;

    // Using the names defined by the AS_POS_UI and AS_SCALE_UI macros
    centered_uv /= Arabesque_Scale_Val; 
    centered_uv -= (Arabesque_Position_Val * 0.5f) / Arabesque_Scale_Val; // Using Arabesque_Position_Val


    float pattern_value = GetArabesquePatternValue_Iterative(
        centered_uv, 
        time,
        Arabesque_Iterations,
        Arabesque_PatternOffset,
        Arabesque_FeedbackScale,
        Arabesque_FoldScale,
        Arabesque_AnimationSpeed // Pass the animation speed uniform to the function
    );

    float3 waves = cos(pattern_value * AS_TWO_PI * float3(Arabesque_WaveFreq1, Arabesque_WaveFreq2, Arabesque_WaveFreq3)); // AS_TWO_PI from AS_Utils.1.fxh

    float3 effect_color_zone = Arabesque_BackgroundColor;
    float effect_alpha = 0.0f; 

    if (waves.x > Arabesque_ColorThreshold1)
    {
        effect_color_zone = Arabesque_Color1;
        effect_alpha = 1.0f;
    }
    else if (waves.y > Arabesque_ColorThreshold2)
    {
        effect_color_zone = Arabesque_Color2;
        effect_alpha = 1.0f;
    }
    else if (effect_alpha < 0.5f && waves.z > Arabesque_ColorThreshold1) 
    {
        effect_color_zone = Arabesque_Color3;
        effect_alpha = 1.0f;
    }
    
    if (effect_alpha < 0.5f && pattern_value < (2.0f / max(0.001f, Arabesque_FoldScale)) && pattern_value > 0.001f) {
         effect_color_zone = Arabesque_BackgroundColor; 
         effect_alpha = 1.0f; 
    }

    if (effect_alpha > 0.0f && Arabesque_ReliefStrength > 0.0f)
    {
        float relief_modulation = 1.0f + waves.z * Arabesque_ReliefStrength;
        effect_color_zone *= relief_modulation;
    }
    
    float4 ps_finalEffectColor = float4(saturate(effect_color_zone), effect_alpha);

    return AS_applyBlend(ps_finalEffectColor, originalColor, Arabesque_BlendMode, Arabesque_BlendAmount); // AS_applyBlend from AS_Utils.1.fxh
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_VFX_Arabesque < ui_tooltip = "Generates intricate, arabesque-like geometric patterns with precise color definition and simulated relief. Inspired by user references."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Arabesque_VFX;
    }
}

#endif // __AS_VFX_ARABESQUE_1_FX