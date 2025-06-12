# Changelog

## [1.9.1] - 2025-06-11

### New Features
- Introduced a Focus Frame effect that highlights a central area with customizable size, aspect ratio, edge softness, background blur, zoom, and brightness. The effect supports depth masking, blending controls, and debug visualization.
- Added a Tilt-Shift / Depth of Field effect featuring depth-aware, high-quality blurring with adjustable focus depth, focus zone size, falloff curve, and maximum blur amount. Includes a debug overlay to visualize the focus line.
- Added visible attribution and license information for original shader inspirations directly in the UI of many shader effects.

### Style
- Updated and corrected aspect ratio preset labels for improved clarity.
- Standardized and cleaned up image URLs and license fields in shader catalogs.
- Improved consistency in shader file formatting by removing extraneous blank lines and trailing whitespace.

## [1.8.4] - 2025-06-06

### New Features
- Introduced a multiscale recursive Quadtree Truchet background effect with advanced palette options, animation, and audio reactivity.
- Added an audio direction visualization effect that displays a reactive arc indicating audio panning.
- Released a cinematic diffusion filter with multiple presets for high-quality bloom and glow effects.
- Enhanced audio features with stereo support, including left/right channel volume and panning controls.
- Added a split-screen debug mode to the Cinematic Diffusion effect, allowing side-by-side comparison of original and processed images.
- Introduced new controls and UI enhancements to the Sunset Clouds effect, including rotation, depth settings, and a new raymarch depth parameter.

### Documentation
- Updated documentation and galleries to reflect new shaders and expanded audio capabilities.
- Added comprehensive shader galleries with detailed descriptions and images.
- Replaced shader template README with a high-level project overview and installation guide.
- Updated gallery documentation to display visual examples for multiple effects by adding image URLs.
- Improved organization and completeness of shader catalog data and gallery documentation.

### Chores
- Added modular build scripts to streamline catalog management, template rendering, and package preparation.
- Automated shader catalog updates and README generation integrated into build process.
- Incremented version numbers and updated build metadata.
- Standardized and reorganized JSON metadata for improved clarity and consistency.
- Reorganized and regrouped shader catalog data for better structure and maintainability.
- Removed a deprecated shader entry from the catalog.
- Automated the addition of attribution metadata to shader files.
