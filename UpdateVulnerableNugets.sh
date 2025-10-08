#!/bin/bash

# UpdateVulnerableNugets.sh
# Shell wrapper for UpdateVulnerableNugets.ps1
# This provides a convenient way to run the PowerShell script on Linux/macOS

echo "eShop Vulnerable NuGet Package Updater (Shell Wrapper)"
echo "======================================================"

# Check if PowerShell Core is available
if command -v pwsh &> /dev/null; then
    echo "Using PowerShell Core (pwsh)"
    pwsh -ExecutionPolicy Bypass -File "$(dirname "$0")/UpdateVulnerableNugets.ps1" "$@"
    exit $?
fi

# Check if dotnet can run PowerShell
if command -v dotnet &> /dev/null; then
    # Try to use dotnet to run PowerShell if available as a global tool
    if dotnet tool list -g | grep -q "Microsoft.PowerShell.ConsoleHost" 2>/dev/null; then
        echo "Using PowerShell via dotnet global tool"
        dotnet pwsh -ExecutionPolicy Bypass -File "$(dirname "$0")/UpdateVulnerableNugets.ps1" "$@"
        exit $?
    fi
fi

echo "ERROR: PowerShell Core (pwsh) not found."
echo "Please install PowerShell Core:"
echo ""
echo "On Ubuntu/Debian:"
echo "  sudo apt-get install -y powershell"
echo ""
echo "On RHEL/CentOS:"
echo "  sudo yum install -y powershell"
echo ""
echo "On macOS with Homebrew:"
echo "  brew install powershell"
echo ""
echo "Or download from: https://github.com/PowerShell/PowerShell/releases"
echo ""
echo "Alternatively, you can install as a .NET global tool:"
echo "  dotnet tool install --global PowerShell"

exit 1