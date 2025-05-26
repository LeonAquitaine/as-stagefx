# AS StageFX Implementation Guide

## Quick Reference

**Essential Dependencies**: `AS_Utils.1.fxh`, `ReShade.fxh`  
**Core Principles**: Consistency, modularity, performance, accessibility  
**Required Guards**: Technique guards prevent duplicate loading

### Common Constants & Ranges:
```hlsl
// Standard UI ranges from AS_Utils.1.fxh:
AS_POSITION_MIN/MAX: -1.5f to 1.5f      // Position controls
AS_SCALE_MIN/MAX: 0.1f to 5.0f          // Scale controls  
AS_ANIMATION_SPEED_MIN/MAX: 0.0f to 5.0f // Animation speed
GRID_SIZE_MIN/MAX: 0.001f to 0.2f       // Grid cell sizes
BORDER_THICKNESS_MIN/MAX: 0.0f to 1.0f  // Border/line thickness

// Commonly used parameter ranges:
Pattern Scale: 0.1 to 10.0 (step 0.01)
Pattern Offset: -2.0 to 2.0 (step 0.01)  
Glow/Blur: 0.0 to 5.0 (step 0.01)
Intensity/Strength: 0.0 to 4.0 (step 0.05)
Rotation: -180.0 to 180.0 (step 0.1)
```

### Essential Macros:
```hlsl
AS_POS_UI(name)              // Position drag control
AS_SCALE_UI(name)            // Scale slider  
AS_STAGEDEPTH_UI(name)       // Stage depth control
AS_ROTATION_UI(snap, fine)   // Rotation controls
AS_AUDIO_UI(name, label, default, category)  // Audio source
AS_BLENDMODE_UI(name)        // Blend mode combo
AS_PALETTE_SELECTION_UI(name, label, default, category) // Palette
```

## Coordinate System

### Standard Order: Effect Processing → Position/Scale → Rotation

#### 4-Step Implementation:
```hlsl
// 1. Convert to normalized central square [-1,1]
float aspectRatio = ReShade::AspectRatio;
float2 uv_norm;
if (aspectRatio >= 1.0) {
    uv_norm.x = (texcoord.x - 0.5) * 2.0 * aspectRatio;
    uv_norm.y = (texcoord.y - 0.5) * 2.0;
} else {
    uv_norm.x = (texcoord.x - 0.5) * 2.0;
    uv_norm.y = (texcoord.y - 0.5) * 2.0 / aspectRatio;
}

// 2. Apply inverse global rotation
float globalRotation = AS_getRotationRadians(SnapRotation, FineRotation);
float sinRot = sin(-globalRotation), cosRot = cos(-globalRotation);
float2 rotated_uv = float2(
    uv_norm.x * cosRot - uv_norm.y * sinRot,
    uv_norm.x * sinRot + uv_norm.y * cosRot
);

// 3. Convert back to texcoord space
float2 rotatedTexCoord;
if (aspectRatio >= 1.0) {
    rotatedTexCoord = float2((rotated_uv.x / aspectRatio / 2.0) + 0.5, (rotated_uv.y / 2.0) + 0.5);
} else {
    rotatedTexCoord = float2((rotated_uv.x / 2.0) + 0.5, (rotated_uv.y * aspectRatio / 2.0) + 0.5);
}

// 4. Apply effect transformation
float2 uv = AS_transformCoord(rotatedTexCoord, EffectCenter, EffectScale, 0.0);
```

#### UI Controls:
```hlsl
AS_POS_UI(EffectCenter)
AS_SCALE_UI(EffectScale)
AS_ROTATION_UI(SnapRotation, FineRotation)
```

## Troubleshooting

### Critical Rule: Use Standard AS_transformCoord Function
**NEVER implement custom coordinate transformations.**

```hlsl
// CORRECT:
float2 uv = AS_transformCoord(texcoord, EffectCenter, EffectScale, globalRotation);

// WRONG:
float2 centered = texcoord - 0.5;
centered.x *= aspectRatio;  // This approach has multiple issues
```

### Common Issues & Fixes:

**Y-Axis Inversion:** Effect at wrong vertical position
- Fixed in AS_Utils.1.fxh: `coord.y -= scaledPos.y;` (not +=)

**X-Axis Central Square:** Effect at screen edge instead of central square
- Fixed in AS_Utils.1.fxh: `scaledPos.x = pos.x * 0.5;` (not * aspectRatio)

**Rotation Order:** Effect orbits screen center instead of rotating around itself
- Fixed in AS_Utils.1.fxh: Apply rotation BEFORE position offset

**Rotation Direction:** Negative values rotate clockwise instead of anticlockwise
- Fixed in AS_Utils.1.fxh: `float negatedRotation = -rotation;`

### Validation Test Cases:
| UI Position | Expected Result |
|-------------|----------------|
| (-1, -1) | Top-left of central square |
| (0, 0) | Exact screen center |
| (+1, +1) | Bottom-right of central square |

## Palette Integration

### UI Declaration:
```hlsl
AS_PALETTE_SELECTION_UI(PaletteSelection, "Effect Palette", AS_PALETTE_CUSTOM, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(EffectName_, "Palette & Style")
```

### Color Retrieval:
```hlsl
float3 effectColor;
if (PaletteSelection == AS_PALETTE_CUSTOM) {
    effectColor = AS_GET_INTERPOLATED_CUSTOM_COLOR(EffectName_, paletteValue);
} else {
    effectColor = AS_getInterpolatedColor(PaletteSelection, paletteValue);
}
```

### Palette Value Examples:
- Linear: `float paletteValue = saturate(distance / maxDistance);`
- Audio: `float paletteValue = saturate(audioAmplitude);`
- Angular: `float paletteValue = saturate(angle / AS_TWO_PI);`

## Audio Reactivity

### UI Controls:
```hlsl
uniform float Sensitivity < ui_label = "Audio Sensitivity"; ui_type = "slider"; ui_min = 0.5; ui_max = 5.0; ui_category = "Audio Reactivity"; > = 1.4;
uniform bool UseLogScale < ui_label = "Use Logarithmic Scale"; ui_category = "Audio Reactivity"; > = false;
```

### Usage Patterns:
```hlsl
// Single band: float audioValue = AS_getFreq(bandIndex) * Sensitivity;
// Interpolated: getMirroredFreqBand(normalizedPosition, mirror_active)
// Processing: float processed = pow(saturate(rawAudio * sensitivity), 0.7);
// Log scale: processed = log(1.0 + processed * 9.0) / log(10.0);
```

## UI Standards

### Standardized Category Order:
```hlsl
// 1. Position & Transformation  
AS_POS_UI(EffectCenter)               // "Position" category
AS_SCALE_UI(EffectScale)

// 2. Palette & Style
AS_PALETTE_SELECTION_UI(PaletteSelection, "Color Palette", AS_PALETTE_CUSTOM, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(EffectName_, "Palette & Style")
uniform bool UseOriginalColors < ui_category = "Palette & Style"; > = false;

// 3. Effect-Specific Appearance
uniform float PatternScale < ui_category = "Pattern"; > = 1.0;
uniform int VisualizationMode < ui_category = "Effect Settings"; > = 0;

// 4. Animation Controls
AS_ANIMATION_SPEED_UI(AnimationSpeed, "Animation")
AS_ANIMATION_KEYFRAME_UI(AnimationKeyframe, "Animation")

// 5. Audio Reactivity  
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(AudioMultiplier, "Intensity", 1.0, 4.0, "Audio Reactivity")

// 6. Stage Controls
AS_STAGEDEPTH_UI(EffectDepth)         // "Stage" category
AS_ROTATION_UI(SnapRotation, FineRotation)

// 7. Final Mix
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_LIGHTEN)  // "Final Mix" category
AS_BLENDAMOUNT_UI(BlendAmount)

// 8. Debug Controls (optional)
AS_DEBUG_UI("Off\0Pattern Only\0Audio\0")  // "Debug" category
```

### UI Macro Usage Patterns:
```hlsl
// Standard macros from AS_Utils.1.fxh:
AS_POS_UI(name)                      // Position drag control (-1.5 to 1.5)
AS_SCALE_UI(name)                    // Scale slider (0.1 to 5.0)
AS_STAGEDEPTH_UI(name)               // Stage depth (0.0 to 1.0)
AS_ROTATION_UI(snapName, fineName)   // Snap rotation + fine adjustment
AS_AUDIO_UI(name, label, default, cat) // Audio source dropdown
AS_BLENDMODE_UI(name)                // Blend mode combo
AS_BLENDAMOUNT_UI(name)              // Blend strength slider
AS_DEBUG_UI(items)                   // Debug mode dropdown

// Palette macros from AS_Palette.1.fxh:
AS_PALETTE_SELECTION_UI(name, label, default, category)
AS_DECLARE_CUSTOM_PALETTE(prefix, category)
```

### Category Organization Rules:
- **Position**: Always first, contains AS_POS_UI and AS_SCALE_UI
- **Palette & Style**: Color controls, material settings, visual style options
- **Effect-Specific**: Categories named by function ("Pattern", "Lighting", "Grid Pattern", etc.)
- **Animation**: Speed controls and keyframe settings (when applicable)
- **Audio Reactivity**: Audio source selection and intensity multipliers
- **Stage**: Depth testing and rotation controls
- **Final Mix**: Blend mode and strength - always near the end
- **Debug**: Debug visualizations - always last category

### UI Declaration Requirements:
- **Single-line only**: All uniform declarations must be one-liners
- **Named constants**: Use MIN/MAX/DEFAULT constants, never magic numbers
- **Consistent tooltips**: Clear, concise explanations of parameter effects
- **Category grouping**: Use `ui_category = "Name"` to group related parameters
- **Category collapsing**: Use `ui_category_closed = true` for secondary/advanced categories
- **Tooltip patterns**: "Controls X", "Adjusts Y", "How much Z affects..."

### Multi-Instance Pattern:
```hlsl
// For effects with multiple copies (spotlights, layers, etc.)
#define LAYER_UI(index, defaults...) \
uniform bool Layer##index##_Enable < ui_category = "Layer " #index " Settings"; ui_category_closed = index > 1; > = defaultEnable; \
uniform float Layer##index##_Param < ui_category = "Layer " #index " Settings"; > = defaultValue;

// Usage: First instance open by default, others closed
LAYER_UI(1, true, 1.0)    // "Layer 1 Settings" - open
LAYER_UI(2, false, 0.5)   // "Layer 2 Settings" - closed
```

## Conversion Workflows

### GLSL to HLSL Mappings:
```hlsl
// GLSL → HLSL
vec2 → float2
vec3 → float3
vec4 → float4
texture2D() → tex2D()
mix() → lerp()
fract() → frac()
mod() → AS_mod()
```

### Replace Patterns:
```hlsl
// OLD: Custom coordinates
vec2 uv = (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
// NEW: Standard transformation
float2 uv = AS_transformCoord(rotatedTexCoord, EffectCenter, EffectScale, 0.0);

// OLD: Hard-coded time
float time = iTime;
// NEW: AS_Utils time
float time = AS_getTime();

// OLD: Hard-coded colors
vec3 color = vec3(1.0, 0.5, 0.0);
// NEW: Palette system
float3 color = AS_getInterpolatedColor(PaletteSelection, paletteValue);
```

## Development Workflow

### Type Codes:
**BGX** (Backgrounds), **VFX** (Visual effects), **LFX** (Lighting), **GFX** (Graphics), **AFX** (Audio-focused)

### Development Phases:
1. **Core Effect**: Basic functionality with placeholders
2. **Coordinate System**: 4-step rotation + position/scale UI
3. **Palette Integration**: Color system + palette UI
4. **Audio Reactivity**: Audio controls + frequency sampling
5. **Optimization**: LOD systems + early termination + polish

### Level of Detail (LOD):
```hlsl
float lod_factor = saturate(1.0 - (distance_from_center - LOD_THRESHOLD) / LOD_THRESHOLD);
int effective_samples = max(MIN_SAMPLES, int(float(MAX_SAMPLES) * lod_factor));
```

### Early Termination:
```hlsl
// Depth/distance/audio checks
if (sceneDepth < EffectDepth - AS_DEPTH_EPSILON) return originalColor;
if (distance_from_center > MAX_EFFECT_RADIUS) return originalColor;
if (audioLevel < MIN_AUDIO_THRESHOLD) return lowIntensityBlend;
```

### Loop Optimization:
```hlsl
// Pre-calculate constants, use [unroll(N)], skip iterations based on LOD
int step_size = max(1, TOTAL_STEPS / effective_steps);
for (int i = 0; i < TOTAL_STEPS; i += step_size) { /* process */ }
```

## Common UI Patterns

### Parameter Naming Conventions:
```hlsl
// Pattern parameters follow consistent naming:
uniform float PatternScale < ui_category = "Pattern"; > = 1.0;
uniform float PatternOffset < ui_category = "Pattern"; > = 0.0;  
uniform int PatternType < ui_category = "Pattern"; > = 0;
uniform float PatternThickness < ui_category = "Pattern"; > = 0.1;

// Grid/mesh effects use standardized names:
uniform float GridSize < ui_category = "Grid Pattern"; > = 0.05;
uniform float GridSpacing < ui_category = "Light Boxes"; > = 32.0;
uniform float BorderThickness < ui_category = "Grid Pattern"; > = 0.1;

// Animation parameters are consistent:
uniform float AnimationSpeed < ui_category = "Animation"; > = 1.0;
uniform float RotationSpeed < ui_category = "Pattern Motion"; > = 0.5;
```

### Audio Parameter Patterns:
```hlsl
// Standard audio source dropdowns:
uniform int VUMeterSource < ui_items = "Volume\0Beat\0Bass\0Mid\0Treble\0"; ui_category = "Audio Reactivity"; > = 1;
uniform int AudioTarget < ui_items = "None\0Parameter A\0Parameter B\0"; ui_category = "Audio Reactivity"; > = 0;

// Multiplier/sensitivity controls:
uniform float AudioMultiplier < ui_min = 0.0; ui_max = 4.0; ui_category = "Audio Reactivity"; > = 1.0;
uniform float VUBarLogMultiplier < ui_tooltip = "Boosts higher frequency bars logarithmically"; ui_category = "Audio Reactivity"; > = 1.0;
```

### Effect-Specific Category Patterns:
```hlsl
// BGX shaders commonly use:
"Pattern"           // Core pattern parameters  
"Lighting"          // Color and illumination settings
"Stage Effects"     // Environmental effects
"Performance"       // Parallax, animation controls

// VFX shaders commonly use:
"Effect Settings"   // Core effect parameters
"Appearance"        // Visual style controls  
"Grid Pattern"      // For grid-based effects
"Layer N Settings"  // For multi-layer effects

// GFX shaders commonly use:
"Pattern"           // Geometric pattern controls
"Composition Guides" // Layout assistance
"Advanced Guide Options" // Extended pattern controls
```

### Tooltip Consistency Patterns:
```hlsl
// Control descriptions follow consistent patterns:
"Controls the X"        // For primary parameters
"Adjusts the Y"        // For modifier parameters  
"How much Z affects..." // For influence parameters
"Size of X"            // For scale parameters
"Speed of Y"           // For animation parameters
"Thickness of Z"       // For line/border parameters
"Enable/Disable X"     // For boolean toggles
```

### Advanced UI Features:
```hlsl
// Spacing and grouping:
uniform float ParamA < ui_spacing = 0; > = 1.0;        // No spacing before
uniform float ParamB < ui_same_line = true; > = 0.5;   // Same line as previous

// Category management:
uniform bool Enable < ui_category = "Layer 1"; ui_category_closed = false; > = true;  // Open by default
uniform bool Enable2 < ui_category = "Layer 2"; ui_category_closed = true; > = false; // Closed by default

// Extended UI text for complex parameters:
uniform int ColorScheme < ui_text = "Defines the color relationship rule. See tooltip for details."; > = 0;
```

---

## Testing Checklist

**Functional**: Rotation, aspect ratio independence, position/scale controls, depth masking, palette integration, audio reactivity  
**Performance**: 60+ FPS @1080p, 30+ FPS @4K, effective LOD, reasonable memory usage
**Visual**: No artifacts, smooth audio response, proper blending, consistent brightness  
**Code**: Naming conventions, UI organization, complete documentation, technique guards, single-line uniforms

## Templates

### Base Template:
```hlsl
#ifndef __AS_TYPECODE_EFFECTNAME_1_fx
#define __AS_TYPECODE_EFFECTNAME_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

// UI declarations (standard order)
AS_POS_UI(EffectCenter)
AS_SCALE_UI(EffectScale)
AS_PALETTE_SELECTION_UI(PaletteSelection, "Effect Palette", AS_PALETTE_CUSTOM, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(Template_, "Palette & Style")
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(SnapRotation, FineRotation)
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_LIGHTEN)
AS_BLENDAMOUNT_UI(BlendAmount)

float4 PS_Template(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    
    // Depth check + coordinate transformation + effect logic
    if (ReShade::GetLinearizedDepth(texcoord) < EffectDepth - AS_DEPTH_EPSILON) return orig;
    
    // [Insert 4-step rotation implementation]
    float2 uv = AS_transformCoord(rotatedTexCoord, EffectCenter, EffectScale, 0.0);
    
    float3 effectColor = float3(1,0,0); // Your effect here
    
    return AS_applyBlend(float4(effectColor, 1.0), orig, BlendMode, BlendAmount);
}

technique AS_TypeCode_EffectName {
    pass { VertexShader = PostProcessVS; PixelShader = PS_Template; }
}

#endif
```

### Audio Addition:
```hlsl
// UI: uniform float Sensitivity < ui_label = "Audio Sensitivity"; ui_type = "slider"; ui_min = 0.5; ui_max = 5.0; ui_category = "Audio Reactivity"; > = 1.4;
// Usage: float audioValue = pow(saturate(AS_getFreq(0) * Sensitivity), 0.7);
```

---

*AS StageFX Implementation Guide - Optimized for AI consumption*
