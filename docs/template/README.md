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

AS-StageFX includes **{{total}} shaders** across four categories: **{{byType.BGX}} Background (BGX)**, **{{byType.GFX}} Graphic (GFX)**, **{{byType.LFX}} Lighting (LFX)**, and **{{byType.VFX}} Visual (VFX)** effects.

**Detailed descriptions and examples: [Shader Gallery](docs/gallery.md).**

### Background Effects (BGX)

| Shader                 | Description                                                                                                | License   |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- | --------- |
{{#each grouped.BGX}}
| **{{name}}** | {{shortDescription}} | {{licenseCode}} |
{{/each}}

### Graphic Effects (GFX)

| Shader                 | Description                                                                                                | License   |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- | --------- |
{{#each grouped.GFX}}
| **{{name}}** | {{shortDescription}} | {{licenseCode}} |
{{/each}}

### Lighting Effects (LFX)

| Shader                 | Description                                                                                                | License   |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- | --------- |
{{#each grouped.LFX}}
| **{{name}}** | {{shortDescription}} | {{licenseCode}} |
{{/each}}

### Visual Effects (VFX)

| Shader                 | Description                                                                                                | License   |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- | --------- |
{{#each grouped.VFX}}
| **{{name}}** | {{shortDescription}} | {{licenseCode}} |
{{/each}}

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
- **{{credits.adaptedCount}} adapted shaders** with full attribution to original creators
- **{{credits.originalCount}} original works** created specifically for AS-StageFX
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