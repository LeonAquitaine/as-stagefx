# AS-StageFX Shader Gallery - Visual Effects Package

This gallery provides detailed descriptions and visual examples of the visual effects included in the **AS_StageFX_VisualEffects** package. For installation instructions and general information, please refer to the [main README](../README.md).

> **Note:** This package requires the [AS_StageFX_Essentials](./gallery.md) package to be installed.

> **Looking for other packages?**
> - [Essentials Gallery](./gallery.md) - Core library files and essential effects
> - [Backgrounds Gallery](./gallery-backgrounds.md) - Complete collection of background effects

---

## Lighting Effects (LFX)

<table>
<tr>
<td width="50%">
<h4>LFX: Candle Flame</h4>
<h5><code>[AS] LFX: Candle Flame|AS_LFX_CandleFlame.1.fx</code></h5>
Generates animated procedural candle flames with realistic shape and color gradients, rendered at a specific depth plane. Features procedural shape/color gradient (customizable palette), depth-plane rendering, extensive control over shape, color, animation speed, sway, flicker, audio reactivity (intensity/movement), and resolution-independent rendering. Supports multiple instances.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/e4ad780c-dd65-4684-b052-20acf4626ac3" alt="Candle Flame Effect" style="max-width:100%;">
</div></td>
</tr>
</table>

---

## Visual Effects (VFX)

<table>
<tr>
<td width="50%">
<h4>VFX: Clair Obscur</h4>
<h5><code>[AS] VFX: Clair Obscur|AS_VFX_ClairObscur.1.fx</code></h5>
Creates a beautiful cascade of floating petals with realistic movement and organic animation. This effect simulates petals drifting through the air with natural rotation variation and elegant entrance/exit effects.<br/><br/>
Petal Textures:  

<a href="https://www.freepik.com/free-vector/realistic-rose-petals-isolated_13304910.htm#fromView=search&page=1&position=0&uuid=c7ea13ec-fc26-4e55-9fb3-475ac469e557&query=Rose+Petal+Texture?sign-up=google">Realistic rose petals isolated by user15245033 on Freepik</a><br/>
<a href="https://www.freepik.com/free-vector/pink-flower-petal-illustration-vector-set_16359014.htm#fromView=search&page=1&position=14&uuid=e443ac80-13a3-47b5-8a9e-55131e185fd7&query=sakura+petals+isolated">Pink flower petal illustration vector set by rawpixel.com on Freepik</a>
<a href="https://www.freepik.com/free-psd/nine-colorful-rose-petals-collection-vibrant-display-detached-rose-petals-various-colors-showcasing-their-delicate-textures-unique-shapes_409092672.htm#fromView=search&page=2&position=5&uuid=b59b1768-c8b2-4db8-92d0-670f89edcd8a&query=white+rose+petals+isolated">Nine Colorful Rose Petals Collection by tohamina on Freepik</a>
</td>
<td width="50%"><div style="text-align:center">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Digital Artifacts</h4>
<h5><code>[AS] VFX: Digital Artifacts|AS_VFX_DigitalArtifacts.1.fx</code></h5>
Creates stylized digital artifacts, glitch effects, and hologram visuals positionable in 3D space. Features multiple effect types (hologram, blocks, scanlines, RGB shifts, noise), audio-reactive intensity, depth-controlled positioning, customizable colors/timing, and blend modes.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/6786cb0a-f2c7-4d82-8584-1c669c7513ea" alt="Digital Artifacts Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Dust Motes</h4>
<h5><code>[AS] VFX: Dust Motes|AS_VFX_DustMotes.1.fx</code></h5>
Simulates static, sharp-bordered dust motes using two independent particle layers. A blur effect is applied to the final image in areas covered by particles. Supports depth masking, rotation, audio reactivity and standard AS blending modes.
</td>
<td width="50%"><div style="text-align:center">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Rainy Window</h4>
<h5><code>[AS] VFX: Rainy Window|AS_VFX_RainyWindow.1.fx</code></h5>
Simulates an immersive rainy window with animated water droplets, realistic trails, and frost. Features dynamic raindrop movement, customizable blur/frost, audio-reactive storm intensity, optional lightning flashes, and resolution independence.<br><br>
Inspired by: <a href="https://www.shadertoy.com/view/ltffzl" target="_new">"Heartfelt" by Martijn Steinrucken (BigWings)</a>.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/94601169-e214-4a45-8879-444b64c65d33" alt="Rainy Window Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Radiant Fire</h4>
<h5><code>[AS] VFX: Radiant Fire|AS_VFX_RadiantFire.1.fx</code></h5>
A GPU-based fire simulation that generates flames radiating from subject edges. Rotation now affects the direction of internal physics forces.
</td>
<td width="50%"><div style="text-align:center">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Screen Ring</h4>
<h5><code>[AS] VFX: Screen Ring|AS_VFX_ScreenRing.1.fx</code></h5>
Draws a textured ring or band in screen space at a specified position and depth, occluded by closer scene geometry. Features customizable radius, thickness, texture mapping with rotation, depth occlusion, blend modes, and debug visualization.
</td>
<td width="50%"><div style="text-align:center">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Spectrum Ring</h4>
<h5><code>[AS] VFX: Spectrum Ring|AS_VFX_SpectrumRing.1.fx</code></h5>
Creates a stylized, audio-reactive circular frequency spectrum visualizer mapping all Listeningway audio bands to a ring. Features a blue-to-yellow color gradient by intensity, selectable repetitions (2-16), linear or mirrored patterns, and smooth centered animation.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/e193b002-d3aa-4d86-8584-7eb667f6ff6c" alt="Spectrum Ring Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Tilted Grid</h4>
<h5><code>[AS] VFX: Tilted Grid|AS_VFX_TiltedGrid.1.fx</code></h5>
Creates a rotatable grid that pixelates the image and adds adjustable borders between grid cells. Corner chamfers are overlaid independently. Each cell captures the color from its center position. Features adjustable grid size, customizable border color/thickness, customizable corner chamfer size, rotation controls, depth masking, audio reactivity, and resolution-independent rendering.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/2e1a68d0-7ba8-4ea3-a572-9108c5030b44" alt="Tilted Grid Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: VU Meter</h4>
<h5><code>[AS] VU Meter|AS_VFX_VUMeter.1.fx</code></h5>
Creates an audio-reactive VU meter visualization with multiple display styles (vertical/horizontal bars, line, dots, classic VU). Features customizable appearance with various palettes, adjustable bar width/spacing/roundness, zoom/pan controls, and audio sensitivity settings.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/1b83d29c-a838-492e-82c8-4c503a6867a5" alt="VU Meter Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Warp Distort</h4>
<h5><code>[AS] VFX: Warp Distort|AS_VFX_WarpDistort.1.fx</code></h5>
This shader creates a customizable mirrored or wavy warp effect that pulses and distorts in sync with audio. The effect's position and depth are adjustable using standardized controls. Features include options for a truly circular or resolution-relative warp shape, audio-reactive pulsing for radius and wave/ripple effects, user-selectable audio sources, and adjustable mirror strength, wave frequency, and edge softness. Position and depth are controlled via standardized UI elements.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/c707583a-99a1-4463-a02f-cdefd2db3e6a" alt="Warp Distort Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Water Surface</h4>
<h5><code>[AS] VFX: Water Surface|AS_VFX_WaterSurface.1.fx</code></h5>
Creates a water surface where reflection start points are determined by object depth—distant objects reflect at the horizon, closer ones lower. Features a configurable water level, animated waves with perspective scaling, adjustable reflection parameters (including vertical compression), and customizable water color/transparency. Ideal for scenes with water, pools, or reflective floors.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/c2a21149-3914-4133-9834-12a3c02b9e29" alt="Water Surface Effect" style="max-width:100%;">
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

Visual effects can be layered strategically for the best results:

1. Apply visual effects in a meaningful order (e.g., water surface before rain)
2. Adjust depth settings to position effects at appropriate distances
3. Use blend modes strategically to achieve the desired layering

### Combining Visual Effects

For professional-looking results:

1. Don't overuse effects - pick 2-3 that complement each other
2. Consider thematic consistency (e.g., water + rain + reflections)
3. Pay attention to depth settings to create a sense of space

---

*For more detailed information about installation, updates, and credits, please refer to the [main README](../README.md).*
