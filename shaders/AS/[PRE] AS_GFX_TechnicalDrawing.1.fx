/**
 * AS_GFX_TechnicalDrawing.1.fx - Hand-Drawn Sketch with Gaussian Blur
 * Author: Leon Aquitaine | License: CC BY 4.0
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader applies a stylized hand-drawn hatching effect to the scene,
 * mimicking a sketch or technical illustration, and then processes the result
 * with a customizable Gaussian blur. It creates dynamic patterns based on scene
 * luminance and can be adjusted for various artistic outputs.
 *
 * FEATURES:
 * - Procedural hatching patterns with adjustable density and line width.
 * - Luminance-based detail control for the hatching.
 * - Adds a subtle edge detection overlay for enhanced definition.
 * - Applies a configurable Gaussian blur as a post-processing step.
 * - Resolution-independent calculations for consistent appearance.
 * - Customizable animation speed for pattern evolution.
 * - Tunable parameters for all major visual aspects.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. The shader defines global UI controls for pattern, animation, and blur settings.
 * 2. A custom `voronoi` function and `gaussian` filter are implemented, utilizing
 * AS-StageFX's noise utilities and standard mathematical constants.
 * 3. `PS_HandDrawing` pass:
 * - Converts screen coordinates to pixel coordinates for detailed calculations.
 * - Applies a pseudo-random offset to pixel coordinates using hash functions.
 * - Generates dynamic hatching based on scene luminance and tunable parameters.
 * - Integrates a Sobel filter for edge detection, overlaying it on the hatched output.
 * - The result is rendered to an intermediate `HandDrawing_Buffer`.
 * 4. `PS_GaussianBlur` pass:
 * - Reads from the `HandDrawing_Buffer`.
 * - Applies a Gaussian blur filter using a configurable kernel size and sigma value.
 * - The final blurred image is rendered to the ReShade back buffer.
 * 5. A two-pass technique is defined to execute these two steps sequentially.
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_GFX_TechnicalDrawing_1_fx
#define __AS_GFX_TechnicalDrawing_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Noise.1.fxh" // For AS_hash functions

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
// Animation Constants
static const float ANIMATION_SPEED_MIN = 0.0;
static const float ANIMATION_SPEED_MAX = 10.0;
static const float ANIMATION_SPEED_DEFAULT = 4.0;

// Pattern Constants
static const float VORONOISCALE_MIN = 1.0;
static const float VORONOISCALE_MAX = 50.0;
static const float VORONOISCALE_DEFAULT = 13.6;
static const float LINEWIDTH_MIN = 1.0;
static const float LINEWIDTH_MAX = 10.0;
static const float LINEWIDTH_DEFAULT = 4.7;
static const int NUMLEVELS_MIN = 1;
static const int NUMLEVELS_MAX = 8;
static const int NUMLEVELS_DEFAULT = 4;

// Blur Constants
static const int KERNEL_SIZE_MIN = 1;
static const int KERNEL_SIZE_MAX = 15;
static const int KERNEL_SIZE_DEFAULT = 7;
static const float SIGMA_MIN = 0.1;
static const float SIGMA_MAX = 5.0;
static const float SIGMA_DEFAULT = 0.85;

// ============================================================================
// UI UNIFORMS
// ============================================================================
// 1. Position & Transformation (Not explicitly used for screen-filling effect, but good to include standard set if needed)
// 2. Palette & Style (Not directly applicable to this monochrome-focused effect, but can be added if colorization is desired)
// 3. Effect-Specific Appearance
uniform float VoronoiScale < ui_type = "slider"; ui_label = "Voronoi Scale"; ui_min = VORONOISCALE_MIN; ui_max = VORONOISCALE_MAX; ui_step = 0.1; ui_category = "Pattern"; > = VORONOISCALE_DEFAULT;
uniform float LineWidth < ui_type = "slider"; ui_label = "Hatch Line Width"; ui_min = LINEWIDTH_MIN; ui_max = LINEWIDTH_MAX; ui_step = 0.1; ui_category = "Pattern"; > = LINEWIDTH_DEFAULT;
uniform int NumLevels < ui_type = "slider"; ui_label = "Hatch Levels"; ui_min = NUMLEVELS_MIN; ui_max = NUMLEVELS_MAX; ui_step = 1; ui_category = "Pattern"; > = NUMLEVELS_DEFAULT;

// 4. Animation Controls
uniform float AnimationSpeed < ui_type = "slider"; ui_label = "Animation Speed"; ui_min = ANIMATION_SPEED_MIN; ui_max = ANIMATION_SPEED_MAX; ui_step = 0.1; ui_category = "Animation"; > = ANIMATION_SPEED_DEFAULT;

// 5. Audio Reactivity (Not implemented in original, but can be added)
// 6. Stage Controls (Not explicitly used as it's a full-screen effect)

// 7. Final Mix (Blend with original) - Handled by the shader logic directly.

// 8. Blur Controls
uniform int KernelSize < ui_type = "slider"; ui_label = "Blur Kernel Size"; ui_min = KERNEL_SIZE_MIN; ui_max = KERNEL_SIZE_MAX; ui_step = 1; ui_category = "Blur"; > = KERNEL_SIZE_DEFAULT;
uniform float Sigma < ui_type = "slider"; ui_label = "Blur Sigma"; ui_min = SIGMA_MIN; ui_max = SIGMA_MAX; ui_step = 0.01; ui_category = "Blur"; > = SIGMA_DEFAULT;

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Luminance calculation
float calculateLuminance(float3 color) {
    return dot(color, float3(0.299, 0.587, 0.114));
}

// Custom Voronoi function (adapted from original GLSL, using AS_Noise hashes)
// Returns xy: sqrt(distance), zw: sum of cell hash components for seeding
float2 customVoronoi(float2 x) {
    float2 n = floor(x);
    float2 f = x - n;

    float3 m = float3(8, 0, 0); // distance, o.x, o.y
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            float2 g = float2(i, j);
            float2 o = AS_hash22(n + g); // Use AS_hash22
            float2 r = g - f + (0.5 + 0.5 * sin(AS_TWO_PI * o));
            float d = dot(r, r);
            if (d < m.x) {
                m = float3(d, o.x, o.y);
            }
        }
    }
    return float2(sqrt(m.x), m.y + m.z); // sqrt(distance), sum of o components
}

// Gaussian function for blur kernel
float gaussian(float2 pos, float sigma) {
    float left = 1.0 / (2.0 * AS_PI * sigma * sigma);
    float right = exp(-dot(pos, pos) / (2.0 * sigma * sigma));
    return left * right;
}

// Sobel kernel (transposed for y)
static const int sobel[9] = { -1, 0, 1, -2, 0, 2, -1, 0, 1 };

// ============================================================================
// TEXTURES AND SAMPLERS
// ============================================================================
texture HandDrawing_Buffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler HandDrawing_Sampler { Texture = HandDrawing_Buffer; };

// ============================================================================
// PIXEL SHADERS
// ============================================================================

// Pixel Shader for Hand Drawing Effect (Buffer A)
float4 PS_HandDrawing(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float4 baseColor = tex2D(ReShade::BackBuffer, texcoord);
    float3 originalRgb = baseColor.rgb;

    // Convert texcoord to pixel coordinates for pixel-based calculations
    float2 fragCoord_px = texcoord * float2(BUFFER_WIDTH, BUFFER_HEIGHT);

    // Get random voronoi region, scaled relative to larger dimension
    float2 p_scaled = fragCoord_px / max(BUFFER_WIDTH, BUFFER_HEIGHT);
    
    // Truncate time for "frame-based" animation as in original
    float time = AnimationSpeed * round(AnimationSpeed * AS_getTime());
    p_scaled += AS_hash21(time); // Use AS_hash21
    float2 c = customVoronoi(VoronoiScale * p_scaled);

    // Sample image and get luminance
    float lum = calculateLuminance(originalRgb);

    // Posterize to determine # hatch
    int num = NumLevels - int(float(NumLevels + 1) * lum);
    
    // Offset coord a bit for jagged lines
    float2 rand_coord_px = fragCoord_px - 0.5 + 0.4 * AS_hash22(fragCoord_px); // Use AS_hash22

    float rand_seed = 100.0 * c.y; // c.y holds the sum of hash components as a seed
    float angle = AS_TWO_PI * AS_hash11(rand_seed); // Use AS_hash11
    float new_lum = 1.0;

    for (int i = 0; i < num; i++) {
        // Offset angle to avoid moire
        rand_seed += 10.0;
        angle += AS_PI * lerp(
            1.0 / float(1 + num),
            1.0 / float(num),
            AS_hash11(rand_seed) // Use AS_hash11
        );
        
        // Procedural hatch pattern
        float d2l = abs(dot(rand_coord_px, float2(cos(angle), sin(angle))));
        float repeat = abs(1.0 - 2.0 * AS_mod(d2l / LineWidth, 1.0)); // Use AS_mod
        repeat = pow(repeat, 1.3);
        float line = smoothstep(0.64, 0.65, repeat);
        new_lum -= line;
    }

    float3 finalColor = originalRgb * clamp(new_lum, 0.0, 1.0);
    
    // Add edge lines with Sobel filter
    // Calculate offsets in UV space using ReShade::PixelSize
    float2 sum_sobel = 0;
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            float2 offset_uv = float2(i - 1, j - 1) * ReShade::PixelSize;
            float4 col = tex2D(ReShade::BackBuffer, texcoord + offset_uv);
            float l = calculateLuminance(col.rgb);
            sum_sobel += l * float2(sobel[i + 3 * j], sobel[j + 3 * i]);
        }
    }
    float mag = length(sum_sobel);
    finalColor *= (1.0 - smoothstep(0.75, 0.9, mag));

    return float4(finalColor, baseColor.a);
}


// Pixel Shader for Gaussian Blur (Image)
float4 PS_GaussianBlur(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float4 sum = 0;
    float totalWeight = 0;

    // Apply convolution
    for (int i = -KernelSize; i <= KernelSize; i++) {
        for (int j = -KernelSize; j <= KernelSize; j++) {
            float2 offset = float2(i, j);
            float weight = gaussian(offset, Sigma);
            
            float2 offset_uv = offset * ReShade::PixelSize;
            float4 col = tex2D(HandDrawing_Sampler, texcoord + offset_uv); // Sample from HandDrawing_Buffer
            sum += weight * float4(col.rgb, 1.0); // Summing alpha of 1.0 for weighted average
            totalWeight += weight; // Accumulate weights
        }
    }
    
    // Normalize sum by accumulated weight (equivalent to sum/sum.a in original GLSL if sum.a was total weight)
    return float4(sum.rgb / totalWeight, 1.0);
}


// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_GFX_TechnicalDrawing {
    // Pass 1: Apply Hand Drawing and Edge Detection to BackBuffer, output to HandDrawing_Buffer
    pass HandDrawingPass {
        VertexShader = PostProcessVS;
        PixelShader = PS_HandDrawing;
        RenderTarget = HandDrawing_Buffer;
    }

    // Pass 2: Apply Gaussian Blur to HandDrawing_Buffer, output to final BackBuffer
    pass GaussianBlurPass {
        VertexShader = PostProcessVS;
        PixelShader = PS_GaussianBlur;
    }
}

#endif // __AS_GFX_TechnicalDrawing_1_fx