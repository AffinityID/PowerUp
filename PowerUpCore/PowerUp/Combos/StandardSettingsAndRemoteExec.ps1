$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition

function getPlainTextServerSettings($serverName)
{
	getPlainTextSettings $serverName servers.txt
}

function getPlainTextDeploymentProfileSettings($deploymentProfile)
{
	getPlainTextSettings $deploymentProfile settings.txt
}

function getPlainTextSettings($parameter, $fileName)
{
	$currentPath = Get-Location
	$fullFilePath = "$currentPath\$fileName"

	Import-Module $scriptPath\..\Modules\PowerUpTemplates\Id.PowershellExtensions.dll
	
	if (!(test-path $fullFilePath))
	{
		return @()
	}
	Write-Host "Processing settings file at $fullFilePath with the following parameter: $parameter"
	get-parsedsettings $fullFilePath $parameter
}

function run($operation, $task, $servers, $remoteWorkingSubFolder = $null)
{
	import-module powerupremote	
	$currentPath = Get-Location
	
	if ($remoteWorkingSubFolder -eq $null)
	{
		$remoteWorkingSubFolder = ${package.name}
	}
	
	invoke-remotetasks $operation $task $servers ${deployment.profile} $remoteWorkingSubFolder $serverSettingsScriptBlock
}


task default -depends preprocesspackage, deploy 

task preprocesspackage {
	& $processTemplatesScriptBlock
}

tasksetup {
	copyDeploymentProfileSpecificFiles
	mergePackageInformation
	mergeSettings
}

function mergePackageInformation()
{
	import-module powerupsettings
	$packageInformation = getPlainTextSettings "PackageInformation" "package.id"
	
	if ($packageInformation)
	{
		import-settings $packageInformation
	}
}

function copyDeploymentProfileSpecificFiles()
{
	import-module poweruptemplates
	Merge-ProfileSpecificFiles ${deployment.profile}
}

function mergeSettings()
{
	import-module powerupsettings

	$deploymentProfileSettings = &$deploymentProfileSettingsScriptBlock ${deployment.profile}

	if ($deploymentProfileSettings)
	{
		import-settings $deploymentProfileSettings
	}
}

function processTemplates()
{
	import-module powerupsettings
	import-module poweruptemplates

	
	#This is the second time we are reading the settings file. Should probably be using the settings from the merge process.
	$deploymentProfileSettings = &$deploymentProfileSettingsScriptBlock ${deployment.profile}
	$packageInformation = getPlainTextSettings "PackageInformation" "package.id"
	
	if (!$deploymentProfileSettings)
	{
		$deploymentProfileSettings = @{}
	}
	
	if ($packageInformation)
	{	
		foreach ($item in $packageInformation.GetEnumerator())
		{
			$deploymentProfileSettings.Add($item.Key, $item.Value)
		}
	}

	Write-Host "Package settings for this profile are:"
	$deploymentProfileSettings | Format-Table -property *

	Write-Host "Substituting and copying templated files"
	merge-templates $deploymentProfileSettings ${deployment.profile}
	
}

$deploymentProfileSettingsScriptBlock = $function:getPlainTextDeploymentProfileSettings
$serverSettingsScriptBlock = $function:getPlainTextServerSettings
$processTemplatesScriptBlock = $function:processTemplates

