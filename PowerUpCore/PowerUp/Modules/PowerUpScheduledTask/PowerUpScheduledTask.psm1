function Create-ScheduledTask($options) {
	if ([string]::IsNullOrWhiteSpace($($options.xml))){
		if ([string]::IsNullOrWhiteSpace($($options.server))){
			Write-Host "schtasks /Create /TN `"$($options.name)`" /RU `"$($options.username)`" /RP `"$($options.password)`" /TR `"$($options.path) $($options.arguments)`" /SC `"$($options.schedule)`" /ST `"$($options.time)`" /D `"$($options.days)`" /NP"
			schtasks /Create /TN "$($options.name)" /RU "$($options.username)" /RP "$($options.password)" /TR "$($options.path) $($options.arguments)" /SC "$($options.schedule)" /ST "$($options.time)" /D "$($options.days)" /NP  
	    }
		else {
			Write-Host "schtasks /Create /TN `"$($options.name)`" /S `"$($options.server)`" /RU `"$($options.username)`" /RP `"$($options.password)`" /TR `"$($options.path) $($options.arguments)`" /SC `"$($options.schedule)`" /ST `"$($options.time)`" /D `"$($options.days)`" /NP"
			schtasks /Create /TN "$($options.name)" /S "$($options.server)" /RU "$($options.username)" /RP "$($options.password)" /TR "$($options.path) $($options.arguments)" /SC "$($options.schedule)" /ST "$($options.time)" /D "$($options.days)" /NP  
		}
	}
	else {
		Write-Host "schtasks /Create /TN `"$($options.name)`" /XML `"$($options.xml)`""
		schtasks /Create /TN "$($options.name)" /XML "$($options.xml)"
	}
}

function Update-ScheduledTask($options) {
	#Cannot use schtasks /change command as it doesn't let us change much
	Delete-ScheduledTask $($options.name)
	Create-ScheduledTask $options
}

function Delete-ScheduledTask($name){
    schtasks /Change /TN "$name" /DISABLE
    schtasks /Delete /TN "$name" /F
}

function Disable-ScheduledTask($name){
    schtasks /Change /TN "$name" /DISABLE
}

function Enable-ScheduledTask($name){
    schtasks /Change /TN "$name" /ENABLE
}

function ScheduledTaskExists($name){
    $allTasks=schtasks /Query /fo csv /v | ConvertFrom-Csv
    $task=$allTasks | ? {$_.TaskName -eq "\$name"}
    return ($task -ne $null)
}

function Enable-ScheduledTasksOfPath($path){
    $tasks=Get-ScheduledTasksOfPath $path
    if ($tasks -ne $null){
        $tasks | % {Enable-ScheduledTask $_.TaskName}
    }
    else{
        Write-Warning "There is no scheduled task of this path"
    }
}

function Disable-ScheduledTasksOfPath($path){
    $tasks=Get-ScheduledTasksOfPath $path
    if ($tasks -ne $null){
        $tasks | % {Disable-ScheduledTask $_.TaskName}
    }
    else{
        Write-Warning "There is no scheduled task of this path"
    }
}

function Get-ScheduledTasksOfPath($path){
 $allTasks=schtasks /Query /fo csv /v | ConvertFrom-Csv
 $tasks=$allTasks | ? {$_."Task To Run" -like "$path*"}
 return $tasks
}

export-modulemember -function Create-ScheduledTask,
                              Enable-ScheduledTasksOfPath,
                              Disable-ScheduledTasksOfPath,
							  Update-ScheduledTask,
                              ScheduledTaskExists


