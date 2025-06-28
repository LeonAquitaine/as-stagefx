# AS-StageFX Shader Gallery

This gallery provides detailed descriptions and visual examples of the complete AS-StageFX collection, which includes **64 shaders** across four categories: **28 Background (BGX)**, **11 Graphic (GFX)**, **3 Lighting (LFX)**, and **22 Visual (VFX)** effects.

For installation instructions and general information, please refer to the [main README](../README.md).

## Core Library Files (.fxh)

The collection includes these foundation libraries used by all shaders:

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
<h3> </h3>
<h5><code>AS_BGX_PlasmaDance.1.fx</code></h5>

</td>
<td width="50%"><div style="text-align:center">
<img src="" alt=" Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Blue Corona </h3>
<h5><code>AS_BGX_BlueCorona.1.fx</code></h5>
Creates a vibrant, abstract blue corona effect with fluid, dynamic motion. The effect generates hypnotic patterns through iterative mathematical transformations, resulting in organic, plasma-like visuals with a predominantly blue color scheme. Features abstract, organic blue corona patterns; smooth fluid-like animation; customizable iteration count/pattern scale; animation speed/flow controls; intuitive color controls; customizable background color; audio reactivity (multiple targets); depth-aware rendering; and standard position, rotation, scale, and blending options.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/XfKGWV" target="_new">Blue Corona [256 Chars]</a>' by SnoopethDuckDuck<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-bluecorona.gif" alt="Blue Corona Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Constellation </h3>
<h5><code>AS_BGX_Constellation.1.fx</code></h5>
Creates an animated stellar constellation pattern with twinkling stars and connecting lines. Perfect for cosmic, night sky, or abstract network visualizations with a hand-drawn aesthetic. Features dynamic constellation lines with customizable thickness and falloff; twinkling star points with adjustable sparkle properties; procedurally animated line connections; animated color palette with adjustable parameters; audio reactivity for zoom, gradient effects, line brightness, and sparkle magnitude; depth-aware rendering; and standard blend options.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/slfGzf" target="_new">old joseph</a>' by jairoandre<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-constellation.gif" alt="Constellation Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Corridor Travel </h3>
<h5><code>AS_BGX_CorridorTravel.1.fx</code></h5>
Simulates an artistic flight through an abstract, glowing, patterned tunnel. Features multiple samples per pixel for pseudo-DOF and motion blur, and simulates light bounces with artistic reflection logic.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/3sXyRN" target="_new">Corridor Travel</a>' by NuSan<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-corridortravel.gif" alt="Corridor Travel Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Cosmic Kaleidoscope </h3>
<h5><code>AS_BGX_CosmicKaleidoscope.1.fx</code></h5>
Renders a raymarched volumetric fractal resembling a Mandelbox or Mandelbulb. Features Kaleidoscope-like mirroring effect with customizable repetitions, audio reactivity for dynamic parameter adjustments, palette-based coloring system with customizable options, and full rotation, position and depth control for scene integration.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/XlfGRj" target="_new">Star Nest</a>' by Kali<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-cosmickaleidoscope.gif" alt="Cosmic Kaleidoscope Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Digital Brain </h3>
<h5><code>AS_BGX_DigitalBrain.1.fx</code></h5>
Creates an abstract visualization of a 'digital brain' with evolving Voronoi patterns and neural-like connections. The effect simulates an organic electronic network with dynamic light paths that mimic neural activity in a stylized, technological manner. Features dynamic Voronoi-based pattern generation, animated 'electrical' pulses simulating synaptic activity, color modulation based on noise texture for organic variation, advanced vignette controls, pre-optimized pattern stretching, classic and texture-based coloring options, customizable animation and pattern controls, and depth-aware rendering with standard blending.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/4sl3Dr" target="_new">Digital Brain</a>' by srtuss<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-digitalbrain.gif" alt="Digital Brain Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Fluorescent </h3>
<h5><code>AS_BGX_Fluorescent.1.fx</code></h5>
Creates a vibrant neon fluorescent background effect that simulates the glow and intensity of fluorescent lighting. Perfect for creating retro, cyberpunk, or futuristic atmospheres with customizable colors and intensity. Features raymarched volumetric fluorescent effect with depth, dynamic color shifting with RGB phase controls, animated pulsing and flowing patterns, audio reactivity for rhythm-synchronized lighting, standard stage controls for positioning and depth, customizable iteration count for quality vs performance balance, and blend mode controls for integration with existing scenes.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/WcGGDd" target="_new">Fluorescent [292]</a>' by Xor<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-fluorescent.gif" alt="Fluorescent Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Golden Clockwork </h3>
<h5><code>AS_BGX_GoldenClockwork.1.fx</code></h5>
Renders a mesmerizing and intricate animated background effect reminiscent of golden clockwork mechanisms or Apollonian gasket-like fractal patterns. The effect features complex, evolving geometric designs with a characteristic golden color palette. Features procedurally generated Apollonian fractal patterns, dynamic animation driven by time, a golden color scheme with lighting and shading effects, depth-like progression through fractal layers, kaleidoscopic and mirroring options for pattern variation and resolution-independent rendering.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/WlcfRS" target="_new">Golden apollian</a>' by mrange<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-goldenclockwork.gif" alt="Golden Clockwork Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Hologram </h3>
<h5><code>AS_BGX_Hologram.1.fx</code></h5>
Creates a dynamic, holographic plasma background with shifting rainbow colors and a plasma distortion effect that responds to a user-controlled viewpoint. Features dynamic plasma field with configurable scale and distortion; shifting spectral rainbow colors; user-controlled viewpoint for interactive effects; and full AS-StageFX integration for positioning, depth masking, and blending.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/NlycDG" target="_new">Hologram stars</a>' by hypothete<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="" alt="Hologram Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Kaleidoscope </h3>
<h5><code>AS_BGX_Kaleidoscope.1.fx</code></h5>
Creates a vibrant, ever-evolving fractal kaleidoscope pattern with animated tendrils. Perfect for psychedelic, cosmic, or abstract backgrounds with a hypnotic quality. Features adjustable kaleidoscope mirror count for symmetry control; fractal zoom and pattern rotation with animation controls; customizable wave parameters and color palette; audio reactivity for zoom, wave intensity, and pattern rotation; depth-aware rendering; and standard blend options.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/ddsyDN" target="_new">Kaleidoscope</a>' by Kanduvisla<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-kaleidoscope.gif" alt="Kaleidoscope Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Light Ripples </h3>
<h5><code>AS_BGX_LightRipples.1.fx</code></h5>
Creates a mesmerizing, rippling kaleidoscopic light pattern effect. Suitable as a dynamic background or overlay. Includes controls for animation, distortion (amplitude, frequencies), color palettes with cycling, audio reactivity, depth-aware rendering, adjustable rotation, and standard blending options.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/XsXXDn" target="_new">Creation by Silexars</a>' by Danguafer/Danilo Guanabara<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-lightripples.gif" alt="Light Ripples Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Light Wall </h3>
<h5><code>AS_BGX_LightWall.1.fx</code></h5>
This shader renders a seamless, soft, overlapping grid of light panels with various built-in patterns. Perfect for creating dance club and concert backdrops with fully customizable colors, patterns, and audio reactivity. Features 14 built-in patterns, audio-reactive panels that pulse to music, customizable color palettes with 9 presets and custom options, light burst effects and cross beams for dramatic highlighting, 3D perspective with tilt, pitch, and roll controls, and others.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-lightwall.gif" alt="Light Wall Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Liquid Chrome </h3>
<h5><code>AS_BGX_LiquidChrome.1.fx</code></h5>
Creates dynamic, flowing psychedelic patterns reminiscent of liquid metal or chrome. This shader iteratively distorts screen coordinates, creating complex, flowing patterns with optional vertical stripe overlays for additional visual texture.

<br><br>
Based on '<a href="https://neort.io/art/bkm813c3p9f7drq1j86g" target="_new">Liquid Chrome</a>' by iamsaitam<br>


</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-liquidchrome.gif" alt="Liquid Chrome Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Log Spirals </h3>
<h5><code>AS_BGX_LogSpirals.1.fx</code></h5>
Creates an organic spiral pattern based on logarithmic growth with animated spheres along the spiral arms. Features precise control over spiral expansion rate and animation, customizable sphere size with fade effects and specular highlights, color palette options with hue cycling and ambient glow, audio reactivity for multiple parameters (animation speed, rotation, arm twist, sphere size, brightness), and standard position/rotation/scale controls for scene integration.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/msGXRD" target="_new">Logarithmic spiral of spheres</a>' by mrange<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-logspirals.gif" alt="Log Spirals Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Melt Wave </h3>
<h5><code>AS_BGX_MeltWave.1.fx</code></h5>
Creates a flowing, warping psychedelic effect inspired by 1970s visual aesthetics. Generates mesmerizing colored patterns with sine-based distortions that evolve over time. Features adjustable zoom/intensity, a palette system (mathematical or preset colors), dynamic time-based animation with keyframe support, audio reactivity mappable to different parameters, and resolution-independent transformation with position/rotation controls.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/XsX3zl" target="_new">70s Melt</a>' by tomorrowevening<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-meltwave.gif" alt="Melt Wave Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Misty Grid </h3>
<h5><code>AS_BGX_MistyGrid.1.fx</code></h5>
Creates an abstract fractal-based grid background with a misty, ethereal appearance using raymarching techniques. Features dynamic fractal-based grid environment, customizable colors with palette system, folding and repetition for complex patterns, camera movement simulation with smooth rotations, audio reactivity affecting multiple parameters (fractal scale, folding intensity, saturation, brightness, camera zoom, animation speed), and standard position/rotation/scale controls.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/wl2Szd" target="_new">[twitch] Misty Grid</a>' by NuSan<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-mistygrid.gif" alt="Misty Grid Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Past Racer </h3>
<h5><code>AS_BGX_PastRacer.1.fx</code></h5>
A ray marching shader that generates one of two selectable abstract procedural scenes. Features domain repetition, custom transformations, and pseudo-random patterns. Scene geometry and flare effects can be reactive to audio frequency bands.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/tsBBzG" target="_new">Outline 2020 Freestyle Live code</a>' by NuSan<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-pastracer.gif" alt="Past Racer Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Plasma Flow </h3>
<h5><code>AS_BGX_PlasmaFlow.1.fx</code></h5>
Sophisticated, gentle, and flexible plasma effect for groovy, atmospheric visuals. Generates smooth, swirling, organic patterns with customizable color gradients (2-4 user-defined colors) and strong audio reactivity. Features procedural plasma/noise with domain warping for fluid motion, controls for speed, scale, complexity, stretch, and warp, audio-reactive modulation of movement, color, brightness, and turbulence, plus standard blend modes and debug views. Ideal for music video backgrounds and overlays.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/slSBDd" target="_new">Plasma Storm</a>' by fuzzmoon<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-plasmaflow.gif" alt="Plasma Flow Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Protean Clouds </h3>
<h5><code>AS_BGX_ProteanClouds.1.fx</code></h5>
Renders dynamic, evolving volumetric clouds through raymarching techniques. Creates an immersive, abstract cloudscape with dynamic color variations and realistic lighting. Features high-quality volumetric cloud formations, customizable cloud density, shape, and detail, dynamic camera movement with adjustable path and sway, sophisticated internal lighting and self-shadowing, color palette system with customizable parameters, audio reactivity for multiple cloud parameters, and resolution-independent rendering with precise position controls.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/3l23Rh" target="_new">Protean clouds</a>' by nimitz<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-proteanclouds.gif" alt="Protean Clouds Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Quadtree Truchet </h3>
<h5><code>AS_BGX_QuadtreeTruchet.1.fx</code></h5>
Creates a sophisticated multiscale recursive Truchet pattern with hierarchical tile overlaps across 3 levels. Generates complex geometric designs through quadtree subdivision and probabilistic tile placement. Features quadtree-based recursive pattern generation, overlapping tile system with collision prevention, full AS palette system support with multiple color modes, Art Deco style with line tiles and weave effects, animated rotation and panning, audio reactivity for scale/rotation/seed/density, stage positioning controls, and debug visualization of the underlying quadtree structure.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/4t3BW4" target="_new">Quadtree Truchet</a>' by Shane<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-quadtreetruchet.gif" alt="Quadtree Truchet Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Raymarched Chain </h3>
<h5><code>AS_BGX_RaymarchedChain.1.fx</code></h5>
Renders a raymarched scene featuring an animated, endlessly twisting chain composed of interconnected torus shapes. The chain follows a procedurally defined path, and its segments rotate and evolve over time, creating a mesmerizing, complex visual. Features raymarched chain of torus shapes with procedural path animation, customizable animation speed and chain geometry, dynamic coloring based on raymarching depth and iteration, camera orientation controls, and standard AS-StageFX blending controls.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/ctSfRV" target="_new">Corrente</a>' by Elsio<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-raymarchedchain.gif" alt="Raymarched Chain Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Stained Lights </h3>
<h5><code>AS_BGX_StainedLights.1.fx</code></h5>
Creates dynamic and colorful patterns reminiscent of stained glass illuminated by shifting light, with multiple blurred layers enhancing depth and visual complexity. Generates layers of distorted, cell-like structures with vibrant, evolving colors and subtle edge highlighting, overlaid with softer, floating elements. Suitable for abstract backgrounds, energy fields, or mystical visuals.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/WlsSzM" target="_new">Stained Lights</a>' by 104<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-stainedlights.gif" alt="Stained Lights Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Sunset Clouds </h3>
<h5><code>AS_BGX_SunsetClouds.1.fx</code></h5>
Renders an animated scene of clouds at sunset using raymarching to create volumetric cloud effects with dynamic lighting and turbulence. Features raymarched volumetric clouds, animated turbulence effect, dynamic sunset coloring that changes over time, and tunable parameters for iterations, animation speed, and visual details.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/wXjSRt" target="_new">Sunset [280]</a>' by Xor<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-sunsetclouds.gif" alt="Sunset Clouds Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Time Crystal </h3>
<h5><code>AS_BGX_TimeCrystal.1.fx</code></h5>
Creates a hypnotic, crystalline fractal structure with dynamic animation and color cycling. Generates patterns reminiscent of crystalline structures or gems with depth and dimension. Features fractal crystal-like patterns (customizable iterations), dynamic animation (controllable speed), adjustable pattern density/detail, customizable color palettes with cycling, audio reactivity for pattern dynamics/colors, depth-aware rendering with standard blending, and adjustable position/rotation controls. Suitable for mystic or sci-fi backgrounds, portals, or energy fields.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/lcl3z2" target="_new">Time Crystal</a>' by raphaeljmu<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-timecrystal.gif" alt="Time Crystal Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Vortex </h3>
<h5><code>AS_BGX_Vortex.1.fx</code></h5>
Creates a psychedelic swirling vortex pattern. The effect is animated and features controls for color, animation speed, swirl characteristics, and brightness. Suitable as a dynamic background. Features animated vortex with customizable speed, palette-based coloring, swirl intensity/frequency/sharpness, brightness falloff, and standard AS-StageFX blending and positioning.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/3fKGRd" target="_new">Vortex__ </a>' by LonkDong<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-vortex.gif" alt="Vortex Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Wavy Squares </h3>
<h5><code>AS_BGX_WavySquares.1.fx</code></h5>
Creates a hypnotic pattern of wavy, animated square tiles that shift and transform. The squares follow a wave-like motion and feature dynamic size changes, creating a flowing, organic grid pattern. Features wavy, undulating square tiling; customizable wave parameters (amplitude, frequency, speed); variable tile size/scaling; shape smoothness/box roundness controls; audio reactivity (multiple targets); depth-aware rendering; adjustable rotation; and standard position, scale, and blending options.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/NdfBzn" target="_new">Square Tiling Example E</a>' by SnoopethDuckDuck<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-wavysquares.gif" alt="Wavy Squares Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Wavy Squiggles </h3>
<h5><code>AS_BGX_WavySquiggles.1.fx</code></h5>
Creates a mesmerizing pattern of adaptive wavy lines that follow a mouse or fixed position. The lines create intricate patterns that look like dynamic squiggly lines arranged around a central point, with rotation applied based on direction. Features position-reactive wavy line patterns; customizable line parameters (rotation influence, thickness, distance, smoothness); optional color palettes (hue, saturation, value control); pattern displacement for off-center effects; audio reactivity (multiple targets); depth-aware rendering; adjustable rotation; and standard position, scale, and blending options.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/7sBfDD" target="_new">Interactive 2.5D Squiggles</a>' by SnoopethDuckDuck<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-wavysquiggles.gif" alt="Wavy Squiggles Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Zippy Zaps </h3>
<h5><code>AS_BGX_ZippyZaps.1.fx</code></h5>
Creates dynamic electric arcs and lightning patterns for a striking background effect. This effect generates procedural electric-like patterns that appear behind objects in the scene, creating an energetic, dynamic background with complete control over appearance and animation. Features animated electric/lightning arcs with procedural generation; fully customizable colors, intensity, and animation parameters; resolution-independent rendering; audio reactivity; depth-aware rendering; and adjustable rotation/positioning in 3D space.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/XXyGzh" target="_new">Zippy Zaps</a>' by SnoopethDuckDuck<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-zippyzaps.gif" alt="Zippy Zaps Effect" style="max-width:100%;">
</div></td>
</tr>
</table>

---

## Graphic Effects (GFX)

<table>
<tr>
<td width="50%">
<h3>Aspect Ratio </h3>
<h5><code>AS_GFX_AspectRatio.1.fx</code></h5>
A versatile aspect ratio framing tool designed to help position subjects for social media posts, photography, and video composition. Features preset aspect ratios for common social media and photography formats (1:1, 16:9, 4:5, etc.), custom aspect ratio input, adjustable clipped area color and opacity, optional composition guides (rule of thirds, golden ratio, center lines), horizontal/vertical alignment controls, and adjustable border appearance. Perfect for precise subject positioning and consistent framing across platforms.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-aspectratio.gif" alt="Aspect Ratio Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Audio Direction </h3>
<h5><code>AS_GFX_AudioDirection.1.fx</code></h5>
Displays animated arrows or indicators that visualize the directionality of audio sources in real time. Features customizable arrow count, size, color, and animation speed. Supports audio reactivity for direction, magnitude, and color. Useful for music visualizations, DJ overlays, or any scene where audio direction feedback is desired.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-audiodirection.gif" alt="Audio Direction Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Brush Stroke </h3>
<h5><code>AS_GFX_BrushStroke.1.fx</code></h5>
Applies painterly brush stroke textures to the scene, simulating layered paint effects. Features customizable brush size, direction, density, and color blending. Includes animation controls for evolving brush patterns and supports palette-based colorization. Ideal for artistic transformations and stylized overlays.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-brushstroke.gif" alt="Brush Stroke Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Cinematic Diffusion </h3>
<h5><code>AS_GFX_CinematicDiffusion.1.fx</code></h5>
A high-quality cinematic diffusion/bloom filter that replicates classic film diffusion looks. Features 8 built-in presets (Pro-Mist, Hollywood Black Magic, etc.) and a fully customizable mode. Multi-pass downsampling ensures smooth, natural glows. Ideal for virtual photography and cinematic shots.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-cinematicdiffusion.gif" alt="Cinematic Diffusion Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Cosmic Glow </h3>
<h5><code>AS_GFX_CosmicGlow.1.fx</code></h5>
Renders an abstract, glowing overlay effect composed of hundreds of animated, rotating arcs arranged in concentric rings. Features animated, rotating arcs with customizable density and count; perspective distortion with axis inclination for realistic 3D viewing angles; two coloring modes: original mathematical formula or standard AS-StageFX palettes; audio reactivity targeting Ring Brightness, Arc Intensity, and Ring Count for dynamic effects; and full integration with AS-StageFX controls for animation, positioning, depth, and blending.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/ls3XW8" target="_new">Cosmic</a>' by XorDev<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="" alt="Cosmic Glow Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Depth Hologram </h3>
<h5><code>AS_GFX_Hologram.1.fx</code></h5>
This shader transforms the entire scene's depth buffer into a holographic field. Unlike a sticker, this effect uses the 3D information of the scene as the source for holographic parallax, color shifts, and lighting. Features uses scene's depth buffer as holographic data source; wavy, procedural noise pattern warped by scene geometry; shifting, spectral rainbow colors based on depth and view angle; 'Hue Compression' that adds more color detail to foreground objects with exponential falloff; optional background darkening to make the hologram pop; support for color palettes to create themed holographic effects; and sophisticated depth-based distortion calculations.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/MdBSWV" target="_new">Protection hologram</a>' by Alexander Alekseev aka TDM<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="" alt="Depth Hologram Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Focus Frame </h3>
<h5><code>AS_GFX_FocusFrame.1.fx</code></h5>
This shader creates a "focus frame" effect by defining a clear, centered rectangular area with a soft, feathered edge. The frame's aspect ratio is fully adjustable. The surrounding space is rendered as a blurred, zoomed, and dimmed version of the background, ideal for creating cinematic compositions. Features a fully adjustable central frame with controls for size and aspect ratio, soft feathered edges for smooth blending between focus area and background, high-quality performant two-pass Gaussian blur for the background, intuitive controls for composition and background effects, depth-aware rendering with standard blending, and debug visualization for frame boundaries.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-focusframe.gif" alt="Focus Frame Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Hand Drawing </h3>
<h5><code>AS_GFX_HandDrawing.1.fx</code></h5>
Transforms your scene into a stylized hand-drawn sketch or technical ink illustration with distinct linework and cross-hatching patterns. Features sophisticated line generation with customizable stroke directions and length, textured fills based on original image colors with noise-based variation, animated 'wobble' effect for an authentic hand-drawn feel, optional paper-like background pattern, depth-aware rendering with standard blending, and comprehensive controls for fine-tuning every aspect of the effect. Perfect for artistic transformations, comic/manga styles, or technical illustrations.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/XtVGD1" target="_new">notebook drawings</a>' by Flockaroo<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://github.com/user-attachments/assets/4074ac6b-a385-4e0f-9d9a-c4d5dd0117cd" alt="Hand Drawing Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>MultiLayer Halftone </h3>
<h5><code>AS_GFX_MultiLayerHalftone.1.fx</code></h5>
Creates a highly customizable multi-layer halftone effect with support for up to four independent layers. Each layer can use different pattern types (dots, lines, crosshatch), isolation methods (brightness, RGB, hue, depth), colors, thresholds, scales, densities, and angles. Features layer blending with transparency support.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-multilayerhalftone.gif" alt="MultiLayer Halftone Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Tilt-Shift </h3>
<h5><code>AS_GFX_TiltShift.1.fx</code></h5>
This shader simulates a realistic camera lens by applying a high-quality, depth-aware blur. Unlike simple screen-space effects, this shader uses the scene's depth buffer to allow for precise focusing. You can select a focal point in the scene's depth, and objects closer or further away will be smoothly blurred, creating a beautiful and realistic "bokeh" or "tilt-shift" effect. Features depth-based focusing allowing precise scene depth selection, focus zone control to define the size of the in-focus area (depth of field), high-quality performant two-pass Gaussian blur driven by depth calculation, depth-aware edge detection that correctly handles foreground and background blur bleeding for realistic effects, interactive debug mode showing focus line when left mouse button is held, and standard blend mode controls for integration.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-tiltshift.gif" alt="Tilt-Shift Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Vignette Plus </h3>
<h5><code>AS_GFX_VignettePlus.1.fx</code></h5>
A vignette shader that provides multiple visual styles and customizable pattern options, creating directional, controllable vignette effects for stage compositions and scene framing. Perfect for adding mood, focus, or stylistic elements. Features four distinct visual styles (Smooth Gradient, Duotone Circles, Directional Lines perpendicular and parallel), multiple mirroring options (none, edge-based, center-based), precise control over effect coverage with start/end falloff points, and much more. Optimized for performance across various resolutions.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/XfjyWG" target="_new">Hexagonal Wipe</a>' by blandprix<br>

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-vignetteplus.gif" alt="Vignette Plus Effect" style="max-width:100%;">
</div></td>
</tr>
</table>

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
<h3> </h3>
<h5><code>AS_VFX_VolumetricFog.1.fx</code></h5>

</td>
<td width="50%"><div style="text-align:center">
<img src="" alt=" Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Boom Sticker </h3>
<h5><code>AS_VFX_BoomSticker.1.fx</code></h5>
Displays a texture overlay ('sticker') with controls for placement, scale, rotation, and audio reactivity. Features customizable depth masking and support for custom textures. Ideal for adding dynamic, music-responsive overlays.

<br><br>
Based on '<a href="https://github.com/Otakumouse/stormshade/blob/master/v4.X/reshade-shaders/Shader%20Library/Recommended/StageDepth.fx" target="_new">StageDepth.fx</a>' by Marot Satil


</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-boomsticker.gif" alt="Boom Sticker Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Circular Spectrum </h3>
<h5><code>AS_VFX_CircularSpectrum.1.fx</code></h5>
Visualizes audio frequencies as a circular spectrum analyzer. Features adjustable band count, radius, thickness, color palette, and animation speed. Supports audio reactivity for dynamic, music-driven visuals. Ideal for overlays, music videos, and live performances.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/tcyGW1" target="_new">Circular audio visualizer</a>' by AIandDesign

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-circularspectrum.gif" alt="Circular Spectrum Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Clair Obscur </h3>
<h5><code>AS_VFX_ClairObscur.1.fx</code></h5>
Simulates dramatic chiaroscuro (light-dark) lighting, emphasizing strong contrast and stylized shadows. Features controls for light direction, intensity, shadow softness, and color tint. Useful for artistic, cinematic, or moody scene transformations.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/ttcBRs" target="_new">[RGR] Hearts</a>' by deeplo

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-clairobscur.gif" alt="Clair Obscur Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Color Balancer </h3>
<h5><code>AS_VFX_ColorBalancer.1.fx</code></h5>
Provides precise color grading by adjusting the balance of shadows, midtones, and highlights independently. Features controls for lift, gamma, gain, and color wheels. Useful for creative color correction and stylized looks.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-colorbalancer.gif" alt="Color Balancer Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Digital Artifacts </h3>
<h5><code>AS_VFX_DigitalArtifacts.1.fx</code></h5>
Applies digital compression artifacts such as blockiness, color banding, and quantization noise. Features adjustable artifact strength, block size, and color depth. Useful for retro, glitch, or degraded video effects.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-digitalartifacts.gif" alt="Digital Artifacts Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Dust Motes </h3>
<h5><code>AS_VFX_DustMotes.1.fx</code></h5>
Simulates floating dust motes and particles drifting through the scene. Features controls for particle density, size, speed, color, and depth of field. Includes animation and blending options for subtle atmospheric enhancement.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-dustmotes.gif" alt="Dust Motes Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Focused Chaos </h3>
<h5><code>AS_VFX_FocusedChaos.1.fx</code></h5>
Creates a visually complex and dynamic abstract effect resembling a focused point of chaotic energy or a swirling cosmic vortex. Patterns are generated using 3D Simplex noise and Fractional Brownian Motion (FBM), with colors evolving based on noise patterns and spatial coordinates, animated over time. Features transparent background, customizable animation, artistic controls for swirl/noise/color/alpha, dithering, domain warping, and standard AS-StageFX depth/blending controls.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/lcfyDj" target="_new">BlackHole (swirl, portal)</a>' by misterprada

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-focusedchaos.gif" alt="Focused Chaos Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Motion Focus </h3>
<h5><code>AS_VFX_MotionFocus.1.fx</code></h5>
Analyzes inter-frame motion differences to dynamically adjust the viewport, zooming towards and centering on areas of detected movement. Uses a multi-pass approach to capture frames, detect motion, analyze motion distribution in quadrants, and apply a corresponding camera transformation with motion-centered zoom. Features multi-pass motion analysis, temporal smoothing, adaptive decay, quadrant-based aggregation, dynamic zoom/focus, and debug visualization.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-motionfocus.gif" alt="Motion Focus Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Motion Trails </h3>
<h5><code>AS_VFX_MotionTrails.1.fx</code></h5>
Applies trailing motion blur to moving objects or the whole scene. Features adjustable trail length, direction, fade, and blending. Useful for simulating speed, action, or ghosting effects in dynamic scenes.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-motiontrails.gif" alt="Motion Trails Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Radial Lens Distortion </h3>
<h5><code>AS_VFX_RadialLensDistortion.1.fx</code></h5>
Simulates various lens distortions including tangential (rotational) blur, chromatic aberration (tangential or horizontal), and geometric barrel/pincushion distortion. Effects are strongest at the edges and diminish towards a configurable center point. Includes presets for emulating specific lens characteristics, plus global strength and focus falloff controls. Ensures consistent effect visibility regardless of source alpha by controlling alpha during blending.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-radiallensdistortion.gif" alt="Radial Lens Distortion Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Radiant Fire </h3>
<h5><code>AS_VFX_RadiantFire.1.fx</code></h5>
Generates radiant, glowing fire effects with animated flames and customizable color gradients. Features controls for flame shape, speed, intensity, and palette. Ideal for magical, fantasy, or atmospheric visuals.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/4ttGWM" target="_new">301's Fire Shader - Remix 3</a>' by mu6k

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-radiantfire.gif" alt="Radiant Fire Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Rainy Window </h3>
<h5><code>AS_VFX_RainyWindow.1.fx</code></h5>
Creates the illusion of raindrops and streaks running down a window, with realistic refraction and blur. Features adjustable rain density, drop size, streak speed, and blending. Perfect for moody, cinematic, or weather-themed scenes.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/ltffzl" target="_new">Heartfelt</a>' by Martijn Steinrucken (BigWings)

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-rainywindow.gif" alt="Rainy Window Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Screen Ring </h3>
<h5><code>AS_VFX_ScreenRing.1.fx</code></h5>
Draws animated rings or circular overlays on the screen. Features controls for ring count, size, thickness, color, and animation speed. Useful for HUDs, overlays, or stylized transitions.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-screenring.gif" alt="Screen Ring Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Sparkle Bloom </h3>
<h5><code>AS_VFX_SparkleBloom.1.fx</code></h5>
Adds sparkling bloom highlights to bright areas, with animated glints and customizable color. Features controls for sparkle density, size, intensity, and animation. Ideal for magical, festive, or dreamy visuals.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-sparklebloom.gif" alt="Sparkle Bloom Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Spectrum Ring </h3>
<h5><code>AS_VFX_SpectrumRing.1.fx</code></h5>
Displays an audio spectrum analyzer in a ring format. Features adjustable band count, radius, thickness, color palette, and animation speed. Supports audio reactivity for dynamic, music-driven visuals. Ideal for overlays, music videos, and live performances.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-spectrumring.gif" alt="Spectrum Ring Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Stencil Mask </h3>
<h5><code>AS_VFX_StencilMask.1.fx</code></h5>
Applies a stencil mask to selectively reveal or hide parts of the scene. Features controls for mask shape, size, position, feathering, and blending. Useful for transitions, overlays, or compositing effects.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-stencilmask.gif" alt="Stencil Mask Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Tilted Grid </h3>
<h5><code>AS_VFX_TiltedGrid.1.fx</code></h5>
Draws a tilted, animated grid overlay on the scene. Features controls for grid angle, spacing, line thickness, color, and animation speed. Useful for stylized overlays, retro visuals, or compositional guides.

<br><br>
Based on '<a href="https://www.youtube.com/watch?v=Tfj6RDqXEHM" target="_new">Godot 4: Tilted Grid Effect Tutorial</a>' by FencerDevLog


</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-tiltedgrid.gif" alt="Tilted Grid Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Volumetric Light </h3>
<h5><code>AS_VFX_VolumetricLight.1.fx</code></h5>
Simulates volumetric light rays (god rays) emanating from a source. Features controls for light position, color, intensity, ray length, and blending. Useful for dramatic, atmospheric, or mystical scene lighting.

<br><br>
Based on '<a href="https://www.shadertoy.com/view/wftXzr" target="_new">fake volumetric 2d light wip</a>' by int_45h

<strong>License:</strong> CC Share-Alike Non-Commercial <span style="color:#888;font-size:90%">()</span>
</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-volumetriclight.gif" alt="Volumetric Light Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>VUMeter </h3>
<h5><code>AS_VFX_VUMeter.1.fx</code></h5>
Displays a classic VU meter with audio-reactive bars. Features controls for bar count, orientation, color, peak hold, and animation. Ideal for music visualizations, overlays, and live performance feedback.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-vumeter.gif" alt="VUMeter Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Warp Distort </h3>
<h5><code>AS_VFX_WarpDistort.1.fx</code></h5>
Applies animated warp distortion to the scene. Features controls for distortion strength, direction, speed, and blending. Useful for psychedelic, dreamlike, or transition effects.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-Warp.gif" alt="Warp Distort Effect" style="max-width:100%;">
</div></td>
</tr>
<tr>
<td width="50%">
<h3>Water Surface </h3>
<h5><code>AS_VFX_WaterSurface.1.fx</code></h5>
Simulates an animated water surface with dynamic ripples, reflections, and customizable color. Features controls for wave speed, amplitude, direction, and reflection intensity. Useful for aquatic, dreamy, or atmospheric effects.

</td>
<td width="50%"><div style="text-align:center">
<img src="https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img/as-stagefx-watersurface.gif" alt="Water Surface Effect" style="max-width:100%;">
</div></td>
</tr>
</table>

---

*For more detailed information about installation, updates, and credits, please refer to the [main README](../README.md). Complete external source attribution is available in [AS_StageFX_Credits.md](../AS_StageFX_Credits.md).*

