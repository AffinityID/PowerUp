Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

function Invoke-PowerUp(
    [Parameter(Mandatory=$true)] [string] $operation,
    [int] $buildNumber = 0,
    [string] $profile = '',
    [string] $task = ''
) {
    $command = "$PSScriptRoot\..\..\Run -operation $operation"
    if ($buildNumber -ne 0) { $command += " -buildNumber $buildNumber" }
    if ($profile -ne '')    { $command += " -operationProfile $profile" }
    if ($task -ne '')       { $command += " -task $task" }
    
    Write-Host $command
    Invoke-Expression $command
}