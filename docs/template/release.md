# AS-StageFX Shaders v${VERSION}

## Installation Instructions

### 1. Download
- [Download the ZIP file](https://github.com/LeonAquitaine/as-stagefx/releases/download/${VERSION}/as-stagefx-${VERSION}.zip) containing the shaders.

### 2. Extract Files
- Unzip the downloaded archive.

### 3. Copy Shaders
- Place the AS folder (which is inside the shaders folder from the download) into your game's reshade-shaders\Shaders directory.
- **Example Path:** 
  ```
  C:\Program Files (x86)\SquareEnix\FINAL FANTASY XIV - A Realm Reborn\game\reshade-shaders\Shaders\AS
  ```

### 4. Launch & Activate
- Start your game.
- Open the ReShade overlay (usually the `Home` key).
- Reload your shaders if necessary (`Ctrl+Shift+R` or via settings).
- You should now find the AS-StageFX shaders (prefixed with `AS_`) in the shader list.
- Enable the ones you wish to use.

## Available Shaders

This package includes the following shaders:

**Lighting Effects (LFX):**
- **AS_LFX_LightWall** - Generates configurable grids of light panels with diverse patterns
- **AS_LFX_StageSpotlights** - Adds up to 3 customizable directional stage lights
- **AS_LFX_LaserShow** - Creates multiple colored laser beams with animated smoke effects

**Visual Effects (VFX):**
- **AS_VFX_BoomSticker** - Displays a texture overlay with audio-reactive positioning
- **AS_VFX_DigitalArtifacts** - Applies audio-driven digital artifacts and hologram effects
- **AS_VFX_SparkleBloom** - Creates a realistic, dynamic sparkle effect on surfaces
- **AS_VFX_MotionTrails** - Creates music-reactive, depth-based motion trails
- **AS_VFX_PlasmaFlow** - Generates smooth, swirling, organic plasma-like patterns
- **AS_VFX_SpectrumRing** - Generates a stylized, circular audio visualizer
- **AS_VFX_StencilMask** - Isolates foreground subjects with customizable borders
- **AS_VFX_VUMeter** - Visualizes audio frequency bands as a VU meter background
- **AS_VFX_WarpDistort** - Creates a circular mirrored or wavy region that reacts to audio