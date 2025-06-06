# AS-StageFX Master Build Script
# Runs catalog management, template rendering, and package preparation in sequence
# Usage: pwsh ./tools/build-all.ps1

$ErrorActionPreference = 'Stop'

Write-Host "[INFO] Step 1: Updating catalog..."
pwsh ./tools/manage-catalog.ps1

Write-Host "[INFO] Step 2: Rendering templates..."
pwsh ./tools/render-templates.ps1

Write-Host "[INFO] Step 3: Preparing packages..."
pwsh ./tools/prepare-packages.ps1

Write-Host "[SUCCESS] All build steps completed."
