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
        $newShaders += @{ filename = $filenameOnly; type = $type }
    }
}
if ($newShaders.Count -gt 0) {
    $catalog += $newShaders
}
# Remove deleted/renamed shaders
$catalog = $catalog | Where-Object { $shaderFiles.Name -contains $_.filename }
# Sort
$catalog = $catalog | Sort-Object -Property name, filename
# Save
$catalog | ConvertTo-Json -Depth 20 | Set-Content -Path $CatalogPath -Encoding UTF8
Write-Host "[SUCCESS] catalog.json updated."

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

# Set licence and license code for all shaders and update credits block
foreach ($entry in $catalog) {
    $isShadertoy = $false
    if ($entry.credits -and $entry.credits.externalUrl -and ($entry.credits.externalUrl -match 'shadertoy.com')) {
        $entry | Add-Member -NotePropertyName 'licence' -NotePropertyValue 'CC Share-Alike Non-Commercial' -Force
        $entry | Add-Member -NotePropertyName 'licenseCode' -NotePropertyValue 'CC BY-NC-SA' -Force
        $entry.credits | Add-Member -NotePropertyName 'licence' -NotePropertyValue 'CC Share-Alike Non-Commercial' -Force
        $entry.credits | Add-Member -NotePropertyName 'licenseCode' -NotePropertyValue 'CC BY-NC-SA' -Force
        $isShadertoy = $true
    }
    if (-not $isShadertoy) {
        $entry | Add-Member -NotePropertyName 'licence' -NotePropertyValue $defaultLicenseDesc -Force
        $entry | Add-Member -NotePropertyName 'licenseCode' -NotePropertyValue $defaultLicenseCode -Force
        if ($entry.credits) {
            $entry.credits | Add-Member -NotePropertyName 'licence' -NotePropertyValue $defaultLicenseDesc -Force
            $entry.credits | Add-Member -NotePropertyName 'licenseCode' -NotePropertyValue $defaultLicenseCode -Force
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

# --- Update as_shader_descriptor in shader files based on catalog credits ---
foreach ($entry in $catalog) {
    if ($entry.credits) {
        $shaderPath = Join-Path $shaderDir $entry.filename
        if (Test-Path $shaderPath) {
            $shaderLines = Get-Content -Path $shaderPath -Raw -Encoding UTF8 -ErrorAction Stop -Force | ForEach-Object { $_ -split "`r?`n" }
            # Remove any existing as_shader_descriptor uniform lines (anywhere)
            $shaderLines = $shaderLines | Where-Object { $_ -notmatch '^\s*uniform\s+int\s+as_shader_descriptor' }
            # Build descriptor text with /n for line breaks
            $descText = "Based on '$($entry.credits.originalTitle)' by $($entry.credits.originalAuthor)\nLink: $($entry.credits.externalUrl)"
            $uiText = "\n$descText\n"
            if ($entry.licence) {
                $uiText += "Licence: $($entry.licence)\n\n"
            }
            # Escape only double quotes for HLSL string
            $uiTextEscaped = $uiText -replace '"', '\\"'
            $descUniform = 'uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "' + $uiTextEscaped + '";>;' 
            # Find first uniform or AS_ UI macro line not inside a macro
            $insertIdx = -1
            $inMacro = $false
            for ($i = 0; $i -lt $shaderLines.Count; $i++) {
                $line = $shaderLines[$i]
                if ($line -match '^\s*#\s*define') { $inMacro = $true }
                elseif ($inMacro -and ($line -match '^\s*$' -or $line -match '^\s*#')) { $inMacro = $false }
                if (-not $inMacro -and ($line -match '^\s*uniform ' -or $line -match '^\s*AS_[A-Z_]+')) {
                    $insertIdx = $i
                    break
                }
            }
            if ($insertIdx -ge 0) {
                # Only insert a blank line if the next line is not already blank
                $afterDescriptor = if ($insertIdx -lt $shaderLines.Count -and $shaderLines[$insertIdx] -ne '') { @('') } else { @() }
                $shaderLines = $shaderLines[0..($insertIdx-1)] + $descUniform + $afterDescriptor + $shaderLines[$insertIdx..($shaderLines.Count-1)]
                Set-Content -Path $shaderPath -Value ($shaderLines -join "`r`n") -Encoding UTF8
                Write-Host "[INFO] Updated as_shader_descriptor in $($entry.filename)"
            } else {
                Write-Host "[WARN] No uniform or AS_ UI macro group found in $($entry.filename), skipping descriptor insert." -ForegroundColor Yellow
            }
        } else {
            Write-Host "[WARN] Shader file not found: $shaderPath" -ForegroundColor Yellow
        }
    }
}

# --- Cleanup: Remove duplicated empty lines and trim file end ---
foreach ($shaderFile in $shaderFiles) {
    $shaderPath = $shaderFile.FullName
    if (Test-Path $shaderPath) {
        $shaderText = Get-Content -Path $shaderPath -Raw -Encoding UTF8
        # Replace all duplicated newlines (2+ in a row) with a single newline, repeatedly until none remain
        do {
            $oldText = $shaderText
            $shaderText = $shaderText -replace "(\r?\n){3,}", "`r`n`r`n"
        } while ($shaderText -ne $oldText)
        # Trim trailing whitespace and newlines from the end of the file
        $shaderText = $shaderText.TrimEnd()
        Set-Content -Path $shaderPath -Value $shaderText -Encoding UTF8
    }
}