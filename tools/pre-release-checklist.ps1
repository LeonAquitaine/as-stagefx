#!/usr/bin/env pwsh
# pre-release-checklist.ps1 - Pre-release checklist for AS-StageFX
# This script identifies issues that need to be resolved before publishing

param(
    [string]$CatalogPath = "../shaders/catalog.json",
    [switch]$ShowDetails = $false,
    [switch]$ShowCount = $true
)

# Resolve the catalog path relative to script location
$ScriptDir = $PSScriptRoot
$CatalogFullPath = Join-Path $ScriptDir $CatalogPath

# Check if catalog file exists
if (-not (Test-Path $CatalogFullPath)) {
    Write-Error "Catalog file not found at: $CatalogFullPath"
    exit 1
}

try {
    # Load and parse the catalog
    Write-Host "Loading catalog from: $CatalogFullPath" -ForegroundColor Cyan
    $catalogContent = Get-Content -Path $CatalogFullPath -Raw -ErrorAction Stop
    $catalog = $catalogContent | ConvertFrom-Json -ErrorAction Stop
    if ($null -eq $catalog) { 
        Write-Error "Catalog is null or empty"
        exit 1
    }    # Find entries with null imageUrl
    $missingImages = $catalog | Where-Object { 
        $_.imageUrl -eq $null -or $_.imageUrl -eq "" 
    }
      # Set images directory path
    $ImagesDir = Join-Path $ScriptDir "../docs/res/img"
    
    # Get list of all available image files
    $availableImages = @()
    if (Test-Path $ImagesDir) {
        $availableImages = Get-ChildItem -Path $ImagesDir -Filter "*.gif" | ForEach-Object { $_.Name }
    }
    
    # Find entries with imageUrl but missing image files
    $brokenImageLinks = @()
    $validImageLinks = @()
    
    # Also check for potential matches for missing images
    $missingWithPotentialMatches = @()
    
    $entriesWithImages = $catalog | Where-Object { 
        $_.imageUrl -ne $null -and $_.imageUrl -ne "" 
    }
    
    foreach ($entry in $entriesWithImages) {
        # Extract filename from GitHub URL (or any URL ending with an image file)
        if ($entry.imageUrl -match "/([^/]+\.(?:gif|png|jpg|jpeg))(?:\?|$)") {
            $filename = $matches[1]
            $imagePath = Join-Path $ImagesDir $filename
            
            if (-not (Test-Path $imagePath)) {
                # Image file doesn't exist - broken link
                $brokenImageLinks += [PSCustomObject]@{
                    Entry = $entry
                    ImageUrl = $entry.imageUrl
                    ExpectedFile = $filename
                    ExpectedPath = $imagePath
                }
            } else {
                # Image file exists - valid link
                $validImageLinks += [PSCustomObject]@{
                    Entry = $entry
                    ImageUrl = $entry.imageUrl
                    ExpectedFile = $filename
                    ExpectedPath = $imagePath
                }
            }
        }
    }
    
    # Check for potential matches for missing images
    foreach ($entry in $missingImages) {
        $shaderName = if ($entry.name) { $entry.name } else { 
            $entry.filename -replace "^AS_[A-Z]{3}_|\.1\.fx$", "" 
        }
        
        # Generate possible naming variations
        $possibleNames = @()
        $cleanName = $shaderName -replace "[^a-zA-Z0-9]", ""
        $possibleNames += "as-stagefx-$($cleanName.ToLower()).gif"
        $possibleNames += "as-stagefx-$($shaderName.ToLower()).gif"
        $possibleNames += "$($cleanName.ToLower()).gif"
        $possibleNames += "$($shaderName.ToLower()).gif"
        
        # Check for fuzzy matches (contains shader name)
        $fuzzyMatches = $availableImages | Where-Object { 
            $imageName = $_ -replace "\.gif$", ""
            $cleanImageName = $imageName -replace "[^a-zA-Z0-9]", ""
            $cleanShaderName = $shaderName -replace "[^a-zA-Z0-9]", ""
            
            # Check if image name contains shader name or vice versa (case insensitive)
            $cleanImageName -like "*$cleanShaderName*" -or $cleanShaderName -like "*$cleanImageName*"
        }
        
        if ($fuzzyMatches.Count -gt 0) {
            $missingWithPotentialMatches += [PSCustomObject]@{
                Entry = $entry
                ShaderName = $shaderName
                PotentialMatches = $fuzzyMatches
            }
        }
    }    # Display results
    $totalIssues = $missingImages.Count + $brokenImageLinks.Count
    $trulyMissing = $missingImages.Count - $missingWithPotentialMatches.Count
    
    Write-Host ""
    Write-Host "🎯 IMAGE VALIDATION RESULTS" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Gray
    
    if ($validImageLinks.Count -gt 0) {
        Write-Host "✅ Valid Image URLs: $($validImageLinks.Count)" -ForegroundColor Green
    }
    
    if ($totalIssues -eq 0) {
        Write-Host "✅ All catalog entries have valid preview images!" -ForegroundColor Green
        Write-Host "✅ All image files exist in docs/res/img/" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Pre-Release Issues Found: $totalIssues problems detected" -ForegroundColor Red
        if ($missingWithPotentialMatches.Count -gt 0) {
            Write-Host "💡 $($missingWithPotentialMatches.Count) potential image matches found that could be linked!" -ForegroundColor Yellow
        }
        
        # Show missing imageUrl entries
        if ($missingImages.Count -gt 0) {
            Write-Host ""
            Write-Host "🚫 Missing Preview Images ($($missingImages.Count) entries):" -ForegroundColor Yellow
            Write-Host ("-" * 40) -ForegroundColor Gray
            
            foreach ($entry in $missingImages) {
                $name = if ($entry.name) { $entry.name } else { "<No Name>" }
                $filename = if ($entry.filename) { $entry.filename } else { "<No Filename>" }
                $type = if ($entry.type) { $entry.type } else { "<No Type>" }
                
                Write-Host "• $name" -ForegroundColor White
                Write-Host "  File: $filename" -ForegroundColor Gray
                Write-Host "  Type: $type" -ForegroundColor Gray
                
                if ($ShowDetails -and $entry.shortDescription) {
                    Write-Host "  Description: $($entry.shortDescription)" -ForegroundColor DarkGray
                }
                Write-Host ""
            }
        }
        
        # Show broken image links
        if ($brokenImageLinks.Count -gt 0) {
            Write-Host ""
            Write-Host "🔗 Broken Image Links ($($brokenImageLinks.Count) entries):" -ForegroundColor Red
            Write-Host ("-" * 40) -ForegroundColor Gray
            
            foreach ($broken in $brokenImageLinks) {
                $entry = $broken.Entry
                $name = if ($entry.name) { $entry.name } else { "<No Name>" }
                $filename = if ($entry.filename) { $entry.filename } else { "<No Filename>" }
                $type = if ($entry.type) { $entry.type } else { "<No Type>" }
                
                Write-Host "• $name" -ForegroundColor White
                Write-Host "  File: $filename" -ForegroundColor Gray
                Write-Host "  Type: $type" -ForegroundColor Gray
                Write-Host "  Expected image: $($broken.ExpectedFile)" -ForegroundColor Red
                Write-Host "  Looking for: $($broken.ExpectedPath)" -ForegroundColor DarkRed
                
                if ($ShowDetails -and $entry.shortDescription) {
                    Write-Host "  Description: $($entry.shortDescription)" -ForegroundColor DarkGray
                }                Write-Host ""
            }
        }        
        
        # Show valid image links (when ShowDetails is used)
        if ($ShowDetails -and $validImageLinks.Count -gt 0) {
            Write-Host ""
            Write-Host "✅ Valid Image Links ($($validImageLinks.Count) entries):" -ForegroundColor Green
            Write-Host ("-" * 40) -ForegroundColor Gray
            
            foreach ($valid in $validImageLinks) {
                $entry = $valid.Entry
                $name = if ($entry.name) { $entry.name } else { "<No Name>" }
                $filename = if ($entry.filename) { $entry.filename } else { "<No Filename>" }
                $type = if ($entry.type) { $entry.type } else { "<No Type>" }
                
                Write-Host "• $name" -ForegroundColor White
                Write-Host "  File: $filename" -ForegroundColor Gray
                Write-Host "  Type: $type" -ForegroundColor Gray
                Write-Host "  Image file: $($valid.ExpectedFile)" -ForegroundColor Green
                
                if ($ShowDetails -and $entry.shortDescription) {
                    Write-Host "  Description: $($entry.shortDescription)" -ForegroundColor DarkGray
                }
                Write-Host ""
            }
        }        if ($ShowCount) {
            Write-Host ("=" * 60) -ForegroundColor Gray
            Write-Host "🔢 SUMMARY - Pre-release status:" -ForegroundColor Yellow
            if ($validImageLinks.Count -gt 0) {
                Write-Host "Entries with valid image URLs: $($validImageLinks.Count)" -ForegroundColor Green
            }
            if ($missingImages.Count -gt 0) {
                Write-Host "Entries missing imageUrl: $($missingImages.Count)" -ForegroundColor Red
            }
            if ($brokenImageLinks.Count -gt 0) {
                Write-Host "Entries with broken image links: $($brokenImageLinks.Count)" -ForegroundColor Red
            }
            Write-Host "Total issues: $totalIssues" -ForegroundColor Red
            Write-Host "Total entries in catalog: $($catalog.Count)" -ForegroundColor Cyan
            $percentage = [math]::Round(($totalIssues / $catalog.Count) * 100, 1)
            Write-Host "Percentage with issues: $percentage%" -ForegroundColor Magenta
        }
    }    # Group by type for summary
    if ($totalIssues -gt 0 -and $ShowCount) {
        Write-Host ""
        Write-Host "📊 Issues by shader type:" -ForegroundColor Cyan
        
        # Combine missing images and broken links for type summary
        $allIssues = @()
        $allIssues += $missingImages | ForEach-Object { [PSCustomObject]@{ Type = $_.type; Issue = "Missing imageUrl" } }
        $allIssues += $brokenImageLinks | ForEach-Object { [PSCustomObject]@{ Type = $_.Entry.type; Issue = "Broken link" } }
        
        $byType = $allIssues | Group-Object Type | Sort-Object Name
        foreach ($group in $byType) {
            $typeName = if ($group.Name) { $group.Name } else { "Unknown" }
            Write-Host "  $typeName`: $($group.Count)" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "💡 Next steps:" -ForegroundColor Green
        if ($missingImages.Count -gt 0) {
            Write-Host "  1. Create preview GIFs for entries missing imageUrl" -ForegroundColor Gray
        }
        if ($brokenImageLinks.Count -gt 0) {
            Write-Host "  2. Create missing image files or fix broken URLs" -ForegroundColor Gray
        }        Write-Host "  3. Add/fix images in docs/res/img/ as as-stagefx-<name>.gif" -ForegroundColor Gray
        Write-Host "  4. Update catalog.json imageUrl fields with correct GitHub raw URLs" -ForegroundColor Gray
        Write-Host "  5. Re-run this script to verify all issues are resolved" -ForegroundColor Gray
        
        # Create reference table for all issues
        Write-Host ""
        Write-Host "📋 Quick Reference - Shader Name → Expected Image File:" -ForegroundColor Cyan
        Write-Host ("=" * 70) -ForegroundColor Gray
        Write-Host "Shader Name".PadRight(35) + "Expected Image File" -ForegroundColor White
        Write-Host ("-" * 35).PadRight(35) + ("-" * 30) -ForegroundColor Gray
        
        # Collect all entries with issues and their expected image names
        $allProblematicEntries = @()
        
        # Add missing image entries
        foreach ($entry in $missingImages) {
            $shaderName = if ($entry.name) { $entry.name } else { $entry.filename -replace "\.fx$", "" }
            $expectedImageName = if ($entry.name) { 
                "as-stagefx-" + ($entry.name -replace "[^a-zA-Z0-9]", "").ToLower() + ".gif"
            } else {
                "as-stagefx-" + ($entry.filename -replace "^AS_[A-Z]{3}_|\.1\.fx$", "").ToLower() + ".gif"
            }
            $allProblematicEntries += [PSCustomObject]@{
                ShaderName = $shaderName
                ExpectedImage = $expectedImageName
                IssueType = "Missing URL"
            }
        }
        
        # Add broken link entries
        foreach ($broken in $brokenImageLinks) {
            $entry = $broken.Entry
            $shaderName = if ($entry.name) { $entry.name } else { $entry.filename -replace "\.fx$", "" }
            $allProblematicEntries += [PSCustomObject]@{
                ShaderName = $shaderName
                ExpectedImage = $broken.ExpectedFile
                IssueType = "Broken Link"
            }
        }
        
        # Sort by shader name and display
        $sortedEntries = $allProblematicEntries | Sort-Object ShaderName
        foreach ($item in $sortedEntries) {
            $nameColumn = $item.ShaderName.PadRight(35)
            $issueColor = if ($item.IssueType -eq "Missing URL") { "Yellow" } else { "Red" }
            Write-Host $nameColumn -NoNewline -ForegroundColor White
            Write-Host $item.ExpectedImage -ForegroundColor $issueColor
        }
          Write-Host ""
        Write-Host "Legend: " -NoNewline -ForegroundColor Gray
        Write-Host "Yellow" -NoNewline -ForegroundColor Yellow
        Write-Host " = Missing imageUrl, " -NoNewline -ForegroundColor Gray
        Write-Host "Red" -NoNewline -ForegroundColor Red
        Write-Host " = Broken image link" -ForegroundColor Gray
    }
    
    # Add unused images analysis
    Write-Host ""
    Write-Host "🗂️  UNUSED IMAGES ANALYSIS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Gray
      # Get all image filenames referenced in catalog
    $usedImages = @()
    foreach ($entry in $catalog) {
        if ($entry.imageUrl -and $entry.imageUrl -match "(as-stagefx-.+\.gif)$") {
            $usedImages += $matches[1]
        }
    }
    
    # Find unused images
    $unusedImages = $availableImages | Where-Object { $_ -notin $usedImages }
    
    if ($unusedImages.Count -gt 0) {
        Write-Host "📁 Found $($unusedImages.Count) image files not associated with any catalog entries:" -ForegroundColor Yellow
        Write-Host ""
        foreach ($image in ($unusedImages | Sort-Object)) {
            Write-Host "  • $image" -ForegroundColor DarkGray
        }
        Write-Host ""
        Write-Host "💡 These images could be:" -ForegroundColor Yellow
        Write-Host "  - Orphaned files from renamed/removed shaders" -ForegroundColor White
        Write-Host "  - Images for new shaders not yet in catalog" -ForegroundColor White
        Write-Host "  - Alternative versions or backup images" -ForegroundColor White
        Write-Host "  - Images with naming that doesn't match current patterns" -ForegroundColor White
    } else {
        Write-Host "✅ All images in docs/res/img/ are associated with catalog entries" -ForegroundColor Green
    }

} catch {
    Write-Error "Failed to process catalog: $_"
    exit 1
}
