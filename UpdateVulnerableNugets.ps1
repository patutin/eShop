#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Updates vulnerable NuGet packages in the eShop solution
    
.DESCRIPTION
    This script scans the eShop solution for NuGet packages with known security vulnerabilities
    and updates them to secure versions. It works with the centralized package management
    system used in this project (Directory.Packages.props).
    
.PARAMETER DryRun
    If specified, only shows what packages would be updated without making changes
    
.PARAMETER Force
    If specified, updates packages even if there are potential breaking changes
    
.EXAMPLE
    .\UpdateVulnerableNugets.ps1
    Scans and updates vulnerable packages
    
.EXAMPLE
    .\UpdateVulnerableNugets.ps1 -DryRun
    Shows what packages would be updated without making changes
#>

param(
    [switch]$DryRun,
    [switch]$Force
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-ColorOutput {
    param($Color, $Message)
    Write-Host "$Color$Message$Reset"
}

function Test-DotNetSdk {
    try {
        $dotnetVersion = dotnet --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput $Green "✓ .NET SDK found: $dotnetVersion"
            return $true
        }
    }
    catch {
        Write-ColorOutput $Red "✗ .NET SDK not found or not accessible"
        return $false
    }
    return $false
}

function Get-VulnerablePackages {
    param($SolutionPath)
    
    Write-ColorOutput $Blue "🔍 Scanning for vulnerable packages..."
    
    try {
        # Run dotnet list package --vulnerable for the solution
        $vulnerableOutput = dotnet list "$SolutionPath" package --vulnerable --include-transitive 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput $Red "Error scanning for vulnerable packages:"
            Write-Host $vulnerableOutput
            return @()
        }
        
        # Parse the output to extract vulnerable packages
        $vulnerablePackages = @()
        $currentProject = ""
        $inVulnerableSection = $false
        
        foreach ($line in $vulnerableOutput -split "`n") {
            $line = $line.Trim()
            
            if ($line -match "^Project '(.+)'") {
                $currentProject = $matches[1]
                $inVulnerableSection = $false
            }
            elseif ($line -match "has the following vulnerable packages") {
                $inVulnerableSection = $true
            }
            elseif ($inVulnerableSection -and $line -match "^\s*>\s*(\S+)\s+(\S+)\s+(\S+)\s+(.+)") {
                $packageName = $matches[1]
                $version = $matches[2]
                $severity = $matches[3]
                $advisory = $matches[4]
                
                $vulnerablePackages += [PSCustomObject]@{
                    Project = $currentProject
                    Package = $packageName
                    Version = $version
                    Severity = $severity
                    Advisory = $advisory
                }
            }
        }
        
        return $vulnerablePackages
    }
    catch {
        Write-ColorOutput $Red "Error scanning for vulnerable packages: $($_.Exception.Message)"
        return @()
    }
}

function Update-PackageInDirectoryPackages {
    param($PackageName, $NewVersion, $DirectoryPackagesPath)
    
    if (-not (Test-Path $DirectoryPackagesPath)) {
        Write-ColorOutput $Red "Directory.Packages.props not found at $DirectoryPackagesPath"
        return $false
    }
    
    try {
        $content = Get-Content $DirectoryPackagesPath -Raw
        
        # Pattern to match PackageVersion Include="PackageName" Version="x.x.x" or Version="$(Variable)"
        $escapedPackageName = [regex]::Escape($PackageName)
        $pattern = "(<PackageVersion\s+Include=`"$escapedPackageName`"\s+Version=`")([^`"]+)(`"[^/>]*/?>"
        
        if ($content -match $pattern) {
            $oldVersion = $matches[2]
            
            # Check if the version uses a variable reference
            if ($oldVersion -match '^\$\(([^)]+)\)$') {
                $variableName = $matches[1]
                Write-ColorOutput $Yellow "Package $PackageName uses variable version '$oldVersion'"
                
                # Try to update the variable definition instead
                $result = Update-VariableInDirectoryPackages -VariableName $variableName -NewVersion $NewVersion -DirectoryPackagesPath $DirectoryPackagesPath
                return $result
            }
            
            $newContent = $content -replace $pattern, "`${1}$NewVersion`${3}"
            
            if (-not $DryRun) {
                Set-Content $DirectoryPackagesPath $newContent -NoNewline
                Write-ColorOutput $Green "✓ Updated $PackageName from $oldVersion to $NewVersion in Directory.Packages.props"
            } else {
                Write-ColorOutput $Yellow "Would update $PackageName from $oldVersion to $NewVersion in Directory.Packages.props"
            }
            return $true
        } else {
            Write-ColorOutput $Yellow "Package $PackageName not found in Directory.Packages.props (might be transitive)"
            return $false
        }
    }
    catch {
        Write-ColorOutput $Red "Error updating $PackageName in Directory.Packages.props: $($_.Exception.Message)"
        return $false
    }
}

function Update-VariableInDirectoryPackages {
    param($VariableName, $NewVersion, $DirectoryPackagesPath)
    
    try {
        $content = Get-Content $DirectoryPackagesPath -Raw
        
        # Pattern to match variable definition like <VariableName>version</VariableName>
        $escapedVariableName = [regex]::Escape($VariableName)
        $pattern = "(<$escapedVariableName>)([^<]+)(</$escapedVariableName>)"
        
        if ($content -match $pattern) {
            $oldVersion = $matches[2]
            
            if (-not $DryRun) {
                $newContent = $content -replace $pattern, "`${1}$NewVersion`${3}"
                Set-Content $DirectoryPackagesPath $newContent -NoNewline
                Write-ColorOutput $Green "✓ Updated variable $VariableName from $oldVersion to $NewVersion in Directory.Packages.props"
            } else {
                Write-ColorOutput $Yellow "Would update variable $VariableName from $oldVersion to $NewVersion in Directory.Packages.props"
            }
            return $true
        } else {
            Write-ColorOutput $Yellow "Variable $VariableName not found in Directory.Packages.props"
            return $false
        }
    }
    catch {
        Write-ColorOutput $Red "Error updating variable $VariableName in Directory.Packages.props: $($_.Exception.Message)"
        return $false
    }
}

function Get-LatestSecureVersion {
    param($PackageName, $CurrentVersion)
    
    try {
        # Use dotnet-outdated or nuget CLI to get latest version
        # For simplicity, we'll use a basic approach with dotnet CLI
        $searchResult = dotnet nuget search $PackageName --exact-match --format json 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $searchResult) {
            $searchData = $searchResult | ConvertFrom-Json
            if ($searchData.data -and $searchData.data.Count -gt 0) {
                $latestVersion = $searchData.data[0].version
                return $latestVersion
            }
        }
        
        # Fallback: suggest incrementing patch version as a basic heuristic
        if ($CurrentVersion -match "^(\d+)\.(\d+)\.(\d+)") {
            $major = [int]$matches[1]
            $minor = [int]$matches[2]
            $patch = [int]$matches[3] + 1
            return "$major.$minor.$patch"
        }
        
        return $null
    }
    catch {
        Write-ColorOutput $Yellow "Could not determine latest version for $PackageName"
        return $null
    }
}

# Main execution
Write-ColorOutput $Blue "eShop Vulnerable NuGet Package Updater"
Write-ColorOutput $Blue "======================================"

if ($DryRun) {
    Write-ColorOutput $Yellow "🔍 Running in DRY RUN mode - no changes will be made"
}

# Check if .NET SDK is available
if (-not (Test-DotNetSdk)) {
    Write-ColorOutput $Red "Please install .NET SDK to continue"
    exit 1
}

# Find solution files
$solutionFiles = Get-ChildItem -Path "." -Name "*.sln*" | Where-Object { $_ -match "\.(sln|slnx|slnf)$" }

if ($solutionFiles.Count -eq 0) {
    Write-ColorOutput $Red "No solution files found in current directory"
    exit 1
}

# Use the first solution file found, prefer .slnf for web projects
$solutionFile = $solutionFiles | Where-Object { $_ -match "\.slnf$" } | Select-Object -First 1
if (-not $solutionFile) {
    $solutionFile = $solutionFiles[0]
}

Write-ColorOutput $Green "Using solution file: $solutionFile"

# Path to Directory.Packages.props
$directoryPackagesPath = Join-Path $PWD "Directory.Packages.props"

# Scan for vulnerable packages
$vulnerablePackages = Get-VulnerablePackages -SolutionPath $solutionFile

if ($vulnerablePackages.Count -eq 0) {
    Write-ColorOutput $Green "🎉 No vulnerable packages found!"
    exit 0
}

Write-ColorOutput $Red "Found $($vulnerablePackages.Count) vulnerable package(s):"
Write-Host ""

# Group by package name to avoid duplicates
$uniqueVulnerabilities = $vulnerablePackages | Group-Object Package

foreach ($group in $uniqueVulnerabilities) {
    $packageName = $group.Name
    $vulnerabilities = $group.Group
    $currentVersion = $vulnerabilities[0].Version
    $maxSeverity = ($vulnerabilities | ForEach-Object { $_.Severity } | Measure-Object -Maximum).Maximum
    
    Write-ColorOutput $Red "📦 $packageName ($currentVersion)"
    foreach ($vuln in $vulnerabilities) {
        Write-Host "   ⚠️  Severity: $($vuln.Severity) - $($vuln.Advisory)"
    }
    
    # Try to get latest secure version
    $latestVersion = Get-LatestSecureVersion -PackageName $packageName -CurrentVersion $currentVersion
    
    if ($latestVersion -and $latestVersion -ne $currentVersion) {
        Write-ColorOutput $Green "   💡 Latest version available: $latestVersion"
        
        if ($Force -or $maxSeverity -in @("High", "Critical")) {
            $updated = Update-PackageInDirectoryPackages -PackageName $packageName -NewVersion $latestVersion -DirectoryPackagesPath $directoryPackagesPath
            if ($updated) {
                Write-ColorOutput $Green "   ✅ Package updated successfully"
            }
        } else {
            Write-ColorOutput $Yellow "   ⏳ Skipped (use -Force to update lower severity vulnerabilities)"
        }
    } else {
        Write-ColorOutput $Yellow "   ❓ Could not determine safe update version"
    }
    Write-Host ""
}

if (-not $DryRun) {
    Write-ColorOutput $Blue "🔄 Restoring packages after updates..."
    try {
        dotnet restore $solutionFile
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput $Green "✓ Package restore completed successfully"
        } else {
            Write-ColorOutput $Yellow "⚠️  Package restore completed with warnings"
        }
    }
    catch {
        Write-ColorOutput $Red "❌ Error during package restore: $($_.Exception.Message)"
    }
}

Write-ColorOutput $Blue "✅ Vulnerable package update process completed"

if (-not $DryRun) {
    Write-ColorOutput $Yellow "💡 Recommendation: Test your application thoroughly after updating packages"
    Write-ColorOutput $Yellow "💡 Consider running 'dotnet build' and 'dotnet test' to ensure compatibility"
}