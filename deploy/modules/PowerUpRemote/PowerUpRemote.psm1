
function invoke-remotetasks($tasks, $serverNames, $deploymentEnvironment, $packageName, $settingsFunction, $remoteexecutiontool=$null)
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
			invoke-remotetaskwithremoting $tasks $server $deploymentEnvironment $packageName
		}
		else
		{
			invoke-remotetaskwithpsexec $tasks $server $deploymentEnvironment $packageName
		}	
	}	
}


function invoke-remotetaskswithpsexec( $tasks, $serverNames, $deploymentEnvironment, $packageName)
{
	invoke-remotetasks $tasks $serverNames $deploymentEnvironment $packageName psexec
}

function invoke-remotetaskswithremoting( $tasks, $serverNames, $deploymentEnvironment, $packageName)
{
	invoke-remotetasks $tasks $serverNames $deploymentEnvironment $packageName psremoting
}


function invoke-remotetaskwithpsexec( $tasks, $server, $deploymentEnvironment, $packageName )
{
	$serverName = $server['server.name'][0]
	write-host "===== Beginning execution of tasks $tasks on server $serverName ====="

	$fullLocalReleaseWorkingFolder = $server['local.temp.working.folder'][0] + '\' + $packageName
	$batchFile = $fullLocalReleaseWorkingFolder + '\' + 'deploy.bat'

	if ($server.ContainsKey('username'))
	{
		cmd /c cscript.exe $PSScriptRoot\cmd.js $PSScriptRoot\psexec.exe \\$serverName /accepteula -u $server['username'][0] -p $server['password'][0] -w $fullLocalReleaseWorkingFolder $batchFile $deploymentEnvironment $tasks
	}
	else
	{
		cmd /c cscript.exe $PSScriptRoot\cmd.js $PSScriptRoot\psexec.exe \\$serverName /accepteula -w $fullLocalReleaseWorkingFolder $batchFile $deploymentEnvironment $tasks		
	}
		
	write-host "====== Finished execution of tasks $tasks on server $serverName ====="

	if ($lastexitcode -ne 0)
	{
		throw "Remotely executed task(s) failed with return code $lastexitcode"
	}
	
}

function invoke-remotetaskwithremoting( $tasks, $server, $deploymentEnvironment, $packageName )
{	
	$serverName = $server['server.name'][0]
	write-host "===== Beginning execution of tasks $tasks on server $serverName ====="

	$fullLocalReleaseWorkingFolder = $server['local.temp.working.folder'][0] + '\' + $packageName

	$command = ".$psakeFile -buildFile $deployFile -deploymentEnvironment $deploymentEnvironment -tasks $tasks"		
	Invoke-Command -scriptblock { param($workingFolder, $env, $tasks) set-location $workingFolder; .\_powerup\deploy\core\deploy_with_psake.ps1 -buildFile .\deploy.ps1 -deploymentEnvironment $env -tasks $tasks } -computername $serverName -ArgumentList $fullLocalReleaseWorkingFolder, $deploymentEnvironment, $tasks 
	
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
				
export-modulemember -function invoke-remotetasks, invoke-remotetaskswithpsexec, invoke-remotetaskswithremoting, enable-psremotingforpowerup