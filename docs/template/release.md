# AS-StageFX Shaders v${VERSION}

This release includes the AS-StageFX shader collection for ReShade.

## Installation

1.  **Download:** Get the `as-stagefx-${VERSION}.zip` file from the [Releases page](https://github.com/LeonAquitaine/as-stagefx/releases/tag/${VERSION}).
2.  **Extract:** Unzip the archive. You will find `shaders` and `textures` folders.
3.  **Copy Files:**
    *   Copy the `AS` folder (from the extracted `shaders` folder) into your game's `reshade-shaders\Shaders\` directory.
    *   Copy the contents of the extracted `textures` folder into your game's `reshade-shaders\Textures\` directory (create it if needed).
    *   *Example Paths:*
        ```
        ...\YourGame\reshade-shaders\Shaders\AS\
        ...\YourGame\reshade-shaders\Textures\
        ```
4.  **Activate:** Launch your game, open the ReShade overlay (`Home` key), and enable the desired `AS_` shaders from the list. Reload shaders (`Ctrl+Shift+R`) if needed.

---

## Updates in v${VERSION}

This release includes important enhancements and improvements:

1. **Upgraded AS_BGX_BlueCorona.1.fx**
   - Fixed horizontal squishing issue for more consistent circular patterns
   - Fixed inverted color controls (higher values now produce stronger colors)
   - Added customizable background color with color picker
   - Added inverse audio reactivity for iteration count
   - Improved aspect ratio handling for better appearance on all resolutions
   - Enhanced documentation and code structure
   - Added to standard AS Shader Framework with proper namespacing and organization

2. **Upgraded AS_BGX_WavySquares.1.fx**
   - Added proper documentation and attribution
   - Improved and standardized helper functions 
   - Implemented modern pixel shader with depth, audio, and position features
   - Updated technique name and UI labels
   - Added to standard AS Shader Framework with proper namespacing and organization
   - Fixed various display issues across different resolutions

3. **Code Quality Improvements**
   - Enhanced adherence to AS StageFX Shader Development standards
   - Improved namespace isolation for better compatibility
   - Standardized UI organization for improved user experience
   - Added proper shader guards to prevent duplicate loading

For the full changelog and documentation, please refer to the main README.md and the GALLERY.md for detailed descriptions of each shader.

---

## Bug Fixes in v1.0.5.0

This release includes several important bug fixes and code quality improvements:

1. **Fixed AS_getTime() function in AS_Utils.1.fxh**
   - Now properly detects when Listeningway is active vs. just present but not running
   - Implements proper fallback mechanism for more reliable timing with or without Listeningway
   - Improves animation consistency across all effects that use time-based animations

2. **Improved SparkleBloom Shader**
   - Added "Edge Power" user parameter for precise control of edge emphasis
   - Replaced magic numbers with named constants for better code maintainability
   - Fixed edge detection to ensure sparkles appear properly at object boundaries

3. **Code Quality Improvements**
   - Enhanced adherence to AS StageFX Shader Development standards
   - Improved naming consistency across constants and parameters
   - Better documentation of intended behavior

For the full changelog and documentation, please refer to the main README.md.

---

## New Shader: AS_VFX_WaterSurface.1.fx

**AS_VFX_WaterSurface.1.fx** simulates a realistic water surface with a depth-based reflection horizon, perspective-correct wave compression, and customizable water color, transparency, and reflection. This effect is ideal for scenes with water, pools, or reflective floors.

**Key Features:**
- Depth-aware reflection horizon that shifts based on scene geometry
- Perspective-correct wave scaling and compression
- Customizable water color, transparency, and reflection intensity
- Dynamic wave direction, speed, and distortion controls
- Full resolution independence and proper UI grouping
- Debug modes for visualizing distortion, depth, and reflection horizon

**Parameters:**
- Water Color, Transparency, Reflection Intensity
- Wave Direction, Speed, Scale, Distortion, Scale Curve
- Water Level, Edge Fade
- Depth Scale, Falloff, Perspective
- Blend Mode, Blend Amount
- Debug Mode

**Implementation:**
1. Calculates a perspective-correct reflection horizon using scene depth and user controls
2. Applies dynamic wave distortion, scaling with distance from the horizon
3. Blends the reflected scene with water color and transparency
4. Supports debug visualization for tuning and troubleshooting

See the main README.md for a full feature table and usage notes.

---

## New Shader: AS_BGX_WavySquiggles.1.fx

**AS_BGX_WavySquiggles.1.fx** creates a mesmerizing pattern of adaptive wavy lines that form intricate designs around a central point. This effect is ideal for creating dynamic backgrounds with audio reactivity.

**Key Features:**
- Dynamic wavy line patterns with controls for rotation, distance, thickness, and smoothness
- Pattern displacement for off-center effects
- Multiple coloring options with original mathematical colors or standard AS palette system
- Comprehensive audio reactivity options

The shader is inspired by SnoopethDuckDuck's "Interactive 2.5D Squiggles" on Shadertoy, enhanced with AS StageFX framework integration for consistent positioning, depth awareness, and audio reactivity.

---

## Maintenance Update v1.5.3

This release includes important fixes and improvements:

1. **Added Robust Perlin Noise Functions to AS_Utils.1.fxh**
   - Implemented `AS_PerlinNoise2D` and `AS_PerlinNoise3D` with proper gradient interpolation
   - Added `AS_Fbm2D` for Fractal Brownian Motion multi-octave noise
   - Added `AS_Fbm2D_Animated` for time-based animation effects
   - Added `AS_DomainWarp2D` for fluid-like distortion patterns
   - All functions follow consistent documentation and parameter naming standards

2. **Fixed Glass Roughness in AS_VFX_RainyWindow.1.fx**
   - Glass Roughness parameter now properly affects droplet shape using noise-based distortion
   - Implemented non-circular droplet shapes with angle-dependent distortion
   - Moved all magic numbers to properly named constants in the tunable constants section
   - Improved resolution independence and aspect ratio correction

3. **Improved AS_BGX_MeltWave.1.fx**
   - Fixed rotation direction to ensure negative values rotate counterclockwise
   - Implemented proper resolution-independent coordinate transformation
   - Updated position controls to use the standard -1.5 to 1.5 range
   - Removed deprecated Border Intensity parameter
   - Updated documentation header to accurately reflect current features

For the full changelog and documentation, please refer to the main README.md.