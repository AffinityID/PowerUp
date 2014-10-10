param(
    [Parameter(Mandatory=$true)][string] $operation, 
    [string] $operationProfile,
    [int] $buildNumber = 0,
    [string] $task = "default"
)

$ExitCode = 0;

Set-StrictMode -Version 2
Write-Host "Executing under account $env:username"
$ErrorActionPreference='Stop'

Write-Host "Importing PowerUp modules"
$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition
$env:PSModulePath += ";$scriptPath\Combos\;$scriptPath\Modules\"

$operationFile = ".\" + $operation + ".ps1"
Write-Host "Invoking PSake with the following:
    Operation: $operation
    OperationFile: $operationFile
    OperationProfile: $operationProfile
    BuildNumber: $buildNumber
    Task: $task"

# Settings should probably be placed here and passed in as part of the parameters when invoking PSake

New-Variable 'powerup.operation' -Value $operation -Option Constant -Scope Global
New-Variable 'powerup.profile' -Value $operationProfile -Option Constant -Scope Global

Import-Module PSake
Invoke-PSake $operationFile $task -Parameters @{
    "build.number" = $buildNumber;
    # Obsolete, use powerup.* from above:
    "operation.profile" = $operationProfile;
    "deployment.profile" = $operationProfile
}

if (-not $PSake.build_success) {
    $host.ui.WriteErrorLine("Build Failed!")
    $ExitCode = 1
}
elseif (Test-Path variable:LastExitCode) {
    $ExitCode = $LastExitCode
}

Write-Host "Exiting with exit code: $ExitCode"
exit $ExitCode