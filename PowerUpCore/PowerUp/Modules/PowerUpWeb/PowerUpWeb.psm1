$iisPath = "IIS:\"
$sitesPath = "IIS:\sites"
$appPoolsPath = "IIS:\apppools"
$bindingsPath = "IIS:\sslbindings"

function StopAppPoolAndSite($appPoolName, $siteName)
{
	StopAppPool($appPoolName)
	StopSite($siteName)
}

function StartAppPoolAndSite($appPoolName, $siteName)
{
	StartSite($siteName)
	StartAppPool($appPoolName)
}

function StopSite($siteName)
{	
	StopWebItem $sitesPath $siteName
}

function StopAppPool($appPoolName)
{	
	StopWebItem $appPoolsPath $appPoolName
}

function StartSite($siteName)
{	
	StartWebItem $sitesPath $siteName
}

function StartAppPool($appPoolName)
{	
	StartWebItem $appPoolsPath $appPoolName
}

function CreateAppPool($appPoolName)
{	
	if (!(WebItemExists $appPoolsPath $appPoolName))
	{
		New-WebAppPool $appPoolName
	}
}

function DeleteAppPool($appPoolName)
{	
	if (WebItemExists $appPoolsPath $appPoolName)
	{
		Remove-WebAppPool $appPoolName
	}
}

function DeleteWebsite($websiteName)
{	
	if (WebsiteExists $websiteName)
	{
		Remove-WebSite $websiteName
	}
}

function WebsiteExists($websiteName)
{	
	return WebItemExists $sitesPath $websiteName
}

function SetAppPoolManagedPipelineMode($appPool, $pipelineMode)
{
	$appPool.managedPipelineMode = $pipelineMode
}

function SetAppPoolManagedRuntimeVersion($appPool, $runtimeVersion)
{
	$appPool.managedRuntimeVersion = $runtimeVersion
}

function CreateWebsite($websiteName, $appPoolName, $fullPath, $protocol, $ip, $port, $hostHeader)
{		
	New-Item $sitesPath\$websiteName -physicalPath $fullPath -applicationPool $appPoolName -bindings @{protocol="http";bindingInformation="${ip}:${port}:${hostHeader}"}
}

function Set-WebsiteForSsl($useSelfSignedCert, $websiteName, $certificateName, $ipAddress, $port, $url)
{
	if ([System.Convert]::ToBoolean($useSelfSignedCert))
	{
		write-host "set-selfsignedsslcertificate ${certificateName}"
		set-selfsignedsslcertificate ${certificateName}
	}
		
	set-sslbinding $certificateName $ipAddress $port
	set-websitebinding $websiteName $url "https" $ipAddress $port 
}



function GetSslCertificate($certName)
{
	if ($certName.StartsWith("*")) {
		#escape the leading asterisk which breaks the regex below (-match ....)
		$certName = "\" + $certName
	}
	Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -match "${certName}"} | Select-Object -First 1
}


function SslBindingExists($ip, $port)
{
	return ((dir IIS:\sslbindings | Where-Object {($_.Port -eq $port) -and ($_.IPAddress -contains $ip)}) | measure-object).Count -gt 0
}

function CreateSslBinding($certificate, $ip, $port)
{
	$existingPath = get-location
	set-location $bindingsPath
	
	$certificate | new-item "${ip}!${port}"
	set-location $existingPath
}


function StopWebItem($itemPath, $itemName)
{
	if (WebItemExists $itemPath $itemName)
	{
		$state = (Get-WebItemState $itemPath\$itemName).Value
		if ($state -eq "started")
		{
			Stop-WebItem $itemPath\$itemName
		}
	}
}

function set-webapppool32bitcompatibility($appPoolName)
{
	$appPool = Get-Item $appPoolsPath\$appPoolName
	$appPool.enable32BitAppOnWin64 = "true"
	$appPool | set-item
}

function SetAppPoolProperties($appPoolName, $pipelineMode, $runtimeVersion)
{
	$appPool = Get-Item $appPoolsPath\$appPoolName
	SetAppPoolManagedPipelineMode $appPool $pipelineMode
	SetAppPoolManagedRuntimeVersion $appPool $runtimeVersion
	$appPool | set-item
}
 

function StartWebItem($itemPath, $itemName)
{
	if (WebItemExists $itemPath $itemName)
	{
		$state = (Get-WebItemState $itemPath\$itemName).Value
		if ($state -eq "stopped")
		{
			Start-WebItem $itemPath\$itemName
		}
	}
}

function WebItemExists($rootPath, $itemName)
{
	return ((dir $rootPath | ForEach-Object {$_.Name}) -contains $itemName)	
}


$ModuleName = "WebAdministration"
$ModuleLoaded = $false
$LoadAsSnapin = $false

if ($PSVersionTable.PSVersion.Major -ge 2)
{
    if ((Get-Module -ListAvailable | ForEach-Object {$_.Name}) -contains $ModuleName)
    {
        Import-Module $ModuleName
        if ((Get-Module | ForEach-Object {$_.Name}) -contains $ModuleName)
        {
            $ModuleLoaded = $true
        }
        else
        {
            $LoadAsSnapin = $true
        }
    }
    elseif ((Get-Module | ForEach-Object {$_.Name}) -contains $ModuleName)
    {
        $ModuleLoaded = $true
    }
    else
    {
        $LoadAsSnapin = $true
    }
}
else
{
    $LoadAsSnapin = $true
}

if ($LoadAsSnapin)
{
    if ((Get-PSSnapin -Registered | ForEach-Object {$_.Name}) -contains $ModuleName)
    {
        Add-PSSnapin $ModuleName
        if ((Get-PSSnapin | ForEach-Object {$_.Name}) -contains $ModuleName)
        {
            $ModuleLoaded = $true
        }
    }
    elseif ((Get-PSSnapin | ForEach-Object {$_.Name}) -contains $ModuleName)
    {
        $ModuleLoaded = $true
    }
}

function Uninstall-WebAppPool($appPoolName)
{
	write-host "Removing apppool $appPoolName"
	DeleteAppPool $appPoolName
}

function set-WebAppPool($appPoolName, $pipelineMode, $runtimeVersion)
{
	write-host "Recreating apppool $appPoolName with pipeline mode $pipelineMode and .Net version $runtimeVersion"
	DeleteAppPool $appPoolName
	CreateAppPool $appPoolName
	SetAppPoolProperties $appPoolName $pipelineMode $runtimeVersion
}

function Uninstall-WebSite($websiteName)
{
	write-host "Removing website $websiteName"
	DeleteWebsite $websiteName
}

function set-WebSite($websiteName, $appPoolName, $fullPath, $hostHeader, $protocol="http", $ip="*", $port="80", $skipIfExists = $false)
{
    if (WebsiteExists $websiteName)
    {
        if ($skipIfExists)
        {
            write-host "Website $websiteName already exists, skipping."
            return;
        }	
        else
        {
            DeleteWebsite $websiteName
        }
    }	
	
    write-host "Recreating website $websiteName with path $fullPath, app pool $apppoolname, bound to to host header $hostHeader with IP $ip, port $port over $protocol"
    CreateWebsite $websiteName $appPoolName $fullPath $protocol $ip $port $hostHeader
}

function set-SelfSignedSslCertificate($certName)
{	
	write-host "Ensuring existance of self signed ssl certificate $certName"
	if(!(GetSslCertificate $certName))
	{
		write-host "Creating self signed ssl certificate $certName"
		& "$PSScriptRoot\makecert.exe" -r -pe -n "CN=${certName}" -b 07/01/2008 -e 07/01/2020 -eku 1.3.6.1.5.5.7.3.1 -ss my -sr localMachine -sky exchange -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12
	}
}
function EnsureSelfSignedSslCertificate($certName)
{	
	if(!(GetSslCertificate $certName))
	{
		& "$PSScriptRoot\makecert" -r -pe -n "CN=${certName}" -b 07/01/2008 -e 07/01/2020 -eku 1.3.6.1.5.5.7.3.1 -ss my -sr localMachine -sky exchange -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12
	}
}

function Set-WebSiteBinding($websiteName, $hostHeader, $protocol="http", $ip="*", $port="80")
{
    if ($hostHeader -eq "" -or $hostHeader -eq "*") {
        #temporary special case to handle bindings with blank host header.
        try {
            new-websitebinding $websiteName $hostHeader $protocol $ip $port 
        } catch {
            $_
        }
    } else {
        $existingBinding = get-webbinding -Name $websiteName -IP $ip -Port $port -Protocol $protocol -HostHeader $hostHeader    
        
        if(!$existingBinding) {
            new-websitebinding $websiteName $hostHeader $protocol $ip $port 
        }        
    }
    
}

function New-WebSiteBinding($websiteName, $hostHeader, $protocol="http", $ip="*", $port="80")
{
	write-host "Binding website $websiteName to host header $hostHeader with IP $ip, port $port over $protocol"
	New-WebBinding -Name $websiteName -IP $ip -Port $port -Protocol $protocol -HostHeader $hostHeader
}

function New-WebSiteBindingNonHttp($websiteName, $protocol, $bindingInformation)
{
	echo "Binding website $websiteName to binding information $bindingInformation over $protocol"
	New-ItemProperty $sitesPath\$websiteName –name bindings –value @{protocol="$protocol";bindingInformation="$bindingInformation"}
}

function Set-SslBinding($certName, $ip, $port)
{
	write-host "Binding certifcate $certName to IP $ip, port $port"
	$certificate = GetSslCertificate $certName
	
	if (!$certificate) {throw "Certificate for site $certName not in current store"}

	if($ip -eq "*") {$ip = "0.0.0.0"}
	
	if(!(SslBindingExists $ip $port))
	{
		CreateSslBinding $certificate $ip $port
	}
}

function Register-VirtualDirectory($websiteName, $subPath, $physicalPath)
{
    $virtualPath = "$sitesPath\$websiteName\$subPath"
    if (Test-Path $virtualPath) {
        Remove-Item $virtualPath -Recurse
    }    
    
    Write-Host "Adding virtual directory $subPath to web site $websiteName pointing to $physicalPath"
    New-Item $virtualPath -physicalPath $physicalPath -type VirtualDirectory 
}

function new-virtualdirectory($websiteName, $subPath, $physicalPath)
{
    Write-Warning "Command new-virtualdirectory is obsolete, use Register-VirtualDirectory instead."
	write-host "Adding virtual directory $subPath to web site $websiteName pointing to $physicalPath"
	New-Item $sitesPath\$websiteName\$subPath -physicalPath $physicalPath -type VirtualDirectory 
}

function new-webapplication($websiteName, $appPoolName, $subPath, $physicalPath)
{
	write-host "Adding application $subPath to web site $websiteName pointing to $physicalPath running under app pool  $appPoolName"
	New-Item $sitesPath\$websiteName\$subPath -physicalPath $physicalPath -applicationPool $appPoolName -type Application 
}

function Stop-AppPool($appPoolName)
{
	write-host "Stopping app pool $appPoolName"
	StopAppPool($appPoolName)	
}

function Stop-AppPoolAndSite($appPoolName, $siteName)
{
	write-host "Stopping app pool $appPoolName and site $siteName"
	StopAppPool($appPoolName)
	StopSite($siteName)
}

function Start-AppPool($appPoolNamee)
{
	write-host "Starting app pool $appPoolName"
	StartSite($siteName)
}

function Start-AppPoolAndSite($appPoolName, $siteName)
{
	write-host "Starting app pool $appPoolName and site $siteName"
	StartSite($siteName)
	StartAppPool($appPoolName)
}

function set-apppoolidentitytouser($appPoolName, $userName, $password)
{
	write-host "Setting $appPoolName to be run under the identity $userName"
	$appPool = Get-Item $appPoolsPath\$appPoolName
	$appPool.processModel.username =  $userName
	$appPool.processModel.password = $password
	$appPool.processModel.identityType = 3
	$appPool | set-item
}

function set-apppoolidentityType($appPoolName, [int]$identityType)
{
	echo "Setting $appPoolName to be run under the identityType $identityType"
	$appPool = Get-Item $appPoolsPath\$appPoolName
	$appPool.processModel.identityType = $identityType
	$appPool | set-item
}

function set-apppoolstartMode($appPoolName, [int]$startMode)
{
	echo "Setting $appPoolName to be run with startMode $startMode"
	$appPool = Get-Item $appPoolsPath\$appPoolName
	$appPool.startMode = $startMode
	$appPool | set-item
}

function set-property($applicationPath, $propertyName, $value)
{
	Set-ItemProperty $sitesPath\$applicationPath -name $propertyName -value $value
}

function set-webproperty($websiteName, $propertyPath, $property, $value)
{
	Set-WebConfigurationProperty -filter $propertyPath -name $property -value $value -location $websiteName
}

function Begin-WebChangeTransaction()
{
	return Begin-WebCommitDelay
}

function End-WebChangeTransaction()
{
	return End-WebCommitDelay
}

function Try-WebRequest([string]$url)
{
  function FullStatusCode($response) {
    return "$([int]$response.StatusCode) $($response.StatusDescription)";
  }

  write-host "Requesting '$($url)'" -nonewline
  $request = [system.Net.WebRequest]::Create($url)
  $request.Timeout = 10 * 60 * 1000 # 10 minutes
  try {
    $response = $request.GetResponse()
  }
  catch [System.Net.WebException] {
    $response = $_.Exception.Response
    if ($response -eq $null) {
      throw;
    }
    
    $stream = $response.GetResponseStream()
    $reader = new-object System.IO.StreamReader($stream)
    $error = $reader.ReadToEnd();
    
    write-host ": $(FullStatusCode($response))"
    throw "Request to $url failed ($(FullStatusCode($response))): $error"
  }
  finally {
    if ($response -ne $null) {
      $response.Close();
    }
  }
   
  write-host ": $(FullStatusCode($response))" -foregroundcolor green
}

export-modulemember -function set-webapppool32bitcompatibility,
                               set-apppoolidentitytouser,
                               set-apppoolidentityType,
                               set-apppoolstartMode,
                               new-webapplication,
                               new-virtualdirectory,
                               Register-VirtualDirectory,
                               start-apppoolandsite,
                               start-apppool,
                               start-site,
                               stop-apppool,
                               stop-apppoolandsite,
                               set-website,
                               uninstall-website,
                               set-webapppool,
                               uninstall-webapppool,
                               set-websitebinding,
                               New-WebSiteBinding,
                               New-WebSiteBindingNonHttp,
                               set-SelfSignedSslCertificate,
                               set-sslbinding,
                               Set-WebsiteForSsl,
                               set-property,
                               set-webproperty,
                               Begin-WebChangeTransaction,
                               End-WebChangeTransaction,
                               Try-WebRequest