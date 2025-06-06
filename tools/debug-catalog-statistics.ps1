# Remove debug script after diagnosis

param(
    [string]$CatalogPath = "$PSScriptRoot/../shaders/catalog-statistics.json"
)

$catalogStats = Get-Content -Path $CatalogPath -Raw | ConvertFrom-Json

Write-Host "[DEBUG] Root keys in catalog-statistics.json:" -ForegroundColor Cyan
foreach ($k in $catalogStats.PSObject.Properties.Name) {
    $v = $catalogStats.$k
    Write-Host "  - $k : $($v.GetType().FullName)" -ForegroundColor Cyan
}

Write-Host "[DEBUG] byType value:" -ForegroundColor Yellow
$catalogStats.byType | ConvertTo-Json | Write-Host

Write-Host "[DEBUG] grouped value (first 1):" -ForegroundColor Yellow
$catalogStats.grouped | ConvertTo-Json -Depth 2 | Write-Host

Write-Host "[DEBUG] total value:" -ForegroundColor Yellow
$catalogStats.total | Write-Host
