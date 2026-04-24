# AS-StageFX Catalog Management Script
# This script scans shader files and updates catalog.json (add, dedupe, update stats)
# Usage: pwsh ./tools/manage-catalog.ps1

param(
    [string]$ConfigPath = "$PSScriptRoot/../config/package-config.json",
    [string]$CatalogPath = "$PSScriptRoot/../shaders/catalog.json"
)

# Error handling for loading configuration file
if (-not (Test-Path $ConfigPath)) {
    Write-Host "[ERROR] Config file not found: $ConfigPath" -ForegroundColor Red
    exit 1
}

$shadersRoot = Split-Path -Parent $ConfigPath | Split-Path -Parent
$shaderDir = Join-Path $shadersRoot "shaders/AS"

# Get all .fx files (excluding [PRE] and others per config)
$shaderFiles = Get-ChildItem -Path $shaderDir -File -Filter "*.fx" | Where-Object { $_.Name -notmatch "^\[PRE\]" }

# Load or create catalog
if (Test-Path $CatalogPath) {
    $catalog = Get-Content -Path $CatalogPath -Raw | ConvertFrom-Json
    if ($null -eq $catalog) { $catalog = @() }
} else {
    $catalog = @()
}

# Deduplicate and update catalog
$existingFilenames = $catalog | ForEach-Object { $_.filename }
$newShaders = @()
foreach ($shaderFile in $shaderFiles) {
    $filenameOnly = $shaderFile.Name
    if (-not ($existingFilenames -contains $filenameOnly)) {
        if ($shaderFile.Name -match "AS_([A-Z]+)_") {
            $type = $matches[1].ToUpper()
        } else {
            $type = "OTHER"
        }
        # Create new shader entry with minimal required properties
        $newShader = @{ 
            filename = $filenameOnly
            type = $type
            name = ""  # Will be populated later from shader metadata
        }
        $newShaders += $newShader
        Write-Host "[NEW] Added shader: $filenameOnly (type: $type)" -ForegroundColor Green
    }
}
if ($newShaders.Count -gt 0) {
    $catalog += $newShaders
}
# Remove deleted/renamed shaders
$catalog = $catalog | Where-Object { $shaderFiles.Name -contains $_.filename }
# Sort (handle entries that might not have a name property yet)
$catalog = $catalog | Sort-Object -Property @{Expression={if($_.name) {$_.name} else {$_.filename}}}, filename
# Save
$catalog | ConvertTo-Json -Depth 20 | Set-Content -Path $CatalogPath -Encoding UTF8
Write-Host "[SUCCESS] catalog.json updated."

# --- Update shader-list.json ---
$shaderListPath = "$PSScriptRoot/../config/shader-list.json"
if (Test-Path $shaderListPath) {
    $shaderList = Get-Content -Path $shaderListPath -Raw | ConvertFrom-Json
    if ($null -eq $shaderList.shaders) { $shaderList.shaders = @() }
    
    # Get existing shader names from shader-list.json
    $existingShaderNames = $shaderList.shaders | ForEach-Object { $_.name }
    
    # Add new shaders to shader-list.json if they were added to catalog
    foreach ($newShader in $newShaders) {
        # Extract shader name without .fx extension (e.g., AS_VFX_VolumetricFog.1)
        $shaderName = [System.IO.Path]::GetFileNameWithoutExtension($newShader.filename)
        
        if (-not ($existingShaderNames -contains $shaderName)) {
            # Determine performance rating based on shader type
            $performance = switch ($newShader.type) {
                "BGX" { "Moderate" }  # Backgrounds tend to be more complex
                "VFX" { "Light" }     # Visual effects are often lighter
                "GFX" { "Light" }     # Graphics effects are usually light
                "LFX" { "Light" }     # Lighting effects are typically light
                default { "Light" }
            }
            
            # Create new shader entry for shader-list.json
            $newShaderListEntry = @{
                credits = @{
                    license = "Creative Commons Attribution 4.0 International"
                }
                name = $shaderName
                performance = $performance
                filename = $newShader.filename
                author = "Leon Aquitaine"
            }
            
            $shaderList.shaders += $newShaderListEntry
            Write-Host "[NEW] Added to shader-list.json: $shaderName (performance: $performance)" -ForegroundColor Green
        }
    }
    
    # Update count and save shader-list.json
    $shaderList.count = $shaderList.shaders.Count
    $shaderList.generated = Get-Date -Format "yyyy-MM-dd"
    
    # Remove deleted/renamed shaders from shader-list.json
    $validShaderNames = $shaderFiles | ForEach-Object { 
        [System.IO.Path]::GetFileNameWithoutExtension($_.Name) 
    }
    $originalCount = $shaderList.shaders.Count
    $shaderList.shaders = $shaderList.shaders | Where-Object { 
        $validShaderNames -contains $_.name 
    }
    $removedCount = $originalCount - $shaderList.shaders.Count
    if ($removedCount -gt 0) {
        Write-Host "[REMOVED] Cleaned up $removedCount deleted shaders from shader-list.json" -ForegroundColor Yellow
    }
    
    # Update final count
    $shaderList.count = $shaderList.shaders.Count
    
    $shaderList | ConvertTo-Json -Depth 10 | Set-Content -Path $shaderListPath -Encoding UTF8
    Write-Host "[SUCCESS] shader-list.json updated."
} else {
    Write-Host "[WARNING] shader-list.json not found: $shaderListPath" -ForegroundColor Yellow
}

# Group shaders by type for statistics
$groupedByType = @{}
foreach ($item in $catalog) {
    $type = $item.type
    if (-not $groupedByType.ContainsKey($type)) {
        $groupedByType[$type] = @()
    }
    $groupedByType[$type] += $item
}

# Build statistics object
$statistics = @{
    byType = @{}
    total = $catalog.Count
    grouped = $groupedByType
}
foreach ($type in $groupedByType.Keys) {
    $statistics.byType[$type] = $groupedByType[$type].Count
}

# Write catalog-statistics.json
$statistics | ConvertTo-Json -Depth 10 | Set-Content -Path "$PSScriptRoot/../shaders/catalog-statistics.json" -Encoding UTF8
Write-Host "[SUCCESS] catalog-statistics.json generated."

# Match available images to catalog entries
$imagesDir = Join-Path $shadersRoot "docs/res/img"
$githubBaseUrl = "https://raw.githubusercontent.com/LeonAquitaine/as-stagefx/main/docs/res/img"

if (Test-Path $imagesDir) {
    $availableImages = Get-ChildItem -Path $imagesDir -Filter "*.gif" | ForEach-Object { $_.Name }
    Write-Host "[INFO] Found $($availableImages.Count) image files in docs/res/img/"
      $matchedCount = 0
    $totalChecked = 0
    
    foreach ($entry in $catalog) {
        $totalChecked++
          # Generate expected image filename from shader filename
        # AS_VFX_WaterSurface.1.fx -> as-stagefx-watersurface.gif
        $shaderBaseName = [System.IO.Path]::GetFileNameWithoutExtension($entry.filename)
        # Remove AS_XXX_ prefix and version suffix
        if ($shaderBaseName -match "AS_[A-Z]+_(.+)\.(\d+)") {
            $effectName = $matches[1]
            
            # Define specific mappings for known mismatches
            $specificMappings = @{}
            
            # Check specific mappings first
            if ($specificMappings.ContainsKey($effectName)) {
                $specificImage = $specificMappings[$effectName]
                if ($availableImages -contains $specificImage) {
                    $githubUrl = "$githubBaseUrl/$specificImage"
                    $entry | Add-Member -NotePropertyName "imageUrl" -NotePropertyValue $githubUrl -Force
                    $matchedCount++
                    Write-Host "[MATCH] $($entry.name) -> $specificImage"
                    continue
                }
            }
            
            # Try automatic variations if no specific mapping found
            $variations = @(
                "as-stagefx-$($effectName.ToLower()).gif",
                "as-stagefx-$effectName.gif",
                "as-stagefx-$($effectName.ToUpper()).gif"
            )
            
            $found = $false
            foreach ($variation in $variations) {
                if ($availableImages -contains $variation) {
                    $githubUrl = "$githubBaseUrl/$variation"
                    $entry | Add-Member -NotePropertyName "imageUrl" -NotePropertyValue $githubUrl -Force
                    $matchedCount++
                    Write-Host "[MATCH] $($entry.name) -> $variation"
                    $found = $true
                    break
                }
            }
            
            if (-not $found) {
                Write-Host "[NO MATCH] $($entry.name) (tried: $($variations -join ', '))" -ForegroundColor DarkGray
            }
        }
    }
    
    Write-Host "[INFO] Image matching complete: $matchedCount matches out of $totalChecked entries"
} else {
    Write-Host "[WARNING] Images directory not found: $imagesDir" -ForegroundColor Yellow
}

# (Assume $catalogPath and $catalog are already loaded with error handling above)
# Remove duplicate loading and use $catalog for all operations

# Deduplicate by filename
$uniqueCatalog = @{}
foreach ($item in $catalog) {
    $uniqueCatalog[$item.filename] = $item
}
$catalog = $uniqueCatalog.Values

# Load package config for default license info
$packageConfig = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
$defaultLicenseDesc = $packageConfig.license.description
$defaultLicenseCode = $packageConfig.license.code

# Ensure every entry has a credits block with 'kind', and backfill licence/licenseCode
# only when they are MISSING. Hand-curated values in catalog.json (e.g. mrange's CC0,
# "N/A (inspiration only)") must never be silently overwritten by this step.
#
# Kind values:
#   port          - straight port from an external source (Shadertoy, GitHub, etc.)
#   port-adapted  - cross-platform adaptation (has platform + adaptedBy)
#   inspiration   - Leon Aquitaine original inspired by an external work
#   original      - Leon Aquitaine original (clean-room or from scratch)
function Get-DefaultKind($entry) {
    $c = $entry.credits
    if (-not $c) { return 'original' }
    if ($c.platform -and $c.adaptedBy) { return 'port-adapted' }
    if ($c.licence -like 'N/A (inspiration*') { return 'inspiration' }
    if ($c.licence -like 'N/A (original*') { return 'original' }
    if ($c.originalAuthor -and $c.externalUrl) { return 'port' }
    if ($c.description -and -not $c.originalAuthor) { return 'original' }
    return 'port'
}

foreach ($entry in $catalog) {
    # Ensure credits object exists; kind is required on every entry
    if (-not $entry.credits) {
        $entry | Add-Member -NotePropertyName 'credits' -NotePropertyValue ([PSCustomObject]@{ kind = 'original' }) -Force
    }
    if (-not $entry.credits.kind) {
        $kind = Get-DefaultKind $entry
        $entry.credits | Add-Member -NotePropertyName 'kind' -NotePropertyValue $kind -Force
    }

    # Backfill root licence/licenseCode only when missing
    $kind = $entry.credits.kind
    if (-not $entry.licence -or -not $entry.licenseCode) {
        # Root-level licence is the licence the shader FILE is distributed under,
        # which for originals and inspirations is always the package default
        # (CC BY 4.0). For pure ports it inherits the upstream licence.
        if ($kind -eq 'port' -or $kind -eq 'port-adapted') {
            if ($entry.credits.licence) {
                if (-not $entry.licence)     { $entry | Add-Member -NotePropertyName 'licence'     -NotePropertyValue $entry.credits.licence     -Force }
                if (-not $entry.licenseCode) { $entry | Add-Member -NotePropertyName 'licenseCode' -NotePropertyValue $entry.credits.licenseCode -Force }
            }
        } else {
            if (-not $entry.licence)     { $entry | Add-Member -NotePropertyName 'licence'     -NotePropertyValue $defaultLicenseDesc -Force }
            if (-not $entry.licenseCode) { $entry | Add-Member -NotePropertyName 'licenseCode' -NotePropertyValue $defaultLicenseCode -Force }
        }
    }

    # Backfill credits.licence only for ports that lack one (Shadertoy default).
    # Inspirations keep "N/A (inspiration only)"; originals don't need a credits.licence.
    if ($kind -eq 'port' -and $entry.credits.externalUrl -and -not $entry.credits.licence) {
        if ($entry.credits.externalUrl -match 'shadertoy\.com') {
            $entry.credits | Add-Member -NotePropertyName 'licence'     -NotePropertyValue 'CC BY-NC-SA 3.0 Unported' -Force
            $entry.credits | Add-Member -NotePropertyName 'licenseCode' -NotePropertyValue 'CC BY-NC-SA 3.0' -Force
        }
    }
}

# Sort by type, then name
$catalog = $catalog | Sort-Object type, name

# Write back to file
try {
    $catalog | ConvertTo-Json -Depth 10 | Set-Content -Path $CatalogPath -Encoding UTF8
    Write-Host "[SUCCESS] Catalog deduplicated, sorted, and written: $CatalogPath"
} catch {
    Write-Host "[ERROR] Failed to write catalog file: $CatalogPath" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# --- Regenerate as_shader_descriptor uniform in shader files from catalog credits ---
#
# Two behaviours worth calling out:
#  * Multi-line `uniform int as_shader_descriptor < ... >;` blocks are stripped as
#    a whole (not just their first line), so legacy hand-formatted descriptors
#    don't leave orphan annotation bodies.
#  * A file that has no existing descriptor is left alone — we don't inject one
#    into shaders that were intentionally kept greenfield. If a shader has a
#    descriptor we regenerate it from catalog credits; otherwise we skip it.
#  * Descriptor text branches on credits.kind; licences are copied verbatim
#    from the catalog (never overridden from a hardcoded default here).

function Format-ShaderDescriptor($entry) {
    $c = $entry.credits
    if (-not $c) { return $null }
    $kind = $c.kind
    $licence = $c.licence
    if (-not $licence) { $licence = $entry.licence }
    $lines = @()
    switch ($kind) {
        'port' {
            $title = $c.originalTitle
            $author = $c.originalAuthor
            if (-not $title -or -not $author) { return $null }
            $lines += "Based on '$title' by $author"
            if ($c.externalUrl) { $lines += "Link: $($c.externalUrl)" }
            if ($licence) { $lines += "Licence: $licence" }
        }
        'port-adapted' {
            $title = $c.originalTitle
            $author = $c.originalAuthor
            $platform = $c.platform
            if (-not $title -or -not $author) { return $null }
            $adaptedFrom = if ($platform) { "Adapted from '$title' by $author on $platform" } else { "Adapted from '$title' by $author" }
            $lines += $adaptedFrom
            if ($c.externalUrl) { $lines += "Link: $($c.externalUrl)" }
            if ($licence) { $lines += "Licence: $licence" }
        }
        'inspiration' {
            $title = $c.originalTitle
            $author = $c.originalAuthor
            $lines += 'Original work by Leon Aquitaine'
            if ($title -and $author) {
                $lines += "Inspired by '$title' by $author"
                if ($c.externalUrl) { $lines += "Link: $($c.externalUrl)" }
            }
            $lines += "Licence: $($entry.licence)"
        }
        'original' {
            $lines += 'Original work by Leon Aquitaine'
            $lines += "Licence: $($entry.licence)"
        }
        default { return $null }
    }
    # Assemble as an HLSL string literal with literal \n separators and trailing blank line
    $joined = ($lines -join '\n')
    $uiText = "\n$joined\n\n"
    $uiTextEscaped = $uiText -replace '"', '\\"'
    return 'uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "' + $uiTextEscaped + '";>;'
}

function Remove-ExistingShaderDescriptor($text) {
    # Remove the entire `uniform int as_shader_descriptor < ... >;` block, whether
    # it's written on a single line, spans multiple lines, or carries a default-
    # value tail like `> = 0;`. Returns a tuple (new text, removed?).
    #
    # Uses `<[^>]*>` rather than `<.*?>` so annotation contents that include `;`
    # can't make the match drift into the next uniform's closing `>;` — the
    # annotation body never legitimately contains a `>` character, so bounding
    # on non-`>` is both safer and more predictable.
    $pattern = '(?sm)^[ \t]*uniform\s+int\s+as_shader_descriptor\s*<[^>]*>\s*(=\s*[^;]*)?\s*;[ \t]*\r?\n?'
    $regex = [regex]::new($pattern)
    if ($regex.IsMatch($text)) {
        return @($regex.Replace($text, ''), $true)
    }
    return @($text, $false)
}

foreach ($entry in $catalog) {
    $shaderPath = Join-Path $shaderDir $entry.filename
    if (-not (Test-Path $shaderPath)) {
        Write-Host "[WARN] Shader file not found: $shaderPath" -ForegroundColor Yellow
        continue
    }

    $descUniform = Format-ShaderDescriptor $entry
    if (-not $descUniform) {
        Write-Host "[WARN] Could not build descriptor for $($entry.filename) (kind=$($entry.credits.kind))" -ForegroundColor Yellow
        continue
    }

    $shaderText = Get-Content -Path $shaderPath -Raw -Encoding UTF8 -ErrorAction Stop
    $stripResult = Remove-ExistingShaderDescriptor $shaderText
    $stripped = $stripResult[0]
    $hadDescriptor = $stripResult[1]

    if (-not $hadDescriptor) {
        # Greenfield shader without a descriptor — leave it untouched.
        continue
    }

    # Reinsert at the same anchor: first line that starts a uniform or AS_ UI macro,
    # skipping lines inside #define macro bodies.
    $lines = $stripped -split "`r?`n"
    $insertIdx = -1
    $inMacro = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^\s*#\s*define') { $inMacro = $true }
        elseif ($inMacro -and ($line -match '^\s*$' -or $line -match '^\s*#')) { $inMacro = $false }
        if (-not $inMacro -and ($line -match '^\s*uniform\s' -or $line -match '^\s*AS_[A-Z_]+')) {
            $insertIdx = $i
            break
        }
    }
    if ($insertIdx -lt 0) {
        Write-Host "[WARN] No uniform or AS_ UI macro group found in $($entry.filename), skipping descriptor insert." -ForegroundColor Yellow
        continue
    }

    $afterDescriptor = if ($insertIdx -lt $lines.Count -and $lines[$insertIdx] -ne '') { @('') } else { @() }
    $newLines = $lines[0..($insertIdx-1)] + $descUniform + $afterDescriptor + $lines[$insertIdx..($lines.Count-1)]
    Set-Content -Path $shaderPath -Value ($newLines -join "`r`n") -Encoding UTF8
    Write-Host "[INFO] Updated as_shader_descriptor in $($entry.filename) (kind=$($entry.credits.kind))"
}

# --- Cleanup: Remove duplicated empty lines and trim file end ---
foreach ($shaderFile in $shaderFiles) {
    $shaderPath = $shaderFile.FullName
    if (Test-Path $shaderPath) {
        $shaderText = Get-Content -Path $shaderPath -Raw -Encoding UTF8        # Replace all duplicated newlines (2+ in a row) with a single newline, repeatedly until none remain
        do {
            $oldText = $shaderText
            $shaderText = $shaderText -replace "(\r?\n){3,}", "`r`n`r`n"
        } while ($shaderText -ne $oldText)
        # Trim trailing whitespace and newlines from the end of the file
        $shaderText = ($shaderText -join "`r`n").TrimEnd()
        Set-Content -Path $shaderPath -Value $shaderText -Encoding UTF8
    }
}