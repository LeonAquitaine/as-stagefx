/**
 * AS_CodeStandards.md - Coding Standards for AS StageFX Shaders
 * Author: Leon Aquitaine
 * Created: April 23, 2025
 * 
 * This document outlines the coding standards and file organization principles
 * for all shaders in the AS StageFX collection. Following these standards ensures
 * consistency, maintainability, and readability across the codebase.
 */

# AS_StageFX Code Standards

This document outlines the coding standards and best practices for the AS_StageFX shader collection. All new and updated shaders should follow these guidelines to maintain consistency across the project.

## File Structure and Naming

- **File Naming**: Use the format `AS_EffectName.Version.fx` (e.g., `AS_LavaLamp.1.fx`)
- **Include Headers**: Include in this order:
  - `ReShade.fxh`
  - `ReShadeUI.fxh`
  - `ListeningwayUniforms.fxh` (if audio reactivity is used)
  - `AS_Utils.1.fxh`

## Versioning System

All shader and utility files use a version suffix (e.g., `.1.fx`, `.1.fxh`). The current collection is version 1. A new version will be created whenever it is necessary to 'break the contract'-for example, if the behavior of uniforms or their expected functions changes in a way that could break compatibility with existing presets. This approach ensures backward compatibility and clarity for users and maintainers.

## Header Documentation

All shader files should begin with a standardized header following this format:

```hlsl
/**
 * AS_ShaderName.Version.fx - Brief description
 * Author: Author Name
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Detailed description of what the shader does (2-4 sentences).
 *
 * FEATURES:
 * - Feature 1
 * - Feature 2
 * - ...
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Step 1 of how the effect works
 * 2. Step 2 of how the effect works
 * 3. ...
 * 
 * ===================================================================================
 */
```

## Uniform Organization

Organize uniforms in logical sections with consistent naming. Use these standard categories (in this order):

1. **Tunable Constants** - Constants at the top, e.g., min/max values that might need tuning
2. **Palette & Style** - Color palette and style settings
3. **Effect-Specific Appearance** - Named for the specific effect (e.g., "Sparkle Appearance")
4. **Animation** - Animation parameters if applicable
5. **Audio Reactivity** - Listeningway integration parameters (use standard macros)
6. **Stage Distance** - Depth parameters for positioning the effect
7. **Final Mix** - Blend mode and strength settings
8. **Debug** - Debug visualization options (using the standard macro)
9. **System Uniforms** - frameCount, etc.

## UI Tunable Constants

UI uniforms must have tunable constants declared at the beginning of a file, following a specific naming convention:
- Use `_MIN`, `_MAX`, and `_DEFAULT` (or `_DEF`) suffixes for each tunable range
- Group related tunables together
- Include comments for any constants with non-obvious purposes

Example:
```hlsl
// --- Tunable Constants ---
static const float RADIUS_MIN = 0.1;
static const float RADIUS_MAX = 0.5;
static const float RADIUS_DEFAULT = 0.25; // Base radius before audio modification

static const float THICKNESS_MIN = 0.01;
static const float THICKNESS_MAX = 0.15; 
static const float THICKNESS_DEFAULT = 0.05; // Line thickness in screen-space units

static const int REPETITIONS_MIN = 1;
static const int REPETITIONS_MAX = 8;     // Maximum supported by the algorithm
static const int REPETITIONS_DEFAULT = 3; // 2^3 = 8 actual repetitions
```

These constants should then be referenced in the uniform declarations to ensure consistency:

```hlsl
uniform float Radius < ui_type = "slider"; ui_label = "Radius"; 
  ui_min = RADIUS_MIN; ui_max = RADIUS_MAX; ui_step = 0.01; 
  ui_category = "Effect-Specific Appearance"; > = RADIUS_DEFAULT;
```

## UI Control Standardization

- Use standardized UI parameter names where applicable:
  - `BlendMode` for the blend mode dropdown
  - `BlendAmount` for blend strength
  - `EffectDepth` or similar for depth control
  - `DebugMode` using the standard debug macro
  
- Use consistent category naming and tooltips for similar parameters

## Audio Reactivity

- Always use the standard macros from `AS_Utils.1.fxh`:
  - `AS_LISTENINGWAY_UI_CONTROLS` for enabling Listeningway
  - `AS_AUDIO_SOURCE_UI` for source selection
  - `AS_AUDIO_MULTIPLIER_UI` for intensity control
  - `AS_getAudioSource`/`AS_applyAudioReactivity` for implementation

## Namespaces and Helper Functions

- Place effect-specific helper functions in a namespace matching the effect name:
  ```hlsl
  namespace AS_EffectName {
      // Helper functions here
  }
  ```

- Use descriptive function names that explain their purpose
- Comment complex algorithms and mathematics

## Technique Definition

- Use a consistent naming convention:
  ```hlsl
  technique AS_EffectName < ui_label = "[AS] Effect Name"; ui_tooltip = "Brief description"; > {
      // passes here
  }
  ```

## Code Quality and Performance

- Add comments to explain complex algorithms or effects
- Structure pixel shaders with consistent sections (get original pixel, apply depth cutoff, effect logic, blending)
- Use namespaced functions to keep the main shader code clean and readable
- Provide performance options when appropriate for complex effects
- Use inline comments to explain tuning values and constants

## Standard Macros and Utilities

Standardized macros for consistent UI elements are provided in `AS_Utils.1.fxh`:

- `AS_DEBUG_MODE_UI("Off\0Option1\0Option2\0")`
- `AS_LISTENINGWAY_UI_CONTROLS("Category Name")`
- `AS_AUDIO_SOURCE_UI(VarName, "Label", DefaultValue, "Category")`
- `AS_AUDIO_MULTIPLIER_UI(VarName, "Label", DefaultValue, MaxValue, "Category")`

## Depth Handling

All effects should have consistent depth handling:

```hlsl
float4 orig = tex2D(ReShade::BackBuffer, texcoord);
float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
if (sceneDepth < EffectDepth - 0.0005)
    return orig;
```

## Blend Modes

Use the standard `AS_blendResult` function from `AS_Utils.1.fxh` for consistent blending behavior across all effects.