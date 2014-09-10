param(
    [Parameter(Mandatory=$true)][string] $operation, 
    [string] $operationProfile,
    [string] $task = "default"
)

Set-StrictMode -Version 2
Write-Host "Executing under account $env:username"
$ErrorActionPreference='Stop'

Write-Host "Importing PowerUp modules"
$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition
$env:PSModulePath = $env:PSModulePath + ";$scriptPath\Modules\" + ";$scriptPath\Combos\"

$operationFile = ".\" + $operation + ".ps1"
Write-Host "Invoking PSake with the following:
    Operation: $operation
    OperationFile: $operationFile
    OperationProfile: $operationProfile
    Task: $task"

Import-Module PowerUpPsake\PSake
Invoke-PSake $operationFile $task -parameters @{ "operation.profile" = $operationProfile; "deployment.profile" = $operationProfile }
