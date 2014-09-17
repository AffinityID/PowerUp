Import-Module $PSScriptRoot\Id.PowershellExtensions.dll

function Expand-Templates($settingsFile, $deploymentProfile, $templatePath, $outputPath) {
	Write-Output "Reading settings"
	$settings = get-parsedsettings $settingsFile $deploymentProfile 
	
	Write-Output "Template settings for the $deploymentProfile environment are:"
	$settings | Format-Table -property *
	
	copy-substitutedsettingfiles -templatesDirectory $templatePath -targetDirectory $outputPath -deploymentEnvironment $deploymentProfile -settings $settings
}

function Merge-ProfileSpecificFiles($deploymentProfile) {
	$currentPath = Get-Location

	if ((Test-Path $currentPath\_profilefiles\$deploymentProfile -PathType Container) -eq $true)
	{
		Copy-Item $currentPath\_profilefiles\$deploymentProfile\* -destination $currentPath\ -recurse -force   
	}	
}


function Merge-Templates($settings, $deploymentProfile) {
	$currentPath = Get-Location
	
	if ((Test-Path $currentPath\_templates\ -PathType Container) -eq $false)
	{
		return
	}

	copy-substitutedsettingfiles -templatesDirectory $currentPath\_templates -targetDirectory $currentPath\_templatesoutput -deploymentEnvironment $deploymentProfile -settings $settings
	
	if ((Test-Path $currentPath\_templatesoutput\$deploymentProfile -PathType Container) -eq $true)
	{
		Copy-Item $currentPath\_templatesoutput\$deploymentProfile\* -destination $currentPath\ -recurse -force    
	}
}


Export-ModuleMember -function Expand-Templates, Merge-Templates, Merge-ProfileSpecificFiles