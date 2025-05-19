# AS StageFX Standards Compliance Checklist

## Checklist for Updating Existing Shaders

This document provides a systematic approach to update shaders for compliance with the updated AS StageFX coding standards.

### 1. Initial File Assessment

- [ ] Check if the shader already has a TUNABLE CONSTANTS section
- [ ] Verify if named parameter constants follow the PARAM_MIN/MAX/DEFAULT format
- [ ] Check if animation parameters use the AS_ANIMATION_UI macro
- [ ] Check if stage controls use the standardized macros
- [ ] Check if the final mix section uses the standardized macros
- [ ] Verify UI section organization matches the standard order

### 2. Parameter Range Constants

Convert magic number values to named constants. For each parameter:

- [ ] Create constants in the TUNABLE CONSTANTS section using the pattern:
  ```hlsl
  static const float PARAM_MIN = 0.1;
  static const float PARAM_MAX = 1.0;
  static const float PARAM_DEFAULT = 0.5; // Short explanation if needed
  ```
  
- [ ] Update uniform declarations to reference these constants:
  ```hlsl
  uniform float Param < ui_min = PARAM_MIN; ui_max = PARAM_MAX; /* other params */ > = PARAM_DEFAULT;
  ```

### 3. Animation Controls

If the shader uses animation:

- [ ] Add standard animation constants if they don't exist:
  ```hlsl
  static const float ANIMATION_SPEED_MIN = 0.0;
  static const float ANIMATION_SPEED_MAX = 5.0;
  static const float ANIMATION_SPEED_DEFAULT = 1.0;
  
  static const float ANIMATION_KEYFRAME_MIN = 0.0;
  static const float ANIMATION_KEYFRAME_MAX = 100.0;
  static const float ANIMATION_KEYFRAME_DEFAULT = 0.0;
  ```
  
- [ ] Use the standardized animation UI macro:
  ```hlsl
  AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")
  ```

- [ ] Verify time value calculation uses the standard helper:
  ```hlsl
  float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);
  ```

### 4. Stage Controls

- [ ] Implement standard stage controls using macros:
  ```hlsl
  // ============================================================================
  // STAGE/POSITION CONTROLS
  // ============================================================================
  AS_POSITION_UI(EffectCenter) 
  AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation) // If rotation is supported
  AS_STAGEDEPTH_UI(EffectDepth) 
  ```
  
- [ ] Verify depth-testing implementation:
  ```hlsl
  float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
  if (sceneDepth < EffectDepth - AS_DEPTH_EPSILON) {
      return original;
  }
  ```

### 5. Final Mix Section

- [ ] Implement standard Final Mix section:
  ```hlsl
  // ============================================================================
  // FINAL MIX
  // ============================================================================
  AS_BLENDMODE_UI(BlendMode) // Default is Normal (0)
  AS_BLENDAMOUNT_UI(BlendAmount)
  ```

- [ ] If a specific default blend mode is needed:
  ```hlsl
  AS_BLENDMODE_UI_DEFAULT(BlendMode, 3) // For specific default, e.g., 3 = Additive
  ```

### 6. Section Organization

Verify sections appear in this exact order:

1. Technique Guard
2. Includes
3. Tunable Constants
4. Palette & Style (if any)
5. Effect-Specific Parameters
6. Animation Controls
7. Audio Reactivity (if any)
8. Stage/Position Controls
9. Final Mix
10. Debug Controls (if any)
11. Helper Functions
12. Main Pixel Shader
13. Technique

## Template for Standard Section Headers

```hlsl
// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================

// ============================================================================
// INCLUDES
// ============================================================================

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================

// ============================================================================
// PALETTE & STYLE
// ============================================================================

// ============================================================================
// EFFECT-SPECIFIC PARAMETERS
// ============================================================================

// ============================================================================
// ANIMATION CONTROLS
// ============================================================================

// ============================================================================
// AUDIO REACTIVITY
// ============================================================================

// ============================================================================
// STAGE/POSITION CONTROLS
// ============================================================================

// ============================================================================
// FINAL MIX
// ============================================================================

// ============================================================================
// DEBUG
// ============================================================================

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// ============================================================================
// MAIN PIXEL SHADER
// ============================================================================

// ============================================================================
// TECHNIQUE
// ============================================================================
```

## Update Process

1. Start with basic shaders that need minimal changes (like adding named constants)
2. Progress to more complex shaders that need UI section reorganization
3. Update animation implementation in shaders that use custom animation logic
4. Validate each updated shader by loading it in ReShade and testing with different parameter values
