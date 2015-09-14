Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Invoke-ComboRemotableTask([Parameter(Mandatory=$true)] [string] $task, [Hashtable] $options) {
    Import-Module PowerUpUtilities
    Merge-Defaults $options @{ remote = $false };
    if ($options['getServerSettings']) {
        Write-Warning "Invoke-ComboRemotableTask: Option 'getServerSettings' is obsolete and should not be used."
    }

    if (!$options.remote) {
        Write-Host "Task $task will be executed locally."
        Invoke-Task $task
        return
    }
        
    Write-Host "Task $task will be executed on $($options.servers)."
    Import-Module PowerUpRemote
    $currentPath = Get-Location
    Invoke-RemoteTasks `
        -operation ${powerup.operation} `
        -tasks $task `
        -serverNames $options.servers `
        -profile ${powerup.profile} `
        -packageName $options.workingSubFolder
}