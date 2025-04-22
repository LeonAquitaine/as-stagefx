# AS-StageFX for ReShade

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)

**A suite of effect shaders for ReShade, meticulously crafted for Final Fantasy XIV screenshots, video production, and virtual performance art.**

![AS-StageFX - Rock Stage Example](https://i.imgur.com/placeholder.jpg)

---

## Overview

**AS-StageFX** brings dynamic stage lighting and atmospheric effects to your fingertips within ReShade. Whether you're capturing stunning gpose shots, creating machinima, or setting the scene for a virtual concert in FFXIV, these shaders provide powerful tools to enhance your visuals.

This collection focuses on performance-style effects, featuring the **Rock Stage Suite** and seamless integration with audio reactivity tools.

---

## Features

**Rock Stage Suite**: A comprehensive set of shaders within AS-StageFX for building dynamic stage environments:
  * **Light Wall**: Generate configurable grids of light panels with diverse patterns, animations, and audio reactivity. Perfect for backdrops and ambient lighting.
  * **Spotlights**: Add customizable directional stage lights with realistic beam effects, colour control, and movement. Ideal for highlighting subjects.
  * **Atmospherics**: Enhance scene depth and mood with volumetric fog, haze, and particle effects that interact intelligently with your scene geometry.

**Deep Audio Integration**:
  * Leverages **[Listeningway](https://github.com/Listeningway)** for sophisticated audio reactivity (optional but highly recommended).
  * Effects respond dynamically to beat detection, frequency ranges, and overall volume.

**Advanced Capabilities**:
  * **Depth-Aware Effects**: Shaders intelligently interact with scene geometry, ensuring lights and fog wrap naturally around objects and characters (requires proper ReShade depth buffer setup).
  * **Multiple Blend Modes**: Fine-tune how lighting effects combine with your scene for various artistic outcomes.
  * **Pattern Presets**: Quickly apply pre-configured looks for the Light Wall and other effects.
  * **Optimized Performance**: Designed with performance in mind, though complex scenes may require tuning.

---

## Installation

**Prerequisites:**
* **ReShade**: Ensure you have the latest version of [ReShade](https://reshade.me/) installed for your target application (e.g., FFXIV).
* **(Optional) Listeningway**: For audio reactivity, install [Listeningway](https://github.com/Listeningway).

**Steps:**
1.  **Download:** Obtain the latest release of **AS-StageFX** from the release page.
2.  **Extract Files:** Unzip the downloaded archive.
3.  **Copy Shaders:** Place the `AS` folder into your game's `reshade-shaders\Shaders` directory.
4.  **Launch & Activate:** Start your game. Open the ReShade overlay (usually the `Home` key) and reload your shaders if necessary. You should now find the **AS-StageFX** shaders (prefixed with `AS_`) in the shader list. Enable the ones you wish to use.

---

## Usage Guide

### Rock Stage: Light Wall (`AS_RockStage-LightWall.1.fx`)

Creates a versatile grid of light panels, ideal for backgrounds.

* **Patterns:** Select from 14+ built-in patterns (e.g., Empty Heart, Diamond, Checker, Beat Meter) or create custom looks.
* **Audio Reactivity:** Panels can pulse, change colour, or animate based on audio input via Listeningway.
* **Customization:** Adjust grid size, colours, brightness, effect intensity, and animation speed.
* **Spotlight Bursts:** Add dynamic flare effects.
* **Depth Integration:** Configure depth settings to ensure the wall appears correctly positioned within your 3D scene.

### Rock Stage: Spotlights (`AS_RockStage-Spotlights.1.fx`)

Adds up to 3 independent, directional spotlights.

* **Control:** Position, aim, and customize each spotlight individually.
* **Audio Reactivity:** Intensity, colour, sway, and animations can react to music.
* **Beam Properties:** Adjust beam colour, softness, length, width, and atmospheric scattering.
* **Visual Quality:** Features realistic light glow and atmospheric interaction.

---

## Tips for Optimal Results

* **Depth Buffer Access:** Crucial for many features! Ensure ReShade has depth buffer access enabled and correctly configured for your game. Check the ReShade overlay's `Add-ons` or `DX11/DX12` tab. You may need to select the correct depth buffer format.
* **Shader Order:** The order in which ReShade applies effects matters. Generally, place **AS-StageFX** effects *after* colour correction (like LUTs or levels) but *before* final post-processing effects like bloom, sharpening, or lens flares. Experiment to find what looks best!
* **Performance Tuning:** These shaders are optimized, but complex effects can be demanding. Disable features or shaders you aren't actively using within the ReShade overlay to save performance. Reduce grid sizes or particle counts if needed.
* **Listeningway Setup:** For the best audio reactivity, ensure Listeningway is running and properly configured to capture the audio source you want the shaders to react to (e.g., game audio, system audio, specific application).

---

## Credits

* **Author:** [Leon Aquitaine](https://bsky.app/profile/leon.aquitaine.social)
* **Product:** AS-StageFX
* **Technology:** Built upon the [ReShade FX](https://github.com/crosire/reshade-shaders/blob/slim/REFERENCE.md) shader framework.
* **Acknowledgements:** Special thanks to the broader ReShade development community and testers.

---

## License

The shaders included in **AS-StageFX** are licensed under the **Creative Commons Attribution 4.0 International License (CC BY 4.0)**.

[![CC BY 4.0](https://licensebuttons.net/l/by/4.0/88x31.png)](https://creativecommons.org/licenses/by/4.0/)

This means you are free to:
* **Share** — copy and redistribute the material in any medium or format.
* **Adapt** — remix, transform, and build upon the material for any purpose, even commercially.

Under the following terms:
* **Attribution** — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.

*(Please note: ReShade itself and Listeningway have their own licenses.)*

---

## Support & Contribution

* **Found a Bug?** Report issues via the [GitHub Issues Page](https://github.com/LeonAquitaine/as-stagefx/issues).
* **Need Help?** Join the Sights of Eorzea community on [Discord](https://discord.com/servers/sights-of-eorzea-1124828911700811957).
* **Stay Updated:** Follow [@Leon Aquitaine](https://bsky.app/profile/leon.aquitaine.social) on BlueSky.
