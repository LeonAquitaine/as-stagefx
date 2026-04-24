# AS_BGX_LiquidChrome — Implementation Specification

**Spec version**: 1.0
**Target file**: `shaders/AS/AS_BGX_LiquidChrome.1.fx`
**Shader category**: Background Effect (BGX)
**Framework**: AS-StageFX for ReShade
**Deliverable license**: CC BY 4.0 (project original)

---

## 1. Clean-room constraints — READ BEFORE IMPLEMENTING

**This is a blind reimplementation. You must produce this shader without referencing any existing implementation.**

- You MUST NOT read, grep, or search for any file that implements a shader with this or a similar name — neither in this repository, nor on Neort, nor on Shadertoy, nor in any other source.
- You MUST NOT ask for the previous version's source code.
- You MUST NOT copy fragments from any "liquid chrome", "chrome fluid", iterative sin/cos warping, or similar shader you may have encountered before.
- You MAY use any technique of your own choosing that produces the observable behavior below.
- If you are unsure about an implementation detail, ask the maintainer — do not infer by examining similar shaders.

Your output is a genuinely new implementation whose copyright belongs to its author.

---

## 2. Purpose

A full-screen background effect that produces a flowing chrome/metallic-looking surface with rippling concentric color bands that evolve continuously over time. An optional vertical-stripe overlay adds a glossy "reflected blinds" or "scan line" character on top. The effect is audio-reactive and participates in AS-StageFX standard controls (position, rotation, scale, depth masking, blend).

---

## 3. Visual character

The shader must produce output with all of these observable properties:

- **Fills the whole screen.** No transparent gaps, no hard edges.
- **Liquid metal appearance**: the pattern reads as a reflective chrome / liquid mercury surface being slowly agitated — smooth warping with strong concentric banding, not chaotic noise.
- **Flowing concentric color bands.** Colored rings/bands radiate outward from shifting centers, forming a moiré-like organic pattern. Bands shift and re-form continuously.
- **Independent horizontal and vertical motion.** The pattern "breathes" at different rates along the X and Y axes. Horizontal and vertical flow have independent speed and amplitude controls.
- **Optional vertical stripe overlay.** When enabled, bright vertical stripes are additively layered onto the pattern, suggesting reflected blinds or light streaks. Multiple stripe layers can be stacked at different spacings. Fully disableable (set count to 0).
- **Per-channel hue controls.** Users can independently shift the "color cycle position" for R, G, and B channels, producing a huge range of palettes from silvery monochrome to full iridescence.
- **Red-channel asymmetry.** Only the red channel has an intensity multiplier — users can boost or dim red relative to green and blue. Green and blue have phase-only controls.
- **Peculiarity the user expects**: the **Blue** hue cycle slider moves the blue channel's color phase in the **opposite** direction from Red and Green sliders. Preserve this quirk — users have presets depending on it.
- **Edge tint gradient.** A user-configurable tint color is mixed in with increasing strength toward the edges of the pattern frame (i.e., distance from the post-transform center). Strength is very subtle by default.
- **User-controlled pattern detail (zoom).** A single master scale parameter zooms into the pattern, trading field-of-view for detail.
- **User-controlled warp complexity.** A separate parameter controls how many "folds" the iterative warping produces; more = more intricate distortion.
- **Responds to position, rotation, and scale** without visual artifacts.
- **Responds to audio** on the user-selected target parameter (flow speed, color cycle, or pattern scale).

---

## 4. UI contract (EXACT — users have saved presets)

### 4.1 Shader descriptor (first uniform)

```hlsl
uniform int as_shader_descriptor < ui_type = "radio"; ui_label = " "; ui_text = "\nLiquid Chrome - Flowing metallic background effect\nLicense: CC BY 4.0\n\n"; >;
```

### 4.2 Uniforms — exact declarations required

All `ui_type` values below are `"drag"` unless noted. All tooltips are **exact** and must match verbatim.

**Pattern Shape category** (`ui_category = "Pattern Shape"`):

| Uniform | Type | ui_min | ui_max | ui_step | Default | ui_label | Tooltip (exact) |
|---|---|---|---|---|---|---|---|
| `coord_scale` | `float` drag | `1.0` | `50.0` | `0.1` | `10.0f` | `"Pattern Detail Scale"` | `"Adjusts the overall size of the psychedelic patterns. Higher values zoom in, revealing finer details and faster perceived motion."` |
| `warp_iterations` | `int` drag | `1` | `20` | `1` | `5` | `"Warp Complexity"` | `"Increases the intricacy and 'folding' of the core warped pattern. More iterations lead to deeper, more detailed distortions."` |

**Color Pattern category** (`ui_category = "Color Pattern"`):

| Uniform | Type | ui_min | ui_max | ui_step | Default | ui_label | Tooltip (exact) |
|---|---|---|---|---|---|---|---|
| `len_post_warp_cos_factor` | `float` drag | `0.0` | `2.0` | `0.01` | `0.4f` | `"Color Band Frequency"` | `"Adjusts the density of color bands or concentric rings overlaying the pattern. Higher values create more, tighter bands."` |
| `len_post_warp_subtract` | `float` drag | `-20.0` | `20.0` | `0.1` | `10.0f` | `"Color Band Offset"` | `"Shifts the phase or starting point of the color banding/ring pattern, affecting color distribution."` |

**Vertical Lines category** (`ui_category = "Vertical Lines"`):

| Uniform | Type | ui_min | ui_max | ui_step | Default | ui_label | Tooltip (exact) |
|---|---|---|---|---|---|---|---|
| `stripe_iterations` | `int` drag | `0` | `10` | `1` | `5` | `"Vertical Line Layers"` | `"Number of overlaid vertical stripe patterns. Each layer adds more lines with different spacing. Set to 0 to disable stripes."` |
| `stripe_period_base` | `float` drag | `0.005` | `0.5` | `0.001` | `0.09f` | `"Vertical Line Spacing"` | `"Controls the fundamental spacing of the vertical line patterns. Smaller values create denser, more frequent lines."` |
| `stripe_scale` | `float` drag | `10.0` | `1000.0` | `1.0` | `200.0f` | `"Vertical Line Sharpness"` | `"Adjusts the sharpness or definition of the vertical lines. Higher values can make lines thinner and more pronounced."` |

**Color Tuning category** (`ui_category = "Color Tuning"`):

| Uniform | Type | ui_min | ui_max | ui_step | Default | ui_label | Tooltip (exact) |
|---|---|---|---|---|---|---|---|
| `color_phase_r` | `float` drag | `-AS_TWO_PI` | `AS_TWO_PI` | `0.01` | `0.2f` | `"Red Hue Cycle"` | `"Shifts the color palette by adjusting the cycle for the red channel. Experiment for different color schemes."` |
| `color_phase_g` | `float` drag | `-AS_TWO_PI` | `AS_TWO_PI` | `0.01` | `0.1f` | `"Green Hue Cycle"` | `"Shifts the color palette by adjusting the cycle for the green channel."` |
| `color_phase_b` | `float` drag | `-AS_TWO_PI` | `AS_TWO_PI` | `0.01` | `-0.05f` | `"Blue Hue Cycle"` | `"Shifts the color palette by adjusting the cycle for the blue channel."` |
| `color_r_multiplier` | `float` drag | `0.0` | `3.0` | `0.01` | `1.15f` | `"Red Intensity"` | `"Controls the overall intensity or brightness of the red color channel."` |
| `background_gradient_strength` | `float` drag | `0.0` | `0.1` | `0.001` | `0.01f` | `"Distortion Tint Strength"` | `"Controls the intensity of a color tint that is mixed in based on the final warped coordinates."` |
| `background_base_color` | `float4` color | | | | `float4(0.05, 0.07, 0.10, 0.0)` | `"Distortion Tint Color"` | `"Sets the color of the tint mixed in based on the final warped coordinates, affecting the overall image tone."` |

**Animation Controls category** (`ui_category = AS_CAT_ANIMATION`):

```hlsl
AS_ANIMATION_SPEED_UI(LiquidChrome_AnimationSpeed, AS_CAT_ANIMATION)
AS_ANIMATION_KEYFRAME_UI(LiquidChrome_AnimationKeyframe, AS_CAT_ANIMATION)
```

| Uniform | Type | ui_min | ui_max | ui_step | Default | ui_label | Tooltip (exact) |
|---|---|---|---|---|---|---|---|
| `warp_time_factor_x` | `float` drag | `0.0` | `0.5` | `0.001` | `0.07f` | `"Horizontal Flow Speed"` | `"Controls the speed of the horizontal animation or 'breathing' in the main warp pattern."` |
| `warp_offset_amp_x` | `float` drag | `0.0` | `1.0` | `0.01` | `0.2f` | `"Horizontal Flow Strength"` | `"Determines how much the pattern animates or 'breathes' along the horizontal axis."` |
| `warp_time_factor_y` | `float` drag | `0.0` | `0.5` | `0.001` | `0.1f` | `"Vertical Flow Speed"` | `"Controls the speed of the vertical animation or 'undulation' in the main warp pattern."` |

**Audio Reactivity Controls** (`ui_category = AS_CAT_AUDIO`):

```hlsl
AS_AUDIO_UI(LiquidChrome_AudioSource, "Audio Source", AS_AUDIO_BEAT, AS_CAT_AUDIO)
AS_AUDIO_MULT_UI(LiquidChrome_AudioMultiplier, "Audio Intensity", 1.0, 2.0, AS_CAT_AUDIO)
```

| Uniform | Type | ui_items | Default | ui_label | Tooltip (exact) |
|---|---|---|---|---|---|
| `LiquidChrome_AudioTarget` | `int` combo | `"None\0Flow Speed\0Color Cycle\0Pattern Scale\0"` | `2` | `"Audio Target"` | `"Select which parameter will be modulated by audio"` — `ui_category = AS_CAT_AUDIO` |

**Stage Controls**:

```hlsl
AS_STAGEDEPTH_UI(LiquidChrome_EffectDepth)
AS_ROTATION_UI(LiquidChrome_SnapRotation, LiquidChrome_FineRotation)
AS_POSITION_SCALE_UI(LiquidChrome_Position, LiquidChrome_Scale)
```

**Blend Controls**:

```hlsl
AS_BLENDMODE_UI(LiquidChrome_BlendMode)
AS_BLENDAMOUNT_UI(LiquidChrome_BlendAmount)
```

### 4.3 Technique declaration

```hlsl
technique AS_BGX_LiquidChrome <
    ui_label = "[AS] BGX: Liquid Chrome";
    ui_tooltip = "Creates dynamic, flowing psychedelic patterns reminiscent of liquid metal or chrome.";
>
{
    pass LiquidChrome_Pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_LiquidChrome;
    }
}
```

### 4.4 Structural note

The current implementation declares uniforms and the pixel shader at **file scope** (no namespace). For consistency with other AS-StageFX shaders you MAY wrap everything in `namespace AS_LiquidChrome { ... }` — preset compatibility is unaffected either way since all relevant uniforms use the `LiquidChrome_` prefix. Either choice is acceptable.

---

## 5. Behavior specification

### 5.1 Required pixel shader pipeline

1. **Depth early-return** at the top: `AS_DEPTH_EARLY_RETURN(texcoord, LiquidChrome_EffectDepth)`.

2. **Animation time**: `time = AS_getAnimationTime(LiquidChrome_AnimationSpeed, LiquidChrome_AnimationKeyframe)`.

3. **Audio modulation** — compute once per pixel:
   ```
   audioMod = AS_audioModulate(1.0, LiquidChrome_AudioSource, LiquidChrome_AudioMultiplier, true, 0) - 1.0
   ```
   (The `-1.0` makes `audioMod` equal the audio *delta*, i.e., zero when audio is silent.) Then derive three local multipliers based on `LiquidChrome_AudioTarget`:
   
   | Target value | meaning | `flowSpeedMod` | `colorCycleMod` | `patternScaleMod` |
   |---|---|---|---|---|
   | 0 | None | `1.0` | `0.0` | `1.0` |
   | 1 | Flow Speed | `1.0 + audioMod` | `0.0` | `1.0` |
   | 2 | Color Cycle | `1.0` | `audioMod * 0.5` | `1.0` |
   | 3 | Pattern Scale | `1.0` | `0.0` | `1.0 + audioMod` |

4. **Coordinate transform (in this order)**:
   - Center with aspect correction: `centered_coord = AS_centeredUVWithAspect(texcoord, ReShade::AspectRatio)`
   - Rotate around center using angle `AS_getRotationRadians(LiquidChrome_SnapRotation, LiquidChrome_FineRotation)`, using the **inverse** rotation direction (i.e., `sincos(-angle, ...)`)
   - Apply scale: divide by `LiquidChrome_Scale`
   - Subtract `LiquidChrome_Position` (x, y)
   - Save a copy as `st` (needed later for the stripe overlay and the edge tint)
   - Multiply the working copy by `coord_scale * patternScaleMod` to expand to pattern working space

5. **Iterative warping (Pattern Shape)** — run `warp_iterations` passes of a smooth coordinate-warping step. Each pass must:
   - Depend on the previous pass's coordinate
   - Include a time-driven horizontal term modulated by `warp_time_factor_x * flowSpeedMod` with amplitude `warp_offset_amp_x`
   - Include a time-driven vertical term modulated by `warp_time_factor_y * flowSpeedMod`
   - Produce smooth, continuously-varying output (no discontinuities)
   
   After the loop ends, save the current `length(coord)` as `len` (the coordinate's magnitude — this is what the color bands will be computed from).
   
   **The exact warping formula is your choice**, but the output must match §3: chrome-like, fluid, breathing horizontally and vertically independently, with more "folds" at higher iteration counts.

6. **Band shaping**: transform `len` so that subsequent color-cycle computations produce concentric bands. The transform must:
   - Scale with `len_post_warp_cos_factor` (higher = denser bands)
   - Offset by `-len_post_warp_subtract` (phase shift of the banding pattern)
   
   Any monotonic-in-len-with-oscillation shape that achieves the observable "concentric bands" look is acceptable.

7. **Vertical stripe overlay** (only if `stripe_iterations > 0`):
   - Re-aspect-correct `st` into a [0..1]-style stripe coordinate (`stripe_coords`): if `aspectRatio >= 1.0` divide `stripe_coords.x /= aspectRatio`, else multiply `stripe_coords.y *= aspectRatio`. Add `0.5`. Clamp to `[0, 1]`.
   - For each layer `i` in `[0, stripe_iterations)`:
     - `current_stripe_period = stripe_period_base * (i + 1)`
     - Add to `len`: `1.0 / (abs(AS_mod(stripe_coords.x, current_stripe_period) * stripe_scale) + AS_STABILITY_EPSILON)`
   - This adds bright vertical peaks where `stripe_coords.x` is near a multiple of each period.

8. **Color generation** — compute each RGB channel by cycling `len` through a periodic function offset by the per-channel phase uniforms. The expected behavior:
   - Red channel: base cycle + `color_phase_r` + `colorCycleMod`, then multiplied by `color_r_multiplier`
   - Green channel: base cycle + `color_phase_g` + `colorCycleMod`
   - Blue channel: base cycle **minus** `color_phase_b` + `colorCycleMod` **← note the inverted sign of the blue phase — this is an intentional asymmetry required for preset compatibility**
   - A cosine-based cycle is idiomatic but any smooth 2π-periodic function may be used consistently across all three channels.

9. **Edge tint gradient** — compute `distanceFromCenter = length(st)` (on the pre-warp centered coords), then:
   ```
   color = lerp(color, background_base_color.rgb, distanceFromCenter * background_gradient_strength)
   ```
   This tints pixels increasingly toward the frame edges with the user's tint color.

10. **Composite**:
    ```
    return float4(AS_composite(color, _as_originalColor.rgb, LiquidChrome_BlendMode, LiquidChrome_BlendAmount), 1.0);
    ```

### 5.2 Audio reactivity summary (reference table)

| Audio Target | Modulated parameter | How |
|---|---|---|
| None | — | — |
| Flow Speed | warp time factors (both X and Y) | Multiplied by `flowSpeedMod` |
| Color Cycle | per-channel color phase | Added as `colorCycleMod` (scaled `audioMod * 0.5`) |
| Pattern Scale | `coord_scale` | Multiplied by `patternScaleMod` |

### 5.3 Technique guard

```hlsl
#ifndef __AS_BGX_LiquidChrome_1_fx
#define __AS_BGX_LiquidChrome_1_fx

// ... includes and declarations ...

#endif // __AS_BGX_LiquidChrome_1_fx
```

### 5.4 Required includes (in this order)

```hlsl
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
```

---

## 6. Acceptance criteria

The implementation is complete when all of the following hold:

1. Shader compiles cleanly with ReShade FX compiler — no errors, no undeclared symbols.
2. `[AS] BGX: Liquid Chrome` entry appears in the shader list with the tooltip text from §4.3.
3. Every UI parameter in §4.2 appears with the exact name, range, default, step, tooltip, and category.
4. On load with defaults: the screen shows a chrome-like flowing pattern with visible concentric color bands, moving continuously, with faint vertical stripes overlaid.
5. Increasing `coord_scale` visibly zooms into the pattern (more detail visible).
6. Increasing `warp_iterations` visibly increases folding / intricacy.
7. Adjusting `len_post_warp_cos_factor` visibly changes band density; `len_post_warp_subtract` visibly phase-shifts the bands.
8. Setting `stripe_iterations` to 0 completely removes the vertical stripe overlay; increasing it adds more stripe layers at progressively larger spacings.
9. Adjusting `color_phase_r`, `color_phase_g`, and `color_phase_b` sliders produces visible hue shifts.
10. Verify the **blue channel phase asymmetry**: moving `color_phase_b` produces a hue shift in the opposite direction from `color_phase_r` and `color_phase_g` at equivalent slider values.
11. `color_r_multiplier` visibly boosts/dims the red channel without affecting green or blue.
12. `background_gradient_strength` + `background_base_color` visibly tint frame edges when above zero.
13. Horizontal and vertical flow speeds are visually independent — setting one to 0 and the other to high should show motion in only one axis.
14. Audio reactivity (with Listeningway running) pulses the parameter selected by `LiquidChrome_AudioTarget`. Setting to `None` disables audio effect entirely.
15. `LiquidChrome_EffectDepth` properly masks the effect behind scene geometry.
16. `LiquidChrome_Position`, `LiquidChrome_Scale`, `LiquidChrome_SnapRotation` + `LiquidChrome_FineRotation` pan/zoom/rotate without artifacts.
17. `LiquidChrome_BlendMode` / `LiquidChrome_BlendAmount` correctly composite the effect.

---

## 7. Non-goals

- No requirement for byte-exact visual reproduction of any prior implementation.
- No requirement for any specific mathematical formulation of the iterative warp, band-shaping, or color-cycling operations.
- Any warping technique that produces the observable chrome/metallic character described in §3 is acceptable.
- Do NOT attempt to reconstruct anyone else's formula — use your own.

---

## 8. Deliverable

A single file at `shaders/AS/AS_BGX_LiquidChrome.1.fx` with:
- `Author: <your name or identifier>` in the header
- `License: Creative Commons Attribution 4.0 International` in the header
- No mention of any upstream shader, prior author, or external source
- Implementation complete per §5, UI per §4, acceptance criteria per §6.
