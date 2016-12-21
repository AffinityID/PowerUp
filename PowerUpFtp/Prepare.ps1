Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

Import-Module PowerUpFileSystem

$toolsPath = "PowerUp/Modules/PowerUpFtp/tools"
Ensure-Directory $toolsPath
Copy-Item '_packages/ftpush.*/tools/ftpush.exe' "$toolsPath/ftpush.exe"