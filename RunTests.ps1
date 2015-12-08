Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Get-ChildItem $scriptPath | % {
    $modulePath = Join-Path $_ 'PowerUp\Modules'
    if (Test-Path $modulePath) {
        $modulePath = Resolve-Path $modulePath    
        $env:PSModulePath += ";$modulePath"
        Write-Host "PSModulePath: added $modulePath."
    }
}

$resultsPath = Join-Path $scriptPath "_testresults"

Import-Module PowerUpFileSystem
Import-Module PowerUpPester

$testsPath = Join-Path $scriptPath "_tests"
Reset-Directory $testsPath
Get-ChildItem $scriptPath | % {
    $testPath = Join-Path $_ 'Tests'
    if (Test-Path $testPath) {
        Copy-Item "$testPath\*" -Destination $testsPath -Recurse
    }
}

Reset-Directory $resultsPath
Invoke-PesterTests $testsPath -ResultsDirectory $resultsPath
Remove-DirectoryFailSafe $testsPath