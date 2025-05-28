# AS StageFX Shader Templates

This directory contains comprehensive templates and documentation for creating AS StageFX shaders.

## Template Files

### Main Template
- **`shader-template.fx.example`** - Complete, fully-documented template with all optional features
- **`shader-template-guide.md`** - Comprehensive guide explaining how to use the template

### Type-Specific Templates
- **`bgx-template.fx.example`** - Background effects (BGX) template with noise-based patterns
- **`vfx-template.fx.example`** - Visual effects (VFX) template with audio reactivity focus
- **`lfx-template.fx.example`** - Lighting effects (LFX) template with multi-instance support
- **`gfx-template.fx.example`** - Graphics/Post-processing (GFX) template with guide overlays

## Quick Start Guide

### 1. Choose Your Template
Select the appropriate template based on your effect type:

| Type | Use Case | Template File |
|------|----------|---------------|
| **BGX** | Full-screen backgrounds, environments, patterns | `bgx-template.fx.example` |
| **VFX** | Overlay effects, particles, audio visualizers | `vfx-template.fx.example` |
| **LFX** | Lighting simulation, flames, spotlights | `lfx-template.fx.example` |
| **GFX** | Image processing, composition aids, guides | `gfx-template.fx.example` |

### 2. Copy and Rename
```bash
# Copy the appropriate template
cp bgx-template.fx ../AS_BGX_YourEffectName.1.fx
```

### 3. Replace Placeholders
Search and replace these placeholders throughout your copied file:

- `[EffectName]` → Your effect name in CamelCase (e.g., `CosmicStorm`)
- `[Author Name]` → Your name
- `[Brief Description]` → One-line effect description
- `[Effect Display Name]` → Human-readable name for UI
- `[Description of the X effect]` → Tooltip description

### 4. Implement Your Effect
Replace the example implementation in the pixel shader with your effect algorithm.

### 5. Test and Validate
- Compile and test your shader
- Verify all UI controls work correctly
- Test audio reactivity functionality
- Ensure proper depth testing and blending

## Template Features

All templates include:

### Standard AS StageFX Features
- ✅ **Audio Reactivity** - Using AS_Utils audio functions
- ✅ **Position/Scale/Rotation Controls** - Standard stage controls
- ✅ **Depth Testing** - Proper depth-aware rendering
- ✅ **Blend Modes** - Full AS blend mode support
- ✅ **Animation System** - Consistent timing and keyframe support
- ✅ **Debug Modes** - Built-in debugging and visualization aids

### Code Quality Features
- ✅ **Technique Guards** - Prevent duplicate loading
- ✅ **Namespace Usage** - Avoid naming conflicts
- ✅ **Comprehensive Documentation** - Headers with features and implementation details
- ✅ **Consistent UI Organization** - Standardized parameter grouping
- ✅ **Helper Functions** - Reusable code patterns
- ✅ **Error Prevention** - Proper bounds checking and validation

### Advanced Features
- ✅ **Palette System Integration** - AS_Palette support (where applicable)
- ✅ **Multi-Instance Support** - UI macros for repeated controls (LFX template)
- ✅ **Texture Support** - Preprocessor-based texture loading (example included)
- ✅ **Resolution Independence** - Consistent rendering across all screen sizes
- ✅ **Aspect Ratio Correction** - Proper coordinate transformation

## Template-Specific Details

### BGX Template Features
- Noise-based pattern generation using AS_Utils functions
- Full-screen coverage with depth testing
- Palette-based coloring system
- Multiple complexity levels and animation controls

### VFX Template Features
- Audio-reactive elements with frequency band access
- Advanced audio target selection system
- Additive blending by default for overlay effects
- Debug mode for frequency band visualization

### LFX Template Features
- Multi-instance light system using UI macros
- Individual depth control per light instance
- Flicker and bloom effects
- Helper functions for light calculation

### GFX Template Features
- Non-destructive image processing
- Composition guide system (Rule of Thirds, Golden Ratio, etc.)
- Anti-aliased line drawing functions
- Professional photography/cinematography aids

## Common Customizations

### Adding Custom Parameters
```hlsl
// Add to constants section
static const float MY_PARAM_MIN = 0.0;
static const float MY_PARAM_MAX = 10.0;
static const float MY_PARAM_DEFAULT = 5.0;

// Add to UI section
uniform float MyParameter < ui_type = "slider"; ui_label = "My Parameter"; 
    ui_min = MY_PARAM_MIN; ui_max = MY_PARAM_MAX; ui_category = "Effect"; > = MY_PARAM_DEFAULT;
```

### Adding Audio Reactivity to Custom Parameters
```hlsl
// Add new audio target constant
static const int AUDIO_TARGET_MY_PARAM = 4; // Next available number

// Update the audio target combo
uniform int Effect_AudioTarget < ui_type = "combo"; ui_label = "Audio Target"; 
    ui_items = "None\0...\0My Parameter\0"; > = 0;

// In pixel shader
float myParam = MyParameter;
if (Effect_AudioTarget == AUDIO_TARGET_MY_PARAM) {
    myParam *= AS_applyAudioReactivity(1.0, Effect_AudioSource, Effect_AudioMultiplier, true);
}
```

### Adding Texture Support
```hlsl
// Add preprocessor customization
#ifndef MY_TEXTURE_PATH
#define MY_TEXTURE_PATH "default_texture.png"
#endif

// Declare texture and sampler
texture MyTexture < source = MY_TEXTURE_PATH; ui_label = "My Texture"; > 
{ Width = 256; Height = 256; Format = RGBA8; };
sampler MyTextureSampler { Texture = MyTexture; AddressU = WRAP; AddressV = WRAP; };

// Use in pixel shader
float3 textureColor = tex2D(MyTextureSampler, textureUV).rgb;
```

## Best Practices

1. **Always use the template** - Don't start from scratch
2. **Follow the UI organization** - Keep categories consistent
3. **Test audio reactivity** - Ensure all audio targets work correctly
4. **Use helper functions** - Keep the main shader clean
5. **Add meaningful tooltips** - Help users understand parameters
6. **Test on different resolutions** - Ensure resolution independence
7. **Document your changes** - Update the header documentation

## Getting Help

- Review existing shaders in the `../` directory for reference implementations
- Check `AS_Utils.1.fxh` for available utility functions
- Refer to `shader-template-guide.md` for detailed explanations
- Use debug modes to troubleshoot issues during development

## Contributing

When creating new templates or improving existing ones:

1. Follow the established patterns and conventions
2. Test thoroughly across different shader types
3. Update documentation to reflect any changes
4. Consider backward compatibility with existing shaders
