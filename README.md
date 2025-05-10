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
-   **Cosmic Kaleidoscope**: Kaleidoscopic star field; dynamic symmetry/rotation.
-   **Light Ripples**: Animated light wave ripples.
-   **Light Wall**: Configurable light panel grids; patterns, 3D perspective, audio reactivity.
-   **Melt Wave**: Customizable melting/warping; resolution-independent positioning.
-   **Plasma Flow**: Smooth, swirling plasma patterns; audio reactivity.
-   **Shine On**: Dynamic light ray backgrounds.
-   **Stained Lights**: Colorful stained glass light patterns; customizable.
-   **Time Crystal**: Crystal-like temporal distortion; configurable patterns.
-   **Wavy Squares**: Dynamic square grid patterns with undulating animation and tunable parameters.
-   **Wavy Squiggles**: Mesmerizing wavy line patterns; dynamic positioning and audio reactivity.
-   **Blue Corona**: Vibrant, abstract plasma-like effect with fluid motion and customizable colors.
-   **Zippy Zaps**: Electric arc/lightning effects; audio reactivity.

### Graphic Effects (GFX)
-   **Multi-Layer Halftone**: Customizable multi-layer halftone screen patterns.

### Lighting Effects (LFX)
-   **Candle Flame**: Up to 4 procedural candle flames; realistic animation, color gradients.
-   **Laser Show**: Multiple colored laser beams from user-defined origin.
-   **Stage Spotlights**: Up to 4 customizable directional stage lights; beam/glow effects.

### Visual Effects (VFX)
-   **Boom Sticker**: Texture overlay; placement, scale, rotation, audio reactivity.
-   **Broken Glass**: Broken glass/mirror effect; customizable crack patterns.
-   **Digital Artifacts**: Audio-driven digital artifacts, glitches, hologram effects.
-   **Motion Trails**: Music-reactive, depth-based motion trails.
-   **Rainy Window**: Realistic rainy window; multi-layered droplets.
-   **Screen Ring**: Customizable circular rings for subject framing.
-   **Sparkle Bloom**: Dynamic sparkle effect; responds to scene lighting/camera movement.
-   **Spectrum Ring**: Circular audio visualizer for Listeningway frequency bands.
-   **Stencil Mask**: Foreground subject isolation; customizable borders, projected shadows.
-   **Tilted Grid**: Rotatable pixelating grid; adjustable borders, chamfered corners.
-   **VU Meter**: Background VU meter; multiple presentation modes.
-   **Warp Distort**: Audio-reactive warp; pulsing radius, wave effects.
-   **Water Surface**: Realistic water surface; depth-based reflection horizon.

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
    -   Shine On: Ray-marching techniques.
    -   Broken Glass: Cellular noise, fracture patterns.
    -   Screen Ring: SDF rendering.
-   **ShaderToy Community**: Various inspirations.
    -   Water Surface: [ShaderToy Water Collection](https://www.shadertoy.com/results?query=water).
    -   Multi-Layer Halftone: ["Halftone Shader"](https://www.shadertoy.com/view/XdcGzn) by P. Gonzalez Vivo.
    -   Plasma Flow: Classic demoscene plasma (e.g., [this](https://www.shadertoy.com/view/XsVSzW)).
    -   Cosmic Kaleidoscope: [Kaleidoscope Toy](https://www.shadertoy.com/view/XtK3Dt) by mindlord.
-   **ReShade Team**: For the ReShade framework.

Attributions are included in shader headers.