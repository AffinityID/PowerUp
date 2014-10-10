Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot\Id.PowershellExtensions.dll" -Global

function import-settings($settings) 
{
    foreach($key in $settings.keys)
    {
		$value = $settings.$key
		if ($value.length -eq 1)
		{
			set-variable -name $key -value $settings.$key[0] -scope global
		}
		else
		{
			set-variable -name $key -value $settings.$key -scope global		
		}
    }	
}

function Test-Setting([Parameter(Mandatory=$true)] [string] $setting, [switch] [boolean] $isTrue = $false) {
    if (-not (Test-Path variable:$setting)) {
        return $false
    }

    $value = (Get-Variable -Name $setting).Value
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $false;
    }
    
    if ($isTrue) {
        return [System.Boolean]::Parse($value)
    }
    
    return $true
}

Export-ModuleMember -function import-settings, Test-Setting