# AS-StageFX for ReShade

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)

![Listeningway7c](https://github.com/user-attachments/assets/e8b32c91-071d-490c-8c07-903738a8d3a0)

**A suite of dynamic, audio-reactive visual effect shaders for ReShade, with a focus on video production and virtual performance art.**

---

## Overview

**AS-StageFX** is a set of dynamic lighting, audio visualizers, and special effects. Initially focused on stage lighting, the collection also include glitter, glitch, warp, and other creative effects. Whether you're capturing gpose shots, creating machinima, setting the scene for a virtual concert, or adding unique flair to your visuals, these shaders provide customizable tools.

Most shaders feature seamless integration with **[Listeningway](https://github.com/Listeningway)** for audio reactivity.

---

## Installation

**Prerequisites:**
* **ReShade**: Ensure you have the latest version of [ReShade](https://reshade.me/) installed for your target application (e.g., FFXIV).
* **(Optional) Listeningway**: For audio reactivity, install [Listeningway](https://github.com/Listeningway). Highly recommended for most shaders in this pack.

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

## Features

AS-StageFX includes a variety of distinct visual effects:

**Stage Lighting & Ambiance:**
* **RS: Light Wall (`AS_RS-LightWall.1.fx`):** Generate configurable grids of light panels with diverse patterns, 3D perspective, audio reactivity, and customizable color palettes. Perfect for backdrops.
* **RS: Spotlights (`AS_RS-Spotlights.1.fx`):** Add up to 3 customizable directional stage lights with realistic beam/glow effects, depth masking, and audio-reactive intensity and movement. (Technique: [AS] Rock Stage: Spotlights)
* **Glitter (`AS_Glitter.1.fx`):** Creates a realistic, dynamic sparkle effect on surfaces that responds to scene lighting, depth, camera movement, and audio. Includes bloom and fresnel effects.
* **Lava Lamp (`AS_LavaLamp.1.fx`):** Renders smooth, merging blobs like a lava lamp, with audio-reactive size, movement, and color. Includes depth occlusion.

**Audio Visualizers & Glitch FX:**
* **Hologram Glitch (`AS_HologramGlitch.1.fx`):** Applies audio-driven hologram and digital glitch effects, including scanlines, RGB split, jitter, and pulsing synced to music.
* **Mandala (`AS_Mandala.1.fx`):** Generates a stylized, circular mandala that acts as a full-spectrum audio visualizer (UV meter) using all Listeningway bands, with repetitions and mirroring.
* **Warp (`AS_Warp.1.fx`):** Creates a circular mirrored or wavy region (often behind a character) that pulses, changes radius, and ripples/warps in sync with audio.
* **MV: Motion Trails (`AS_MV-MotionTrails.1.fx`):** Creates music-reactive, depth-based motion trails for dramatic visual effects in videos and screenshots. (Technique: [AS] Music Video: Motion Trails)

**Core Capabilities:**
* **Deep Audio Integration:** Most effects leverage **[Listeningway](https://github.com/Listeningway)**, allowing various parameters (intensity, speed, size, color, etc.) to react dynamically to volume, beat, bass, treble, or specific frequency bands.
* **Depth-Aware Effects:** Many shaders intelligently interact with scene geometry (using the depth buffer) for natural integration, masking, and occlusion.
* **Customization:** Offers extensive controls for colors, intensity, speed, positioning, blend modes, and audio source selection per effect.
* **Shared Utilities (`AS_Utils.fxh`):** Uses a common backend for blend modes, audio processing, color palettes, and timing, ensuring consistency.

---

## Usage Guide

Below are details on each effect shader included in AS-StageFX:

### Glitter Effect (`AS_Glitter.1.fx`)

Creates a realistic, dynamic glitter/sparkle effect on surfaces.

* **Description:** Simulates tiny reflective particles that pop in, glow, and fade out, responding dynamically to scene lighting, depth, camera movement, and audio.
* **Key Features:**
    * Natural sparkle distribution via multi-layered Voronoi noise.
    * Customizable sparkle animation and lifetime.
    * Depth-based masking for precise placement control.
    * High-quality bloom effect with adjustable quality settings.
    * Fresnel effect based on surface normals for realistic light interaction (sparkles brighter at glancing angles).
    * Multiple blend modes and color options.
    * Audio-reactive sparkle intensity and animation speed via Listeningway.

### Hologram Glitch Effect (`AS_HologramGlitch.1.fx`)

Applies audio-driven hologram and digital glitch effects.

* **Description:** Creates scanlines, RGB color splitting, and digital jitter/glitching effects that pulse and react to music via Listeningway for impactful visuals.
* **Key Features:**
    * Audio-reactive scanlines, RGB split intensity, and digital glitch frequency/strength.
    * Pulsing, jitter, and color offsets driven by selectable audio sources (volume, beat, bass, treble, etc.).
    * Adjustable base intensity, speed, and randomness for each effect component.
    * Debug visualizations for mask and audio input.

### Lava Lamp Effect (`AS_LavaLamp.1.fx`)

Renders an audio-reactive visualization resembling a lava lamp.

* **Description:** Creates smooth, merging blobs of color whose size, movement speed, and color intensity are modulated by audio input.
* **Key Features:**
    * Adjustable blob count, base size, blend strength, and movement characteristics.
    * Audio-reactive blob size and movement speed via Listeningway.
    * Customizable colors for blobs and background.
    * Controls for gravity/buoyancy simulation.
    * Depth occlusion support to mask the effect by scene geometry.
    * Debug modes for viewing mask/audio.

### Mandala Audio Visualizer (`AS_Mandala.1.fx`)

Generates a stylized mandala acting as a full-spectrum audio visualizer.

* **Description:** Creates a circular, centered mandala pattern that visualizes intensity across all available Listeningway audio bands simultaneously.
* **Key Features:**
    * Uses all Listeningway audio bands for a detailed UV meter effect.
    * Color gradient (blue for low intensity through red to yellow for high) based on band strength.
    * User-selectable number of repetitions (slices) from 2 to 16.
    * Pattern style options: linear or mirrored repetition.
    * Smooth animation and response to audio changes.

### RS: Light Wall (`AS_RS-LightWall.1.fx`)

Creates a versatile grid of configurable light panels, ideal for backgrounds.

* **Description:** Renders a seamless grid of soft, overlapping light panels with built-in patterns, perfect for dance club or concert backdrops with full customization.
* **Key Features:**
    * 14+ built-in patterns (Heart, Diamond, Beat Meter, etc.) controlling panel visibility.
    * Audio-reactive patterns and pulsing effects via Listeningway.
    * Customizable color palettes (9 presets + custom) with smooth interpolation.
    * Optional light burst effects and cross beams for added drama.
    * 3D perspective controls (tilt, pitch, roll) for depth simulation.
    * Multiple blend modes for seamless scene integration.

### RS: Spotlights (`AS_RS-Spotlights.1.fx`)

Simulates a vibrant stage lighting system with directional spotlights.

*Technique name in ReShade: `[AS] Rock Stage: Spotlights`*

* **Description:** Adds up to 3 independently controllable spotlights with customizable properties, glow effects, and audio reactivity for dramatic lighting.
* **Key Features:**
    * Control position, size, color, angle, and direction for each of the 3 spotlights.
    * Audio-reactive light intensity, automated sway/movement, and pulsing via Listeningway.
    * Atmospheric bokeh glow effects that inherit spotlight colors.
    * Depth-based masking for natural integration with the scene (lights appear behind objects).
    * Multiple blend modes for different lighting scenarios (additive, screen, etc.).

### Warp Effect (`AS_Warp.1.fx`)

Creates an audio-reactive circular mirror or wave effect.

* **Description:** Generates a circular or elliptical region (often centered behind a character) that mirrors or distorts the scene within it, pulsing and warping in sync with music.
* **Key Features:**
    * Circular or elliptical region with adjustable edge softness.
    * Audio-reactive pulsing effect, radius changes, and wave/ripple intensity via Listeningway.
    * User-selectable audio source (volume, beat, bass, treble, etc.) to drive effects.
    * Adjustable base mirror strength, wave frequency/amplitude, and edge softness.
    * Debug visualizations for viewing the effect mask and audio input.

### MV: Motion Trails (`AS_MV-MotionTrails.1.fx`)

Creates music-reactive, depth-based motion trails for dramatic visual effects.

*Technique name in ReShade: `[AS] Music Video: Motion Trails`*

* **Description:**
    * Objects within a specified depth threshold leave behind colored trails that slowly fade, creating dynamic visual paths ideal for music videos, dramatic footage, and creative compositions.
* **Key Features:**
    * Depth-based subject tracking for dynamic trail effects
    * User-definable trail color, strength, and persistence
    * Audio-reactive trail timing, intensity, and colors through Listeningway
    * Multiple blend modes for scene integration
    * Optional real-time subject highlight for better visualization
    * Several timing modes: tempo-based, frame-based, on audio beat, or manual
    * Precise depth control for targeting specific scene elements

---

## Tips for Optimal Results

* **Depth Buffer Access:** Crucial for many features! Ensure ReShade has depth buffer access enabled and correctly configured for your game. Check the ReShade overlay's `Add-ons` or `DX11/DX12` tab. You may need to select the correct depth buffer format (often one with reversed depth works best for FFXIV).
* **Shader Order:** The order in which ReShade applies effects matters. Experiment, but generally place **AS-StageFX** effects *after* foundational color grading (like LUTs or levels) but *before* final screen-space effects like bloom, sharpening, lens flares, or letterboxing. Visualizers might work well placed earlier or later depending on the desired interaction.
* **Performance Tuning:** These shaders are optimized, but complex effects or multiple active shaders can be demanding. Disable effects or specific features within their settings when not needed. Reduce particle counts, grid sizes, or quality settings if performance issues arise.
* **Listeningway Setup:** For the best audio reactivity, ensure Listeningway is running and properly configured to capture the audio source you want the shaders to react to (e.g., game audio, system audio, specific application like Spotify). Adjust Listeningway's sensitivity and band settings as needed.

---

## Credits

* **Author / Lead Developer:** [Leon Aquitaine](https://bsky.app/profile/leon.aquitaine.social)
* **Product:** AS-StageFX
* **Technology:** Built upon the [ReShade FX](https://github.com/crosire/reshade-shaders/blob/slim/REFERENCE.md) shader framework.
* **Acknowledgements:** Special thanks to the broader ReShade development community (especially contributors like prod80, Lord of Lunacy, etc. for foundational techniques) and testers within the FFXIV gposing community.

---

## License

The shaders included in **AS-StageFX** are licensed under the **Creative Commons Attribution 4.0 International License (CC BY 4.0)**. See the [LICENSE.md](LICENSE.md) file for full details.

[![CC BY 4.0](https://licensebuttons.net/l/by/4.0/88x31.png)](https://creativecommons.org/licenses/by/4.0/)

This means you are free to share and adapt these shaders with appropriate credit.

*(Please note: ReShade itself and Listeningway have their own separate licenses.)*

---

## Support & Contribution

* **Found a Bug?** Report issues via the [GitHub Issues Page](https://github.com/LeonAquitaine/as-stagefx/issues).
* **Need Help?** Join the Sights of Eorzea community on [Discord](https://discord.com/servers/sights-of-eorzea-1124828911700811957).
* **Stay Updated:** Follow [@Leon Aquitaine](https://bsky.app/profile/leon.aquitaine.social) on BlueSky.
