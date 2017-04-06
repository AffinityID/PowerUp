Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Invoke-ComboRemotableTask([Parameter(Mandatory=$true)] [string] $task, [Hashtable] $options) {
    Import-Module PowerUpUtilities
    Merge-Defaults $options @{ remote = $false }
    if ($options['getServerSettings']) {
        Write-Error "Invoke-ComboRemotableTask: Option 'getServerSettings' is obsolete and should not be used."
    }

    if (!$options.remote) {
        Write-Host "Task $task will be executed locally."
        Invoke-Task $task
        return
    }
        
    Write-Host "Task $task will be executed on $($options.servers)."
    Import-Module PowerUpRemote
    $currentPath = Get-Location
    foreach ($serverName in $options.servers) {
        Invoke-RemoteTasks `
            -ServerName $serverName `
            -ShareName $options.share `
            -PackageName $options.workingSubFolder `
            -Operation ${powerup.operation} `
            -Tasks $task `
            -Profile ${powerup.profile} `
    }
}