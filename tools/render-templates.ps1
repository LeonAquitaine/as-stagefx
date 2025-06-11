# AS-StageFX Template Rendering Script
# Renders README.md and docs from templates using catalog-statistics.json
# Usage: pwsh ./tools/render-templates.ps1

param(
    [string]$CatalogPath = "$PSScriptRoot/../shaders/catalog-statistics.json",  # Now uses statistics file
    [hashtable]$Templates = @{
        Readme = @{ Template = "$PSScriptRoot/../docs/template/README.md"; Out = "$PSScriptRoot/../README.md" }
        Gallery = @{ Template = "$PSScriptRoot/../docs/template/gallery.md"; Out = "$PSScriptRoot/../docs/gallery.md" }
        GalleryBGX = @{ Template = "$PSScriptRoot/../docs/template/gallery-backgrounds.md"; Out = "$PSScriptRoot/../docs/gallery-backgrounds.md" }
        GalleryVFX = @{ Template = "$PSScriptRoot/../docs/template/gallery-visualeffects.md"; Out = "$PSScriptRoot/../docs/gallery-visualeffects.md" }
        Credits = @{ Template = "$PSScriptRoot/../docs/template/AS_StageFX_Credits.md"; Out = "$PSScriptRoot/../AS_StageFX_Credits.md" }
    }
)

# Load catalog-statistics
$catalogStats = Get-Content -Path $CatalogPath -Raw | ConvertFrom-Json

# Flatten all grouped arrays into a single 'shaders' array for credits rendering
$allShaders = @()
if ($catalogStats.grouped) {
    foreach ($group in $catalogStats.grouped.PSObject.Properties) {
        $items = $group.Value
        if ($items -is [System.Collections.IEnumerable]) {
            foreach ($item in $items) { $allShaders += $item }
        }
    }
}
$catalogStats | Add-Member -MemberType NoteProperty -Name shaders -Value $allShaders -Force

# Precompute arrays for credits template
$BGXAdapted = $allShaders | Where-Object { $_.type -eq 'BGX' -and $_.credits -and $_.credits.originalAuthor }
$OtherAdapted = $allShaders | Where-Object { $_.type -ne 'BGX' -and $_.credits -and $_.credits.originalAuthor }
$OriginalWorks = $allShaders | Where-Object { -not ($_.credits -and $_.credits.originalAuthor) }
$catalogStats | Add-Member -MemberType NoteProperty -Name BGXAdapted -Value $BGXAdapted -Force
$catalogStats | Add-Member -MemberType NoteProperty -Name OtherAdapted -Value $OtherAdapted -Force
$catalogStats | Add-Member -MemberType NoteProperty -Name OriginalWorks -Value $OriginalWorks -Force

# Load default license info from package-config.json
$packageConfigPath = "$PSScriptRoot/../config/package-config.json"
$packageConfig = Get-Content -Path $packageConfigPath -Raw | ConvertFrom-Json
$defaultLicenseDesc = $packageConfig.license.description
$defaultLicenseCode = $packageConfig.license.code

# Before rendering, blank out licence/license fields if they match the default
foreach ($group in $catalogStats.grouped.PSObject.Properties) {
    $items = $group.Value
    foreach ($item in $items) {
        if ($item.licence -eq $defaultLicenseDesc) { $item.licence = $null }
        if ($item.license -eq $defaultLicenseCode) { $item.license = $null }
        if ($item.credits) {
            if ($item.credits.licence -eq $defaultLicenseDesc) { $item.credits.licence = $null }
            if ($item.credits.license -eq $defaultLicenseCode) { $item.credits.license = $null }
        }
    }
}

# Helper: Get value from nested property path (e.g., "grouped.VFX.0.name")
function Get-CatalogValue($obj, $path) {
    $parts = $path -split '\.'
    foreach ($part in $parts) {
        if ($null -eq $obj) { return $null }
        if ($obj -is [System.Collections.IDictionary] -and $obj.ContainsKey($part)) {
            $obj = $obj[$part]
        } elseif ($obj.PSObject.Properties.Name -contains $part) {
            $obj = $obj.$part
        } else {
            return $null
        }
    }
    return $obj
}

# --- Template Rendering Engine ---
# 1. Evaluate all {{#if ...}}...{{/if}} blocks first, before any property replacements
function Get-NestedPropertyValue {
    param($context, $propertyPath)
    # Support simple (eq field value) and (ne field value) expressions
    if ($propertyPath -match '^\(eq ([^ ]+) "([^"]+)"\)$') {
        $field = $matches[1]
        $val = $matches[2]
        $actual = $context.$field
        return ($actual -eq $val)
    } elseif ($propertyPath -match '^\(ne ([^ ]+) "([^"]+)"\)$') {
        $field = $matches[1]
        $val = $matches[2]
        $actual = $context.$field
        return ($actual -ne $val)
    }
    $parts = $propertyPath -split '\.'
    $value = $context
    foreach ($part in $parts) {
        if ($null -eq $value) { return $null }
        if ($value -is [System.Collections.IDictionary] -and $value.Contains($part)) {
            $value = $value[$part]
        } elseif ($value.PSObject.Properties.Match($part)) {
            $value = $value.$part
        } else {
            return $null
        }
    }
    return $value
}

$ifBlockPattern = '(?ms){{#if ([^}]+)}}(.*?){{/if}}'
do {
    $oldContent = $templateContent
    $templateContent = [regex]::Replace($templateContent, $ifBlockPattern, {
        param($match)
        $prop = $match.Groups[1].Value.Trim()
        $block = $match.Groups[2].Value
        $val = Get-NestedPropertyValue $context $prop
        if ($val) {
            return $block
        } else {
            return ''
        }
    })
} while ($templateContent -ne $oldContent)

# 2. Now do property replacements as before
# 1. Replace all property markers (e.g. {{total}}, {{byType.BGX}}) with direct values
# Use approved verbs for PowerShell functions
function Invoke-PropertyReplacement {
    param($template, $data)
    return [regex]::Replace($template, '{{([a-zA-Z0-9_.]+)}}', {
        param($m)
        if ($null -eq $m -or -not $m.Groups[1]) { return '' }
        $ph = $m.Groups[1].Value
        $val = Get-CatalogValue $data $ph
        if ($null -eq $val) {
            return ''
        }
        return $val.ToString()
    })
}

# 2. Replace all group/array blocks (e.g. {{#each grouped.BGX}}...{{/each}})
function Invoke-GroupReplacement {
    param($template, $data)
    $pattern = '{{#each ([a-zA-Z0-9_.]+)}}([\s\S]*?){{/each}}'
    return [regex]::Replace($template, $pattern, {
        param($match)
        if ($null -eq $match -or -not $match.Groups[1] -or -not $match.Groups[2]) { return '' }
        $groupPath = $match.Groups[1].Value
        $block = $match.Groups[2].Value.Trim()
        $arr = Get-CatalogValue $data $groupPath
        if ($null -eq $arr -or $arr.Count -eq 0) { return '' }
        $rows = @()
        foreach ($item in $arr) {
            $row = $block
            
            # Process all {{#if}} blocks recursively within this item context
            $ifBlockPattern = '(?ms){{#if ([^}]+)}}(.*?){{/if}}'
            do {
                $oldRow = $row
                $row = [regex]::Replace($row, $ifBlockPattern, {
                    param($m3)
                    $fieldPath = $m3.Groups[1].Value.Trim()
                    $ifBlock = $m3.Groups[2].Value
                    $val = Get-NestedPropertyValue $item $fieldPath
                    if ($val) { return $ifBlock } else { return '' }
                })
            } while ($row -ne $oldRow)
            
            # Process property replacements
            $row = [regex]::Replace($row, '{{([a-zA-Z0-9_.]+)}}', {
                param($m2)
                if ($null -eq $m2 -or -not $m2.Groups[1]) { return '' }
                $field = $m2.Groups[1].Value
                $v = Get-NestedPropertyValue $item $field
                if ($null -eq $v) { return '' } else { return $v.ToString() }
            })
            $rows += $row
        }
        return ($rows -join "`n")
    })
}

# --- Main rendering logic ---
# --- Evaluate all if-blocks recursively until none remain ---
function Remove-AllIfBlocks {
    param($content, $context)
    $ifBlockPattern = '(?ms){{#if ([^}]+)}}(.*?){{/if}}'
    do {
        $oldContent = $content
        $content = [regex]::Replace($content, $ifBlockPattern, {
            param($match)
            $prop = $match.Groups[1].Value.Trim()
            $block = $match.Groups[2].Value
            $val = Get-NestedPropertyValue $context $prop
            if ($val) {
                return $block
            } else {
                return ''
            }
        })
    } while ($content -ne $oldContent)
    return $content
}

# Before rendering, blank out licence/license fields for each item if they match the default, for all grouped categories (BGX, GFX, LFX, VFX),
# so the README template will only show license info if it differs from the default.
foreach ($cat in @('BGX','GFX','LFX','VFX')) {
    if ($catalogStats.grouped.$cat) {
        foreach ($item in $catalogStats.grouped.$cat) {
            if ($item.licence -eq $defaultLicenseDesc) { $item.licence = $null }
            if ($item.license -eq $defaultLicenseCode) { $item.license = $null }
            if ($item.credits) {
                if ($item.credits.licence -eq $defaultLicenseDesc) { $item.credits.licence = $null }
                if ($item.credits.license -eq $defaultLicenseCode) { $item.credits.license = $null }
            }
        }
    }
}

foreach ($key in $Templates.Keys) {
    $templatePath = $Templates[$key].Template
    $outPath = $Templates[$key].Out
    if (!(Test-Path $templatePath)) { Write-Host "[WARN] Template not found: $templatePath" -ForegroundColor Yellow; continue }
    $template = Get-Content -Path $templatePath -Raw

    # Process {{#each}} blocks first (which handles {{#if}} blocks within item contexts)
    $rendered = Invoke-GroupReplacement $template $catalogStats
    
    # Then process any remaining global {{#if}} blocks
    $rendered = Remove-AllIfBlocks $rendered $catalogStats
    
    # Finally process simple property replacements
    $rendered = Invoke-PropertyReplacement $rendered $catalogStats

    # Remove any lines or inline markers like {{#if ...}}, {{/if}}, {{else}}, etc, that were not replaced
    $rendered = $rendered -replace '(?m)^\s*{{[#/]?if[^}]*}}\s*$', ''
    $rendered = $rendered -replace '(?m)^\s*{{else}}\s*$', ''
    $rendered = $rendered -replace '{{[#/]?if[^}]*}}', ''

    Set-Content -Path $outPath -Value $rendered -Encoding UTF8
    Write-Host "[SUCCESS] Rendered $outPath from $templatePath" -ForegroundColor Green
}
