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
try {
    $configContent = Get-Content -Path $ConfigPath -Raw
} catch {
    Write-Host "[ERROR] Failed to read config file: $ConfigPath" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
try {
    $config = $configContent | ConvertFrom-Json
} catch {
    Write-Host "[ERROR] Failed to parse JSON in config file: $ConfigPath" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
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
