# AS-StageFX Package Preparation Script
# Prepares package folders, manifest, and ZIPs for distribution
# Usage: pwsh ./tools/prepare-packages.ps1

param(
    [string]$ConfigPath = "$PSScriptRoot/../config/package-config.json",
    [string]$CatalogPath = "$PSScriptRoot/../shaders/catalog.json",
    [string]$OutputPath = "$PSScriptRoot/../packages"
)

# Load config and catalog
$config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
$catalog = Get-Content -Path $CatalogPath -Raw | ConvertFrom-Json
$shadersRoot = Split-Path -Parent $ConfigPath | Split-Path -Parent
$shaderDir = Join-Path $shadersRoot "shaders/AS"

# Utility functions (Write-Info, Write-Success, etc.)
function Write-Info($msg) { Write-Host "[INFO] $msg" }
function Write-Success($msg) { Write-Host "[SUCCESS] $msg" }
function Write-Warning($msg) { Write-Host "[WARNING] $msg" }

function Get-ShaderType($filename) {
    if ($filename -match "AS_([^_]+)_") {
        $typeCode = $matches[1].ToLower()
        switch ($typeCode) {
            "bgx" { return "bgx" }
            "vfx" { return "vfx" }
            "lfx" { return "lfx" }
            "gfx" { return "gfx" }
            "afx" { return "afx" }
            default { return "other" }
        }
    } elseif ($filename -match "\.fxh$") { return "fxh" }
    return "other"
}

function Test-IsPrerelease($filename) {
    foreach ($pattern in $config.buildRules.excludePatterns) {
        if ($filename -match $pattern) { return $true }
    }
    return $false
}

function Get-ParsedShaderContentDependencies($shaderPath, $availableDependencies) {
    $content = Get-Content -Path $shaderPath -Raw
    $fxhDependencies = @()
    $textureDependencies = @()
    $includePattern = '#include\s+["<]([^">]+)[">]'
    if ($config.buildRules.dependencyTracking.includePatterns) {
        $includePattern = $config.buildRules.dependencyTracking.includePatterns[0]
    }
    $includeMatches = [regex]::Matches($content, $includePattern)
    foreach ($match in $includeMatches) {
        $includePath = $match.Groups[1].Value
        if ($includePath -match "\.fxh$") {
            $includeName = $includePath -replace ".*[\\/]", ""
            if ($includeName -ne "ReShade.fxh" -and $includeName -ne "ReShadeUI.fxh") {
                if ($availableDependencies.FxhFiles -contains $includeName) {
                    $fxhDependencies += $includeName
                }
            }
        }
    }
    $texturePattern = 'texture\s+\w+\s*<\s*source\s*=\s*([^;>]+)\s*[;>]';
    if ($config.buildRules.dependencyTracking.texturePatterns) {
        $texturePattern = $config.buildRules.dependencyTracking.texturePatterns[0]
    }
    $textureMatches = [regex]::Matches($content, $texturePattern)
    foreach ($match in $textureMatches) {
        $texturePathOrMacro = $match.Groups[1].Value.Trim().Trim('"')
        if ($texturePathOrMacro -notmatch '"') {
            $escapedMacro = [regex]::Escape($texturePathOrMacro)
            $macroRegex = ('#define\s+' + $escapedMacro + '\s+"([^"]+)"')
            try {
                $macroDefinitionMatches = [regex]::Matches($content, $macroRegex)
            } catch {
                Write-Warning "[WARN] Invalid regex pattern for macro: $macroRegex. Skipping."
                continue
            }
            if ($macroDefinitionMatches.Count -gt 0) {
                $texturePathOrMacro = $macroDefinitionMatches[0].Groups[1].Value
            } else {
                continue
            }
        }
        $textureName = $texturePathOrMacro -replace ".*[\\/]", ""
        if ($textureName -match '\.' -and ($availableDependencies.TextureFiles -contains $textureName)) {
            if (-not ($textureDependencies -contains $textureName)) {
                $textureDependencies += $textureName
            }
        }
    }
    return @{
        FxhDependencies = $fxhDependencies | Select-Object -Unique
        TextureDependencies = $textureDependencies | Select-Object -Unique
    }
}

function Get-AggregatedPackageDependencies($shaders, $allShadersCollection, $currentShadersRoot, $currentAvailableDependencies) {
    $packageFxhDependencies = @()
    $packageTextureDependencies = @()
    foreach ($shaderName in $shaders) {
        $shaderFile = $allShadersCollection | Where-Object { $_.Name -eq $shaderName } | Select-Object -First 1
        if ($shaderFile) {
            $dependencies = Get-ParsedShaderContentDependencies $shaderFile.FullName $currentAvailableDependencies
            $packageFxhDependencies += $dependencies.FxhDependencies
            $packageTextureDependencies += $dependencies.TextureDependencies
        }
    }
    $packageFxhDependencies = $packageFxhDependencies | Select-Object -Unique
    $packageTextureDependencies = $packageTextureDependencies | Select-Object -Unique
    return @{
        FxhDependencies = $packageFxhDependencies
        TextureDependencies = $packageTextureDependencies
    }
}

# Prepare output directories
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

# Build a collection of available dependencies (FXH files and textures)
$availableDependencies = @{
    FxhFiles = @()
    TextureFiles = @()
}
$allShaders = Get-ChildItem -Path $shaderDir -File -Filter *.fx* | Where-Object { $_.Name -notmatch "^\[PRE\]" }
$availableDependencies.FxhFiles = Get-ChildItem -Path $shaderDir -File -Filter *.fxh | ForEach-Object { $_.Name }
$textureDir = Join-Path $shadersRoot $config.paths.textureDir
if (Test-Path $textureDir) {
    $availableDependencies.TextureFiles = Get-ChildItem -Path $textureDir -File | ForEach-Object { $_.Name }
}

# Get package names and paths
$packagePrefix = $config.packageNames.prefix
$essentialsName = $config.packageNames.essentials
$backgroundsName = $config.packageNames.backgrounds
$visualEffectsName = $config.packageNames.visualEffects
$completeName = $config.packageNames.complete
$shaderDirPath = $config.paths.shaderDir
$textureDirPath = $config.paths.textureDir

# Get lists of shaders for each package from catalog
$catalogItems = $catalog.shaders.items
$essentialShaders = @()
foreach ($categoryName in $config.essentials.PSObject.Properties.Name) {
    $category = $config.essentials.$categoryName
    foreach ($shader in $category) {
        $essentialShaders += $shader
    }
}
$backgroundShaders = $catalogItems | Where-Object { $_.type -eq 'BGX' } | ForEach-Object { $_.filename }
$visualEffectShaders = $catalogItems | Where-Object { $_.type -match 'VFX|LFX|GFX|AFX' } | ForEach-Object { $_.filename }
$allShadersList = $catalogItems | ForEach-Object { $_.filename }

# Create package directories
$essentialsDir = Join-Path $OutputPath "$packagePrefix$essentialsName"
$backgroundsDir = Join-Path $OutputPath "$packagePrefix$backgroundsName"
$visualEffectsDir = Join-Path $OutputPath "$packagePrefix$visualEffectsName"
$completeDir = Join-Path $OutputPath "$packagePrefix$completeName"
$packageDirs = @($essentialsDir, $backgroundsDir, $visualEffectsDir, $completeDir)
foreach ($dir in $packageDirs) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $shaderDirFull = Join-Path $dir $shaderDirPath
    if (-not (Test-Path $shaderDirFull)) { New-Item -ItemType Directory -Path $shaderDirFull -Force | Out-Null }
    if ($dir -eq $essentialsDir -or $dir -eq $completeDir) {
        $texturesDir = Join-Path $dir $textureDirPath
        if (-not (Test-Path $texturesDir)) { New-Item -ItemType Directory -Path $texturesDir -Force | Out-Null }
    }
}

# Copy shaders and dependencies to each package
function Copy-ShadersToPackage($shaderList, $packageDirName, $packageDesc, $currentAllShaders, $currentShadersRoot, $currentAvailableDependencies) {
    $packageFullPath = Join-Path $OutputPath $packageDirName
    Write-Info "Processing package: $packageDirName"
    # Resolve dependencies for this package
    $packageDependencies = Get-AggregatedPackageDependencies $shaderList $currentAllShaders $currentShadersRoot $currentAvailableDependencies
    $fxhDependencies = $packageDependencies.FxhDependencies
    $textureDependencies = $packageDependencies.TextureDependencies
    Write-Info "  $($shaderList.Count) primary shaders for this package."
    Write-Info "  Resolved dependencies: $($fxhDependencies.Count) FXH files, $($textureDependencies.Count) textures."
    $packageShaderDir = Join-Path $packageFullPath $shaderDirPath
    if (-not (Test-Path $packageShaderDir)) { New-Item -ItemType Directory -Path $packageShaderDir -Force | Out-Null }
    foreach ($shaderName in $shaderList) {
        $shader = $currentAllShaders | Where-Object { $_.Name -eq $shaderName } | Select-Object -First 1
        if ($shader) {
            $destPath = Join-Path $packageShaderDir $shaderName
            Copy-Item -Path $shader.FullName -Destination $destPath -Force
        } else {
            Write-Warning "Shader not found in project: $shaderName (when copying to $packageDirName)"
        }
    }
    foreach ($fxhName in $fxhDependencies) {
        $fxh = $currentAllShaders | Where-Object { $_.Name -eq $fxhName } | Select-Object -First 1
        if ($fxh) {
            $destPath = Join-Path $packageShaderDir $fxhName
            if (-not (Test-Path $destPath -PathType Leaf) -or ($shaderList -notcontains $fxhName) ) {
                Copy-Item -Path $fxh.FullName -Destination $destPath -Force
            }
        } else {
            Write-Warning "FXH dependency not found in project: $fxhName (when copying to $packageDirName)"
        }
    }
    if ($textureDependencies.Count -gt 0) {
        $textureSourceDir = Join-Path $currentShadersRoot $textureDirPath
        $textureDestDir = Join-Path $packageFullPath $textureDirPath
        if (-not (Test-Path $textureDestDir)) { New-Item -ItemType Directory -Path $textureDestDir -Force | Out-Null }
        foreach ($textureName in $textureDependencies) {
            $sourceTexturePath = Join-Path $textureSourceDir $textureName
            if (Test-Path $sourceTexturePath) {
                $destTexturePath = Join-Path $textureDestDir $textureName
                Copy-Item -Path $sourceTexturePath -Destination $destTexturePath -Force
            } else {
                Write-Warning "Texture dependency not found in source: $textureName (when copying to $packageDirName)"
            }
        }
    }
    # Add to manifest data
    $script:packagesForManifest += @{
        Name = $packageDirName
        Description = $packageDesc
        Shaders = $shaderList
        Dependencies = $packageDependencies
        ShaderCount = $shaderList.Count
        FxhCount = $fxhDependencies.Count
        TextureCount = $textureDependencies.Count
    }
}

$script:packagesForManifest = @()
Copy-ShadersToPackage -shaderList $essentialShaders -packageDirName "$packagePrefix$essentialsName" -packageDesc $config.packageDescription.essentials -currentAllShaders $allShaders -currentShadersRoot $shadersRoot -currentAvailableDependencies $availableDependencies
Copy-ShadersToPackage -shaderList $backgroundShaders -packageDirName "$packagePrefix$backgroundsName" -packageDesc $config.packageDescription.backgrounds -currentAllShaders $allShaders -currentShadersRoot $shadersRoot -currentAvailableDependencies $availableDependencies
Copy-ShadersToPackage -shaderList $visualEffectShaders -packageDirName "$packagePrefix$visualEffectsName" -packageDesc $config.packageDescription.visualeffects -currentAllShaders $allShaders -currentShadersRoot $shadersRoot -currentAvailableDependencies $availableDependencies
Copy-ShadersToPackage -shaderList $allShadersList -packageDirName "$packagePrefix$completeName" -packageDesc $config.packageDescription.complete -currentAllShaders $allShaders -currentShadersRoot $shadersRoot -currentAvailableDependencies $availableDependencies
Write-Success "All packages processed."

# Generate package manifest
function New-PackageManifest($packagesDataToManifest, $manifestPath) {
    Write-Info "Generating package manifest: $manifestPath"
    $manifest = @{
        version = $config.version
        buildDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        packages = [System.Collections.Generic.List[object]]::new()
    }
    $sortedPackagesData = $packagesDataToManifest | Sort-Object Name
    foreach ($package in $sortedPackagesData) {
        $fxhDeps = @()
        if ($package.Dependencies.FxhDependencies) {
            if ($package.Dependencies.FxhDependencies -is [array]) {
                $fxhDeps = $package.Dependencies.FxhDependencies
            } else {
                $fxhDeps = @($package.Dependencies.FxhDependencies)
            }
        }
        $textureDeps = @()
        if ($package.Dependencies.TextureDependencies) {
            if ($package.Dependencies.TextureDependencies -is [array]) {
                $textureDeps = $package.Dependencies.TextureDependencies
            } else {
                $textureDeps = @($package.Dependencies.TextureDependencies)
            }
        }
        $packageManifest = @{
            name = $package.Name
            version = $config.version
            description = $package.Description
            shaderCount = $package.ShaderCount
            fxhDependencyCount = $package.FxhCount
            textureDependencyCount = $package.TextureCount
            shaders = $package.Shaders
            dependencies = @{ fxh = $fxhDeps; textures = $textureDeps }
        }
        $manifest.packages.Add($packageManifest)
    }
    $manifestPath = Join-Path $OutputPath $config.paths.manifestFile
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -Path $manifestPath -Encoding UTF8
    Write-Success "Package manifest generated: $manifestPath"
}
New-PackageManifest -packagesDataToManifest $script:packagesForManifest -manifestPath (Join-Path $OutputPath $config.paths.manifestFile)

# Create ZIP archives for each package
Write-Info "Creating ZIP archives for packages..."
foreach ($package in $script:packagesForManifest) {
    $packageFolderName = $package.Name
    $packageFolderPath = Join-Path $OutputPath $packageFolderName
    $zipFilePath = Join-Path $OutputPath "$packageFolderName.zip"
    if (Test-Path $packageFolderPath) {
        try {
            Compress-Archive -Path "$packageFolderPath\*" -DestinationPath $zipFilePath -Force -ErrorAction Stop
            Write-Success "Created ZIP archive: $zipFilePath"
        } catch {
            Write-Host "[ERROR] Failed to create ZIP archive for $packageFolderName : $_"
        }
    } else {
        Write-Warning "Package folder not found for zipping: $packageFolderPath"
    }
}

# Remove all package folders after zipping
Write-Info "Cleaning up package folders..."
foreach ($package in $script:packagesForManifest) {
    $packageFolderName = $package.Name
    $packageFolderPath = Join-Path $OutputPath $packageFolderName
    if (Test-Path $packageFolderPath) {
        try {
            Remove-Item -Path $packageFolderPath -Recurse -Force
            Write-Success "Removed package folder: $packageFolderPath"
        } catch {
            Write-Warning "Failed to remove package folder: $packageFolderPath ($_)."
        }
    }
}

Write-Host "[SUCCESS] Package preparation complete."
