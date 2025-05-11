# AS-StageFX for ReShade

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)

![Listeningway](https://github.com/user-attachments/assets/e8b32c91-071d-490c-8c07-903738a8d3a0)

**A suite of dynamic, audio-reactive visual effect shaders for ReShade, optimized for video production and virtual performance art.**

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

Effects are categorized as Background (BGX), Graphic (GFX), Lighting (LFX), and Visual (VFX).

### Background Effects (BGX)
-   **Cosmic Kaleidoscope**: Renders a raymarched volumetric fractal (Mandelbox/Mandelbulb-like) with adjustable parameters, kaleidoscopic mirroring, audio reactivity, palette-based coloring, and full rotation/position/depth control. Includes fixes for tiling and rotation from the original source.
-   **Fractal Strands**: Intricate, evolving fractal patterns; customizable type, depth, colors, animation, audio reactivity.
-   **Light Ripples**: Mesmerizing, rippling kaleidoscopic light patterns with customizable distortion, animation, color palettes (with cycling), audio reactivity, depth-awareness, rotation, and blending.
-   **Light Wall**: Seamless, soft, overlapping grid of light panels with 14 built-in patterns. Features audio reactivity, customizable palettes, light bursts, 3D perspective, and blend modes.
-   **Melt Wave**: Flowing, warping psychedelic effect with sine-based distortions. Features adjustable zoom/intensity, palette system, time-based animation with keyframes, audio reactivity, and position/rotation controls.
-   **Plasma Flow**: Sophisticated, gentle, flexible plasma effect with procedural noise and domain warping. Generates smooth, swirling, organic patterns with customizable color gradients (2-4 colors) and audio-reactive modulation of movement, color, brightness, and turbulence.
-   **Shine On**: Dynamic, evolving fractal noise pattern with bright, sparkly, moving crystal highlights. Features layered noise, procedural animation, customizable crystal parameters, audio reactivity, and depth-awareness.
-   **Stained Lights**: Dynamic, colorful patterns like stained glass with shifting light and blurred layers. Features multi-layered/iterated patterns, animation, customizable scaling/edges, audio reactivity, post-processing, and depth-awareness.
-   **Time Crystal**: Hypnotic, crystalline fractal structure with dynamic animation and color cycling. Features customizable iterations, speed, density/detail, palettes, audio reactivity, depth-awareness, and position/rotation controls.
-   **Wavy Squares**: Hypnotic pattern of wavy, animated, transforming square tiles with dynamic size changes. Features customizable wave parameters, tile size/scaling, smoothness/roundness, audio reactivity, depth-awareness, rotation, and standard position/scale/blend options.
-   **Wavy Squiggles**: Mesmerizing pattern of adaptive wavy lines following a fixed position, forming intricate, rotating designs. Features customizable line parameters, color palettes, pattern displacement, audio reactivity, depth-awareness, and rotation.
-   **Blue Corona**: Vibrant, abstract blue corona with fluid, dynamic motion and hypnotic, organic, plasma-like visuals. Features customizable iteration/scale, speed/flow, color controls, audio reactivity, depth-awareness, and standard position/rotation/scale/blend options.
-   **Zippy Zaps**: Dynamic electric arcs/lightning patterns with procedural generation. Features customizable colors, intensity, animation, resolution independence, audio reactivity, depth-awareness, and 3D rotation/positioning.
-   **Golden Clockwork**: Intricate, animated golden clockwork or Apollonian fractal patterns. Features complex geometric designs and dynamic movement with a golden palette. Offers extensive controls for animation (speed, keyframe, path evolution), complexity, color, audio reactivity, stage presence (position, scale, rotation, depth), and blending.

### Graphic Effects (GFX)
-   **Multi-Layer Halftone**: Highly customizable multi-layer halftone (up to 4 layers). Each layer supports different patterns (dots, lines, crosshatch), isolation methods (brightness, RGB, hue, depth), colors, thresholds, scales, densities, angles, and layer blending.

### Lighting Effects (LFX)
-   **Candle Flame**: Animated procedural candle flames with realistic shape/color gradients at a specific depth. Features customizable appearance (shape, color, animation, sway, flicker), audio reactivity, resolution independence, and multiple instances.
-   **Laser Show**: Multiple colored laser beams from a user-defined origin, illuminating animated procedural smoke. Features up to 8 configurable beams, FBM Simplex noise smoke with domain warping, audio-reactive fanning/blinking, depth occlusion, and tunable blending.
-   **Stage Spotlights**: Simulates up to 4 independently controllable directional spotlights with glow effects and audio reactivity. Features customizable position, size, color, angle, direction, audio-reactive intensity, automated sway, pulsing, bokeh glow, depth-masking, and multiple blend modes.

### Visual Effects (VFX)
-   **Boom Sticker**: Displays a texture overlay ("sticker") with controls for placement, scale, rotation, audio reactivity, and depth masking.
-   **Broken Glass**: Broken glass/mirror effect; customizable crack patterns.
-   **Digital Artifacts**: Creates stylized digital artifacts, glitch effects, and hologram visuals with 3D positioning. Features audio-reactive intensity, depth control, and various effect types.
-   **Motion Trails**: Creates striking, persistent motion trails based on depth. Features multiple capture modes, audio reactivity, and customizable trail appearance.
-   **Rainy Window**: Simulates a rainy window with animated droplets, trails, and frost. Features customizable blur, audio-reactive intensity, and optional lightning.
-   **Screen Ring**: Draws a textured ring/band in screen space with depth occlusion. Customizable position, size, texture, and rotation.
-   **Sparkle Bloom**: Creates a dynamic sparkle and bloom effect that responds to scene lighting, depth, camera movement, and audio. Features Voronoi noise, customizable lifetime, depth masking, fresnel, and bloom.
-   **Spectrum Ring**: Generates a stylized, circular audio visualizer displaying all Listeningway frequency bands. Features customizable repetitions, patterns, and color gradients.
-   **Stencil Mask**: Foreground subject isolation; customizable borders, projected shadows.
-   **Tilted Grid**: Rotatable pixelating grid with adjustable borders and chamfered corners. Features audio reactivity and depth masking.
-   **VU Meter**: Audio-reactive VU meter with multiple display styles (bars, line, dots, classic VU), customizable appearance, palettes, and zoom/pan controls.
-   **Warp Distort**: Creates an audio-reactive warp effect with customizable shape (circular or resolution-relative), pulsing radius, and wave/ripple effects. Position and depth are adjustable.
-   **Water Surface**: Water surface with depth-based reflections, perspective-scaled waves, and customizable appearance.

**Detailed descriptions and examples: [Shader Gallery](docs/GALLERY.md).**

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

Many shaders are adaptations from effects for other engines, enhanced for ReShade.
-   **FencerDevLog**: Original Godot shader tutorials.
    -   Rainy Window: [Godot 4: Rainy Window Shader](https://www.youtube.com/watch?v=QAOt24qV98c)
    -   Candle Flame: [Godot 4: Candle Flame Shader](https://www.youtube.com/watch?v=6ZZVwbzE8cw)
    -   Tilted Grid: [Godot 4: Tilted Grid Effect Tutorial](https://www.youtube.com/watch?v=Tfj6RDqXEHM)
    -   Support: [Patreon](https://www.patreon.com/c/FencerDevLog/posts)
-   **Inigo Quilez**: Procedural graphics work ([iquilezles.org](https://iquilezles.org)).
    -   Cosmic Kaleidoscope: "Domain Warping," "Kaleidoscopic IFS."
    -   ZippyZaps: Electric arcs, "2D SDF."
-   **The Book of Shaders**: Educational resource ([thebookofshaders.com](https://thebookofshaders.com)).
    -   Shine On: Original "Shine On" by emodeman ([ShaderToy](https://www.shadertoy.com/view/st23zw)).
    -   Broken Glass: Cellular noise, fracture patterns.
    -   Screen Ring: SDF rendering.
-   **ShaderToy Community**: Various inspirations.
    -   Water Surface: [ShaderToy Water Collection](https://www.shadertoy.com/results?query=water).
    -   Multi-Layer Halftone: ["Halftone Shader"](https://www.shadertoy.com/view/XdcGzn) by P. Gonzalez Vivo.
    -   Plasma Flow: Classic demoscene plasma (e.g., [this](https://www.shadertoy.com/view/XsVSzW)).
    -   Cosmic Kaleidoscope: Original "cosmos in crystal" by nayk ([ShaderToy](https://www.shadertoy.com/view/MXccR4)).
    -   Rainy Window: Core droplet logic inspired by "Heartfelt" by Martijn Steinrucken (BigWings) ([ShaderToy](https://www.shadertoy.com/view/ltffzl)).
    -   Blue Corona: Based on "Blue Corona" by SnoopethDuckDuck ([ShaderToy](https://www.shadertoy.com/view/XfKGWV)), adapted with enhanced controls and AS StageFX integration.
    -   Light Ripples: Original shader by Danilo Guanabara ([Pouet](https://www.pouet.net/prod.php?which=57245)).
    -   Shine On: Original "Shine On" by emodeman ([ShaderToy](https://www.shadertoy.com/view/st23zw)).
    -   Stained Lights: Inspired by "Stained Lights" by 104 ([ShaderToy](https://www.shadertoy.com/view/WlsSzM)).
    -   Time Crystal: Original concept "Time Crystal" by raphaeljmu ([ShaderToy](https://www.shadertoy.com/view/lcl3z2)).
    -   Wavy Squares: Original "Square Tiling Example E" by SnoopethDuckDuck ([ShaderToy](https://www.shadertoy.com/view/NdfBzn)).
    -   Wavy Squiggles: Original "Interactive 2.5D Squiggles" by SnoopethDuckDuck ([ShaderToy](https://www.shadertoy.com/view/7sBfDD)).
    -   Zippy Zaps: Original shader by SnoopethDuckDuck (ShaderToy link pending).
-   **ReShade Team**: For the ReShade framework.

Attributions are included in shader headers.