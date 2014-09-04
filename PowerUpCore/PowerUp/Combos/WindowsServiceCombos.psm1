function Invoke-Combo-StandardWindowsService($options)
{
	import-module powerupfilesystem
	import-module powerupwindowsservice
				
	if (!$options.destinationfolder)
	{
		$options.destinationfolder = $options.servicename
	}

	if (!$options.sourcefolder)
	{
		$options.sourcefolder = $options.destinationfolder
	}
	
	if (!$options.fulldestinationpath)
	{
		$options.fulldestinationpath = "$($options.serviceroot)\$($options.destinationfolder)"
	}

	if (!$options.fullsourcepath)
	{
		$options.fullsourcepath = "$(get-location)\$($options.sourcefolder)"
	}
	
	if (!$options.exename)
	{
		$options.exename = "$($options.servicename).exe"
	}
		
	Uninstall-Service $options.servicename

	if($options.copywithoutmirror)
	{
		copy-directory $options.fullsourcepath $options.fulldestinationpath
	}
	else
	{
		copy-mirroreddirectory $options.fullsourcepath $options.fulldestinationpath
	}
	
	Install-Service $options.servicename (Join-Path $options.fulldestinationpath $options.exename)
	
	if ($options.serviceaccountusername)
	{
		Set-ServiceCredentials $options.servicename $options.serviceaccountusername $options.serviceaccountpassword
	}
	
	if ($options.failureoptionsrestartonfail)
	{
		if (!$options.failureoptionsresetfailurecountafterdays)
		{
			$options.failureoptionsresetfailurecountafterdays = 1
		}
		
		if (!$options.failureoptionsresetdelayminutes)
		{
			$options.failureoptionsresetdelayminutes = 1
		}
	
		Set-ServiceFailureOptions $options.servicename $options.failureoptionsresetfailurecountafterdays "restart" $options.failureoptionsresetdelayminutes
	}

    if ($options.donotstartimmediately)
    {
        return;
    }

    try
    {
        Start-Service $options.servicename
    }
    catch
    {
        Write-Error "Failed to start service $($options.servicename): $_" -ErrorAction Continue
        $logs = (Get-EventLog Application -Source $options.servicename -ErrorAction SilentlyContinue | Select-Object -First 5)
        if ($logs) {
            Write-Host "Recent Application event logs for $($options.servicename):"
            $logs | % {                
                Write-Host "$($_.TimeGenerated) $($_.EntryType)" -ForegroundColor DarkMagenta
                Write-Host $_.Message
                Write-Host ""
            }
        }
        throw
    }
}
