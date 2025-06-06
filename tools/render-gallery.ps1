param(
    [string]$CatalogPath = "$PSScriptRoot/../shaders/catalog-statistics.json",
    [string]$GalleryTemplatePath = "$PSScriptRoot/../docs/template/gallery.md",
    [string]$GalleryOutPath = "$PSScriptRoot/../docs/gallery-backgrounds.md",
    [string]$GroupKey = "BGX",
    [string]$GalleryTitle = "AS-StageFX Shader Gallery - Backgrounds Package",
    [string]$SectionTitle = "Background Effects (BGX)",
    [string]$PackageName = "AS_StageFX_Backgrounds"
)

# Load catalog-statistics.json with error handling
try {
    $catalogContent = Get-Content -Path $CatalogPath -Raw
} catch {
    Write-Host "[ERROR] Failed to read catalog file: $CatalogPath" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
try {
    $catalogStats = $catalogContent | ConvertFrom-Json
} catch {
    Write-Host "[ERROR] Failed to parse JSON in catalog file: $CatalogPath" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

$template = Get-Content -Path $GalleryTemplatePath -Raw

# Prepare data for template
$effects = $catalogStats.grouped.$GroupKey
$effectCount = $effects.Count

# Replace global property markers
$template = $template -replace '{{galleryTitle}}', [regex]::Escape($GalleryTitle)
$template = $template -replace '{{sectionTitle}}', [regex]::Escape($SectionTitle)
$template = $template -replace '{{packageName}}', [regex]::Escape($PackageName)
$template = $template -replace '{{effectCount}}', $effectCount

# Group block replacement
$pattern = '{{#each effects}}([\s\S]*?){{/each}}'
$template = [regex]::Replace($template, $pattern, {
    param($match)
    $block = $match.Groups[1].Value.Trim()
    $rows = @()
    foreach ($item in $effects) {
        $row = [regex]::Replace($block, '{{([a-zA-Z0-9_]+)}}', {
            param($m2)
            $field = $m2.Groups[1].Value
            if ($item -is [System.Collections.IDictionary] -and $item.ContainsKey($field)) {
                $v = $item[$field]
            } elseif ($item.PSObject -and $item.PSObject.Properties.Name -contains $field) {
                $v = $item.$field
            } else {
                $v = ''
            }
            if ($null -eq $v) { return '' } else { return $v.ToString() }
        })
        $rows += $row
    }
    return ($rows -join "`n")
})

try {
    Set-Content -Path $GalleryOutPath -Value $template -Encoding UTF8
    Write-Host "[SUCCESS] Gallery rendered: $GalleryOutPath"
} catch {
    Write-Host "[ERROR] Failed to write gallery file: $GalleryOutPath" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}