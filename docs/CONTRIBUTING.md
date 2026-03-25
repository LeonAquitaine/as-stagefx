# Contributing to AS StageFX

Thanks for your interest in improving AS StageFX! This project follows SoC, KISS, YAGNI, and DRY principles. Please use the standards below to keep the codebase consistent and maintainable.

## Quick checklist

- Preserve public-facing names: shader filenames, technique names, and uniform names are backward compatible across minor versions.
- Use canonical helpers from `AS_Utils.1.fxh` (see Function Reference below).
- Avoid legacy/shim names. If you find one, migrate call sites and remove the shim.
- Keep effects resolution independent (Aspect: `ReShade::AspectRatio`, helpers in `AS_Utils`).
- Group UI uniforms with `AS_CAT_*` category constants (see Category Constants below).
- Use single-line uniform declarations (required for parsing tools).
- Every shader must include an `as_shader_descriptor` uniform for attribution and metadata display.

## Function reference

### Current canonical functions

| Area | Function | Purpose |
|------|----------|---------|
| Transform | `AS_transformUVCentered` | Center-based UV transform |
| Transform | `AS_applyPositionAndScale` | Apply position and scale to UV |
| Rotation | `AS_rotate2D` | 2D rotation of a point |
| Time | `AS_timeSeconds` | Current time in seconds |
| Audio | `AS_audioLevelFromSource` | Raw audio level from a source index |
| Audio | `AS_audioModulate` | Modulate a value by audio (with mode) |
| Audio | `AS_audioModulateMul` | Modulate a value by audio (multiply only) |
| Compositing | `AS_composite` | Blend effect RGB with background using blend mode |
| Compositing | `AS_compositeRGBA` | RGBA variant preserving background alpha |
| Color | `AS_adjustSaturation` | Adjust color saturation |
| Color | `AS_srgbToLinear` | sRGB to linear conversion |
| Color | `AS_linearToSrgb` | Linear to sRGB conversion |
| Blending | `AS_blendRGB`, `AS_blendRGBA` | Low-level blend operations |
| SDF | `AS_sdfBox` | Signed distance for box shapes |
| Math | `AS_mod`, `AS_EPSILON`, `AS_EPS_SAFE` | Safe modulo and epsilon constants |
| Hash | `AS_hash11`, `AS_hash21`, `AS_hash12` | Fast hash functions |

### Deprecated functions -- do not use

These shims exist for backward compatibility and will be removed in v2.0:

| Deprecated | Replacement |
|------------|-------------|
| `AS_applyAudioReactivity` | `AS_audioModulate` |
| `AS_applyAudioReactivityEx` | `AS_audioModulate` |
| `AS_getAudioSource` | `AS_audioLevelFromSource` |
| `AS_getTime` | `AS_timeSeconds` |
| `AS_applyRotation` | `AS_rotate2D` |
| `AS_applyCenteredUVTransform` | `AS_transformUVCentered` |
| `AS_applyPosScale` | `AS_applyPositionAndScale` |

## Category constants

Use `AS_CAT_*` constants for `ui_category` values. Never hardcode category strings.

Canonical ordering in a shader file:

1. Effect-specific categories (custom per shader)
2. `AS_CAT_PALETTE` -- "Palette & Style"
3. `AS_CAT_APPEARANCE` -- "Appearance"
4. `AS_CAT_ANIMATION` -- "Animation"
5. `AS_CAT_AUDIO` -- "Audio Reactivity"
6. `AS_CAT_STAGE` -- "Stage"
7. `AS_CAT_PERFORMANCE` -- "Performance"
8. `AS_CAT_FINAL` -- "Final Mix"
9. `AS_CAT_DEBUG` -- "Debug"

Additional constants available: `AS_CAT_PATTERN`, `AS_CAT_LIGHTING`, `AS_CAT_COLOR`.

## UI macros

Use the standard macros instead of writing raw uniform declarations for common controls:

- `AS_AUDIO_UI()` -- audio source selector
- `AS_AUDIO_MULT_UI()` -- audio multiplier slider
- `AS_AUDIO_TARGET_UI()` -- audio target combo
- `AS_AUDIO_GAIN_UI()` -- audio gain slider
- `AS_BLENDMODE_UI()` / `AS_BLENDMODE_UI_DEFAULT()` -- blend mode selector
- `AS_COLOR_CYCLE_UI()` -- color cycling toggle
- `AS_USE_PALETTE_UI()` -- palette enable toggle
- `AS_BACKGROUND_COLOR_UI()` -- background color picker

## Noise library

Noise functions are split across two headers:

- **`AS_Noise.1.fxh`** -- Core noise: `AS_hash*`, `AS_PerlinNoise2D`, `AS_Fbm2D`, `AS_VoronoiNoise2D`, `AS_DomainWarp2D`
- **`AS_Noise_Extended.1.fxh`** -- Advanced noise: additional algorithms for specialized effects

Include only what you need. Most shaders only require `AS_Noise.1.fxh`.

## Namespace convention

Wrap all shader-local helper functions and constants in a namespace:

```hlsl
namespace AS_EffectName {
    // helper functions, constants
}
```

Use the effect name without type prefix (e.g., `AS_BlueCorona`, not `AS_BGX_BlueCorona`).

## Shader descriptor requirement

Every shader must include an `as_shader_descriptor` uniform for attribution display in the UI:

```hlsl
uniform int as_shader_descriptor <ui_type = "radio"; ui_label = " "; ui_text = "\nBased on '...' by ...\nLink: ...\nLicence: ...\n\n";>;
```

## File structure

Organize shader files in this order:

```
TECHNIQUE GUARD -> INCLUDES -> CONSTANTS -> UI DECLARATIONS ->
HELPER FUNCTIONS (in namespace) -> PIXEL SHADER -> TECHNIQUE
```

- Shared functionality goes in `AS_Utils.1.fxh` (or noise headers for noise).
- Do not add per-shader mini-helpers that duplicate existing utilities.

## Build and validation

- Use `build-all.ps1` for local checks. Optional strict mode:
  - `pwsh ./build-all.ps1 -Strict` will fail if catalog issues exist.
- Run `validate-shader-style.ps1` to check for:
  - Deprecated function usage
  - Namespace naming convention violations
  - `fmod()` usage (use `AS_mod` instead)
  - Missing BlendMode UI
  - Technique guard naming errors
- Each package entry must have a preview GIF at `docs/res/img/as-stagefx-<name>.gif` and a valid `imageUrl` in `shaders/catalog.json`.

## Documentation

- Update docs when behavior or public knobs change.
- Add a short description header comment per shader using the template in `docs/template/shader-template.fx.example`.

## PR style

- Keep diffs minimal and focused; avoid unrelated formatting changes.
- Add or update small targeted tests (where applicable) or a quick demo preset.
- Describe the change, rationale, and impact on performance/compat.

## Code style notes

- Avoid static shader variables; they can crash in pixel shaders.
- Avoid magic numbers; use constants from `AS_Utils`.
- Prefer `AS_mod` over `fmod`, and standard helpers over ad-hoc math.

Thank you for contributing!
