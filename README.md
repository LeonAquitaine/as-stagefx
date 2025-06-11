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

AS-StageFX includes **57 shaders** across four categories: **26 Background (BGX)**, **7 Graphic (GFX)**, **3 Lighting (LFX)**, and **21 Visual (VFX)** effects.

**Detailed descriptions and examples: [Shader Gallery](docs/gallery.md).**

### Background Effects (BGX)

| Shader                 | Description                                                                                                | License   |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- | --------- |
| **Blue Corona** | Vibrant, abstract blue corona with fluid, dynamic motion and hypnotic, organic, plasma-like visuals. Customizable and audio-reactive. | CC BY-NC-SA |
| **Constellation** | Creates an animated stellar constellation pattern with twinkling stars and connecting lines. Perfect for cosmic, night sky, or abstract network visualizations with a hand-drawn aesthetic. | CC BY-NC-SA |
| **Corridor Travel** | Simulates an artistic flight through an abstract, glowing, patterned tunnel with pseudo-DOF, motion blur, and light bounce simulation. | CC BY-NC-SA |
| **Cosmic Kaleidoscope** | Renders a raymarched volumetric fractal (Mandelbox/Mandelbulb-like) with kaleidoscopic mirroring, audio reactivity, and palette-based coloring. | CC BY-NC-SA |
| **Digital Brain** | Abstract visualization of a digital brain neural network with animated Voronoi patterns, neural-like connections, and electrical pulses. | CC BY-NC-SA |
| **Fluorescent** | Creates a vibrant neon fluorescent background effect with raymarched volumetric patterns. Perfect for retro, cyberpunk, or futuristic atmospheres. | CC BY-NC-SA |
| **Golden Clockwork** | Intricate, animated golden clockwork or Apollonian fractal patterns. | CC BY-NC-SA |
| **Kaleidoscope** | Creates a vibrant, ever-evolving fractal kaleidoscope pattern with animated tendrils. Perfect for psychedelic, cosmic, or abstract backgrounds with a hypnotic quality. | CC BY-NC-SA |
| **Light Ripples** | Mesmerizing, rippling kaleidoscopic light patterns with customizable distortion, animation, color palettes, and audio reactivity. | CC BY-NC-SA |
| **Light Wall** | A seamless, soft, overlapping grid of light panels with various built-in patterns. Perfect for creating dance club and concert backdrops. | CC BY 4.0 |
| **Liquid Chrome** | Creates dynamic, flowing psychedelic patterns reminiscent of liquid metal or chrome, with optional vertical stripe overlays. | CC BY 4.0 |
| **Log Spirals** | Creates an organic spiral pattern based on logarithmic growth with animated spheres along the spiral arms. | CC BY-NC-SA |
| **Melt Wave** | Flowing, warping psychedelic effect with sine-based distortions, palette system, keyframe animation, and audio reactivity. | CC BY-NC-SA |
| **Misty Grid** | Abstract fractal-based grid background with a misty, ethereal appearance using raymarching. Audio-reactive and customizable. | CC BY-NC-SA |
| **Past Racer** | Raymarched abstract procedural scene (2 selectable) with domain repetition, custom transformations, and audio-reactive geometry/flares. | CC BY-NC-SA |
| **Plasma Flow** | Sophisticated, gentle, flexible plasma effect with procedural noise, domain warping, and customizable audio-reactive color gradients. | CC BY-NC-SA |
| **Protean Clouds** | Volumetric, evolving procedural clouds with raymarching, dynamic color, and realistic lighting. | CC BY-NC-SA |
| **Quadtree Truchet** | Multiscale recursive Truchet pattern with hierarchical tile overlaps, Art Deco line tiles, weave effects, and sophisticated palette system. | CC BY-NC-SA |
| **Raymarched Chain** | Raymarched animated chain of interconnected torus shapes following a procedural path. Features dynamic rotation, customizable geometry, and sophisticated lighting with camera controls. | CC BY-NC-SA |
| **Stained Lights** | Dynamic, colorful patterns like stained glass with shifting light, blurred layers, and audio reactivity. | CC BY-NC-SA |
| **Sunset Clouds** | Raymarched volumetric clouds with animated turbulence and dynamic sunset coloring. | CC BY-NC-SA |
| **Time Crystal** | Hypnotic, crystalline fractal structure with dynamic animation, color cycling, and audio reactivity. | CC BY-NC-SA |
| **Vortex** | Psychedelic swirling vortex pattern with animated color, swirl, and brightness controls. | CC BY-NC-SA |
| **Wavy Squares** | Hypnotic pattern of wavy, animated, transforming square tiles with dynamic size changes. Audio-reactive and depth-aware. | CC BY-NC-SA |
| **Wavy Squiggles** | Mesmerizing pattern of adaptive wavy lines forming intricate, rotating designs. Audio-reactive and depth-aware. | CC BY-NC-SA |
| **Zippy Zaps** | Dynamic electric arcs/lightning patterns with procedural generation, audio reactivity, and 3D positioning. | CC BY-NC-SA |

### Graphic Effects (GFX)

| Shader                 | Description                                                                                                | License   |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- | --------- |
| **Aspect Ratio** | A versatile aspect ratio framing tool for subject positioning and composition. | CC BY 4.0 |
| **Audio Direction** | Visualizes audio directionality as animated arrows or indicators, ideal for music-driven scenes or overlays. | CC BY 4.0 |
| **Brush Stroke** | Transforms the scene with painterly brush stroke textures and dynamic, layered paint effects. | CC BY 4.0 |
| **Cinematic Diffusion** | High-quality cinematic diffusion/bloom filter with 8 classic presets and a fully customizable mode. | CC BY 4.0 |
| **Hand Drawing** | Transforms the scene into a stylized hand-drawn sketch with distinct linework. | CC BY-NC-SA |
| **MultiLayer Halftone** | Highly customizable multi-layer halftone (up to 4 layers) with various patterns, isolation methods, and blending options. | CC BY 4.0 |
| **Vignette Plus** | Advanced vignette effect with customizable shape, color, animation, blur, and audio reactivity. | CC BY-NC-SA |

### Lighting Effects (LFX)

| Shader                 | Description                                                                                                | License   |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- | --------- |
| **Candle Flame** | Simulates a realistic, animated candle flame with flicker, glow, and color controls. | CC BY 4.0 |
| **Laser Show** | Projects animated laser beams and patterns with customizable color, speed, and audio reactivity. | CC BY 4.0 |
| **Stage Spotlights** | Simulates moving stage spotlights with beam controls, color, and audio reactivity. | CC BY 4.0 |

### Visual Effects (VFX)

| Shader                 | Description                                                                                                | License   |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- | --------- |
| **Boom Sticker** | Displays a texture overlay ('sticker') with controls for placement, scale, rotation, and audio reactivity. | CC BY 4.0 |
| **Circular Spectrum** | Displays a circular audio spectrum analyzer with customizable bands, colors, and animation. | CC BY-NC-SA |
| **Clair Obscur** | Applies dramatic chiaroscuro lighting with strong contrast and stylized shadows. | CC BY-NC-SA |
| **Color Balancer** | Adjusts scene color balance with independent controls for shadows, midtones, and highlights. | CC BY 4.0 |
| **Digital Artifacts** | Simulates digital compression artifacts, blockiness, and color banding. | CC BY 4.0 |
| **Dust Motes** | Adds floating dust motes and particles with customizable density, size, and animation. | CC BY 4.0 |
| **Focused Chaos** | Swirling cosmic vortex/black hole effect with animated noise and artistic controls. | CC BY-NC-SA |
| **Motion Focus** | Automatic motion-based camera focus and zoom using inter-frame motion analysis. | CC BY 4.0 |
| **Motion Trails** | Creates trailing motion blur effects for moving objects or the entire scene. | CC BY 4.0 |
| **Radial Lens Distortion** | Emulates radial and lens-specific distortions including blur, chromatic aberration, and geometric warping. | CC BY 4.0 |
| **Radiant Fire** | Simulates radiant, glowing fire with animated flames and color gradients. | CC BY-NC-SA |
| **Rainy Window** | Simulates raindrops and streaks on a window with refraction and blur effects. | CC BY-NC-SA |
| **Screen Ring** | Draws animated rings or circular overlays with customizable size, color, and animation. | CC BY 4.0 |
| **Sparkle Bloom** | Adds sparkling bloom highlights with animated glints and color controls. | CC BY 4.0 |
| **Spectrum Ring** | Visualizes audio spectrum as a ring with customizable bands, colors, and animation. | CC BY 4.0 |
| **Stencil Mask** | Applies a stencil mask for selective effect application with shape and position controls. | CC BY 4.0 |
| **Tilted Grid** | Draws a tilted, animated grid overlay with customizable angle, spacing, and color. | CC BY 4.0 |
| **Volumetric Light** | Simulates volumetric light rays and god rays with customizable source, color, and intensity. | CC BY-NC-SA |
| **VUMeter** | Displays a classic VU meter with audio-reactive bars and customizable appearance. | CC BY 4.0 |
| **Warp Distort** | Applies animated warp distortion with customizable strength, direction, and speed. | CC BY 4.0 |
| **Water Surface** | Simulates animated water surface with ripples, reflections, and customizable color. | CC BY 4.0 |

---

## Core Capabilities

-   **Audio Integration:** Most effects utilize [Listeningway](https://github.com/gposingway/Listeningway) for dynamic parameter reaction to volume, beat, bass, treble, or specific frequency bands. New stereo features include left/right channel volume and audio panning for spatial effects.
-   **Depth Awareness:** Many shaders interact with scene geometry (via depth buffer) for integration, masking, and occlusion.
-   **Customization:** Extensive controls for color, intensity, speed, position, blend modes, and audio source per effect.

---

## Disclaimer

Sample images in this repository may contain characters and stickers from Final Fantasy XIV, property of Square Enix Co., Ltd., used for demonstration only. All Final Fantasy XIV content © SQUARE ENIX CO., LTD. All Rights Reserved. This is a fan project, not affiliated with Square Enix.

---

## Credits and Attributions

AS-StageFX includes both original shaders and adaptations from various sources across the graphics programming community. Proper attribution is maintained for all external sources as required by Creative Commons licensing.

**For detailed attribution information**, see: **[AS_StageFX_Credits.md](../AS_StageFX_Credits.md)**

This comprehensive credits document includes:
- ** adapted shaders** with full attribution to original creators
- ** original works** created specifically for AS-StageFX
- **Complete source links** and licensing information
- **Categorized sources**: Shadertoy, Godot, Art of Code, and other GLSL communities

### Key Acknowledgments

- **ReShade Team**: For the exceptional ReShade framework
- **Shadertoy Community**: Primary source for adapted effects
- **FencerDevLog**: Godot shader tutorials and inspiration
- **Inigo Quilez**: Mathematical foundations and procedural techniques
- **All original creators**: Listed individually in the comprehensive credits

---

*For more detailed information about installation, updates, and credits, please refer to the [main README](../README.md). Complete external source attribution is available in [AS_StageFX_Credits.md](../AS_StageFX_Credits.md).*
