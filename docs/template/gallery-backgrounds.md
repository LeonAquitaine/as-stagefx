# AS-StageFX Shader Gallery - Backgrounds Package

This gallery provides detailed descriptions and visual examples of the **{{byType.BGX}} background effects** included in the **AS_StageFX_Backgrounds** package. These dynamic, audio-reactive backgrounds range from cosmic and abstract patterns to flowing animations and crystalline structures.

For installation instructions and general information, please refer to the [main README](../README.md).

> **Note:** This package requires the [AS_StageFX_Essentials](./gallery.md) package to be installed.

> **Looking for other packages?**
> - [Essentials Gallery](./gallery.md) - Core library files and essential effects  
> - [Visual Effects Gallery](./gallery-visualeffects.md) - Complete collection of visual effects

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
{{#if credits.description}}{{credits.description}}<br>{{/if}}
{{#if credits.externalUrl}}<a href="{{credits.externalUrl}}" target="_new">Source</a>{{/if}}
{{/if}}
</td>
<td width="50%">
<img src="{{imageUrl}}" alt="{{name}} Effect" style="max-width:100%;"/>
<div style="text-align:center">
</div></td>
</tr>
{{/each}}
</table>

---

*For more detailed information about installation, updates, and credits, please refer to the [main README](../README.md). Complete external source attribution is available in [AS_StageFX_Credits.md](../AS_StageFX_Credits.md).*
