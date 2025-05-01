/**
 * AS_CodeStandards.md - Coding Standards for AS StageFX Shaders
 * Author: Leon Aquitaine
 * Updated: April 28, 2025
 */

# AS StageFX Code Standards

## File Organization

- **Naming**: Use `AS_TypeCode_EffectName.Version.fx` (e.g., `AS_LFX_LaserShow.1.fx`)
- **Required Headers**:
  ```hlsl
  
  
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

## Code Structure

### Tunable Constants
```hlsl
// --- Tunable Constants ---
static const float PARAM_MIN = 0.1;
static const float PARAM_MAX = 1.0;
static const float PARAM_DEFAULT = 0.5; // Short explanation if needed
```

### Uniform Organization
Organize uniforms in this order:
1. **Tunable Constants** - Constants with min/max/default values
2. **Palette & Style** - Color palette and visual style settings
3. **Effect-Specific Appearance** - Core parameters for the specific effect
4. **Animation** - Time-based animation parameters 
5. **Audio Reactivity** - Audio-reactive controls using standard macros
6. **Stage Distance** - Depth parameters for positioning the effect
7. **Final Mix** - Blend mode and strength settings
8. **Debug** - Debug visualization options

### UI Standardization
```hlsl
// Use consistent naming conventions across all shaders
uniform float MyParameter <
    ui_type = "slider";
    ui_label = "Clear Label";
    ui_tooltip = "Concise explanation";
    ui_min = MYPARAM_MIN;
    ui_max = MYPARAM_MAX;
    ui_step = 0.01;
    ui_category = "Standard Category";
> = MYPARAM_DEFAULT;
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

## Multi-Instance Effects
When defining macros for generating multiple instances:
- Pass all variable, sampler, and technique names as parameters
- Provide clear documentation and instantiation examples
- Use consistent naming conventions across instances

## Centralized Tunables

The `AS_Utils.1.fxh` file contains standardized tunable constants that should be used across all shaders for consistency:

```hlsl
// --- Stage Distance (Depth) Constants ---
#define AS_STAGEDEPTH_MIN 0.0
#define AS_STAGEDEPTH_MAX 1.0
#define AS_STAGEDEPTH_DEFAULT 0.05  // Standardized default stage depth

// --- Blend Amount Constants ---
#define AS_BLENDAMOUNT_MIN 0.0
#define AS_BLENDAMOUNT_MAX 1.0
#define AS_BLENDAMOUNT_DEFAULT 1.0

// --- Sway Animation Constants ---
#define AS_SWAYSPEED_MIN 0.0
#define AS_SWAYSPEED_MAX 5.0
#define AS_SWAYSPEED_DEFAULT 1.0

#define AS_SWAYANGLE_MIN 0.0
#define AS_SWAYANGLE_MAX 180.0
#define AS_SWAYANGLE_DEFAULT 15.0
```

### Standardized UI Macros

Use these macros from `AS_Utils.1.fxh` instead of defining your own UI controls for common parameters:

```hlsl
// Stage Depth control
AS_STAGEDEPTH_UI(StageDepth, "Distance", "Stage Distance")

// Blend Mode and Amount controls
AS_BLENDMODE_UI(BlendMode, "Final Mix")
AS_BLENDAMOUNT_UI(BlendAmount, "Final Mix")

// Sway Animation controls
AS_SWAYSPEED_UI(SwaySpeed, "Animation")
AS_SWAYANGLE_UI(SwayAngle, "Animation")

// Rotation controls (Snap in 45° increments + Fine adjustment)
AS_ROTATION_UI(SnapRotate, FineRotate, "Transform")
```

### Standardized Helper Functions

Use these helper functions for common calculations:

```hlsl
// Basic sway animation
float sway = AS_applySway(SwayAngle, SwaySpeed);

// Audio-reactive sway animation
float sway = AS_applyAudioSway(SwayAngle, SwaySpeed, AudioSource, AudioMult);
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

### Benefits
- Improves code readability and maintainability
- Ensures consistent precision across all shaders
- Centralizes values so they can be updated in one place
- Makes mathematical operations more explicit and understandable