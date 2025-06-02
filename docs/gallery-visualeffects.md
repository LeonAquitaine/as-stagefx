# AS-StageFX Shader Gallery - Visual Effects Package

This gallery provides detailed descriptions and visual examples of the **23 effects** (3 Lighting + 20 Visual) included in the **AS_StageFX_VisualEffects** package. These effects range from lighting simulation and audio visualization to particle systems and post-processing tools.

For installation instructions and general information, please refer to the [main README](../README.md).

> **Note:** This package requires the [AS_StageFX_Essentials](./gallery.md) package to be installed.

> **Looking for other packages?**
> - [Essentials Gallery](./gallery.md) - Core library files and essential effects
> - [Backgrounds Gallery](./gallery-backgrounds.md) - Complete collection of background effects

---

## Lighting Effects (LFX)

<table>
<tr>
<td width="50%">
<h4>LFX: Candle Flame ✨</h4>
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
<h4>VFX: Focused Chaos 🔥</h4>
<h5><code>[AS] VFX: Focused Chaos|AS_VFX_FocusedChaos.1.fx</code></h5>
Creates a visually complex and dynamic abstract effect resembling a focused point of chaotic energy or a swirling cosmic vortex. Features dynamic, animated vortex pattern using 3D Simplex Noise and FBM, transparent background blending with the game scene, customizable animation speed and keyframing, extensive artistic controls for swirl, noise, color, and alpha falloff, dithering option to reduce color banding artifacts, and subtle domain warping to improve noise pattern quality.<br><br>
Original: <a href="https://www.shadertoy.com/view/lcfyDj" target="_new">"BlackHole (swirl, portal)" by misterprada</a> with additional inspiration from <a href="https://x.com/cmzw_/status/1787147460772864188" target="_new">celestianmaze's work</a>.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-image"/>
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Circular Spectrum ⚡</h4>
<h5><code>[AS] VFX: Circular Spectrum|AS_VFX_CircularSpectrum.1.fx</code></h5>
Creates a circular audio spectrum visualizer with dots of light radiating from the center. The number and color of dots react to audio frequency bands, creating a dynamic visual representation of music. Features customizable palette support (including custom palettes), mirrored or linear frequency mapping, adjustable dot size and spacing, bloom effects, audio sensitivity controls, and depth masking for 3D positioning.<br><br>
Inspired by: <a href="https://www.shadertoy.com/view/tcyGW1" target="_new">"Circular audio visualizer" by AIandDesign</a>.
</td>
<td width="50%"><div style="text-align:center">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Color Balancer ✨</h4>
<h5><code>[AS] VFX: Color Balancer|AS_VFX_ColorBalancer.1.fx</code></h5>
Enables colorists and videographers to apply classic cinematic color harmony models (complementary, analogous, triadic, split-complementary, tetradic) to live visuals or video production. It offers flexible color manipulation across shadows, midtones, and highlights, allowing for sophisticated color grading that maintains natural-looking skin tones while dramatically enhancing the overall visual impact.
</td>
<td width="50%"><div style="text-align:center">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Clair Obscur ⚡</h4>
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
<h4>VFX: Digital Artifacts ✨</h4>
<h5><code>[AS] VFX: Digital Artifacts|AS_VFX_DigitalArtifacts.1.fx</code></h5>
Creates stylized digital artifacts, glitch effects, and hologram visuals positionable in 3D space. Features multiple effect types (hologram, blocks, scanlines, RGB shifts, noise), audio-reactive intensity, depth-controlled positioning, customizable colors/timing, and blend modes.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/6786cb0a-f2c7-4d82-8584-1c669c7513ea" alt="Digital Artifacts Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Dust Motes ⚡</h4>
<h5><code>[AS] VFX: Dust Motes|AS_VFX_DustMotes.1.fx</code></h5>
Simulates static, sharp-bordered dust motes using two independent particle layers. A blur effect is applied to the final image in areas covered by particles. Supports depth masking, rotation, audio reactivity and standard AS blending modes.
</td>
<td width="50%"><div style="text-align:center">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Motion Focus ⚡</h4>
<h5><code>[AS] VFX: Motion Focus|AS_VFX_MotionFocus.1.fx</code></h5>
Analyzes inter-frame motion differences to dynamically adjust the viewport, zooming towards and centering on areas of detected movement. Features multi-pass motion analysis with temporal smoothing, adaptive decay for responsive adjustments, quadrant-based motion aggregation, motion-weighted zoom center calculation, generous zoom limits for dramatic effects, and edge correction to prevent sampling outside screen bounds.<br><br>
Based on: "MotionFocus.fx" originally made by <strong>Ganossa</strong> and ported by <strong>IDDQD</strong>.
</td>
<td width="50%"><div style="text-align:center">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Rainy Window ⚡</h4>
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
<h4>VFX: Radial Lens Distortion ✨</h4>
<h5><code>[AS] VFX: Radial Lens Distortion|AS_VFX_RadialLensDistortion.1.fx</code></h5>
Emulates various lens distortions including tangential (rotational) blur, chromatic aberration (tangential or horizontal), and geometric barrel/pincushion distortion. Effects are strongest at the edges and diminish towards a configurable center point. Features internal presets for common lens emulations (vintage soft focus, chromatic edge, dreamy haze, anamorphic cine, Helios vintage, wide-angle), independent blur and chromatic aberration controls, global strength multiplier, effect focus exponent for falloff control, variable sample count for quality/performance tuning, aspect ratio correction for circular patterns, and consistent alpha handling for effect visibility.
</td>
<td width="50%"><div style="text-align:center">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Radiant Fire ✨</h4>
<h5><code>[AS] VFX: Radiant Fire|AS_VFX_RadiantFire.1.fx</code></h5>
A fire simulation that generates flames radiating from subject edges. Rotation affects the direction of internal physics forces.<br/><br/>
Original: <a href='https://www.shadertoy.com/view/4ttGWM' target='_new'>"301's Fire Shader - Remix 3" by mu6k</a>
</td>
<td width="50%"><div style="text-align:center">
</div>
<img src="https://github.com/user-attachments/assets/e706810d-673e-4e58-b274-8cde25c3f13f"/>
</td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Screen Ring ✨</h4>
<h5><code>[AS] VFX: Screen Ring|AS_VFX_ScreenRing.1.fx</code></h5>
Draws a textured ring or band in screen space at a specified position and depth, occluded by closer scene geometry. Features customizable radius, thickness, texture mapping with rotation, depth occlusion, blend modes, and debug visualization.
</td>
<td width="50%"><div style="text-align:center">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Spectrum Ring ✨</h4>
<h5><code>[AS] VFX: Spectrum Ring|AS_VFX_SpectrumRing.1.fx</code></h5>
Creates a stylized, audio-reactive circular frequency spectrum visualizer mapping all Listeningway audio bands to a ring. Features a blue-to-yellow color gradient by intensity, selectable repetitions (2-16), linear or mirrored patterns, and smooth centered animation.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/e193b002-d3aa-4d86-8584-7eb667f6ff6c" alt="Spectrum Ring Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Tilted Grid ✨</h4>
<h5><code>[AS] VFX: Tilted Grid|AS_VFX_TiltedGrid.1.fx</code></h5>
Creates a rotatable grid that pixelates the image and adds adjustable borders between grid cells. Corner chamfers are overlaid independently. Each cell captures the color from its center position. Features adjustable grid size, customizable border color/thickness, customizable corner chamfer size, rotation controls, depth masking, audio reactivity, and resolution-independent rendering.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/2e1a68d0-7ba8-4ea3-a572-9108c5030b44" alt="Tilted Grid Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: VU Meter ⚡</h4>
<h5><code>[AS] VU Meter|AS_VFX_VUMeter.1.fx</code></h5>
Creates an audio-reactive VU meter visualization with multiple display styles (vertical/horizontal bars, line, dots, classic VU). Features customizable appearance with various palettes, adjustable bar width/spacing/roundness, zoom/pan controls, and audio sensitivity settings.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/1b83d29c-a838-492e-82c8-4c503a6867a5" alt="VU Meter Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Warp Distort ✨</h4>
<h5><code>[AS] VFX: Warp Distort|AS_VFX_WarpDistort.1.fx</code></h5>
This shader creates a customizable mirrored or wavy warp effect that pulses and distorts in sync with audio. The effect's position and depth are adjustable using standardized controls. Features include options for a truly circular or resolution-relative warp shape, audio-reactive pulsing for radius and wave/ripple effects, user-selectable audio sources, and adjustable mirror strength, wave frequency, and edge softness. Position and depth are controlled via standardized UI elements.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/c707583a-99a1-4463-a02f-cdefd2db3e6a" alt="Warp Distort Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Volumetric Light ✨</h4>
<h5><code>[AS] VFX: Volumetric Light|AS_VFX_VolumetricLight.1.fx</code></h5>
Simulates 2D volumetric light shafts (god rays) with depth-based occlusion and customizable colors. Features interactive light source positioning, user-selectable colors via palette system or custom colors, adjustable light brightness and ray properties, audio reactivity for dynamic lighting effects, depth-based occlusion where objects in front of the light source block rays, optional direct lighting on scene elements, and resolution-independent rendering. Perfect for creating atmospheric lighting effects in any scene.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-volumetric-light" alt="Volumetric Light Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Water Surface ✨</h4>
<h5><code>[AS] VFX: Water Surface|AS_VFX_WaterSurface.1.fx</code></h5>
Creates a water surface where reflection start points are determined by object depth—distant objects reflect at the horizon, closer ones lower. Features a configurable water level, animated waves with perspective scaling, adjustable reflection parameters (including vertical compression), and customizable water color/transparency. Ideal for scenes with water, pools, or reflective floors.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/c2a21149-3914-4133-9834-12a3c02b9e29" alt="Water Surface Effect" style="max-width:100%;">
</div></td>
</tr>
</table>

---

*For more detailed information about installation, updates, and credits, please refer to the [main README](../README.md). Complete external source attribution is available in [AS_StageFX_Credits.md](../AS_StageFX_Credits.md).*
