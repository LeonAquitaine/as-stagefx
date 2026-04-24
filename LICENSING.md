# AS-StageFX Licensing

AS-StageFX is a collection of shaders distributed under **multiple licences** — each shader's licence is documented in its file header and in [README.md](README.md). This document explains the overall licensing model so consumers can use the shaders correctly.

---

## Quick reference — what licence does each shader use?

| Shader category | Licence |
|---|---|
| **Original works by Leon Aquitaine** (most GFX, LFX, and many VFX effects) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |
| **Original works inspired by external creators** (AS_VFX_BoomSticker, AS_VFX_ClairObscur, AS_VFX_TiltedGrid) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |
| **Ports of works explicitly dedicated to public domain** (AS_BGX_GoldenClockwork, AS_BGX_LogSpirals) | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| **Ports of works from Shadertoy without custom licence** (most BGX, several VFX, some GFX) | [CC BY-NC-SA 3.0 Unported](https://creativecommons.org/licenses/by-nc-sa/3.0/) |
| **Ports with explicit upstream CC BY-NC-SA** (AS_VFX_RainyWindow) | [CC BY-NC-SA 3.0 Unported](https://creativecommons.org/licenses/by-nc-sa/3.0/) |
| **Shaders produced via clean-room reimplementation from behavioural spec** (AS_BGX_MeltWave, AS_BGX_Constellation, AS_BGX_LiquidChrome) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) — see Section 5 |

The authoritative per-shader licence is documented in:
- The **file header** of each `.fx` file (the licence line near the top)
- The **AS-StageFX ui_text** shown inside ReShade (near the top of each shader's UI panel)
- The **License** column in the table in [README.md](README.md)
- The **Licence** field in [AS_StageFX_Credits.md](AS_StageFX_Credits.md) (for adapted shaders)

If any of these disagree, treat the `.fx` file header as authoritative.

---

## 1. What each licence permits

### CC BY 4.0 — Attribution
- Commercial and non-commercial use permitted
- Modification and redistribution permitted
- You must give appropriate credit to Leon Aquitaine and link to the licence
- No requirement to share derivatives under the same licence

### CC0 1.0 — Public Domain Dedication
- Any use permitted, commercial or non-commercial
- No attribution legally required (though good practice)
- No warranty, no liability

### CC BY-NC-SA 3.0 Unported — Attribution, Non-Commercial, ShareAlike
- **Non-commercial use only** (no selling, no monetised video with commercial ads beyond fair-use limits, etc.)
- Modification and redistribution permitted for non-commercial purposes
- You must give appropriate credit to both Leon Aquitaine AND the original upstream author
- Derivatives must be distributed under the same CC BY-NC-SA 3.0 licence

---

## 2. Why the mixed model?

Most AS-StageFX shaders began as ports/adaptations of work published by other authors on [Shadertoy](https://www.shadertoy.com/). Shadertoy's terms ([shadertoy.com/terms](https://www.shadertoy.com/terms)) state:

> Users decide which license applies to every shader they create, and if you don't place a license on a shader, it will be protected by the default Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

The **ShareAlike clause** of CC BY-NC-SA 3.0 requires that any derivative work be distributed under a compatible licence. This is why most BGX effects inherit **CC BY-NC-SA 3.0 Unported** — not because Leon Aquitaine chose that licence, but because the upstream Shadertoy authors (implicitly or explicitly) did.

Where the upstream author explicitly chose a more permissive licence (e.g. mrange's CC0 grants for `Golden apollian` and `Logarithmic spiral of spheres`), that more permissive licence propagates.

Where a shader is Leon's own original implementation — even when inspired by a tutorial or concept from someone else — the project's default of **CC BY 4.0** applies.

---

## 3. Attribution requirements

### When using AS-StageFX shaders in video/screenshots/content

- **CC BY 4.0 shaders**: credit "AS-StageFX by Leon Aquitaine" (or similar) in a visible location (video description, end credits, post caption).
- **CC BY-NC-SA 3.0 shaders**: credit **both** Leon Aquitaine (for the ReShade port) **and** the original upstream author (listed in [AS_StageFX_Credits.md](AS_StageFX_Credits.md)). Content must be non-commercial.
- **CC0 shaders**: attribution is not legally required but appreciated.

### When redistributing or modifying the shader code

- Preserve the licence header in each `.fx` file.
- Preserve the `as_shader_descriptor` ui_text block that names the upstream author.
- For CC BY-NC-SA shaders: your modifications must also be released under CC BY-NC-SA 3.0 or a compatible licence.

---

## 4. Translation and localisation

Translating the UI text, tooltips, and descriptions of these shaders into another language **is permitted under each shader's own licence**:

- **CC BY 4.0 shaders** — translate freely with attribution.
- **CC0 shaders** — translate freely, no attribution required.
- **CC BY-NC-SA 3.0 shaders** — translation is permitted for non-commercial use, the translated version must be CC BY-NC-SA 3.0, and attribution to both Leon Aquitaine and the original upstream author must be preserved.

Translators are welcome to contact Leon Aquitaine to have their translations hosted upstream.

---

## 5. Clean-room reimplementation history (2026-04-24)

Three shaders in the BGX category were originally ports of external works with problematic licensing (ambiguous author restrictions, Neort platform without explicit redistribution grant, etc.). On 2026-04-24 these were replaced with clean-room original implementations produced from behavioural specifications (see [docs/specs/](docs/specs/)).

| Shader | Spec | Implementation licence |
|---|---|---|
| [AS_BGX_MeltWave.1.fx](shaders/AS/AS_BGX_MeltWave.1.fx) | [spec](docs/specs/AS_BGX_MeltWave.spec.md) | CC BY 4.0 |
| [AS_BGX_Constellation.1.fx](shaders/AS/AS_BGX_Constellation.1.fx) | [spec](docs/specs/AS_BGX_Constellation.spec.md) | CC BY 4.0 |
| [AS_BGX_LiquidChrome.1.fx](shaders/AS/AS_BGX_LiquidChrome.1.fx) | [spec](docs/specs/AS_BGX_LiquidChrome.spec.md) | CC BY 4.0 |

**Clean-room integrity process used:**

1. A behavioural specification was written describing *what* each shader must do (visual character, UI contract, pipeline steps) without revealing implementation details (algorithms, formulas, constants, code structure).
2. Three separate clean-room implementer agents — each with no prior exposure to the original shader code — were given only the specification and the AS framework headers.
3. Each implementer designed their own techniques satisfying the specification.
4. The tainted originals were overwritten by the new implementations.

The resulting implementations share no code with any prior work and are distributed as Leon Aquitaine originals under the AS-StageFX project licence (CC BY 4.0). The specifications themselves remain available in [docs/specs/](docs/specs/) as a record of the process.

---

## 6. Contact

For licensing questions, commercial licensing inquiries, or to report a licensing issue:

- **Maintainer**: Leon Aquitaine
- **Repository**: [github.com/LeonAquitaine/as-stagefx](https://github.com/LeonAquitaine/as-stagefx)
- **Issues**: [github.com/LeonAquitaine/as-stagefx/issues](https://github.com/LeonAquitaine/as-stagefx/issues)

If you are an upstream author whose work is credited here and you would like to change the attribution or ask for a shader to be removed, please open an issue or contact the maintainer directly — your wishes will be honoured.

---

**Last updated**: 2026-04-24
