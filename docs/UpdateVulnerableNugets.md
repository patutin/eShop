# UpdateVulnerableNugets - Security Package Update Tool

## Overview

The UpdateVulnerableNugets tools help maintain the security of the eShop application by identifying and updating NuGet packages with known security vulnerabilities.

## Files

- **UpdateVulnerableNugets.ps1** - Main PowerShell script with full functionality
- **UpdateVulnerableNugets.bat** - Windows batch wrapper 
- **UpdateVulnerableNugets.sh** - Linux/macOS shell wrapper
- **docs/UpdateVulnerableNugets.md** - This documentation

## Features

### Vulnerability Scanning
- Scans all projects in the solution for packages with known security vulnerabilities
- Uses `dotnet list package --vulnerable` command for accurate vulnerability detection
- Reports vulnerability severity levels (Low, Medium, High, Critical)
- Shows advisory information for each vulnerability

### Package Management Integration
- Works seamlessly with centralized package management (Directory.Packages.props)
- Handles both direct version specifications and MSBuild variable references
- Automatically updates variable definitions when packages use version variables
- Preserves existing package configuration and formatting

### Safe Update Process
- Dry-run mode to preview changes before applying them
- Severity-based filtering (updates High/Critical by default, use -Force for all)
- Automatic package restore after updates
- Backup-friendly (changes are visible in git diff)

### Cross-Platform Support
- PowerShell Core for cross-platform compatibility
- Platform-specific wrapper scripts for convenience
- Handles different PowerShell installations gracefully

## Usage

### Basic Usage

```powershell
# Scan and update high/critical vulnerabilities
./UpdateVulnerableNugets.ps1

# Preview what would be updated (recommended first step)
./UpdateVulnerableNugets.ps1 -DryRun

# Update all vulnerabilities regardless of severity
./UpdateVulnerableNugets.ps1 -Force
```

### Platform-Specific Commands

**Windows:**
```cmd
UpdateVulnerableNugets.bat
UpdateVulnerableNugets.bat -DryRun
```

**Linux/macOS:**
```bash
./UpdateVulnerableNugets.sh
./UpdateVulnerableNugets.sh -DryRun
```

### Parameters

- `-DryRun` - Preview mode, shows what would be updated without making changes
- `-Force` - Update all vulnerabilities including lower severity ones (Low/Medium)

## Prerequisites

### Required
- .NET SDK (version matching global.json)
- Solution must be buildable/restorable

### Recommended
- PowerShell Core (pwsh) for best cross-platform experience
- Git for tracking changes

### Installation on Different Platforms

**Windows:**
PowerShell is typically pre-installed. For PowerShell Core:
```powershell
winget install Microsoft.PowerShell
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install -y powershell
```

**Linux (RHEL/CentOS):**
```bash
sudo yum install -y powershell
```

**macOS:**
```bash
brew install powershell
```

**As .NET Global Tool:**
```bash
dotnet tool install --global PowerShell
```

## How It Works

### 1. Environment Validation
- Checks for .NET SDK availability
- Validates PowerShell installation
- Locates solution files (prefers .slnf for web projects)

### 2. Vulnerability Detection
- Runs `dotnet list package --vulnerable --include-transitive`
- Parses output to identify vulnerable packages
- Extracts package names, versions, severity, and advisory information

### 3. Version Resolution
- Attempts to find latest secure versions using `dotnet nuget search`
- Falls back to heuristic version increment for patch updates
- Respects semantic versioning principles

### 4. Package Updates
- Updates Directory.Packages.props with new versions
- Handles both direct versions and MSBuild variables
- Preserves XML formatting and structure

### 5. Validation
- Runs `dotnet restore` to validate updated packages
- Reports any restoration issues or conflicts

## Directory.Packages.props Integration

The script understands the centralized package management format used in this project:

```xml
<PropertyGroup>
  <AspireVersion>9.5.0</AspireVersion>
</PropertyGroup>
<ItemGroup>
  <!-- Direct version -->
  <PackageVersion Include="Dapper" Version="2.1.35" />
  
  <!-- Variable reference -->
  <PackageVersion Include="Aspire.Hosting.Redis" Version="$(AspireVersion)" />
</ItemGroup>
```

### Variable Handling
When a package uses a variable reference like `$(AspireVersion)`, the script:
1. Identifies the variable name
2. Locates the variable definition in the PropertyGroup
3. Updates the variable value (affecting all packages using that variable)
4. Reports which variable was updated

## Best Practices

### Before Running
1. Commit or stash any uncommitted changes
2. Run with `-DryRun` first to review planned changes
3. Ensure your development environment is ready for testing

### After Running
1. Review the changes with `git diff Directory.Packages.props`
2. Run `dotnet build` to check for compilation issues
3. Run `dotnet test` to validate functionality
4. Test critical application paths manually

### Regular Maintenance
1. Run weekly or after Dependabot PRs are merged
2. Monitor security advisories for your key dependencies
3. Keep the .NET SDK updated to the latest stable version

## Troubleshooting

### Common Issues

**"Please install .NET SDK to continue"**
- The required .NET SDK version (from global.json) is not installed
- Install the correct SDK version or update global.json

**"No solution files found"**
- Run from the repository root directory
- Ensure .sln, .slnx, or .slnf files exist

**"PowerShell not found"**
- Install PowerShell Core using platform-specific instructions above
- Use the appropriate wrapper script for your platform

**Package restore fails after updates**
- Some package combinations may be incompatible
- Review the specific error messages
- Consider updating one package at a time
- Check for known breaking changes in updated packages

### Limitations

1. **Transitive Dependencies**: The script focuses on top-level packages. Some vulnerabilities may be in transitive dependencies that require updating parent packages.

2. **Breaking Changes**: The script doesn't analyze breaking changes between versions. Always test after updates.

3. **Version Constraints**: Some packages may have version constraints that prevent updating to the latest version.

4. **Beta/Preview Packages**: The script may not handle pre-release versions optimally.

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Security Scan
on:
  schedule:
    - cron: '0 2 * * 1'  # Weekly on Monday at 2 AM
  workflow_dispatch:

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
      - name: Scan for vulnerable packages
        run: ./UpdateVulnerableNugets.sh -DryRun
      - name: Create issue if vulnerabilities found
        if: failure()
        # Add your issue creation logic here
```

## Related Tools

- **Dependabot**: Automated dependency updates (configured in `.github/dependabot.yml`)
- **dotnet list package**: Core .NET vulnerability scanning
- **dotnet-outdated**: More comprehensive package update tool
- **Snyk**: Commercial security scanning platform
- **OWASP Dependency-Check**: Open-source security scanner

## Contributing

To improve the UpdateVulnerableNugets tools:

1. Test with different package configurations
2. Add support for additional package managers (if needed)
3. Improve version resolution logic
4. Add more comprehensive error handling
5. Enhance cross-platform compatibility

Please follow the project's contribution guidelines and ensure changes work across all supported platforms.