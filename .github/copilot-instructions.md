# AS StageFX Copilot Instructions

## Context
I'm developing HLSL shader effects for the AS StageFX collection, which are used in ReShade for real-time post-processing in games. These shaders focus on high-quality, procedural visual effects with standardized interfaces.

## Rules and Standards

### Critical Rules
1. **Uniform declarations must always be single-line** to maintain compatibility with shader parsing tools.
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

2. **Always use technique guards** to prevent duplicate loading:
   ```hlsl
   #ifndef __AS_LFX_ShaderName_1_fx
   #define __AS_LFX_ShaderName_1_fx
   
   // ...shader code...
   
   #endif // __AS_LFX_ShaderName_1_fx
   ```

3. **Use named constants from AS_Utils** instead of magic numbers (AS_PI, AS_TWO_PI, etc.).

4. **Always include resolution independence** - effects must render consistently across different resolutions and aspect ratios.

5. **Use standard shader organization**:
   ```
   // TECHNIQUE GUARD
   // INCLUDES
   // TUNABLE CONSTANTS
   // UNIFORM UI DECLARATIONS (in specific order)
   // NAMESPACE & HELPER FUNCTIONS
   // MAIN PIXEL SHADER
   // TECHNIQUE
   ```

6. **Always use centralized utility functions** - Use functions from AS_Utils.1.fxh whenever possible instead of reimplementing common functionality. If you identify a potentially reusable function across multiple shaders, suggest its addition to AS_Utils or a specialized utility library (like AS_Palettes for color management).
   ```hlsl
   // CORRECT ✓
   float hash = AS_hash21(position); // Using utility function
   float angle = AS_PI * 2.0 * rotation; // Using named constant
   float3 colorValue = AS_getInterpolatedColor(paletteID, t); // Using palette system
   
   // INCORRECT ✗
   float hash = frac(sin(dot(position, float2(12.9898, 78.233))) * 43758.5453); // Reimplementing hash
   float angle = 3.14159 * 2.0 * rotation; // Using magic number
   // Reimplementing color interpolation instead of using the palette system
   ```

### Noise Function Usage
When generating procedural effects, use the appropriate noise functions based on need:

- For simple random values: `AS_hash11/12/21`
- For organic patterns: `AS_PerlinNoise2D`
- For natural textures: `AS_Fbm2D` (specify octaves, lacunarity, persistence)
- For flowing effects: `AS_Fbm2D_Animated`
- For cell patterns: `AS_VoronoiNoise2D`
- For ridges/boundaries: `AS_CellularNoise2D`
- For complex fluid effects: `AS_DomainWarp2D`

Scale noise parameters by resolution to maintain consistent appearance across different displays.

### Audio Reactivity
Include standard audio reactivity using macros:
```hlsl
// Define audio controls
AS_AUDIO_SOURCE_UI(Effect_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULTIPLIER_UI(Effect_AudioMultiplier, "Intensity", 1.0, 2.0, "Audio Reactivity")

// In pixel shader
float effectStrength = AS_applyAudioReactivity(BaseStrength, Effect_AudioSource, 
                                             Effect_AudioMultiplier, true);
```

### Uniform Organization
Always arrange uniforms in this order:
1. Tunable Constants
2. Palette & Style
3. Effect-Specific Appearance
4. Animation
5. Audio Reactivity
6. Stage Distance
7. Final Mix
8. Debug

### Optimization
1. Use DRY principles - extract repeated logic into functions
2. For multi-instance effects (lights, particles), use parameter structures and loop-based processing
3. Implement proper resolution scaling
4. Document performance costs in comments

### Full-Screen Rotation and Coordinate System

When implementing effects that support full-screen rotation (controlled via standard rotation UI like `AS_ROTATION_UI`), use the following coordinate system and transformation logic to ensure correct placement and aspect ratio handling:

1.  **UI Coordinate System**:
    *   Position controls (e.g., `float2 EffectPosition`) should use a centered coordinate system.
    *   `(0,0)` represents the exact center of the screen.
    *   The range `[-1, 1]` in both X and Y maps to the largest square that fits within the screen boundaries (the "central square").
    *   UI sliders should typically range beyond `[-1, 1]` (e.g., `[-1.5, 1.5]`) to allow placement in areas outside the central square on non-square aspect ratios.

2.  **Shader Coordinate Transformation**:
    *   **Step 1: Center Screen Coordinates:** Transform screen UVs (`uv`) into a centered coordinate system (`screen_coords`) where the *shortest* screen dimension spans `[-0.5, 0.5]`. The longer dimension scales proportionally with the aspect ratio.
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
    *   **Step 2: Apply Inverse Rotation:** Apply the inverse of the global rotation to `screen_coords` to get `rotated_screen_coords`.
      ```hlsl
      float globalRotation = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
      float sinRot = sin(-globalRotation);
      float cosRot = cos(-globalRotation);
      float2 rotated_screen_coords;
      rotated_screen_coords.x = screen_coords.x * cosRot - screen_coords.y * sinRot;
      rotated_screen_coords.y = screen_coords.x * sinRot + screen_coords.y * cosRot;
      ```
    *   **Step 3: Map UI Position:** Convert the UI position parameter (`EffectPosition`, which is in the `[-1.5, 1.5]` range) into the same `screen_coords` system. The `[-1, 1]` range maps to `[-0.5, 0.5]`.
      ```hlsl
      float2 effect_screen_coords = EffectPosition * 0.5;
      ```
    *   **Step 4: Calculate Relative Difference:** Find the difference between the pixel's rotated coordinate and the effect's base coordinate.
      ```hlsl
      float2 diff = rotated_screen_coords - effect_screen_coords;
      ```
    *   **Step 5: Normalize:** Normalize `diff` using the effect's dimensions (width, height, zoom), ensuring these dimensions are correctly scaled to match the `screen_coords` system.
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

## Example Patterns and Best Practices

### Resolution Independence
```hlsl
// Standard resolution scaling calculation
float resolutionScale = (float)BUFFER_HEIGHT / 1080.0;

// Scale pattern density by resolution
float2 patternScale = basePatternScale / resolutionScale;

// Correct for aspect ratio
float2 aspect_corrected_size = float2(EffectWidth / ReShade::AspectRatio, EffectHeight);
```

### Documentation Header
```hlsl
/**
 * AS_TP_ShaderName.Version.fx - Brief description
 * Author: Your Name
 * License: Creative Commons Attribution 4.0 International
 * 
 * DESCRIPTION: 2-4 sentence overview
 * FEATURES: Bullet points of key features
 * IMPLEMENTATION: Brief numbered steps of the effect's approach
 */
```

### Multi-Layer Effects
For complex effects, use multi-scale approach:
```hlsl
// Large-scale pattern for overall shape
float basePattern = AS_PerlinNoise2D(texcoord * 2.0);

// Medium-scale detail
float detail = AS_PerlinNoise2D(texcoord * 8.0) * 0.5;

// Fine-scale detail for texture
float texture = AS_ValueNoise2D(texcoord * 32.0) * 0.25;

// Combine the scales
float finalNoise = basePattern + detail + texture;
```

## Additional Notes
1. Follow the naming convention: `AS_TypeCode_EffectName.Version.fx`
2. Use major version numbers (`.1.fx`, `.2.fx`) when breaking compatibility with presets
3. Implement graceful fallbacks for features like audio reactivity
4. Test shaders at multiple resolutions and aspect ratios