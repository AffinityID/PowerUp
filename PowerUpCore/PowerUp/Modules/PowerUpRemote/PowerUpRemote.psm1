
function invoke-remotetasks(
    [Parameter(Mandatory = $true)][string] $operation,
    $tasks, $serverNames, $profile, $packageName, $settingsFunction, $remoteexecutiontool=$null
)
{
	$currentLocation = get-location
	$servers = get-serversettings $settingsFunction $serverNames

	copy-package $servers $packageName
	
	foreach ($server in $servers)
	{
		if (!$remoteexecutiontool)
		{
			if ($server.ContainsKey('remote.task.execution.remoteexecutiontool'))
			{
				$remoteexecutiontool = $server['remote.task.execution.remoteexecutiontool'][0]
				$remoteexecutiontool = 'psexec'
			}
		}

		if ($remoteexecutiontool -eq 'psremoting')
		{
			invoke-remotetaskwithremoting $operation $tasks $server $profile $packageName
		}
		else
		{
			invoke-remotetaskwithpsexec $operation $tasks $server $profile $packageName
		}
	}
}


function invoke-remotetaskswithpsexec(
    [Parameter(Mandatory = $true)][string] $operation,
    $tasks, $serverNames, $profile, $packageName
)
{
	invoke-remotetasks $operation $tasks $serverNames $profile $packageName psexec
}

function invoke-remotetaskswithremoting(
    [Parameter(Mandatory = $true)][string] $operation,
    $tasks, $serverNames, $profile, $packageName
)
{
	invoke-remotetasks $operation $tasks $serverNames $profile $packageName psremoting
}

# TODO: Convert to Invoke-RemoteCommandWithPSExec to support any kind of command
function invoke-remotetaskwithpsexec(
    [Parameter(Mandatory = $true)][string] $operation,
    $tasks, $server, $profile, $packageName
)
{
    $serverName = $server['server.name'][0]
    $username = $null
    $password = $null
    if ($server.ContainsKey('username')) {
        $username = $server['username'][0]
        $password = $server['password'][0]
    }
    
    $fullLocalReleaseWorkingFolder = $server['local.temp.working.folder'][0] + '\' + $packageName
    Invoke-TaskWithPSExec `
        -RootFolder $fullLocalReleaseWorkingFolder `
        -Operation $operation `
        -Profile $profile `
        -Tasks $tasks `
        -Server $serverName `
        -Username $username `
        -Password $password
}

function Invoke-TaskWithPSExec(
    [Parameter(Mandatory = $true)][string] $operation,
    [string] $rootFolder,
    [string] $profile,
    [string] $tasks,
    [string] $server,
    [string] $username,
    [string] $password,
    [switch] $doNotLoadUserProfile
) {
    # TODO: Move to the module level
    Set-StrictMode -Version 2
    $ErrorActionPreference = 'Stop'

    Import-Module PowerUpUtilities
    
    $serverForLog = [string]$(if($server) { $server } else { 'local' })
    Write-Host "===== Beginning execution of tasks $tasks on $serverForLog ====="  -ForegroundColor White
    $batchFile = $rootFolder + '\_powerup\Run.bat'

    $psExecArguments = Format-ExternalArguments @{
        '/accepteula' = [switch]$true
        '-w' = $rootFolder
        '-u' = $username
        '-p' = $password
        '-e' = $doNotLoadUserProfile
    } -EscapeAll
    if ($server) {
        $psExecArguments = "\\$server $psExecArguments"
    }
    $psExecArguments += " $batchFile"
    
    # TODO: consolidate with PowerUpMeta
    $runArguments = Format-ExternalArguments @{
        '-Operation' = $operation
        '-OperationProfile' = $profile
        '-Task' = $tasks
    } -EscapeAll
    $psExecArguments += " $runArguments"
    
    # TODO: Invoke-External (currently fails with an escaping issue)
    Invoke-External "cmd /c cscript.exe $PSScriptRoot\cmd.js $PSScriptRoot\psexec.exe $psExecArguments"
    
    if ($LastExitCode -ne 0) {
        throw "Remotely executed task(s) failed with return code $LastExitCode"
    }
        
    Write-Host "====== Finished execution of tasks $tasks on $serverForLog ====="  -ForegroundColor White
}

function invoke-remotetaskwithremoting(
    [Parameter(Mandatory = $true)][string] $operation,
    $tasks, $server, $profile, $packageName
)
{	
	$serverName = $server['server.name'][0]
	write-host "===== Beginning execution of tasks $tasks on server $serverName ====="

	$fullLocalReleaseWorkingFolder = $server['local.temp.working.folder'][0] + '\' + $packageName

	Invoke-Command -scriptblock { param($workingFolder, $op, $prof, $tasks) set-location $workingFolder; .\_powerup\RunPSake.ps1 -Operation $op -OperationProfile $prof -Task $tasks } -computername $serverName -ArgumentList $fullLocalReleaseWorkingFolder, $operation, $profile, $tasks 
	
	write-host "========= Finished execution of tasks $tasks on server $serverName ====="
}

function copy-package($servers, $packageName)
{		
	import-module powerupfilesystem

	foreach ($server in $servers)
	{	
		$remoteDir = $server['remote.temp.working.folder'][0]
		$serverName = $server['server.name'][0]
		
		if(!$remoteDir)
		{
			throw "Setting remote.temp.working.folder not set for server $serverName"
		}
			
		$remotePath = $remoteDir + '\' + $packageName
		$currentLocation = get-location

		$packageCopyRequired = $false
				
		if ((!(Test-Path $remotePath\package.id) -or !(Test-Path $currentLocation\package.id)))
		{		
			$packageCopyRequired = $true
		}
		else
		{
			$packageCopyRequired = !((Get-Item $remotePath\package.id).LastWriteTime -eq (Get-Item $currentLocation\package.id).LastWriteTime)
		}
		
		if ($packageCopyRequired)
		{	
			write-host "Copying deployment package to $remotePath"
			Copy-MirroredDirectory $currentLocation $remotePath
		}
	}
}	

function get-serverSettings($settingsFunction, $serverNames)
{	
		
	$servers = @()
	
	foreach($serverName in $serverNames)
	{
		$serverSettings = &$settingsFunction $serverName		
		$servers += $serverSettings
	}
	
	$servers
}

function enable-psremotingforpowerup
{
	$nlm = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"))
	$connections = $nlm.getnetworkconnections()
	
	$connections |foreach {
		if ($_.getnetwork().getcategory() -eq 0)
		{
			$_.getnetwork().setcategory(1)
		}
	}

	Enable-PSRemoting -Force 

	$currentPath = get-location
	Copy-Item $currentPath\_powerup\deploy\core\powershell.exe.config -destination C:\Windows\System32\wsmprovhost.exe.config -force
}
				
Export-ModuleMember -function invoke-remotetasks,
                               Invoke-TaskWithPSExec,
                               invoke-remotetaskswithpsexec,
                               invoke-remotetaskswithremoting,
                               enable-psremotingforpowerup