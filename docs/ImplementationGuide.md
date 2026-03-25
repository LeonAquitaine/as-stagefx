# AS StageFX Implementation Guide

## Quick Start - Use the Templates

Start with the comprehensive templates in `docs/template/`:

- `README.md` - Quick start guide and template overview
- `shader-template.fx` - Complete template with all features
- `bgx-template.fx` - Background effects template
- `vfx-template.fx` - Visual effects template
- `lfx-template.fx` - Lighting effects template
- `gfx-template.fx` - Graphics/post-processing template

**Workflow:**
1. Copy the appropriate template for your effect type
2. Replace placeholders (marked with `[BRACKETS]`)
3. Implement your effect algorithm in the marked sections
4. Test and validate using the built-in debug modes

---

## Critical Requirements

**Essential Dependencies**: `AS_Utils.1.fxh`, `ReShade.fxh`

### Non-Negotiable Standards

1. **Single-line uniforms** -- parsing tools require all uniform declarations on one line
2. **Technique guards** -- `#ifndef __AS_TypeCode_ShaderName_1_fx`
3. **Named constants** for all UI min/max/default values (no magic numbers)
4. **Resolution independence** across all screen sizes and aspect ratios
5. **Shader-prefixed textures** -- `ShaderName_TextureName` to prevent conflicts
6. **AS_Utils constants** -- `AS_PI`, `AS_TWO_PI`, `AS_DEPTH_EPSILON` instead of literals

### Shader Descriptor

Every shader must include a descriptor uniform for identification in the ReShade panel. The descriptor appears at the top of the shader's parameter panel in ReShade — it's the first thing users see.

**For original shaders** — include the effect name + a short user-friendly description:

```hlsl
uniform int as_shader_descriptor <ui_type = "radio"; ui_label = " "; ui_text = "AS StageFX | Light Wrap | Bleeds background light around foreground subject edges for natural compositing glow. | by Leon Aquitaine"; > = 0;
```

**For ported effects** — include attribution and license information:

```hlsl
uniform int as_shader_descriptor <ui_type = "radio"; ui_label = " "; ui_text = "AS StageFX | Cosmic Storm | Adapted from 'Star Nest' by Pablo Roman Andrioli (Shadertoy). License: MIT. | by Leon Aquitaine"; > = 0;
```

### Writing Good Shader Descriptions

The description in `ui_text` should explain what the effect does **in visual terms**, not technical terms. The target audience is a photographer or content creator, not a graphics programmer.

| Bad (technical) | Good (visual) |
|-----------------|---------------|
| "3-pass separable Gaussian with luminance-weighted midtone blending" | "Adds a soft, dreamy glow to skin and fabric while keeping edges crisp" |
| "Applies per-channel gamma/gain curve remapping" | "Simulates the wild color shifts of developing film in the wrong chemicals" |
| "Depth-buffer Fresnel-weighted additive composite" | "Bleeds background light around subject edges, like real backlight on a film set" |
| "Procedural FBM noise with animated UV offset" | "Warm blobs of light drift across the frame, like light leaking into an analog camera" |

Aim for 1-2 sentences that answer: **"What will this do to my screenshot?"**

### Common Constants and Ranges

```hlsl
// Mathematical constants (ALWAYS use these):
AS_PI, AS_TWO_PI, AS_HALF_PI, AS_QUARTER_PI
AS_EPSILON, AS_DEPTH_EPSILON (0.0005), AS_EDGE_AA (0.05)
AS_HALF, AS_QUARTER, AS_THIRD, AS_TWO_THIRDS

// Standard UI ranges from AS_Utils.1.fxh:
AS_POSITION_MIN/MAX: -1.5f to 1.5f
AS_SCALE_MIN/MAX: 0.1f to 5.0f
AS_ANIMATION_SPEED_MIN/MAX: 0.0f to 5.0f
AS_RANGE_BLEND_MIN/MAX: 0.0f to 1.0f
AS_RANGE_AUDIO_MULT_MIN/MAX: 0.0f to 2.0f

// Standard parameter ranges:
Pattern Scale: 0.1 to 10.0 (step 0.01)
Pattern Offset: -2.0 to 2.0 (step 0.01)
Glow/Blur: 0.0 to 5.0 (step 0.01)
Intensity/Strength: 0.0 to 4.0 (step 0.05)
Rotation: -180.0 to 180.0 (step 0.1)
```

### Uniform Declaration Rules

```hlsl
// CORRECT - Single line with named constants
static const float RADIUS_MIN = 0.1;
static const float RADIUS_MAX = 1.0;
static const float RADIUS_DEFAULT = 0.5;
uniform float Radius < ui_type = "slider"; ui_label = "Radius"; ui_min = RADIUS_MIN; ui_max = RADIUS_MAX; ui_category = "Pattern"; > = RADIUS_DEFAULT;

// INCORRECT - Multi-line breaks parsing tools
uniform float Radius <
    ui_type = "slider";
    ui_label = "Radius";
    ui_min = 0.1; ui_max = 1.0;
> = 0.5;
```

---

## File Structure (Required Order)

```hlsl
/**
 * Filename.fx - Brief Description
 * Author: Name | License: CC BY 4.0
 * DESCRIPTION: What the effect does
 * FEATURES: Key capabilities
 * IMPLEMENTATION: Technical approach
 */

#ifndef __AS_TypeCode_ShaderName_Version_fx
#define __AS_TypeCode_ShaderName_Version_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// 1. TUNABLE CONSTANTS (with named MIN/MAX/DEFAULT)
// 2. PALETTE & STYLE
// 3. EFFECT-SPECIFIC APPEARANCE
// 4. ANIMATION CONTROLS
// 5. AUDIO REACTIVITY
// 6. STAGE/POSITION CONTROLS
// 7. FINAL MIX
// 8. DEBUG (optional)

// Shader code...

#endif // __AS_TypeCode_ShaderName_Version_fx
```

### Type Codes

- **BGX** -- Backgrounds (full-screen generative)
- **VFX** -- Visual effects (overlays, distortions, particles)
- **LFX** -- Lighting effects (spotlights, glow, flames)
- **GFX** -- Graphics/post-processing (filters, color grading, stylization)

### Namespace Convention

Use `namespace AS_EffectName { }` (underscore after AS) for shaders with 5 or more helper functions. This prevents symbol collisions when multiple shaders are loaded:

```hlsl
namespace AS_MeltWave {
    // All helper functions, constants, and pixel shaders here
    float helperFunc(...) { ... }
    float4 PS_Main(...) { ... }
} // namespace AS_MeltWave
```

---

## Spatial Mode Classification

Different shader types use different subsets of the standard feature set. Understanding which mode your effect falls into determines which UI controls and utilities to include.

### Mode A: Full-Screen Generator (BGX)

Background effects that generate imagery covering the full screen. All standard features apply.

**Features**: position, scale, rotation, animation, audio, palette, depth, blend

**Examples**: BlueCorona, Constellation, CosmicKaleidoscope, ProteanClouds

### Mode B: Placed Overlay (some VFX, some GFX)

Effects that produce a visual element positioned on screen. Position and scale are meaningful; rotation is sometimes applicable.

**Features**: position, scale, rotation (sometimes), animation, audio, palette, depth, blend

**Examples**: ScreenRing, SpectrumRing, BoomSticker, CircularSpectrum

### Mode C: Scene Filter (GFX post-processing)

Post-processing effects that modify the existing scene image. Position and scale are rarely meaningful. No palette typically -- they modify existing colors rather than generating new ones.

**Features**: blend, depth (sometimes), audio (sometimes), animation (sometimes)

**Examples**: CinematicDiffusion, TiltShift, HandDrawing, BrushStroke, MultiLayerHalftone

### Mode D: Temporal/Accumulation (MotionTrails)

Effects that accumulate data across frames using ping-pong buffers. Position, scale, and rotation do not apply since the effect operates on the full scene history.

**Features**: depth, audio, blend -- NO position/scale/rotation

**Examples**: MotionTrails, MotionFocus

### Mode E: Multi-Instance (Spotlights, Stickers, Flames)

Effects with multiple independent copies, each with its own position and parameters. Global controls (audio, blend) apply to all instances.

**Features**: per-instance position/scale/enable, global audio, global blend/depth

**Examples**: StageSpotlights, BoomSticker (multi), CandleFlame

---

## Category Constants and Ordering

Use `AS_CAT_*` constants for all `ui_category` values. Never use hardcoded category strings.

```hlsl
AS_CAT_PALETTE      // "Palette & Style"
AS_CAT_APPEARANCE   // "Appearance"
AS_CAT_PATTERN      // "Pattern"
AS_CAT_LIGHTING     // "Lighting"
AS_CAT_COLOR        // "Color"
AS_CAT_ANIMATION    // "Animation"
AS_CAT_AUDIO        // "Audio Reactivity"
AS_CAT_STAGE        // "Stage"
AS_CAT_PERFORMANCE  // "Performance"
AS_CAT_FINAL        // "Final Mix"
AS_CAT_DEBUG        // "Debug"
```

### Canonical Ordering (top to bottom in ReShade panel)

1. **Effect-specific categories** -- descriptive names like "Pattern", "Fractal", "Grid" (come FIRST)
2. `AS_CAT_PALETTE` -- Color palette and style controls
3. `AS_CAT_APPEARANCE` -- Visual appearance tuning
4. `AS_CAT_ANIMATION` -- Animation speed, keyframe, sway
5. `AS_CAT_AUDIO` -- Audio reactivity source and intensity
6. `AS_CAT_STAGE` -- Stage depth, position, rotation, scale
7. `AS_CAT_PERFORMANCE` -- Quality, iteration count, resolution
8. `AS_CAT_FINAL` -- Blend mode and blend strength
9. `AS_CAT_DEBUG` -- Debug visualization modes

---

## Complete Macro Reference

### Position and Stage Controls

```hlsl
AS_POS_UI(name)
// Position drag control, float2, range [-1.5, 1.5], category AS_CAT_STAGE

AS_SCALE_UI(name)
// Scale slider, float, range [0.1, 5.0], category AS_CAT_STAGE

AS_POSITION_SCALE_UI(posName, scaleName)
// Combined position + scale (convenience macro)

AS_STAGEDEPTH_UI(name)
// Stage depth slider, float, range [0.0, 1.0], category AS_CAT_STAGE

AS_ROTATION_UI(snapName, fineName)
// Snap rotation (45-degree steps, int -4..4) + fine rotation (float -45..45 degrees)
// Both in AS_CAT_STAGE, fine rotation on same line as snap
```

### Animation Controls

```hlsl
AS_ANIMATION_SPEED_UI(name, category)
// Animation speed slider, range [0.0, 5.0], default 1.0

AS_ANIMATION_KEYFRAME_UI(name, category)
// Animation keyframe slider, range [0.0, 100.0], default 0.0

AS_ANIMATION_UI(speedName, keyframeName, category)
// Combined speed + keyframe (convenience macro)

AS_SWAYSPEED_UI(name, category)
// Sway speed slider, range [0.0, 5.0], default 1.0

AS_SWAYANGLE_UI(name, category)
// Sway angle slider, range [0.0, 180.0], default 15.0
```

### Audio Reactivity Controls

```hlsl
AS_AUDIO_UI(name, label, defaultSource, category)
// Audio source combo box. Items: Off/Solid/Volume/Beat/Bass/Treble/Mid/VolumeLeft/VolumeRight/Pan

AS_AUDIO_MULT_UI(name, label, defaultValue, maxValue, category)
// Audio intensity slider, range [0.0, maxValue], step 0.05

AS_AUDIO_TARGET_UI(name, items, defaultTarget)
// Audio target combo, lets user choose which parameter responds to audio.
// Category is always AS_CAT_AUDIO. Provide custom items string.

AS_AUDIO_GAIN_UI(name, label, maxValue, defaultValue)
// Per-parameter audio gain slider, range [0.0, maxValue], step 0.01
// Category is always AS_CAT_AUDIO.

AS_AUDIO_STEREO_UI(name, label, defaultSource, category)
// Stereo-aware audio source combo box (same items as AS_AUDIO_UI)

AS_STEREO_POSITION_UI(name, category)
// Stereo position slider, range [-1.0, 1.0], step 0.01

AS_AUDIO_STEREO_FULL_UI(sourceName, posName, multName, label, defaultSource, category)
// Combined stereo source + position + multiplier (three uniforms in one macro)
```

### Palette and Color Controls

```hlsl
AS_PALETTE_SELECTION_UI(name, label, default, category)
// Palette selection combo (from AS_Palette.1.fxh)

AS_DECLARE_CUSTOM_PALETTE(prefix, category)
// Declares custom 5-color palette uniforms (from AS_Palette.1.fxh)

AS_USE_PALETTE_UI(name, category)
// Boolean toggle: "Use Palette Coloring" vs mathematical coloring. Default false.

AS_COLOR_CYCLE_UI(name, category)
// Color cycle speed slider, range [-2.0, 2.0], step 0.1, default 0.0
// Negative = reverse direction, 0 = static.

AS_BACKGROUND_COLOR_UI(name, defaultColor, category)
// Background color picker (float3). For effects that replace the scene.
```

### Blending and Final Mix Controls

```hlsl
AS_BLENDMODE_UI(name)
// Blend mode combo, default Normal (0)

AS_BLENDMODE_UI_DEFAULT(name, mode)
// Blend mode combo with specific default (e.g., AS_BLEND_LIGHTEN)

AS_BLENDAMOUNT_UI(name)
// Blend strength slider, range [0.0, 1.0], default 1.0, category AS_CAT_FINAL
```

### Debug Controls

```hlsl
AS_DEBUG_UI(items)
// Debug mode combo with custom items string, category AS_CAT_DEBUG
```

### Texture and Sampler Creation

```hlsl
AS_CREATE_TEXTURE(TEXTURE_NAME, SIZE_XY, FORMAT_TYPE, MIP_LEVELS)
AS_CREATE_SAMPLER(SAMPLER_NAME, TEXTURE_RESOURCE, FILTER_TYPE, ADDRESS_MODE)
AS_CREATE_TEX_SAMPLER(TEXTURE_NAME, SAMPLER_NAME, SIZE_XY, FORMAT_TYPE, MIP_LEVELS, FILTER_TYPE, ADDRESS_MODE)
```

---

## Coordinate System and Naming Convention

### Standard Coordinate Names

Use these names consistently across all shaders:

| Name | Meaning |
|------|---------|
| `texcoord` | Raw input UV from vertex shader, range [0, 1] |
| `uvCentered` | Centered coordinates, (0,0) = screen center |
| `uvAspect` | Centered + aspect-ratio corrected (circles are circular) |
| `uvTransformed` | After position, scale, and/or rotation applied |
| `uvPolar` | Polar coordinates: .x = angle (radians), .y = radius |

### Utility Functions

```hlsl
// Center and aspect-correct UVs
float2 uvAspect = AS_centeredUVWithAspect(texcoord, ReShade::AspectRatio);

// Rotate a 2D point around the origin
float2 rotated = AS_rotate2D(point, angleRadians);

// Apply position offset and scale to centered coordinates
float2 positioned = AS_applyPositionAndScale(uvAspect, pos, scale);

// All-in-one: center + aspect + position + scale + rotation
float2 uvTransformed = AS_transformUVCentered(texcoord, pos, scale, rotation);

// Get rotation in radians from snap + fine UI values
float rotation = AS_getRotationRadians(SnapRotation, FineRotation);

// Compute polar angle and radius from texcoord
float2 uvPolar = AS_polarAngleRadius(texcoord, ReShade::AspectRatio);
```

### Resolution Independence

Always use `AS_transformUVCentered` or the individual helper functions. Never implement custom coordinate transforms manually.

```hlsl
// CORRECT:
float2 uv = AS_transformUVCentered(texcoord, EffectCenter, EffectScale, globalRotation);

// WRONG: manual aspect ratio handling
float2 centered = texcoord - 0.5;
centered.x *= aspectRatio;
```

### Validation Test Cases

| UI Position | Expected Result |
|-------------|----------------|
| (-1, -1) | Top-left of central square |
| (0, 0) | Exact screen center |
| (+1, +1) | Bottom-right of central square |

---

## Compositing Pattern

The correct pattern for depth-aware compositing in pixel shaders:

```hlsl
float4 PS_Main(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // 1. Read original scene
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);

    // 2. Depth check (early return)
    if (AS_isInFrontOfStage(texcoord, EffectDepth))
        return originalColor;

    // 3. Compute effect
    float3 effectColor = computeEffect(texcoord, time, ...);

    // 4. For additive effects (light, glow): ADD to scene, never darken
    float3 wrappedScene = originalColor.rgb + effectLight;

    // 5. User's BlendMode/BlendAmount controls the final mix
    // NEVER use BlendMode for the core effect operation -- it belongs to the user
    float3 result = AS_composite(wrappedScene, originalColor.rgb, BlendMode, BlendAmount);
    return float4(result, originalColor.a);
}
```

The `AS_DEPTH_EARLY_RETURN` macro combines steps 1 and 2:

```hlsl
AS_DEPTH_EARLY_RETURN(texcoord, EffectDepth)
// After this, _as_originalColor is available as float4
```

### Compositing Functions

```hlsl
// RGB blend + lerp in one call
float3 AS_composite(effectRgb, bgRgb, blendMode, blendAmount);

// RGBA variant (preserves background alpha)
float4 AS_compositeRGBA(effectRgb, bgRgba, blendMode, blendAmount);

// Low-level blend (foreground over background)
float3 AS_blendRGB(fgRgb, bgRgb, mode);
float4 AS_blendRGBA(fgRgba, bgRgba, mode, opacity);
```

---

## Multi-Pass Shader Pattern

### RenderTarget Declarations

```hlsl
texture ShaderName_Buffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler ShaderName_BufferSampler { Texture = ShaderName_Buffer; };
```

All textures and samplers MUST be prefixed with the shader name to prevent naming conflicts.

### Named Pass Blocks

```hlsl
technique AS_VFX_EffectName {
    pass HorizontalBlur {
        VertexShader = PostProcessVS;
        PixelShader = PS_BlurH;
        RenderTarget = ShaderName_TempBuffer;
    }
    pass VerticalBlur {
        VertexShader = PostProcessVS;
        PixelShader = PS_BlurV;
    }
}
```

### Common Multi-Pass Patterns

**Separable Gaussian Blur** (H pass to buffer, V pass to output):
Used by FocusFrame and similar effects. Split 2D blur into two 1D passes for O(n) instead of O(n^2).

```hlsl
texture ShaderName_BlurH { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler ShaderName_BlurHSampler { Texture = ShaderName_BlurH; };

float4 PS_BlurHorizontal(...) : SV_Target {
    // Sample horizontally from BackBuffer, write to BlurH buffer
    float3 colorSum = 0; float totalWeight = 0;
    for (int i = -RADIUS; i <= RADIUS; i++) {
        float weight = gaussWeight(i);
        colorSum += tex2D(ReShade::BackBuffer, tc + float2(i * px, 0)).rgb * weight;
        totalWeight += weight;
    }
    return float4(colorSum / totalWeight, 1.0);
}

float4 PS_BlurVertical(...) : SV_Target {
    // Sample vertically from BlurH buffer, write to output
    float3 colorSum = 0; float totalWeight = 0;
    for (int i = -RADIUS; i <= RADIUS; i++) {
        float weight = gaussWeight(i);
        colorSum += tex2D(ShaderName_BlurHSampler, tc + float2(0, i * py)).rgb * weight;
        totalWeight += weight;
    }
    return float4(colorSum / totalWeight, 1.0);
}
```

**Bloom Pyramid Downsampling** (CinematicDiffusion pattern):
Successive downscale passes extract and blur bright areas. Each pass reads from the previous and writes to a smaller buffer.

**Ping-Pong Accumulation** (MotionTrails, RadiantFire pattern):
Two buffers alternate roles each frame. The current frame reads from buffer A, blends with new data, and writes to buffer B. Next frame the roles swap. Used for temporal effects.

```hlsl
texture ShaderName_AccumA { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
texture ShaderName_AccumB { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
// Passes alternate: read A write B, then read B write A
```

**Mask, Blur, Composite** (LightWrap pattern):
First pass generates a mask, second pass blurs it, third pass composites the blurred mask with the scene.

### Alpha-Weighted Blur

When blurring content with varying alpha (e.g., particles over transparent background), use alpha-weighted accumulation to prevent dark halos:

```hlsl
float3 colorSum = 0;
float alphaWeightSum = 0;
float totalWeight = 0;

for (int i = -RADIUS; i <= RADIUS; i++) {
    float4 s = tex2D(sampler, tc + offset * i);
    float w = gaussWeight(i);
    colorSum += s.rgb * s.a * w;  // weight color by alpha
    alphaWeightSum += s.a * w;
    totalWeight += w;
}

float3 finalColor = colorSum / max(alphaWeightSum, AS_EPSILON);
float finalAlpha = alphaWeightSum / max(totalWeight, AS_EPSILON);
```

### Texture Formats

| Format | Use Case |
|--------|----------|
| `RGBA8` | Standard color buffers, masks |
| `RGBA16F` | HDR intermediate buffers, bloom, accumulation |
| `RG32F` | Temporal data, motion vectors, 2-component float data |
| `R32F` | Scalar values, depth, single-channel data |

---

## Standard Animation Pattern

```hlsl
// UI controls
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, AS_CAT_ANIMATION)

// Time calculation in pixel shader
float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);

// With audio-reactive speed
float animSpeed = AnimationSpeed;
if (AudioTarget == TARGET_ANIMATION_SPEED) {
    animSpeed = AS_audioModulate(AnimationSpeed, AudioSource, AudioMultiplier, true, 0);
}
time = AS_getAnimationTime(animSpeed, AnimationKeyframe);
```

---

## Palette Integration

### UI Declaration

```hlsl
AS_PALETTE_SELECTION_UI(PaletteSelection, "Effect Palette", AS_PALETTE_CUSTOM, AS_CAT_PALETTE)
AS_DECLARE_CUSTOM_PALETTE(EffectName_, AS_CAT_PALETTE)
```

### Color Retrieval

Use the `AS_GET_PALETTE_COLOR` macro to eliminate repeated if/else:

```hlsl
float3 color = AS_GET_PALETTE_COLOR(EffectName_, PaletteSelection, paletteValue);
```

Or manually:

```hlsl
float3 effectColor;
if (PaletteSelection == AS_PALETTE_CUSTOM) {
    effectColor = AS_GET_INTERPOLATED_CUSTOM_COLOR(EffectName_, paletteValue);
} else {
    effectColor = AS_getInterpolatedColor(PaletteSelection, paletteValue);
}
```

### Palette Value Examples

- Linear: `float paletteValue = saturate(distance / maxDistance);`
- Audio: `float paletteValue = saturate(audioAmplitude);`
- Angular: `float paletteValue = saturate(angle / AS_TWO_PI);`

---

## Audio Reactivity Standards

### Key Principles

- Use AS_Utils macros -- do not check for Listeningway directly
- Effects must work gracefully without Listeningway installed
- Always set the enable parameter to `true` in audio functions
- Use standard UI macros for consistency

### Standard Audio Controls

```hlsl
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_BEAT, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(AudioMultiplier, "Audio Intensity", 1.0, 2.0, AS_CAT_AUDIO)

// In pixel shader
float modulated = AS_audioModulate(baseValue, AudioSource, AudioMultiplier, true, 0);
```

### Audio Source Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `AS_AUDIO_OFF` | 0 | No reactivity |
| `AS_AUDIO_SOLID` | 1 | Constant value (always 1.0) |
| `AS_AUDIO_VOLUME` | 2 | Overall volume |
| `AS_AUDIO_BEAT` | 3 | Beat detection |
| `AS_AUDIO_BASS` | 4 | Low frequency band |
| `AS_AUDIO_TREBLE` | 5 | High frequency band |
| `AS_AUDIO_MID` | 6 | Mid frequency band |
| `AS_AUDIO_VOLUME_LEFT` | 7 | Left channel volume |
| `AS_AUDIO_VOLUME_RIGHT` | 8 | Right channel volume |
| `AS_AUDIO_PAN` | 9 | Audio pan (-1 to 1) |

### Audio Functions

```hlsl
// Get raw audio level from source
float level = AS_audioLevelFromSource(audioSource);

// Modulate a value by audio (mode 0 = multiplicative, mode 1 = additive)
float result = AS_audioModulate(baseValue, source, multiplier, enabled, mode);

// Multiplicative-only shorthand
float result = AS_audioModulateMul(baseValue, source, multiplier, enabled);

// Stereo-aware modulation
float result = AS_audioModulateMulStereo(baseValue, source, multiplier, stereoPos, enabled);

// Get stereo audio reactivity based on screen position
float level = AS_getStereoAudioReactivity(position, audioSource);

// Get audio direction as angle in radians
float dir = AS_getAudioDirectionRadians();
```

---

## Multi-Instance Effects Pattern

For effects supporting multiple copies (spotlights, layers, flames):

```hlsl
// 1. Define count and UI macro
static const int EFFECT_COUNT = 4;

#define EFFECT_UI(index, defaultEnable, defaultParam1) \
uniform bool Effect##index##_Enable < ui_label = "Enable " #index; ui_category = "Effect " #index; ui_category_closed = index > 1; > = defaultEnable; \
uniform float Effect##index##_Param1 < ui_category = "Effect " #index; > = defaultParam1;

// 2. Instantiate controls -- first enabled by default, others disabled and closed
EFFECT_UI(1, true, 1.0)
EFFECT_UI(2, false, 0.5)

// 3. Parameter structure
struct EffectParams {
    bool enable;
    float param1;
};

// 4. Getter function
EffectParams GetEffectParams(int index) {
    EffectParams params;
    if (index == 0) { params.enable = Effect1_Enable; params.param1 = Effect1_Param1; }
    // ... handle other indices
    return params;
}

// 5. Process in loop
for (int i = 0; i < EFFECT_COUNT; i++) {
    EffectParams params = GetEffectParams(i);
    if (!params.enable) continue;
    // Process effect using params structure
}
```

---

## Noise Library

### Core: AS_Noise.1.fxh

Include this for most effects. Provides:

- **Hash functions**: `AS_hash11`, `AS_hash21`, `AS_hash12`, `AS_hash22`, `AS_hash31`
- **Value noise**: `AS_ValueNoise2D`
- **Perlin noise**: `AS_PerlinNoise2D`, `AS_PerlinNoise3D`
- **Simplex noise**: `AS_SimplexNoise3D`
- **FBM**: `AS_Fbm2D`

### Extended: AS_Noise_Extended.1.fxh

Include only if you need specialized patterns. Automatically includes `AS_Noise.1.fxh`. Provides:

- **Animated variants**: `AS_ValueNoise2D_Animated`, `AS_PerlinNoise2D_Animated`, `AS_Fbm2D_Animated`
- **Voronoi/cellular noise**: `AS_VoronoiNoise2D`
- **Domain warping**: `AS_DomainWarp2D`
- **Turbulence and ridge noise**: sharp, layered effects
- **Pattern functions**: wood, marble, cloud, wave generators

### Selection Guidelines

| Need | Function |
|------|----------|
| Simple randomness | `AS_hash11`, `AS_hash21`, `AS_hash12` |
| Organic patterns | `AS_PerlinNoise2D` |
| Natural textures | `AS_Fbm2D` |
| Flowing effects | `AS_Fbm2D_Animated` (Extended) |
| Cell patterns | `AS_VoronoiNoise2D` (Extended) |
| Complex fluids | `AS_DomainWarp2D` (Extended) |

---

## Deprecated Functions

These legacy aliases are defined as shims in AS_Utils.1.fxh and will be removed in v2.0. Use the new names in all new code.

| Deprecated | Replacement |
|------------|-------------|
| `AS_applyAudioReactivity()` | `AS_audioModulate(..., 0)` |
| `AS_applyAudioReactivityEx()` | `AS_audioModulate()` |
| `AS_getAudioSource()` | `AS_audioLevelFromSource()` |
| `AS_getTime()` | `AS_timeSeconds()` |
| `AS_applyRotation()` | `AS_rotate2D()` |
| `AS_transformCoord()` | `AS_transformUVCentered()` |
| `AS_applyPosScale()` | `AS_applyPositionAndScale()` |

---

## Conversion Workflows

### GLSL to HLSL Mappings

```hlsl
vec2/vec3/vec4        -> float2/float3/float4
texture2D()           -> tex2D()
mix()                 -> lerp()
fract()               -> frac()
mod()                 -> AS_mod()
```

### Replace Patterns

```hlsl
// OLD: Shadertoy coordinates
vec2 uv = (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
// NEW: Standard transformation
float2 uv = AS_transformUVCentered(texcoord, EffectCenter, EffectScale, 0.0);

// OLD: Hard-coded time
float time = iTime;
// NEW: AS_Utils time
float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);

// OLD: Hard-coded colors
vec3 color = vec3(1.0, 0.5, 0.0);
// NEW: Palette system
float3 color = AS_GET_PALETTE_COLOR(EffectName_, PaletteSelection, paletteValue);
```

---

## Texture and Sampler Naming

All texture and sampler declarations MUST be prefixed with the shader name to prevent naming conflicts when multiple shaders are loaded simultaneously.

```hlsl
// CORRECT
texture RainyWindow_EffectBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler RainyWindow_EffectSampler { Texture = RainyWindow_EffectBuffer; AddressU = CLAMP; AddressV = CLAMP; };

// INCORRECT
texture EffectBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
```

**Naming pattern**: `ShaderName_TextureName` where `ShaderName` is the main part of the shader filename (e.g., for `AS_VFX_RainyWindow.1.fx`, use `RainyWindow_` prefix).

---

## Debug Controls Pattern

```hlsl
AS_DEBUG_UI("Off\0Pattern Only\0Audio Levels\0Depth Mask\0")

// In pixel shader
if (DebugMode == AS_DEBUG_PATTERN) {
    return float4(patternValue, patternValue, patternValue, 1.0);
}
if (DebugMode == AS_DEBUG_AUDIO) {
    return AS_debugAudio(texcoord, DebugMode);
}
if (DebugMode == AS_DEBUG_DEPTH) {
    float mask = AS_isSceneBehind(texcoord, EffectDepth) ? 1.0 : 0.0;
    return float4(mask, mask, mask, 1.0);
}
```

---

## Performance Optimization

### Level of Detail (LOD)

```hlsl
float lod_factor = saturate(1.0 - (distance_from_center - LOD_THRESHOLD) / LOD_THRESHOLD);
int effective_samples = max(MIN_SAMPLES, int(float(MAX_SAMPLES) * lod_factor));
```

### Early Termination

```hlsl
if (AS_isInFrontOfStage(texcoord, EffectDepth)) return originalColor;
if (distance_from_center > MAX_EFFECT_RADIUS) return originalColor;
if (audioLevel < MIN_AUDIO_THRESHOLD) return lerp(originalColor, lowIntensityResult, 0.1);
```

### Loop Optimization

```hlsl
// Pre-calculate constants outside loops
[unroll(8)]
for (int i = 0; i < 8; i++) { /* small known-count loops */ }

// Dynamic step size based on quality
int step_size = max(1, TOTAL_STEPS / effective_steps);
for (int i = 0; i < TOTAL_STEPS; i += step_size) { /* process */ }
```

---

## Development Phases

1. **Core Effect**: Basic functionality with placeholders
2. **Coordinate System**: Position/scale/rotation UI via standard helpers
3. **Palette Integration**: Color system + palette UI
4. **Audio Reactivity**: Audio controls + frequency sampling
5. **Optimization**: LOD systems + early termination + polish

---

## Versioning and Compatibility

**Major version changes** (`.1.fx` to `.2.fx`) break preset compatibility:
- Uniform parameter changes (name, type, range)

**Minor updates** maintain compatibility:
- Bug fixes, performance optimizations, additional optional features
- Function signature changes, UI reorganization

---

## Quick Reference Tables

### Common UI Value Ranges

| Parameter Type | Min | Max | Default | Step |
|---------------|-----|-----|---------|------|
| Opacity | 0.0 | 1.0 | 1.0 | 0.01 |
| Scale | 0.1 | 5.0 | 1.0 | 0.01 |
| Position | -1.5 | 1.5 | 0.0 | 0.01 |
| Animation Speed | 0.0 | 5.0 | 1.0 | 0.01 |
| Audio Multiplier | 0.0 | 2.0 | 1.0 | 0.05 |
| Rotation Snap | -4 | 4 | 0 | 1 |
| Rotation Fine | -45.0 | 45.0 | 0.0 | 0.1 |
| Stereo Position | -1.0 | 1.0 | 0.0 | 0.01 |
| Blend Amount | 0.0 | 1.0 | 1.0 | -- |
| Stage Depth | 0.0 | 1.0 | 0.05 | 0.01 |

### Blend Mode Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `AS_BLEND_NORMAL` | 0 | Normal / opaque blend |
| `AS_BLEND_LIGHTEN` | 5 | Lighten only |

---

## Testing Checklist

**Functional**: Rotation, aspect ratio independence, position/scale controls, depth masking, palette integration, audio reactivity
**Performance**: 60+ FPS at 1080p, 30+ FPS at 4K, effective LOD, reasonable memory usage
**Visual**: No artifacts, smooth audio response, proper blending, consistent brightness
**Code**: Naming conventions, UI organization, technique guards, single-line uniforms, shader descriptor present

---

## Lessons Learned: Practical Wisdom from Building 80+ Shaders

This section captures hard-won knowledge from iterative in-game development. These aren't rules you'll find in HLSL documentation — they're patterns that emerged from building, testing, breaking, and fixing real effects.

### 1. Compositing: The Golden Rule

**The core effect operation and the user's BlendMode are SEPARATE concerns.**

The single most common mistake is using `AS_composite()` or `AS_blendRGB()` for the core effect logic. The correct pattern:

```hlsl
// Step 1: Compute the effect result (core operation — additive, multiplicative, whatever the algorithm needs)
float3 effectResult = originalColor.rgb + wrapLight;  // Example: additive light
// OR
float3 effectResult = originalColor.rgb * colorGrade;  // Example: color grading
// OR
float3 effectResult = generatedPattern;                 // Example: background replacement

// Step 2: THEN apply the user's blend mode choice on top
float3 finalRgb = AS_composite(effectResult, originalColor.rgb, BlendMode, BlendAmount);
return float4(finalRgb, 1.0);
```

**Why this matters**: If you use Screen blend for the additive step AND the user also has Screen selected, you get double-screened mush. The user's BlendMode controls how the ENTIRE effect mixes with the original scene. Your algorithm should produce the correct result assuming Normal blend.

### 2. Additive Light Effects Must NEVER Darken

If your effect adds light (glow, wrap, leak, bloom, halation), test with a pure black scene AND a pure white scene:

- Black scene: the light should be clearly visible
- White scene: the result should be white or slightly brighter — NEVER darker

If adding your effect to a bright pixel makes it dimmer, the algorithm is wrong. Common causes:
- Using `lerp()` instead of `+` for the light contribution
- Multiplying by a factor < 1.0 before adding
- Using Screen blend (which compresses highlights) when you mean additive

### 3. Depth Buffer in Games: What You Need to Know

**The depth buffer is NOT a clean, smooth gradient.** In FFXIV (and most games):

- **1-2 pixel imprecision** at silhouette edges (where character meets background)
- **Depth discontinuities** at polygon edges within a mesh (armor plates, hair strands)
- **Sky/far plane** reads as depth ≈ 1.0 (or 0.0 depending on reversed-Z)
- **Hard threshold** (`depth < X`) creates razor-sharp cuts; use `smoothstep` for gradual transitions

**For surface normals from depth**: Sample at 8-12 pixel separation, not 1 pixel. Single-pixel normals are noisy garbage in games because adjacent pixels belong to different polygons. Wide sampling produces stable, smooth normals at the cost of losing fine detail — acceptable for effects like Fresnel.

**Depth discontinuity guard**: When computing normals or gradients from depth, adjacent pixels may belong to completely different surfaces (character vs. background). Check if the depth difference exceeds a threshold; if so, the "normal" at that pixel is unreliable. At silhouette edges where one side crosses `EffectDepth`, set Fresnel to maximum (it's the most edge-on surface). At mesh-internal edges, suppress the artifact.

### 4. Alpha-Weighted Blur: When and How

Standard Gaussian blur treats every pixel equally. When blurring content that has transparent regions (like a background with a foreground cutout), transparent pixels contribute BLACK:

```
Standard blur: (red + red + BLACK + BLACK + red) / 5 = dim red  ← WRONG
Alpha-weighted: (red×1 + red×1 + 0×0 + 0×0 + red×1) / 3 = bright red  ← CORRECT
```

**Use alpha-weighted blur whenever you're blurring content with varying alpha.** The pattern:

```hlsl
float3 colorSum = 0; float alphaWeightSum = 0; float totalWeight = 0;
for (int i = -RADIUS; i <= RADIUS; i++) {
    float4 s = tex2Dlod(sampler, float4(tc + offset * i, 0, 0));
    float w = gaussWeight(i);
    colorSum += s.rgb * s.a * w;
    alphaWeightSum += s.a * w;
    totalWeight += w;
}
float3 finalColor = colorSum / max(alphaWeightSum, AS_EPSILON);
float finalAlpha = alphaWeightSum / max(totalWeight, AS_EPSILON);
```

**Critical**: For separable blur (H then V), alpha-weight ONLY the first pass. The second pass uses standard blur on the already-weighted result. Alpha-weighting both passes causes directional asymmetry (vertical edges get double-penalized).

### 5. Default Values: The First Impression

When a user enables your shader for the first time, the default values should produce a **visible but tasteful** result. Not overwhelming, not invisible. The user should immediately understand what the effect does without touching any sliders.

**Good defaults**:
- Light Wrap: width=8, intensity=0.5 → visible glow around character edges
- Film Grain: amount=0.3 → subtle texture, not TV static
- Bleach Bypass: strength=0.5 → noticeable but not monochrome

**Bad defaults**:
- Blur radius=0 → effect is invisible, user thinks it's broken
- Intensity=2.0 → overwhelming, user disables immediately
- All RGB offsets at 0 → cross-processing with no visible effect

### 6. Loop Safety in ReShade

ReShade's shader compiler has strict requirements for loops:

```hlsl
// CORRECT: Compile-time bound with runtime early exit
static const int MAX_SAMPLES = 32;
for (int i = 0; i < MAX_SAMPLES; i++) {
    if (i >= dynamicCount) break;
    // Use tex2Dlod() inside loops, NEVER tex2D()
    float4 s = tex2Dlod(sampler, float4(uv, 0, 0));
}

// WRONG: Dynamic loop bound (may not compile)
for (int i = 0; i < dynamicCount; i++) { ... }

// WRONG: tex2D inside a loop (undefined behavior)
for (int i = 0; i < 16; i++) {
    float4 s = tex2D(sampler, uv);  // BAD — use tex2Dlod
}
```

### 7. Spatial Mode Determines Feature Set

Don't blindly add every feature to every shader. The spatial mode dictates what makes sense:

| Feature | Generator (BGX) | Overlay (VFX) | Filter (GFX) | Temporal (D) | Multi-Instance (LFX) |
|---------|:---:|:---:|:---:|:---:|:---:|
| Position/Scale | Yes | Usually | No | No | Per-instance |
| Rotation | Yes | Sometimes | Rarely | No | Per-instance |
| Palette | Yes | Often | Rarely | No | Global |
| Animation | Yes | Often | Sometimes | Inherent | Global |
| Audio | Yes | Often | Sometimes | Often | Per-instance |
| Depth | Yes | Yes | Sometimes | Yes | Yes |
| BlendMode | Yes | Yes | Yes | Yes | Yes |

A color grading filter (Mode C) with Position/Scale is nonsensical. A temporal accumulation effect (Mode D) with rotation would break the frame history. Match features to the effect's nature.

### 8. Naming Things for Humans

Your users are photographers and content creators, not shader programmers. Every label and tooltip should describe the **visual result**, not the algorithm:

| Technical Name | User-Friendly Name |
|---------------|-------------------|
| "Fractal Iterations" | "Pattern Detail (GPU Cost)" |
| "Raymarching Steps" | "Quality (Higher = Slower)" |
| "Domain Warp Intensity" | "Pattern Wildness" |
| "Gaussian Sigma" | "Blur Softness" |
| "Luminance Threshold" | "Brightness Cutoff" |
| "Fresnel Exponent" | "Surface Reach" |

For tooltips, describe what extreme values look like:
```
"How far the light wraps around edges. Low = thin rim. High = deep crescent glow."
```

### 9. Presets: In-Shader Quick Starts

For complex effects with many parameters, provide a preset combo that configures good starting points:

```hlsl
uniform int PresetMode < ui_type = "combo"; ui_label = "Preset";
    ui_items = "Custom\0Subtle Portrait\0Dramatic Stage\0Heavy Grunge\0";
    ui_category = AS_CAT_APPEARANCE; > = 1;
```

Then in the pixel shader, override parameter values based on the preset selection. Users pick a look, then optionally fine-tune. This dramatically lowers the barrier to entry for effects with 10+ parameters.

See `AS_GFX_CrossProcessing` (5 chemistry presets) and `AS_GFX_CinematicDiffusion` (8 film filter presets) for production examples.

### 10. The Shader Creation Workflow

Based on building 20 shaders in rapid succession, the most efficient workflow is:

1. **Classify the spatial mode** — determines which macros and features to include
2. **Write the header** — file comment, technique guard, includes, descriptor
3. **Define constants** — all MIN/MAX/DEFAULT values as named `static const`
4. **Declare uniforms** — effect-specific first, then standard macros in canonical order
5. **Write the pixel shader** — start with just the core algorithm producing a `float3` result
6. **Add depth gating** — `AS_isInFrontOfStage` early return if applicable
7. **Add audio modulation** — wire AS_audioModulate to the relevant parameters
8. **Add compositing** — `AS_composite(effectResult, original, BlendMode, BlendAmount)`
9. **Add debug modes** — at minimum: audio levels and depth mask visualization
10. **Tune defaults** — enable the shader and adjust until the first impression is right

Steps 1-4 are mechanical (copy from template). Steps 5-6 are the creative work. Steps 7-10 are polish. Don't try to add audio/palette/depth before the core algorithm works.

### 11. Common Pitfalls (Quick Reference)

| Pitfall | Symptom | Fix |
|---------|---------|-----|
| `tex2D` in a loop | Compile error or undefined behavior | Use `tex2Dlod(sampler, float4(uv, 0, 0))` |
| Dynamic loop bound | Compile error | Use `static const int` max + runtime `break` |
| `fmod()` with negatives | Undefined behavior, visual glitches | Use `AS_mod()` |
| Deprecated function name | Compile error (undeclared identifier) | Check deprecated table in this guide |
| `AS_PALETTE_WARM` or similar | Compile error | Check actual constant names in AS_Palette.1.fxh |
| BlendMode for core logic | Double-blended mush | Additive/multiply directly, BlendMode for final mix only |
| Alpha-weighted both blur passes | Vertical edges dimmer than horizontal | Alpha-weight pass 1 only |
| 1-pixel normal sampling | Blocky, noisy surface normals | Sample at 8-12 pixel separation |
| Fresnel multiplying intensity | Uniform blobs of light | Fresnel should modify falloff exponent |
| Depth guard at silhouette edge | Dark gap between foreground and wrap | Check if neighbor crosses EffectDepth → set fresnel to max |
| Default intensity too high | User disables effect immediately | Start subtle: 0.3-0.5 for most parameters |
| Hardcoded category string | Inconsistency when category name changes | Use AS_CAT_* constants |
| Missing `ui_step` on slider | ReShade uses default precision (often too coarse) | Always specify ui_step |

### 12. Quality Checklist (Before Release)

**Visual Quality:**
- [ ] Default values produce a visible, tasteful result
- [ ] Effect never darkens when it should only add light
- [ ] No visible artifacts at depth boundaries
- [ ] Looks correct at both 1080p and 4K
- [ ] Works with and without Listeningway audio plugin
- [ ] Smooth, non-jarring audio response

**Code Quality:**
- [ ] Technique guard: `__AS_TypeCode_EffectName_1_fx` (mixed case, with `_1_`)
- [ ] Namespace: `AS_EffectName` (underscore after AS)
- [ ] Shader descriptor with user-friendly description
- [ ] All uniforms on single lines
- [ ] All `ui_category` values use AS_CAT_* constants
- [ ] All sliders have `ui_step` specified
- [ ] All sliders have `ui_tooltip` explaining the visual effect
- [ ] Named constants for all min/max/default values
- [ ] No deprecated function calls
- [ ] No `fmod()` — use `AS_mod()`
- [ ] No `tex2D()` inside loops — use `tex2Dlod()`
- [ ] Textures/samplers prefixed with shader name

**Feature Integration:**
- [ ] Standard macros used for all standard controls
- [ ] Canonical category ordering (effect-specific → palette → animation → audio → stage → final → debug)
- [ ] `AS_composite()` for final output
- [ ] Debug mode with at least audio and depth visualization
- [ ] Early return for depth-gated pixels

---

*AS StageFX Implementation Guide -- Reference for shader development*
