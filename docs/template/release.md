# AS-StageFX Shaders v${VERSION}

Thank you for downloading the AS-StageFX shader collection for ReShade! This package provides a variety of lighting, visual, and audio-reactive effects designed for stage performances, virtual photography, and creative expression in games.

## Installation Instructions

### 1. Download
- [Download the ZIP file](https://github.com/LeonAquitaine/as-stagefx/releases/download/${VERSION}/as-stagefx-${VERSION}.zip) containing the shaders and textures.

### 2. Extract Files
- Unzip the downloaded archive. You should see `shaders` and `textures` folders.

### 3. Copy Shaders & Textures
- **Shaders:** Place the `AS` folder (found inside the extracted `shaders` folder) into your game's `reshade-shaders\Shaders` directory.
- **Textures:** Place the contents of the extracted `textures` folder into your game's `reshade-shaders\Textures` directory. Create the `Textures` folder if it doesn't exist.
- **Example Paths:** 
  ```
  C:\...\YourGame\reshade-shaders\Shaders\AS
  C:\...\YourGame\reshade-shaders\Textures\
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
- **AS_LFX_CandleFlame** - Creates procedural candle flames with support for multiple instances
- **AS_LFX_LaserShow** - Creates multiple colored laser beams with animated smoke effects
- **AS_LFX_LightWall** - Generates configurable grids of light panels with diverse patterns
- **AS_LFX_StageSpotlights** - Adds up to 3 customizable directional stage lights

**Visual Effects (VFX):**
- **AS_VFX_BoomSticker** - Displays a texture overlay with audio-reactive positioning
- **AS_VFX_DigitalArtifacts** - Applies audio-driven digital artifacts and hologram effects
- **AS_VFX_MotionTrails** - Creates music-reactive, depth-based motion trails
- **AS_VFX_MultiLayerHalftone** - Applies halftone patterns with separate control over shadows, midtones and highlights
- **AS_VFX_PlasmaFlow** - Generates smooth, swirling, organic plasma-like patterns
- **AS_VFX_RainyWindow** - Simulates raindrops sliding down a window with dynamic trails
- **AS_VFX_SparkleBloom** - Creates a realistic, dynamic sparkle effect on surfaces
- **AS_VFX_SpectrumRing** - Generates a stylized, circular audio visualizer
- **AS_VFX_StencilMask** - Isolates foreground subjects with customizable borders
- **AS_VFX_TiltedGrid** - Creates a rotatable grid with adjustable borders and chamfered corners
- **AS_VFX_VUMeter** - Visualizes audio frequency bands as a VU meter background
- **AS_VFX_WarpDistort** - Creates a circular mirrored or wavy region that reacts to audio

## Usage Notes
- Most shaders include audio reactivity features powered by the [Listeningway](https://github.com/ValentinAkrock/Listeningway) ReShade addon. Ensure Listeningway is installed and configured for audio reactivity to function.
- Many shaders utilize depth information. Ensure your game provides depth buffer access to ReShade for these effects to work correctly.
- Performance impact varies by shader and settings. Adjust parameters like quality levels or sample counts if needed.

## License
AS-StageFX shaders are licensed under the Creative Commons Attribution 4.0 International License (CC BY 4.0). You are free to use, share, and adapt these shaders for any purpose, including commercially, as long as you provide attribution.

---
Enjoy the show!