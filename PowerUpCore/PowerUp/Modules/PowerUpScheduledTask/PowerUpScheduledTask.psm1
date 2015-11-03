# TODO: standard name (e.g. New-ScheduledTask)
function Create-ScheduledTask($options) {
    Import-Module PowerUpUtilities
    $arguments = Format-ExternalArguments @{
      '/TN'  = $options.name
      '/XML' = $options.xml
      '/TR'  = "$($options.path) $($options.arguments)"
      '/SC'  = $options.schedule
      '/D'   = $options.days
      '/ST'  = $options.time
      '/RU'  = $options.username
      '/RP'  = $options.password
      '/S'   = $options.server
    } -EscapeAll

    Invoke-External "schtasks /Create $arguments"
}

function Update-ScheduledTask ($options) {
    #Cannot use schtasks /change command as it doesn't let us change much
    Delete-ScheduledTask $($options.name)
    Create-ScheduledTask $options
}

function Delete-ScheduledTask ([Parameter(Mandatory=$true)] [string] $name) {
    # TODO: apply to all functions, then to the whole file
    Set-StrictMode -Version 2
    $ErrorActionPreference = 'Stop'

    Write-Host "Deleting scheduled task $name"
    Invoke-External "schtasks /Change /TN `"$name`" /DISABLE"
    Invoke-External "schtasks /Delete /TN `"$name`" /F"
}

function Disable-ScheduledTask([Parameter(Mandatory=$true)] [string] $name) {
    # TODO: apply to all functions, then to the whole file
    Set-StrictMode -Version 2
    $ErrorActionPreference = 'Stop'

    Import-Module PowerUpUtilities

    Write-Host "Disabling scheduled task $name"
    Invoke-External "schtasks /Change /TN `"$name`" /DISABLE"
}

function Enable-ScheduledTask([Parameter(Mandatory=$true)] [string] $name) {
    # TODO: apply to all functions, then to the whole file
    Set-StrictMode -Version 2
    $ErrorActionPreference = 'Stop'

    Import-Module PowerUpUtilities

    Write-Host "Enabling scheduled task $name"
    Invoke-External "schtasks /Change /TN `"$name`" /ENABLE"
}

function ScheduledTaskExists($name) {
    Write-Warning "ScheduledTaskExists is obsolete/has non-standard name, use Test-ScheduledTask instead."
    return Test-ScheduledTask $name
}

function Test-ScheduledTask([Parameter(Mandatory=$true)] [string] $name) {
    # TODO: apply to all functions, then to the whole file
    Set-StrictMode -Version 2
    $ErrorActionPreference = 'Stop'
    
    Import-Module PowerUpUtilities
    
    $allTasks = Invoke-External { schtasks /Query /fo csv /v } | ConvertFrom-Csv
    $task = $allTasks | ? { $_.TaskName -eq "\$name" }
    return ($task -ne $null)
}

function Enable-ScheduledTasksOfPath($path) {
    $tasks=Get-ScheduledTasksOfPath $path
    if ($tasks -ne $null) {
        $tasks | % {Enable-ScheduledTask $_.TaskName}
    }
    else {
        Write-Host "There are no scheduled tasks for '$path'."
    }
}

function Disable-ScheduledTasksOfPath($path) {
    $tasks=Get-ScheduledTasksOfPath $path
    if ($tasks -ne $null) {
        $tasks | % {Disable-ScheduledTask $_.TaskName}
    }
    else {
        Write-Host "There are no scheduled tasks for '$path'."
    }
}

function Get-ScheduledTasksOfPath($path) {
    $allTasks=schtasks /Query /fo csv /v | ConvertFrom-Csv
    $tasks=$allTasks | ? { $_."Task To Run" -like "$path*" }
    return $tasks
}

export-modulemember -function Create-ScheduledTask,
                               Enable-ScheduledTask,
                               Disable-ScheduledTask,
                               Enable-ScheduledTasksOfPath,
                               Disable-ScheduledTasksOfPath,
                               Update-ScheduledTask,
                               Test-ScheduledTask,
                               ScheduledTaskExists