<!-- filepath: AS_StageFX_Credits.md -->
# AS-StageFX External Credits and Attribution

**Repository**: AS-StageFX ReShade Shader Collection
**Maintainer**: Leon Aquitaine

This document records external sources, original authors, and inspiration credits for the AS-StageFX shader collection, and the licence under which each ported shader is distributed.

The collection contains two categories of externally-informed work:

1. **Original works with inspiration credits** — shaders Leon wrote from scratch, crediting a prior work as visual or conceptual inspiration. These are licensed **CC BY 4.0** (the AS-StageFX project licence).
2. **Ports and adaptations** — shaders derived from an external source. These inherit the upstream source's licence.

Purely original shaders (no external inspiration) are not listed here; they are covered by the project default of **CC BY 4.0** and appear only in the main [README.md](README.md).

For the overall licensing model see [LICENSING.md](LICENSING.md).

---

## 1. Original Works with Inspiration Credits

These shaders are original implementations by Leon Aquitaine, crediting prior works that inspired them. They are not ports and do not inherit any upstream licence.

### AS_VFX_BoomSticker.1.fx — Boom Sticker
- **Licence**: CC BY 4.0 (AS-StageFX project licence)
- **Author**: Leon Aquitaine (original implementation)
- **Inspiration**: "StageDepth.fx" by Marot Satil (2019), GShade ReShade package — original depth-masked texture-overlay concept.
- **Upstream reference**: https://github.com/Otakumouse/stormshade/blob/master/v4.X/reshade-shaders/Shader%20Library/Recommended/StageDepth.fx

### AS_VFX_ClairObscur.1.fx — Clair Obscur
- **Licence**: CC BY 4.0 (AS-StageFX project licence)
- **Author**: Leon Aquitaine (original implementation)
- **Inspiration**: Motion inspired by "[RGR] Hearts" by deeplo.
- **Upstream reference**: https://www.shadertoy.com/view/ttcBRs

### AS_VFX_TiltedGrid.1.fx — Tilted Grid
- **Licence**: CC BY 4.0 (AS-StageFX project licence)
- **Author**: Leon Aquitaine (original implementation)
- **Inspiration**: Technique learned from FencerDevLog's "Godot 4: Tilted Grid Effect Tutorial".
- **Upstream reference**: https://www.youtube.com/watch?v=Tfj6RDqXEHM (video no longer available)

### AS_BGX_MeltWave.1.fx — Melt Wave
- **Licence**: CC BY 4.0 (AS-StageFX project licence)
- **Author**: Leon Aquitaine (clean-room original implementation, 2026-04-24)
- **History**: An earlier port carrying ambiguous upstream licensing was replaced with a clean-room implementation produced from behavioural specification [docs/specs/AS_BGX_MeltWave.spec.md](docs/specs/AS_BGX_MeltWave.spec.md). The current implementation shares no code with any prior work.

### AS_BGX_Constellation.1.fx — Constellation
- **Licence**: CC BY 4.0 (AS-StageFX project licence)
- **Author**: Leon Aquitaine (clean-room original implementation, 2026-04-24)
- **History**: An earlier port with ambiguous upstream provenance was replaced with a clean-room implementation produced from behavioural specification [docs/specs/AS_BGX_Constellation.spec.md](docs/specs/AS_BGX_Constellation.spec.md). The current implementation shares no code with any prior work.

### AS_BGX_LiquidChrome.1.fx — Liquid Chrome
- **Licence**: CC BY 4.0 (AS-StageFX project licence)
- **Author**: Leon Aquitaine (clean-room original implementation, 2026-04-24)
- **History**: An earlier port of an neort.io work with no explicit redistribution licence was replaced with a clean-room implementation produced from behavioural specification [docs/specs/AS_BGX_LiquidChrome.spec.md](docs/specs/AS_BGX_LiquidChrome.spec.md). The current implementation shares no code with any prior work.

---

## 2. Ports and Adaptations

The following shaders are ports/adaptations of external works. Each inherits the upstream source's licence. Where an author explicitly declared a licence, it is noted; otherwise the platform default applies (Shadertoy's default is CC BY-NC-SA 3.0 Unported per [shadertoy.com/terms](https://www.shadertoy.com/terms)).

### Background Effects (BGX)

#### AS_BGX_BlueCorona.1.fx — Blue Corona
- **Original Author**: SnoopethDuckDuck
- **Original Title**: Blue Corona [256 Chars]
- **Source**: https://www.shadertoy.com/view/XfKGWV
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_CorridorTravel.1.fx — Corridor Travel
- **Original Author**: NuSan
- **Original Title**: Corridor Travel
- **Source**: https://www.shadertoy.com/view/3sXyRN
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_CosmicKaleidoscope.1.fx — Cosmic Kaleidoscope
- **Original Author**: Kali
- **Original Title**: Star Nest
- **Source**: https://www.shadertoy.com/view/XlfGRj
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_DigitalBrain.1.fx — Digital Brain
- **Original Author**: srtuss
- **Original Title**: Digital Brain
- **Source**: https://www.shadertoy.com/view/4sl3Dr
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_Fluorescent.1.fx — Fluorescent
- **Original Author**: Xor
- **Original Title**: Fluorescent [292]
- **Source**: https://www.shadertoy.com/view/WcGGDd
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_GoldenClockwork.1.fx — Golden Clockwork
- **Original Author**: mrange
- **Original Title**: Golden apollian
- **Source**: https://www.shadertoy.com/view/WlcfRS
- **Licence**: **CC0 1.0 Universal** (explicitly dedicated to public domain by the author)

#### AS_BGX_Hologram.1.fx — Hologram
- **Original Author**: hypothete
- **Original Title**: Hologram stars
- **Source**: https://www.shadertoy.com/view/NlycDG
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_Kaleidoscope.1.fx — Kaleidoscope
- **Original Author**: Kanduvisla
- **Original Title**: Kaleidoscope
- **Source**: https://www.shadertoy.com/view/ddsyDN
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_LightRipples.1.fx — Light Ripples
- **Original Author**: Danguafer (Danilo Guanabara)
- **Original Title**: Creation by Silexars
- **Source**: https://www.shadertoy.com/view/XsXXDn
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_LogSpirals.1.fx — Log Spirals
- **Original Author**: mrange
- **Original Title**: Logarithmic spiral of spheres
- **Source**: https://www.shadertoy.com/view/msGXRD
- **Licence**: **CC0 1.0 Universal** (explicitly dedicated to public domain by the author)

#### AS_BGX_MistyGrid.1.fx — Misty Grid
- **Original Author**: NuSan
- **Original Title**: [twitch] Misty Grid
- **Source**: https://www.shadertoy.com/view/wl2Szd
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_PastRacer.1.fx — Past Racer
- **Original Author**: NuSan
- **Original Title**: Outline 2020 Freestyle Live code
- **Source**: https://www.shadertoy.com/view/tsBBzG
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_PlasmaFlow.1.fx — Plasma Flow
- **Original Author**: fuzzmoon
- **Original Title**: Plasma Storm
- **Source**: https://www.shadertoy.com/view/slSBDd
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_ProteanClouds.1.fx — Protean Clouds
- **Original Author**: nimitz (twitter: @stormoid)
- **Original Title**: Protean clouds
- **Source**: https://www.shadertoy.com/view/3l23Rh
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default, also declared inline by the upstream author)

#### AS_BGX_QuadtreeTruchet.1.fx — Quadtree Truchet
- **Original Author**: Shane
- **Original Title**: Quadtree Truchet
- **Source**: https://www.shadertoy.com/view/4t3BW4
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_RaymarchedChain.1.fx — Raymarched Chain
- **Original Author**: Elsio
- **Original Title**: Corrente
- **Source**: https://www.shadertoy.com/view/ctSfRV
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_StainedLights.1.fx — Stained Lights
- **Original Author**: 104
- **Original Title**: Stained Lights
- **Source**: https://www.shadertoy.com/view/WlsSzM
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_SunsetClouds.1.fx — Sunset Clouds
- **Original Author**: Xor
- **Original Title**: Sunset [280]
- **Source**: https://www.shadertoy.com/view/wXjSRt
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_TimeCrystal.1.fx — Time Crystal
- **Original Author**: raphaeljmu
- **Original Title**: Time Crystal
- **Source**: https://www.shadertoy.com/view/lcl3z2
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_Vortex.1.fx — Vortex
- **Original Author**: LonkDong
- **Original Title**: Vortex__
- **Source**: https://www.shadertoy.com/view/3fKGRd
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_Waveform.1.fx — Waveform
- **Original Author**: Xor (XorDev)
- **Original Title**: Waveform [315]
- **Source**: https://www.shadertoy.com/view/Wcc3z2
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)
- **Note**: The Shadertoy original includes a commented-out Soundcloud audio sample (disabled upstream when Shadertoy's Soundcloud integration stopped working). This port enables audio reactivity via Listeningway frequency bands in place of the original texture lookup.

#### AS_BGX_WavySquares.1.fx — Wavy Squares
- **Original Author**: SnoopethDuckDuck
- **Original Title**: Square Tiling Example E
- **Source**: https://www.shadertoy.com/view/NdfBzn
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_WavySquiggles.1.fx — Wavy Squiggles
- **Original Author**: SnoopethDuckDuck
- **Original Title**: Interactive 2.5D Squiggles
- **Source**: https://www.shadertoy.com/view/7sBfDD
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_BGX_ZippyZaps.1.fx — Zippy Zaps
- **Original Author**: SnoopethDuckDuck
- **Original Title**: Zippy Zaps
- **Source**: https://www.shadertoy.com/view/XXyGzh
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

### Graphic Effects (GFX)

#### AS_GFX_CosmicGlow.1.fx — Cosmic Glow
- **Original Author**: Xor (XorDev)
- **Original Title**: Cosmic [256 Chars]
- **Source**: https://www.shadertoy.com/view/msjXRK
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_GFX_HandDrawing.1.fx — Hand Drawing
- **Original Author**: Flockaroo
- **Original Title**: notebook drawings
- **Source**: https://www.shadertoy.com/view/XtVGD1
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_GFX_Hologram.1.fx — Depth Hologram
- **Original Author**: Alexander Alekseev (TDM)
- **Original Title**: Protection hologram
- **Source**: https://www.shadertoy.com/view/MdBSWV
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_GFX_VignettePlus.1.fx — Vignette Plus
- **Original Author**: blandprix
- **Original Title**: Hexagonal Wipe
- **Source**: https://www.shadertoy.com/view/XfjyWG
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

### Visual Effects (VFX)

#### AS_VFX_CircularSpectrum.1.fx — Circular Spectrum
- **Original Author**: AIandDesign
- **Original Title**: Circular audio visualizer
- **Source**: https://www.shadertoy.com/view/tcyGW1
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_VFX_FocusedChaos.1.fx — Focused Chaos
- **Original Author**: misterprada
- **Original Title**: BlackHole (swirl, portal)
- **Source**: https://www.shadertoy.com/view/lcfyDj
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_VFX_RadiantFire.1.fx — Radiant Fire
- **Original Author**: mu6k
- **Original Title**: 301's Fire Shader - Remix 3
- **Source**: https://www.shadertoy.com/view/4ttGWM
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

#### AS_VFX_RainyWindow.1.fx — Rainy Window
- **Original Author**: Martijn Steinrucken (BigWings)
- **Original Title**: Heartfelt
- **Source**: https://www.shadertoy.com/view/ltffzl
- **Licence**: CC BY-NC-SA 3.0 Unported (explicitly declared inline by the upstream author)

#### AS_VFX_VolumetricLight.1.fx — Volumetric Light
- **Original Author**: int_45h
- **Original Title**: fake volumetric 2d light wip
- **Source**: https://www.shadertoy.com/view/wftXzr
- **Licence**: CC BY-NC-SA 3.0 Unported (Shadertoy default)

---

## 3. Attribution Notice

All adaptations maintain attribution to original creators as required by Creative Commons licensing. When using or redistributing these shaders, please:

- Preserve the original author's attribution (listed above) in any published work.
- Preserve the licence notice in the shader file header.
- For CC BY-NC-SA works: do not use commercially, and distribute any derivative under the same licence.
- For CC0 works: no attribution is legally required, though good practice is to credit.
- For CC BY 4.0 works (Leon's originals and CC BY 4.0 ports): credit Leon Aquitaine.

For the full licensing model, see [LICENSING.md](LICENSING.md).

---

**Last Updated**: 2026-04-24
**Compiled by**: Leon Aquitaine (maintainer)
