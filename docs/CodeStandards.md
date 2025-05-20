# AS StageFX Code Standards

## ⚠️ CRITICAL STANDARDS ⚠️

These requirements are non-negotiable for all AS StageFX shaders:

1. **Resolution Independence**: All effects must render consistently across different resolutions and aspect ratios.

2. **One-Line Uniform Declarations**: All uniform declarations MUST be one-liners. Multi-line uniform declarations break parsing tools and make code harder to maintain.
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

3. **Technique Guards**: Every shader must use proper technique guards to prevent duplicate loading.
   ```hlsl
   #ifndef __AS_LFX_ShaderName_1_fx
   #define __AS_LFX_ShaderName_1_fx
   
   // ...shader code...
   
   #endif // __AS_LFX_ShaderName_1_fx
   ```

4. **Mathematical Constants**: Always use AS_Utils constants (AS_PI, AS_TWO_PI, AS_HALF, etc.) instead of magic numbers.
   ```hlsl
   // CORRECT ✓
   float radius = AS_HALF * (1.0 + sin(time * AS_TWO_PI));
   if (depth < effectDepth - AS_DEPTH_EPSILON) { return original; }
   
   // INCORRECT ✗
   float radius = 0.5 * (1.0 + sin(time * 6.28));
   if (depth < effectDepth - 0.0005) { return original; }
   ```

5. **Standardized UI Macros**: Use the predefined macros from AS_Utils.1.fxh for common parameters.

6. **Shader-Specific Texture/Sampler Prefixing**: All texture and sampler declarations MUST be prefixed with the shader name to prevent naming conflicts when multiple shaders are loaded.
   ```hlsl
   // CORRECT ✓
   texture ShaderName_EffectBuffer { ... };
   sampler ShaderName_EffectSampler { Texture = ShaderName_EffectBuffer; ... };
   
   // INCORRECT ✗
   texture EffectBuffer { ... };
   sampler EffectSampler { Texture = EffectBuffer; ... };
   ```

7. **Named Parameter Range Constants**: All UI parameter min/max/default values MUST use named constants instead of magic numbers. These should be defined at the top of the file in the constants section using the naming format PARAMETER_MIN, PARAMETER_MAX, PARAMETER_DEFAULT.
   ```hlsl
   // CORRECT ✓
   static const float RADIUS_MIN = 0.1;
   static const float RADIUS_MAX = 1.0;
   static const float RADIUS_DEFAULT = 0.5;
   
   uniform float Radius < ui_min = RADIUS_MIN; ui_max = RADIUS_MAX; /* other UI parameters */ > = RADIUS_DEFAULT;
   
   // INCORRECT ✗
   uniform float Radius < ui_min = 0.1; ui_max = 1.0; /* other UI parameters */ > = 0.5;
   ```

8. **Standardized UI Section Organization**: Each shader MUST organize UI controls into standardized sections following the exact ordering specified in the Standard Code Structure section of this document. The Animation Controls, Stage Controls, and Final Mix sections MUST be implemented using the standard macros and structure detailed later in this document.

7. **Named Parameter Range Constants**: All UI parameter min/max/default values MUST use named constants instead of magic numbers. These should be defined at the top of the file in the constants section using the naming format PARAMETER_MIN, PARAMETER_MAX, PARAMETER_DEFAULT.
   ```hlsl
   // CORRECT ✓
   static const float RADIUS_MIN = 0.1;
   static const float RADIUS_MAX = 1.0;
   static const float RADIUS_DEFAULT = 0.5;
   
   uniform float Radius < ui_min = RADIUS_MIN; ui_max = RADIUS_MAX; /* other UI parameters */ > = RADIUS_DEFAULT;
   
   // INCORRECT ✗
   uniform float Radius < ui_min = 0.1; ui_max = 1.0; /* other UI parameters */ > = 0.5;
   ```

8. **Standardized UI Section Organization**: Each shader MUST organize UI controls into standardized sections following the exact ordering specified in the Standard Code Structure section of this document. The Animation Controls, Stage Controls, and Final Mix sections MUST be implemented using the standard macros and structure detailed later in this document.

## Common Constants Reference

The `AS_Utils.1.fxh` file provides standardized constants for various purposes:

### Mathematical Constants
- `AS_PI`, `AS_TWO_PI`, `AS_HALF_PI` - Mathematical constants
- `AS_EPSILON`, `AS_EPSILON_SAFE` - Small numbers to prevent division by zero
- `AS_HALF`, `AS_QUARTER`, `AS_THIRD`, `AS_TWO_THIRDS` - Common fractions
- `AS_DEPTH_EPSILON` - Value for z-fighting prevention (0.0005)
- `AS_EDGE_AA` - Edge anti-aliasing size (0.05)

### Display Constants
- `AS_RESOLUTION_BASE_HEIGHT`, `AS_RESOLUTION_BASE_WIDTH` - Reference resolution (1080p)
- `AS_UI_POSITION_RANGE` - Standard range for position UI (-1.5 to 1.5)
- `AS_UI_POSITION_SCALE` - Position scaling factor (0.5)
- `AS_SCREEN_CENTER_X`, `AS_SCREEN_CENTER_Y` - Screen center coordinates (0.5)

### Animation Constants
- `AS_ANIMATION_SPEED_SLOW/NORMAL/FAST` - Animation speed multipliers
- `AS_TIME_1_SECOND`, `AS_TIME_HALF_SECOND`, etc. - Timing constants
- `AS_PATTERN_FREQ_LOW/MED/HIGH` - Standard pattern frequencies

### UI Value Ranges
- `AS_RANGE_ZERO_ONE_MIN/MAX` - Standard 0-1 range
- `AS_RANGE_OPACITY_MIN/MAX/DEFAULT` - Opacity parameter range
- `AS_RANGE_AUDIO_MULT_MIN/MAX/DEFAULT` - Audio multiplier range
- `AS_RANGE_SCALE_MIN/MAX/DEFAULT` - Scale parameter range

### Debug Constants
- `AS_DEBUG_OFF`, `AS_DEBUG_MASK`, `AS_DEBUG_DEPTH`, etc. - Debug mode constants

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

## Comment Header Standards

All shader files in the AS StageFX collection must follow this standardized comment header format:

```hlsl
/**
 * Filename.fx - Brief Description
 * Author: Author Name
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * 2-3 sentence overview of what the shader does and its primary purpose.
 * This should clearly explain the visual effect and when it would be used.
 *
 * FEATURES:
 * - Bullet point list of key capabilities
 * - Each point should highlight a distinct feature
 * - Include audio reactivity, customization options, etc.
 * - Focus on user-facing features
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Numbered steps explaining how the effect works technically
 * 2. Brief explanation of the algorithm or approach
 * 3. Mention key techniques or optimizations
 * 4. Keep technical but understandable
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __SHADER_IDENTIFIER_fx
#define __SHADER_IDENTIFIER_fx

// Rest of shader code...

#endif // __SHADER_IDENTIFIER_fx
```

### Required Sections

1. **File and Author Information**
   - Filename with brief description
   - Author name
   - License with full rights statement

2. **Description Section**
   - 2-3 sentence overview of the shader's purpose
   - Should explain what the effect looks like and when it would be used

3. **Features Section**
   - Bullet point list of key capabilities
   - Should focus on user-facing features
   - Include audio reactivity if present

4. **Implementation Overview**
   - Numbered steps explaining the technical approach
   - Brief but informative explanation of how the shader works

5. **Separator Lines**
   - Use `===================================================================================` for major sections
   - Place before and after the main description block

6. **Technique Guard**
   - Must include the standardized comment block:
   ```hlsl
   // ============================================================================
   // TECHNIQUE GUARD - Prevents duplicate loading of the same shader
   // ============================================================================
   ```
   - Guard macro name must match filename: `__AS_TypeCode_ShaderName_Version_fx`
   - Close with matching comment: `#endif // __SHADER_IDENTIFIER_fx`

7. **Section Headers**
   - Use consistent formatting for all section headers:
   ```hlsl
   // ============================================================================
   // SECTION NAME
   // ============================================================================
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
6. **Stage** - Depth, rotation, and global positioning parameters
7. **Final Mix** - Blend mode and strength settings
8. **Debug** - Debug visualization options

**UI Grouping:**
- Use `ui_category = "Category Name";` consistently to group related parameters.
- Follow the standard category order listed above.
- For multi-instance effects (e.g., using `EFFECT_UI` macro), each instance should have its own category (e.g., `ui_category = "Effect " #index;`).
- Use `ui_category_closed = true;` for categories that are less frequently accessed or for instances beyond the first one (e.g., `ui_category_closed = index > 1;`) to keep the UI cleaner by default.

### Tunable Constants
```hlsl
// --- Tunable Constants ---
static const float PARAM_MIN = 0.1;
static const float PARAM_MAX = 1.0;
static const float PARAM_DEFAULT = 0.5; // Short explanation if needed
```

### Animation Controls Section
This section must contain controls for both animation speed and keyframe position to allow users to either animate the effect or select a specific static frame. 

Standard Animation Controls Section Format:
```hlsl
// ============================================================================
// ANIMATION CONTROLS
// ============================================================================

// --- Animation Constants ---
static const float ANIMATION_SPEED_MIN = 0.0;
static const float ANIMATION_SPEED_MAX = 5.0;
static const float ANIMATION_SPEED_DEFAULT = 1.0;

static const float ANIMATION_KEYFRAME_MIN = 0.0;
static const float ANIMATION_KEYFRAME_MAX = 100.0;
static const float ANIMATION_KEYFRAME_DEFAULT = 0.0;

// --- Using Standard Animation UI Macros ---
// Option 1: Combined animation controls (both speed and keyframe)
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation") 

// Option 2: Separate animation controls
// AS_ANIMATION_KEYFRAME_UI(AnimationKeyframe, "Animation")
// AS_ANIMATION_SPEED_UI(AnimationSpeed, "Animation")
```

Standard Time Value Calculation:
```hlsl
// In the pixel shader:
float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);

// Optional audio reactivity for animation speed
float animSpeed = AnimationSpeed;
if (AudioTarget == TARGET_ANIMATION_SPEED) {
    float audioValue = AS_applyAudioReactivity(1.0, AudioSource, AudioMult, true) - 1.0;
    animSpeed = AnimationSpeed * (1.0 + audioValue);
}
time = AS_getAnimationTime(animSpeed, AnimationKeyframe);
```

### Stage Controls Section
This section must include depth masking and other stage-related parameters in a standard format. All shaders should use the standardized stage control macros.

Standard Stage Controls Section Format:
```hlsl
// ============================================================================
// STAGE/POSITION CONTROLS
// ============================================================================
AS_POSITION_UI(EffectCenter) // Defines float2 EffectCenter; category "Position", default (0,0)
AS_ROTATION_UI(SnapRotation, FineRotation) // Defines snap and fine rotation controls
AS_STAGEDEPTH_UI(EffectDepth) // ui_category "Stage", creates float EffectDepth

// Optional: If your effect needs perspective controls
// AS_PERSPECTIVE_UI(PerspectiveAngles, PerspectiveZOffset, PerspectiveFocalLength, "Perspective")
```

Standard Stage Depth Implementation:
```hlsl
// In the pixel shader:
float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
if (sceneDepth < EffectDepth - AS_DEPTH_EPSILON) {
    return original; // Skip effect for pixels in front of the effect plane
}
```

### Final Mix Section
This section must include standardized blend mode and blend amount controls, allowing users to adjust how the effect is blended with the scene.

Standard Final Mix Section Format:
```hlsl
// ============================================================================
// FINAL MIX
// ============================================================================
AS_BLENDMODE_UI(BlendMode) // Default is Normal (0)
AS_BLENDAMOUNT_UI(BlendAmount)

// For effects that need a specific default blend mode:
// AS_BLENDMODE_UI_DEFAULT(BlendMode, 3) // 3 = Additive
```

Standard Blend Implementation:
```hlsl
// In the pixel shader's return statement:
return AS_applyBlendMode(BlendMode, original, effectColor, BlendAmount);
```

### Tunable Constants
```hlsl
// --- Tunable Constants ---
static const float PARAM_MIN = 0.1;
static const float PARAM_MAX = 1.0;
static const float PARAM_DEFAULT = 0.5; // Short explanation if needed
```

### Animation Controls Section
This section must contain controls for both animation speed and keyframe position to allow users to either animate the effect or select a specific static frame. 

Standard Animation Controls Section Format:
```hlsl
// ============================================================================
// ANIMATION CONTROLS
// ============================================================================

// --- Animation Constants ---
static const float ANIMATION_SPEED_MIN = 0.0;
static const float ANIMATION_SPEED_MAX = 5.0;
static const float ANIMATION_SPEED_DEFAULT = 1.0;

static const float ANIMATION_KEYFRAME_MIN = 0.0;
static const float ANIMATION_KEYFRAME_MAX = 100.0;
static const float ANIMATION_KEYFRAME_DEFAULT = 0.0;

// --- Using Standard Animation UI Macros ---
// Option 1: Combined animation controls (both speed and keyframe)
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation") 

// Option 2: Separate animation controls
// AS_ANIMATION_KEYFRAME_UI(AnimationKeyframe, "Animation")
// AS_ANIMATION_SPEED_UI(AnimationSpeed, "Animation")
```

Standard Time Value Calculation:
```hlsl
// In the pixel shader:
float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);

// Optional audio reactivity for animation speed
float animSpeed = AnimationSpeed;
if (AudioTarget == TARGET_ANIMATION_SPEED) {
    animSpeed = AS_applyAudioReactivityEx(AnimationSpeed, AudioSource, AudioMultiplier, true, 1); // Mode 1 = additive
}
float time = AS_getAnimationTime(animSpeed, AnimationKeyframe);
```

### Stage Controls Section
This section must contain controls for positioning the effect in 3D space including position coordinates, rotation (if applicable), and depth control.

Standard Stage Controls Section Format:
```hlsl
// ============================================================================
// STAGE CONTROLS
// ============================================================================

// Position controls (required)
AS_POSITION_UI(EffectPosition) // ui_category "Position", creates float2 EffectPosition

// Rotation controls (optional, omit if the effect doesn't support rotation)
AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation) // ui_category "Stage"

// Depth control (required)
AS_STAGEDEPTH_UI(EffectDepth) // ui_category "Stage", creates float EffectDepth
```

### Final Mix Section
This section must contain controls for blending the effect with the original scene, including blend mode selection and strength/opacity control.

Standard Final Mix Section Format:
```hlsl
// ============================================================================
// FINAL MIX
// ============================================================================

// Blend mode selection - use one of these options:
AS_BLENDMODE_UI(BlendMode) // Default is Normal (0)
// Or with specific default:
// AS_BLENDMODE_UI_DEFAULT(BlendMode, 3) // 3 = Additive

// Blend strength/opacity control (required)
AS_BLENDAMOUNT_UI(BlendAmount) // ui_category "Final Mix", creates float BlendAmount
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

### Naming Requirements
All texture and sampler declarations MUST be prefixed with the shader name to prevent naming conflicts when multiple shaders are loaded simultaneously.

```hlsl
// CORRECT ✓
texture ShaderName_EffectBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler ShaderName_EffectSampler { 
    Texture = ShaderName_EffectBuffer; 
    AddressU = CLAMP; 
    AddressV = CLAMP; 
    MinFilter = LINEAR; 
    MagFilter = LINEAR; 
};

// INCORRECT ✗
texture EffectBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler EffectSampler { 
    Texture = EffectBuffer; 
    AddressU = CLAMP; 
    AddressV = CLAMP; 
    MinFilter = LINEAR; 
    MagFilter = LINEAR; 
};
```

The prefixing pattern should be `ShaderName_TextureName`, where `ShaderName` is the main part of the shader file name (e.g., for `AS_VFX_RainyWindow.1.fx`, use `RainyWindow_` as the prefix).

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

## Full-Screen Rotation and Coordinate System

When implementing effects that support full-screen rotation (controlled via standard rotation UI like `AS_ROTATION_UI`), use the following coordinate system and transformation logic to ensure correct placement and aspect ratio handling:

1. **UI Coordinate System**:
   - Position controls (e.g., `float2 EffectPosition`) should use a centered coordinate system.
   - `(0,0)` represents the exact center of the screen.
   - The range `[-1, 1]` in both X and Y maps to the largest square that fits within the screen boundaries (the "central square").
   - UI sliders should typically range beyond `[-1, 1]` (e.g., `[-1.5, 1.5]`) to allow placement in areas outside the central square on non-square aspect ratios.

2. **Shader Coordinate Transformation**:
   - **Step 1: Center Screen Coordinates:** Transform screen UVs (`uv`) into a centered coordinate system (`screen_coords`) where the *shortest* screen dimension spans `[-0.5, 0.5]`. The longer dimension scales proportionally with the aspect ratio.
     ```hlsl
     float aspectRatio = ReShade::AspectRatio; // BUFFER_WIDTH / BUFFER_HEIGHT
     float2 screen_coords;
     if (aspectRatio >= 1.0) { // Wider or square
         screen_coords.x = (uv.x - 0.5) * aspectRatio;
         screen_coords.y = uv.y - 0.5;
     } else { // Taller
         screen_coords.x = uv.x - 0.5;
         screen_coords.y = (uv.y - 0.5) / aspectRatio;
     }
     // Note: screen_coords.y typically increases downwards at this stage.
     ```
   - **Step 2: Apply Inverse Rotation:** Apply the inverse of the global rotation to `screen_coords` to get `rotated_screen_coords`.
     ```hlsl
     float globalRotation = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
     float sinRot = sin(-globalRotation);
     float cosRot = cos(-globalRotation);
     float2 rotated_screen_coords;
     rotated_screen_coords.x = screen_coords.x * cosRot - screen_coords.y * sinRot;
     rotated_screen_coords.y = screen_coords.x * sinRot + screen_coords.y * cosRot;
     ```
   - **Step 3: Map UI Position:** Convert the UI position parameter (`EffectPosition`, which is in the `[-1.5, 1.5]` range) into the same `screen_coords` system. The `[-1, 1]` range maps to `[-0.5, 0.5]`.
     ```hlsl
     float2 effect_screen_coords = EffectPosition * 0.5;
     ```
   - **Step 4: Calculate Relative Difference:** Find the difference between the pixel's rotated coordinate and the effect's base coordinate.
     ```hlsl
     float2 diff = rotated_screen_coords - effect_screen_coords;
     ```
   - **Step 5: Normalize:** Normalize `diff` using the effect's dimensions (width, height, zoom), ensuring these dimensions are correctly scaled to match the `screen_coords` system.
     ```hlsl
     // Example for flame-like effect where dimensions are relative to screen height
     float normWidth = EffectWidth * EffectZoom;
     float normHeight = EffectHeight * EffectZoom;
     float2 effectDimInScreenCoords;
     if (aspectRatio >= 1.0) { // Wide
         effectDimInScreenCoords.x = normWidth * aspectRatio;
         effectDimInScreenCoords.y = normHeight;
     } else { // Tall
         effectDimInScreenCoords.x = normWidth;
         effectDimInScreenCoords.y = normHeight / aspectRatio;
     }
     float2 rel_uv;
     rel_uv.x = (effectDimInScreenCoords.x > 1e-5) ? diff.x / effectDimInScreenCoords.x : 0.0;
     // Adjust Y direction if needed by the effect's internal logic (e.g., negate if Y should increase upwards)
     rel_uv.y = (effectDimInScreenCoords.y > 1e-5) ? -diff.y / effectDimInScreenCoords.y : 0.0;
     ```

This approach ensures effects are placed correctly and maintain their aspect ratio regardless of screen dimensions or global rotation.

## Lessons Learned from Implementation

### Resolution-Independent Effect Rendering
1. **Coordinate Space Transformations**: Always transform coordinates to a uniform space before effect calculations - use the central square (-1,-1) to (1,1) as a reference for all placement and calculations.

2. **Normalize Before Rotating**: For rotation operations, always convert coordinates to normalized space first, then apply rotation. This prevents distortion in non-square resolutions.

3. **Two-Phase Coordinate Handling**: 
   - Use normalized coordinates for positional calculations (like relative positioning and angle calculations)
   - Use screen-space coordinates for resolution-dependent calculations (like size relative to display dimensions)

4. **Avoid Aspect Ratio Distortion**: When checking angles/directions, counteract aspect ratio distortion by applying the inverse of aspect ratio scaling to direction calculations:
   ```hlsl
   // Correct for aspect ratio distortion when checking angles
   if (aspectRatio >= 1.0) { // Wide screen
       dirVec.x /= aspectRatio; // Undo horizontal stretching
   } else { // Tall screen
       dirVec.y *= aspectRatio; // Undo vertical stretching
   }
   ```

### Light Beam Rendering Guidelines
1. **Multi-Component Falloff**: When rendering light beams or similar gradient effects, use multiple falloff components:
   ```hlsl
   // Central axis falloff
   float radialFalloff = 1.0 - smoothstep(0.0, 0.9, normalizedPerpDist);
   
   // Length-based falloff
   float distanceFalloff = 1.0 - smoothstep(0.0, radius, distance);
   
   // Combine falloffs with proper weighting
   float finalIntensity = radialFalloff * distanceFalloff * baseIntensity;
   ```

2. **Avoid Hotspots & Artifacts**: For natural-looking light:
   - Use non-linear falloff (pow, exp) with gentle exponents (0.5-1.5) for soft gradients
   - Apply special case treatment for endpoints (source and termination points)
   - Combine multiple falloff curves with different characteristics
   - Avoid sharp transitions by using smoothstep with appropriate range values

3. **Physically-Based Beam Shapes**: Use trigonometry to model light behavior:
   ```hlsl
   // Calculate cone width at different distances from source
   float halfAngleRad = angleInDegrees * 0.5 * (AS_PI / 180.0);
   float beamWidthAtDist = projectedDist * tan(halfAngleRad);
   
   // Calculate perpendicular distance from beam center axis
   float perpDist = sqrt(1.0 - pow(dot(normalize(dirVec), spotDir), 2)) * dist;
   
   // Calculate normalized position within cone
   float normalizedPerpDist = perpDist / beamWidthAtDist;
   ```

### Noise Function Usage
When generating procedural effects, use the appropriate noise functions based on need:

### Texture-Based Effects
1. **Preprocessor-Based Texture UI**: For texture resources that need to appear in the UI, use preprocessor definitions:
   ```hlsl
   #ifndef TEXTURE_PATH
   #define TEXTURE_PATH "default.png" // Default texture path
   #endif

   texture EffectTexture < source = TEXTURE_PATH; ui_label = "Effect Texture"; > 
   { Width = 256; Height = 256; Format = RGBA8; };
   ```

2. **Texture UI Visibility Helpers**: Add UI elements to ensure texture selection is visible:
   ```hlsl
   uniform bool RefreshUI < source = "key"; keycode = 13; mode = "toggle"; 
      ui_label = " "; ui_text = "Press Enter to refresh UI"; 
      ui_category = "Texture Settings"; > = false;
   ```

3. **Multiple Resolution Handling**: For repeated texture patterns, scale sampling based on resolution:
   ```hlsl
   float resolutionScale = (float)BUFFER_HEIGHT / 1080.0;
   float2 scaledUV = uv * resolutionScale; // Larger screens = denser patterns
   float noiseValue = tex2D(NoiseSampler, scaledUV).r;
   ```

### Rotated Distortion Effects
1. **Separation of Rotation and Sampling**: When implementing rotated distortion effects:
   - Calculate the distortion vectors using the rotated coordinates
   - Apply the resulting distortion to the original (non-rotated) texture coordinates
   ```hlsl
   // Calculate distortion in rotated space
   float2 rotatedUV = ApplyRotationTransform(texcoord, rotation);
   float2 distortionVector = CalculateDistortion(rotatedUV);
   
   // Apply distortion to original texcoord (not rotated texcoord)
   float2 distortedUV = texcoord + distortionVector;
   float4 result = tex2D(ReShade::BackBuffer, distortedUV);
   ```

2. **Aspect Ratio Correction for Distortion Vectors**: When applying distortion calculated in a rotated/normalized space:
   ```hlsl
   // Calculate distortion in normalized/rotated space
   float2 distortion = CalculateDistortion(normalizedUV);
   
   // Correct the distortion vector for aspect ratio before applying
   distortion.x /= ReShade::AspectRatio;
   
   // Apply the corrected distortion to the original coordinates
   float2 finalUV = texcoord + distortion * intensity;
   ```

3. **Safe Texture Sampling**: Always clamp distorted texture coordinates to prevent sampling outside valid range:
   ```hlsl
   distortedUV = clamp(distortedUV, 0.0, 1.0);
   float4 result = tex2D(ReShade::BackBuffer, distortedUV);
   ```

### Audio Reactivity for Visual Parameters
1. **Parameter-Specific Audio Targeting**: Instead of applying audio to all parameters, let users select which parameter to affect:
   ```hlsl
   uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter";
      ui_items = "None\0Parameter A\0Parameter B\0"; > = 0;
      
   // In pixel shader
   if (AudioTarget == 1) { // Parameter A
       paramA = baseParamA + (baseParamA * audioValue * scaleFactor);
   } else if (AudioTarget == 2) { // Parameter B
       paramB = saturate(baseParamB + (baseParamB * audioValue * scaleFactor));
   }
   ```

2. **Multiple Parameter Types**: Include parameters that affect different aspects of the visual effect:
   - Size/scale parameters (droplet size, pattern density)
   - Intensity/strength parameters (distortion amount, effect opacity)
   - Texture/roughness parameters (surface details, noise intensity)
   - Speed/animation parameters (movement rate, oscillation frequency)

## Animation Control Standards

### Animation Speed and Keyframe Pattern

For shaders that include time-based animation, use the following pattern to allow users to either enjoy animated results or select specific static frames:

1. **Standard Animation Controls**:
   ```hlsl
   // Animation constants
   static const float ANIMATION_SPEED_MIN = 0.0;
   static const float ANIMATION_SPEED_MAX = 5.0;
   static const float ANIMATION_SPEED_STEP = 0.01;
   static const float ANIMATION_SPEED_DEFAULT = 1.0;
   
   static const float ANIMATION_KEYFRAME_MIN = 0.0;
   static const float ANIMATION_KEYFRAME_MAX = 100.0;
   static const float ANIMATION_KEYFRAME_STEP = 0.1;
   static const float ANIMATION_KEYFRAME_DEFAULT = 0.0;
   
   // Animation UI controls
   uniform float AnimationKeyframe < ui_type = "slider"; ui_label = "Animation Keyframe"; ui_tooltip = "Sets a specific point in time for the animation. Useful for finding and saving specific patterns."; ui_min = ANIMATION_KEYFRAME_MIN; ui_max = ANIMATION_KEYFRAME_MAX; ui_step = ANIMATION_KEYFRAME_STEP; ui_category = "Animation"; > = ANIMATION_KEYFRAME_DEFAULT;
   uniform float AnimationSpeed < ui_type = "slider"; ui_label = "Animation Speed"; ui_tooltip = "Controls the overall animation speed of the effect. Set to 0 to pause animation and use keyframe only."; ui_min = ANIMATION_SPEED_MIN; ui_max = ANIMATION_SPEED_MAX; ui_step = ANIMATION_SPEED_STEP; ui_category = "Animation"; > = ANIMATION_SPEED_DEFAULT;
   ```

2. **Time Calculation in Pixel Shader**:
   ```hlsl
   // Get time and calculate animation
   float time;
   if (AnimationSpeed <= 0.0001) {
       // When animation speed is effectively zero, use keyframe directly
       time = AnimationKeyframe;
   } else {
       // Otherwise use animated time plus keyframe offset
       time = (AS_getTime() * AnimationSpeed) + AnimationKeyframe;
   }
   ```

3. **Audio-Reactive Animation**:
   If implementing audio reactivity for animation speed, include the audio application before the time calculation:
   ```hlsl
   float animSpeed = AnimationSpeed;
   
   // Apply audio reactivity if animation speed is the target
   if (AudioTarget == 1) {
       animSpeed *= AS_applyAudioReactivity(1.0, AudioSource, AudioMultiplier, true);
   }
   
   // Time calculation
   float time;
   if (animSpeed <= 0.0001) {
       time = AnimationKeyframe;
   } else {
       time = (AS_getTime() * animSpeed) + AnimationKeyframe;
   }
   ```

4. **Important Implementation Notes**:
   - Always check for effectively zero speed (`<= 0.0001`) rather than exact zero to account for floating-point imprecision
   - When animation is paused (speed = 0), the keyframe value should be used directly
   - When animation is running, the keyframe value should still be applied as an offset
   - This approach simplifies the UI by avoiding redundant "Enable Animation" checkboxes
   - Place the Keyframe control before the Speed control in the UI for logical user flow
