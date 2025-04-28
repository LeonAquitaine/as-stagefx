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

**Stage Lighting & Ambiance (RS):**
- **AS_RS-LightWall** - Generates configurable grids of light panels with diverse patterns
- **AS_RS-Spotlights** - Adds up to 3 customizable directional stage lights
- **AS_LaserCannon** - Creates multiple colored laser beams with animated smoke effects

**Cinematic Effects (CN):**
- **AS_CN-BoomSticker** - Displays a texture overlay with audio-reactive positioning
- **AS_CN-DigitalGlitch** - Applies audio-driven digital artifacts and hologram effects
- **AS_CN-Glitter** - Creates a realistic, dynamic sparkle effect on surfaces
- **AS_CN-MotionTrails** - Creates music-reactive, depth-based motion trails
- **AS_CN-PlasmaFlow** - Generates smooth, swirling, organic plasma-like patterns
- **AS_CN-SpectrumRing** - Generates a stylized, circular audio visualizer
- **AS_CN-StencilMask** - Isolates foreground subjects with customizable borders
- **AS_CN-VUMeter** - Visualizes audio frequency bands as a VU meter background
- **AS_CN-Warp** - Creates a circular mirrored or wavy region that reacts to audio