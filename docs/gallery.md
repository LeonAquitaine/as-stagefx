# AS-StageFX Shader Gallery - Essentials Package

This gallery provides detailed descriptions and visual examples of the shaders included in the **AS_StageFX_Essentials** package. For installation instructions and general information, please refer to the [main README](../README.md).

> **Looking for other packages?**
> - [Backgrounds Gallery](./gallery-backgrounds.md) - Complete collection of background effects
> - [Visual Effects Gallery](./gallery-visualeffects.md) - Complete collection of visual effects

## Core Library Files (.fxh)

The Essentials package includes these foundation libraries used by all shaders:

- **AS_Utils.1.fxh** - Core utility functions, constants, and common code
- **AS_Noise.1.fxh** - Noise generation functions (Perlin, Simplex, FBM, etc.)
- **AS_Palette.1.fxh** - Color palette and gradient system
- **AS_Palette_Styles.1.fxh** - Preset color palettes and styles

---

## Lighting Effects (LFX)

<table>
  <tr>
    <td width="50%"><strong>LFX: Laser Show</strong> (<code>AS_LFX_LaserShow.1.fx</code>)<br>
      Renders multiple colored laser beams emanating from a user-defined origin, illuminating a swirling, animated smoke field. Features up to 8 configurable beams, procedural FBM Simplex noise smoke with domain warping, audio-reactive fanning and blinking, depth-based occlusion, and user-tunable blending. Highly configurable.<br><em>Technique: [AS] Laser Show</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/555b32cd-be6f-47c2-92a6-39994e861637" alt="Laser Show Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>LFX: Stage Spotlights</strong> (<code>AS_LFX_StageSpotlights.1.fx</code>)<br>
      Simulates a vibrant rock concert stage lighting system with up to 4 independently controllable directional spotlights, glow effects, and audio reactivity. Features customizable position, size, color, angle, direction, audio-reactive intensity, automated sway, pulsing, bokeh glow, depth-masking, and multiple blend modes. Ideal for dramatic lighting.<br><em>Technique: [AS] Stage Spotlights</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/73e1081b-147e-4355-b867-d4964238245b" alt="Spotlights Effect" style="max-width:100%;">
    </div></td>
  </tr>
</table>

---

## Visual Effects (VFX)

<table>
  <tr>
    <td width="50%"><strong>VFX: Boom Sticker</strong> (<code>AS_VFX_BoomSticker.1.fx</code>)<br>
      Displays a texture overlay ("sticker") with controls for placement, scale, rotation, and audio reactivity. Features customizable depth masking and support for custom textures. Ideal for adding dynamic, music-responsive overlays.<br><em>Technique: [AS] Boom Sticker</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/ee8e98b8-198b-4a65-a40d-032eca60dcc5" alt="Boom Sticker Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: Motion Trails</strong> (<code>AS_VFX_MotionTrails.1.fx</code>)<br>
      Creates striking, persistent motion trails ideal for music videos. Objects within a depth threshold leave fading colored trails. Features multiple capture modes (tempo, frame, audio beat, manual), customizable trail color/strength/persistence, audio reactivity, blend modes, and optional subject highlight modes.<br><em>Technique: [AS] Motion Trails</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/1b7a2750-89be-424b-b149-4d850692d9f8" alt="Motion Trails Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: Sparkle Bloom</strong> (<code>AS_VFX_SparkleBloom.1.fx</code>)<br>
      Creates a realistic glitter/sparkle effect that dynamically responds to scene lighting, depth, and camera movement. Simulates tiny reflective particles with multi-layered Voronoi noise, customizable lifetime, depth masking, high-quality bloom, fresnel effect, blend modes, color options, and audio-reactive intensity/animation.<br><em>Technique: [AS] VFX: Sparkle Bloom</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/a0998834-4795-414e-a685-9c7ab685a515" alt="Sparkle Bloom Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: Stencil Mask</strong> (<code>AS_VFX_StencilMask.1.fx</code>)<br>
      Isolates foreground subjects based on depth and applies customizable borders and projected shadows around them. Includes options for various border styles, shadow appearance, and audio reactivity for dynamic effects.<br><em>Technique: [AS] VFX: Stencil Mask</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/98097147-0a9e-40ac-ae21-0b19e5241c91" alt="Stencil Mask Effect" style="max-width:100%;">
    </div></td>
  </tr>
</table>

---

## Background Effects (BGX)

<table>
  <tr>
    <td width="50%"><strong>BGX: Light Ripples</strong> (<code>AS_BGX_LightRipples.1.fx</code>)<br>
      Creates a mesmerizing, rippling kaleidoscopic light pattern effect. Suitable as a dynamic background or overlay. Includes controls for animation, distortion (amplitude, frequencies), color palettes with cycling, audio reactivity, depth-aware rendering, adjustable rotation, and standard blending options. Original shader by Danilo Guanabara ([Pouet](https://www.pouet.net/prod.php?which=57245)).<br><em>Technique: [AS] BGX: Light Ripples</em></td>
    <td width="50%"><div style="text-align:center">
      <!-- Placeholder for future image -->
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>BGX: Stained Lights</strong> (<code>AS_BGX_StainedLights.1.fx</code>)<br>
      Creates dynamic and colorful patterns reminiscent of stained glass illuminated by shifting light, with multiple blurred layers enhancing depth and visual complexity. Generates layers of distorted, cell-like structures with vibrant, evolving colors and subtle edge highlighting, overlaid with softer, floating elements. Features multi-layered pattern generation (adjustable iterations), dynamic animation with speed control, customizable pattern scaling/edge highlighting, audio reactivity for animation/pattern evolution, post-processing (curve adjustments, noise), blurred floating layers for depth, and depth-aware rendering with standard blending. Inspired by "Stained Lights" by 104 ([ShaderToy](https://www.shadertoy.com/view/WlsSzM)). Suitable for abstract backgrounds, energy fields, or mystical visuals.<br><em>Technique: [AS] BGX: Stained Lights</em></td>
    <td width="50%"><div style="text-align:center">
      <!-- Placeholder for future image -->
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>BGX: Time Crystal</strong> (<code>AS_BGX_TimeCrystal.1.fx</code>)<br>
      Creates a hypnotic, crystalline fractal structure with dynamic animation and color cycling. Generates patterns reminiscent of crystalline structures or gems with depth and dimension. Features fractal crystal-like patterns (customizable iterations), dynamic animation (controllable speed), adjustable pattern density/detail, customizable color palettes with cycling, audio reactivity for pattern dynamics/colors, depth-aware rendering with standard blending, and adjustable position/rotation controls. Suitable for mystic or sci-fi backgrounds, portals, or energy fields.<br><em>Technique: [AS] BGX: Time Crystal</em></td>
    <td width="50%"><div style="text-align:center">
      <!-- Placeholder for future image -->
    </div></td>
  </tr>
</table>

---

## Graphic Effects (GFX)

<table>
  <tr>
    <td width="50%"><strong>GFX: Multi-Layer Halftone</strong> (<code>AS_GFX_MultiLayerHalftone.1.fx</code>)<br>
      Creates a highly customizable multi-layer halftone effect with support for up to four independent layers. Each layer can use different pattern types (dots, lines, crosshatch), isolation methods (brightness, RGB, hue, depth), colors, thresholds, scales, densities, and angles. Features layer blending with transparency support. Based on "Halftone Shader" by P. Gonzalez Vivo ([ShaderToy](https://www.shadertoy.com/view/XdcGzn)).<br><em>Technique: [AS] Multi-Layer Halftone</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/b93c9d03-5d23-4b32-aa3e-f2b6a9736c70" alt="Multi-Layer Halftone Effect" style="max-width:100%;">
    </div></td>
  </tr>
</table>

---

## Usage Tips

### Audio Reactivity

Most shaders in the AS-StageFX collection include audio reactivity options. Here are some tips for getting the most out of these features:

1. **Listeningway Integration:** Install [Listeningway](https://github.com/gposingway/Listeningway) for full audio responsiveness. Without it, shaders will still work but won't react to sound.

2. **Audio Source Selection:** Each shader with audio reactivity includes an "Audio Source" dropdown. Choose the appropriate source for your needs:
   - **Bass**: Good for rhythmic pulsing effects
   - **Mids**: Works well for vocals and most instruments
   - **Treble**: Better for high-frequency response (cymbals, etc.)
   - **Volume**: Overall audio volume (good for general reactivity)
   - **Custom**: Allows using a specific frequency band

3. **Adjusting Sensitivity:** Use the "Audio Reactivity" slider to control how strongly the effect responds to audio. Higher values create more dramatic effects.

### Performance Considerations

Some effects can be more demanding than others. If you experience performance issues:

1. Start with fewer shaders active at once
2. Reduce resolution scale settings in more complex shaders
3. Avoid using multiple distortion-based effects simultaneously

### Combining Shaders

For the best visual results when combining multiple shaders:

1. Apply background effects (BGX) first
2. Add lighting effects (LFX) next
3. Apply visual effects (VFX) last for final touches
4. Pay attention to blend modes in each shader to control how they interact

---

*For more detailed information about installation, updates, and credits, please refer to the [main README](../README.md).*