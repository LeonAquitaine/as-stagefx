# AS-StageFX for ReShade

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)

![Listeningway7c](https://github.com/user-attachments/assets/e8b32c91-071d-490c-8c07-903738a8d3a0)

**A suite of dynamic, audio-reactive visual effect shaders for ReShade, with a focus on video production and virtual performance art.**

---

## Overview

**AS-StageFX** is a set of dynamic lighting, audio visualizers, and special effects. Initially focused on stage lighting, the collection also includes glitter, glitch, warp, and other creative effects. Whether you're capturing gpose shots, creating machinima, setting the scene for a virtual concert, or adding unique flair to your visuals, these shaders provide customizable tools.

Most shaders feature seamless integration with **[Listeningway](https://github.com/gposingway/Listeningway)** for audio reactivity.

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

## Features

AS-StageFX includes a variety of distinct visual effects:

<table>
  <tr>
    <th colspan="2"><strong>Lighting Effects (LFX)</strong></th>
  </tr>
  <tr>
    <td width="50%"><strong>LFX: Light Wall</strong> (<code>AS_LFX_LightWall.1.fx</code>)<br>
      Generate configurable grids of light panels with diverse patterns, 3D perspective, audio reactivity, and customizable color palettes. Perfect for backdrops.</td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/ece86ab7-36f1-459c-8c83-31414c3b5cc3" alt="Light Wall Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>LFX: Stage Spotlights</strong> (<code>AS_LFX_StageSpotlights.1.fx</code>)<br>
      Add up to 3 customizable directional stage lights with realistic beam/glow effects, depth masking, and audio-reactive intensity and movement.<br><em>Technique: [AS] Stage Spotlights</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/73e1081b-147e-4355-b867-d4964238245b" alt="Spotlights Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>LFX: Laser Show</strong> (<code>AS_LFX_LaserShow.1.fx</code>)<br>
      Renders multiple colored laser beams emanating from a user-defined origin, illuminating a swirling, animated smoke field. Features audio-reactive fanning, blinking, and vortex effects.<br><em>Technique: [AS] Laser Show</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/555b32cd-be6f-47c2-92a6-39994e861637" alt="Laser Show Effect" style="max-width:100%;">
    </div></td>
  </tr>
  
  <tr>
    <th colspan="2"><strong>Visual Effects (VFX)</strong></th>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: Digital Artifacts</strong> (<code>AS_VFX_DigitalArtifacts.1.fx</code>)<br>
      Applies audio-driven digital artifacts, glitches and hologram effects, including scanlines, RGB split, jitter, and pulsing synced to music.</td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/6786cb0a-f2c7-4d82-8584-1c669c7513ea" alt="Digital Artifacts Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: Sparkle Bloom</strong> (<code>AS_VFX_SparkleBloom.1.fx</code>)<br>
      Creates a realistic, dynamic sparkle effect on surfaces that responds to scene lighting, depth, camera movement, and audio. Includes bloom and fresnel effects.</td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/a0998834-4795-414e-a685-9c7ab685a515" alt="Sparkle Bloom Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: Motion Trails</strong> (<code>AS_VFX_MotionTrails.1.fx</code>)<br>
      Creates music-reactive, depth-based motion trails for dramatic visual effects in videos and screenshots.<br><em>Technique: [AS] Motion Trails</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/1b7a2750-89be-424b-b149-4d850692d9f8" alt="Motion Trails Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: Plasma Flow</strong> (<code>AS_VFX_PlasmaFlow.1.fx</code>)<br>
      Generates smooth, swirling, organic plasma-like patterns with enhanced palette options, domain warping, and strong audio reactivity. Ideal for music video backgrounds and atmospheric visuals.</td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/ba95325d-eff0-439e-a452-567675da84fe" alt="Plasma Flow Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: Spectrum Ring</strong> (<code>AS_VFX_SpectrumRing.1.fx</code>)<br>
      Generates a stylized, circular audio visualizer that displays all Listeningway frequency bands, with repetitions and mirroring options.</td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/e193b002-d3aa-4d86-8584-7eb667f6ff6c" alt="Spectrum Ring Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: Stencil Mask</strong> (<code>AS_VFX_StencilMask.1.fx</code>)<br>
      Isolates foreground subjects based on depth and applies customizable borders and projected shadows, with options for border styles and audio reactivity.</td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/98097147-0a9e-40ac-ae21-0b19e5241c91" alt="Stencil Mask Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: VU Meter</strong> (<code>AS_VFX_VUMeter.1.fx</code>)<br>
      Visualizes Listeningway frequency bands as a VU meter background with multiple presentation modes (bars, line, dots), color palettes, and customizable appearance options.<br><em>Technique: [AS] VU Meter Background</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/1b83d29c-a838-492e-82c8-4c503a6867a5" alt="VU Meter Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: Boom Sticker</strong> (<code>AS_VFX_BoomSticker.1.fx</code>)<br>
      Displays a texture overlay ("sticker") with controls for placement, scale, rotation, and audio reactivity. Perfect for adding overlays that react to music.<br><em>Technique: [AS] Boom Sticker</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/ee8e98b8-198b-4a65-a40d-032eca60dcc5" alt="Boom Sticker Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: Warp Distort</strong> (<code>AS_VFX_WarpDistort.1.fx</code>)<br>
      Creates a circular mirrored or wavy region (often behind a character) that pulses, changes radius, and ripples/warps in sync with audio.</td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/c707583a-99a1-4463-a02f-cdefd2db3e6a" alt="Warp Distort Effect" style="max-width:100%;">
    </div></td>
  </tr>
</table>

<table>
  <tr>
    <th><strong>Core Capabilities</strong></th>
  </tr>
  <tr>
    <td>
      <ul>
        <li><strong>Deep Audio Integration:</strong> Most effects leverage <strong><a href="https://github.com/gposingway/Listeningway">Listeningway</a></strong>, allowing various parameters (intensity, speed, size, color, etc.) to react dynamically to volume, beat, bass, treble, or specific frequency bands.</li>
        <li><strong>Depth-Aware Effects:</strong> Many shaders intelligently interact with scene geometry (using the depth buffer) for natural integration, masking, and occlusion.</li>
        <li><strong>Customization:</strong> Offers extensive controls for colors, intensity, speed, positioning, blend modes, and audio source selection per effect.</li>
      </ul>
    </td>
  </tr>
</table>

---

## Disclaimer

The sample images used in this repository contain characters and stickers from Final Fantasy XIV. These elements are the intellectual property of Square Enix Co., Ltd. and are used here solely for demonstration purposes. All Final Fantasy XIV content is © SQUARE ENIX CO., LTD. All Rights Reserved.

This shader collection is a fan-made project and is not affiliated with, endorsed by, or supported by Square Enix.