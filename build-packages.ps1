# =====================================================================
# AS StageFX Packaging Script
# =====================================================================
# This script generates distribution packages for AS StageFX shaders
# based on the configuration in package-config.json
# =====================================================================

param(
    [string]$ConfigPath = "$PSScriptRoot\config\package-config.json",
    [string]$OutputPath = "$PSScriptRoot\packages"
)

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
    if ($dir -eq $essentialsDir -or $dir -eq $completeDir) {
        $texturesDir = Join-Path $dir $textureDirPath
        if (-not (Test-Path $texturesDir)) {
            New-Item -ItemType Directory -Path $texturesDir -Force | Out-Null
        }
    }
}

# Copy appropriate shaders to each package
function Copy-ShadersToPackage($shaderList, $packageDir) {
    foreach ($shaderName in $shaderList) {
        $shader = $allShaders | Where-Object { $_.Name -eq $shaderName } | Select-Object -First 1
        
        if ($shader) {
            $destPath = Join-Path $packageDir "$shaderDirPath\$shaderName"
            Copy-Item -Path $shader.FullName -Destination $destPath -Force
        }
        else {
            Write-Warning "Shader not found in project: $shaderName"
        }
    }
}

# Copy textures to specified package
function Copy-TexturesToPackage($packageDir) {
    # Get texture directory
    $textureSourceDir = Join-Path $shadersRoot $textureDirPath
    if (Test-Path $textureSourceDir) {
        $textureDestDir = Join-Path $packageDir $textureDirPath
        
        # Create textures directory if it doesn't exist
        if (-not (Test-Path $textureDestDir)) {
            New-Item -ItemType Directory -Path $textureDestDir -Force | Out-Null
        }
        
        # Copy all textures
        $textures = Get-ChildItem -Path $textureSourceDir -File
        foreach ($texture in $textures) {
            $destPath = Join-Path $textureDestDir $texture.Name
            Copy-Item -Path $texture.FullName -Destination $destPath -Force
        }
        
        Write-Info "Copied $($textures.Count) texture files to $packageDir"
        return $textures.Count
    } else {
        Write-Warning "Texture directory not found: $textureSourceDir"
        return 0
    }
}

# Create the readme files for each package
function New-ReadmeFile($packageDir, $description) {
    $readmePath = Join-Path $packageDir $config.paths.readmeFile
    
    # Get package version from config
    $packageVersion = $config.version
    
    # Check if this package includes textures
    $hasTextures = Test-Path (Join-Path $packageDir $textureDirPath)
    $textureNote = ""
    if ($hasTextures) {
        $textureNote = "`nNote: This package includes texture files required by some shaders."
    }
    
    # Replace placeholders in readme template
    $readmeContent = $config.readmeTemplate
    $readmeContent = $readmeContent -replace "{version}", $packageVersion
    $readmeContent = $readmeContent -replace "{description}", $description
    $readmeContent = $readmeContent -replace "{textureNote}", $textureNote
    $readmeContent = $readmeContent -replace "{supportUrl}", $config.supportUrl
    
    Set-Content -Path $readmePath -Value $readmeContent
}

# Copy shaders to packages
Write-Info ("Generating " + $essentialsName + " package...")
Copy-ShadersToPackage $essentialShaders $essentialsDir
Copy-TexturesToPackage $essentialsDir
New-ReadmeFile $essentialsDir $config.packageDescription.essentials

Write-Info ("Generating " + $backgroundsName + " package...")
Copy-ShadersToPackage $backgroundShaders $backgroundsDir
New-ReadmeFile $backgroundsDir $config.packageDescription.backgrounds

Write-Info ("Generating " + $visualEffectsName + " package...")
Copy-ShadersToPackage $visualEffectShaders $visualEffectsDir
New-ReadmeFile $visualEffectsDir $config.packageDescription.visualeffects

Write-Info ("Generating " + $completeName + " Collection package...")
Copy-ShadersToPackage $allShadersList $completeDir
Copy-TexturesToPackage $completeDir
New-ReadmeFile $completeDir $config.packageDescription.complete

# Create ZIP archives for easy distribution
function New-ZipPackage($sourceDir) {
    $dirName = Split-Path $sourceDir -Leaf
    $zipPath = Join-Path $OutputPath "$dirName.zip"
    
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($sourceDir, $zipPath)
    
    return $zipPath
}

# Create zip packages if PowerShell version supports it
if ($PSVersionTable.PSVersion.Major -ge 5) {
    Write-Info "Creating ZIP packages..."
    
    $essentialsZip = New-ZipPackage $essentialsDir
    $backgroundsZip = New-ZipPackage $backgroundsDir
    $visualEffectsZip = New-ZipPackage $visualEffectsDir
    $completeZip = New-ZipPackage $completeDir
      Write-Success "Created ZIP packages:"
    Write-Output "  - $essentialsZip"
    Write-Output "  - $backgroundsZip"
    Write-Output "  - $visualEffectsZip"
    Write-Output "  - $completeZip"
}
else {
    Write-Warning "PowerShell 5.0 or higher required for ZIP creation. Packages are available as folders."
}

# Generate JSON manifest of package contents
function New-PackageManifest() {
    # Get package version from config
    $packageVersion = $config.version
    
    Write-Info "Using package version: $packageVersion"
    
    # Get texture file list
    $textureSourceDir = Join-Path $shadersRoot $textureDirPath
    $textureFiles = @()
    if (Test-Path $textureSourceDir) {
        $textureFiles = (Get-ChildItem -Path $textureSourceDir -File).Name
    }
    
    # Create main manifest
    $manifestFile = $config.paths.manifestFile
    $manifest = @{
        packageVersion = $packageVersion
        version = $packageVersion # For backward compatibility
        generatedOn = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        packages = @{
            essentials = @{
                name = "$packagePrefix$essentialsName"
                version = $packageVersion
                description = $config.packageDescription.essentials
                fileCount = $essentialShaders.Count
                files = $essentialShaders | Sort-Object
                textures = @{
                    fileCount = $textureFiles.Count
                    files = $textureFiles | Sort-Object
                }
            }
            backgrounds = @{
                name = "$packagePrefix$backgroundsName"
                version = $packageVersion
                description = $config.packageDescription.backgrounds
                fileCount = $backgroundShaders.Count
                files = $backgroundShaders | Sort-Object
            }
            visualEffects = @{
                name = "$packagePrefix$visualEffectsName"
                version = $packageVersion
                description = $config.packageDescription.visualeffects
                fileCount = $visualEffectShaders.Count
                files = $visualEffectShaders | Sort-Object
            }
            complete = @{
                name = "$packagePrefix$completeName"
                version = $packageVersion
                description = $config.packageDescription.complete
                fileCount = $allShadersList.Count
                files = $allShadersList | Sort-Object
                textures = @{
                    fileCount = $textureFiles.Count
                    files = $textureFiles | Sort-Object
                }
            }
        }
    }
      $manifestPath = Join-Path $OutputPath $manifestFile
    $manifest | ConvertTo-Json -Depth 4 | Set-Content -Path $manifestPath
    
    # Now that the main manifest is created, remove the package folders
    # but only if ZIP files exist (meaning we've created them earlier)
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        Remove-PackageFolders -PackagesPath $OutputPath -FolderNames @(
            "$packagePrefix$essentialsName",
            "$packagePrefix$backgroundsName",
            "$packagePrefix$visualEffectsName",
            "$packagePrefix$completeName"
        )
    }
    
    Write-Info "Generated package manifests with version: $packageVersion"
    return $manifestPath
}

$manifestPath = New-PackageManifest

# Package generation summary
Write-Success "Package generation complete!"
# Get the version for the summary
$packageVersion = $config.version

# Get texture count for the summary
$textureSourceDir = Join-Path $shadersRoot $textureDirPath
$textureCount = 0
if (Test-Path $textureSourceDir) {
    $textureCount = (Get-ChildItem -Path $textureSourceDir -File).Count
}

Write-Output "Package Version: $packageVersion"
Write-Output ($essentialsName + ": " + $essentialShaders.Count + " shaders + " + $textureCount + " textures")
Write-Output ($backgroundsName + ": " + $backgroundShaders.Count + " shaders")
Write-Output ($visualEffectsName + ": " + $visualEffectShaders.Count + " shaders")
Write-Output ($completeName + " Collection: " + $allShadersList.Count + " shaders + " + $textureCount + " textures")
Write-Output ""
Write-Output "Packages are available at: $OutputPath"
Write-Output "Package manifest: $manifestPath"
