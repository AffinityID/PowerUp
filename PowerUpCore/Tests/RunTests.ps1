Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition
$env:PSModulePath += ";$scriptPath\..\PowerUp\Modules"
$resultsPath = "$scriptPath\..\..\_testresults"

Import-Module PowerUpFileSystem
Import-Module PowerUpTestRunner

Reset-Directory $resultsPath
Invoke-PesterTests $scriptPath -ResultsDirectory $resultsPath