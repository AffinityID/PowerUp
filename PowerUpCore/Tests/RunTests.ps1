Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition
$env:PSModulePath += ";$scriptPath\..\PowerUp\Modules"

Import-Module "$scriptPath\..\PowerUp\Modules\PowerUpTestRunner\Pester.3.0.0\Pester"
Invoke-Pester -Path .