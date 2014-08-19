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
	
	Set-Service $options.servicename $options.fulldestinationpath $options.exename
	
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
	
	if (!$options.donotstartimmediately)
	{
		start-service $options.servicename
	}
}
