function SvnCheckOut
{
	param ([string]$svnUrl       = $(read-host "Please specify the path to SVN"),
		   [string]$svnLocalPath = $(read-host "Please specify the local path"),
		   [string]$svnUsername  = $(read-host "Please specify the username"),
		   [string]$svnPassword  = $(read-host "Please specify the password")
		  )
	if (!(Test-Path $svnLocalPath))
	{
		Write-Host "The path doesn't exist, it will be created"
		New-Item -ItemType directory -Path $svnLocalPath
	}
	# Load SharpSVN DLL
	[Reflection.Assembly]::LoadFile("$PSScriptRoot\SharpSvn.dll")
	
	# Creates a SharpSVN SvnClient object
	$svnClient = new-object SharpSvn.SvnClient
	$svnClient.Authentication.DefaultCredentials = New-Object System.Net.NetworkCredential($svnUsername, $svnPassword)
	
	# Creates a SharpSVN SvnUriTarget object
	$repoUri = new-object SharpSvn.SvnUriTarget($svnUrl)

	# Perform the checkout
	$svnClient.CheckOut($repoUri, $svnLocalPath)
}

function SvnUpdate
{
	param([string]$svnLocalPath = $(read-host "Please specify the local path"),
		  [string]$svnUsername  = $(read-host "Please specify the username"),
		  [string]$svnPassword  = $(read-host "Please specify the password")
	)
	if (!(Test-Path $svnLocalPath))
	{
	  throw "Please specify a correct local path"
	}
	
	# Load SharpSVN DLL
	[Reflection.Assembly]::LoadFile("$PSScriptRoot\SharpSvn.dll")
	
	# Creates a SharpSVN SvnClient object
	$svnClient = new-object SharpSvn.SvnClient
	$svnClient.Authentication.DefaultCredentials = New-Object System.Net.NetworkCredential($svnUsername, $svnPassword)

	# Perform the update
	$svnClient.Update($svnLocalPath)
}