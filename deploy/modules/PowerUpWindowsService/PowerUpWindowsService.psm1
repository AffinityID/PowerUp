function Set-ServiceCredentials
{
    param
    (
        [string] $Name = $(throw 'Must provide a service name'),
        [string] $Username = $(throw "Must provide a username"),
        [string] $Password = $(throw "Must provide a password")
    ) 
    
	if (!($Username.Contains("\")))
	{
        $Username = "$env:COMPUTERNAME\$Username"
    }
    
    $service = gwmi win32_service -filter "name='$Name'"
	if ($service -ne $null)
	{
        $params = $service.psbase.getMethodParameters("Change");
        $params["StartName"] = $Username
        $params["StartPassword"] = $Password
    
        $service.invokeMethod("Change", $params, $null)

		Write-Output "Credentials changed for service '$Name'"
	}
	else
	{
		throw "Could not find service '$Name' for which to change credentials"
	}
}

function Set-ServiceStartMode
{
    param
    (
        [string] $Name = $(throw 'Must provide a service name'),
        [string] $Mode = $(throw 'Must provide a new start mode')
    ) 
        
    $service = gwmi win32_service -filter "name='$Name'"
	if ($service -ne $null)
	{
        $params = $service.psbase.getMethodParameters("Change");
        $params["StartMode"] = $Mode
        $service.invokeMethod("Change", $params, $null)

		Write-Output "Start mode change to '$Mode' for service '$Name'"
	}
	else
	{
		throw "Could not find service '$Name' for which to change start mode"
	}
}


function Set-ServiceFailureOptions
{
    param
    (
        [string] $Name = $(throw 'Must provide a service name'),
        [int] $ResetDays,
        [string] $Action,
        [int] $DelayMinutes
    ) 
    	
	$ResetSeconds = $($ResetDays*60*60*24)
	$DelayMilliseconds = $($DelayMinutes*1000*60)
	$Action = "restart"
	$Actions = "$Action/$DelayMilliseconds/$Action/$DelayMilliseconds/$Action/$DelayMilliseconds"
		
	write-host "Setting service failure options for service $Name to reset after $ResetDays days, and $Action after $DelayMinutes minutes"
	
	& sc.exe failure $Name reset= $ResetSeconds actions= $Actions
}

function Get-SpecificService
{
	param
    (
        [string] $Name = $(throw 'Must provide a service name')
    )
	
	return Get-Service | Where-Object {$_.Name -eq $Name}
}
	
	
	
function Stop-MaybeNonExistingService
{
	param
    (
        [string] $Name = $(throw 'Must provide a service name')
    ) 

	$serviceExists = !((Get-Service | Where-Object {$_.Name -eq $Name}) -eq $null)
	
	if ($serviceExists) {
		Write-Host "$Name Service is installed"
		
		Write-Host "Stopping $Name"
		Stop-Service $Name		
	}
	else
	{
		Write-Host "$Name Service is not installed, so cannot be stopped"
	}

}

function Start-MaybeNonExistingService
{
	param
    (
        [string] $Name = $(throw 'Must provide a service name')
    ) 

	$serviceExists = !((Get-Service | Where-Object {$_.Name -eq $Name}) -eq $null)
	
	if ($serviceExists) {
		Write-Host "$Name Service is installed"
		
		Write-Host "Starting $Name"
		Start-Service $Name		
	}
	else
	{
		Write-Host "$Name Service is not installed, so cannot be started"
	}

}

function Uninstall-Service 
{
	param
	(
		[string] $Name = $(throw 'Must provide a service name')
	) 

	$service = get-wmiobject -query "select * from win32_service where name='$Name'"
		
	if ($service) {
		Write-Host "$Name Service is installed"
		
		Write-Host "Uninstalling $Name"

		try{
			& "$PSScriptRoot\InstallUtil.exe" $service.pathname /u /LogToConsole=true
		}
		catch{
			throw "Could not uninstall $Name Service"
		}		
	}
}

function Set-Service
{
	param
    (
        [string] $Name = $(throw 'Must provide a service name'),
		[string] $InstallPath = $(throw 'Must provide a service name'),
		[string] $ExeFileName = $(throw 'Must provide a service name')
    ) 

	uninstall-service $Name $InstallPath $ExeFileName
		
	try{
		& "$PSScriptRoot\InstallUtil.exe" "$InstallPath\$ExeFileName" /LogToConsole=true
	}
	catch{
		throw "Could not install $Name Service"
	}
	
}