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

# Precompute kind-grouped arrays for the Credits template. The template engine
# doesn't handle nested {{#if}} well, so we do the filtering once here in code
# and expose flat arrays the template can iterate directly.
function Get-CreditsKind($item) {
    if ($item.credits -and $item.credits.kind) { return $item.credits.kind }
    return 'original'
}

$portsByType = @{}
foreach ($type in @('BGX','GFX','LFX','VFX','AFX')) {
    $portsByType[$type] = @($allShaders | Where-Object {
        $_.type -eq $type -and (Get-CreditsKind $_) -in @('port','port-adapted')
    } | Sort-Object filename)
}

# Originals that we still want listed in Credits.md — the "inspiration" kind
# (credited as inspired-by) and "original" entries that carry a description /
# historical note worth surfacing (e.g. clean-room rewrites). Pure originals
# with no story behind them are covered by the project default licence only.
$originalsWithInspiration = @($allShaders | Where-Object {
    (Get-CreditsKind $_) -eq 'inspiration'
} | Sort-Object filename)

# Derive a ready-to-render `inspirationText` for each inspiration entry. Prefer a
# hand-written `credits.description`, but strip any redundant "Original work by
# Leon Aquitaine" preamble since the template already states that on its own
# line. Fall back to a synthesized "Inspired by '<title>' by <author>" when no
# description is present (e.g. AS_VFX_TiltedGrid).
foreach ($item in $originalsWithInspiration) {
    $text = $null
    if ($item.credits -and $item.credits.description) {
        $text = $item.credits.description
        $text = $text -replace '^Original work by Leon Aquitaine[;:,]?\s*', ''
        if ($text.Length -gt 0) {
            $text = $text.Substring(0,1).ToUpper() + $text.Substring(1)
        }
    }
    if (-not $text -and $item.credits -and $item.credits.originalTitle -and $item.credits.originalAuthor) {
        $text = "Inspired by '$($item.credits.originalTitle)' by $($item.credits.originalAuthor)"
    }
    $item | Add-Member -NotePropertyName 'inspirationText' -NotePropertyValue $text -Force
}

$originalsWithHistory = @($allShaders | Where-Object {
    (Get-CreditsKind $_) -eq 'original' -and $_.credits -and $_.credits.description
} | Sort-Object filename)

$catalogStats | Add-Member -MemberType NoteProperty -Name portsBGX -Value $portsByType['BGX'] -Force
$catalogStats | Add-Member -MemberType NoteProperty -Name portsGFX -Value $portsByType['GFX'] -Force
$catalogStats | Add-Member -MemberType NoteProperty -Name portsLFX -Value $portsByType['LFX'] -Force
$catalogStats | Add-Member -MemberType NoteProperty -Name portsVFX -Value $portsByType['VFX'] -Force
$catalogStats | Add-Member -MemberType NoteProperty -Name portsAFX -Value $portsByType['AFX'] -Force
$catalogStats | Add-Member -MemberType NoteProperty -Name originalsWithInspiration -Value $originalsWithInspiration -Force
$catalogStats | Add-Member -MemberType NoteProperty -Name originalsWithHistory -Value $originalsWithHistory -Force

# Load default license info from package-config.json
$packageConfigPath = "$PSScriptRoot/../config/package-config.json"
$packageConfig = Get-Content -Path $packageConfigPath -Raw | ConvertFrom-Json
$defaultLicenseDesc = $packageConfig.license.description

# Before rendering, blank out licence/license fields if they match the default
foreach ($group in $catalogStats.grouped.PSObject.Properties) {
    $items = $group.Value
    foreach ($item in $items) {
        # Null out only `licence` (the long description) when it matches the project
        # default, so the gallery's `{{#if licence}}` hides the default licence line.
        # `licenseCode` stays populated so README's License column can render "CC BY 4.0"
        # for every entry (that column is expected to be fully populated).
        if ($item.licence -eq $defaultLicenseDesc) { $item.licence = $null }
        if ($item.credits -and $item.credits.licence -eq $defaultLicenseDesc) { $item.credits.licence = $null }
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
    # Traverse dotted paths like 'credits.kind' inside the current context
    function Resolve-DottedPath($ctx, $path) {
        $parts = $path -split '\.'
        $v = $ctx
        foreach ($part in $parts) {
            if ($null -eq $v) { return $null }
            if ($v -is [System.Collections.IDictionary] -and $v.Contains($part)) {
                $v = $v[$part]
            } elseif ($v.PSObject.Properties.Match($part)) {
                $v = $v.$part
            } else {
                return $null
            }
        }
        return $v
    }

    # Support simple (eq path "value") and (ne path "value") expressions, where
    # path may be dotted (e.g. (eq credits.kind "port"))
    if ($propertyPath -match '^\(eq ([^ ]+) "([^"]+)"\)$') {
        $actual = Resolve-DottedPath $context $matches[1]
        return ($actual -eq $matches[2])
    } elseif ($propertyPath -match '^\(ne ([^ ]+) "([^"]+)"\)$') {
        $actual = Resolve-DottedPath $context $matches[1]
        return ($actual -ne $matches[2])
    }
    return (Resolve-DottedPath $context $propertyPath)
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

# Second pass over typed groups so {{#if licence}} in gallery rows hides the
# default-licence line even when iterating grouped.BGX/GFX/LFX/VFX. `licenseCode`
# is intentionally preserved so README's License column can render for every entry.
foreach ($cat in @('BGX','GFX','LFX','VFX','AFX')) {
    if ($catalogStats.grouped.$cat) {
        foreach ($item in $catalogStats.grouped.$cat) {
            if ($item.licence -eq $defaultLicenseDesc) { $item.licence = $null }
            if ($item.credits -and $item.credits.licence -eq $defaultLicenseDesc) { $item.credits.licence = $null }
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
