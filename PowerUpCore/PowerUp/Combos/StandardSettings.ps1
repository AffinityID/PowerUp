$profileSettings = @{};
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

	Import-Module $scriptPath\..\Modules\PowerUpSettings\Id.PowershellExtensions.dll
	
	if (!(test-path $fullFilePath))
	{
		return @()
	}
	Write-Host "Processing settings file at $fullFilePath with the following parameter: $parameter"
	get-parsedsettings $fullFilePath $parameter
}

function Import-PowerUpProfileSettings() {
    Import-Module PowerUpSettings

    $profileSettings = &$deploymentProfileSettingsScriptBlock ${deployment.profile}
    if (!$profileSettings)
    {
        $profileSettings = @{}
    }
    
    $packageInformation = getPlainTextSettings "PackageInformation" "package.id"
    if ($packageInformation)
    {
        foreach ($item in $packageInformation.GetEnumerator())
        {
            $profileSettings.Add($item.Key, $item.Value)
        }
    }
    
    Write-Host "Package settings for this profile are:"
    $profileSettings | Format-Table -property * | Out-String
    import-settings $profileSettings
}

tasksetup {
    Import-PowerUpProfileSettings
}

$deploymentProfileSettingsScriptBlock = $function:getPlainTextDeploymentProfileSettings
$serverSettingsScriptBlock = $function:getPlainTextServerSettings