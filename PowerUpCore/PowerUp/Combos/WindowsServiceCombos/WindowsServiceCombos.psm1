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
	
	if ($options.failureoptions.enablerecovery)
	{
		if (!$options.failureoptions.resetfailurecountafterseconds)
		{
			$options.failureoptions.resetfailurecountafterseconds = 86400
		}
		
		if (!$options.failureoptions.firstactiondelayseconds)
		{
			$options.failureoptions.firstactiondelayseconds = 0
		}

		if (!$options.failureoptions.secondactiondelayseconds)
		{
			$options.failureoptions.secondactiondelayseconds = 0
		}
		
		if (!$options.failureoptions.subsequentactiondelayseconds)
		{
			$options.failureoptions.subsequentactiondelayseconds = 0
		}
		Set-ServiceFailureOptions $options.servicename $options.failureoptions.resetfailurecountafterseconds $options.failureoptions.firstaction $options.failureoptions.firstactiondelayseconds $options.failureoptions.secondaction $options.failureoptions.secondactiondelayseconds $options.failureoptions.subsequentaction $options.failureoptions.subsequentactiondelayseconds
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
