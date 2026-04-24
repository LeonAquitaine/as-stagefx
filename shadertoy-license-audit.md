# AS-StageFX Source License Audit

**Captured at**: 2026-04-24T13:17:30Z
**Captured via**: Claude Cowork (attached browser session)
**Total sources audited**: 38
**Audit scope**: original-source license discovery for AS-StageFX ported shaders

## Legend

- `detected_license`: the license as stated by the original author on the source page.
  - Use the canonical short form where possible: `CC0-1.0`, `CC-BY-4.0`, `CC-BY-NC-4.0`, `CC-BY-NC-SA-3.0`, `CC-BY-NC-SA-4.0`, `CC-BY-SA-4.0`, `MIT`, `Apache-2.0`, `BSD-3-Clause`, `GPL-3.0`, `all-rights-reserved`, `proprietary`, `unknown`.
  - If the author made no license statement, use `HOST_DEFAULT` and fill `host_default_applied` accordingly.
- `declaration_source`: where the license info came from — `author-description`, `inline-comment`, `host-default`, `repo-license-file`, `none`.
- `status`: `ok` | `source_404` | `source_private` | `source_unreachable` | `review_required`.

## Auditor caveats

1. Shadertoy descriptions were extracted verbatim from the `#shaderDescription` / `#shaderInfo` DOM elements rendered by the live page (not from meta tags or the shader code editor). The `info` panel that precedes the description includes the rendered author username and publish date, also copied verbatim.
2. For each Shadertoy source the description panel was scanned for the license keywords listed in the audit brief. Unless this audit explicitly notes an inline-code license statement (see entry 30), the shader's GLSL source code was **not** exhaustively inspected; an inline licence in code could still exist and would supersede the Shadertoy host default. Reviewers wanting a belt-and-braces audit should re-scan the GLSL of each shader for `License`, `Licence`, `CC`, `CC0`, etc., in the shader's `Common`/`Image` pass source.
3. Shadertoy's terms (https://www.shadertoy.com/terms, §"Shader License") state that shaders posted without an explicit author license fall under **CC BY-NC-SA 3.0 Unported** by default; this is the value recorded in `host_default_applied` for silent entries.

## Summary table

| # | Shader file | Host | Detected license | Declaration source | Status |
|---|---|---|---|---|---|
| 1 | AS_BGX_BlueCorona.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 2 | AS_BGX_Constellation.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 3 | AS_BGX_CorridorTravel.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 4 | AS_BGX_CosmicKaleidoscope.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 5 | AS_BGX_DigitalBrain.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 6 | AS_BGX_Fluorescent.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 7 | AS_BGX_GoldenClockwork.1.fx | shadertoy | CC0-1.0 | author-description | ok |
| 8 | AS_BGX_Hologram.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 9 | AS_BGX_Kaleidoscope.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 10 | AS_BGX_LightRipples.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 11 | AS_BGX_LogSpirals.1.fx | shadertoy | CC0-1.0 | author-description | ok |
| 12 | AS_BGX_MeltWave.1.fx | shadertoy | unknown | author-description | review_required |
| 13 | AS_BGX_MistyGrid.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 14 | AS_BGX_PastRacer.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 15 | AS_BGX_PlasmaFlow.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 16 | AS_BGX_ProteanClouds.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 17 | AS_BGX_QuadtreeTruchet.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 18 | AS_BGX_RaymarchedChain.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 19 | AS_BGX_StainedLights.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 20 | AS_BGX_SunsetClouds.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 21 | AS_BGX_TimeCrystal.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 22 | AS_BGX_Vortex.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 23 | AS_BGX_WavySquares.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 24 | AS_BGX_WavySquiggles.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 25 | AS_BGX_ZippyZaps.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 26 | AS_VFX_CircularSpectrum.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 27 | AS_VFX_ClairObscur.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 28 | AS_VFX_FocusedChaos.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 29 | AS_VFX_RadiantFire.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 30 | AS_VFX_RainyWindow.1.fx | shadertoy | CC-BY-NC-SA-3.0 | inline-comment | ok |
| 31 | AS_VFX_VolumetricLight.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 32 | AS_GFX_CosmicGlow.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 33 | AS_GFX_Hologram.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 34 | AS_GFX_HandDrawing.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 35 | AS_GFX_VignettePlus.1.fx | shadertoy | HOST_DEFAULT (CC-BY-NC-SA-3.0) | host-default | ok |
| 36 | AS_BGX_LiquidChrome.1.fx | neort.io | unknown | none | review_required |
| 37 | AS_VFX_BoomSticker.1.fx | github.com | BSD-2-Clause | inline-comment | review_required |
| 38 | AS_VFX_TiltedGrid.1.fx | youtube.com | null | none | source_unreachable |

## Per-source detail

### 1. AS_BGX_BlueCorona.1.fx

- **Source URL**: https://www.shadertoy.com/view/XfKGWV
- **Host**: shadertoy.com
- **Page title (as rendered)**: Blue Corona [256 Chars]
- **Author username (as rendered)**: SnoopethDuckDuck
- **Publish / last-update date (as rendered)**: 2024-04-16
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > golfing welcome 🌟
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: none

### 2. AS_BGX_Constellation.1.fx

- **Source URL**: https://www.shadertoy.com/view/slfGzf
- **Host**: shadertoy.com
- **Page title (as rendered)**: old joseph by jairoandre
- **Author username (as rendered)**: jairoandre
- **Publish / last-update date (as rendered)**: 2021-06-01
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > Another tutorial based on the art of code videos. Credits to BigWings
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: Shadertoy page title ("old joseph by jairoandre") differs from the AS-StageFX file name ("Constellation"). Reviewer may want to confirm this is the correct upstream source.

### 3. AS_BGX_CorridorTravel.1.fx

- **Source URL**: https://www.shadertoy.com/view/3sXyRN
- **Host**: shadertoy.com
- **Page title (as rendered)**: Corridor Travel
- **Author username (as rendered)**: NuSan
- **Publish / last-update date (as rendered)**: 2020-03-14
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > Inspired by "past racer" by jetlab
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: none

### 4. AS_BGX_CosmicKaleidoscope.1.fx

- **Source URL**: https://www.shadertoy.com/view/XlfGRj
- **Host**: shadertoy.com
- **Page title (as rendered)**: Star Nest
- **Author username (as rendered)**: Kali
- **Publish / last-update date (as rendered)**: 2013-06-17
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > 3D kaliset fractal - volumetric rendering and some tricks. I put the params on top to play with. Mouse enabled to explore different regions. 
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: Upstream title is "Star Nest"; AS-StageFX filename is "CosmicKaleidoscope".

### 5. AS_BGX_DigitalBrain.1.fx

- **Source URL**: https://www.shadertoy.com/view/4sl3Dr
- **Host**: shadertoy.com
- **Page title (as rendered)**: Digital Brain
- **Author username (as rendered)**: srtuss
- **Publish / last-update date (as rendered)**: 2013-06-12
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > Some experiments with voronoi noise. I found many cool looking formulas, here is one of them. (Also try fullscreen!)
  > *Now with colors.
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: none

### 6. AS_BGX_Fluorescent.1.fx

- **Source URL**: https://www.shadertoy.com/view/WcGGDd
- **Host**: shadertoy.com
- **Page title (as rendered)**: Fluorescent [292]
- **Author username (as rendered)**: Xor
- **Publish / last-update date (as rendered)**: 2025-05-30
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > More fun with glowy shaders
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: none

### 7. AS_BGX_GoldenClockwork.1.fx

- **Source URL**: https://www.shadertoy.com/view/WlcfRS
- **Host**: shadertoy.com
- **Page title (as rendered)**: Golden apollian
- **Author username (as rendered)**: mrange
- **Publish / last-update date (as rendered)**: 2021-02-09
- **Detected license**: CC0-1.0
- **Host default applied**: null
- **Declaration source**: author-description
- **Evidence (verbatim description excerpt)**:
  > Licence CC0: Golden apollian
  > More late night coding
- **Status**: ok
- **Audit notes**: Upstream title is "Golden apollian"; AS-StageFX filename is "GoldenClockwork". Author spells it "Licence" (British).

### 8. AS_BGX_Hologram.1.fx

- **Source URL**: https://www.shadertoy.com/view/NlycDG
- **Host**: shadertoy.com
- **Page title (as rendered)**: Hologram stars
- **Author username (as rendered)**: hypothete
- **Publish / last-update date (as rendered)**: 2022-09-04
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > Made a rainbow hologram shader for my website background. The final version has a couple more tweaks for scroll position and responsive star size. Click and drag your mouse to offset the plasma reflections.
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: none

### 9. AS_BGX_Kaleidoscope.1.fx

- **Source URL**: https://www.shadertoy.com/view/ddsyDN
- **Host**: shadertoy.com
- **Page title (as rendered)**: Kaleidoscope by Kanduvisla
- **Author username (as rendered)**: kanduvisla
- **Publish / last-update date (as rendered)**: 2023-06-15
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > This is the first shader I made, a kaleidoscope. Thanks to kishimisu for his excelent tutorial!
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: none

### 10. AS_BGX_LightRipples.1.fx

- **Source URL**: https://www.shadertoy.com/view/XsXXDn
- **Host**: shadertoy.com
- **Page title (as rendered)**: Creation by Silexars
- **Author username (as rendered)**: Danguafer
- **Publish / last-update date (as rendered)**: 2014-04-29
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > My first demoscene release. Achieved second place @ DemoJS 2011. It has been said to be the first 1k WebGL intro ever released.
  >
  > Try Prism, a next-gen graph-based shader editor @ https://prism.sensorial.studio
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: Upstream title is "Creation by Silexars"; AS-StageFX filename is "LightRipples".

### 11. AS_BGX_LogSpirals.1.fx

- **Source URL**: https://www.shadertoy.com/view/msGXRD
- **Host**: shadertoy.com
- **Page title (as rendered)**: Logarithmic spiral of spheres
- **Author username (as rendered)**: mrange
- **Publish / last-update date (as rendered)**: 2023-04-06
- **Detected license**: CC0-1.0
- **Host default applied**: null
- **Declaration source**: author-description
- **Evidence (verbatim description excerpt)**:
  > CC0: Logarithmic spiral of spheres
  > Meh, been struggling coming up with shaders that
  > Twitter art came to the rescue and this inspired me:
  > https://twitter.com/MaxDrekker/status/1643694297605103630?s=20
- **Status**: ok
- **Audit notes**: none

### 12. AS_BGX_MeltWave.1.fx

- **Source URL**: https://www.shadertoy.com/view/XsX3zl
- **Host**: shadertoy.com
- **Page title (as rendered)**: 70s Melt
- **Author username (as rendered)**: tomorrowevening
- **Publish / last-update date (as rendered)**: 2013-08-12
- **Detected license**: unknown
- **Host default applied**: null
- **Declaration source**: author-description
- **Evidence (verbatim description excerpt)**:
  > THE COLORS MAN, THE COLORS.
  >
  > Inspired by @WAHa_06x36's sine puke
  >
  > Not for personal or professiaonal use.
- **Status**: review_required
- **Audit notes**: The phrase "Not for personal or professiaonal use." (sic) is an explicit but ambiguous / self-contradicting restriction. Taken literally it forbids both personal and professional use, i.e. effectively all use. It is unclear whether this is humour/sarcasm or a genuine `all-rights-reserved`/`no-use` statement; it directly conflicts with Shadertoy's host default of CC-BY-NC-SA-3.0 (which allows non-commercial use). A human reviewer should contact the author or err on the side of the stated restriction before redistributing the port.

### 13. AS_BGX_MistyGrid.1.fx

- **Source URL**: https://www.shadertoy.com/view/wl2Szd
- **Host**: shadertoy.com
- **Page title (as rendered)**: [twitch] Misty Grid
- **Author username (as rendered)**: NuSan
- **Publish / last-update date (as rendered)**: 2019-08-26
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > Shader coded live on twitch (https://www.twitch.tv/nusan_fx)
  > The shader was made using Bonzomatic.
  > You can find the original shader here: http://lezanu.fr/LiveCode/MistyGrid.glsl
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: Description points to an external canonical source at lezanu.fr. If that site carries a distinct license it would take precedence over Shadertoy's host default.

### 14. AS_BGX_PastRacer.1.fx

- **Source URL**: https://www.shadertoy.com/view/tsBBzG
- **Host**: shadertoy.com
- **Page title (as rendered)**: Outline 2020 Freestyle Live code
- **Author username (as rendered)**: NuSan
- **Publish / last-update date (as rendered)**: 2020-05-23
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > Shader coded live during Outline Online 2020 in ~2h
  > There is two scenes that you can switch by changing SCENE from 0 to 1
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: Upstream title is "Outline 2020 Freestyle Live code"; AS-StageFX filename is "PastRacer". Note that entry 3's description calls "past racer" an inspiration source — the same phrase here may be coincidence. Reviewer may want to verify the port is based on this shader.

### 15. AS_BGX_PlasmaFlow.1.fx

- **Source URL**: https://www.shadertoy.com/view/slSBDd
- **Host**: shadertoy.com
- **Page title (as rendered)**: Plasma Storm
- **Author username (as rendered)**: fuzzmoon
- **Publish / last-update date (as rendered)**: 2022-05-18
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > Experimenting with 3D Gradient noise from Inigo Quilez. 
  > here the 3d noise is used in an iterative loop to deform the uv cords
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: none

### 16. AS_BGX_ProteanClouds.1.fx

- **Source URL**: https://www.shadertoy.com/view/3l23Rh
- **Host**: shadertoy.com
- **Page title (as rendered)**: Protean clouds
- **Author username (as rendered)**: nimitz
- **Publish / last-update date (as rendered)**: 2019-05-27
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > Fully procedural 3D animated volume with three evaluations per step (for shading) running fast enough for 1080p rendering.
  >
  > Featuring simple mouse interaction.
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: none

### 17. AS_BGX_QuadtreeTruchet.1.fx

- **Source URL**: https://www.shadertoy.com/view/4t3BW4
- **Host**: shadertoy.com
- **Page title (as rendered)**: Quadtree Truchet
- **Author username (as rendered)**: Shane
- **Publish / last-update date (as rendered)**: 2018-10-17
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > Quadtree Truchet - Based on Christopher Carlson's "Multi-Scale Truchet Patterns" paper. Mouse down to show the underlying quadtree grid structure.
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: none

### 18. AS_BGX_RaymarchedChain.1.fx

- **Source URL**: https://www.shadertoy.com/view/ctSfRV
- **Host**: shadertoy.com
- **Page title (as rendered)**: Corrente
- **Author username (as rendered)**: Elsio
- **Publish / last-update date (as rendered)**: 2023-09-08
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > Olha só que legal: se vc tem um sdf e um meio de dobrar o espaço, raymarch faz essa mágica! 
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: Upstream title is "Corrente" (Portuguese for "chain/current"); AS-StageFX filename is "RaymarchedChain". The Shadertoy info panel also notes it is "Forked from mysterious rotation", which may have its own upstream licensing to trace.

### 19. AS_BGX_StainedLights.1.fx

- **Source URL**: https://www.shadertoy.com/view/WlsSzM
- **Host**: shadertoy.com
- **Page title (as rendered)**: Stained Lights
- **Author username (as rendered)**: 104
- **Publish / last-update date (as rendered)**: 2019-07-06
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > saturday 2D fun
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: none

### 20. AS_BGX_SunsetClouds.1.fx

- **Source URL**: https://www.shadertoy.com/view/wXjSRt
- **Host**: shadertoy.com
- **Page title (as rendered)**: Sunset [280]
- **Author username (as rendered)**: Xor
- **Publish / last-update date (as rendered)**: 2025-05-05
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > Based on my tweet shader
  >     
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: Shadertoy info panel notes it is "Forked from Nebula 3 [299]" (also by Xor).

### 21. AS_BGX_TimeCrystal.1.fx

- **Source URL**: https://www.shadertoy.com/view/lcl3z2
- **Host**: shadertoy.com
- **Page title (as rendered)**: Time Crystal
- **Author username (as rendered)**: raphaeljmu
- **Publish / last-update date (as rendered)**: 2023-12-22
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > First attempt while following kishimisu's tutorial.
  >
  > https://www.youtube.com/watch?v=f4s1h2YETNY
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: none

### 22. AS_BGX_Vortex.1.fx

- **Source URL**: https://www.shadertoy.com/view/3fKGRd
- **Host**: shadertoy.com
- **Page title (as rendered)**: Vortex__
- **Author username (as rendered)**: LonkDong
- **Publish / last-update date (as rendered)**: 2025-05-28
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > Vortex
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: none

### 23. AS_BGX_WavySquares.1.fx

- **Source URL**: https://www.shadertoy.com/view/NdfBzn
- **Host**: shadertoy.com
- **Page title (as rendered)**: Square Tiling Example E
- **Author username (as rendered)**: SnoopethDuckDuck
- **Publish / last-update date (as rendered)**: 2022-02-09
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > just playing around with things
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: Shadertoy info panel notes it is "Forked from Square Tiling Example".

### 24. AS_BGX_WavySquiggles.1.fx

- **Source URL**: https://www.shadertoy.com/view/7sBfDD
- **Host**: shadertoy.com
- **Page title (as rendered)**: Interactive 2.5D Squiggles
- **Author username (as rendered)**: SnoopethDuckDuck
- **Publish / last-update date (as rendered)**: 2022-03-03
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  >  please upload please upload please upload please upload please upload please upload 
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: none

### 25. AS_BGX_ZippyZaps.1.fx

- **Source URL**: https://www.shadertoy.com/view/XXyGzh
- **Host**: shadertoy.com
- **Page title (as rendered)**: Zippy Zaps [394 Chars]
- **Author username (as rendered)**: SnoopethDuckDuck
- **Publish / last-update date (as rendered)**: 2024-06-01
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > Golfing always welcome ⚡
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: none

### 26. AS_VFX_CircularSpectrum.1.fx

- **Source URL**: https://www.shadertoy.com/view/tcyGW1
- **Host**: shadertoy.com
- **Page title (as rendered)**: Circular audio visualizer
- **Author username (as rendered)**: AIandDesign
- **Publish / last-update date (as rendered)**: 2025-05-24
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > Kind of a work in progress. Looks good though.
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: none

### 27. AS_VFX_ClairObscur.1.fx

- **Source URL**: https://www.shadertoy.com/view/ttcBRs
- **Host**: shadertoy.com
- **Page title (as rendered)**: [RGR] Hearts
- **Author username (as rendered)**: deeplo
- **Publish / last-update date (as rendered)**: 2021-02-13
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > falling hearts like tree leaves
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: Upstream title is "[RGR] Hearts"; AS-StageFX filename is "ClairObscur". Reviewer may want to confirm the port source.

### 28. AS_VFX_FocusedChaos.1.fx

- **Source URL**: https://www.shadertoy.com/view/lcfyDj
- **Host**: shadertoy.com
- **Page title (as rendered)**: BlackHole (swirl, portal)
- **Author username (as rendered)**: misterprada
- **Publish / last-update date (as rendered)**: 2024-07-22
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > Ref - https://x.com/cmzw_/status/1787147460772864188 (celestianmaze)
  >
  > Black Hole
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: Description attributes the visual reference to @cmzw_ (celestianmaze) on X/Twitter — not a licensing statement, but worth noting as an attribution chain.

### 29. AS_VFX_RadiantFire.1.fx

- **Source URL**: https://www.shadertoy.com/view/4ttGWM
- **Host**: shadertoy.com
- **Page title (as rendered)**: 301's Fire Shader - Remix 3
- **Author username (as rendered)**: mu6k
- **Publish / last-update date (as rendered)**: 2016-07-27
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > Sorry, I couln't resist :P. This is another take on the plasma-fire effect. Original code by CaliCoastReplay and 301.
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: Description attributes the original code to "CaliCoastReplay and 301", implying this is a derivative. The upstream shaders may have independent licensing and would need to be traced.

### 30. AS_VFX_RainyWindow.1.fx

- **Source URL**: https://www.shadertoy.com/view/ltffzl
- **Host**: shadertoy.com
- **Page title (as rendered)**: Heartfelt
- **Author username (as rendered)**: BigWIngs
- **Publish / last-update date (as rendered)**: 2017-12-17
- **Detected license**: CC-BY-NC-SA-3.0
- **Host default applied**: null
- **Declaration source**: inline-comment
- **Evidence (verbatim description excerpt)**:
  > If you want to really get sad then be sure to watch with sound ;) If you want to see and control the rain, comment out the HAS_HEART define Controls: Mouse x = scrub time y = rain amount (only without heart)
  >
  > No explicit license statement found in the description panel.
  >
  > The GLSL source code, however, carries an explicit inline licence declaration in its header comments:
  >
  > > // Heartfelt - by Martijn Steinrucken aka BigWings - 2017
  > > // Email:countfrolic@gmail.com Twitter:@The_ArtOfCode
  > > // License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
- **Status**: ok
- **Audit notes**: The author's inline statement matches Shadertoy's host default (CC-BY-NC-SA-3.0), so there is no conflict. Recorded as `inline-comment` rather than `host-default` because the author explicitly asserted the licence in code.

### 31. AS_VFX_VolumetricLight.1.fx

- **Source URL**: https://www.shadertoy.com/view/wftXzr
- **Host**: shadertoy.com
- **Page title (as rendered)**: fake volumetric 2d light wip
- **Author username (as rendered)**: int_45h
- **Publish / last-update date (as rendered)**: 2025-05-31
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > mimics the godrays effect you see in older games, right now I'm using a lot more texture samples than I should and I'm certain there's a better way to do this, but im sticking with it for now
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: none

### 32. AS_GFX_CosmicGlow.1.fx

- **Source URL**: https://www.shadertoy.com/view/ls3XW8
- **Host**: shadertoy.com
- **Page title (as rendered)**: Isometric Grid 2 (108 chars)
- **Author username (as rendered)**: FabriceNeyret2
- **Publish / last-update date (as rendered)**: 2016-03-26
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > code golfing of  lejeunerenard's https://www.shadertoy.com/view/ltjGWt
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: Upstream title is "Isometric Grid 2 (108 chars)"; AS-StageFX filename is "CosmicGlow". This is itself a code-golf derivative of lejeunerenard's Shadertoy view ltjGWt — reviewer may want to double-check the correct source.

### 33. AS_GFX_Hologram.1.fx

- **Source URL**: https://www.shadertoy.com/view/MdBSWV
- **Host**: shadertoy.com
- **Page title (as rendered)**: Protection hologram
- **Author username (as rendered)**: TDM
- **Publish / last-update date (as rendered)**: 2014-11-14
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > Proof of concept. Hologram effect with little parallax.
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: Note there are two Hologram ports in AS-StageFX (entry 8 BGX and entry 33 GFX "Depth Hologram") — different upstreams.

### 34. AS_GFX_HandDrawing.1.fx

- **Source URL**: https://www.shadertoy.com/view/XtVGD1
- **Host**: shadertoy.com
- **Page title (as rendered)**: notebook drawings
- **Author username (as rendered)**: flockaroo
- **Publish / last-update date (as rendered)**: 2016-09-21
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > hand drawing effect
  > ...i used to draw a lot, now i let computers pursue my hobbies ;)
  >
  > took aspect ratio into account, so webcams dont get quenched too much
  > ...so try your webcam instead of jean claude ;)
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: none

### 35. AS_GFX_VignettePlus.1.fx

- **Source URL**: https://www.shadertoy.com/view/XfjyWG
- **Host**: shadertoy.com
- **Page title (as rendered)**: Hexagonal Wipe
- **Author username (as rendered)**: blandprix
- **Publish / last-update date (as rendered)**: 2024-08-06
- **Detected license**: HOST_DEFAULT
- **Host default applied**: CC-BY-NC-SA-3.0
- **Declaration source**: host-default
- **Evidence (verbatim description excerpt)**:
  > A gentle screen transition with disappearing hexagonal cells.
  > Did you know a hexagonal grid is the densest possible arrangement of circles?
  >
  > No explicit license statement found.
- **Status**: ok
- **Audit notes**: Upstream title is "Hexagonal Wipe"; AS-StageFX filename is "VignettePlus". Reviewer may want to confirm the port source.

### 36. AS_BGX_LiquidChrome.1.fx

- **Source URL**: https://neort.io/art/bkm813c3p9f7drq1j86g
- **Host**: neort.io
- **Page title (as rendered)**: liquid chrome
- **Author username (as rendered)**: iamsaitam
- **Publish / last-update date (as rendered)**: 2019.7.15
- **Detected license**: unknown
- **Host default applied**: host default unknown
- **Declaration source**: none
- **Evidence (verbatim description excerpt)**:
  > (The art page renders only the shader, title, author and date — there is no author-written description panel on this page.)
  >
  > Verbatim visible page text:
  > > NFT
  > > Explore
  > > Challenge
  > > Space
  > > Exhibition
  > > Sign Up / Sign In
  > > Best of 2019
  > > liquid chrome
  > > by iamsaitam
  > > ·
  > > 2019.7.15
  > > person
  > >
  > > 29
  > >
  > > share
  > > more_horiz
  > > code
  > > visibility
  > > fullscreen
  > > 1
  > > 2
  > > 4
  > > 8
  > > pause
  >
  > No explicit license statement found on the art page.
  >
  > Relevant clauses from neort.io's Terms of Use (https://neort.io/terms) governing "Posted Content":
  > > Users may post the Content whose copyright is rightfully owned by such User. Any Content whose copyright is owned by anyone other than the posting User shall not be posted.
  > > Users may view and otherwise use the Posted Content to the extent that it does not infringe on the rights of copyright holders. In addition, Users may reproduce the Posted Content on social network services, blogs, and other third party services only if such Users comply with the conditions set forth below, and the User who posted such Posted Content shall not object to such use.
  > > The URL of the Posted Content (with a link to the page pertaining to the Posted content on the Service) shall be included.
  > > The name of the author of the Posted Content shall be indicated.
  > > The reproducing User shall not gain direct economic benefits from the reproduction of the Posted Content by any means including requir[…]
- **Status**: review_required
- **Audit notes**: neort.io does not publish a named default licence for hosted shaders. Its ToS only authorises very limited viewer uses (social-media reproduction with link back + author attribution + no direct economic benefit), which is more restrictive than any standard open licence and is closer to "all rights reserved, permissive reshare only". Because the ToS explicitly forbids posting Content the poster does not own, the upstream copyright is retained by iamsaitam; any redistribution of the ported shader almost certainly needs the author's direct permission. Recorded as `detected_license: unknown` and flagged for human review / direct contact with the author.

### 37. AS_VFX_BoomSticker.1.fx

- **Source URL**: https://github.com/Otakumouse/stormshade/blob/master/v4.X/reshade-shaders/Shader%20Library/Recommended/StageDepth.fx
- **Host**: github.com
- **Page title (as rendered)**: Otakumouse/stormshade: Custom reshade build (unlocked z-depth) + shader preset for Final Fantasy 14.
- **Author username (as rendered)**: Otakumouse (repo owner); upstream file author: Marot Satil (per inline comment)
- **Publish / last-update date (as rendered)**: Copyright year 2019 (per inline comment header)
- **Detected license**: BSD-2-Clause
- **Host default applied**: null
- **Declaration source**: inline-comment
- **Evidence (verbatim description excerpt)**:
  > The repository root `github.com/Otakumouse/stormshade` has **no `LICENSE` file**. The "About" sidebar lists only "Readme" under Resources (no license badge), so GitHub does not recognise this repository as carrying a declared licence — the default is "all rights reserved" under the repository owner.
  >
  > The individual shader file, however, carries an explicit inline BSD 2-Clause license header (verbatim first ~1500 chars of the file):
  >
  > > // Made by Marot Satil for the GShade ReShade package!
  > > // You can follow me via @MarotSatil on Twitter, but I don't use it all that much.
  > > // Follow @GPOSERS_FFXIV on Twitter and join us on Discord (https://discord.gg/39WpvU2)
  > > // for the latest GShade package updates!
  > > //
  > > // This shader was designed in the same vein as GreenScreenDepth.fx, but instead of applying a
  > > // green screen with adjustable distance, it applies a PNG texture with adjustable opacity.
  > > //
  > > // PNG transparency is fully supported, so you could for example add another moon to the sky
  > > // just as readily as create a "green screen" stage like in real life.
  > > //
  > > // Copyright (c) 2019, Marot Satil
  > > // All rights reserved.
  > > //
  > > // Redistribution and use in source and binary forms, with or without
  > > // modification, are permitted provided that the following conditions
  > > // are met:
  > > // 1. Redistributions of source code must retain the above copyright
  > > //    notice, the header above it, this list of conditions, and the following disclaimer
  > > //    in this position and unchanged.
  > > // 2. Redistributions in binary form must reproduce the above copyright
  > > //    notice, the header above it, this list of conditions, and the following disclaimer in the
  > > //    documentation and/or other materials provided with the distribution.
  > > //
  > > // THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR
  > > // IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
  > > // OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
  > > // IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
  > > // INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
  > > // NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  > > // DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  > > // THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  > > // (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
  > > // THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
- **Status**: review_required
- **Audit notes**: Two-layer licensing picture. (1) The host GitHub repository carries no `LICENSE` file and GitHub's "Resources" sidebar does not list a license — so GitHub's default ("no permissive grant; all rights reserved by repo owner") applies to the repository *as a whole*. (2) The individual shader file's inline header, however, is the textbook BSD 2-Clause ("Simplified BSD") license text, granting redistribution and modification subject to the two listed conditions. The file header attributes the shader to **Marot Satil** ("Made by Marot Satil for the GShade ReShade package!") — i.e. Otakumouse/stormshade is itself a redistribution from the upstream GShade project; the canonical upstream is likely `github.com/Mortalitas/GShade-Shaders` or similar. Reviewer should (a) treat the file-level BSD-2-Clause as the authoritative licence for `StageDepth.fx`, (b) comply with both clauses (copyright-notice retention), and (c) consider crediting the upstream GShade project rather than Otakumouse/stormshade.

### 38. AS_VFX_TiltedGrid.1.fx

- **Source URL**: https://www.youtube.com/watch?v=Tfj6RDqXEHM
- **Host**: youtube.com
- **Page title (as rendered)**: null
- **Author username (as rendered)**: null
- **Publish / last-update date (as rendered)**: null
- **Detected license**: null
- **Host default applied**: null (YouTube grants no implicit code license)
- **Declaration source**: none
- **Evidence (verbatim description excerpt)**:
  > Skip navigation
  > Create
  > 9+
  > This video isn't available anymore
  > GO TO HOME
- **Status**: source_unreachable
- **Audit notes**: The YouTube video has been removed or made private (YouTube's standard "This video isn't available anymore" interstitial was served). No title, channel, description, or licence information is retrievable from the canonical URL. Because YouTube never grants an implicit code licence to material shown in a video regardless, the original AS-StageFX port's license provenance cannot be established from this URL alone. Reviewer should attempt to recover the original author via (a) Wayback Machine capture of the video URL, (b) the AS-StageFX port's inline credits / header comments, or (c) direct contact with the AS-StageFX maintainer.

## Audit completeness

- Sources reachable: 37
- Sources 404: 0
- Sources private: 0
- Sources with explicit license: 5  (entries 7, 11, 12, 30, 37 — i.e. two CC0, one ambiguous/unknown no-use, one CC-BY-NC-SA-3.0 inline, one BSD-2-Clause inline)
- Sources falling back to host default: 29  (28 Shadertoy + 1 neort.io where no named host-default exists)
- Sources flagged review_required: 3  (entry 12 MeltWave, entry 36 LiquidChrome, entry 37 BoomSticker)

Note on `source_unreachable` vs `reachable`: entry 38 (YouTube TiltedGrid) is counted under `source_unreachable` and is therefore excluded from the "sources reachable" count (37 = 38 total − 1 unreachable). It is not double-counted in `review_required`.
