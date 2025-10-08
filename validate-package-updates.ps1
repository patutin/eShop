#!/usr/bin/env pwsh
# Package Update Validation Script
# This script validates the NuGet package updates and runs security scans

Write-Host "🔍 eShop Package Update Validation" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Check .NET SDK version
Write-Host "`n📋 Checking .NET SDK version..." -ForegroundColor Yellow
dotnet --version

# Clean and restore packages
Write-Host "`n🧹 Cleaning solution..." -ForegroundColor Yellow
dotnet clean

Write-Host "`n📦 Restoring packages..." -ForegroundColor Yellow
dotnet restore
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Package restore failed!" -ForegroundColor Red
    exit 1
}

# Check for vulnerable packages (PRIORITY)
Write-Host "`n🚨 Checking for vulnerable packages..." -ForegroundColor Red
Write-Host "=====================================" -ForegroundColor Red
dotnet list package --vulnerable
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Vulnerability scan completed" -ForegroundColor Green
} else {
    Write-Host "⚠️  Vulnerability scan had issues" -ForegroundColor Yellow
}

# Check for outdated packages
Write-Host "`n📈 Checking for outdated packages..." -ForegroundColor Yellow
dotnet list package --outdated
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Outdated package scan completed" -ForegroundColor Green
} else {
    Write-Host "⚠️  Outdated package scan had issues" -ForegroundColor Yellow
}

# Build solution
Write-Host "`n🔨 Building solution..." -ForegroundColor Yellow
dotnet build --no-restore
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed! Check for breaking changes from package updates." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Build successful!" -ForegroundColor Green

# Run tests
Write-Host "`n🧪 Running tests..." -ForegroundColor Yellow
dotnet test --no-build --verbosity normal
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Tests failed! Check for compatibility issues." -ForegroundColor Red
    exit 1
}
Write-Host "✅ All tests passed!" -ForegroundColor Green

# Final vulnerability check
Write-Host "`n🔒 Final security validation..." -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Green
dotnet list package --vulnerable
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Security validation completed" -ForegroundColor Green
    Write-Host "🎉 Package updates validated successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Please review vulnerability scan results" -ForegroundColor Yellow
}

Write-Host "`n📊 Package Update Summary:" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "• Duende.IdentityServer: 7.3.2 → 7.4.1 (Security)" -ForegroundColor White
Write-Host "• MediatR: 13.0.0 → 13.1.1" -ForegroundColor White  
Write-Host "• gRPC: 2.71.0 → 2.73.0" -ForegroundColor White
Write-Host "• FluentValidation: 12.0.0 → 12.2.0" -ForegroundColor White
Write-Host "• Dapper: 2.1.35 → 2.1.44" -ForegroundColor White
Write-Host "• OpenTelemetry: 1.12.0 → 1.13.0" -ForegroundColor White
Write-Host "• xUnit: 2.9.3 → 2.10.0" -ForegroundColor White
Write-Host "• Google.Protobuf: 3.32.1 → 3.35.2 (Security)" -ForegroundColor White
Write-Host "• IdentityModel: 7.0.0 → 7.1.0 (Security)" -ForegroundColor White
Write-Host "• And other security/stability updates" -ForegroundColor White