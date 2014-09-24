Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

[Reflection.Assembly]::LoadFile("$PSScriptRoot\SharpSvn.dll")

# TODO: remove sometime later
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

    Write-Warning "SvnCheckOut is obsolete, use New-SvnWorkingCopy instead."
    New-SvnWorkingCopy $svnLocalPath $svnUrl $svnUsername $svnPassword
}

# TODO: improve naming (Update-SvnItem?)
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
	
	# Creates a SharpSVN SvnClient object
	$svnClient = new-object SharpSvn.SvnClient
	$svnClient.Authentication.DefaultCredentials = New-Object System.Net.NetworkCredential($svnUsername, $svnPassword)

	# Perform the update
	$svnClient.Update($svnLocalPath)
}

function New-SvnWorkingCopy(
    [Parameter(Mandatory=$true)][string]$path,
    [Parameter(Mandatory=$true)][uri]$url,
    [string]$username,
    [string]$password
)
{
    Use-SvnClient $username $password {
        param ($client)
    
        $args = New-SvnArgs SharpSvn.SvnCheckOutArgs
        $source = New-Object SharpSvn.SvnUriTarget($url)

        Write-Host "Checking out '$url' to '$path'."
        $client.CheckOut($source, $path, $args) | Out-Null
    }
}

function Remove-SvnItem(
    [Parameter(Mandatory=$true)][string]$path,
    [string]$message,
    [string]$username,
    [string]$password
)
{
    $pathUri = ConvertTo-RemoteUri $path
    Use-SvnClient $username $password {
        param ($client)

        $args = New-SvnArgs SharpSvn.SvnDeleteArgs $message
        if (!$pathUri)
        {
            Write-Host "Deleting local '$path' from SVN working copy."
            $client.Delete($path, $args) | Out-Null
        }
        else
        {
            Write-Host "Deleting '$path'."
            $client.RemoteDelete($pathUri, $args)  | Out-Null
        }
    }
}

function Copy-SvnItem(
    [Parameter(Mandatory=$true)][string]$path,
    [Parameter(Mandatory=$true)][string]$destinationPath,
    [string]$message,
    [string]$username,
    [string]$password
)
{
    $pathUri = ConvertTo-RemoteUri $path
    $source = if (!$pathUri) { New-Object SharpSvn.SvnPathTarget($path) }
              else { New-Object SharpSvn.SvnUriTarget($pathUri) }

    Use-SvnClient $username $password {
        param ($client)

        $args = New-SvnArgs SharpSvn.SvnCopyArgs $message
        if (!$pathUri)
        {
            Write-Host "Copying local '$path' to '$destinationPath' in SVN working copy."
            $source = New-Object SharpSvn.SvnPathTarget($path)
            $client.Copy($source, $destinationPath, $args)  | Out-Null
        }
        else
        {
            Write-Host "Copying '$path' to '$destinationPath'."
            $source = New-Object SharpSvn.SvnUriTarget($pathUri)
            $client.RemoteCopy($source, [uri]$destinationPath, $args) | Out-Null
        }
    }
}

function Get-SvnChildItem(
    [Parameter(Mandatory=$true)][string]$path,
    [string]$username,
    [string]$password
)
{
    $pathUri =  ConvertTo-RemoteUri $path
    Use-SvnClient $username $password {
        param ($client)

        $args = New-SvnArgs SharpSvn.SvnListArgs
        $target = if (!$pathUri) { New-Object SharpSvn.SvnPathTarget($path) }
                  else { New-Object SharpSvn.SvnUriTarget($pathUri) }

        Write-Host "Getting items from '$path'."

        # http://stackoverflow.com/questions/25677197/write-output-not-working-inside-a-callback
        <# $client.List($target, $args, {
            param ($sender, $e)
            $e.Detach()
            Write-Output $e
        }) #>

        $results = $null
        $client.GetList($target, $args, [ref]$results) | Out-Null
        $results | % { $_.Detach(); $_ } | Select-Object -Skip 1
    }
}

function Publish-SvnItem(
    [Parameter(Mandatory=$true)][string]$path,
    [string]$message,
    [string]$username,
    [string]$password
)
{
    Use-SvnClient $username $password {
        param ($client)
        
        $args = New-SvnArgs SharpSvn.SvnCommitArgs $message
        Write-Host "Committing $path to SVN (message = '$message')."
        $client.Commit($path, $args)
    }
}

#private
function ConvertTo-RemoteUri([string]$path)
{
    $uri = New-Object uri($path, [UriKind]::RelativeOrAbsolute)
    if (!$uri.IsAbsoluteUri -or $uri.IsFile)
    {
        return $null
    }

    return $uri
}

# private
function Use-SvnClient([string]$username, [string]$password, [ScriptBlock]$block) {
    Import-Module PowerUpUtilities
    
    Use-Object (New-Object SharpSvn.SvnClient) {
        param ($client)
        if ($username)
        {
            $client.Authentication.DefaultCredentials = New-Object Net.NetworkCredential($username, $password)
        }

        &$block $client
    }
}

# private
function New-SvnArgs([string]$type, [string] $message)
{
    $args = New-Object $type
    $args.ThrowOnError = $true

    if ($message)
    {
        $args.LogMessage = $message
    }
    return $args
}

Export-ModuleMember -function SvnCheckOut,
                              SvnUpdate,
                              New-SvnWorkingCopy,
                              Remove-SvnItem,
                              Copy-SvnItem,
                              Get-SvnChildItem,
                              Publish-SvnItem