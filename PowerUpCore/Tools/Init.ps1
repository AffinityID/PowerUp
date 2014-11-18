param($installPath, $toolsPath, $package, $project)
Set-StrictMode -Version 2

Import-Module $installPath\PowerUp\Modules\PowerUpFileSystem\PowerUpFileSystem.psm1
Invoke-Robocopy $installPath\PowerUp .\_powerup "/np /ns /ndl /njh /njs"

if (!(Test-Path ".\powerup.bat")) {
    # Test-Path is so that other files can be deleted if not needed
    Invoke-Robocopy $installPath\RootFiles . "/xx /xc /xn /xo /np /ns /ndl /njh /njs"
}