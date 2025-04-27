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
    <th colspan="2"><strong>Stage Lighting & Ambiance (RS)</strong></th>
  </tr>
  <tr>
    <td width="50%"><strong>RS: Light Wall</strong> (<code>AS_RS-LightWall.1.fx</code>)<br>
      Generate configurable grids of light panels with diverse patterns, 3D perspective, audio reactivity, and customizable color palettes. Perfect for backdrops.</td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/ece86ab7-36f1-459c-8c83-31414c3b5cc3" alt="Light Wall Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>RS: Spotlights</strong> (<code>AS_RS-Spotlights.1.fx</code>)<br>
      Add up to 3 customizable directional stage lights with realistic beam/glow effects, depth masking, and audio-reactive intensity and movement.<br><em>Technique: [AS] Rock Stage: Spotlights</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/73e1081b-147e-4355-b867-d4964238245b" alt="Spotlights Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <th colspan="2"><strong>Cinematic Effects (CN)</strong></th>
  </tr>
  <tr>
    <td width="50%"><strong>CN: Digital Glitch</strong> (<code>AS_CN-DigitalGlitch.1.fx</code>)<br>
      Applies audio-driven digital artifacts, glitches and hologram effects, including scanlines, RGB split, jitter, and pulsing synced to music.</td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/6786cb0a-f2c7-4d82-8584-1c669c7513ea" alt="Digital Glitch Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>CN: Glitter</strong> (<code>AS_CN-Glitter.1.fx</code>)<br>
      Creates a realistic, dynamic sparkle effect on surfaces that responds to scene lighting, depth, camera movement, and audio. Includes bloom and fresnel effects.</td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/a0998834-4795-414e-a685-9c7ab685a515" alt="Glitter Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>CN: Motion Trails</strong> (<code>AS_CN-MotionTrails.1.fx</code>)<br>
      Creates music-reactive, depth-based motion trails for dramatic visual effects in videos and screenshots.<br><em>Technique: [AS] Cinematic: Motion Trails</em></td>
    <td width="50%"><div style="text-align:center"><img src="https://github.com/user-attachments/assets/PLACEHOLDER-MOTIONTRAILS.gif" alt="Motion Trails Effect" style="max-width:100%;"></div></td>
  </tr>
  <tr>
    <td width="50%"><strong>CN: Plasma Flow</strong> (<code>AS_CN-PlasmaFlow.1.fx</code>)<br>
      Generates smooth, swirling, organic plasma-like patterns reminiscent of a lava lamp but more fluid and customizable, ideal for atmospheric visuals in music videos.</td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/ba95325d-eff0-439e-a452-567675da84fe" alt="Plasma Flow Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>CN: Spectrum Ring</strong> (<code>AS_CN-SpectrumRing.1.fx</code>)<br>
      Generates a stylized, circular audio visualizer that displays all Listeningway frequency bands, with repetitions and mirroring options.</td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/e193b002-d3aa-4d86-8584-7eb667f6ff6c" alt="Spectrum Ring Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>CN: Stencil Mask</strong> (<code>AS_CN-StencilMask.1.fx</code>)<br>
      Isolates foreground subjects based on depth and applies customizable borders and projected shadows, with options for border styles and audio reactivity.</td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/98097147-0a9e-40ac-ae21-0b19e5241c91" alt="Stencil Mask Effect" style="max-width:100%;">
  </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>CN: Warp</strong> (<code>AS_CN-Warp.1.fx</code>)<br>
      Creates a circular mirrored or wavy region (often behind a character) that pulses, changes radius, and ripples/warps in sync with audio.</td>
    <td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/c707583a-99a1-4463-a02f-cdefd2db3e6a" alt="Warp Effect" style="max-width:100%;">
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
        <li><strong>Shared Utilities:</strong> Uses a common backend (<code>AS_Utils.1.fxh</code>) for blend modes, audio processing, color palettes, and timing, ensuring consistency.</li>
      </ul>
    </td>
  </tr>
</table>

---

## Usage Guide

Below are details on each effect shader included in AS-StageFX:

### CN: Glitter Effect (`AS_CN-Glitter.1.fx`)

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

### CN: Digital Glitch Effect (`AS_CN-DigitalGlitch.1.fx`)

Applies audio-driven digital artifacts, glitches, and hologram effects.

* **Description:** Creates digital artifacts, glitches, and holographic visuals with scanlines, RGB color splitting, and jitter effects that pulse and react to music via Listeningway.
* **Key Features:**
    * Multiple effect types (hologram, RGB shift, block corruption, scanlines, noise & static)
    * Audio-reactive scanlines, RGB split intensity, and digital glitch frequency/strength.
    * Pulsing, jitter, and color offsets driven by selectable audio sources (volume, beat, bass, treble, etc.).
    * Adjustable base intensity, speed, and randomness for each effect component.
    * Depth-controlled positioning for precise placement in 3D space.
    * Debug visualizations for mask and audio input.

### CN: Plasma Flow (`AS_CN-PlasmaFlow.1.fx`)

Generates smooth, flowing plasma-like patterns for atmospheric visuals.

* **Description:** Creates a sophisticated, gentle, and flexible plasma-like effect with smooth, swirling, organic patterns reminiscent of a lava lamp but more fluid and customizable.
* **Key Features:**
    * Procedural plasma/noise effect with smooth, flowing motion using domain warping.
    * User-customizable colors with support for up to 4 base colors for rich gradients.
    * Adjustable movement controls for speed, scale/zoom, and complexity/turbulence.
    * Pattern shape parameters to influence the plasma form (e.g., 'Warp Intensity').
    * Audio reactivity via Listeningway for dynamic modulation of movement, color, and complexity.
    * Multiple blend modes for seamless scene integration.

### CN: Spectrum Ring Visualizer (`AS_CN-SpectrumRing.1.fx`)

Generates a circular audio spectrum visualizer.

* **Description:** Creates a circular, centered ring pattern that visualizes intensity across all available Listeningway audio bands simultaneously.
* **Key Features:**
    * Uses all Listeningway audio bands for a detailed spectrum visualization.
    * Customizable color gradient based on audio intensity.
    * User-selectable number of repetitions (segments) for the visualization.
    * Multiple pattern style options (linear or mirrored repetition).
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

### CN: Stencil Mask (`AS_CN-StencilMask.1.fx`)

Creates a stencil mask effect with customizable borders and projected shadows.

* **Description:** Isolates foreground subjects based on depth and applies customizable borders and projected shadows around them.
* **Key Features:**
    * Depth-based subject isolation.
    * Multiple border styles (Solid, Glow, Pulse, Dash, Double Line).
    * Customizable border color, opacity, thickness, and smoothing.
    * Optional projected shadow with customizable color, opacity, and offset.
    * Audio reactivity via Listeningway for border thickness, pulse, and shadow movement.
    * Debug modes for visualizing masks.

### CN: Warp Effect (`AS_CN-Warp.1.fx`)

Creates an audio-reactive circular mirror or wave effect.

* **Description:** Generates a circular or elliptical region (often centered behind a character) that mirrors or distorts the scene within it, pulsing and warping in sync with music.
* **Key Features:**
    * Circular or elliptical region with adjustable edge softness.
    * Audio-reactive pulsing effect, radius changes, and wave/ripple intensity via Listeningway.
    * User-selectable audio source (volume, beat, bass, treble, etc.) to drive effects.
    * Adjustable base mirror strength, wave frequency/amplitude, and edge softness.
    * Debug visualizations for viewing the effect mask and audio input.

### CN: Motion Trails (`AS_CN-MotionTrails.1.fx`)

Creates music-reactive, depth-based motion trails for dramatic visual effects.

*Technique name in ReShade: `[AS] Cinematic: Motion Trails`*

* **Description:**
    * Objects within a specified depth threshold leave behind colored trails that slowly fade, creating dynamic visual paths ideal for music videos, dramatic footage, and cinematic compositions.
* **Key Features:**
    * Depth-based subject tracking for dynamic trail effects
    * User-definable trail color, strength, and persistence
    * Audio-reactive trail timing, intensity, and colors through Listeningway
    * Multiple blend modes for scene integration
    * Optional real-time subject highlight for better visualization
    * Several timing modes: tempo-based, frame-based, on audio beat, or manual
    * Precise depth control for targeting specific scene elements
