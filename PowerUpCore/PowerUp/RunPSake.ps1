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
$parentPath = Split-Path -parent $MyInvocation.MyCommand.Definition
Get-ChildItem "$parentPath\..\..\*" -Include 'Modules','Combos' -Recurse | sort Name | % {
    $env:PSModulePath += ";$($_.FullName)\"
}

$operationFile = ".\" + $operation + ".ps1"
Write-Host "Invoking PSake with the following:
    Operation: $operation
    OperationFile: $operationFile
    OperationProfile: $operationProfile
    Task: $task"

Import-Module PowerUpPsake\PSake
Invoke-PSake $operationFile $task -Framework 4.0x64 -Parameters @{ "build.number" = $buildNumber; "operation.profile" = $operationProfile; "deployment.profile" = $operationProfile }

if (-not $PSake.build_success) {
    $host.ui.WriteErrorLine("Build Failed!")
    $ExitCode = 1
}
elseif (Test-Path variable:LastExitCode) {
    $ExitCode = $LastExitCode
}

Write-Host "Exiting with exit code: $ExitCode"
exit $ExitCode