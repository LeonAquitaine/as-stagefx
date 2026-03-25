#!/usr/bin/env pwsh
# validate-shader-style.ps1 - Quick style checks for AS-StageFX shaders
# Goals: ensure single-line uniform declarations, technique guards, includes order, and no legacy shim usage

param(
    [switch]$FailOnIssues = $false
)

$root = Join-Path $PSScriptRoot ".."
$shadersDir = Join-Path $root "shaders"

$issues = @()

# Counters by severity
$errorCount = 0
$warningCount = 0
$infoCount = 0

# Helper to add issue with severity
function Add-Issue([string]$file, [string]$message, [string]$severity = "WARN") {
    $script:issues += [PSCustomObject]@{ File = $file; Message = $message; Severity = $severity }
    switch ($severity) {
        "ERROR"   { $script:errorCount++ }
        "WARNING" { $script:warningCount++ }
        "INFO"    { $script:infoCount++ }
        default   { $script:warningCount++ }
    }
}

# Deprecated function -> replacement mapping
$deprecatedFunctions = @{
    'AS_applyAudioReactivity('   = 'AS_audioModulate()'
    'AS_applyAudioReactivityEx(' = 'AS_audioModulate()'
    'AS_getAudioSource('         = 'AS_audioLevelFromSource()'
    'AS_getTime('                = 'AS_timeSeconds()'
    'AS_applyRotation('          = 'AS_rotate2D()'
    'AS_transformCoord('         = 'AS_transformUVCentered()'
    'AS_applyPosScale('          = 'AS_applyPositionAndScale()'
}

# Utility shader basenames that are excluded from BlendMode UI check
$utilityShaders = @(
    'AS_GFX_AspectRatio',
    'AS_GFX_MultiLayerHalftone',
    'AS_VFX_ColorBalancer'
)

# Check each .fx file (excluding [PRE])
Get-ChildItem -Path $shadersDir -Recurse -File -Include *.fx | Where-Object { $_.Name -notmatch "^\[PRE\]" } | ForEach-Object {
    $file = $_.FullName
    $name = $_.Name
    $content = Get-Content -Path $file -Raw

    # 1) Technique guard present
    if ($content -notmatch "#ifndef\s+__[A-Za-z0-9_]+_fx") {
        Add-Issue $name "Missing technique guard (#ifndef __SHADER_IDENTIFIER_fx)"
    }
    if ($content -notmatch "#define\s+__[A-Za-z0-9_]+_fx") {
        Add-Issue $name "Missing technique guard #define"
    }
    if ($content -notmatch "#endif\s+//\s+__[A-Za-z0-9_]+_fx") {
        Add-Issue $name "Missing technique guard #endif comment"
    }

    # 2) Includes order
    $incUtils = '#include\s+"AS_Utils\.1\.fxh"'
    $incOrder = '#include\s+"ReShade\.fxh"[\s\S]*#include\s+"AS_Utils\.1\.fxh"'
    if (($content -match $incUtils) -and ($content -notmatch $incOrder)) {
        Add-Issue $name "Include order should be: ReShade.fxh before AS_Utils.1.fxh"
    }

    # 3) Legacy shim usage
    $legacyPatterns = @("\bAS_transformCoord\b", "\bAS_applyPosScale\b", "\brot_hlsl\b", "\bbox_hlsl\b", "\bRot\(", "\bstanh\(")
    foreach ($pat in $legacyPatterns) {
        if ($content -match $pat) {
            Add-Issue $name "Legacy shim/reference detected: $pat"
        }
    }

    # 4) Single-line uniform declarations: flag any 'uniform' line where '<' appears without a matching '>' on the same line
    $lines = $content -split "`r?`n"
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        if ($line -match '^\s*uniform\b' -and $line -match '<' -and $line -notmatch '>') {
            Add-Issue $name "Potential multi-line uniform declaration; prefer single-line for parser tooling"
            break
        }
    }

    # =========================================================================
    # NEW CHECKS
    # =========================================================================

    # 5) Deprecated function usage
    foreach ($funcCall in $deprecatedFunctions.Keys) {
        $replacement = $deprecatedFunctions[$funcCall]
        # Extract just the function name (without trailing paren) for word-boundary matching
        $funcName = $funcCall.TrimEnd('(')
        # Match the function call but NOT inside single-line comments or #define lines
        # We check line-by-line to skip comment-only lines
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            # Skip lines that are full-line comments or preprocessor definitions (in the utils header)
            if ($trimmed -match '^\s*//' -or $trimmed -match '^\s*#define\b' -or $trimmed -match '^\s*\*') {
                continue
            }
            # Strip inline trailing comments before checking
            $codePart = $line -replace '//.*$', ''
            if ($codePart -match [regex]::Escape($funcCall)) {
                Add-Issue $name "WARNING: Uses deprecated function '$funcName'. Use '$replacement' instead." "WARNING"
                break  # One warning per function per file
            }
        }
    }

    # 6) Namespace naming convention - AS[A-Z] without underscore
    if ($content -match 'namespace\s+(AS[A-Z][A-Za-z0-9]*)') {
        $nsName = $Matches[1]
        # Only flag if there is no underscore after 'AS' (i.e., ASFoo instead of AS_Foo)
        if ($nsName -match '^AS[A-Z]' -and $nsName -notmatch '^AS_') {
            $corrected = $nsName -replace '^AS', 'AS_'
            Add-Issue $name "WARNING: Namespace '$nsName' should use underscore: '$corrected'" "WARNING"
        }
    }

    # 7) fmod() usage (not in comments)
    $fmodFound = $false
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        # Skip comment-only lines
        if ($trimmed -match '^\s*//' -or $trimmed -match '^\s*\*') {
            continue
        }
        # Strip inline trailing comments
        $codePart = $line -replace '//.*$', ''
        if ($codePart -match '\bfmod\s*\(') {
            $fmodFound = $true
            break
        }
    }
    if ($fmodFound) {
        Add-Issue $name "WARNING: Uses fmod() which has undefined behavior with negative values. Use AS_mod() instead." "WARNING"
    }

    # 8) Missing BlendMode UI (skip utility shaders)
    $baseName = $name -replace '\.1\.fx$', '' -replace '\.fx$', ''
    $isUtility = $utilityShaders -contains $baseName
    if (-not $isUtility) {
        if ($content -notmatch 'AS_BLENDMODE_UI' -and $content -notmatch 'BLENDING_COMBO') {
            Add-Issue $name "INFO: Missing BlendMode UI. Consider adding AS_BLENDMODE_UI for compositing control." "INFO"
        }
    }

    # 9) Technique guard naming convention
    #    Expected pattern: __AS_Category_Name_1_fx (derived from filename AS_Category_Name.1.fx)
    $expectedGuard = '__' + ($name -replace '\.', '_')
    if ($content -match '#ifndef\s+(__[A-Za-z0-9_]+_fx\b[A-Za-z0-9_]*)') {
        $actualGuard = $Matches[1]

        # Check for ALL_CAPS guards (the guard should use mixed case matching the filename)
        $isAllCaps = $actualGuard -cmatch '__AS_[A-Z0-9_]+$' -and $actualGuard -cnotmatch '[a-z]'
        # Check for missing version suffix (should end with _1_fx for .1.fx files)
        $missingVersion = ($name -match '\.1\.fx$') -and ($actualGuard -notmatch '_1_fx')
        # Check that the guard matches the expected pattern derived from filename
        $guardMismatch = $actualGuard -cne $expectedGuard

        if ($isAllCaps -or $missingVersion) {
            Add-Issue $name "WARNING: Technique guard '$actualGuard' doesn't follow naming convention '$expectedGuard'" "WARNING"
        }
    }
}

# Report
if ($issues.Count -eq 0) {
    Write-Host "[SUCCESS] Style validation passed." -ForegroundColor Green
    exit 0
}

Write-Host "[WARN] Style validation found $($issues.Count) issues:" -ForegroundColor Yellow

# Display with severity-appropriate colors
$issues | ForEach-Object {
    $color = switch ($_.Severity) {
        "ERROR"   { "Red" }
        "WARNING" { "DarkYellow" }
        "INFO"    { "Cyan" }
        default   { "DarkYellow" }
    }
    Write-Host (" - {0}: {1}" -f $_.File, $_.Message) -ForegroundColor $color
}

# Summary by severity
Write-Host ""
Write-Host "Summary: $errorCount error(s), $warningCount warning(s), $infoCount info(s)" -ForegroundColor White

if ($FailOnIssues) {
    Write-Error "Style issues detected. Failing as requested (-FailOnIssues)."
    exit 3
}

exit 0
