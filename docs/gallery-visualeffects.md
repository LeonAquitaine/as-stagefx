# AS-StageFX Shader Gallery - Visual Effects Package

This gallery provides detailed descriptions and visual examples of the **visual effects** (3 Lighting + 21 Visual) included in the **AS_StageFX_VisualEffects** package. These effects range from lighting simulation and audio visualization to particle systems and post-processing tools.

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
<h3>Candle Flame </h3>
<h5><code>AS_LFX_CandleFlame.1.fx</code></h5>
Renders a realistic animated candle flame with natural flicker and glow. Features customizable flame shape, color, flicker speed, and intensity. Includes controls for flame position, scale, and blending. Ideal for atmospheric lighting and cozy scene effects.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-Candle.gif" alt="Candle Flame Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Laser Show </h3>
<h5><code>AS_LFX_LaserShow.1.fx</code></h5>
Projects animated laser beams and geometric patterns onto the stage. Features customizable beam count, color, speed, and spread. Supports audio reactivity for beam movement and intensity. Includes controls for rotation, position, and blending. Perfect for concert, club, or sci-fi lighting effects.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-lasershow.gif" alt="Laser Show Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Stage Spotlights </h3>
<h5><code>AS_LFX_StageSpotlights.1.fx</code></h5>
Simulates moving stage spotlights with adjustable beam width, color, intensity, and movement patterns. Features multiple spotlights with independent controls, audio reactivity for movement and brightness, and blending options for integration with other effects. Ideal for live performance and dramatic scene lighting.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-Spotlights.gif" alt="Stage Spotlights Effect" style="max-width:100%;">
</div></td>
</tr>
</table>

---

## Visual Effects (VFX)

<table>
<tr>
<td width="50%">
<h4>VFX: Boom Sticker </h4>
<h5><code>[AS] VFX: Boom Sticker|AS_VFX_BoomSticker.1.fx</code></h5>
Displays a texture overlay ('sticker') with controls for placement, scale, rotation, and audio reactivity. Features customizable depth masking and support for custom textures. Ideal for adding dynamic, music-responsive overlays.

<br><br>
Based on '<a href="https://github.com/Otakumouse/stormshade/blob/master/v4.X/reshade-shaders/Shader%20Library/Recommended/StageDepth.fx" target="_new">StageDepth.fx</a>' by Marot Satil<br>

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-BoomSticker.gif" alt="Boom Sticker Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Circular Spectrum </h4>
<h5><code>[AS] VFX: Circular Spectrum|AS_VFX_CircularSpectrum.1.fx</code></h5>
Visualizes audio frequencies as a circular spectrum analyzer. Features adjustable band count, radius, thickness, color palette, and animation speed. Supports audio reactivity for dynamic, music-driven visuals. Ideal for overlays, music videos, and live performances.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/tcyGW1" target="_new">Circular audio visualizer</a>' by AIandDesign<br>

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-circularspectrum.gif" alt="Circular Spectrum Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Clair Obscur </h4>
<h5><code>[AS] VFX: Clair Obscur|AS_VFX_ClairObscur.1.fx</code></h5>
Simulates dramatic chiaroscuro (light-dark) lighting, emphasizing strong contrast and stylized shadows. Features controls for light direction, intensity, shadow softness, and color tint. Useful for artistic, cinematic, or moody scene transformations.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/ttcBRs" target="_new">[RGR] Hearts</a>' by deeplo<br>

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-ClairObscur.gif" alt="Clair Obscur Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Color Balancer </h4>
<h5><code>[AS] VFX: Color Balancer|AS_VFX_ColorBalancer.1.fx</code></h5>
Provides precise color grading by adjusting the balance of shadows, midtones, and highlights independently. Features controls for lift, gamma, gain, and color wheels. Useful for creative color correction and stylized looks.

</td>
<td width="50%"><div style="text-align:center">
<img src="" alt="Color Balancer Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Digital Artifacts </h4>
<h5><code>[AS] VFX: Digital Artifacts|AS_VFX_DigitalArtifacts.1.fx</code></h5>
Applies digital compression artifacts such as blockiness, color banding, and quantization noise. Features adjustable artifact strength, block size, and color depth. Useful for retro, glitch, or degraded video effects.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-digitalartifacts.gif" alt="Digital Artifacts Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Dust Motes </h4>
<h5><code>[AS] VFX: Dust Motes|AS_VFX_DustMotes.1.fx</code></h5>
Simulates floating dust motes and particles drifting through the scene. Features controls for particle density, size, speed, color, and depth of field. Includes animation and blending options for subtle atmospheric enhancement.

</td>
<td width="50%"><div style="text-align:center">
<img src="" alt="Dust Motes Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Focused Chaos </h4>
<h5><code>[AS] VFX: Focused Chaos|AS_VFX_FocusedChaos.1.fx</code></h5>
Creates a visually complex and dynamic abstract effect resembling a focused point of chaotic energy or a swirling cosmic vortex. Patterns are generated using 3D Simplex noise and Fractional Brownian Motion (FBM), with colors evolving based on noise patterns and spatial coordinates, animated over time. Features transparent background, customizable animation, artistic controls for swirl/noise/color/alpha, dithering, domain warping, and standard AS-StageFX depth/blending controls.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/lcfyDj" target="_new">BlackHole (swirl, portal)</a>' by misterprada<br>

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-focusedchaos.gif" alt="Focused Chaos Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Motion Focus </h4>
<h5><code>[AS] VFX: Motion Focus|AS_VFX_MotionFocus.1.fx</code></h5>
Analyzes inter-frame motion differences to dynamically adjust the viewport, zooming towards and centering on areas of detected movement. Uses a multi-pass approach to capture frames, detect motion, analyze motion distribution in quadrants, and apply a corresponding camera transformation with motion-centered zoom. Features multi-pass motion analysis, temporal smoothing, adaptive decay, quadrant-based aggregation, dynamic zoom/focus, and debug visualization.

</td>
<td width="50%"><div style="text-align:center">
<img src="" alt="Motion Focus Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Motion Trails </h4>
<h5><code>[AS] VFX: Motion Trails|AS_VFX_MotionTrails.1.fx</code></h5>
Applies trailing motion blur to moving objects or the whole scene. Features adjustable trail length, direction, fade, and blending. Useful for simulating speed, action, or ghosting effects in dynamic scenes.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-motiontrails.gif" alt="Motion Trails Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Radial Lens Distortion </h4>
<h5><code>[AS] VFX: Radial Lens Distortion|AS_VFX_RadialLensDistortion.1.fx</code></h5>
Simulates various lens distortions including tangential (rotational) blur, chromatic aberration (tangential or horizontal), and geometric barrel/pincushion distortion. Effects are strongest at the edges and diminish towards a configurable center point. Includes presets for emulating specific lens characteristics, plus global strength and focus falloff controls. Ensures consistent effect visibility regardless of source alpha by controlling alpha during blending.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-radiallensdistortion.gif" alt="Radial Lens Distortion Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Radiant Fire </h4>
<h5><code>[AS] VFX: Radiant Fire|AS_VFX_RadiantFire.1.fx</code></h5>
Generates radiant, glowing fire effects with animated flames and customizable color gradients. Features controls for flame shape, speed, intensity, and palette. Ideal for magical, fantasy, or atmospheric visuals.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/4ttGWM" target="_new">301's Fire Shader - Remix 3</a>' by mu6k<br>

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-radiantfire.gif" alt="Radiant Fire Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Rainy Window </h4>
<h5><code>[AS] VFX: Rainy Window|AS_VFX_RainyWindow.1.fx</code></h5>
Creates the illusion of raindrops and streaks running down a window, with realistic refraction and blur. Features adjustable rain density, drop size, streak speed, and blending. Perfect for moody, cinematic, or weather-themed scenes.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/ltffzl" target="_new">Heartfelt</a>' by Martijn Steinrucken (BigWings)<br>

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-rainywindow.gif" alt="Rainy Window Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Screen Ring </h4>
<h5><code>[AS] VFX: Screen Ring|AS_VFX_ScreenRing.1.fx</code></h5>
Draws animated rings or circular overlays on the screen. Features controls for ring count, size, thickness, color, and animation speed. Useful for HUDs, overlays, or stylized transitions.

</td>
<td width="50%"><div style="text-align:center">
<img src="" alt="Screen Ring Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Sparkle Bloom </h4>
<h5><code>[AS] VFX: Sparkle Bloom|AS_VFX_SparkleBloom.1.fx</code></h5>
Adds sparkling bloom highlights to bright areas, with animated glints and customizable color. Features controls for sparkle density, size, intensity, and animation. Ideal for magical, festive, or dreamy visuals.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-sparklebloom.gif" alt="Sparkle Bloom Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Spectrum Ring </h4>
<h5><code>[AS] VFX: Spectrum Ring|AS_VFX_SpectrumRing.1.fx</code></h5>
Displays an audio spectrum analyzer in a ring format. Features adjustable band count, radius, thickness, color palette, and animation speed. Supports audio reactivity for dynamic, music-driven visuals. Ideal for overlays, music videos, and live performances.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-SpectrumRing.gif" alt="Spectrum Ring Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Stencil Mask </h4>
<h5><code>[AS] VFX: Stencil Mask|AS_VFX_StencilMask.1.fx</code></h5>
Applies a stencil mask to selectively reveal or hide parts of the scene. Features controls for mask shape, size, position, feathering, and blending. Useful for transitions, overlays, or compositing effects.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-StencilMask.gif" alt="Stencil Mask Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Tilted Grid </h4>
<h5><code>[AS] VFX: Tilted Grid|AS_VFX_TiltedGrid.1.fx</code></h5>
Draws a tilted, animated grid overlay on the scene. Features controls for grid angle, spacing, line thickness, color, and animation speed. Useful for stylized overlays, retro visuals, or compositional guides.

<br><br>
Based on '<a href="https://www.youtube.com/watch?v=Tfj6RDqXEHM" target="_new">Godot 4: Tilted Grid Effect Tutorial</a>' by FencerDevLog<br>

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-tiltedgrid.gif" alt="Tilted Grid Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Volumetric Light </h4>
<h5><code>[AS] VFX: Volumetric Light|AS_VFX_VolumetricLight.1.fx</code></h5>
Simulates volumetric light rays (god rays) emanating from a source. Features controls for light position, color, intensity, ray length, and blending. Useful for dramatic, atmospheric, or mystical scene lighting.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/wftXzr" target="_new">fake volumetric 2d light wip</a>' by int_45h<br>

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-volumetriclight.gif" alt="Volumetric Light Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: VUMeter </h4>
<h5><code>[AS] VFX: VUMeter|AS_VFX_VUMeter.1.fx</code></h5>
Displays a classic VU meter with audio-reactive bars. Features controls for bar count, orientation, color, peak hold, and animation. Ideal for music visualizations, overlays, and live performance feedback.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-VUMeter.gif" alt="VUMeter Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Warp Distort </h4>
<h5><code>[AS] VFX: Warp Distort|AS_VFX_WarpDistort.1.fx</code></h5>
Applies animated warp distortion to the scene. Features controls for distortion strength, direction, speed, and blending. Useful for psychedelic, dreamlike, or transition effects.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-Warp.gif" alt="Warp Distort Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Water Surface </h4>
<h5><code>[AS] VFX: Water Surface|AS_VFX_WaterSurface.1.fx</code></h5>
Simulates an animated water surface with dynamic ripples, reflections, and customizable color. Features controls for wave speed, amplitude, direction, and reflection intensity. Useful for aquatic, dreamy, or atmospheric effects.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-watersurface.gif" alt="Water Surface Effect" style="max-width:100%;">
</div></td>
</tr>
</table>

---

*For more detailed information about installation, updates, and credits, please refer to the [main README](../README.md). Complete external source attribution is available in [AS_StageFX_Credits.md](../AS_StageFX_Credits.md).*

