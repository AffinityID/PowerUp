Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$env:PSModulePath += ";$(Resolve-Path '.\PowerUpCore\PowerUp\Modules\')"
Import-Module PowerUpNuGet

Write-Host "Preparing..." -ForegroundColor White
Get-ChildItem $scriptPath | % {
    if (!(Test-Path "$_\Prepare.ps1")) {
        return
    }

    Write-Host "  $_" -ForegroundColor White
    if (Test-Path "$_\packages.config") {
        Restore-NuGetPackages -Project "$_\packages.config" -PackagesDirectory "$_\_packages"
    }

    Push-Location "$_"
    try {
        &".\Prepare.ps1"
    }
    finally {
        Pop-Location
    }
}