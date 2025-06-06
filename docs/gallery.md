# AS-StageFX Shader Gallery - Essentials Package

This gallery provides detailed descriptions and visual examples of the core shaders included in the **AS_StageFX_Essentials** package. The complete AS-StageFX collection includes ** shaders** across four categories: ** Background (BGX)**, ** Graphic (GFX)**, ** Lighting (LFX)**, and ** Visual (VFX)** effects.

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
<h4>BGX: Blue Corona </h4>
<h5><code>[AS] BGX: Blue Corona|AS_BGX_BlueCorona.1.fx</code></h5>
Creates a vibrant, abstract blue corona effect with fluid, dynamic motion. The effect generates hypnotic patterns through iterative mathematical transformations, resulting in organic, plasma-like visuals with a predominantly blue color scheme. Features abstract, organic blue corona patterns; smooth fluid-like animation; customizable iteration count/pattern scale; animation speed/flow controls; intuitive color controls; customizable background color; audio reactivity (multiple targets); depth-aware rendering; and standard position, rotation, scale, and blending options.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/f5ee6ce1-36b9-4d2f-9250-4c345394c27c" alt="Blue Corona Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Constellation </h4>
<h5><code>[AS] BGX: Constellation|AS_BGX_Constellation.1.fx</code></h5>
Creates an animated stellar constellation pattern with twinkling stars and connecting lines. Perfect for cosmic, night sky, or abstract network visualizations with a hand-drawn aesthetic. Features dynamic constellation lines with customizable thickness and falloff; twinkling star points with adjustable sparkle properties; procedurally animated line connections; animated color palette with adjustable parameters; audio reactivity for zoom, gradient effects, line brightness, and sparkle magnitude; depth-aware rendering; and standard blend options.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/8a7e8736-c23c-47eb-a753-c44ffc101b71" alt="Constellation Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Corridor Travel </h4>
<h5><code>[AS] BGX: Corridor Travel|AS_BGX_CorridorTravel.1.fx</code></h5>
Simulates an artistic flight through an abstract, glowing, patterned tunnel. Features multiple samples per pixel for pseudo-DOF and motion blur, and simulates light bounces with artistic reflection logic.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/be502be4-cc82-44a4-8947-74dfd6f072b8" alt="Corridor Travel Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Cosmic Kaleidoscope </h4>
<h5><code>[AS] BGX: Cosmic Kaleidoscope|AS_BGX_CosmicKaleidoscope.1.fx</code></h5>
Renders a raymarched volumetric fractal resembling a Mandelbox or Mandelbulb. Features Kaleidoscope-like mirroring effect with customizable repetitions, audio reactivity for dynamic parameter adjustments, palette-based coloring system with customizable options, and full rotation, position and depth control for scene integration.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/d466ec57-964c-4c25-93e2-6d01ca4ee1d3" alt="Cosmic Kaleidoscope Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Digital Brain </h4>
<h5><code>[AS] BGX: Digital Brain|AS_BGX_DigitalBrain.1.fx</code></h5>
Creates an abstract visualization of a 'digital brain' with evolving Voronoi patterns and neural-like connections. The effect simulates an organic electronic network with dynamic light paths that mimic neural activity in a stylized, technological manner. Features dynamic Voronoi-based pattern generation, animated 'electrical' pulses simulating synaptic activity, color modulation based on noise texture for organic variation, advanced vignette controls, pre-optimized pattern stretching, classic and texture-based coloring options, customizable animation and pattern controls, and depth-aware rendering with standard blending.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/27c3f540-b8f5-4b85-a4a4-4a5076e67f39" alt="Digital Brain Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Fluorescent </h4>
<h5><code>[AS] BGX: Fluorescent|AS_BGX_Fluorescent.1.fx</code></h5>
Creates a vibrant neon fluorescent background effect that simulates the glow and intensity of fluorescent lighting. Perfect for creating retro, cyberpunk, or futuristic atmospheres with customizable colors and intensity. Features raymarched volumetric fluorescent effect with depth, dynamic color shifting with RGB phase controls, animated pulsing and flowing patterns, audio reactivity for rhythm-synchronized lighting, standard stage controls for positioning and depth, customizable iteration count for quality vs performance balance, and blend mode controls for integration with existing scenes.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/PLACEHOLDER-IMAGE-ID" alt="Fluorescent Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Golden Clockwork </h4>
<h5><code>[AS] BGX: Golden Clockwork|AS_BGX_GoldenClockwork.1.fx</code></h5>
Renders a mesmerizing and intricate animated background effect reminiscent of golden clockwork mechanisms or Apollonian gasket-like fractal patterns. The effect features complex, evolving geometric designs with a characteristic golden color palette. Features procedurally generated Apollonian fractal patterns, dynamic animation driven by time, a golden color scheme with lighting and shading effects, depth-like progression through fractal layers, kaleidoscopic and mirroring options for pattern variation, resolution-independent rendering, and UI controls for animation (speed, keyframe, path speed), palette, fractal/kaleidoscope parameters, audio reactivity, stage controls (position, scale, rotation, depth), and blending.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/583dfe11-c8b6-4e34-ad79-35d875ce32c6" alt="Golden Clockwork Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Kaleidoscope </h4>
<h5><code>[AS] BGX: Kaleidoscope|AS_BGX_Kaleidoscope.1.fx</code></h5>
Creates a vibrant, ever-evolving fractal kaleidoscope pattern with animated tendrils. Perfect for psychedelic, cosmic, or abstract backgrounds with a hypnotic quality. Features adjustable kaleidoscope mirror count for symmetry control; fractal zoom and pattern rotation with animation controls; customizable wave parameters and color palette; audio reactivity for zoom, wave intensity, and pattern rotation; depth-aware rendering; and standard blend options.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/8bd0fdee-77a8-40d6-be9f-1708186e5590" alt="Kaleidoscope Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Light Ripples </h4>
<h5><code>[AS] BGX: Light Ripples|AS_BGX_LightRipples.1.fx</code></h5>
Creates a mesmerizing, rippling kaleidoscopic light pattern effect. Suitable as a dynamic background or overlay. Includes controls for animation, distortion (amplitude, frequencies), color palettes with cycling, audio reactivity, depth-aware rendering, adjustable rotation, and standard blending options.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/99bc3c0c-caac-4060-883c-079d92419abc" alt="Light Ripples Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Light Wall </h4>
<h5><code>[AS] BGX: Light Wall|AS_BGX_LightWall.1.fx</code></h5>
This shader renders a seamless, soft, overlapping grid of light panels with various built-in patterns. Perfect for creating dance club and concert backdrops with fully customizable colors, patterns, and audio reactivity.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/4871c7be-b540-4f19-8cb2-bbd0c47ac237" alt="Light Wall Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Liquid Chrome </h4>
<h5><code>[AS] BGX: Liquid Chrome|AS_BGX_LiquidChrome.1.fx</code></h5>
Creates dynamic, flowing psychedelic patterns reminiscent of liquid metal or chrome. This shader iteratively distorts screen coordinates, creating complex, flowing patterns with optional vertical stripe overlays for additional visual texture.

</td>
<td width="50%"><div style="text-align:center">
<img src="" alt="Liquid Chrome Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Log Spirals </h4>
<h5><code>[AS] BGX: Log Spirals|AS_BGX_LogSpirals.1.fx</code></h5>
Creates an organic spiral pattern based on logarithmic growth with animated spheres along the spiral arms. Features precise control over spiral expansion rate and animation, customizable sphere size with fade effects and specular highlights, color palette options with hue cycling and ambient glow, audio reactivity for multiple parameters (animation speed, rotation, arm twist, sphere size, brightness), and standard position/rotation/scale controls for scene integration.

</td>
<td width="50%"><div style="text-align:center">
<img src="" alt="Log Spirals Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Melt Wave </h4>
<h5><code>[AS] BGX: Melt Wave|AS_BGX_MeltWave.1.fx</code></h5>
Creates a flowing, warping psychedelic effect inspired by 1970s visual aesthetics. Generates mesmerizing colored patterns with sine-based distortions that evolve over time. Features adjustable zoom/intensity, a palette system (mathematical or preset colors), dynamic time-based animation with keyframe support, audio reactivity mappable to different parameters, and resolution-independent transformation with position/rotation controls.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/4871c7be-b540-4f19-8cb2-bbd0c47ac237" alt="Melt Wave Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Misty Grid </h4>
<h5><code>[AS] BGX: Misty Grid|AS_BGX_MistyGrid.1.fx</code></h5>
Creates an abstract fractal-based grid background with a misty, ethereal appearance using raymarching techniques. Features dynamic fractal-based grid environment, customizable colors with palette system, folding and repetition for complex patterns, camera movement simulation with smooth rotations, audio reactivity affecting multiple parameters (fractal scale, folding intensity, saturation, brightness, camera zoom, animation speed), and standard position/rotation/scale controls.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/ddd37fd8-70be-442c-aaed-f31063f8d9e9" alt="Misty Grid Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Past Racer </h4>
<h5><code>[AS] BGX: Past Racer|AS_BGX_PastRacer.1.fx</code></h5>
A ray marching shader that generates one of two selectable abstract procedural scenes. Features domain repetition, custom transformations, and pseudo-random patterns. Scene geometry and flare effects can be reactive to audio frequency bands.

</td>
<td width="50%"><div style="text-align:center">
<img src="" alt="Past Racer Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Plasma Flow </h4>
<h5><code>[AS] BGX: Plasma Flow|AS_BGX_PlasmaFlow.1.fx</code></h5>
Sophisticated, gentle, and flexible plasma effect for groovy, atmospheric visuals. Generates smooth, swirling, organic patterns with customizable color gradients (2-4 user-defined colors) and strong audio reactivity. Features procedural plasma/noise with domain warping for fluid motion, controls for speed, scale, complexity, stretch, and warp, audio-reactive modulation of movement, color, brightness, and turbulence, plus standard blend modes and debug views. Ideal for music video backgrounds and overlays.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/ba95325d-eff0-439e-a452-567675da84fe" alt="Plasma Flow Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Protean Clouds </h4>
<h5><code>[AS] BGX: Protean Clouds|AS_BGX_ProteanClouds.1.fx</code></h5>
Renders dynamic, evolving volumetric clouds through raymarching techniques. Creates an immersive, abstract cloudscape with dynamic color variations and realistic lighting. Features high-quality volumetric cloud formations, customizable cloud density, shape, and detail, dynamic camera movement with adjustable path and sway, sophisticated internal lighting and self-shadowing, color palette system with customizable parameters, audio reactivity for multiple cloud parameters, and resolution-independent rendering with precise position controls.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-image" alt="Protean Clouds Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Quadtree Truchet </h4>
<h5><code>[AS] BGX: Quadtree Truchet|AS_BGX_QuadtreeTruchet.1.fx</code></h5>
Creates a sophisticated multiscale recursive Truchet pattern with hierarchical tile overlaps across 3 levels. Generates complex geometric designs through quadtree subdivision and probabilistic tile placement. Features quadtree-based recursive pattern generation, overlapping tile system with collision prevention, full AS palette system support with multiple color modes, Art Deco style with line tiles and weave effects, animated rotation and panning, audio reactivity for scale/rotation/seed/density, stage positioning controls, and debug visualization of the underlying quadtree structure.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-image" alt="Quadtree Truchet Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Raymarched Chain </h4>
<h5><code>[AS] BGX: Raymarched Chain|AS_BGX_RaymarchedChain.1.fx</code></h5>
Renders a raymarched scene featuring an animated, endlessly twisting chain composed of interconnected torus shapes. The chain follows a procedurally defined path, and its segments rotate and evolve over time, creating a mesmerizing, complex visual. Features raymarched chain of torus shapes with procedural path animation, customizable animation speed and chain geometry, dynamic coloring based on raymarching depth and iteration, camera orientation controls, and standard AS-StageFX blending controls.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-image" alt="Raymarched Chain Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Shine On </h4>
<h5><code>[AS] BGX: Shine On|AS_BGX_ShineOn.1.fx</code></h5>
Creates a dynamic, evolving fractal noise pattern with bright, sparkly crystal highlights that move across the screen. Combines multiple layers of noise with procedural animation for a mesmerizing background effect. Features layered noise patterns with dynamic animation, crystal point highlights with customizable parameters, audio reactivity, and depth-aware rendering.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/50162c8a-4841-4319-b731-d79c15453c7a" alt="Shine On Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Stained Lights </h4>
<h5><code>[AS] BGX: Stained Lights|AS_BGX_StainedLights.1.fx</code></h5>
Creates dynamic and colorful patterns reminiscent of stained glass illuminated by shifting light, with multiple blurred layers enhancing depth and visual complexity. Generates layers of distorted, cell-like structures with vibrant, evolving colors and subtle edge highlighting, overlaid with softer, floating elements. Features multi-layered pattern generation (adjustable iterations), dynamic animation with speed control, customizable pattern scaling/edge highlighting, audio reactivity for animation/pattern evolution, post-processing (curve adjustments, noise), blurred floating layers for depth, and depth-aware rendering with standard blending. Suitable for abstract backgrounds, energy fields, or mystical visuals.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/45b96c92-dedd-45ec-8007-69efb93c3786" alt="Stained Lights Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Sunset Clouds </h4>
<h5><code>[AS] BGX: Sunset Clouds|AS_BGX_SunsetClouds.1.fx</code></h5>
Renders an animated scene of clouds at sunset using raymarching to create volumetric cloud effects with dynamic lighting and turbulence. Features raymarched volumetric clouds, animated turbulence effect, dynamic sunset coloring that changes over time, and tunable parameters for iterations, animation speed, and visual details.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-image" alt="Sunset Clouds Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Time Crystal </h4>
<h5><code>[AS] BGX: Time Crystal|AS_BGX_TimeCrystal.1.fx</code></h5>
Creates a hypnotic, crystalline fractal structure with dynamic animation and color cycling. Generates patterns reminiscent of crystalline structures or gems with depth and dimension. Features fractal crystal-like patterns (customizable iterations), dynamic animation (controllable speed), adjustable pattern density/detail, customizable color palettes with cycling, audio reactivity for pattern dynamics/colors, depth-aware rendering with standard blending, and adjustable position/rotation controls. Suitable for mystic or sci-fi backgrounds, portals, or energy fields.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/ffec219a-b0c2-481a-a1c4-125ad699c8f8" alt="Time Crystal Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Vortex </h4>
<h5><code>[AS] BGX: Vortex|AS_BGX_Vortex.1.fx</code></h5>
Creates a psychedelic swirling vortex pattern. The effect is animated and features controls for color, animation speed, swirl characteristics, and brightness. Suitable as a dynamic background. Features animated vortex with customizable speed, palette-based coloring, swirl intensity/frequency/sharpness, brightness falloff, and standard AS-StageFX blending and positioning.

</td>
<td width="50%"><div style="text-align:center">
<img src="" alt="Vortex Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Wavy Squares </h4>
<h5><code>[AS] BGX: Wavy Squares|AS_BGX_WavySquares.1.fx</code></h5>
Creates a hypnotic pattern of wavy, animated square tiles that shift and transform. The squares follow a wave-like motion and feature dynamic size changes, creating a flowing, organic grid pattern. Features wavy, undulating square tiling; customizable wave parameters (amplitude, frequency, speed); variable tile size/scaling; shape smoothness/box roundness controls; audio reactivity (multiple targets); depth-aware rendering; adjustable rotation; and standard position, scale, and blending options.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/30c2fa46-0d3c-4fe4-bb24-001b85585f41" alt="Wavy Squares Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Wavy Squiggles </h4>
<h5><code>[AS] BGX: Wavy Squiggles|AS_BGX_WavySquiggles.1.fx</code></h5>
Creates a mesmerizing pattern of adaptive wavy lines that follow a mouse or fixed position. The lines create intricate patterns that look like dynamic squiggly lines arranged around a central point, with rotation applied based on direction. Features position-reactive wavy line patterns; customizable line parameters (rotation influence, thickness, distance, smoothness); optional color palettes (hue, saturation, value control); pattern displacement for off-center effects; audio reactivity (multiple targets); depth-aware rendering; adjustable rotation; and standard position, scale, and blending options.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/adfe182d-2507-49e1-82c1-38e41a1403a5" alt="Wavy Squiggles Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>BGX: Zippy Zaps </h4>
<h5><code>[AS] BGX: Zippy Zaps|AS_BGX_ZippyZaps.1.fx</code></h5>
Creates dynamic electric arcs and lightning patterns for a striking background effect. This effect generates procedural electric-like patterns that appear behind objects in the scene, creating an energetic, dynamic background with complete control over appearance and animation. Features animated electric/lightning arcs with procedural generation; fully customizable colors, intensity, and animation parameters; resolution-independent rendering; audio reactivity; depth-aware rendering; and adjustable rotation/positioning in 3D space.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/f32eebde-9c76-49ab-ab6e-50bc4fdeaf2f" alt="Zippy Zaps Effect" style="max-width:100%;">
</div></td>
</tr>
</table>

---

## Graphic Effects (GFX)

<table>
<tr>
<td width="50%">
<h4>GFX: Aspect Ratio </h4>
<h5><code>[AS] GFX: Aspect Ratio|AS_GFX_AspectRatio.1.fx</code></h5>
A versatile aspect ratio framing tool designed to help position subjects for social media posts, photography, and video composition. Features preset aspect ratios for common social media and photography formats (1:1, 16:9, 4:5, etc.), custom aspect ratio input, adjustable clipped area color and opacity, optional composition guides (rule of thirds, golden ratio, center lines), horizontal/vertical alignment controls, and adjustable border appearance. Perfect for precise subject positioning and consistent framing across platforms.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/6c622f56-edf8-4dc7-a18d-52995e846237" alt="Aspect Ratio Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>GFX: Audio Direction </h4>
<h5><code>[AS] GFX: Audio Direction|AS_GFX_AudioDirection.1.fx</code></h5>
Displays animated arrows or indicators that visualize the directionality of audio sources in real time. Features customizable arrow count, size, color, and animation speed. Supports audio reactivity for direction, magnitude, and color. Useful for music visualizations, DJ overlays, or any scene where audio direction feedback is desired.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-audiodirection" alt="Audio Direction Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>GFX: Brush Stroke </h4>
<h5><code>[AS] GFX: Brush Stroke|AS_GFX_BrushStroke.1.fx</code></h5>
Applies painterly brush stroke textures to the scene, simulating layered paint effects. Features customizable brush size, direction, density, and color blending. Includes animation controls for evolving brush patterns and supports palette-based colorization. Ideal for artistic transformations and stylized overlays.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-brushstroke" alt="Brush Stroke Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>GFX: Cinematic Diffusion </h4>
<h5><code>[AS] GFX: Cinematic Diffusion|AS_GFX_CinematicDiffusion.1.fx</code></h5>
A high-quality cinematic diffusion/bloom filter that replicates classic film diffusion looks. Features 8 built-in presets (Pro-Mist, Hollywood Black Magic, etc.) and a fully customizable mode. Multi-pass downsampling ensures smooth, natural glows. Ideal for virtual photography and cinematic shots.

</td>
<td width="50%"><div style="text-align:center">
<img src="" alt="Cinematic Diffusion Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>GFX: Hand Drawing </h4>
<h5><code>[AS] GFX: Hand Drawing|AS_GFX_HandDrawing.1.fx</code></h5>
Transforms your scene into a stylized hand-drawn sketch or technical ink illustration with distinct linework and cross-hatching patterns. Features sophisticated line generation with customizable stroke directions and length, textured fills based on original image colors with noise-based variation, animated 'wobble' effect for an authentic hand-drawn feel, optional paper-like background pattern, depth-aware rendering with standard blending, and comprehensive controls for fine-tuning every aspect of the effect. Perfect for artistic transformations, comic/manga styles, or technical illustrations.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/4074ac6b-a385-4e0f-9d9a-c4d5dd0117cd" alt="Hand Drawing Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>GFX: MultiLayer Halftone </h4>
<h5><code>[AS] GFX: MultiLayer Halftone|AS_GFX_MultiLayerHalftone.1.fx</code></h5>
Creates a highly customizable multi-layer halftone effect with support for up to four independent layers. Each layer can use different pattern types (dots, lines, crosshatch), isolation methods (brightness, RGB, hue, depth), colors, thresholds, scales, densities, and angles. Features layer blending with transparency support.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/b93c9d03-5d23-4b32-aa3e-f2b6a9736c70" alt="MultiLayer Halftone Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>GFX: Vignette Plus </h4>
<h5><code>[AS] GFX: Vignette Plus|AS_GFX_VignettePlus.1.fx</code></h5>
A vignette shader that provides multiple visual styles and customizable pattern options, creating directional, controllable vignette effects for stage compositions and scene framing. Perfect for adding mood, focus, or stylistic elements. Features four distinct visual styles (Smooth Gradient, Duotone Circles, Directional Lines perpendicular and parallel), multiple mirroring options (none, edge-based, center-based), precise control over effect coverage with start/end falloff points, and much more. Optimized for performance across various resolutions.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/bf471099-9c4a-423b-ae1f-fae2f83d924a" alt="Vignette Plus Effect" style="max-width:100%;">
</div></td>
</tr>
</table>

---

## Lighting Effects (LFX)

<table>
<tr>
<td width="50%">
<h4>LFX: Candle Flame </h4>
<h5><code>[AS] LFX: Candle Flame|AS_LFX_CandleFlame.1.fx</code></h5>
Renders a realistic animated candle flame with natural flicker and glow. Features customizable flame shape, color, flicker speed, and intensity. Includes controls for flame position, scale, and blending. Ideal for atmospheric lighting and cozy scene effects.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-candleflame" alt="Candle Flame Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>LFX: Laser Show </h4>
<h5><code>[AS] LFX: Laser Show|AS_LFX_LaserShow.1.fx</code></h5>
Projects animated laser beams and geometric patterns onto the stage. Features customizable beam count, color, speed, and spread. Supports audio reactivity for beam movement and intensity. Includes controls for rotation, position, and blending. Perfect for concert, club, or sci-fi lighting effects.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-lasershow" alt="Laser Show Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>LFX: Stage Spotlights </h4>
<h5><code>[AS] LFX: Stage Spotlights|AS_LFX_StageSpotlights.1.fx</code></h5>
Simulates moving stage spotlights with adjustable beam width, color, intensity, and movement patterns. Features multiple spotlights with independent controls, audio reactivity for movement and brightness, and blending options for integration with other effects. Ideal for live performance and dramatic scene lighting.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-spotlights" alt="Stage Spotlights Effect" style="max-width:100%;">
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

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/ee8e98b8-198b-4a65-a40d-032eca60dcc5" alt="Boom Sticker Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Circular Spectrum </h4>
<h5><code>[AS] VFX: Circular Spectrum|AS_VFX_CircularSpectrum.1.fx</code></h5>
Visualizes audio frequencies as a circular spectrum analyzer. Features adjustable band count, radius, thickness, color palette, and animation speed. Supports audio reactivity for dynamic, music-driven visuals. Ideal for overlays, music videos, and live performances.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-circularspectrum" alt="Circular Spectrum Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Clair Obscur </h4>
<h5><code>[AS] VFX: Clair Obscur|AS_VFX_ClairObscur.1.fx</code></h5>
Simulates dramatic chiaroscuro (light-dark) lighting, emphasizing strong contrast and stylized shadows. Features controls for light direction, intensity, shadow softness, and color tint. Useful for artistic, cinematic, or moody scene transformations.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-clairobscur" alt="Clair Obscur Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Color Balancer </h4>
<h5><code>[AS] VFX: Color Balancer|AS_VFX_ColorBalancer.1.fx</code></h5>
Provides precise color grading by adjusting the balance of shadows, midtones, and highlights independently. Features controls for lift, gamma, gain, and color wheels. Useful for creative color correction and stylized looks.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-colorbalancer" alt="Color Balancer Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Digital Artifacts </h4>
<h5><code>[AS] VFX: Digital Artifacts|AS_VFX_DigitalArtifacts.1.fx</code></h5>
Applies digital compression artifacts such as blockiness, color banding, and quantization noise. Features adjustable artifact strength, block size, and color depth. Useful for retro, glitch, or degraded video effects.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-digitalartifacts" alt="Digital Artifacts Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Dust Motes </h4>
<h5><code>[AS] VFX: Dust Motes|AS_VFX_DustMotes.1.fx</code></h5>
Simulates floating dust motes and particles drifting through the scene. Features controls for particle density, size, speed, color, and depth of field. Includes animation and blending options for subtle atmospheric enhancement.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-dustmotes" alt="Dust Motes Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Focused Chaos </h4>
<h5><code>[AS] VFX: Focused Chaos|AS_VFX_FocusedChaos.1.fx</code></h5>
Creates a visually complex and dynamic abstract effect resembling a focused point of chaotic energy or a swirling cosmic vortex. Patterns are generated using 3D Simplex noise and Fractional Brownian Motion (FBM), with colors evolving based on noise patterns and spatial coordinates, animated over time. Features transparent background, customizable animation, artistic controls for swirl/noise/color/alpha, dithering, domain warping, and standard AS-StageFX depth/blending controls.

</td>
<td width="50%"><div style="text-align:center">
<img src="" alt="Focused Chaos Effect" style="max-width:100%;">
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
<img src="https://github.com/user-attachments/assets/placeholder-motiontrails" alt="Motion Trails Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Radial Lens Distortion </h4>
<h5><code>[AS] VFX: Radial Lens Distortion|AS_VFX_RadialLensDistortion.1.fx</code></h5>
Simulates various lens distortions including tangential (rotational) blur, chromatic aberration (tangential or horizontal), and geometric barrel/pincushion distortion. Effects are strongest at the edges and diminish towards a configurable center point. Includes presets for emulating specific lens characteristics, plus global strength and focus falloff controls. Ensures consistent effect visibility regardless of source alpha by controlling alpha during blending.

</td>
<td width="50%"><div style="text-align:center">
<img src="" alt="Radial Lens Distortion Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Radiant Fire </h4>
<h5><code>[AS] VFX: Radiant Fire|AS_VFX_RadiantFire.1.fx</code></h5>
Generates radiant, glowing fire effects with animated flames and customizable color gradients. Features controls for flame shape, speed, intensity, and palette. Ideal for magical, fantasy, or atmospheric visuals.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-radiantfire" alt="Radiant Fire Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Rainy Window </h4>
<h5><code>[AS] VFX: Rainy Window|AS_VFX_RainyWindow.1.fx</code></h5>
Creates the illusion of raindrops and streaks running down a window, with realistic refraction and blur. Features adjustable rain density, drop size, streak speed, and blending. Perfect for moody, cinematic, or weather-themed scenes.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-rainywindow" alt="Rainy Window Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Screen Ring </h4>
<h5><code>[AS] VFX: Screen Ring|AS_VFX_ScreenRing.1.fx</code></h5>
Draws animated rings or circular overlays on the screen. Features controls for ring count, size, thickness, color, and animation speed. Useful for HUDs, overlays, or stylized transitions.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-screenring" alt="Screen Ring Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Sparkle Bloom </h4>
<h5><code>[AS] VFX: Sparkle Bloom|AS_VFX_SparkleBloom.1.fx</code></h5>
Adds sparkling bloom highlights to bright areas, with animated glints and customizable color. Features controls for sparkle density, size, intensity, and animation. Ideal for magical, festive, or dreamy visuals.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-sparklebloom" alt="Sparkle Bloom Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Spectrum Ring </h4>
<h5><code>[AS] VFX: Spectrum Ring|AS_VFX_SpectrumRing.1.fx</code></h5>
Displays an audio spectrum analyzer in a ring format. Features adjustable band count, radius, thickness, color palette, and animation speed. Supports audio reactivity for dynamic, music-driven visuals. Ideal for overlays, music videos, and live performances.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-spectrumring" alt="Spectrum Ring Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Stencil Mask </h4>
<h5><code>[AS] VFX: Stencil Mask|AS_VFX_StencilMask.1.fx</code></h5>
Applies a stencil mask to selectively reveal or hide parts of the scene. Features controls for mask shape, size, position, feathering, and blending. Useful for transitions, overlays, or compositing effects.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-stencilmask" alt="Stencil Mask Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Tilted Grid </h4>
<h5><code>[AS] VFX: Tilted Grid|AS_VFX_TiltedGrid.1.fx</code></h5>
Draws a tilted, animated grid overlay on the scene. Features controls for grid angle, spacing, line thickness, color, and animation speed. Useful for stylized overlays, retro visuals, or compositional guides.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-tiltedgrid" alt="Tilted Grid Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Volumetric Light </h4>
<h5><code>[AS] VFX: Volumetric Light|AS_VFX_VolumetricLight.1.fx</code></h5>
Simulates volumetric light rays (god rays) emanating from a source. Features controls for light position, color, intensity, ray length, and blending. Useful for dramatic, atmospheric, or mystical scene lighting.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-volumetriclight" alt="Volumetric Light Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: VUMeter </h4>
<h5><code>[AS] VFX: VUMeter|AS_VFX_VUMeter.1.fx</code></h5>
Displays a classic VU meter with audio-reactive bars. Features controls for bar count, orientation, color, peak hold, and animation. Ideal for music visualizations, overlays, and live performance feedback.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-vumeter" alt="VUMeter Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Warp Distort </h4>
<h5><code>[AS] VFX: Warp Distort|AS_VFX_WarpDistort.1.fx</code></h5>
Applies animated warp distortion to the scene. Features controls for distortion strength, direction, speed, and blending. Useful for psychedelic, dreamlike, or transition effects.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-warpdistort" alt="Warp Distort Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h4>VFX: Water Surface </h4>
<h5><code>[AS] VFX: Water Surface|AS_VFX_WaterSurface.1.fx</code></h5>
Simulates an animated water surface with dynamic ripples, reflections, and customizable color. Features controls for wave speed, amplitude, direction, and reflection intensity. Useful for aquatic, dreamy, or atmospheric effects.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/placeholder-watersurface" alt="Water Surface Effect" style="max-width:100%;">
</div></td>
</tr>
</table>

---

*For more detailed information about installation, updates, and credits, please refer to the [main README](../README.md). Complete external source attribution is available in [AS_StageFX_Credits.md](../AS_StageFX_Credits.md).*

