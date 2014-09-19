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

function Test-Setting($setting) {
    if (-not (Test-Path variable:$setting)) {
        return $false
    }

    $var = Get-Variable -Name $setting
    if ([string]::IsNullOrWhiteSpace($var.Value)) {
        return $false;
    }
    
    return $true
}

Export-ModuleMember -function import-settings, Test-Setting