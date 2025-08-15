/**
 * AS_GFX_OilPainting.1.fx - Oil Paint Brush Drawing with Relief Lighting
 *
 * Original Creator: florian berger (flockaroo) - 2018
 * Original Licens// 6. Relief Lighting Settings
uniform float PaintSpec < ui_type = "slider"; ui_label = "Paint Specularity"; ui_min = PAINTSPEC_MIN; ui_max = PAINTSPEC_MAX; ui_step = 0.01; ui_category = "Relief Lighting"; ui_tooltip = "Adjusts the intensity of specular highlights on the paint texture."; > = PAINTSPEC_DEFAULT;

// 7. Vignette Settingsreative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
 * Original Shaderoo.org Geometry Version: https://shaderoo.org/?shader=N6DFZT
 *
 * Adapted for ReShade AS-StageFX by: Leon Aquitaine
 * AS-StageFX License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader creates an artistic oil paint brush drawing effect, transforming the
 * scene into a stylized illustration with visible brush strokes. A second pass then
 * applies relief lighting, enhancing the perceived depth and texture of the strokes
 * and adding a customizable vignette. It's ideal for a painterly or technical
 * drawing aesthetic.
 *
 * FEATURES:
 * - Procedural brush strokes with customizable detail, size, and bending.
 * - Depth-based brush detail control for realistic depth of field effects.
 * - Luminance-driven brush stroke density.
 * - Optional color keying for background replacement.
 * - Customizable source image contrast and brightness.
 * - Simulated canvas texture for added realism.
 * - Relief lighting pass with adjustable paint specularity.
 * - Dynamic vignette with configurable intensity and pattern.
 * - Resolution-independent rendering for consistent results across various screen resolutions.
 * - Tunable animation for stroke movement and various visual parameters.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. The shader defines a comprehensive set of UI controls for all effect parameters,
 * organized into standard AS-StageFX categories.
 * 2. Helper functions are included for luminance calculation, a custom Voronoi-like
 * randomness, and a gaussian function for the lighting pass.
 * 3. `PS_OilPaintingDrawing` Pass:
 * - Processes the input scene (`ReShade::BackBuffer`) and an optional background texture.
 * - Calculates dynamic brush stroke positions and properties based on luminance,
 * random textures, and animated time.
 * - Generates and blends individual brush strokes, simulating oil paint layers.
 * - Outputs the primary brush drawing to `OilPainting_Buffer`.
 * 4. `PS_OilPaintingRelief` Pass:
 * - Reads the `OilPainting_Buffer` as its primary input.
 * - Calculates a 'normal map' from the luminance gradients of the brush strokes.
 * - Applies simple diffuse and specular lighting based on a fixed light direction.
 * - Adds a dynamic vignette effect.
 * - Renders the final result to the main screen.
 * 5. A two-pass technique (`OilPaintingDrawingPass`, `OilPaintingReliefPass`) ensures
 * sequential execution of the brush drawing and relief lighting effects.
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_GFX_OilPainting_1_fx
#define __AS_GFX_OilPainting_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Noise.1.fxh" // For AS_hash functions

// ============================================================================
// TEXTURES AND SAMPLERS
// ============================================================================

// Defined dimensions for AS_NoiseTexture as textureSize is not available
static const int AS_NOISE_TEXTURE_WIDTH = 256;
static const int AS_NOISE_TEXTURE_HEIGHT = 256;

#ifndef AS_NOISE_TEXTURE_PATH
#define AS_NOISE_TEXTURE_PATH "perlin512x8CNoise.png" // Default noise texture
#endif
texture AS_NoiseTexture < source = AS_NOISE_TEXTURE_PATH; ui_label = "Randomness Texture"; ui_tooltip = "Texture for random values and noise. Can be a custom noise map."; >
{ Width = AS_NOISE_TEXTURE_WIDTH; Height = AS_NOISE_TEXTURE_HEIGHT; Format = RGBA8; }; // Using 256x256 as a common noise texture size
sampler AS_NoiseSampler { Texture = AS_NoiseTexture; AddressU = REPEAT; AddressV = REPEAT; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };

// Defined dimensions for AS_BackgroundTexture as textureSize is not available
static const int AS_BACKGROUND_TEXTURE_WIDTH = 256;
static const int AS_BACKGROUND_TEXTURE_HEIGHT = 256;

#ifndef AS_BACKGROUND_TEXTURE_PATH
#define AS_BACKGROUND_TEXTURE_PATH "perlin512x8Noise.png" // Default blank background
#endif
texture AS_BackgroundTexture < source = AS_BACKGROUND_TEXTURE_PATH; ui_label = "Color Key Background"; ui_tooltip = "Texture used for background when Color Keying is enabled."; >
{ Width = AS_BACKGROUND_TEXTURE_WIDTH; Height = AS_BACKGROUND_TEXTURE_HEIGHT; Format = RGBA8; }; // Example size, texture will be sampled based on aspect ratio
sampler AS_BackgroundSampler { Texture = AS_BackgroundTexture; AddressU = REPEAT; AddressV = REPEAT; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };


texture OilPainting_Buffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler OilPainting_Sampler { Texture = OilPainting_Buffer; };

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
// General Settings
static const float QUALITY_PERCENT_MIN = 1.0;
static const float QUALITY_PERCENT_MAX = 100.0;
static const float QUALITY_PERCENT_DEFAULT = 85.0;

// Source Image Adjustments
static const float SRCCONTRAST_MIN = 0.0;
static const float SRCCONTRAST_MAX = 5.0;
static const float SRCCONTRAST_DEFAULT = 1.4;
static const float SRCBRIGHT_MIN = 0.0;
static const float SRCBRIGHT_MAX = 2.0;
static const float SRCBRIGHT_DEFAULT = 1.0;

// Brush Settings
static const float BRUSHDETAIL_MIN = 0.0;
static const float BRUSHDETAIL_MAX = 1.0;
static const float BRUSHDETAIL_DEFAULT = 0.1;
static const float DEPTH_DETAIL_INFLUENCE_MIN = 0.0;
static const float DEPTH_DETAIL_INFLUENCE_MAX = 2.0;
static const float DEPTH_DETAIL_INFLUENCE_DEFAULT = 0.0;
static const float STROKEBEND_MIN = -2.0;
static const float STROKEBEND_MAX = 2.0;
static const float STROKEBEND_DEFAULT = -1.0;
static const float BRUSHSIZE_MIN = 0.1;
static const float BRUSHSIZE_MAX = 5.0;
static const float BRUSHSIZE_DEFAULT = 1.0;

// Animation
static const float ANIMATION_BASE_SPEED = 0.5; // Base speed for sin-based animation of strokes

// Relief Lighting
static const float PAINTSPEC_MIN = 0.0;
static const float PAINTSPEC_MAX = 1.0;
static const float PAINTSPEC_DEFAULT = 0.15;

// Vignette
static const float VIGNETTE_MIN = 0.0;
static const float VIGNETTE_MAX = 5.0;
static const float VIGNETTE_DEFAULT = 1.5;


// ============================================================================
// UI UNIFORMS
// ============================================================================
// 1. General Settings
uniform float QualityPercent < ui_type = "slider"; ui_label = "Brush Quality Percent"; ui_min = QUALITY_PERCENT_MIN; ui_max = QUALITY_PERCENT_MAX; ui_step = 1.0; ui_category = "General Settings"; ui_tooltip = "Adjusts the overall detail and number of brush strokes."; > = QUALITY_PERCENT_DEFAULT;

// 2. Source Image Adjustments
uniform float SrcContrast < ui_type = "slider"; ui_label = "Source Contrast"; ui_min = SRCCONTRAST_MIN; ui_max = SRCCONTRAST_MAX; ui_step = 0.01; ui_category = "Source Image"; ui_tooltip = "Adjusts the contrast of the underlying image used for stroke generation."; > = SRCCONTRAST_DEFAULT;
uniform float SrcBright < ui_type = "slider"; ui_label = "Source Brightness"; ui_min = SRCBRIGHT_MIN; ui_max = SRCBRIGHT_MAX; ui_step = 0.01; ui_category = "Source Image"; ui_tooltip = "Adjusts the brightness of the underlying image used for stroke generation."; > = SRCBRIGHT_DEFAULT;
uniform bool UseColorKeyBG < ui_label = "Enable Color Key BG"; ui_category = "Source Image"; ui_tooltip = "If enabled, replaces certain colors with the Background Texture."; > = false; // Corresponds to COLORKEY_BG
uniform bool UseCanvasEffect < ui_label = "Enable Canvas Effect"; ui_category = "Source Image"; ui_tooltip = "Adds a subtle canvas texture to the background."; > = false; // Corresponds to CANVAS

// 3. Brush Settings
uniform float BrushDetail < ui_type = "slider"; ui_label = "Brush Detail"; ui_min = BRUSHDETAIL_MIN; ui_max = BRUSHDETAIL_MAX; ui_step = 0.01; ui_category = "Brush"; ui_tooltip = "Controls the level of detail captured by brush strokes (higher value = more detail)."; > = BRUSHDETAIL_DEFAULT;
uniform float DepthDetailInfluence < ui_type = "slider"; ui_label = "Depth Detail Influence"; ui_min = DEPTH_DETAIL_INFLUENCE_MIN; ui_max = DEPTH_DETAIL_INFLUENCE_MAX; ui_step = 0.01; ui_category = "Brush"; ui_tooltip = "Controls how much depth affects brush detail. 0 = no influence, higher values = less detail at greater distances."; > = DEPTH_DETAIL_INFLUENCE_DEFAULT;
uniform float StrokeBend < ui_type = "slider"; ui_label = "Stroke Bend"; ui_min = STROKEBEND_MIN; ui_max = STROKEBEND_MAX; ui_step = 0.01; ui_category = "Brush"; ui_tooltip = "Controls the bending of individual brush strokes."; > = STROKEBEND_DEFAULT;
uniform float BrushSize < ui_type = "slider"; ui_label = "Brush Size Multiplier"; ui_min = BRUSHSIZE_MIN; ui_max = BRUSHSIZE_MAX; ui_step = 0.01; ui_category = "Brush"; ui_tooltip = "Multiplies the size of the generated brush strokes."; > = BRUSHSIZE_DEFAULT;

// 4. Animation Controls
AS_ANIMATION_UI(MasterTimeSpeed, MasterTimeKeyframe, "Global Animation")

// 5. Stage Controls
AS_STAGEDEPTH_UI(EffectDepth)

// 6. Relief Lighting Settings
uniform float PaintSpec < ui_type = "slider"; ui_label = "Paint Specularity"; ui_min = PAINTSPEC_MIN; ui_max = PAINTSPEC_MAX; ui_step = 0.01; ui_category = "Relief Lighting"; ui_tooltip = "Adjusts the intensity of specular highlights on the paint texture."; > = PAINTSPEC_DEFAULT;

// 7. Vignette Settings
uniform float Vignette < ui_type = "slider"; ui_label = "Vignette Intensity"; ui_min = VIGNETTE_MIN; ui_max = VIGNETTE_MAX; ui_step = 0.01; ui_category = "Vignette"; ui_tooltip = "Controls the strength of the darkening effect at the screen edges."; > = VIGNETTE_DEFAULT;


// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// N(v) is a 2D perpendicular vector (v.y, -v.x)
float2 N(float2 v) {
    return float2(v.y, -v.x);
}

// Get random value from AS_NoiseSampler based on UV coordinates
float4 getRand_uv(float2 pos) {
    return tex2Dlod(AS_NoiseSampler, float4(pos * ReShade::PixelSize, 0.0, 0.0));
}

// Get random value procedurally based on integer index using AS_hash functions
float4 getRand_idx(int idx) {
    float f_idx = float(idx);
    float h1 = AS_hash11(f_idx);
    float h2 = AS_hash11(f_idx + 1.0);
    float h3 = AS_hash11(f_idx + 2.0);
    float h4 = AS_hash11(f_idx + 3.0);
    return float4(h1, h2, h3, h4);
}

// Get color from the original image (BackBuffer) or background texture
// with depth masking awareness
float4 getCol(float2 pos, float lod) {
    float2 Res = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float2 Res0 = float2(BUFFER_WIDTH, BUFFER_HEIGHT); // iChannel0 is BackBuffer
    // Use declared constant dimensions for AS_BackgroundTexture
    float2 Res2 = float2(AS_BACKGROUND_TEXTURE_WIDTH, AS_BACKGROUND_TEXTURE_HEIGHT);

    // Scale UV for sampling source image based on aspect ratio
    float2 uv = (pos - 0.5 * Res) * min(Res0.y / Res.y, Res0.x / Res.x) / Res0 + 0.5;
    
    // Clamp UV to prevent sampling outside of [0,1]
    uv = saturate(uv);

    // Check if this pixel would be depth-masked
    float sampleDepth = ReShade::GetLinearizedDepth(uv);
    
    // If the sampled pixel is depth-masked, try to find a nearby unmasked pixel
    if(sampleDepth < EffectDepth - AS_DEPTH_EPSILON) {
        // Sample in a small spiral pattern to find a nearby unmasked pixel
        float2 spiralOffsets[8] = {
            float2(1, 0), float2(0, 1), float2(-1, 0), float2(0, -1),
            float2(1, 1), float2(-1, 1), float2(-1, -1), float2(1, -1)
        };
        
        float spiralRadius = 3.0 / min(Res.x, Res.y); // Small radius in UV space
        
        for(int i = 0; i < 8; i++) {
            float2 testUV = saturate(uv + spiralOffsets[i] * spiralRadius);
            float testDepth = ReShade::GetLinearizedDepth(testUV);
            
            if(testDepth >= EffectDepth - AS_DEPTH_EPSILON) {
                uv = testUV; // Use this unmasked pixel instead
                break;
            }
        }
        
        // If no unmasked pixel found nearby, expand the search
        if(sampleDepth < EffectDepth - AS_DEPTH_EPSILON) {
            spiralRadius *= 2.0;
            for(int i = 0; i < 8; i++) {
                float2 testUV = saturate(uv + spiralOffsets[i] * spiralRadius);
                float testDepth = ReShade::GetLinearizedDepth(testUV);
                
                if(testDepth >= EffectDepth - AS_DEPTH_EPSILON) {
                    uv = testUV;
                    break;
                }
            }
        }
    }

    float4 col = clamp(((tex2Dlod(ReShade::BackBuffer, float4(uv, 0.0, lod)) - 0.5) * SrcContrast + 0.5 * SrcBright), 0.0, 1.0);

    // Color keying for background
    if (UseColorKeyBG) {
        float2 uv_bg = (pos - 0.5 * Res) * min(Res2.y / Res.y, Res2.x / Res.x) / Res2 + 0.5;
        uv_bg = saturate(uv_bg);
        float4 bg = tex2Dlod(AS_BackgroundSampler, float4(uv_bg, 0.0, lod + 0.7));
        col = lerp(col, bg, dot(col.xyz, float3(-0.6, 1.3, -0.6))); // Use lerp
    }
    return col;
}

// Get value color for gradient calculation, with LOD bias
float3 getValCol(float2 pos, float lod) {
    // The lod bias log2(Res0.x/600.) attempts to keep LOD consistent regardless of resolution.
    float2 Res0 = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    return getCol(pos, 1.5 + log2(Res0.x / 600.0)).xyz;
}

// Compares absolute values of components and returns the component with the max absolute value
float compsignedmax(float3 c) {
    float3 s = sign(c);
    float3 a = abs(c);
    if (a.x > a.y && a.x > a.z) return c.x;
    if (a.y > a.x && a.y > a.z) return c.y;
    return c.z;
}

// Get gradient magnitude in two directions
float2 getGradMax(float2 pos, float eps) {
    float2 d = float2(eps, 0);
    float2 Res = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float2 Res0 = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    
    // Calc lod according to step size
    float lod = log2(2.0 * eps * Res0.x / Res.x);
    
    return float2(
        compsignedmax(getValCol(pos + d.xy, lod) - getValCol(pos - d.xy, lod)),
        compsignedmax(getValCol(pos + d.yx, lod) - getValCol(pos - d.yx, lod))
    ) / eps / 2.0;
}

// Quad for brush stroke geometry (used for determining point within stroke)
float2 quad(float2 p1, float2 p2, float2 p3, float2 p4, int idx) {
    float2 p[6] = {p1, p2, p3, p2, p4, p3};
    return p[idx % 6]; // Use modulo operator for integer indexing
}


// Get value from oil painting buffer for relief lighting
float getVal_local(float2 uv_val) {
    float2 Res = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    return length(tex2Dlod(OilPainting_Sampler, float4(uv_val, 0.0, 0.5 + 0.5 * log2(Res.x / AS_RESOLUTION_BASE_WIDTH))).xyz) * 1.0;
}

// Get gradient from oil painting buffer
float2 getGrad_local(float2 uv_grad, float delta) {
    float2 d = float2(delta, 0);
    return float2(
        getVal_local(uv_grad + d.xy) - getVal_local(uv_grad - d.xy),
        getVal_local(uv_grad + d.yx) - getVal_local(uv_grad - d.yx)
    ) / delta;
}

// ============================================================================
// PIXEL SHADERS
// ============================================================================

// Pass 1: Apply Oil Painting Effect (Buffer A logic)
float4 PS_OilPaintingDrawing(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Check depth masking first
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    if(sceneDepth < EffectDepth - AS_DEPTH_EPSILON)
    {
        // Return the original color if depth check fails
        return tex2D(ReShade::BackBuffer, texcoord);
    }

    float2 fragCoord_px = texcoord * float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float2 Res = float2(BUFFER_WIDTH, BUFFER_HEIGHT);

    float2 current_pos = fragCoord_px;
    
    // Original shader applies an animation to the `pos` which is `fragCoord`
    float animTime = AS_getAnimationTime(MasterTimeSpeed, MasterTimeKeyframe);
    current_pos += 4.0 * sin(animTime * ANIMATION_BASE_SPEED * float2(1, 1.7)) * Res.y / 400.0;
    
    float canv = 0.0;
    if (UseCanvasEffect) {
        canv = max(canv, (getRand_uv(current_pos * float2(0.7, 0.03))).x);
        canv = max(canv, (getRand_uv(current_pos * float2(0.03, 0.7))).x);
    }
    float4 fragColor = float4((0.93 + 0.07 * canv).xxx, 1.0); // Base canvas color
    canv -= 0.5;

    int pidx0 = 0;
    
    float layerScaleFact = QualityPercent / 100.0;

    // Number of grid positions on highest detail level
    int NumGrid = int(float(0x10000 / 2) * min(pow(Res.x / AS_RESOLUTION_BASE_WIDTH, 0.5), 1.0) * (1.0 - layerScaleFact * layerScaleFact));
    
    float aspect = Res.x / Res.y;
    int NumX = int(sqrt(float(NumGrid) * aspect) + 0.5);
    int NumY = int(sqrt(float(NumGrid) / aspect) + 0.5);
    
    // Calc max layer: NumY*layerScaleFact^maxLayer==10. - so min-scale layer has at least 10 strokes in y
    int maxLayer = int(log2(10.0 / float(NumY)) / log2(layerScaleFact));
    
    for (int layer = min(maxLayer, 11); layer >= 0; layer--) {
        int NumX2 = int(float(NumX) * pow(layerScaleFact, float(layer)) + 0.5);
        int NumY2 = int(float(NumY) * pow(layerScaleFact, float(layer)) + 0.5);

        for (int ni = 0; ni < 9; ni++) {
            int nx = (ni % 3) - 1;
            int ny = ni / 3 - 1;
            
            // Index centered in cell
            int n0 = int(dot(floor(current_pos / Res.xy * float2(NumX2, NumY2)), float2(1, NumX2)));
            int pidx2 = n0 + NumX2 * ny + nx;
            int pidx = pidx0 + pidx2;
            
            float3 brushPos;
            brushPos.xy = (float2(pidx2 % NumX2, pidx2 / NumX2) + 0.5) / float2(NumX2, NumY2) * Res;
            
            float gridW = Res.x / float(NumX2);
            float gridW0 = Res.x / float(NumX);
            
            // Add some noise to grid pos
            brushPos.xy += gridW * (getRand_idx(pidx + int(animTime * 123.0)).xy - 0.5);
            
            // More trigonal grid by displacing every 2nd line
            brushPos.x += gridW * 0.5 * (AS_mod(float(pidx2) / float(NumY2), 2.0) - 0.5);
            
            float2 g = getGradMax(brushPos.xy, gridW * 1.0) * 0.5 + getGradMax(brushPos.xy, gridW * 0.12) * 0.5
                       + 0.0003 * sin(current_pos / Res * 20.0); // Add some gradient to plain areas
            float gl = length(g);
            float2 n = normalize(g);
            float2 t = N(n); // Perpendicular vector

            brushPos.z = 0.5;

            // Width and length of brush stroke
            float wh = (gridW - 0.6 * gridW0) * 1.2;
            float lh = wh;
            float stretch = sqrt(1.5 * pow(3.0, 1.0 / float(layer + 1)));
            wh *= BrushSize * (0.8 + 0.4 * getRand_idx(pidx).y) / stretch;
            lh *= BrushSize * (0.8 + 0.4 * getRand_idx(pidx).z) * stretch;
            float wh0 = wh;
            
            wh /= (1.0 - 0.25 * abs(StrokeBend));
            
            // Calculate effective brush detail (potentially depth-based)
            float effectiveBrushDetail = BrushDetail;
            if (DepthDetailInfluence > 0.0) {
                // Sample depth at brush position
                float2 brushUV = brushPos.xy / Res;
                brushUV = saturate(brushUV);
                float brushDepth = ReShade::GetLinearizedDepth(brushUV);
                
                // Scale brush detail based on depth and influence strength
                // At DepthDetailInfluence = 1.0, far objects (depth = 1) get 50% detail
                // At DepthDetailInfluence = 2.0, far objects (depth = 1) get 25% detail
                float depthScale = lerp(1.0, 1.0 - (DepthDetailInfluence * 0.5), saturate(brushDepth));
                effectiveBrushDetail *= depthScale;
            }
            
            wh = (gl * effectiveBrushDetail < 0.003 / wh0 && wh0 < Res.x * 0.02 && layer != maxLayer) ? 0.0 : wh;
            
            float2 uv = float2(dot(current_pos - brushPos.xy, n), dot(current_pos - brushPos.xy, t)) / float2(wh, lh) * 0.5;
            
            // Bending the brush stroke
            uv.x -= 0.125 * StrokeBend;
            uv.x += uv.y * uv.y * StrokeBend;
            uv.x /= (1.0 - 0.25 * abs(StrokeBend));
            uv += 0.5;
            
            float s = 1.0;
            s *= uv.x * (1.0 - uv.x) * 6.0;
            s *= uv.y * (1.0 - uv.y) * 6.0;
            
            float s0 = s;
            s = clamp((s - 0.5) * 2.0, 0.0, 1.0);
            float2 uv0 = uv;
            
            // Brush hair noise
            float pat = tex2Dlod(AS_NoiseSampler, float4(uv * 1.5 * sqrt(Res.x / 600.0) * float2(0.06, 0.006), 0.0, 1.0)).x
                        + tex2Dlod(AS_NoiseSampler, float4(uv * 3.0 * sqrt(Res.x / 600.0) * float2(0.06, 0.006), 0.0, 1.0)).x;
            float4 rnd = getRand_idx(pidx);
            
            s0 = s;
            s *= 0.7 * pat;
            uv0.y = 1.0 - uv0.y;
            float smask = clamp(max(cos(uv0.x * AS_PI * 2.0 + 1.5 * (rnd.x - 0.5)), (1.5 * exp(-uv0.y * uv0.y / 0.15 / 0.15) + 0.2) * (1.0 - uv0.y)) + 0.1, 0.0, 1.0);
            s += s0 * smask;
            s -= 0.5 * uv0.y;
            
            if (UseCanvasEffect) { // Corresponds to #ifdef CANVAS
                s += (1.0 - smask) * canv * 1.0;
                s += (1.0 - smask) * (getRand_uv(current_pos * 0.7).z - 0.5) * 0.5;
            }
            
            float4 dfragColor;
            dfragColor.xyz = getCol(brushPos.xy, 1.0).xyz * lerp(s * 0.13 + 0.87, 1.0, smask); // Use lerp
            s = clamp(s, 0.0, 1.0);
            dfragColor.w = s * step(-0.5, -abs(uv0.x - 0.5)) * step(-0.5, -abs(uv0.y - 0.5));
            
            // Do alpha blending
            fragColor = lerp(fragColor, dfragColor, dfragColor.w); // Use lerp
        }
        pidx0 += NumX2 * NumY2;
    }
    return fragColor;
}

// Pass 2: Apply Relief Lighting (Image logic)
float4 PS_OilPaintingRelief(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Check depth masking first
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    if(sceneDepth < EffectDepth - AS_DEPTH_EPSILON)
    {
        // Return the original color if depth check fails
        return tex2D(ReShade::BackBuffer, texcoord);
    }

    float2 fragCoord_px = texcoord * float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float2 Res = float2(BUFFER_WIDTH, BUFFER_HEIGHT);

    float2 uv = texcoord;
    float3 n = float3(getGrad_local(uv, 1.0 / Res.y), 150.0);
    n = normalize(n);
    
    float4 fragColor_debug_normal = float4(n, 1.0); // For debugging normals, not final output.

    float3 light = normalize(float3(-1, 1, 1.4));
    float diff = clamp(dot(n, light), 0.0, 1.0);
    float spec = clamp(dot(reflect(light, n), float3(0, 0, -1)), 0.0, 1.0);
    spec = pow(spec, 12.0) * PaintSpec;
    
    float sh = clamp(dot(reflect(light * float3(-1, -1, 1), n), float3(0, 0, -1)), 0.0, 1.0);
    sh = pow(sh, 4.0) * 0.1;
    
    // Combine original texture, diffuse, specular, and shadow
    float4 finalColor = tex2D(OilPainting_Sampler, uv) * lerp(diff, 1.0, 0.9) // Use lerp
                + spec * float4(0.85, 1.0, 1.15, 1.0)
                + sh * float4(0.85, 1.0, 1.15, 1.0);
    finalColor.w = 1.0;
    
    // Vignette calculation
    float2 scc = (fragCoord_px - 0.5 * Res) / Res.x;
    float vign = 1.1 - Vignette * dot(scc, scc);
    vign *= 1.0 - 0.7 * Vignette * exp(-sin(fragCoord_px.x / Res.x * AS_PI) * 40.0); // Use AS_PI
    vign *= 1.0 - 0.7 * Vignette * exp(-sin(fragCoord_px.y / Res.y * AS_PI) * 20.0); // Use AS_PI
    finalColor.xyz *= vign;

    return finalColor;
}


// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_GFX_OilPainting <
    ui_label = "[AS] GFX: Oil Painting";
    ui_tooltip = "Creates an artistic oil paint brush drawing effect with relief lighting and canvas texture.";
>
{
    // Pass 1: Applies the oil paint brush drawing effect
    // Output to OilPainting_Buffer
    pass OilPaintingDrawingPass {
        VertexShader = PostProcessVS;
        PixelShader = PS_OilPaintingDrawing;
        RenderTarget = OilPainting_Buffer;
    }

    // Pass 2: Applies relief lighting and vignette to the drawing
    // Output to ReShade::BackBuffer (final screen)
    pass OilPaintingReliefPass {
        VertexShader = PostProcessVS;
        PixelShader = PS_OilPaintingRelief;
    }
}

#endif // __AS_GFX_OilPainting_1_fx