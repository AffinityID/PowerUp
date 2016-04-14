$iisPath = "IIS:\"
$sitesPath = "IIS:\sites"
$appPoolsPath = "IIS:\apppools"

$ModuleName = "WebAdministration"
$ModuleLoaded = $false
$LoadAsSnapin = $false

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

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

function GetSslCertificate($certName)
{
	if ($certName.StartsWith("*")) {
		#escape the leading asterisk which breaks the regex below (-match ....)
		$certName = "\" + $certName
	}
	Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -match "${certName}"} | Select-Object -First 1
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

function StopWebItemInternal(
    [Parameter(Mandatory=$true)] [string] $itemType,
    [Parameter(Mandatory=$true)] [string] $itemPath,
    [Parameter(Mandatory=$true)] [string] $itemName
) {
    if (!(WebItemExists $itemPath $itemName)) {
        Write-Warning "$itemType '$itemName' was not found and cannot be stopped."
        return
    }
    StartOrStopExistingWebItemInternal $itemType $itemPath $itemName 'Stop' 'Stopping' 'Stopped'
}
 
function StartWebItemInternal(
    [Parameter(Mandatory=$true)] [string] $itemType,
    [Parameter(Mandatory=$true)] [string] $itemPath,
    [Parameter(Mandatory=$true)] [string] $itemName
) {
    if (!(WebItemExists $itemPath $itemName)) {
        throw "$itemType '$itemName' was not found and cannot be started."
        return;
    }
    StartOrStopExistingWebItemInternal $itemType $itemPath $itemName 'Start' 'Starting' 'Started'
}

function StartOrStopExistingWebItemInternal(
    [Parameter(Mandatory=$true)] [string] $itemType,
    [Parameter(Mandatory=$true)] [string] $itemPath,
    [Parameter(Mandatory=$true)] [string] $itemName,
    [Parameter(Mandatory=$true)] [string] $action,
    [Parameter(Mandatory=$true)] [string] $progressing,
    [Parameter(Mandatory=$true)] [string] $completed
) {
    Import-Module PowerUpUtilities
    $getState = { (Get-WebItemState $itemPath\$itemName).Value }

    $state = &$getState
    Wait-Until { 
        $state = &$getState
        return $state -ne 'Starting' -and $state -ne 'Stopping'
    } -BeforeFirstWait { 
        Write-Host "$itemType '$itemName' is $state`: waiting to complete."
    } -Timeout $(New-TimeSpan -Minutes 10)
    
    $state = &$getState
    if ($state -eq $completed) {
        Write-Host "$itemType '$itemName' is already $completed`: $action not required."
        return
    }
    
    Write-Host "$progressing $itemType '$itemName'."
    Invoke-Expression "$action-WebItem `"$itemPath\$itemName`""

    Wait-Until {
        $state = &$getState
        return $state -eq $completed
    } -BeforeFirstWait { 
        Write-Host "Waiting until $itemType '$itemName' is $completed."
    } -Timeout $(New-TimeSpan -Minutes 10)
}

function WebItemExists($rootPath, $itemName)
{
	return ((dir $rootPath | ForEach-Object {$_.Name}) -contains $itemName)	
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

function Register-WebAppPool(
    [Parameter(Mandatory=$true)] [string] $appPoolName,
    [Parameter(Mandatory=$true)] [string] $runtimeVersion
)
{
    Write-Host "Ensuring app pool $appPoolName with .NET version '$runtimeVersion'."
    CreateAppPool $appPoolName
    SetAppPoolProperties $appPoolName Integrated $runtimeVersion
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

    # http://forums.iis.net/t/1159761.aspx
    $id = (Get-ChildItem $sitesPath | % { $_.id } | sort -Descending | select -first 1) + 1
    
    write-host "Recreating website $websiteName with path $fullPath, app pool $apppoolname, bound to to host header $hostHeader with IP $ip, port $port over $protocol"
    New-Item $sitesPath\$websiteName -id $id -physicalPath $fullPath -applicationPool $appPoolName -bindings @{protocol=$protocol;bindingInformation="${ip}:${port}:${hostHeader}"}
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

function Set-WebSiteBinding($websiteName, $hostHeader, $protocol="http", $ip="*", $port="80", [switch] [boolean] $useSni = $false) {
    if ($hostHeader -eq "" -or $hostHeader -eq "*") {
        #temporary special case to handle bindings with blank host header.
        try {
            New-WebsiteBinding $websiteName $hostHeader $protocol $ip $port -UseSni:$useSni
        } catch {
            $_
        }
    }
    else {
        $existingBinding = Get-WebBinding -Name $websiteName -IP $ip -Port $port -Protocol $protocol -HostHeader $hostHeader
        if (!$existingBinding) {
            New-WebsiteBinding $websiteName $hostHeader $protocol $ip $port -UseSni:$useSni
        }
    }
    
}

function New-WebSiteBinding($websiteName, $hostHeader, $protocol="http", $ip="*", $port="80", [switch] [boolean] $useSni = $false) {
    $sslFlags = $(if ($useSni) { 1 } else { 0 })
    Write-Host "Binding website $websiteName to host header $hostHeader with IP $ip, port $port, flags $sslFlags over $protocol"
    if ($sslFlags -gt 0) {
        New-WebBinding -Name $websiteName -IP $ip -Port $port -Protocol $protocol -HostHeader $hostHeader -SslFlags $sslFlags
    }
    else {
        # Some older versions do not support -SslFlags argument at all
        New-WebBinding -Name $websiteName -IP $ip -Port $port -Protocol $protocol -HostHeader $hostHeader
    }
}

function New-WebSiteBindingNonHttp($websiteName, $protocol, $bindingInformation)
{
	echo "Binding website $websiteName to binding information $bindingInformation over $protocol"
	New-ItemProperty $sitesPath\$websiteName –name bindings –value @{protocol="$protocol";bindingInformation="$bindingInformation"}
}

function Set-SslBinding(
    [Parameter(Mandatory=$true)] [string] $certificateName,
    [Parameter(Mandatory=$true)] [string] $ip,
    [Parameter(Mandatory=$true)] [string] $port,
    [string] $host = '*'
) {
    Write-Host "Binding certificate $certificateName to IP $ip, port $port, host $host."
    $certificate = GetSslCertificate $certificateName

    if (!$certificate) {
        throw "Certificate $certificateName was not found in current store."
    }

    $pathIP = $(if ($ip -ne '*') { $ip } else { '' })    
    $path = "IIS:\SslBindings\$pathIP!$port"
    if ($host -ne '*') {
        if (!$host) {
            Write-Error "Host must not be empty (use * instead)."
        }

        $path += "!$host"
    }

    if (Test-Path $path) {
        Write-Host "Removing existing binding for IP $ip, port $port, host $host."
        Remove-Item $path
    }

    if ($host -ne '*') {
        $certificate | New-Item $path -SslFlags 1 | Out-Null
    }
    else {
        # Older versions might not have SslFlags
        $certificate | New-Item $path | Out-Null
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

function New-WebApplication(
    [Parameter(Mandatory=$true)] [string] $websiteName,
    [Parameter(Mandatory=$true)] [string] $appPoolName,
    [Parameter(Mandatory=$true)] [string] $subPath,
    [Parameter(Mandatory=$true)] [string] $physicalPath,
    [switch] $force
)
{
    Write-Host "Adding application $subPath to web site $websiteName pointing to $physicalPath running under app pool $appPoolName."
    New-Item $sitesPath\$websiteName\$subPath `
        -PhysicalPath $physicalPath `
        -ApplicationPool $appPoolName `
        -Type Application `
        -Force:$force
}

function Stop-AppPool($name) {
    StopWebItemInternal AppPool $appPoolsPath $name
}

# TODO rename to something with WebSite, though Stop-WebSite is taken by IIS snap-in
function Stop-Site([Parameter(Mandatory=$true)] [string] $siteName) {
    StopWebItemInternal Site $sitesPath $siteName
}

function Stop-AppPoolAndSite(
    [Parameter(Mandatory=$true)] [string] $appPoolName,
    [Parameter(Mandatory=$true)] [string] $siteName
) {
    Stop-AppPool $appPoolName
    Stop-Site $siteName
}

function Start-AppPool([Parameter(Mandatory=$true)] [string] $name) {
    StartWebItemInternal AppPool $appPoolsPath $name
}

# TODO rename to something with WebSite, though Start-WebSite is taken by IIS snapin
function Start-Site ([Parameter(Mandatory=$true)] [string] $name) {
    StartWebItemInternal Site $sitesPath $name
}

function Start-AppPoolAndSite(
    [Parameter(Mandatory=$true)] [string] $appPoolName,
    [Parameter(Mandatory=$true)] [string] $siteName
) {
    Start-Site $siteName
    Start-AppPool $appPoolName
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

function Set-AppPoolIdleTimeout(
	[Parameter(Mandatory=$true)] [string] $appPoolName, 
	[Parameter(Mandatory=$true)] [int] $mins)
{
	write-host "Setting $appPoolName Idle Time-out to $mins minutes"
	$appPool = Get-Item $appPoolsPath\$appPoolName
	$appPool.processModel.idleTimeout = [TimeSpan]::FromMinutes($mins)
	$appPool | Set-Item
}

export-modulemember -function set-webapppool32bitcompatibility,
                               set-apppoolidentitytouser,
                               set-apppoolidentityType,
                               set-apppoolstartMode,
                               new-webapplication,
                               new-virtualdirectory,
                               Register-VirtualDirectory,
                               Start-AppPoolAndSite,
                               Start-AppPool,
                               Start-Site,
                               Stop-AppPool,
                               Stop-AppPoolAndSite,
                               set-website,
                               uninstall-website,
                               set-webapppool,
                               uninstall-webapppool,
                               Set-WebSiteBinding,
                               New-WebSiteBinding,
                               New-WebSiteBindingNonHttp,
                               set-SelfSignedSslCertificate,
                               Set-SslBinding,
                               set-property,
                               set-webproperty,
                               Begin-WebChangeTransaction,
                               End-WebChangeTransaction,
                               Set-AppPoolIdleTimeout