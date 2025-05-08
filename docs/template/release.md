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

## Updates in v1.0.4.2

This release includes important enhancements and improvements:

1. **New `stanh()` Function in AS_Utils.1.fxh**
   - Added safe hyperbolic tangent function to prevent NaN/infinity for extreme inputs
   - Provides vectorized versions for float2, float3, and float4 types
   - Improves mathematical stability in shaders using hyperbolic tangent functions

2. **Enhanced ZippyZaps Shader**
   - Added option to use original mathematical colors with adjustable intensity and saturation
   - Inverted Arc Flow Factor behavior for more intuitive control (higher values = more chaotic patterns)
   - Improved audio reactivity options:
     - Added Arc Flow Factor as an audio reactivity target
     - Added Main Color Numerator as an audio reactivity target
     - Removed less effective Animation Speed and Arc Sharpness options
   - Updated default values for improved visual quality

3. **Code Quality Improvements**
   - Enhanced adherence to AS StageFX Shader Development standards
   - Better documentation of functions and parameters
   - Fixed audio reactivity application for Arc Flow Factor

For the full changelog and documentation, please refer to the main README.md.

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

*For detailed descriptions, usage notes (including audio reactivity with Listeningway), and license information, please refer to the main [README.md](https://github.com/LeonAquitaine/as-stagefx/blob/main/README.md).*