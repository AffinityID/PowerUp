param (
    [Parameter(Mandatory=$true)][string] $installPath,
    $toolsPath,
    $package,
    $project
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$env:PSModulePath += ";$installPath\PowerUp\Modules"

Import-Module PowerUpFileSystem
if (Test-Path  '.\_powerup\Modules') {
    $externals = (Get-Item .\_powerup\Modules\*\.PowerUpExternal | % { $_.Directory })
    if ($externals -eq $null) { # PowerShell quirk?
        $externals = @()
    }
}
else {
    $externals = @()
}

if ($externals) {
    Write-Host "External modules:"
    $externals | % { Write-Host "  $($_.Name)" }
}

Invoke-Robocopy $installPath\PowerUp .\_powerup `
    -Purge -CopyDirectories `
    -ExcludeDirectories @($externals | % { "`"$($_.FullName)`"" }) `
    -NoFileSize -NoProgress -NoDirectoryList -NoJobHeader -NoJobSummary

if (!(Test-Path ".\powerup.bat")) {
    New-Item _templates -Type Directory | Out-Null
    Invoke-Robocopy . _templates -Files *.config `
        -CopyDirectories `
        -ExcludeDirectories _templates -ExcludeExtra -ExcludeChanged -ExcludeNewer -ExcludeOlder `
        -NoDirectoryList -NoJobHeader -NoJobSummary
    
    # Test-Path is so that other files can be deleted if not needed
    Invoke-Robocopy $installPath\RootFiles . `
        -CopyDirectoriesIncludingEmpty `
        -ExcludeExtra -ExcludeChanged -ExcludeNewer -ExcludeOlder `
        -NoFileSize -NoProgress -NoJobHeader -NoJobSummary
}