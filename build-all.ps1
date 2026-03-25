# AS-StageFX Master Build Script
# Runs catalog management, template rendering, and package preparation in sequence
# Usage:
#   pwsh ./build-all.ps1
#   pwsh ./build-all.ps1 -Strict   # exits non-zero if pre-release or style issues are detected

param(
	[switch]$Strict = $false
)

$ErrorActionPreference = 'Stop'

Write-Host "[INFO] Step 1: Updating catalog..."
pwsh ./tools/manage-catalog.ps1

Write-Host "[INFO] Step 2: Rendering templates..."
pwsh ./tools/render-templates.ps1

Write-Host "[INFO] Step 3: Preparing packages..."
pwsh ./tools/prepare-packages.ps1

Write-Host "[INFO] Step 4: Pre-Release checklist..."
if ($Strict) {
	pwsh ./tools/pre-release-checklist.ps1 -FailOnIssues
}
else {
	pwsh ./tools/pre-release-checklist.ps1
}

Write-Host "[INFO] Step 5: Style & standards validation..."
if ($Strict) {
	pwsh ./tools/validate-shader-style.ps1 -FailOnIssues
}
else {
	pwsh ./tools/validate-shader-style.ps1
}

Write-Host "[SUCCESS] All build steps completed."
