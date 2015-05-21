param (
    [Parameter(Mandatory=$true)][string] $installPath,
    $toolsPath,
    $package,
    $project
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

Import-Module .\_powerup\Modules\PowerUpFileSystem\PowerUpFileSystem.psm1
Invoke-Robocopy $installPath\PowerUp\Modules\PowerUpJsonFallback .\_powerup\Modules\PowerUpJsonFallback "/purge /s /np /ns /njh /njs /ndl"