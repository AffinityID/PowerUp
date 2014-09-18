param($installPath, $toolsPath, $package, $project)
Set-StrictMode -Version 2

Import-Module $installPath\PowerUp\Modules\PowerUpFileSystem\PowerUpFileSystem.psm1
Copy-Directory $installPath\PowerUp .\_powerup
