function Install-AppFabric($isServer2008R2)
{
	#See http://msdn.microsoft.com/en-us/library/ff637714.aspx
	if ([System.Convert]::ToBoolean($isServer2008R2))
	{
		Write-Host "Installing AppFabric for Server 2008 R2 x64"
		& "$PSScriptRoot\WindowsServerAppFabricSetup_x64_6.1.exe" /i HostingServices
	}
	else
	{
		Write-Host "Installing AppFabric for Server 2008 x64"
		& "$PSScriptRoot\WindowsServerAppFabricSetup_x64_6.0.exe" /i HostingServices
	}
	Write-Host "AppFabric Installed"
}

Export-ModuleMember -function Install-AppFabric