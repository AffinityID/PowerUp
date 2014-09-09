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

Export-ModuleMember -function import-settings