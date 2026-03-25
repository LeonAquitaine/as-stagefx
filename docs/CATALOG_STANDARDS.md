# Catalog & Deployment Standards

This document defines the standards for `shaders/catalog.json` and preview images to keep packaging and documentation consistent.

## Catalog entries
Each entry should include:
- `filename`: Exact shader file name, e.g., `AS_GFX_VignettePlus.1.fx`
- `type`: One of `BGX`, `GFX`, `VFX`, `LFX`, `AFX`
- `name`: Human-friendly display name
- `shortDescription`: 1–2 line summary for gallery
- `imageUrl`: Raw GitHub URL to `docs/res/img/as-stagefx-<slug>.gif`

Notes:
- The `<slug>` should match the display name in lowercase and without spaces/punctuation: `as-stagefx-tiltshift.gif`.
- For unnamed entries, default the slug to the filename without the `AS_XXX_` prefix and `.1.fx` suffix.

## Preview images
- Path: `docs/res/img/as-stagefx-<slug>.gif`
- Dimensions: 640×360 or 640×640 (square effects); keep file sizes modest.
- Content: short loop demonstrating the core effect.

## Validation
- Run `pwsh ./build-all.ps1` for a quick check.
- Run `pwsh ./build-all.ps1 -Strict` to fail if missing or broken images are detected.
- Use `tools/pre-release-checklist.ps1 -ShowDetails` to inspect issues.

## Packaging
- Packages are defined by `config/package-config.json`.
- Pre-release shaders (matching exclude patterns like `^\[PRE\]`) are skipped.
- Dependencies are auto-detected from `#include` statements and texture `source` attributes.

## Change workflow
1. Add/update a shader.
2. Add/update its catalog entry with name, description, and imageUrl.
3. Add the preview GIF to `docs/res/img/`.
4. Build with `-Strict` and fix any reported issues.

## Anti-patterns to avoid
- Missing `imageUrl` or broken links in the catalog.
- Using ad-hoc image names that break the naming convention.
- Duplicated description text across entries.

By following these standards, the gallery, packages, and docs stay in sync and reliable.
