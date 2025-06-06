# AS-StageFX Build System Modularization Plan

## 1. Catalog Management Script (manage-catalog.ps1)
- Scans shader source files and updates catalog.json
- Adds new entries, deduplicates, and updates statistics
- Removes obsolete/renamed entries
- Ensures only filename (not path) is stored
- No packaging, no template rendering

## 2. Template Rendering Script (render-templates.ps1)
- Loads catalog.json
- Renders README.md, docs, and other files from templates
- Injects statistics and (optionally) tables by filtering catalog.items at render time
- No catalog mutation, no packaging

## 3. Package Preparation/Deploy Script (prepare-packages.ps1)
- Loads catalog.json
- Prepares package folders, copies shaders, dependencies
- Generates package-manifest.json
- Creates ZIPs for distribution
- Cleans up temp/package folders
- No catalog mutation, no template rendering

## Data Flow
- manage-catalog.ps1 → catalog.json
- render-templates.ps1 ← catalog.json
- prepare-packages.ps1 ← catalog.json

## Next Steps
1. Extract catalog management logic from build-packages.ps1 to manage-catalog.ps1
2. Extract template rendering logic to render-templates.ps1
3. Extract packaging logic to prepare-packages.ps1
4. Update build-packages.ps1 to orchestrate or deprecate

---

This plan will be used to guide the script refactoring and modularization.
