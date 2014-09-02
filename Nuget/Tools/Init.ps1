Set-StrictMode -Version 2
$scriptRoot =  Split-Path -Parent $MyInvocation.MyCommand.Path

Import-Module $scriptRoot\..\PowerUp\Deploy\Modules\PowerUpFileSystem\PowerUpFileSystem.psm1

Copy-Directory $scriptRoot\..\PowerUp .\_powerup
