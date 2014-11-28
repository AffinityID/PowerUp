Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

function Invoke-PowerUp(
    [Parameter(Mandatory=$true)] [string] $operation,
    [int] $buildNumber = 0,
    [string] $profile = '',
    [string] $task = ''
) {
    Import-Module PowerUpUtilities

    $message = "$operation"
    $command = "$PSScriptRoot\..\..\Run -operation $operation"
    if ($buildNumber -ne 0) { $command += " -buildNumber $buildNumber" }
    if ($profile -ne '')    {
        $command += " -operationProfile $profile"
        $message += " $profile"
    }
    if ($task -ne '')       { 
        $command += " -task $task"
        $message += " ($task)"
    }

    Write-Host "`r`n--- PowerUp $($message): starting  ---`r`n" -ForegroundColor White
    try {
        Invoke-External $command
    }
    catch {
        Write-Host "`r`n--- PowerUp $($message): failed ---`r`n" -ForegroundColor Red
        throw
    }
    Write-Host "`r`n--- PowerUp $($message): completed ---`r`n" -ForegroundColor White
}