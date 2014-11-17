Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Invoke-ComboScheduledTasks([Parameter(Mandatory=$true)][hashtable] $options) {
    Import-Module PowerUpUtilities
    Import-Module PowerUpScheduledTask
    Import-Module PowerUpFileSystem
    
    # apply defaults
    Merge-Defaults $options @{
        commandarguments = ''
        destinationfolder = { $options.sourcefolder }
        fullsourcefolder = { "$(get-location)\$($options.sourcefolder)" }
        fulldestinationfolder = { "$($options.approot)\$($options.destinationfolder)" }
        fullcommandpath = { "$($options.fulldestinationfolder)\$($options.command)" }
        '[ordered]' = @('destinationfolder','fullsourcefolder','fulldestinationfolder','fullcommandpath')
    }
    Write-Host "Scheduled task options: $($options | Out-String)"
    
    Disable-ScheduledTasksOfPath $options.fullcommandpath
    try {
        Copy-MirroredDirectory $options.fullsourcefolder $options.fulldestinationfolder
        
        $options.tasks | % {
            $task = $_
            $definition = @{
                name = $task.name
                path = $options.fullcommandpath
                arguments = $options.commandarguments
                schedule = $task.schedule
                time = $task.time
                days = $task.days
            }
            if ($task.ContainsKey('username')) {
                $definition.username = $task.username
                $definition.password = $task.password
            }
            
            Write-Host "Task: $($definition | Out-String)"
            if (Test-ScheduledTask $task.name) {
                Write-Warning "Scheduled task $($task.name) already exists, it will be deleted and recreated."
                Update-ScheduledTask $definition
            }
            else {
                Create-ScheduledTask $definition
            }
        }
    }
    finally {
        Enable-ScheduledTasksOfPath $options.fullcommandpath
    }
}