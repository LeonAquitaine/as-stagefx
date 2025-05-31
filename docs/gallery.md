# AS-StageFX Shader Gallery - Essentials Package

This gallery provides detailed descriptions and visual examples of the core shaders included in the **AS_StageFX_Essentials** package. The complete AS-StageFX collection includes **45 shaders** across four categories: **21 Background (BGX)**, **4 Graphic (GFX)**, **3 Lighting (LFX)**, and **17 Visual (VFX)** effects.

For installation instructions and general information, please refer to the [main README](../README.md).

> **Looking for other packages?**
> - [Backgrounds Gallery](./gallery-backgrounds.md) - Complete collection of background effects
> - [Visual Effects Gallery](./gallery-visualeffects.md) - Complete collection of visual effects

## Core Library Files (.fxh)

The Essentials package includes these foundation libraries used by all shaders:

- **AS_Noise.1.fxh** - Noise generation functions (Perlin, Simplex, FBM, etc.)
- **AS_Palette.1.fxh** - Color palette and gradient system
- **AS_Palette_Styles.1.fxh** - Preset color palettes and styles
- **AS_Perspective.1.fxh** - Perspective and 3D utility functions
- **AS_Utils.1.fxh** - Core utility functions, constants, and common code

---

## Background Effects (BGX)

<table>
<tr>
<td width="50%">
<h4>BGX: Light Ripples ✨</h4>
<h5><code>[AS] BGX: Light Ripples|AS_BGX_LightRipples.1.fx</code></h5>
Creates a mesmerizing, rippling kaleidoscopic light pattern effect. Suitable as a dynamic background or overlay. Includes controls for animation, distortion (amplitude, frequencies), color palettes with cycling, audio reactivity, depth-aware rendering, adjustable rotation, and standard blending options.<br><br>
Original: <a href="https://www.pouet.net/prod.php?which=57245" target="_new">Shader by Danilo Guanabara</a>.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/99bc3c0c-caac-4060-883c-079d92419abc">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Stained Lights ✨</h4>
<h5><code>[AS] BGX: Stained Lights|AS_BGX_StainedLights.1.fx</code></h5>
Creates dynamic and colorful patterns reminiscent of stained glass illuminated by shifting light, with multiple blurred layers enhancing depth and visual complexity. Generates layers of distorted, cell-like structures with vibrant, evolving colors and subtle edge highlighting, overlaid with softer, floating elements. Features multi-layered pattern generation (adjustable iterations), dynamic animation with speed control, customizable pattern scaling/edge highlighting, audio reactivity for animation/pattern evolution, post-processing (curve adjustments, noise), blurred floating layers for depth, and depth-aware rendering with standard blending. Suitable for abstract backgrounds, energy fields, or mystical visuals.<br><br>
Inspired by: <a href="https://www.shadertoy.com/view/WlsSzM" target="_new">"Stained Lights" by 104</a>.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/45b96d92-dedd-45ec-8007-69efb93c3786">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Time Crystal ✨</h4>
<h5><code>[AS] BGX: Time Crystal|AS_BGX_TimeCrystal.1.fx</code></h5>
Creates a hypnotic, crystalline fractal structure with dynamic animation and color cycling. Generates patterns reminiscent of crystalline structures or gems with depth and dimension. Features fractal crystal-like patterns (customizable iterations), dynamic animation (controllable speed), adjustable pattern density/detail, customizable color palettes with cycling, audio reactivity for pattern dynamics/colors, depth-aware rendering with standard blending, and adjustable position/rotation controls. Suitable for mystic or sci-fi backgrounds, portals, or energy fields.<br><br>
Original: <a href="https://www.shadertoy.com/view/lcl3z2" target="_new">"Time Crystal" by raphaeljmu</a>.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/ffec219a-b0c2-481a-a1c4-125ad699c8f8">
</div></td>
</tr>
</table>

---

## Graphic Effects (GFX)

<table>
<tr>
<td width="50%">
<h4>GFX: Aspect Ratio ✨</h4>
<h5><code>[AS] GFX: Aspect Ratio|AS_GFX_AspectRatio.1.fx</code></h5>
A versatile aspect ratio framing tool designed to help position subjects for social media posts, photography, and video composition. Features preset aspect ratios for common social media and photography formats (1:1, 16:9, 4:5, etc.), custom aspect ratio input, adjustable clipped area color and opacity, optional composition guides (rule of thirds, golden ratio, center lines), horizontal/vertical alignment controls, and adjustable border appearance. Perfect for precise subject positioning and consistent framing across platforms.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/6c622f56-edf8-4dc7-a18d-52995e846237">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>GFX: Multi-Layer Halftone ✨</h4>
<h5><code>[AS] Multi-Layer Halftone|AS_GFX_MultiLayerHalftone.1.fx</code></h5>
Creates a highly customizable multi-layer halftone effect with support for up to four independent layers. Each layer can use different pattern types (dots, lines, crosshatch), isolation methods (brightness, RGB, hue, depth), colors, thresholds, scales, densities, and angles. Features layer blending with transparency support.<br><br>
Based on: <a href="https://www.shadertoy.com/view/XdcGzn" target="_new">"Halftone Shader" by P. Gonzalez Vivo</a>.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/b93c9d03-5d23-4b32-aa3e-f2b6a9736c70" alt="Multi-Layer Halftone Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>GFX: Vignette Plus ✨</h4>
<h5><code>[AS] GFX: Vignette Plus|AS_GFX_VignettePlus.1.fx</code></h5>
A vignette shader that provides multiple visual styles and customizable pattern options, creating directional, controllable vignette effects for stage compositions and scene framing. Perfect for adding mood, focus, or stylistic elements. Features four distinct visual styles (Smooth Gradient, Duotone Circles, Directional Lines perpendicular and parallel), multiple mirroring options (none, edge-based, center-based), precise control over effect coverage with start/end falloff points, and much more. Optimized for performance across various resolutions.<br><br>
Inspired by: The hexagonal grid implementation is adapted from <a href="https://www.shadertoy.com/view/XfjyWG" target="_new">"hexagonal wipe" by blandprix</a>.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/bf471099-9c4a-423b-ae1f-fae2f83d924a">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>GFX: Hand Drawing 💀</h4>
<h5><code>[AS] GFX: Hand Drawing|AS_GFX_HandDrawing.1.fx</code></h5>
Transforms your scene into a stylized hand-drawn sketch or technical ink illustration with distinct linework and cross-hatching patterns. Features sophisticated line generation with customizable stroke directions and length, textured fills based on original image colors with noise-based variation, animated "wobble" effect for an authentic hand-drawn feel, optional paper-like background pattern, depth-aware rendering with standard blending, and comprehensive controls for fine-tuning every aspect of the effect. Perfect for artistic transformations, comic/manga styles, or technical illustrations.<br><br>
Based on: <a href="https://www.shadertoy.com/view/XtVGD1" target="_new">"notebook drawings" by Flockaroo (2016)</a>.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/4074ac6b-a385-4e0f-9d9a-c4d5dd0117cd">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>GFX: Brush Stroke ✨</h4>
<h5><code>[AS] GFX: Brush Stroke|AS_GFX_BrushStroke.1.fx</code></h5>
Creates a stylized brush stroke band effect with highly textured, irregular edges. Features procedurally generated irregular edges using thresholded FBM noise, anisotropic noise scaling for directional ink texture appearance, dynamic thresholding system for stroke density variation from center to edge, optional drop shadow with configurable color and positioning, advanced texture shading with highlights and shadows, invert mode for negative space effects, audio reactivity for stroke height/ink contrast/shadow opacity, and full positioning/scaling/rotation controls with aspect ratio independence. Perfect for artistic overlays, title effects, or creative masking.
</td>
<td width="50%"><div style="text-align:center">
</div></td>
</tr>
</table>

---

## Lighting Effects (LFX)

<table>
<tr>
<td width="50%">
<h4>LFX: Laser Show ✨</h4>
<h5><code>[AS] Laser Show|AS_LFX_LaserShow.1.fx</code></h5>
Renders multiple colored laser beams emanating from a user-defined origin, illuminating a swirling, animated smoke field. Features up to 8 configurable beams, procedural FBM Simplex noise smoke with domain warping, audio-reactive fanning and blinking, depth-based occlusion, and user-tunable blending. Highly configurable.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/555b32cd-be6f-47c2-92a6-39994e861637" alt="Laser Show Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>LFX: Stage Spotlights ✨</h4>
<h5><code>[AS] Stage Spotlights|AS_LFX_StageSpotlights.1.fx</code></h5>
Simulates a vibrant rock concert stage lighting system with up to 4 independently controllable directional spotlights, glow effects, and audio reactivity. Features customizable position, size, color, angle, direction, audio-reactive intensity, automated sway, pulsing, bokeh glow, depth-masking, and multiple blend modes. Ideal for dramatic lighting.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/73e1081b-147e-4355-b867-d4964238245b" alt="Spotlights Effect" style="max-width:100%;">
</div></td>
</tr>
</table>

---

## Visual Effects (VFX)

<table>
<tr>
<td width="50%">
<h4>VFX: Boom Sticker ✨</h4>
<h5><code>[AS] Boom Sticker|AS_VFX_BoomSticker.1.fx</code></h5>
Displays a texture overlay ("sticker") with controls for placement, scale, rotation, and audio reactivity. Features customizable depth masking and support for custom textures. Ideal for adding dynamic, music-responsive overlays.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/ee8e98b8-198b-4a65-a40d-032eca60dcc5" alt="Boom Sticker Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Motion Trails ✨</h4>
<h5><code>[AS] Motion Trails|AS_VFX_MotionTrails.1.fx</code></h5>
Creates striking, persistent motion trails ideal for music videos. Objects within a depth threshold leave fading colored trails. Features multiple capture modes (tempo, frame, audio beat, manual), customizable trail color/strength/persistence, audio reactivity, blend modes, and optional subject highlight modes.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/1b7a2750-89be-424b-b149-4d850692d9f8" alt="Motion Trails Effect" style="max-width:100%;">
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
<h4>VFX: Sparkle Bloom ⚡</h4>
<h5><code>[AS] VFX: Sparkle Bloom|AS_VFX_SparkleBloom.1.fx</code></h5>
Creates a realistic glitter/sparkle effect that dynamically responds to scene lighting, depth, and camera movement. Simulates tiny reflective particles with multi-layered Voronoi noise, customizable lifetime, depth masking, high-quality bloom, fresnel effect, blend modes, color options, and audio-reactive intensity/animation.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/a0998834-4795-414e-a685-9c7ab685a515" alt="Sparkle Bloom Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Stencil Mask ⚡</h4>
<h5><code>[AS] VFX: Stencil Mask|AS_VFX_StencilMask.1.fx</code></h5>
Isolates foreground subjects based on depth and applies customizable borders and projected shadows around them. Includes options for various border styles, shadow appearance, and audio reactivity for dynamic effects.
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/98097147-0a9e-40ac-ae21-0b19e5241c91" alt="Stencil Mask Effect" style="max-width:100%;">
</div></td>
</tr>
</table>

---

*For more detailed information about installation, updates, and credits, please refer to the [main README](../README.md). Complete external source attribution is available in [AS_StageFX_Credits.md](../AS_StageFX_Credits.md).*
