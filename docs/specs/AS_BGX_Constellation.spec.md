# AS_BGX_Constellation — Implementation Specification

**Spec version**: 1.0
**Target file**: `shaders/AS/AS_BGX_Constellation.1.fx`
**Shader category**: Background Effect (BGX)
**Framework**: AS-StageFX for ReShade
**Deliverable license**: CC BY 4.0 (project original)

---

## 1. Clean-room constraints — READ BEFORE IMPLEMENTING

**This is a blind reimplementation. You must produce this shader without referencing any existing implementation.**

- You MUST NOT read, grep, or search for any file that implements a shader with this or a similar name — neither in this repository, nor on Shadertoy, nor in any other source.
- You MUST NOT ask for the previous version's source code.
- You MUST NOT copy fragments from any "constellation", "star field", "BigWings tutorial", or similar shader you may have encountered before.
- You MAY use any technique of your own choosing that produces the observable behavior below.
- If you are unsure about an implementation detail, ask the maintainer — do not infer by examining similar shaders.

Your output is a genuinely new implementation whose copyright belongs to its author.

---

## 2. Purpose

A full-screen background effect that creates a field of twinkling star-like points connected by soft glowing lines, evoking a night sky, a star chart, or an abstract neural network. Multiple parallax layers provide a sense of depth, and the whole field gently rotates and shifts colors over time. The effect is audio-reactive and participates in AS-StageFX standard controls (depth masking, blend).

---

## 3. Visual character

The shader must produce output with all of these observable properties:

- **Dark background, bright elements.** The pattern renders luminous stars and lines against a dark/transparent base; it adds light rather than replacing the scene (additive-style, though controlled by the blend mode).
- **Star points**: small, bright, fuzzy, with a soft bloom/halo. Their sharpness and base intensity are user-controllable.
- **Twinkling**: each star pulses/flickers at an individual rhythm, not synchronized with its neighbors. Users control the speed, magnitude, and neighbor-to-neighbor variation of the twinkle.
- **Connection lines**: thin soft-edged glowing line segments connect each star to several nearby stars. Lines have a bright core and a softer falloff region on their edges.
- **Line-length shaping**: lines with "preferred" lengths can appear brighter than unusually long or short ones, giving the network a curated look (controlled by `LineLengthModStrength`).
- **Stable topology**: the network of stars and their connections is consistent frame-to-frame. You can pick out recognizable shapes and they persist as the field drifts and rotates. Stars are NOT being randomly reshuffled each frame.
- **Parallax depth**: multiple layers of stars at different scales are visible simultaneously. Some layers feel close (fewer, larger, brighter stars); some feel far (more, smaller, dimmer stars). Layers fade in and cycle out gradually over time, giving a subtle flying-through-space feel.
- **Continuous slow rotation** of the whole field.
- **Time-varying color**: the color of stars and lines cycles through different hues over time. User parameters control the speed, range, and channel phasing of the cycle.
- **Vertical gradient darkening**: audio reactivity can drive a vertical fade that darkens part of the screen relative to another, creating a horizon-like mood effect.

---

## 4. UI contract (EXACT — users have saved presets)

### 4.1 Private constants (declare as `static const` inside the namespace)

```
LINE_CORE_THICKNESS_MIN=0.001   MAX=0.05   DEFAULT=0.01
LINE_FALLOFF_WIDTH_MIN=0.001    MAX=0.1    DEFAULT=0.02
LINE_OVERALL_BRIGHTNESS_MIN=0.0 MAX=10.0   DEFAULT=1.0
LINE_LENGTH_MOD_STRENGTH_MIN=0.0 MAX=1.0   DEFAULT=1.0

SPARKLE_SHARPNESS_MIN=1.0        MAX=50.0  DEFAULT=10.0
SPARKLE_BASE_INTENSITY_MIN=0.0   MAX=5.0   DEFAULT=1.0
SPARKLE_TWINKLE_SPEED_MIN=0.0    MAX=50.0  DEFAULT=10.0
SPARKLE_TWINKLE_MAGNITUDE_MIN=0.0 MAX=1.0  DEFAULT=1.0
SPARKLE_PHASE_VARIATION_MIN=0.0  MAX=50.0  DEFAULT=10.0

PALETTE_TIME_SCALE_MIN=0.0       MAX=100.0 DEFAULT=20.0
PALETTE_COLOR_AMPLITUDE_MIN=0.0  MAX=1.0   DEFAULT=0.25
PALETTE_COLOR_BIAS_MIN=0.0       MAX=1.0   DEFAULT=0.75

ZOOM_MIN=0.1                     MAX=5.0   DEFAULT=1.0

AUDIO_GAIN_ZOOM_MAX=2.0              DEFAULT=0.0
AUDIO_GAIN_GRADIENT_MAX=5.0          DEFAULT=1.0
AUDIO_GAIN_LINE_BRIGHTNESS_MAX=2.0   DEFAULT=0.0
AUDIO_GAIN_LINE_FALLOFF_MAX=2.0      DEFAULT=0.0
AUDIO_GAIN_SPARKLE_MAG_MAX=3.0       DEFAULT=0.0
```

### 4.2 Shader descriptor (first uniform)

```hlsl
uniform int as_shader_descriptor < ui_type = "radio"; ui_label = " "; ui_text = "\nConstellation - Animated star network background\nLicense: CC BY 4.0\n\n"; >;
```

### 4.3 Uniforms — exact declarations required

All `ui_type` values below are `"drag"` unless noted. All tooltips are **exact** and must match verbatim.

**Lines category** (`ui_category = "Lines"`):

| Uniform | ui_label | ui_step | Tooltip (exact) |
|---|---|---|---|
| `LineCoreThickness` | `"Core Thickness"` | `0.001` | `"Width of the solid center of each constellation line. Increase for bolder, more visible connections."` |
| `LineFalloffWidth` | `"Edge Softness"` | `0.001` | `"How gradually constellation lines fade at their edges. Higher values create softer, more diffused lines."` |
| `LineOverallBrightness` | `"Overall Brightness"` | `0.1` | `"Master brightness multiplier for all constellation lines. Increase to make the line network more prominent."` |
| `LineLengthModStrength` | `"Length Affects Brightness"` | `0.01` | `"How much a line's length influences its brightness. At 1.0, shorter lines appear brighter than longer ones."` |

**Stars category** (`ui_category = "Stars"`):

| Uniform | ui_label | ui_step | Tooltip (exact) |
|---|---|---|---|
| `SparkleSharpness` | `"Sharpness"` | `0.1` | `"How focused each star point appears. Higher values create tiny pinpoint stars; lower values make broader glows."` |
| `SparkleBaseIntensity` | `"Base Intensity"` | `0.01` | `"Base brightness of each star before twinkling is applied. Zero hides the stars completely."` |
| `SparkleTwinkleSpeed` | `"Twinkle Speed"` | `0.1` | `"How fast the stars flicker on and off. Higher values produce rapid twinkling."` |
| `SparkleTwinkleMagnitude` | `"Twinkle Amount"` | `0.01` | `"Strength of the twinkling effect. At zero stars shine steadily; at maximum they pulse dramatically."` |
| `SparklePhaseVariation` | `"Twinkle Variation"` | `0.1` | `"How differently each star twinkles relative to its neighbors. Higher values make each star blink independently."` |

**Palette** (`ui_category = AS_CAT_PALETTE`):

| Uniform | Type | ui_label | Default | ui_step | Tooltip (exact) |
|---|---|---|---|---|---|
| `PaletteTimeScale` | `float` drag | `"Palette Animation Speed"` | `PALETTE_TIME_SCALE_DEFAULT` | `0.1` | `"How fast the color palette shifts over time. Zero freezes the colors; higher values cycle quickly."` |
| `PaletteColorPhaseFactors` | `float3` drag | `"Palette Color Phase Factors (RGB)"` | `float3(0.345f, 0.543f, 0.682f)` | `0.001` | `"Controls the phase offset for each color channel, determining which colors appear at different times."` |
| `PaletteColorAmplitude` | `float` drag | `"Palette Color Amplitude"` | `PALETTE_COLOR_AMPLITUDE_DEFAULT` | `0.01` | `"Range of color variation in the palette. Higher values produce more vivid color swings."` |
| `PaletteColorBias` | `float` drag | `"Palette Color Bias (Brightness)"` | `PALETTE_COLOR_BIAS_DEFAULT` | `0.01` | `"Base brightness offset for the palette. Higher values make the overall color scheme lighter and warmer."` |

Note: `PaletteColorPhaseFactors.x=0.345, .y=0.543, .z=0.682` is the exact default; it is a tuned value and must not be changed.

**Animation & Time Controls** (category literal: `"Animation"`, then `AS_CAT_ANIMATION` for Zoom):

```hlsl
AS_ANIMATION_UI(TimeSpeed, TimeKeyframe, "Animation")
```

| Uniform | Type | ui_label | Default | ui_step | Tooltip (exact) |
|---|---|---|---|---|---|
| `Zoom` | `float` drag | `"Zoom"` | `ZOOM_DEFAULT` | `0.01` | `"Adjust to zoom in or out of the pattern."` — category `AS_CAT_ANIMATION` |

**Audio Reactivity** (category literal: `"Audio Reactivity"`):

```hlsl
AS_AUDIO_UI(MasterAudioSource, "Audio Source", AS_AUDIO_BASS, "Audio Reactivity")
AS_AUDIO_GAIN_UI(AudioGain_GradientEffect,    "Gradient",         AUDIO_GAIN_GRADIENT_MAX,        AUDIO_GAIN_GRADIENT_DEFAULT)
AS_AUDIO_GAIN_UI(AudioGain_LineBrightness,    "Line Brightness",  AUDIO_GAIN_LINE_BRIGHTNESS_MAX, AUDIO_GAIN_LINE_BRIGHTNESS_DEFAULT)
AS_AUDIO_GAIN_UI(AudioGain_LineFalloff,       "Line Softness",    AUDIO_GAIN_LINE_FALLOFF_MAX,    AUDIO_GAIN_LINE_FALLOFF_DEFAULT)
AS_AUDIO_GAIN_UI(AudioGain_SparkleMagnitude,  "Sparkle Amount",   AUDIO_GAIN_SPARKLE_MAG_MAX,     AUDIO_GAIN_SPARKLE_MAG_DEFAULT)
AS_AUDIO_GAIN_UI(AudioGain_Zoom,              "Zoom",             AUDIO_GAIN_ZOOM_MAX,            AUDIO_GAIN_ZOOM_DEFAULT)
```

**Stage & Depth**:

```hlsl
AS_STAGEDEPTH_UI(EffectDepth)
```

**Final Mix**:

```hlsl
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)
```

### 4.4 Technique declaration

```hlsl
technique AS_BGX_Constellation <
    ui_label = "[AS] BGX: Constellation";
    ui_tooltip = "Dynamic cosmic constellation pattern with twinkling stars and connecting Lines.\n"
                 "Perfect for cosmic, night sky, or abstract network visualizations.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Constellation;
    }
}
```

---

## 5. Behavior specification

### 5.1 Required pixel shader pipeline

1. Read original backbuffer color (needed for final blend).

2. Compute animation time: `AS_getAnimationTime(TimeSpeed, TimeKeyframe)`.

3. Compute normalized, centered, aspect-independent UV from `texcoord * ReShade::ScreenSize` and `ReShade::ScreenSize.y`.

4. Compute master audio level once: `AS_audioLevelFromSource(MasterAudioSource)`.

5. Apply audio-modulated zoom to the UV:
   ```
   audioBoostedZoom = Zoom * (1 + audioLevel * AudioGain_Zoom)
   normalizedUV /= audioBoostedZoom
   ```

6. Apply continuous slow rotation of the UV using time. The rotation must be smooth and non-periodic-feeling over short viewing windows.

7. Render the star/line field **in multiple parallax layers**. Each layer:
   - Is rendered at a different scale (zoom) than its neighbors.
   - Has a fade-in-then-fade-out opacity envelope driven by time, so layers appear to cycle through a depth axis.
   - Contributes brightness additively to an accumulator.
   
   The specific number of layers, their scale ratios, and their timing formula are **your choice**. The visible result must be multiple star-scales simultaneously present, with smooth cross-fading.

8. Inside each layer:
   - Generate a stable, deterministic field of star points based on a spatial grid and a hash seeded from the grid coordinate. Use `AS_hash22` (from `AS_Noise.1.fxh`) for stability.
   - Animate each star's position slowly over time by an amount small relative to its grid cell, so they drift without swapping neighbors.
   - For each pixel, find the nearby stars and:
     - Add a soft point-glow contribution for each star, falling off with distance. Sharpness is controlled by `SparkleSharpness`, base intensity by `SparkleBaseIntensity`.
     - Add a per-star twinkle oscillation: magnitude `SparkleTwinkleMagnitude` (audio-boosted), speed `SparkleTwinkleSpeed`, per-star phase offset scaled by `SparklePhaseVariation`. Stars with different phase offsets should twinkle out-of-sync.
     - Draw line segments from each star to several of its neighbors. Lines have:
       - A bright core of width `LineCoreThickness`.
       - A soft falloff outside the core of width `audioBoostedFalloffWidth = LineFalloffWidth * (1 + audioLevel * AudioGain_LineFalloff)` (clamp to min 0.001).
       - Brightness modulated by line length, blended with `LineLengthModStrength` (1.0 = full length modulation, 0.0 = no modulation).
   - Which neighbors each star connects to is your choice, but the topology must be **stable** (same neighbors every frame).

9. Accumulate brightness across layers weighted by each layer's opacity envelope.

10. Compute a time-varying palette color vector:
    ```
    palette = sin(mainAnimationTime * PaletteTimeScale * PaletteColorPhaseFactors) * PaletteColorAmplitude + PaletteColorBias
    ```
    where `mainAnimationTime` is a slow-scaled animation time. The resulting `palette` is a `float3` that varies smoothly over time.

11. Compute final color:
    ```
    audioBoostedBrightness = LineOverallBrightness * (1 + audioLevel * AudioGain_LineBrightness)
    finalColor = accumulatedBrightness * audioBoostedBrightness * palette
    ```

12. Apply vertical gradient darkening:
    ```
    audioModulatedGradient = audioLevel * AudioGain_GradientEffect
    gradientEffect = (normalizedUV.y) * audioModulatedGradient * 2
    finalColor -= gradientEffect * palette
    ```
    (The `* palette` term preserves color tinting of the fade.)

13. Compute depth mask:
    ```
    depthMask = AS_isInFrontOfStage(texcoord, EffectDepth) ? 0.0 : 1.0
    ```

14. Composite:
    ```
    return float4(AS_composite(saturate(finalColor), originalColor.rgb, BlendMode, BlendStrength * depthMask), 1.0)
    ```

### 5.2 Audio reactivity summary

For reference during implementation, every audio-reactive parameter follows the pattern `param * (1 + audioLevel * gain)`:

| Parameter | Gain |
|---|---|
| `LineOverallBrightness` | `AudioGain_LineBrightness` |
| `SparkleTwinkleMagnitude` | `AudioGain_SparkleMagnitude` |
| `LineFalloffWidth` | `AudioGain_LineFalloff` (then `max(0.001, ...)`) |
| `Zoom` | `AudioGain_Zoom` |
| Gradient effect | `AudioGain_GradientEffect` (multiplied directly with audioLevel, not `1+`) |

### 5.3 Stability guarantees

- Star positions must be **stable**: same star in same location frame-to-frame (they may drift slowly, but must not teleport or reshuffle).
- Connection topology must be **stable**: the same star connects to the same neighbors frame-to-frame.
- The only things that vary per-frame are: drift offsets, twinkle phase, rotation angle, palette color, layer fade cycle.

### 5.4 Namespace and guard

```hlsl
#ifndef __AS_BGX_Constellation_1_fx
#define __AS_BGX_Constellation_1_fx

// ... includes ...

namespace AS_Constellation {
    // all constants, uniforms, helpers, pixel shader
} // namespace AS_Constellation

// technique declaration (outside namespace)

#endif
```

### 5.5 Required includes (in this order)

```hlsl
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Noise.1.fxh"
```

---

## 6. Acceptance criteria

The implementation is complete when all of the following hold:

1. Shader compiles cleanly with ReShade FX compiler — no errors, no undeclared symbols.
2. `[AS] BGX: Constellation` entry appears in the shader list with the tooltip text from §4.4.
3. Every UI parameter in §4.3 appears with the exact name, range, default, step, tooltip, and category.
4. On load at default settings: visible constellation pattern — twinkling stars connected by soft glowing lines on a dark background, gently rotating, with slowly-cycling colors.
5. Changing each Lines parameter produces the advertised effect (thicker lines, softer edges, brighter lines, length-based brightness modulation).
6. Changing each Stars parameter produces the advertised effect (sharper/softer points, brighter points, faster/slower twinkle, bigger/smaller twinkle magnitude, more/less phase variation between stars).
7. Stars remain in stable positions frame-to-frame (no random reshuffling).
8. The connection topology is stable frame-to-frame.
9. Multiple parallax layers are visible simultaneously, with layers fading in and out cyclically.
10. `PaletteTimeScale` visibly controls how fast colors cycle; setting it to 0 freezes colors.
11. `Zoom` zooms in/out of the pattern.
12. With Listeningway running, audio reactivity visibly pulses each of: line brightness, line softness, sparkle amount, zoom, gradient darkening.
13. `EffectDepth` correctly masks the effect behind scene geometry.
14. `BlendMode` / `BlendStrength` correctly composite the effect.

---

## 7. Non-goals

- No requirement for byte-exact reproduction of any prior implementation.
- No requirement for any specific star-placement or neighbor-selection scheme, so long as topology is stable.
- Any stable, continuous pattern-generation technique that satisfies §3 and §6 is acceptable.
- Do NOT attempt to reconstruct anyone else's formula — use your own.

---

## 8. Deliverable

A single file at `shaders/AS/AS_BGX_Constellation.1.fx` with:
- `Author: <your name or identifier>` in the header
- `License: Creative Commons Attribution 4.0 International` in the header
- No mention of any upstream shader, prior author, or external source
- Implementation complete per §5, UI per §4, acceptance criteria per §6.
