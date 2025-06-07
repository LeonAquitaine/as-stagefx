# =====================================================================
# AS StageFX Packaging Script
# =====================================================================
# This script generates distribution packages for AS StageFX shaders
# based on the configuration in package-config.json
# =====================================================================

param(
    [string]$ConfigPath = "$PSScriptRoot\..\config\package-config.json",
    [string]$OutputPath = "$PSScriptRoot\..\packages"
)

# CD to the parent's directory
Set-Location (Split-Path -Parent $PSScriptRoot)

# =====================================================================
# UTILITY FUNCTIONS
# =====================================================================

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success($message) {
    Write-ColorOutput Green "[SUCCESS] $message"
}

function Write-Info($message) {
    Write-ColorOutput Cyan "[INFO] $message"
}

function Write-Warning($message) {
    Write-ColorOutput Yellow "[WARNING] $message"
}

function Write-Error($message) {
    Write-ColorOutput Red "[ERROR] $message"
}

function Get-ShaderType($filename) {
    if ($filename -match "AS_([^_]+)_") {
        # Extract the type code (BGX, VFX, etc.)
        $typeCode = $matches[1].ToLower()
        
        # Map the type code to a folder name
        switch ($typeCode) {
            "bgx" { return "bgx" }
            "vfx" { return "vfx" }
            "lfx" { return "lfx" }
            "gfx" { return "gfx" }
            "afx" { return "afx" }
            default { return "other" }
        }
    }
    elseif ($filename -match "\.fxh$") {
        return "fxh"
    }
    
    return "other"
}

function Test-IsPrerelease($filename) {
    # Check if the filename matches any exclude patterns from config
    foreach ($pattern in $config.buildRules.excludePatterns) {
        if ($filename -match $pattern) {
            return $true
        }
    }
    return $false
}

# This function is not currently used, available dependencies are gathered in the main script block.
# function Get-AvailableDependencies() {
#     # Get all .fxh files in the workspace
#     $fxhFiles = Get-ChildItem -Path $shadersRoot -Recurse -File -Filter "*.fxh" | Where-Object {
#         $file = $_
#         # Check if file path is in any of the excluded paths
#         $excluded = $false
#         foreach ($excludePath in $excludePathsArray) {
#             if ($file.FullName -match $excludePath) {
#                 $excluded = $true
#                 break
#             }
#         }
#         -not $excluded
#     } | Select-Object -ExpandProperty Name

#     # Get all texture files
#     $textureSourceDir = Join-Path $shadersRoot $textureDirPath
#     $textureFiles = @()
#     if (Test-Path $textureSourceDir) {
#         $textureFiles = Get-ChildItem -Path $textureSourceDir -File | Select-Object -ExpandProperty Name
#     }

#     return @{
#         FxhFiles = $fxhFiles
#         TextureFiles = $textureFiles
#     }
# }

function Get-ParsedShaderContentDependencies($shaderPath, $availableDependencies) {
    # Read the shader content
    $content = Get-Content -Path $shaderPath -Raw
    
    # Initialize dependency arrays
    $fxhDependencies = @()
    $textureDependencies = @()
    
    # Get include pattern from config or use default
    $includePattern = '#include\s+["<]([^">]+)[">]'
    if ($config.buildRules.dependencyTracking.includePatterns) {
        $includePattern = $config.buildRules.dependencyTracking.includePatterns[0]
    }
    
    # Find .fxh dependencies using regex for #include statements
    $includeMatches = [regex]::Matches($content, $includePattern)
    foreach ($match in $includeMatches) {
        $includePath = $match.Groups[1].Value
        # Only add .fxh files
        if ($includePath -match "\.fxh$") {
            # Extract just the filename without directory path
            $includeName = $includePath -replace ".*[\\/]", ""
            # Ensure we don't add ReShade standard includes
            if ($includeName -ne "ReShade.fxh" -and $includeName -ne "ReShadeUI.fxh") {
                # Check if this fxh file exists in our available dependencies
                if ($availableDependencies.FxhFiles -contains $includeName) {
                    $fxhDependencies += $includeName
                }
            }
        }
    }
    
    # Fallback FXH matching for basename has been removed for precision.
    
    # Get texture pattern from config or use default
    $texturePattern = 'texture\s+\w+\s*<\s*source\s*=\s*([^;>]+)\s*[;>]'
    if ($config.buildRules.dependencyTracking.texturePatterns) {
        $texturePattern = $config.buildRules.dependencyTracking.texturePatterns[0]
    }
    
    # Find texture dependencies using regex for texture definitions with source attribute
    $textureMatches = [regex]::Matches($content, $texturePattern)
    foreach ($match in $textureMatches) {
        $texturePathOrMacro = $match.Groups[1].Value.Trim().Trim('"')
        
        # Handle macro cases like source=TEXTURE_PATH
        # Check if it looks like a macro (no quotes, no dot typically)
        if ($texturePathOrMacro -notmatch '"') {
            # Look for a macro definition: #define TEXTURE_PATH "actual.png"
            $macroRegex = "#define\s+$([regex]::Escape($texturePathOrMacro))\s+`"([^`"]+)`""
            $macroDefinitionMatches = [regex]::Matches($content, $macroRegex)
            if ($macroDefinitionMatches.Count -gt 0) {
                $texturePathOrMacro = $macroDefinitionMatches[0].Groups[1].Value
            }
            else {
                # If macro not found in this file, we cannot resolve it here.
                # It might be defined in an included FXH or intended for global definition.
                # For dependency tracking, we skip it if not resolvable locally.
                Write-Warning "Could not resolve texture macro '$texturePathOrMacro' directly in shader '$shaderPath'. It might be defined in an included FXH or globally."
                continue # Skip this unresolved macro
            }
        }
        
        # Extract just the filename without directory path from the (potentially resolved) path
        $textureName = $texturePathOrMacro -replace ".*[\\/]", ""

        # Only add if it's a real file name (contains a dot) and is in the available list
        if ($textureName -match "\." -and ($availableDependencies.TextureFiles -contains $textureName)) {
            if (-not ($textureDependencies -contains $textureName)) { # Ensure uniqueness before adding
                 $textureDependencies += $textureName
            }
        }
    }
    
    # Fallback texture matching for basename has been removed for precision.
    
    # Add global dependencies from config
    if ($config.buildRules.dependencyTracking.globalDependencies) {
        foreach ($globalDep in $config.buildRules.dependencyTracking.globalDependencies) {
            if ($globalDep -match "\.fxh$" -and ($availableDependencies.FxhFiles -contains $globalDep) -and -not ($fxhDependencies -contains $globalDep)) {
                $fxhDependencies += $globalDep
            }
            # Global textures are not explicitly handled here, assuming they are part of FXH or direct includes if needed
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
    
    # Ensure we only have unique dependencies
    $packageFxhDependencies = $packageFxhDependencies | Select-Object -Unique
    $packageTextureDependencies = $packageTextureDependencies | Select-Object -Unique
    
    return @{
        FxhDependencies = $packageFxhDependencies
        TextureDependencies = $packageTextureDependencies
    }
}

function Clear-PackagesDirectory {
    param(
        [string]$PackagesPath
    )
    
    Write-Info "Cleaning packages directory: $PackagesPath"
    
    try {
        if (Test-Path $PackagesPath) {
            # Get only the folders in the packages directory (not ZIP files or manifest)
            $packageFolders = Get-ChildItem -Path $PackagesPath -Directory -Force -ErrorAction Stop
            
            # Track counts for summary
            $foldersRemoved = 0
            
            foreach ($folder in $packageFolders) {
                try {
                    # Remove each package folder recursively
                    Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction Stop
                    $foldersRemoved++
                }
                catch {
                    Write-Warning "Failed to remove $($folder.FullName): $_"
                }
            }
              if ($foldersRemoved -gt 0) {
                Write-Success "Cleaned packages directory: Removed $foldersRemoved package folders"
            } else {
                Write-Info "No package folders to clean in packages directory"
            }
        }
        else {
            Write-Info "Packages directory does not exist, it will be created"
        }
    }
    catch {
        Write-Error "Error during cleanup process: $_"
        # Continue execution even if cleanup fails
        Write-Warning "Continuing with package generation despite cleanup errors"
    }
}

function Remove-PackageFolders {
    param(
        [string]$PackagesPath,
        [array]$FolderNames
    )
    
    Write-Info "Removing package folders (keeping only ZIPs and manifest)..."
    
    $foldersRemoved = 0
    
    foreach ($folderName in $FolderNames) {
        $folderPath = Join-Path $PackagesPath $folderName
        
        if (Test-Path $folderPath) {
            try {
                Remove-Item -Path $folderPath -Recurse -Force
                $foldersRemoved++
            }
            catch {
                Write-Warning "Failed to remove $folderPath : $_"
            }
        }
    }
    
    if ($foldersRemoved -gt 0) {
        Write-Success "Removed $foldersRemoved package folders, keeping only ZIP files and manifest"
    }
    else {
        Write-Info "No package folders to remove"
    }
}

# =====================================================================
# MAIN SCRIPT
# =====================================================================

# Verify config file exists
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Configuration file not found: $ConfigPath"
    exit 1
}

# Read the configuration file
try {
    $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
    Write-Info "Configuration loaded from $ConfigPath"
} 
catch {
    Write-Error "Failed to parse configuration file: $_"
    exit 1
}

# Clean the packages directory before building new packages
Clear-PackagesDirectory -PackagesPath $OutputPath

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
    Write-Info "Created output directory: $OutputPath"
}

# Get all shader files in the project
$shadersRoot = Split-Path -Parent $ConfigPath | Split-Path -Parent
$excludePathsArray = $config.paths.excludePaths
$shaderExtensions = $config.fileExtensions.shaders

# Build the inclusion pattern for file extensions
$includePattern = $shaderExtensions | ForEach-Object { "*$_" }

# Get all shader files in the project, filtering out excluded paths
$allShaders = Get-ChildItem -Path $shadersRoot -Recurse -File -Include $includePattern | Where-Object {
    $file = $_
    # Check if file path is in any of the excluded paths
    $excluded = $false
    foreach ($excludePath in $excludePathsArray) {
        if ($file.FullName -match $excludePath) {
            $excluded = $true
            break
        }
    }
    -not $excluded
}

Write-Info "Found $($allShaders.Count) shader files"

# Build a collection of available dependencies (FXH files and textures)
$availableDependencies = @{
    FxhFiles = @()
    TextureFiles = @()
}

# Find all .fxh files
$availableDependencies.FxhFiles = $allShaders | Where-Object { $_.Name -match "\.fxh$" } | ForEach-Object { $_.Name }

# Find all texture files
$textureDir = Join-Path $shadersRoot $config.paths.textureDir
if (Test-Path $textureDir) {
    $availableDependencies.TextureFiles = Get-ChildItem -Path $textureDir -File | ForEach-Object { $_.Name }
}

Write-Info "Found $($availableDependencies.FxhFiles.Count) FXH files and $($availableDependencies.TextureFiles.Count) texture files for dependency tracking"

# Create lists for each package
$essentialShaders = @()
$backgroundShaders = @()
$visualEffectShaders = @()
$allShadersList = @()

# Get list of files in essentials package from config
foreach ($categoryName in $config.essentials.PSObject.Properties.Name) {
    $category = $config.essentials.$categoryName
    foreach ($shader in $category) {
        $essentialShaders += $shader
    }
}

# Process all shaders and categorize them
foreach ($shader in $allShaders) {
    $shaderName = $shader.Name
    
    # Skip shaders prefixed with [PRE]
    if (Test-IsPrerelease $shaderName) {
        Write-Info "Skipping prerelease shader: $shaderName"
        continue
    }
    
    $shaderType = Get-ShaderType $shaderName
    $allShadersList += $shaderName
    
    # If the shader is not in the essentials list
    if (-not ($essentialShaders -contains $shaderName)) {
        # Add to appropriate category package
        if ($shaderType -eq "bgx") {
            $backgroundShaders += $shaderName
        }
        elseif ($shaderType -match "vfx|lfx|gfx|afx") {
            $visualEffectShaders += $shaderName
        }
    }
}

# Get package name prefix and names from config
$packagePrefix = $config.packageNames.prefix
$essentialsName = $config.packageNames.essentials
$backgroundsName = $config.packageNames.backgrounds
$visualEffectsName = $config.packageNames.visualEffects
$completeName = $config.packageNames.complete

# Create package directories
$essentialsDir = Join-Path $OutputPath "$packagePrefix$essentialsName"
$backgroundsDir = Join-Path $OutputPath "$packagePrefix$backgroundsName"
$visualEffectsDir = Join-Path $OutputPath "$packagePrefix$visualEffectsName"
$completeDir = Join-Path $OutputPath "$packagePrefix$completeName"

# Get paths from config
$shaderDirPath = $config.paths.shaderDir
$textureDirPath = $config.paths.textureDir

# Create directories with structure
$packageDirs = @($essentialsDir, $backgroundsDir, $visualEffectsDir, $completeDir)

foreach ($dir in $packageDirs) {
    # Create main directory
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
    
    # Create shader directory structure
    $shaderDir = Join-Path $dir $shaderDirPath
    if (-not (Test-Path $shaderDir)) {
        New-Item -ItemType Directory -Path $shaderDir -Force | Out-Null
    }
    
    # For essentials and complete packages, also create textures directory
    # This logic might need adjustment based on actual texture dependencies per package
    # For now, creating it for essentials and complete as before.
    if ($dir -eq $essentialsDir -or $dir -eq $completeDir) {
        $texturesDir = Join-Path $dir $textureDirPath
        if (-not (Test-Path $texturesDir)) {
            New-Item -ItemType Directory -Path $texturesDir -Force | Out-Null
        }
    }
}

# Store package details for manifest generation
$script:packagesForManifest = @()
$script:createdPackageFolderNames = [System.Collections.Generic.List[string]]::new() # Added to store folder names

# Copy appropriate shaders to each package
function Copy-ShadersToPackage($shaderList, $packageDirName, $packageDesc, $currentAllShaders, $currentShadersRoot, $currentAvailableDependencies) {
    $packageFullPath = Join-Path $OutputPath $packageDirName
    Write-Info "Processing package: $packageDirName"
    $script:createdPackageFolderNames.Add($packageDirName) # Add folder name to the list

    # Resolve dependencies for this package
    $packageDependencies = Get-AggregatedPackageDependencies $shaderList $currentAllShaders $currentShadersRoot $currentAvailableDependencies
    $fxhDependencies = $packageDependencies.FxhDependencies
    $textureDependencies = $packageDependencies.TextureDependencies
    
    Write-Info "  $($shaderList.Count) primary shaders for this package."
    Write-Info "  Resolved dependencies: $($fxhDependencies.Count) FXH files, $($textureDependencies.Count) textures."
    
    # Create shader directory within the package if it doesn't exist
    $packageShaderDir = Join-Path $packageFullPath $shaderDirPath
    if (-not (Test-Path $packageShaderDir)) {
        New-Item -ItemType Directory -Path $packageShaderDir -Force | Out-Null
    }

    # Copy the main shaders
    foreach ($shaderName in $shaderList) {
        $shader = $currentAllShaders | Where-Object { $_.Name -eq $shaderName } | Select-Object -First 1
        
        if ($shader) {
            $destPath = Join-Path $packageShaderDir $shaderName
            Copy-Item -Path $shader.FullName -Destination $destPath -Force
        }
        else {
            Write-Warning "Shader not found in project: $shaderName (when copying to $packageDirName)"
        }
    }
    
    # Copy FXH dependencies
    foreach ($fxhName in $fxhDependencies) {
        $fxh = $currentAllShaders | Where-Object { $_.Name -eq $fxhName } | Select-Object -First 1
        
        if ($fxh) {
            $destPath = Join-Path $packageShaderDir $fxhName
            # Ensure not to copy over a primary shader if an FXH has the same name (unlikely but a safeguard)
            if (-not (Test-Path $destPath -PathType Leaf) -or ($shaderList -notcontains $fxhName) ) {
                 Copy-Item -Path $fxh.FullName -Destination $destPath -Force
            }
        }
        else {
            Write-Warning "FXH dependency not found in project: $fxhName (when copying to $packageDirName)"
        }
    }
    
    # Copy texture dependencies
    if ($textureDependencies.Count -gt 0) {
        $textureSourceDir = Join-Path $currentShadersRoot $textureDirPath
        $textureDestDir = Join-Path $packageFullPath $textureDirPath
        
        # Create textures directory if it doesn't exist
        if (-not (Test-Path $textureDestDir)) {
            New-Item -ItemType Directory -Path $textureDestDir -Force | Out-Null
        }
        
        foreach ($textureName in $textureDependencies) {
            $sourceTexturePath = Join-Path $textureSourceDir $textureName
            if (Test-Path $sourceTexturePath) {
                $destTexturePath = Join-Path $textureDestDir $textureName
                Copy-Item -Path $sourceTexturePath -Destination $destTexturePath -Force
            }
            else {
                Write-Warning "Texture dependency not found in source: $textureName (when copying to $packageDirName)"
            }
        }
    }

    # Add to manifest data
    $script:packagesForManifest += @{
        Name = $packageDirName
        Description = $packageDesc
        Shaders = $shaderList # List of primary shader names
        Dependencies = $packageDependencies # Contains .FxhDependencies and .TextureDependencies arrays
        ShaderCount = $shaderList.Count
        FxhCount = $fxhDependencies.Count
        TextureCount = $textureDependencies.Count
    }
}

# Call Copy-ShadersToPackage for each package
# Essentials Package
Copy-ShadersToPackage -shaderList $essentialShaders `
                      -packageDirName "$packagePrefix$essentialsName" `
                      -packageDesc $config.packageDescription.essentials `
                      -currentAllShaders $allShaders `
                      -currentShadersRoot $shadersRoot `
                      -currentAvailableDependencies $availableDependencies

# Backgrounds Package
Copy-ShadersToPackage -shaderList $backgroundShaders `
                      -packageDirName "$packagePrefix$backgroundsName" `
                      -packageDesc $config.packageDescription.backgrounds `
                      -currentAllShaders $allShaders `
                      -currentShadersRoot $shadersRoot `
                      -currentAvailableDependencies $availableDependencies

# Visual Effects Package
Copy-ShadersToPackage -shaderList $visualEffectShaders `
                      -packageDirName "$packagePrefix$visualEffectsName" `
                      -packageDesc $config.packageDescription.visualeffects `
                      -currentAllShaders $allShaders `
                      -currentShadersRoot $shadersRoot `
                      -currentAvailableDependencies $availableDependencies

# Complete Package (all non-prerelease shaders)
Copy-ShadersToPackage -shaderList $allShadersList `
                      -packageDirName "$packagePrefix$completeName" `
                      -packageDesc $config.packageDescription.complete `
                      -currentAllShaders $allShaders `
                      -currentShadersRoot $shadersRoot `
                      -currentAvailableDependencies $availableDependencies

Write-Success "All packages processed."

# Generate package manifest
function New-PackageManifest($packagesDataToManifest, $manifestPath) {
    Write-Info "Generating package manifest: $manifestPath"
    
    $manifest = @{
        version = $config.version
        buildDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        packages = [System.Collections.Generic.List[object]]::new() # Initialize as a resizable list
    }
    
    # Sort packages by display order from config, then by name
    $sortedPackagesData = $packagesDataToManifest | Sort-Object {
        $order = $config.packageDisplayOrder.IndexOf($_.Name.Replace($packagePrefix, "").TrimStart('_'))
        if ($order -eq -1) { $order = 999 } # Put unsorted items at the end
        $order
    }, Name

    foreach ($package in $sortedPackagesData) {
        # Ensure dependencies are arrays, even if empty
        $fxhDeps = @()
        if ($package.Dependencies.FxhDependencies) {
            if ($package.Dependencies.FxhDependencies -is [array]) {
                $fxhDeps = $package.Dependencies.FxhDependencies
            }
            else {
                $fxhDeps = @($package.Dependencies.FxhDependencies)
            }
        }

        $textureDeps = @()
        if ($package.Dependencies.TextureDependencies) {
            if ($package.Dependencies.TextureDependencies -is [array]) {
                $textureDeps = $package.Dependencies.TextureDependencies
            }
            else {
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
            shaders = $package.Shaders # This is a list of primary shader filenames for the package
            dependencies = @{ # This structure contains the lists of dependency filenames
                fxh = $fxhDeps
                textures = $textureDeps
            }
        }
        $manifest.packages.Add($packageManifest)
    }
    
    try {
        $manifest | ConvertTo-Json -Depth 5 | Set-Content -Path $manifestPath -Encoding UTF8
        Write-Success "Package manifest generated: $manifestPath"
    }
    catch {
        Write-Error "Failed to generate package manifest: $_"
    }
}

$manifestFilePath = Join-Path $OutputPath $config.paths.manifestFile
New-PackageManifest -packagesDataToManifest $packagesForManifest -manifestPath $manifestFilePath

# Create ZIP archives for each package
Write-Info "Creating ZIP archives for packages..."
foreach ($packageData in $packagesForManifest) {
    $packageFolderName = $packageData.Name
    $packageFolderPath = Join-Path $OutputPath $packageFolderName
    $zipFilePath = Join-Path $OutputPath "$packageFolderName.zip"

    if (Test-Path $packageFolderPath) {
        try {
            Compress-Archive -Path "$packageFolderPath\\*" -DestinationPath $zipFilePath -Force -ErrorAction Stop
            Write-Success "Created ZIP archive: $zipFilePath"
        }
        catch {
            Write-Error "Failed to create ZIP archive for $packageFolderName : $_"
        }
    }
    else {
        Write-Warning "Package folder not found for zipping: $packageFolderPath"
    }
}

# Clean up individual package folders after zipping
Remove-PackageFolders -PackagesPath $OutputPath -FolderNames $script:createdPackageFolderNames

# Create README files for each package
# ... (rest of the script remains the same for now)

# === BEGIN: Catalog auto-update for new shaders ===
$catalogPath = Join-Path $shadersRoot "shaders\catalog.json"
if (Test-Path $catalogPath) {
    $catalog = Get-Content -Path $catalogPath -Raw | ConvertFrom-Json
    # catalog.json is an array of shader objects
    $catalogItems = $catalog
    $existingFilenames = $catalogItems | ForEach-Object { $_.filename }
    $shaderDir = Join-Path $shadersRoot "shaders/AS"
    $shaderFiles = Get-ChildItem -Path $shaderDir -File -Filter "*.fx" | Where-Object { $_.Name -notmatch "^\[PRE\]" }
    $newShaders = @()
    foreach ($shaderFile in $shaderFiles) {
        # Use only the filename, not the path
        $filenameOnly = $shaderFile.Name
        if (-not ($existingFilenames -contains $filenameOnly)) {
            if ($shaderFile.Name -match "AS_([A-Z]+)_") {
                $type = $matches[1].ToUpper()
            } else {
                $type = "OTHER"
            }
            # Create a basic shader entry for new shaders
            $newShaders += @{ 
                name = $filenameOnly -replace "\.fx$", "" -replace "AS_[A-Z]+_", ""
                filename = $filenameOnly
                type = $type
                shortDescription = "Auto-generated entry for $filenameOnly"
                longDescription = "This shader was automatically detected and added to the catalog. Please update with proper description."
            }
        }
    }
    if ($newShaders.Count -gt 0) {
        Write-Info "Adding $($newShaders.Count) new shaders to catalog.json..."
        $catalog += $newShaders
    }
    # Sort items by name (case-insensitive)
    $catalog = $catalog | Sort-Object -Property name, filename
    # Write pretty-printed JSON with 4 spaces per indent
    $json = $catalog | ConvertTo-Json -Depth 20
    $json = $json -replace '^( +)', { $args[0].Value -replace '  ', '    ' }
    Set-Content -Path $catalogPath -Value $json -Encoding UTF8
    Write-Success "catalog.json updated with new shaders, sorted, and pretty-printed."
} else {
    Write-Warning "catalog.json not found, skipping catalog update."
}
# === END: Catalog auto-update for new shaders ===

# === BEGIN: Precompute statistics and arrays for README ===
$catalogPath = Join-Path $shadersRoot "shaders\catalog.json"
if (Test-Path $catalogPath) {
    $catalog = Get-Content -Path $catalogPath -Raw | ConvertFrom-Json
    # catalog.json is an array of shader objects
    $items = $catalog
    $types = @('BGX','GFX','LFX','VFX')
    
    # Create statistics object
    $statistics = @{
        total = $items.Count
        byType = @{}
    }
    
    # Create grouped object for template iteration
    $grouped = @{}
    
    # Calculate type counts and group shaders by type
    foreach ($type in $types) {
        $arr = @($items | Where-Object { $_.type -eq $type })
        $statistics.byType.$type = $arr.Count
        $grouped.$type = $arr
    }
    
    # Create a catalog structure for template rendering
    $catalogForTemplate = @{
        shaders = @{
            statistics = $statistics
        }
        grouped = $grouped
    }
    
    # Write the statistics to a separate file for README template rendering
    $statisticsPath = Join-Path $shadersRoot "shaders\catalog-statistics.json"
    $json = $catalogForTemplate | ConvertTo-Json -Depth 20
    $json = $json -replace '^( +)', { $args[0].Value -replace '  ', '    ' }
    Set-Content -Path $statisticsPath -Value $json -Encoding UTF8
    Write-Info "catalog-statistics.json updated for README rendering."
}
# === END: Precompute statistics and arrays for README ===

# === BEGIN: Render README.md from template and catalog ===
$statisticsPath = Join-Path $shadersRoot "shaders\catalog-statistics.json"
$readmeTemplatePath = Join-Path $PSScriptRoot "..\docs\template\README.md"
$readmeOutPath = Join-Path $PSScriptRoot "..\README.md"
if ((Test-Path $statisticsPath) -and (Test-Path $readmeTemplatePath)) {
    $catalogStats = Get-Content -Path $statisticsPath -Raw | ConvertFrom-Json
    $template = Get-Content -Path $readmeTemplatePath -Raw

    # Helper: Get value from nested property path (e.g., "shaders.statistics.byType.BGX")
    function Get-CatalogValue($obj, $path) {
        $parts = $path -split '\.'
        foreach ($part in $parts) {
            if ($null -eq $obj) { return $null }
            if ($obj.PSObject.Properties.Name -contains $part) {
                $obj = $obj.$part
            } else {
                return $null
            }
        }
        return $obj
    }

    # Remove all {{#each ...}} table blocks (no table interpolation)
    $template = [regex]::Replace($template, '{{#each [^}]+}}([\s\S]*?){{/each}}', '')

    # Replace all {{field}} placeholders with direct values from catalog (byType, total, etc)
    $template = $template -replace '{{([a-zA-Z0-9_.]+)}}', {
        if ($args.Count -eq 0 -or -not $args[0].Groups[1]) { return '' }
        $ph = $args[0].Groups[1].Value
        $val = Get-CatalogValue $catalogStats $ph
        if ($null -eq $val) { return '' }
        return $val.ToString()
    }

    Set-Content -Path $readmeOutPath -Value $template -Encoding UTF8
    Write-Success "README.md rendered from template and catalog statistics."
} else {
    Write-Warning "README template or catalog statistics not found, skipping README generation."
}
# === END: Render README.md from template and catalog ===
