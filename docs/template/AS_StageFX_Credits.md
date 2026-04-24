<!-- filepath: docs/template/AS_StageFX_Credits.md -->
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

{{#each originalsWithInspiration}}
### {{filename}} — {{name}}
- **Licence**: CC BY 4.0 (AS-StageFX project licence)
- **Author**: Leon Aquitaine (original implementation)
- **Inspiration**: {{inspirationText}}
- **Upstream reference**: {{credits.externalUrl}}

{{/each}}
{{#each originalsWithHistory}}
### {{filename}} — {{name}}
- **Licence**: CC BY 4.0 (AS-StageFX project licence)
- **Author**: Leon Aquitaine (original implementation)
- **History**: {{credits.description}}

{{/each}}
---

## 2. Ports and Adaptations

The following shaders are ports/adaptations of external works. Each inherits the upstream source's licence. Where an author explicitly declared a licence, it is noted; otherwise the platform default applies (Shadertoy's default is CC BY-NC-SA 3.0 Unported per [shadertoy.com/terms](https://www.shadertoy.com/terms)).

### Background Effects (BGX)

{{#each portsBGX}}
#### {{filename}} — {{name}}
- **Original Author**: {{credits.originalAuthor}}
- **Original Title**: {{credits.originalTitle}}
- **Source**: {{credits.externalUrl}}
- **Licence**: {{credits.licence}}

{{/each}}
### Graphic Effects (GFX)

{{#each portsGFX}}
#### {{filename}} — {{name}}
- **Original Author**: {{credits.originalAuthor}}
- **Original Title**: {{credits.originalTitle}}
- **Source**: {{credits.externalUrl}}
- **Licence**: {{credits.licence}}

{{/each}}
### Lighting Effects (LFX)

{{#each portsLFX}}
#### {{filename}} — {{name}}
- **Original Author**: {{credits.originalAuthor}}
- **Original Title**: {{credits.originalTitle}}
- **Source**: {{credits.externalUrl}}
- **Licence**: {{credits.licence}}

{{/each}}
### Visual Effects (VFX)

{{#each portsVFX}}
#### {{filename}} — {{name}}
- **Original Author**: {{credits.originalAuthor}}
- **Original Title**: {{credits.originalTitle}}
- **Source**: {{credits.externalUrl}}
- **Licence**: {{credits.licence}}

{{/each}}
---

## Attribution Notice

All adaptations maintain proper attribution to original creators as required by Creative Commons licensing. When using these shaders, please ensure you include attribution to both Leon Aquitaine (for the ReShade adaptation and AS framework integration) and the original creators listed above.

For commercial use, please verify licensing terms with original creators where applicable, though most Shadertoy content is available under permissive licenses.

---

**AS-StageFX Version**: {{version}}
**Maintainer**: Leon Aquitaine
