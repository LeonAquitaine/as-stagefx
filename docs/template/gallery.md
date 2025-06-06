# AS-StageFX Shader Gallery - Essentials Package

This gallery provides detailed descriptions and visual examples of the core shaders included in the **AS_StageFX_Essentials** package. The complete AS-StageFX collection includes **{{shaderCount}} shaders** across four categories: **{{bgxCount}} Background (BGX)**, **{{gfxCount}} Graphic (GFX)**, **{{lfxCount}} Lighting (LFX)**, and **{{vfxCount}} Visual (VFX)** effects.

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
{{#each grouped.BGX}}
<tr>
<td width="50%">
<h4>BGX: {{name}} {{icon}}</h4>
<h5><code>[AS] BGX: {{name}}|{{filename}}</code></h5>
{{longDescription}}
{{#if credits}}
<br><br>
{{#if credits.description}}{{credits.description}}<br>{{/if}}
{{#if credits.externalUrl}}<a href="{{credits.externalUrl}}" target="_new">Source</a>{{/if}}
{{/if}}
</td>
<td width="50%"><div style="text-align:center">
<img src="{{imageUrl}}" alt="{{name}} Effect" style="max-width:100%;">
</div></td>
</tr>
{{/each}}
</table>

---

## Graphic Effects (GFX)

<table>
{{#each grouped.GFX}}
<tr>
<td width="50%">
<h4>GFX: {{name}} {{icon}}</h4>
<h5><code>[AS] GFX: {{name}}|{{filename}}</code></h5>
{{longDescription}}
{{#if credits}}
<br><br>
{{#if credits.description}}{{credits.description}}<br>{{/if}}
{{#if credits.externalUrl}}<a href="{{credits.externalUrl}}" target="_new">Source</a>{{/if}}
{{/if}}
</td>
<td width="50%"><div style="text-align:center">
<img src="{{imageUrl}}" alt="{{name}} Effect" style="max-width:100%;">
</div></td>
</tr>
{{/each}}
</table>

---

## Lighting Effects (LFX)

<table>
{{#each grouped.LFX}}
<tr>
<td width="50%">
<h4>LFX: {{name}} {{icon}}</h4>
<h5><code>[AS] LFX: {{name}}|{{filename}}</code></h5>
{{longDescription}}
{{#if credits}}
<br><br>
{{#if credits.description}}{{credits.description}}<br>{{/if}}
{{#if credits.externalUrl}}<a href="{{credits.externalUrl}}" target="_new">Source</a>{{/if}}
{{/if}}
</td>
<td width="50%"><div style="text-align:center">
<img src="{{imageUrl}}" alt="{{name}} Effect" style="max-width:100%;">
</div></td>
</tr>
{{/each}}
</table>

---

## Visual Effects (VFX)

<table>
{{#each grouped.VFX}}
<tr>
<td width="50%">
<h4>VFX: {{name}} {{icon}}</h4>
<h5><code>[AS] VFX: {{name}}|{{filename}}</code></h5>
{{longDescription}}
{{#if credits}}
<br><br>
{{#if credits.description}}{{credits.description}}<br>{{/if}}
{{#if credits.externalUrl}}<a href="{{credits.externalUrl}}" target="_new">Source</a>{{/if}}
{{/if}}
</td>
<td width="50%"><div style="text-align:center">
<img src="{{imageUrl}}" alt="{{name}} Effect" style="max-width:100%;">
</div></td>
</tr>
{{/each}}
</table>

---

*For more detailed information about installation, updates, and credits, please refer to the [main README](../README.md). Complete external source attribution is available in [AS_StageFX_Credits.md](../AS_StageFX_Credits.md).*
