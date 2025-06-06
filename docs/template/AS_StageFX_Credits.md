<!-- filepath: docs/template/AS_StageFX_Credits.md -->
# AS-StageFX External Credits and Attribution

**Repository**: AS-StageFX ReShade Shader Collection  

This document lists all external sources, original authors, and inspiration credits for the AS-StageFX shader collection. The majority of the shaders are adaptations and ports, but proper attribution to original creators is maintained as required by Creative Commons licensing.

---

## Shadertoy & External Adaptations (BGX)
{{#each grouped.BGX}}
### {{filename}} - {{name}}
- **Original Author**: {{credits.originalAuthor}}
- **Original Title**: {{credits.originalTitle}}
- **Notes**: {{credits.description}}
- **Source**: {{credits.externalUrl}}

{{/each}}

## Shadertoy & External Adaptations (VFX)
{{#each grouped.VFX}}
### {{filename}} - {{name}}
- **Original Author**: {{credits.originalAuthor}}
- **Original Title**: {{credits.originalTitle}}
- **Notes**: {{credits.description}}
- **Source**: {{credits.externalUrl}}

{{/each}}

## Shadertoy & External Adaptations (GFX)
{{#each grouped.GFX}}
### {{filename}} - {{name}}
- **Original Author**: {{credits.originalAuthor}}
- **Original Title**: {{credits.originalTitle}}
- **Notes**: {{credits.description}}
- **Source**: {{credits.externalUrl}}

{{/each}}

## Shadertoy & External Adaptations (LFX)
{{#each grouped.LFX}}
### {{filename}} - {{name}}
- **Original Author**: {{credits.originalAuthor}}
- **Original Title**: {{credits.originalTitle}}
- **Notes**: {{credits.description}}
- **Source**: {{credits.externalUrl}}

{{/each}}

---

## Attribution Notice

All adaptations maintain proper attribution to original creators as required by Creative Commons licensing. When using these shaders, please ensure you include attribution to both Leon Aquitaine (for the ReShade adaptation and AS framework integration) and the original creators listed above.

For commercial use, please verify licensing terms with original creators where applicable, though most Shadertoy content is available under permissive licenses.

---

**Compilation Date**: {{date}}  
**AS-StageFX Version**: {{version}}  
**Maintainer**: Leon Aquitaine
