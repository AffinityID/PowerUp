param($installPath, $toolsPath, $package, $project)
Set-StrictMode -Version 2

Import-Module .\_powerup\Modules\PowerUpFileSystem\PowerUpFileSystem.psm1
Copy-Directory $installPath\PowerUp .\_powerup
