param($installPath, $toolsPath, $package, $project)
Set-StrictMode -Version 2

Import-Module $installPath\PowerUp\Modules\PowerUpFileSystem\PowerUpFileSystem.psm1
Invoke-Robocopy $installPath\PowerUp .\_powerup "/s /purge /np /ns /njh /njs /ndl"

if (!(Test-Path ".\powerup.bat")) {
    # Test-Path is so that other files can be deleted if not needed
    Invoke-Robocopy $installPath\RootFiles . "/xx /xc /xn /xo /np /ns /njh /njs"
}