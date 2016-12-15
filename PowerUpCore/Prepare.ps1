Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

Import-Module PowerUpFileSystem

$nuGetToolsPath = "PowerUp/Modules/PowerUpNuGet/tools"
Ensure-Directory $nuGetToolsPath
Copy-Item '_packages/Nupkg*/tools/*.*' $nuGetToolsPath
Copy-Item '_packages/NuGet.*/tools/*.*' $nuGetToolsPath