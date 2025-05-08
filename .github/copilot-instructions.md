# AS StageFX Shader Development Guide

## Critical Guidelines

1. **Single-line uniform declarations** (required for parsing tools)
   ```hlsl
   uniform float Param < ui_type = "slider"; ui_label = "Label"; ui_min = MIN; ui_max = MAX; ui_category = "Category"; > = DEFAULT;
   ```

2. **Technique guards** to prevent duplicate loading
   ```hlsl
   #ifndef __AS_LFX_ShaderName_1_fx
   #define __AS_LFX_ShaderName_1_fx
   // ...
   #endif // __AS_LFX_ShaderName_1_fx
   ```

3. **Consistent code organization**
   ```
   TECHNIQUE GUARD → INCLUDES → CONSTANTS → UI DECLARATIONS → 
   HELPER FUNCTIONS → PIXEL SHADER → TECHNIQUE
   ```

4. **Use AS_Utils functions** instead of reimplementing common operations
   - Math constants: `AS_PI`, `AS_TWO_PI` (never use magic numbers)
   - Hash functions: `AS_hash11/21/12`
   - Noise functions: `AS_PerlinNoise2D`, `AS_Fbm2D`, etc.
   - Audio: `AS_applyAudioReactivity()`, `AS_getAudioSource()`
   - UI macros: `AS_AUDIO_SOURCE_UI()`, `AS_BLENDMODE_UI()`, etc.

5. **Resolution independence** - All effects must render consistently regardless of screen size/ratio

## UI Standards

### Uniform Organization (in order)
1. Tunable Constants
2. Palette & Style
3. Effect-Specific Parameters
4. Animation Controls
5. Audio Reactivity
6. Stage/Position Controls
7. Final Mix (Blend)
8. Debug Controls

### Category Organization
- Group related parameters with consistent `ui_category` names
- Use `ui_category_closed = true` for secondary categories
- For multi-instance effects, use `ui_category = "Effect " #index`

## Pattern Implementation Guide

### Texture-Based Effects
```hlsl
// Preprocessor-based texture UI
#ifndef TEXTURE_PATH
#define TEXTURE_PATH "default.png"
#endif

texture EffectTexture < source = TEXTURE_PATH; ui_label = "Texture"; > 
{ Width = 256; Height = 256; Format = RGBA8; };
sampler TextureSampler { Texture = EffectTexture; AddressU = REPEAT; AddressV = REPEAT; /* etc */ };
```

### Audio Reactivity - Parameter-Specific
```hlsl
// UI element for selecting which parameter reacts to audio
uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target";
   ui_items = "None\0Parameter A\0Parameter B\0"; > = 0;

// In pixel shader
float paramA_final = paramA;
if (AudioTarget == 1) {
    float audioValue = AS_applyAudioReactivity(1.0, AudioSource, AudioMult, true) - 1.0;
    paramA_final = paramA + (paramA * audioValue * scaleFactor);
}
```

### Rotated Distortion Effects
```hlsl
// Calculate in rotated space, apply to original coordinates
float2 rotatedUV = ApplyRotationTransform(texcoord, rotation);
float2 distortionVector = CalculateDistortion(rotatedUV);
distortionVector.x /= ReShade::AspectRatio; // Aspect ratio correction
float2 distortedUV = clamp(texcoord + distortionVector, 0.0, 1.0);
float4 result = tex2D(ReShade::BackBuffer, distortedUV);
```

### Resolution Scaling
```hlsl
float resolutionScale = (float)BUFFER_HEIGHT / 1080.0;
float2 scaledCoord = texcoord * resolutionScale;
```

### Documentation Header Template
```hlsl
/**
 * AS_TypeCode_Name.Version.fx - Brief Description
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

## Quick Reference

### Naming Convention
- Shaders: `AS_TypeCode_EffectName.Version.fx`
  - Type codes: LFX (Lighting), VFX (Visual), AFX (Audio), etc.
  - Version: Major version (.1.fx, .2.fx) changes break preset compatibility

### Function Selection Guide
- Simple randomness → `AS_hash11/21/12`
- Organic patterns → `AS_PerlinNoise2D`
- Natural textures → `AS_Fbm2D`
- Flowing effects → `AS_Fbm2D_Animated`
- Cell/voronoi → `AS_VoronoiNoise2D`
- Complex fluids → `AS_DomainWarp2D`

## Commit and Documentation Guidelines

### Documentation Updates
- When preparing to commit, check all documentation (.md and .txt files, like readme.md and docs/template/release.md) for necessary changes and additions
- Update docs to reflect new features, parameters, or behavior changes
- Modify documentation files to maintain consistency with code
- Commit all pending changes with meaningful commit messages that describe the changes in detail