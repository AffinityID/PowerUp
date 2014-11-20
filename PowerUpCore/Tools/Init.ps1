param (
    [Parameter(Mandatory=$true)][string] $installPath,
    $toolsPath,
    $package,
    $project
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

Import-Module $installPath\PowerUp\Modules\PowerUpFileSystem\PowerUpFileSystem.psm1
if (Test-Path  '.\_powerup\Modules') {
    $externals = (Get-Item .\_powerup\Modules\*\.PowerUpExternal | % { $_.Directory })
}
else {
    $externals = @()
}

if ($externals) {
    Write-Host "External modules:"
    $externals | % { Write-Host "  $($_.Name)" }
}

$externalsString = ($externals | % { "`"$($_.FullName)`"" }) -join ' '
Invoke-Robocopy $installPath\PowerUp .\_powerup "/purge /s /np /ns /njh /njs /ndl /xd $externalsString"

if (!(Test-Path ".\powerup.bat")) {
    # Test-Path is so that other files can be deleted if not needed
    Invoke-Robocopy $installPath\RootFiles . "/xx /xc /xn /xo /np /ns /njh /njs"
}