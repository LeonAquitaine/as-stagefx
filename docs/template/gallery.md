# AS-StageFX Shader Gallery

This gallery provides detailed descriptions and visual examples of the complete AS-StageFX collection, which includes **{{total}} shaders** across four categories: **{{byType.BGX}} Background (BGX)**, **{{byType.GFX}} Graphic (GFX)**, **{{byType.LFX}} Lighting (LFX)**, and **{{byType.VFX}} Visual (VFX)** effects.

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
{{#each grouped.BGX}}
<tr>
<td width="50%">
<h3>{{name}} {{icon}}</h3>
<h5><code>{{filename}}</code></h5>
{{longDescription}}
{{#if credits}}
<br><br>
{{#if credits.originalTitle}}Based on '<a href="{{credits.externalUrl}}" target="_new">{{credits.originalTitle}}</a>' by {{credits.originalAuthor}}<br>{{/if}}
{{/if}}
{{#if licence}}<br><strong>License:</strong> {{licence}} <span style="color:#888;font-size:90%">({{license}})</span>{{/if}}
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
<h3>{{name}} {{icon}}</h3>
<h5><code>{{filename}}</code></h5>
{{longDescription}}
{{#if credits}}
<br><br>
{{#if credits.originalTitle}}Based on '<a href="{{credits.externalUrl}}" target="_new">{{credits.originalTitle}}</a>' by {{credits.originalAuthor}}<br>{{/if}}
{{/if}}
{{#if licence}}<br><strong>License:</strong> {{licence}} <span style="color:#888;font-size:90%">({{license}})</span>{{/if}}
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
<h3>{{name}} {{icon}}</h3>
<h5><code>{{filename}}</code></h5>
{{longDescription}}
{{#if credits}}
<br><br>
{{#if credits.originalTitle}}Based on '<a href="{{credits.externalUrl}}" target="_new">{{credits.originalTitle}}</a>' by {{credits.originalAuthor}}<br>{{/if}}
{{/if}}
{{#if licence}}<br><strong>License:</strong> {{licence}} <span style="color:#888;font-size:90%">({{license}})</span>{{/if}}
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
<h3>{{name}} {{icon}}</h3>
<h5><code>{{filename}}</code></h5>
{{longDescription}}
{{#if credits}}
<br><br>
{{#if credits.originalTitle}}Based on '<a href="{{credits.externalUrl}}" target="_new">{{credits.originalTitle}}</a>' by {{credits.originalAuthor}}{{/if}}
{{/if}}
{{#if licence}}<br><strong>License:</strong> {{licence}} <span style="color:#888;font-size:90%">({{license}})</span>{{/if}}
</td>
<td width="50%"><div style="text-align:center">
<img src="{{imageUrl}}" alt="{{name}} Effect" style="max-width:100%;">
</div></td>
</tr>
{{/each}}
</table>

---

*For more detailed information about installation, updates, and credits, please refer to the [main README](../README.md). Complete external source attribution is available in [AS_StageFX_Credits.md](../AS_StageFX_Credits.md).*
