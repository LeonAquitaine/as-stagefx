# AS-StageFX for ReShade

![Listeningway](https://github.com/user-attachments/assets/e8b32c91-071d-490c-8c07-903738a8d3a0)

**A suite of dynamic, audio-reactive visual effect shaders for ReShade, optimized for video production and virtual performance art.**

---

![GitHub release (latest by date)](https://img.shields.io/github/v/release/LeonAquitaine/as-stagefx)
![GitHub all releases](https://img.shields.io/github/downloads/LeonAquitaine/as-stagefx/total)
[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)
![GitHub last commit](https://img.shields.io/github/last-commit/LeonAquitaine/as-stagefx/dev)
![Code Size](https://img.shields.io/github/languages/code-size/LeonAquitaine/as-stagefx)
![GitHub top language](https://img.shields.io/github/languages/top/LeonAquitaine/as-stagefx)
![GitHub issues](https://img.shields.io/github/issues/LeonAquitaine/as-stagefx)
![GitHub contributors](https://img.shields.io/github/contributors/LeonAquitaine/as-stagefx)

---

## Description

AS-StageFX provides a collection of performant, customizable, and audio-reactive visual effects shaders for ReShade. These are designed for screen capture, video recording, streaming, and virtual photography.

---

## Installation

**Prerequisites:**
* **ReShade**: Latest version ([reshade.me](https://reshade.me/)).
* **(Optional) Listeningway**: For audio reactivity ([github.com/gposingway/Listeningway](https://github.com/gposingway/Listeningway)).

**Steps:**
1.  **Download:** Get the [latest release ZIP](https://github.com/LeonAquitaine/as-stagefx/releases/latest).
2.  **Extract:** Unzip the archive.
3.  **Copy Shaders:** Place the `AS` folder (from `shaders` in the download) into your game's `reshade-shaders\Shaders` directory.
    * **Example:** `C:\Program Files (x86)\SquareEnix\FINAL FANTASY XIV - A Realm Reborn\game\reshade-shaders\Shaders\AS`
4.  **Activate:** Launch the game. Open ReShade overlay (default: `Home` key). Reload shaders if needed (`Ctrl+Shift+R` or via settings). AS-StageFX shaders (prefix `AS_`) will be in the list.

---

## Available Shaders

AS-StageFX includes **45 shaders** across four categories: **21 Background (BGX)**, **4 Graphic (GFX)**, **3 Lighting (LFX)**, and **17 Visual (VFX)** effects.

**Detailed descriptions and examples: [Shader Gallery](docs/gallery.md).**

## Performance Guide

Shaders are marked with an icon to give a general idea of their processing intensity:

| Icon | Category      | Count | GPU Time (ms) | Use Cases                                                                 |
| :--: | ------------- | :---: | :-----------: | ------------------------------------------------------------------------- |
|  ✨  | Light         |  31   |    < 0.5      | Everyday use, stacking multiple effects, older hardware.                    |
|  ⚡  | Moderate      |   7   |   0.5 - 2.5   | General purpose, good balance of quality and performance.                   |
|  🔥  | Heavy         |   3   |   2.5 - 10.0  | High-impact visuals, use sparingly if performance is critical.              |
|  💀  | Very Heavy    |   1   |    > 10.0     | Cinematic shots, offline rendering, or very powerful hardware. Demanding. |

### Background Effects (BGX)

| Shader                 | Description                                                                                                |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- |
| **AS_BGX_BlueCorona** 🔥 | Vibrant, abstract blue corona with fluid, dynamic motion and hypnotic, organic, plasma-like visuals. Customizable and audio-reactive. |
| **AS_BGX_Constellation** ⚡ | Creates an animated stellar constellation pattern with twinkling stars and connecting lines. Perfect for cosmic, night sky, or abstract network visualizations with a hand-drawn aesthetic. |
| **AS_BGX_CorridorTravel** 🔥 | Simulates an artistic flight through an abstract, glowing, patterned tunnel with pseudo-DOF, motion blur, and light bounce simulation. |
| **AS_BGX_CosmicKaleidoscope** ⚡ | Renders a raymarched volumetric fractal (Mandelbox/Mandelbulb-like) with kaleidoscopic mirroring, audio reactivity, and palette-based coloring. |
| **AS_BGX_DigitalBrain** ✨ | Abstract visualization of a digital brain neural network with animated Voronoi patterns, neural-like connections, and electrical pulses. |
| **AS_BGX_GoldenClockwork** ✨ | Intricate, animated golden clockwork or Apollonian fractal patterns with complex geometric designs and dynamic movement. |
| **AS_BGX_Kaleidoscope** ✨ | Creates a vibrant, ever-evolving fractal kaleidoscope pattern with animated tendrils. Perfect for psychedelic, cosmic, or abstract backgrounds with a hypnotic quality. |
| **AS_BGX_LightRipples** ✨ | Mesmerizing, rippling kaleidoscopic light patterns with customizable distortion, animation, color palettes, and audio reactivity. |
| **AS_BGX_LightWall** ✨ | Renders a seamless, soft, overlapping grid of light panels with various built-in patterns, ideal for dance club/concert backdrops. Customizable and audio-reactive. |
| **AS_BGX_LiquidChrome** ✨ | Creates dynamic, flowing psychedelic patterns reminiscent of liquid metal or chrome, with optional vertical stripe overlays. |
| **AS_BGX_LogSpirals** ✨ | Creates an organic spiral pattern based on logarithmic growth with animated spheres along the spiral arms. Features precise control over spiral expansion rate and animation, customizable sphere size with fade effects and specular highlights. |
| **AS_BGX_MeltWave** ✨ | Flowing, warping psychedelic effect with sine-based distortions, palette system, keyframe animation, and audio reactivity. |
| **AS_BGX_MistyGrid** 🔥 | Abstract fractal-based grid background with a misty, ethereal appearance using raymarching. Audio-reactive and customizable. |
| **AS_BGX_PastRacer** ⚡ | Raymarched abstract procedural scene (2 selectable) with domain repetition, custom transformations, and audio-reactive geometry/flares. |
| **AS_BGX_PlasmaFlow** ✨ | Sophisticated, gentle, flexible plasma effect with procedural noise, domain warping, and customizable audio-reactive color gradients. |
| **AS_BGX_ShineOn** ✨ | Dynamic, evolving fractal noise pattern with bright, sparkly, moving crystal highlights. Audio-reactive and depth-aware. |
| **AS_BGX_StainedLights** ✨ | Dynamic, colorful patterns like stained glass with shifting light, blurred layers, and audio reactivity. |
| **AS_BGX_TimeCrystal** ✨ | Hypnotic, crystalline fractal structure with dynamic animation, color cycling, and audio reactivity. |
| **AS_BGX_WavySquares** ✨ | Hypnotic pattern of wavy, animated, transforming square tiles with dynamic size changes. Audio-reactive and depth-aware. |
| **AS_BGX_WavySquiggles** ✨ | Mesmerizing pattern of adaptive wavy lines forming intricate, rotating designs. Audio-reactive and depth-aware. |
| **AS_BGX_ZippyZaps** ⚡ | Dynamic electric arcs/lightning patterns with procedural generation, audio reactivity, and 3D positioning. |

### Graphic Effects (GFX)

| Shader                 | Description                                                                                                |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- |
| **AS_GFX_AspectRatio** ✨ | A versatile aspect ratio framing tool designed to help position subjects for social media posts, photography, and video composition. Features preset aspect ratios for common social media and photography formats (1:1, 16:9, 4:5, etc.), custom aspect ratio input, adjustable clipped area color and opacity, and other helper functions. Perfect for precise subject positioning and consistent framing across platforms. |
| **AS_GFX_HandDrawing** 💀 | Transforms the scene into a stylized hand-drawn sketch with distinct linework. Features sophisticated line generation with customizable stroke directions and length and textured fills based on original image colors with noise-based variation. Perfect for artistic transformations, comic/manga styles, or technical illustrations. |
| **AS_GFX_MultiLayerHalftone** ✨| Highly customizable multi-layer halftone (up to 4 layers) with various patterns, isolation methods, and blending options. |
| **AS_GFX_VignettePlus** ✨ | Advanced vignette effect with customizable shape, color, animation, blur, and audio reactivity. |

### Lighting Effects (LFX)

| Shader                 | Description                                                                                                |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- |
| **AS_LFX_CandleFlame** ✨ | Animated procedural candle flames with realistic shape/color gradients, audio reactivity, and multiple instances. |
| **AS_LFX_LaserShow** ✨ | Multiple colored laser beams from a user-defined origin, illuminating animated procedural smoke. Audio-reactive and depth-occluded. |
| **AS_LFX_StageSpotlights** ✨ | Simulates up to 4 independently controllable directional spotlights with glow effects, audio reactivity, and depth-masking. |

### Visual Effects (VFX)

| Shader                 | Description                                                                                                |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- |
| **AS_VFX_BoomSticker** ✨ | Displays a texture overlay ("sticker") with controls for placement, scale, rotation, audio reactivity, and depth masking. |
| **AS_VFX_CircularSpectrum** ⚡ | Creates a dynamic circular audio spectrum visualizer with floating dots arranged in a ring pattern, featuring customizable colors, patterns, and audio reactivity. |
| **AS_VFX_ClairObscur** ✨ | Creates a beautiful cascade of floating petals with realistic movement, organic animation, and natural rotation variation. |
| **AS_VFX_ColorBalancer** ✨ | Enables colorists and videographers to apply classic cinematic color harmony models (complementary, analogous, triadic, split-complementary, tetradic) to live visuals or video production. It offers flexible color manipulation across shadows, midtones, and highlights. |
| **AS_VFX_DigitalArtifacts** ✨ | Stylized digital artifacts, glitch effects, and hologram visuals with 3D positioning and audio-reactive intensity. |
| **AS_VFX_DustMotes** ⚡ | Simulates static, sharp-bordered dust motes using two independent particle layers with a blur effect. Audio-reactive and depth-masked. |
| **AS_VFX_MotionTrails** ✨ | Creates striking, persistent motion trails based on depth, with multiple capture modes and audio reactivity. |
| **AS_VFX_RadiantFire** ✨ | GPU-based fire simulation generating flames radiating from subject edges, with physics affected by rotation. |
| **AS_VFX_RainyWindow** ✨ | Simulates a rainy window with animated droplets, trails, frost, and optional audio-reactive lightning. |
| **AS_VFX_ScreenRing** ✨ | Draws a textured ring/band in screen space with depth occlusion, customizable position, size, texture, and rotation. |
| **AS_VFX_SparkleBloom** ⚡ | Dynamic sparkle and bloom effect responding to scene lighting, depth, camera movement, and audio. Uses Voronoi noise. |
| **AS_VFX_SpectrumRing** ✨ | Stylized circular audio visualizer displaying all Listeningway frequency bands with customizable patterns and colors. |
| **AS_VFX_StencilMask** ✨ | Foreground subject isolation with customizable borders and projected shadows. |
| **AS_VFX_TiltedGrid** ✨ | Rotatable pixelating grid with adjustable borders, chamfered corners, audio reactivity, and depth masking. |
| **AS_VFX_VUMeter** ✨ | Audio-reactive VU meter with multiple display styles, customizable appearance, palettes, and zoom/pan controls. |
| **AS_VFX_WarpDistort** ✨ | Audio-reactive warp effect with customizable shape, pulsing radius, and wave/ripple effects. Adjustable position and depth. |
| **AS_VFX_WaterSurface** ✨ | Water surface with depth-based reflections, perspective-scaled waves, and customizable appearance. |

---

## Core Capabilities

-   **Audio Integration:** Most effects utilize [Listeningway](https://github.com/gposingway/Listeningway) for dynamic parameter reaction to volume, beat, bass, treble, or specific frequency bands.
-   **Depth Awareness:** Many shaders interact with scene geometry (via depth buffer) for integration, masking, and occlusion.
-   **Customization:** Extensive controls for color, intensity, speed, position, blend modes, and audio source per effect.

---

## Disclaimer

Sample images in this repository may contain characters and stickers from Final Fantasy XIV, property of Square Enix Co., Ltd., used for demonstration only. All Final Fantasy XIV content © SQUARE ENIX CO., LTD. All Rights Reserved. This is a fan project, not affiliated with Square Enix.

---

## Credits and Attributions

AS-StageFX includes both original shaders and adaptations from various sources across the graphics programming community. Proper attribution is maintained for all external sources as required by Creative Commons licensing.

**For detailed attribution information**, see: **[AS_StageFX_Credits.md](AS_StageFX_Credits.md)**

This comprehensive credits document includes:
- **29 adapted shaders** with full attribution to original creators
- **19 original works** created specifically for AS-StageFX
- **Complete source links** and licensing information
- **Categorized sources**: Shadertoy, Godot, Art of Code, and other GLSL communities

### Key Acknowledgments

- **ReShade Team**: For the exceptional ReShade framework
- **Shadertoy Community**: Primary source for adapted effects
- **FencerDevLog**: Godot shader tutorials and inspiration
- **Inigo Quilez**: Mathematical foundations and procedural techniques
- **All original creators**: Listed individually in the comprehensive credits