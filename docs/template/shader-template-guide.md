# AS StageFX Shader Template Guide

This document explains how to use the shader template and provides specific guidance for different shader types.

## Template Location

The comprehensive shader template is located at:
`docs/template/shader-template.fx.example`

## Using the Template

1. **Copy the template file** to your shader location
2. **Replace placeholders** marked with `[BRACKETS]` with your specific values
3. **Remove optional sections** that don't apply to your shader type
4. **Customize UI parameters** based on your effect's needs
5. **Implement your effect algorithm** in the pixel shader

## Placeholder Reference

| Placeholder | Description | Examples |
|-------------|-------------|----------|
| `[TYPECODE]` | Shader category code | BGX, VFX, LFX, GFX |
| `[EffectName]` | CamelCase effect name | BlueCorona, CircularSpectrum |
| `[Version]` | Major version number | 1, 2, 3 |
| `[Brief Description]` | One-line summary | "Blue Corona Background Effect" |
| `[Author Name]` | Your name | "Leon Aquitaine" |

## Shader Type Guidelines

### BGX (Background Effects)
**Purpose**: Full-screen background patterns and environments

**Typical Features**:
- Procedural pattern generation using AS_Utils noise functions
- Full-screen coverage with depth testing
- Animation and audio reactivity
- Color palette support

**Key Implementation Points**:
- Use `AS_getAnimationTime()` for consistent animation
- Apply audio reactivity to pattern parameters
- Ensure resolution independence
- Use depth testing to render behind scene objects

**Example Parameters**:
- Pattern scale, speed, complexity
- Color weights or palette selection
- Background color
- Animation controls

### VFX (Visual Effects)
**Purpose**: Overlay effects, particles, distortions, audio visualizers

**Typical Features**:
- Audio-reactive elements using FreqBands data
- Particle systems or geometric patterns
- Position and scale controls
- Advanced blending modes

**Key Implementation Points**:
- Use `AS_applyAudioReactivity()` for audio response
- Implement AS_Palette system for dynamic coloring
- Support multiple instances (use UI macros for repeated controls)
- Consider texture-based effects with preprocessor customization

**Example Parameters**:
- Audio sensitivity and target selection
- Particle count, size, behavior
- Effect positioning and scaling
- Bloom and glow controls

### LFX (Lighting Effects)
**Purpose**: Lighting simulation, flame effects, spotlights

**Typical Features**:
- Realistic lighting simulation
- Multi-instance support (multiple lights/flames)
- Depth-aware rendering
- Advanced shape and color controls

**Key Implementation Points**:
- Use UI macros to define multiple instances efficiently
- Implement proper depth occlusion
- Create helper functions for repeated calculations
- Support fine-tuned positioning and sizing

**Example Parameters**:
- Light/flame position, size, intensity
- Color temperature or palette
- Shape and behavior controls
- Flicker and animation settings

### GFX (Graphics/Post-Processing)
**Purpose**: Image processing, composition aids, screen-space effects

**Typical Features**:
- Non-destructive image processing
- Composition guides and overlays
- Aspect ratio and framing tools
- Screen-space transformations

**Key Implementation Points**:
- Focus on enhancing rather than replacing the original image
- Provide comprehensive control sets for professional use
- Implement multiple overlay modes
- Ensure pixel-perfect accuracy for guides

**Example Parameters**:
- Processing intensity and thresholds
- Guide types and visibility
- Overlay colors and opacity
- Precision positioning controls

## Advanced Patterns

### Audio Reactivity Pattern
```hlsl
// Parameter-specific audio target selection
uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target";
    ui_items = "None\0Parameter A\0Parameter B\0"; > = 0;

// In pixel shader
float paramA_final = paramA;
if (AudioTarget == 1) {
    float audioValue = AS_applyAudioReactivity(1.0, AudioSource, AudioMult, true) - 1.0;
    paramA_final = paramA + (paramA * audioValue * scaleFactor);
}
```

### Multi-Instance Pattern
```hlsl
#define INSTANCE_UI(index, defaultEnable, defaultPos, defaultScale) \
uniform bool Instance##index##_Enable < ui_label = "Enable Instance " #index; ui_category = "Instance " #index; > = defaultEnable; \
uniform float2 Instance##index##_Position < ui_type = "slider"; ui_label = "Position"; ui_min = -1.0; ui_max = 1.0; ui_category = "Instance " #index; > = defaultPos; \
uniform float Instance##index##_Scale < ui_type = "slider"; ui_label = "Scale"; ui_min = 0.1; ui_max = 2.0; ui_category = "Instance " #index; > = defaultScale;

// Use the macro for each instance
INSTANCE_UI(1, true, float2(0.0, 0.0), 1.0)
INSTANCE_UI(2, false, float2(0.2, 0.2), 0.8)
```

### Texture-Based Pattern
```hlsl
// Preprocessor-based texture customization
#ifndef TEXTURE_PATH
#define TEXTURE_PATH "default.png"
#endif

texture EffectTexture < source = TEXTURE_PATH; ui_label = "Texture"; > 
{ Width = 256; Height = 256; Format = RGBA8; };
sampler TextureSampler { Texture = EffectTexture; /* sampling settings */ };
```

### Palette Integration Pattern
```hlsl
// In UI section
AS_PALETTE_SELECTION_UI(EffectPalette, "Color Palette", AS_PALETTE_FIRE, "Colors")
AS_DECLARE_CUSTOM_PALETTE(Effect_, "Colors")

// In pixel shader
float3 effectColor;
if (EffectPalette == AS_PALETTE_CUSTOM) {
    effectColor = AS_GET_INTERPOLATED_CUSTOM_COLOR(Effect_, colorPosition);
} else {
    effectColor = AS_getInterpolatedColor(EffectPalette, colorPosition);
}
```

## Best Practices

### UI Organization
1. **Tunable Constants** - Core effect parameters
2. **Palette & Style** - Color and appearance controls
3. **Effect-Specific** - Unique parameters for this effect
4. **Animation Controls** - Speed and keyframe controls
5. **Audio Reactivity** - Audio source and target selection
6. **Stage/Position** - Positioning, scaling, rotation, depth
7. **Final Mix** - Blend mode and strength
8. **Debug Controls** - Development and troubleshooting aids

### Coordinate System
- Always apply transformations in this order: **rotation → position → scale**
- Use `AS_getRotationRadians()` for consistent rotation handling
- Apply aspect ratio correction: `coords.x *= ReShade::AspectRatio`
- Rotate around screen center, not effect center

### Performance Considerations
- Use constants instead of magic numbers
- Minimize texture samples in loops
- Use `saturate()`, `lerp()`, and `smoothstep()` for smooth transitions
- Cache expensive calculations outside loops

### Code Style
- Use meaningful variable names
- Group related UI controls with consistent categories
- Add helpful tooltips to all UI elements
- Comment complex mathematical operations
- Use helper functions for repeated calculations

## Validation Checklist

Before committing your shader:

- [ ] All placeholder values replaced
- [ ] UI controls properly organized and categorized
- [ ] Audio reactivity implemented and tested
- [ ] Depth testing working correctly
- [ ] Effect scales properly with resolution
- [ ] Blend modes function as expected
- [ ] Debug modes provide useful information
- [ ] Documentation header complete and accurate
- [ ] Technique guard uses correct identifier
- [ ] No compilation errors or warnings
