# AS-StageFX for ReShade

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)

![Listeningway](https://github.com/user-attachments/assets/e8b32c91-071d-490c-8c07-903738a8d3a0)

**A suite of dynamic, audio-reactive visual effect shaders for ReShade, with a focus on video production and virtual performance art.**

---

## Overview

**AS-StageFX** is a set of dynamic lighting, audio visualizers, and special effects. Initially focused on stage lighting, the collection also includes glitter, glitch, warp, and other creative effects. Whether you're capturing gpose shots, creating machinima, setting the scene for a virtual concert, or adding unique flair to your visuals, these shaders provide customizable tools.

Most shaders feature seamless integration with **[Listeningway](https://github.com/gposingway/Listeningway)** for audio reactivity.

### Latest Updates (May 8, 2025)
- Split documentation for better readability - detailed shader gallery now in [GALLERY.md](docs/GALLERY.md)
- Added new `stanh()` function to AS_Utils.1.fxh for improved hyperbolic tangent calculation stability
- Enhanced AS_BGX_ZippyZaps with original color mode, inverted Arc Flow Factor, and improved audio reactivity targets
- Fixed audio reactivity for Arc Flow Factor to correctly respond to audio intensity
- Updated default values in ZippyZaps for better visual quality
- Updated version to 1.0.4.2

### Previous Updates (May 5, 2025)
- Fixed AS_getTime() function in AS_Utils.1.fxh to properly detect when Listeningway is active
- Improved SparkleBloom shader with edge control parameter and better code standards compliance
- Replaced magic numbers with named constants in various shaders for better maintainability
- Updated version to 1.0.4.1

---

## Installation

**Prerequisites:**
* **ReShade**: Ensure you have the latest version of [ReShade](https://reshade.me/) installed for your target application (e.g., FFXIV).
* **(Optional) Listeningway**: For audio reactivity, install [Listeningway](https://github.com/gposingway/Listeningway). Highly recommended for most shaders in this pack.

**Steps:**
1. **Download:** [Download the ZIP file](https://github.com/LeonAquitaine/as-stagefx/releases/latest) containing the shaders from the [Releases Page](https://github.com/LeonAquitaine/as-stagefx/releases).
2. **Extract Files:** Unzip the downloaded archive.
3. **Copy Shaders:** Place the `AS` folder (which is inside the `shaders` folder from the download) into your game's `reshade-shaders\Shaders` directory.
   * **Example Path:** 
     ```
     C:\Program Files (x86)\SquareEnix\FINAL FANTASY XIV - A Realm Reborn\game\reshade-shaders\Shaders\AS
     ```
4. **Launch & Activate:** Start your game. Open the ReShade overlay (usually the `Home` key) and reload your shaders if necessary (`Ctrl+Shift+R` or via settings). You should now find the **AS-StageFX** shaders (prefixed with `AS_`) in the shader list. Enable the ones you wish to use.

---

## Available Shaders

AS-StageFX includes a variety of distinct visual effects organized into categories:

### Lighting Effects (LFX)
- **Stage Spotlights** - Up to 3 customizable directional stage lights with beam/glow effects
- **Laser Show** - Multiple colored laser beams emanating from a user-defined origin
- **Candle Flame** - Procedural candle flames with realistic animation and color gradients

### Visual Effects (VFX)
- **Digital Artifacts** - Audio-driven digital artifacts, glitches and hologram effects
- **Sparkle Bloom** - Dynamic sparkle effect responding to scene lighting and camera movement
- **Motion Trails** - Music-reactive, depth-based motion trails for dramatic visual effects
- **Plasma Flow** - Smooth, swirling, organic plasma-like patterns with audio reactivity
- **Spectrum Ring** - Circular audio visualizer displaying Listeningway frequency bands
- **Stencil Mask** - Isolates foreground subjects with customizable borders and projected shadows
- **VU Meter** - Background VU meter with multiple presentation modes
- **Boom Sticker** - Texture overlay with placement, scale, rotation, and audio reactivity
- **Warp Distort** - Circular mirrored/wavy region that pulses and ripples in sync with audio
- **Tilted Grid** - Rotatable pixelating grid with adjustable borders and chamfered corners
- **Rainy Window** - Realistic rainy window effect with multi-layered droplets
- **Water Surface** - Realistic water surface with depth-based reflection horizon
- **Screen Ring** - Customizable circular rings for framing subjects
- **Broken Glass** - Broken glass/mirror effect with customizable crack patterns

### Background Effects (BGX)
- **Cosmic Kaleidoscope** - Kaleidoscopic star field with dynamic symmetry and rotation
- **Infinite Zoom** - Infinitely zooming fractal pattern creating a tunnel/vortex effect
- **Light Wall** - Configurable grids of light panels with patterns, 3D perspective, and audio reactivity
- **Shine On** - Dynamic light ray backgrounds for dreamy or celestial atmospheres
- **Stained Lights** - Colorful stained glass light patterns with customizable design
- **Time Crystal** - Crystal-like temporal distortion effects with configurable patterns
- **Zippy Zaps** - Electric arc/lightning effects with audio reactivity

### Graphic Effects (GFX)
- **Multi-Layer Halftone** - Customizable halftone screen patterns with multiple layers

**Detailed descriptions and visual examples of each shader can be found in the [Shader Gallery](docs/GALLERY.md).**

---

## Core Capabilities

- **Deep Audio Integration:** Most effects leverage [Listeningway](https://github.com/gposingway/Listeningway), allowing various parameters to react dynamically to volume, beat, bass, treble, or specific frequency bands.
- **Depth-Aware Effects:** Many shaders intelligently interact with scene geometry (using the depth buffer) for natural integration, masking, and occlusion.
- **Customization:** Offers extensive controls for colors, intensity, speed, positioning, blend modes, and audio source selection per effect.

---

## Disclaimer

The sample images used in this repository contain characters and stickers from Final Fantasy XIV. These elements are the intellectual property of Square Enix Co., Ltd. and are used here solely for demonstration purposes. All Final Fantasy XIV content is © SQUARE ENIX CO., LTD. All Rights Reserved.

This shader collection is a fan-made project and is not affiliated with, endorsed by, or supported by Square Enix.

---

## Credits and Attributions

Most shaders in the AS_StageFX collection are conversions and adaptations from original effects implemented for other engines, reimagined and enhanced for ReShade. We'd like to acknowledge the following contributors and inspirations:

- **FencerDevLog** - Creator of the original Godot shader tutorials that inspired multiple effects in this collection:
  - Rainy Window shader: [Godot 4: Rainy Window Shader](https://www.youtube.com/watch?v=QAOt24qV98c)
  - Candle Flame shader: [Godot 4: Candle Flame Shader](https://www.youtube.com/watch?v=6ZZVwbzE8cw)
  - Tilted Grid shader: [Godot 4: Tilted Grid Effect Tutorial](https://www.youtube.com/watch?v=Tfj6RDqXEHM)
  - Support his work: [FencerDevLog Patreon](https://www.patreon.com/c/FencerDevLog/posts)

- **Inigo Quilez** - Pioneering work in procedural graphics whose articles inspired:
  - Cosmic Kaleidoscope: Based on "Domain Warping" and "Kaleidoscopic IFS" techniques
  - Infinite Zoom: Adapted from "Distance Functions" and "Fractal Brownian Motion" principles
  - ZippyZaps: Electric arc simulation based on "2D SDF" principles
  - Visit his website: [https://iquilezles.org](https://iquilezles.org) 

- **The Book of Shaders** - Open educational resource that influenced:
  - Shine On: Adapted from ray-marching techniques 
  - Broken Glass: Inspired by cellular noise and fracture patterns
  - Screen Ring: Based on SDF (Signed Distance Field) rendering concepts
  - Resource available at: [https://thebookofshaders.com](https://thebookofshaders.com)

- **ShaderToy Community** - Various creators whose works inspired:
  - Water Surface: Informed by multiple water simulation techniques from [ShaderToy Water Collection](https://www.shadertoy.com/results?query=water)
  - Multi-Layer Halftone: Adapted from ["Halftone Shader"](https://www.shadertoy.com/view/XdcGzn) by Patricio Gonzalez Vivo
  - Plasma Flow: Inspired by classic demoscene plasma effects like [this implementation](https://www.shadertoy.com/view/XsVSzW)
  - Cosmic Kaleidoscope: Draws from techniques in [Kaleidoscope Toy](https://www.shadertoy.com/view/XtK3Dt) by mindlord
  - Broken Glass: References elements from [Glass Shatter](https://www.shadertoy.com/view/ltffzl) by exoticorn

- **Listeningway** - Core audio integration by [gposingway](https://github.com/gposingway/Listeningway)

- **ReShade Team** - For creating and maintaining the framework that makes these effects possible

Each shader includes appropriate attributions in its header documentation.
