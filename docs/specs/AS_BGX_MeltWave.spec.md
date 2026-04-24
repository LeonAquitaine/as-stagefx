# AS_BGX_MeltWave — Implementation Specification

**Spec version**: 1.0
**Target file**: `shaders/AS/AS_BGX_MeltWave.1.fx`
**Shader category**: Background Effect (BGX)
**Framework**: AS-StageFX for ReShade
**Deliverable license**: CC BY 4.0 (project original)

---

## 1. Clean-room constraints — READ BEFORE IMPLEMENTING

**This is a blind reimplementation. You must produce this shader without referencing any existing implementation.**

- You MUST NOT read, grep, or search for any file that implements a shader with this or a similar name — neither in this repository, nor on Shadertoy, nor in any other source.
- You MUST NOT ask anyone for the previous version's source code.
- You MUST NOT copy fragments from any "70s melt", "melt wave", iterative-sine-distortion, or similar shader you may have encountered before.
- You MAY use any technique of your own choosing that produces the observable behavior below.
- If you are unsure about an implementation detail, ask the maintainer — do not infer by examining similar shaders.

Your output is a genuinely new implementation whose copyright belongs to its author.

---

## 2. Purpose

A full-screen background effect that produces a flowing, warping, continuously-evolving psychedelic color pattern with a 1970s retro character. The effect is audio-reactive, palette-aware, and participates in the AS-StageFX standard controls (position, rotation, depth masking, blend).

---

## 3. Visual character

The shader must produce output with all of these observable properties:

- **Fills the whole screen.** No transparent gaps, no hard edges, no visible tiles or grid.
- **Fluid, viscous motion.** Colors appear to flow and warp like a lava lamp or slow-moving liquid. No sudden transitions, no flicker at default settings.
- **Two motion scales simultaneously.** A slow macro-undulation sweeps across the frame; finer localized eddies and swirls ride on top.
- **User-controlled detail density.** Low values produce broad, simple patterns; high values produce intricate, busy, fine-scale structure.
- **Two color modes**:
  - *Original Colors mode* — a vibrant retro palette where red, green, and blue channels vary independently, producing characteristic 70s color combinations (magenta next to lime green, cyan next to orange).
  - *Palette mode* — the underlying pattern intensity is mapped through a user-selected AS palette, producing coordinated color harmonies that can optionally cycle over time.
- **Continuous smooth animation** driven by time.
- **Responds to position, rotation, and scale** without breaking.
- **Responds to audio** on the user-selected target parameter.

---

## 4. UI contract (EXACT — users have saved presets)

### 4.1 Private constants (declare as `static const` inside the namespace)

| Constant | Value |
|---|---|
| `ITERATIONS_MIN` | `10` |
| `ITERATIONS_MAX` | `80` |
| `ITERATIONS_STEP` | `1` |
| `ITERATIONS_DEFAULT` | `40` |
| `BRIGHTNESS_MIN` | `0.5` |
| `BRIGHTNESS_MAX` | `2.0` |
| `BRIGHTNESS_STEP` | `0.01` |
| `BRIGHTNESS_DEFAULT` | `0.975` |
| `MELT_INTENSITY_MIN` | `0.25` |
| `MELT_INTENSITY_MAX` | `4.0` |
| `MELT_INTENSITY_STEP` | `0.05` |
| `MELT_INTENSITY_DEFAULT` | `1.0` |
| `SATURATION_MIN` | `0.0` |
| `SATURATION_MAX` | `2.0` |
| `SATURATION_STEP` | `0.01` |
| `SATURATION_DEFAULT` | `1.0` |
| `COLOR_CYCLE_SPEED_MIN` | `-2.0` |
| `COLOR_CYCLE_SPEED_MAX` | `2.0` |
| `COLOR_CYCLE_SPEED_STEP` | `0.1` |
| `COLOR_CYCLE_SPEED_DEFAULT` | `0.1` |
| `ANIMATION_SPEED_MIN` | `0.0` |
| `ANIMATION_SPEED_MAX` | `5.0` |
| `ANIMATION_SPEED_STEP` | `0.01` |
| `ANIMATION_SPEED_DEFAULT` | `1.25` |
| `ANIMATION_KEYFRAME_MIN` | `0.0` |
| `ANIMATION_KEYFRAME_MAX` | `100.0` |
| `ANIMATION_KEYFRAME_STEP` | `0.1` |
| `ANIMATION_KEYFRAME_DEFAULT` | `0.0` |
| `POSITION_MIN` | `-1.5` |
| `POSITION_MAX` | `1.5` |
| `POSITION_STEP` | `0.01` |
| `POSITION_DEFAULT` | `0.0` |
| `SCALE_MIN` | `0.5` |
| `SCALE_MAX` | `2.0` |
| `SCALE_STEP` | `0.01` |
| `SCALE_DEFAULT` | `1.0` |
| `AUDIO_MULTIPLIER_DEFAULT` | `1.0` |
| `AUDIO_MULTIPLIER_MAX` | `5.0` |

### 4.2 Shader descriptor (first uniform)

```hlsl
uniform int as_shader_descriptor < ui_type = "radio"; ui_label = " "; ui_text = "\nMelt Wave - Psychedelic flowing distortion\nLicense: CC BY 4.0\n\n"; >;
```

### 4.3 Uniforms — exact declarations required

Effect Settings category (category label: `"Effect Settings"`):

| Uniform | Type | ui_label | Extra |
|---|---|---|---|
| `Iterations` | `int` slider | `"Zoom Intensity"` | uses `ITERATIONS_*` |
| `Brightness` | `float` slider | `"Brightness"` | uses `BRIGHTNESS_*` |
| `MeltIntensity` | `float` slider | `"Melt Intensity"` | uses `MELT_INTENSITY_*` |

Palette & Style category (use `AS_CAT_PALETTE`):

| Uniform | Type | ui_label | Default | Tooltip (exact) |
|---|---|---|---|---|
| `UseOriginalColors` | `bool` toggle | `"Use Original Math Colors"` | `true` | `"If enabled, uses the original mathematical coloring method. Otherwise, uses palettes."` |
| `Saturation` | `float` slider | `"Original Color Saturation"` | `SATURATION_DEFAULT` | `"Saturation for original math colors (if Use Original Math Colors is enabled)."` |
| `TintColor` | `float3` color | `"Original Color Tint"` | `float3(1.0, 1.0, 1.0)` | `"Tint for original math colors (if Use Original Math Colors is enabled)."` |
| `PalettePreset` | via macro | | | `AS_PALETTE_SELECTION_UI(PalettePreset, "Color Palette", AS_PALETTE_NEON, AS_CAT_PALETTE)` |
| custom palette | via macro | | | `AS_DECLARE_CUSTOM_PALETTE(MeltWave_, AS_CAT_PALETTE)` |
| `ColorCycleSpeed` | `float` slider | `"Palette Color Cycle Speed"` | `COLOR_CYCLE_SPEED_DEFAULT` | `"Controls how fast palette colors cycle. 0 = static. Only active if not using original math colors."` |
| `BackgroundColor` | via macro | | | `AS_BACKGROUND_COLOR_UI(BackgroundColor, float3(0.0, 0.0, 0.0), AS_CAT_PALETTE)` |

Audio Reactivity (via macros):

```hlsl
AS_AUDIO_UI(MeltWave_AudioSource, "Audio Source", AS_AUDIO_BASS, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(MeltWave_AudioMultiplier, "Audio Multiplier", AUDIO_MULTIPLIER_DEFAULT, AUDIO_MULTIPLIER_MAX, AS_CAT_AUDIO)
AS_AUDIO_TARGET_UI(MeltWave_AudioTarget, "Melt Intensity\0Animation Speed\0Brightness\0Zoom\0All\0", 2)
```

Animation, Position, Stage, Rotation, Final Mix, Debug (via macros):

```hlsl
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, AS_CAT_ANIMATION)
AS_POSITION_SCALE_UI(Position, Scale)
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(RotationSnap, RotationFine)
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)
AS_DEBUG_UI("Off\0Show Audio Reactivity\0")
```

### 4.4 Technique declaration

```hlsl
technique AS_BGX_MeltWave < ui_label = "[AS] BGX: Melt Wave"; ui_tooltip = "Generates a flowing, liquid-like psychedelic visual effect with customizable parameters and audio reactivity."; >
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = AS_MeltWave::PS_MeltWave;
    }
}
```

---

## 5. Behavior specification

### 5.1 Required pixel shader pipeline

1. **Depth early-return** at the top: `AS_DEPTH_EARLY_RETURN(texcoord, EffectDepth)`.

2. **Audio modulation** — compute once per pixel:
   ```
   audioReactivity = AS_audioModulate(1.0, MeltWave_AudioSource, MeltWave_AudioMultiplier, true, 0)
   ```
   Copy uniform values into locals, then apply `audioReactivity` as a multiplier to the local copies of the parameters selected by `MeltWave_AudioTarget`:
   - `0` → Melt Intensity only
   - `1` → Animation Speed only
   - `2` → Brightness only
   - `3` → Zoom Intensity (Iterations) only
   - `4` → all four
   
   The uniform values themselves are not modified.

3. **Animation time**: `time = AS_getAnimationTime(animationValue, AnimationKeyframe)`.

4. **Coordinate transform (in this order)**:
   - Center with aspect correction: `AS_centeredUVWithAspect(texcoord, ReShade::AspectRatio)`
   - Rotate around center using angle `AS_getRotationRadians(RotationSnap, RotationFine)`, using the **inverse** rotation direction
   - Apply position and scale: `AS_applyPositionAndScale(...)`
   - Expand to a range suitable for effect intensity (you choose the factor)
   - Re-apply aspect correction on the horizontal axis

5. **Pattern field** — produce a continuously-varying 2D distortion/deformation field over the transformed coordinates. The field must satisfy:
   - Fluid/flowing character, no discontinuities
   - Smooth evolution over `time`
   - Distortion amplitude scales with the local `MeltIntensity` value
   - Detail density scales with the local `Iterations` value (higher = more structure)
   - Deterministic: same inputs produce same output frame-to-frame
   
   **Technique is unspecified. Use anything that meets these observable properties.**

6. **Color generation**:
   - **If `UseOriginalColors == true`**:
     - Produce an RGB color where each channel varies distinctly across the frame, exhibiting the characteristic 1970s retro look (unusual combinations like magenta-lime-cyan adjacency).
     - Apply `AS_adjustSaturation(color, Saturation)`.
     - Multiply by `TintColor`.
   - **Else** (Palette mode):
     - Compute a scalar intensity from the pattern — idiomatic choice is `dot(rawPattern, AS_LUMA_REC709)`.
     - Optionally time-cycle the parameter by adding `time * ColorCycleSpeed * 0.05` and wrapping with `frac()` when `ColorCycleSpeed != 0`.
     - Sample: `AS_GET_PALETTE_COLOR(MeltWave_, PalettePreset, t)`.

7. **Brightness**: multiply the processed color by the local `Brightness` value.

8. **Effect alpha**: derive a scalar ≈ `(r + g + b) / 4 * 1.5` so dark regions are transparent and bright regions are opaque.

9. **Final composite**:
   ```
   blendedColor = AS_blendRGB(processedColor, BackgroundColor, BlendMode)
   mixed = lerp(BackgroundColor, blendedColor, BlendAmount * effectAlpha)
   return float4(lerp(_as_originalColor.rgb, mixed, BlendAmount), _as_originalColor.a);
   ```

10. **Debug overlay**: if `DebugMode == 1`, draw a greyscale indicator circle at texcoord center ≈ `(0.1, 0.1)`, radius ≈ `0.08`. The circle's grey level equals `audioReactivity` (clamped to [0, 1]).

### 5.2 Namespace and guard

```hlsl
#ifndef __AS_BGX_MeltWave_1_fx
#define __AS_BGX_MeltWave_1_fx

// ... includes ...

namespace AS_MeltWave {
    // all constants, uniforms, helpers, and the pixel shader
}

// technique declaration (outside namespace, referencing AS_MeltWave::PS_MeltWave)

#endif
```

### 5.3 Required includes (in this order)

```hlsl
#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"
```

---

## 6. Acceptance criteria

The implementation is complete when all of the following hold:

1. Shader compiles cleanly with ReShade FX compiler — no errors, no undeclared symbols.
2. The `[AS] BGX: Melt Wave` entry appears in the ReShade shader list with the tooltip text from §4.4.
3. Every UI parameter listed in §4.3 appears with the exact name, range, default, step, tooltip, and category.
4. On load at default settings: the screen shows a flowing psychedelic pattern in the retro RGB palette, with visible continuous motion.
5. Setting `MeltIntensity` to its min vs. its max visibly changes how strongly the pattern warps.
6. Setting `Iterations` to its min vs. its max visibly changes how busy/detailed the pattern is.
7. Toggling `UseOriginalColors` off switches the pattern from retro RGB to a coordinated palette-mapped look.
8. Selecting different palettes via `PalettePreset` changes the color harmony visibly.
9. `Position`, `Scale`, `RotationSnap` + `RotationFine` pan/zoom/rotate the pattern without visual artifacts.
10. `EffectDepth` properly masks the effect behind scene geometry in a test scene.
11. With Listeningway running, audio reactivity visibly pulses the parameter(s) selected by `MeltWave_AudioTarget`.
12. `DebugMode == "Show Audio Reactivity"` renders a visible indicator circle in the top-left.
13. `BlendMode` / `BlendAmount` correctly composite the effect over the original backbuffer.

---

## 7. Non-goals

- No requirement for byte-exact visual reproduction of any prior implementation.
- No requirement for any specific mathematical formulation.
- Any stable, continuous, audio-responsive distortion approach that satisfies §3 and §6 is acceptable.
- Do NOT attempt to reconstruct anyone else's formula — use your own.

---

## 8. Deliverable

A single file at `shaders/AS/AS_BGX_MeltWave.1.fx` with:
- `Author: <your name or identifier>` in the header
- `License: Creative Commons Attribution 4.0 International` in the header
- No mention of any upstream shader, prior author, or external source
- Implementation complete per §5, UI per §4, acceptance criteria per §6.
