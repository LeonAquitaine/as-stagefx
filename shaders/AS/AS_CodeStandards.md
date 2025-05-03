/**
 * AS_CodeStandards.md - Coding Standards for AS StageFX Shaders
 * Author: Leon Aquitaine
 * Updated: May 3, 2025
 */

# AS StageFX Code Standards

## ⚠️ CRITICAL STANDARDS ⚠️

These requirements are non-negotiable for all AS StageFX shaders:

1. **One-Line Uniform Declarations**: All uniform declarations MUST be one-liners. Multi-line uniform declarations break parsing tools and make code harder to maintain.
   ```hlsl
   // CORRECT ✓
   uniform float MyParameter < ui_type = "slider"; ui_label = "Clear Label"; ui_tooltip = "Concise explanation"; ui_min = MYPARAM_MIN; ui_max = MYPARAM_MAX; ui_step = 0.01; ui_category = "Standard Category"; > = MYPARAM_DEFAULT;
   
   // INCORRECT ✗
   uniform float MyParameter < 
       ui_type = "slider"; 
       ui_label = "Clear Label";
       ui_tooltip = "Concise explanation";
       ui_min = MYPARAM_MIN; ui_max = MYPARAM_MAX;
       ui_category = "Standard Category";
   > = MYPARAM_DEFAULT;
   ```

2. **Technique Guards**: Every shader must use proper technique guards to prevent duplicate loading.
   ```hlsl
   #ifndef __AS_LFX_ShaderName_1_fx
   #define __AS_LFX_ShaderName_1_fx
   
   // ...shader code...
   
   #endif // __AS_LFX_ShaderName_1_fx
   ```

3. **Mathematical Constants**: Always use AS_Utils constants (AS_PI, AS_TWO_PI, etc.) instead of magic numbers.

4. **Standardized UI Macros**: Use the predefined macros from AS_Utils.1.fxh for common parameters.

5. **Resolution Independence**: All effects must render consistently across different resolutions and aspect ratios.

## File Organization

- **Naming**: Use `AS_TypeCode_EffectName.Version.fx` (e.g., `AS_LFX_LaserShow.1.fx`)

- **Required Headers**:
  ```hlsl
  #include "ReShade.fxh"
  #include "AS_Utils.1.fxh"  // Always include for utilities and audio reactivity
  ```

- **Standard Header Documentation**:
  ```hlsl
  /**
   * AS_TP_ShaderName.Version.fx - Brief description
   * Author: Author Name
   * License: Creative Commons Attribution 4.0 International
   * 
   * DESCRIPTION: 2-4 sentence overview
   * FEATURES: Bullet points of key features
   * IMPLEMENTATION: Brief numbered steps of the effect's approach
   */
  ```

## Versioning

Major version numbers (`.1.fx`, `.2.fx`) indicate compatibility-breaking changes. Use when uniforms or functions change in ways that break existing presets.

## Standard Code Structure

Every shader should follow this section organization:

```hlsl
// TECHNIQUE GUARD
// INCLUDES
// POSITION
// TUNABLE CONSTANTS
// PALETTE & STYLE
// EFFECT-SPECIFIC APPEARANCE
// ANIMATION
// AUDIO REACTIVITY
// STAGE DISTANCE
// FINAL MIX
// DEBUG
// NAMESPACE & HELPERS
// MAIN PIXEL SHADER
// TECHNIQUE
```

### Uniform Organization
Organize uniforms in this exact order:
1. **Tunable Constants** - Constants with min/max/default values
2. **Palette & Style** - Color palette and visual style settings
3. **Effect-Specific Appearance** - Core parameters for the specific effect
4. **Animation** - Time-based animation parameters 
5. **Audio Reactivity** - Audio-reactive controls using standard macros
6. **Stage Distance** - Depth parameters for positioning the effect
7. **Final Mix** - Blend mode and strength settings
8. **Debug** - Debug visualization options

### Tunable Constants
```hlsl
// --- Tunable Constants ---
static const float PARAM_MIN = 0.1;
static const float PARAM_MAX = 1.0;
static const float PARAM_DEFAULT = 0.5; // Short explanation if needed
```

### Pixel Shader Structure
1. Get original pixel color and depth
2. Apply depth cutoff if applicable
3. Implement effect logic
4. Use standard blend function for compositing

## Audio Reactivity

### Key Principles
- **Use AS_Utils macros**: Don't check for Listeningway directly
- **Audio controls**: Use standard UI macros for consistency 
- **Enable parameter**: Always set to `true` in audio functions
- **Graceful degradation**: Effects should work without Listeningway

### Standard Audio Controls
```hlsl
// Define audio controls
AS_AUDIO_SOURCE_UI(Effect_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(Effect_AudioMultiplier, "Intensity", 1.0, 2.0, "Audio Reactivity")

// In pixel shader
float effectStrength = AS_applyAudioReactivity(BaseStrength, Effect_AudioSource, 
                                             Effect_AudioMultiplier, true);
```

### Audio Source Constants
- `AS_AUDIO_OFF` (0) - No reactivity
- `AS_AUDIO_SOLID` (1) - Constant value
- `AS_AUDIO_VOLUME` (2) - Overall volume
- `AS_AUDIO_BEAT` (3) - Beat detection
- `AS_AUDIO_BASS` (4) - Low frequency
- `AS_AUDIO_TREBLE` (5) - High frequency
- `AS_AUDIO_MID` (6) - Mid frequency

## Textures and Samplers
```hlsl
texture EffectBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler EffectSampler { 
    Texture = EffectBuffer; 
    AddressU = CLAMP; 
    AddressV = CLAMP; 
    MinFilter = LINEAR; 
    MagFilter = LINEAR; 
};
```

## Depth Handling
```hlsl
float4 orig = tex2D(ReShade::BackBuffer, texcoord);
float depth = ReShade::GetLinearizedDepth(texcoord);
if (depth < EffectDepth - 0.0005)
    return orig;
```

## Mathematical Constants

Always use the standardized mathematical constants from `AS_Utils.1.fxh` instead of using magic numbers:

```hlsl
// --- Mathematical Constants ---
static const float AS_PI = 3.14159265359;         // π
static const float AS_TWO_PI = 6.28318530718;     // 2π
static const float AS_HALF_PI = 1.57079632679;    // π/2
static const float AS_QUARTER_PI = 0.78539816339; // π/4
static const float AS_INV_PI = 0.31830988618;     // 1/π
static const float AS_E = 2.71828182846;          // Euler's number
static const float AS_GOLDEN_RATIO = 1.61803398875; // Golden ratio φ
```

### Examples

Instead of:
```hlsl
float angle = 3.14159 * param;  // BAD: Magic number
float sineWave = sin(time * 6.28318);  // BAD: Magic number
```

Use:
```hlsl
float angle = AS_PI * param;  // GOOD: Named constant
float sineWave = sin(time * AS_TWO_PI);  // GOOD: Named constant
```

## Code Optimization

### DRY (Don't Repeat Yourself) Principles
When implementing shaders with repetitive elements or multiple instances (layers, lights, etc.):

1. **Use UI Definition Macros**
2. **Use Parameter Structures**
3. **Extract Reusable Functions**
4. **Use Loop-Based Processing**

### Multi-Instance Effects Pattern
For effects that support multiple copies (spotlights, flames, etc.), follow this standard pattern:

1. **Define a Count Constant**:
   ```hlsl
   static const int EFFECT_COUNT = 4;  // Number of instances supported
   ```

2. **Create a UI Definition Macro**:
   ```hlsl
   #define EFFECT_UI(index, defaultEnable, defaultParams...) \
   uniform bool Effect##index##_Enable < ui_label = "Enable " #index; ui_category = "Effect " #index; ui_category_closed = index > 1; > = defaultEnable; \
   uniform float Effect##index##_Param1 < /* parameter UI definition */ > = defaultParam1; \
   // ...more parameters
   ```

3. **Use the Macro to Create Controls**:
   ```hlsl
   // First instance (enabled by default, standard positioning)
   EFFECT_UI(1, true, standardParams...)
   
   // Additional instances (disabled by default, varied positions)
   EFFECT_UI(2, false, variedParams...)
   ```

4. **Define Parameter Structure**:
   ```hlsl
   struct EffectParams {
       bool enable;
       float param1;
       float param2;
       // ...more parameters
   };
   ```

5. **Create Getter Function**:
   ```hlsl
   EffectParams GetEffectParams(int index) {
       EffectParams params;
       
       // Set shared parameters first
       params.sharedParam = GlobalSharedParam;
       
       // Set instance-specific parameters
       if (index == 0) {
           params.enable = Effect1_Enable;
           params.param1 = Effect1_Param1;
           // ...
       }
       else if (index == 1) {
           // ...parameters for second instance
       }
       // ...handle remaining instances
       
       return params;
   }
   ```

6. **Process Instances in Loop**:
   ```hlsl
   // In pixel shader
   float4 result = orig;
   
   for (int i = 0; i < EFFECT_COUNT; i++) {
       EffectParams params = GetEffectParams(i);
       
       // Skip disabled instances
       if (!params.enable) continue;
       
       // Process this instance using structure parameters
       float4 effectResult = ProcessEffect(params, uv, timer);
       
       // Blend with accumulated result
       result = BlendEffectWithResult(result, effectResult);
   }
   ```

7. **Best Practices**:
   - Only the first instance should be enabled by default
   - Use `ui_category_closed = true` for all but the first instance
   - Use slightly varied parameters for each instance for visual interest
   - Keep core processing functions isolated from UI parameters by using the parameter structure

### Performance Considerations

1. **Layer-Based Activation**:
   - Use individual enable flags rather than global layer count parameters
   - Always check the enable flag at the beginning of layer processing
   - Only the first layer should be enabled by default to provide a clean starting point

## Resolution Independence

All shaders MUST implement resolution-independent rendering:

1. **Mandatory Requirements**:
   - Size and position parameters should be specified in normalized coordinates (0.0-1.0)
   - All horizontal dimensions must be corrected for aspect ratio
   - Effects should appear visually identical regardless of screen resolution

2. **Standard Implementation**:
   ```hlsl
   // Correcting for aspect ratio in UV calculations
   float2 aspect_corrected_size = float2(EffectWidth / ReShade::AspectRatio, EffectHeight);
   
   // For position-based effects (correct placement on any resolution)
   float2 rel_uv = (texcoord - EffectPosition) / aspect_corrected_size;
   ```

3. **Position Controls**:
   - Position controls should always appear at the top of the UI in their own "Position" category
   - Primary positioning should use a drag control for intuitive visual placement
   - When precision is needed, provide slider controls as well