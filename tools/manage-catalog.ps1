# AS-StageFX Catalog Management Script
# This script scans shader files and updates catalog.json (add, dedupe, update stats)
# Usage: pwsh ./tools/manage-catalog.ps1

param(
    [string]$ConfigPath = "$PSScriptRoot/../config/package-config.json",
    [string]$CatalogPath = "$PSScriptRoot/../shaders/catalog.json"
)

# Load config
$config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
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

# Read the catalog.json file as a flat array
$catalogPath = Join-Path $PSScriptRoot '../shaders/catalog.json'
$catalog = Get-Content $catalogPath -Raw | ConvertFrom-Json

# Deduplicate by name (keep first occurrence)
$seen = @{
}
$deduped = @()
foreach ($item in $catalog) {
    if (-not $seen.ContainsKey($item.name)) {
        $seen[$item.name] = $true
        $deduped += $item
    }
}

# Separate items with and without a 'name' property
$withName = $deduped | Where-Object { $_.PSObject.Properties["name"] -and $_.name }
$withoutName = $deduped | Where-Object { -not ($_.PSObject.Properties["name"] -and $_.name) }

# Sort only those with a name, leave the rest at the end
$sortedWithName = $withName | Sort-Object -Property { $_.name.ToLowerInvariant() }
$finalCatalog = @($sortedWithName + $withoutName)

# Write back as a flat array, pretty-printed
$finalCatalog | ConvertTo-Json -Depth 10 | Set-Content $catalogPath
