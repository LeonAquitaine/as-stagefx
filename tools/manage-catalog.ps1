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
            $specificMappings = @{
                "CandleFlame" = "as-stagefx-Candle.gif"
                "ClairObscur" = "as-stagefx-ClairObscur.gif"
                "RadiantFire" = "as-stagefx-radiantfire.gif"
                "SpectrumRing" = "as-stagefx-SpectrumRing.gif"
                "StageSpotlights" = "as-stagefx-Spotlights.gif"
                "StencilMask" = "as-stagefx-StencilMask.gif"
                "VUMeter" = "as-stagefx-VUMeter.gif"
                "WarpDistort" = "as-stagefx-Warp.gif"
                "WaterSurface" = "as-stagefx-watersurface.gif"
                "LightWall" = "as-stagefx-LightWall.gif"
                "SparkleBloom" = "as-stagefx-sparklebloom.gif"
                "BoomSticker" = "as-stagefx-BoomSticker.gif"
                "DigitalGlitch" = "as-stagefx-DigitalGlitch.gif"
                "LaserCannon" = "as-stagefx-LaserCannon.gif"
                "LightTrail" = "as-stagefx-LightTrail.gif"
                "PlasmaFlow" = "as-stagefx-PlasmaFlow.gif"
                "WavySquares" = "as-stagefx-wavysquares.gif"
                "WavySquiggles" = "as-stagefx-wavysquiggles.gif"
                "ZippyZaps" = "as-stagefx-zippyzaps.gif"
                "BlueCorona" = "as-stagefx-bluecorona.gif"
                "CosmicKaleidoscope" = "as-stagefx-cosmickaleidoscope.gif"
                "DigitalBrain" = "as-stagefx-digitalbrain.gif"
                "GoldenClockwork" = "as-stagefx-goldenclockwork.gif"
                "LightRipples" = "as-stagefx-lightripples.gif"
                "MeltWave" = "as-stagefx-meltwave.gif"
                "MistyGrid" = "as-stagefx-mistygrid.gif"
                "ShineOn" = "as-stagefx-shineon.gif"
                "StainedLights" = "as-stagefx-stainedlights.gif"
                "TimeCrystal" = "as-stagefx-timecrystal.gif"
                "VignettePlus" = "as-stagefx-vignetteplus.gif"
                "AspectRatio" = "as-stagefx-aspectratio.gif"
                "HalfTone" = "as-stagefx-halftone.gif"
                "Grid" = "as-stagefx-grid.gif"
                "Rain" = "as-stagefx-rain.gif"
                "Constellation" = "as-stagefx-constellation.gif"
                "CorridorTravel" = "as-stagefx-corridortravel.gif"
                "Kaleidoscope" = "as-stagefx-kaleidoscope.gif"
                "Misty" = "as-stagefx-misty.gif"
            }
            
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
