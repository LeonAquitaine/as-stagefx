# AS-StageFX Shader Gallery

This gallery provides detailed descriptions and visual examples of all shaders included in the AS-StageFX collection. For installation instructions and general information, please refer to the [main README](../README.md).

---

## Lighting Effects (LFX)

<table>
  <tr>
    <td width="50%"><strong>LFX: Candle Flame</strong> (<code>AS_LFX_CandleFlame.1.fx</code>)<br>
      Generates animated procedural candle flames with realistic shape and color gradients, rendered at a specific depth plane. Features procedural shape/color gradient (customizable palette), depth-plane rendering, extensive control over shape, color, animation speed, sway, flicker, audio reactivity (intensity/movement), and resolution-independent rendering. Supports multiple instances.<br><em>Technique: [AS] LFX: Candle Flame</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/e4ad780c-dd65-4684-b052-20acf4626ac3" alt="Candle Flame Effect" style="max-width:100%;">
    </div></td>
  </tr>
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
    <td width="50%"><strong>VFX: Broken Glass</strong> (<code>AS_VFX_BrokenGlass.1.fx</code>)<br>
      Simulates a broken glass or mirror effect with customizable crack patterns, distortion, and audio reactivity for dynamic shattering visualization.<br><em>Technique: [AS] VFX: Broken Glass</em></td>
    <td width="50%"><div style="text-align:center">
      <!-- Placeholder for future image -->
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: Digital Artifacts</strong> (<code>AS_VFX_DigitalArtifacts.1.fx</code>)<br>
      Creates stylized digital artifacts, glitch effects, and hologram visuals positionable in 3D space. Features multiple effect types (hologram, blocks, scanlines, RGB shifts, noise), audio-reactive intensity, depth-controlled positioning, customizable colors/timing, and blend modes.</td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/6786cb0a-f2c7-4d82-8584-1c669c7513ea" alt="Digital Artifacts Effect" style="max-width:100%;">
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
    <td width="50%"><strong>VFX: Rainy Window</strong> (<code>AS_VFX_RainyWindow.1.fx</code>)<br>
      Simulates an immersive rainy window with animated water droplets, realistic trails, and frost. Features dynamic raindrop movement, customizable blur/frost, audio-reactive storm intensity, optional lightning flashes, and resolution independence. Inspired by Martijn Steinrucken's "Heartfelt".<br><em>Technique: [AS] VFX: Rainy Window</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/94601169-e214-4a45-8879-444b64c65d33" alt="Rainy Window Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: Screen Ring</strong> (<code>AS_VFX_ScreenRing.1.fx</code>)<br>
      Draws a textured ring or band in screen space at a specified position and depth, occluded by closer scene geometry. Features customizable radius, thickness, texture mapping with rotation, depth occlusion, blend modes, and debug visualization.<br><em>Technique: [AS] VFX: Screen Ring</em></td>
    <td width="50%"><div style="text-align:center">
      <!-- Placeholder for future image -->
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
    <td width="50%"><strong>VFX: Spectrum Ring</strong> (<code>AS_VFX_SpectrumRing.1.fx</code>)<br>
      Creates a stylized, audio-reactive circular frequency spectrum visualizer mapping all Listeningway audio bands to a ring. Features a blue-to-yellow color gradient by intensity, selectable repetitions (2-16), linear or mirrored patterns, and smooth centered animation.<br><em>Technique: [AS] VFX: Spectrum Ring</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/e193b002-d3aa-4d86-8584-7eb667f6ff6c" alt="Spectrum Ring Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: Stencil Mask</strong> (<code>AS_VFX_StencilMask.1.fx</code>)<br>
      Isolates foreground subjects based on depth and applies customizable borders and projected shadows around them. Includes options for various border styles, shadow appearance, and audio reactivity for dynamic effects.<br><em>Technique: [AS] VFX: Stencil Mask</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/98097147-0a9e-40ac-ae21-0b19e5241c91" alt="Stencil Mask Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: Tilted Grid</strong> (<code>AS_VFX_TiltedGrid.1.fx</code>)<br>
      Creates a rotatable grid that pixelates the image and adds adjustable borders between grid cells. Corner chamfers are overlaid independently. Each cell captures the color from its center position. Features adjustable grid size, customizable border color/thickness, customizable corner chamfer size, rotation controls, depth masking, audio reactivity, and resolution-independent rendering.<br><em>Technique: [AS] VFX: Tilted Grid</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/2e1a68d0-7ba8-4ea3-a572-9108c5030b44" alt="Tilted Grid Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: VU Meter</strong> (<code>AS_VFX_VUMeter.1.fx</code>)<br>
      Creates an audio-reactive VU meter visualization with multiple display styles (vertical/horizontal bars, line, dots, classic VU). Features customizable appearance with various palettes, adjustable bar width/spacing/roundness, zoom/pan controls, and audio sensitivity settings.<br><em>Technique: [AS] VU Meter Background</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/1b83d29c-a838-492e-82c8-4c503a6867a5" alt="VU Meter Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: Warp Distort</strong> (<code>AS_VFX_WarpDistort.1.fx</code>)<br>
      This shader creates a customizable mirrored or wavy warp effect that pulses and distorts in sync with audio. The effect's position and depth are adjustable using standardized controls. Features include options for a truly circular or resolution-relative warp shape, audio-reactive pulsing for radius and wave/ripple effects, user-selectable audio sources, and adjustable mirror strength, wave frequency, and edge softness. Position and depth are controlled via standardized UI elements.<br><em>Technique: [AS] VFX: Warp Distort</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/c707583a-99a1-4463-a02f-cdefd2db3e6a" alt="Warp Distort Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>VFX: Water Surface</strong> (<code>AS_VFX_WaterSurface.1.fx</code>)<br>
      Creates a water surface where reflection start points are determined by object depth—distant objects reflect at the horizon, closer ones lower. Features a configurable water level, animated waves with perspective scaling, adjustable reflection parameters (including vertical compression), and customizable water color/transparency. Ideal for scenes with water, pools, or reflective floors.<br><em>Technique: [AS] VFX: Water Surface</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/c2a21149-3914-4133-9834-12a3c02b9e29" alt="Water Surface Effect" style="max-width:100%;">
    </div></td>
  </tr>
</table>

---

## Background Effects (BGX)

<table>
  <tr>
    <td width="50%"><strong>BGX: Cosmic Kaleidoscope</strong> (<code>AS_BGX_CosmicKaleidoscope.1.fx</code>)<br>
      Renders a raymarched volumetric fractal resembling a Mandelbox or Mandelbulb. Features adjustable fractal parameters, kaleidoscope-like mirroring with customizable repetitions, audio reactivity for dynamic adjustments, a palette-based coloring system, and full rotation, position, and depth control for scene integration. Includes fixes for accurate tiling and missing rotation from the original source.<br><em>Technique: [AS] BGX: Cosmic Kaleidoscope</em></td>
    <td width="50%"><div style="text-align:center">
      <!-- Placeholder for future image -->
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>BGX: Fractal Strands</strong> (<code>AS_BGX_FractalStrands.2.fx</code>)<br>
      Generates intricate, evolving fractal patterns that create mesmerizing and complex visual backdrops. Features controls for fractal type, iteration depth, color schemes, animation speed, and audio reactivity.<br><em>Technique: [AS] BGX: Fractal Strands</em></td>
    <td width="50%"><div style="text-align:center">
      <!-- Placeholder for future image -->
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>BGX: Light Ripples</strong> (<code>AS_BGX_LightRipples.1.fx</code>)<br>
      Creates a mesmerizing, rippling kaleidoscopic light pattern effect. Suitable as a dynamic background or overlay. Includes controls for animation, distortion (amplitude, frequencies), color palettes with cycling, audio reactivity, depth-aware rendering, adjustable rotation, and standard blending options.<br><em>Technique: [AS] BGX: Light Ripples</em></td>
    <td width="50%"><div style="text-align:center">
      <!-- Placeholder for future image -->
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>BGX: Light Wall</strong> (<code>AS_BGX_LightWall.1.fx</code>)<br>
      Renders a seamless, soft, overlapping grid of light panels with various built-in patterns (14 total, including Heart, Diamond, Beat Meter). Features audio-reactive panels pulsing to music, customizable color palettes (9 presets + custom), light burst effects, cross beams, 3D perspective controls (tilt, pitch, roll), and multiple blend modes. Perfect for dance club/concert backdrops.<br><em>Technique: [AS] BGX: Light Wall</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/ece86ab7-36f1-459c-8c83-31414c3b5cc3" alt="Light Wall Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>BGX: Melt Wave</strong> (<code>AS_BGX_MeltWave.1.fx</code>)<br>
      Creates a flowing, warping psychedelic effect inspired by 1970s visual aesthetics. Generates mesmerizing colored patterns with sine-based distortions that evolve over time. Features adjustable zoom/intensity, a palette system (mathematical or preset colors), dynamic time-based animation with keyframe support, audio reactivity mappable to different parameters, and resolution-independent transformation with position/rotation controls.<br><em>Technique: [AS] VFX: Melt Wave</em></td>
    <td width="50%"><div style="text-align:center">
      <!-- Placeholder for future image -->
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>BGX: Plasma Flow</strong> (<code>AS_BGX_PlasmaFlow.1.fx</code>)<br>
      Sophisticated, gentle, and flexible plasma effect for groovy, atmospheric visuals. Generates smooth, swirling, organic patterns with customizable color gradients (2-4 user-defined colors) and strong audio reactivity. Features procedural plasma/noise with domain warping for fluid motion, controls for speed, scale, complexity, stretch, and warp, audio-reactive modulation of movement, color, brightness, and turbulence, plus standard blend modes and debug views. Ideal for music video backgrounds and overlays.<br><em>Technique: [AS] BGX: Plasma Flow</em></td>
    <td width="50%"><div style="text-align:center">
      <img src="https://github.com/user-attachments/assets/ba95325d-eff0-439e-a452-567675da84fe" alt="Plasma Flow Effect" style="max-width:100%;">
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>BGX: Shine On</strong> (<code>AS_BGX_ShineOn.1.fx</code>)<br>
      Creates a dynamic, evolving fractal noise pattern with bright, sparkly crystal highlights that move across the screen. Combines multiple layers of noise with procedural animation for a mesmerizing background effect. Features layered noise patterns with dynamic animation, crystal point highlights with customizable parameters, audio reactivity, and depth-aware rendering.<br><em>Technique: [AS] BGX: Shine On</em></td>
    <td width="50%"><div style="text-align:center">
      <!-- Placeholder for future image -->
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>BGX: Stained Lights</strong> (<code>AS_BGX_StainedLights.1.fx</code>)<br>
      Creates dynamic and colorful patterns reminiscent of stained glass illuminated by shifting light, with multiple blurred layers enhancing depth and visual complexity. Generates layers of distorted, cell-like structures with vibrant, evolving colors and subtle edge highlighting, overlaid with softer, floating elements. Features multi-layered pattern generation (adjustable iterations), dynamic animation with speed control, customizable pattern scaling/edge highlighting, audio reactivity for animation/pattern evolution, post-processing (curve adjustments, noise), blurred floating layers for depth, and depth-aware rendering with standard blending. Suitable for abstract backgrounds, energy fields, or mystical visuals.<br><em>Technique: [AS] BGX: Stained Lights</em></td>
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
  <tr>
    <td width="50%"><strong>BGX: Wavy Squares</strong> (<code>AS_BGX_WavySquares.1.fx</code>)<br>
      Creates a hypnotic pattern of wavy, animated square tiles that shift and transform. The squares follow a wave-like motion and feature dynamic size changes, creating a flowing, organic grid pattern. Features wavy, undulating square tiling; customizable wave parameters (amplitude, frequency, speed); variable tile size/scaling; shape smoothness/box roundness controls; audio reactivity (multiple targets); depth-aware rendering; adjustable rotation; and standard position, scale, and blending options.<br><em>Technique: [AS] BGX: Wavy Squares</em></td>
    <td width="50%"><div style="text-align:center">
      <!-- Placeholder for future image -->
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>BGX: Wavy Squiggles</strong> (<code>AS_BGX_WavySquiggles.1.fx</code>)<br>
      Creates a mesmerizing pattern of adaptive wavy lines that follow a mouse or fixed position. The lines create intricate patterns that look like dynamic squiggly lines arranged around a central point, with rotation applied based on direction. Features position-reactive wavy line patterns; customizable line parameters (rotation influence, thickness, distance, smoothness); optional color palettes (hue, saturation, value control); pattern displacement for off-center effects; audio reactivity (multiple targets); depth-aware rendering; adjustable rotation; and standard position, scale, and blending options.<br><em>Technique: [AS] BGX: Wavy Squiggles</em></td>
    <td width="50%"><div style="text-align:center">
      <!-- Placeholder for future image -->
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>BGX: Blue Corona</strong> (<code>AS_BGX_BlueCorona.1.fx</code>)<br>
      Creates a vibrant, abstract blue corona effect with fluid, dynamic motion. The effect generates hypnotic patterns through iterative mathematical transformations, resulting in organic, plasma-like visuals with a predominantly blue color scheme. Features abstract, organic blue corona patterns; smooth fluid-like animation; customizable iteration count/pattern scale; animation speed/flow controls; intuitive color controls; customizable background color; audio reactivity (multiple targets); depth-aware rendering; and standard position, rotation, scale, and blending options.<br><em>Technique: [AS] BGX: Blue Corona</em></td>
    <td width="50%"><div style="text-align:center">
      <!-- Placeholder for future image -->
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>BGX: Zippy Zaps</strong> (<code>AS_BGX_ZippyZaps.1.fx</code>)<br>
      Creates dynamic electric arcs and lightning patterns for a striking background effect. This effect generates procedural electric-like patterns that appear behind objects in the scene, creating an energetic, dynamic background with complete control over appearance and animation. Features animated electric/lightning arcs with procedural generation; fully customizable colors, intensity, and animation parameters; resolution-independent rendering; audio reactivity; depth-aware rendering; and adjustable rotation/positioning in 3D space.<br><em>Technique: [AS] BGX: Zippy Zaps</em></td>
    <td width="50%"><div style="text-align:center">
      <!-- Placeholder for future image -->
    </div></td>
  </tr>
  <tr>
    <td width="50%"><strong>BGX: Golden Clockwork</strong> (<code>AS_BGX_GoldenClockwork.1.fx</code>)<br>
      Renders a mesmerizing and intricate animated background effect reminiscent of golden clockwork mechanisms or Apollonian gasket-like fractal patterns. The effect features complex, evolving geometric designs with a characteristic golden color palette. Features procedurally generated Apollonian fractal patterns, dynamic animation driven by time, a golden color scheme with lighting and shading effects, depth-like progression through fractal layers, kaleidoscopic and mirroring options for pattern variation, resolution-independent rendering, and UI controls for animation (speed, keyframe, path speed), palette, fractal/kaleidoscope parameters, audio reactivity, stage controls (position, scale, rotation, depth), and blending.<br><em>Technique: [AS] BGX: Golden Clockwork</em></td>
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
      Creates a highly customizable multi-layer halftone effect with support for up to four independent layers. Each layer can use different pattern types (dots, lines, crosshatch), isolation methods (brightness, RGB, hue, depth), colors, thresholds, scales, densities, and angles. Features layer blending with transparency support.<br><em>Technique: [AS] Multi-Layer Halftone</em></td>
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