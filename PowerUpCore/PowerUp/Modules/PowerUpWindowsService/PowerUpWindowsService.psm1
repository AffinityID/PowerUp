Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Set-ServiceCredentials(
    [Parameter(Mandatory=$true)] [string] $name,
    [Parameter(Mandatory=$true)] [Management.Automation.PSCredential] $credentials
)
{
    $username = $credentials.UserName
    if (!$username.Contains("\")) {
        $username = "$env:COMPUTERNAME\$\username"
    }

    $service = Get-WmiObject Win32_Service -Filter "name='$name'"
    if (!$service) {
        throw "Service '$name' was not found."
    }

    Write-Output "Setting credentials for service '$Name' to '$username'"
    $params = $service.PSBase.GetMethodParameters("Change")
    $params["StartName"] = $username
    $params["StartPassword"] = $credentials.GetNetworkCredential().Password

    $service.InvokeMethod("Change", $params, $null) | Out-Null
}

function Set-ServiceStartMode(
    [Parameter(Mandatory=$true)] [string] $name,
    [Parameter(Mandatory=$true)] [System.ServiceProcess.ServiceStartMode] $mode
)
{
    $service = Get-WmiObject Win32_Service -Filter "name='$name'"
    if (!$service) {
        throw "Service '$name' was not found."
    }

    Write-Output "Setting start mode for service '$Name' to '$mode'"
    $params = $service.PSBase.GetMethodParameters("Change")
    $params["StartMode"] = $mode.ToString()

    $service.InvokeMethod("Change", $params, $null) | Out-Null
}

Add-Type -TypeDefinition "public enum ServiceFailureAction { Restart, Reboot }"
function Set-ServiceFailureOptions
{
	param
	(
		[Parameter(Mandatory=$true)] [string] $name,
		[int] $resetSeconds,
		[ServiceFailureAction] $firstFailureAction,
		[int] $firstFailureDelaySeconds,
		[ServiceFailureAction] $secondFailureAction,
		[int] $secondFailureDelaySeconds,
		[ServiceFailureAction] $subsequentFailureAction,
		[int] $subsequentFailureDelaySeconds
	)
	
	Import-Module PowerUpUtilities
	
	$actionSegmentOne=GetActionSegment $firstFailureAction $firstFailureDelaySeconds
	$actionSegmentTwo=GetActionSegment $secondFailureAction $secondFailureDelaySeconds
	$actionSegmentThree=GetActionSegment $subsequentFailureAction $subsequentFailureDelaySeconds

	$actions = "$actionSegmentOne/$actionSegmentTwo/$actionSegmentThree"
	write-host "Setting service failure options for service $name to reset after $resetSeconds seconds, and the actions are $actions"
	Invoke-External "sc.exe failure $name reset= $resetSeconds actions= $actions"
}

function GetActionSegment
{
	param
	(
		[ServiceFailureAction] $action,
		[int] $failureDelaySeconds
	)
	#We do not support action: run at the moment 
	$validActions = @('restart','reboot')
	$actionSegment="/"
	if (!$action){
		return $actionSegment
	}

	if ($failureDelaySeconds -eq 0){
		throw "Please provide the failure action delay time in seconds"
	}
	$failureDelayMilliseconds=$($failureDelaySeconds*1000)
	$actionSegment="$action/$failureDelayMilliseconds"
	return $actionSegment
}

function Get-SpecificService
{
	param
    (
        [string] $Name = $(throw 'Must provide a service name')
    )

	Write-Warning "Get-SpecificService is obsolete, use Get-MaybeNonExistingService instead."
	return Get-Service | Where-Object {$_.Name -eq $Name}
}

# TODO: Better name?
function Get-MaybeNonExistingService([Parameter(Mandatory=$true)][string] $name)
{
    # http://stackoverflow.com/questions/4967496/check-if-a-windows-service-exists-and-delete-in-powershell#17177020
    return Get-Service "$name*" -Include $name
}

# TODO: Better name?
function Stop-MaybeNonExistingService([Parameter(Mandatory=$true)][string] $name)
{
    $serviceExists =  Get-MaybeNonExistingService $name
    if ($serviceExists)
    {
        Write-Host "Service $name exists, stopping."
        Stop-Service $name
    }
    else
    {
        Write-Host "Service $name does not exist, so it cannot be stopped."
    }
}

# TODO: Do we actually need to start non-existing services?
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

function Uninstall-Service([Parameter(Mandatory=$true)][string]$name)
{
    $service = Get-WmiObject -Query "select * from Win32_Service where Name='$name'"
    if ($service)
    {
        Write-Host "Service $name is installed, starting uninstall:"

        Write-Host "  1. Ensuring service is stopped."
        Stop-Service $name

        Write-Host "  2. Killing any open 'Services' windows to free service handles."
        taskkill /fi "windowtitle eq Services"

        Write-Host "  3. Uninstalling service $name."
        &"$PSScriptRoot\InstallUtil.exe" $service.pathname /u /LogToConsole=true
    }
    else
    {
        Write-Host "Service $name is not installed, uninstall is not needed."
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

    Write-Warning "Set-Service is obsolete, use Install-Service instead."
    Install-Service $Name "$InstallPath\$ExeFileName"
}

function Install-Service(
    [Parameter(Mandatory=$true)][string]$name,
    [Parameter(Mandatory=$true)][string]$path
) {
    Uninstall-Service $name
    &"$PSScriptRoot\InstallUtil.exe" $path /LogToConsole=true
}