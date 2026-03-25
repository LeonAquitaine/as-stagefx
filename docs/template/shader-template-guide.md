# AS StageFX Shader Template Guide

This document explains how to use the shader templates and provides specific guidance for different shader types.

## Template Files

| Template | Mode | Purpose |
|----------|------|---------|
| `shader-template.fx.example` | Generic | Base template with all patterns |
| `bgx-template.fx.example` | A: Generator | Full-screen procedural backgrounds |
| `vfx-template.fx.example` | B: Overlay | Visual effects overlaid on scene |
| `gfx-template.fx.example` | C: Filter | Image processing / post-processing |
| `lfx-template.fx.example` | E: Multi-Instance | Multi-instance lighting effects |

## Using the Templates

1. **Copy the appropriate template file** to `shaders/AS/`
2. **Replace placeholders** marked with `[BRACKETS]` with your specific values
3. **Remove optional sections** that don't apply to your effect
4. **Customize UI parameters** based on your effect's needs
5. **Implement your effect algorithm** in the pixel shader

## Placeholder Reference

| Placeholder | Description | Examples |
|-------------|-------------|----------|
| `[TYPECODE]` | Shader category code | BGX, VFX, LFX, GFX |
| `[EffectName]` | CamelCase effect name | BlueCorona, CircularSpectrum |
| `[Effect Display Name]` | Human-readable name | "Blue Corona", "Circular Spectrum" |
| `[Author Name]` | Your name | "Leon Aquitaine" |
| `[Brief Description]` | One-line summary | "Blue Corona Background Effect" |

## Critical Conventions

### Technique Guard Format
Use mixed case with `_1_` version suffix:
```hlsl
#ifndef __AS_BGX_CosmicStorm_1_fx
#define __AS_BGX_CosmicStorm_1_fx
```
NOT all caps, NOT missing version suffix.

### Namespace Convention
Use `AS_` prefix with underscore:
```hlsl
namespace AS_CosmicStorm {
```

### Shader Descriptor
Place immediately after includes. Include a user-friendly description (what will this do to my screenshot?):
```hlsl
uniform int as_shader_descriptor <ui_type = "radio"; ui_label = " "; ui_text = "AS StageFX | Cosmic Storm | Swirling fractal vortex background with volumetric lighting. | by Leon Aquitaine"; > = 0;
```
Descriptions should be in visual terms, not technical — see ImplementationGuide.md "Writing Good Shader Descriptions" for guidelines.

### Category Constants
Use `AS_CAT_*` constants instead of hardcoded strings:
```hlsl
// CORRECT:
ui_category = AS_CAT_PALETTE;
ui_category = AS_CAT_ANIMATION;
ui_category = AS_CAT_AUDIO;
ui_category = AS_CAT_STAGE;
ui_category = AS_CAT_FINAL;
ui_category = AS_CAT_DEBUG;

// WRONG:
ui_category = "Palette & Style";
ui_category = "Animation";
```
Effect-specific categories remain as strings (e.g., `"Pattern"`, `"Fractal"`).

### Function Names (Current API)
Use the current function names, not deprecated ones:
```hlsl
// CURRENT                          // DEPRECATED (do not use)
AS_audioModulate(v, src, mul, f, 0) // AS_applyAudioReactivity(v, src, mul, f)
AS_audioModulate(v, src, mul, f, m) // AS_applyAudioReactivityEx(v, src, mul, f, m)
AS_audioLevelFromSource(source)     // AS_getAudioSource(source)
AS_timeSeconds()                    // AS_getTime()
AS_rotate2D(coords, angle)         // AS_applyRotation(coords, angle)
```

### Standard UI Macros
Use these macros for standard controls:
```hlsl
// Audio target selector
AS_AUDIO_TARGET_UI(EffectName_AudioTarget, "None\0Speed\0Intensity\0", 0)

// Color cycling speed
AS_COLOR_CYCLE_UI(ColorCycleSpeed, AS_CAT_PALETTE)

// Toggle between mathematical and palette coloring
AS_USE_PALETTE_UI(UseOriginalColors, AS_CAT_PALETTE)
```

### Compositing Pattern
Use `AS_composite()` for final output instead of manual blend + lerp:
```hlsl
// PREFERRED: Single-call compositing
float3 finalRgb = AS_composite(effectColor, originalColor.rgb, BlendMode, BlendStrength);

// EQUIVALENT but verbose:
float3 blendedColor = AS_blendRGB(effectColor, originalColor.rgb, BlendMode);
float3 finalRgb = lerp(originalColor.rgb, blendedColor, BlendStrength);
```

For additive glow effects, compute light and add to scene:
```hlsl
float3 finalRgb = originalColor.rgb + effectLight;
```

BlendMode is for USER final mix control, not for core effect compositing.

## Shader Type Guidelines

### BGX (Background Effects) - Mode A: Generator
**Purpose**: Full-screen background patterns and environments

**Includes ALL standard controls**:
- Position, Scale, Rotation (Stage)
- Animation speed and keyframe
- Audio source, multiplier, and target
- Full palette system: `AS_PALETTE_SELECTION_UI` + `AS_DECLARE_CUSTOM_PALETTE` + `AS_USE_PALETTE_UI` + `AS_COLOR_CYCLE_UI`
- Background color
- Depth testing, blend mode, debug

**Key Implementation Points**:
- Use `AS_getAnimationTime()` for consistent animation
- Apply `AS_audioModulate()` to pattern parameters
- Use `AS_rotate2D()` for coordinate rotation
- Ensure resolution independence
- Use depth testing to render behind scene objects

### VFX (Visual Effects) - Mode B: Overlay
**Purpose**: Overlay effects, particles, distortions, audio visualizers

**Includes position/scale/rotation** and depth masking with `AS_STAGEDEPTH_UI`.

**Key Implementation Points**:
- Use `AS_audioModulate()` for audio response
- Implement palette system for dynamic coloring
- Use `AS_COLOR_CYCLE_UI` for color animation
- Depth masking via `AS_STAGEDEPTH_UI`
- Consider additive blending for glow effects

### GFX (Graphics/Post-Processing) - Mode C: Filter
**Purpose**: Image processing, composition aids, screen-space effects

**Does NOT include position/scale by default** - filters process the entire image.

**Key Implementation Points**:
- Focus on enhancing rather than replacing the original image
- Show depth-aware compositing (selective application by depth)
- Can use multi-pass techniques (e.g., 2-pass separable Gaussian blur)
- Audio reactivity is optional

### LFX (Lighting Effects) - Mode E: Multi-Instance
**Purpose**: Lighting simulation, flame effects, spotlights

**Uses the per-instance macro pattern**:
1. Define `EFFECT_UI` macro with all per-instance parameters
2. Create a `Params` struct to hold instance data
3. Create a `GetParams()` getter function
4. Each instance can have its own audio source selection

**Key Implementation Points**:
- Define `EFFECT_UI` macro for repeatable instance UI
- Use `struct LightParams` + `GetLightParams()` for clean parameter access
- Each instance gets independent audio source via the macro
- Global controls (palette, animation, blend) shared across instances
- Use `AS_audioLevelFromSource()` for per-instance audio

## Canonical UI Ordering

All shaders should follow this order for standard controls:

```hlsl
// ---- Effect-Specific Parameters ----
// ... (custom categories like "Pattern", "Fractal", "Shape")

// ---- Standard Controls (canonical order) ----
// Palette & Style    (AS_CAT_PALETTE)
// Animation          (AS_CAT_ANIMATION)
// Audio Reactivity   (AS_CAT_AUDIO)
// Stage              (AS_CAT_STAGE)
// Final Mix          (AS_CAT_FINAL)
// Debug              (AS_CAT_DEBUG)
```

## Advanced Patterns

### Audio Reactivity with AS_AUDIO_TARGET_UI
```hlsl
// In UI section
AS_AUDIO_UI(Effect_AudioSource, "Audio Source", AS_AUDIO_BEAT, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(Effect_AudioMultiplier, "Intensity", 1.0, 2.0, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(MyEffect_AudioTarget, "None\0Parameter A\0Parameter B\0", 0)

// In pixel shader
float paramA = ParamA;
float paramB = ParamB;
float audioValue = AS_audioModulate(1.0, Effect_AudioSource, Effect_AudioMultiplier, true, 0);
if (MyEffect_AudioTarget == 1) paramA *= audioValue;
else if (MyEffect_AudioTarget == 2) paramB *= audioValue;
```

### Full Palette System
```hlsl
// In UI section
AS_PALETTE_SELECTION_UI(EffectPalette, "Color Palette", AS_PALETTE_FIRE, AS_CAT_PALETTE)
AS_DECLARE_CUSTOM_PALETTE(Effect_, AS_CAT_PALETTE)
AS_USE_PALETTE_UI(UseOriginalColors, AS_CAT_PALETTE)
AS_COLOR_CYCLE_UI(ColorCycleSpeed, AS_CAT_PALETTE)

// In pixel shader
float colorPos = effectValue;
if (abs(ColorCycleSpeed) > AS_EPSILON) {
    colorPos = frac(colorPos + AS_timeSeconds() * ColorCycleSpeed * 0.1);
}

float3 effectColor;
if (!UseOriginalColors) {
    if (EffectPalette == AS_PALETTE_CUSTOM) {
        effectColor = AS_GET_INTERPOLATED_CUSTOM_COLOR(Effect_, colorPos);
    } else {
        effectColor = AS_getInterpolatedColor(EffectPalette, colorPos);
    }
} else {
    effectColor = originalMathColor; // Your mathematical coloring
}
```

### Multi-Instance Pattern (LFX)
```hlsl
#define EFFECT_UI(index, defaultEnable, defaultPos, defaultSize, defaultAudioSource) \
uniform bool Inst##index##_Enable < ui_label = "Enable " #index; ui_category = "Instance " #index; > = defaultEnable; \
uniform float2 Inst##index##_Position < ui_type = "slider"; ui_label = "Position"; ui_min = -1.5; ui_max = 1.5; ui_category = "Instance " #index; > = defaultPos; \
uniform float Inst##index##_Size < ui_type = "slider"; ui_label = "Size"; ui_min = 0.01; ui_max = 1.0; ui_category = "Instance " #index; > = defaultSize; \
uniform int Inst##index##_AudioSource < ui_type = "combo"; ui_label = "Audio Source"; ui_items = "Off\0Volume\0Beat\0Bass\0"; ui_category = "Instance " #index; > = defaultAudioSource;

EFFECT_UI(1, true, float2(0.0, 0.0), 0.5, 2)
EFFECT_UI(2, false, float2(0.3, 0.3), 0.3, 2)

struct InstanceParams { bool enable; float2 position; float size; int audioSource; };

InstanceParams GetInstanceParams(int idx) {
    InstanceParams p;
    if (idx == 0) { p.enable = Inst1_Enable; p.position = Inst1_Position; p.size = Inst1_Size; p.audioSource = Inst1_AudioSource; }
    else { p.enable = Inst2_Enable; p.position = Inst2_Position; p.size = Inst2_Size; p.audioSource = Inst2_AudioSource; }
    return p;
}
```

## Validation Checklist

Before committing your shader:

**Structure:**
- [ ] All `[BRACKET]` placeholder values replaced
- [ ] Technique guard uses mixed case: `__AS_TypeCode_EffectName_1_fx`
- [ ] Namespace uses `AS_EffectName` format (with underscore)
- [ ] Shader descriptor present with user-friendly description
- [ ] Documentation header complete (DESCRIPTION, FEATURES, IMPLEMENTATION OVERVIEW)
- [ ] All uniforms on single lines (parsing tools require this)
- [ ] Textures/samplers prefixed with shader name (prevents conflicts)

**UI Quality:**
- [ ] UI categories use `AS_CAT_*` constants (not hardcoded strings)
- [ ] Standard controls follow canonical ordering (effect → palette → animation → audio → stage → final → debug)
- [ ] All sliders have `ui_step` specified
- [ ] All sliders have `ui_tooltip` explaining the visual result (not the algorithm)
- [ ] Named constants for all min/max/default values
- [ ] Default values produce a visible, tasteful result on first enable

**API Compliance:**
- [ ] Uses `AS_audioModulate()` not `AS_applyAudioReactivity()`
- [ ] Uses `AS_timeSeconds()` not `AS_getTime()`
- [ ] Uses `AS_rotate2D()` not `AS_applyRotation()`
- [ ] Uses `AS_AUDIO_TARGET_UI()` macro for audio target
- [ ] Uses `AS_composite()` for final output — BlendMode is for user's final mix only
- [ ] No `fmod()` — use `AS_mod()`
- [ ] No `tex2D()` inside loops — use `tex2Dlod(sampler, float4(uv, 0, 0))`
- [ ] No deprecated function calls (see ImplementationGuide.md)

**Functional:**
- [ ] Audio reactivity works (and gracefully degrades without Listeningway)
- [ ] Depth testing working correctly
- [ ] Effect scales properly with resolution
- [ ] Additive light effects never darken the scene
- [ ] Debug modes provide useful information (at minimum: audio + depth)

See also: **ImplementationGuide.md § "Lessons Learned"** for common pitfalls and their fixes.
