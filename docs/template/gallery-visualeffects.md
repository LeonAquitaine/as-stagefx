# AS-StageFX Shader Gallery - Visual Effects Package

This gallery provides detailed descriptions and visual examples of the **visual effects** ({{byType.LFX}} Lighting + {{byType.VFX}} Visual) included in the **AS_StageFX_VisualEffects** package. These effects range from lighting simulation and audio visualization to particle systems and post-processing tools.

For installation instructions and general information, please refer to the [main README](../README.md).

> **Note:** This package requires the [AS_StageFX_Essentials](./gallery.md) package to be installed.

> **Looking for other packages?**
> - [Essentials Gallery](./gallery.md) - Core library files and essential effects
> - [Backgrounds Gallery](./gallery-backgrounds.md) - Complete collection of background effects

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
