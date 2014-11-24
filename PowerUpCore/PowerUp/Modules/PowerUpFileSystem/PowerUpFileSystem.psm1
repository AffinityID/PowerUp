Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

function Ensure-Directory([string]$directory)
{
	if (!(Test-Path $directory -PathType Container))
	{
		Write-Host "Creating folder $directory"
		New-Item $directory -type directory | Out-Null
	}
}

function Reset-Directory([Parameter(Mandatory=$true)][string] $path) {
    Remove-DirectoryFailSafe $path
    Write-Host "Creating directory $path"
    New-Item $path -Type Directory | Out-Null
}

function Copy-Directory([string]$sourceDirectory, [string]$destinationDirectory) {
    Write-Warning "Copy-Directory is obsolete, use Invoke-Robocopy instead for better control."
    
    Write-Host "copying newer files from $sourceDirectory to $destinationDirectory"
    Invoke-Robocopy $sourceDirectory $destinationDirectory "/E /np /njh /nfl /ns /nc"

    Write-Host "Successfully copied to $destinationDirectory "
    cmd /c #reset the lasterrorcode strangely set by robocopy to be non-0
}

function Copy-MirroredDirectory([string]$sourceDirectory, [string]$destinationDirectory)
{
	Write-Host "Mirroring $sourceDirectory to $destinationDirectory"
	Invoke-Robocopy $sourceDirectory $destinationDirectory "/E /np /njh /nfl /ns /nc /mir"
	
	Write-Host "Successfully mirrored to $destinationDirectory "
	cmd /c #reset the lasterrorcode strangely set by robocopy to be non-0
}

function Invoke-Robocopy(
    [Parameter(Mandatory=$true)] [string] $sourceDirectory,
    [Parameter(Mandatory=$true)] [string] $destinationDirectory,
    [string] $options = '',
    
    # TODO: add other arguments and obsolete $options
    [string[]] $files,
    [switch] $mirror,
    [switch] $purge,
    [switch] $copyDirectories,
    [switch] $copyDirectoriesIncludingEmpty,
    [string[]] $excludeDirectories,
    [switch] $excludeExtra,
    [switch] $excludeChanged,
    [switch] $excludeNewer,
    [switch] $excludeOlder,
    [switch] $noProgress,
    [switch] $noFileSize,
    [switch] $noFileList,
    [switch] $noDirectoryList,
    [switch] $noJobHeader,
    [switch] $noJobSummary
) {
    Import-Module PowerUpUtilities
    
    $options += (Format-ExternalArguments @{
        '/e'     = $copyDirectoriesIncludingEmpty
        '/s'     = $copyDirectories
        '/purge' = $purge
        '/mir'   = $mirror
        
        '/xd'    = $(if ($excludeDirectories) { ($excludeDirectories | % { "`"$(Resolve-Path $_)`"" }) -Join ' ' } else { $null })
        
        '/xx'    = $excludeExtra
        '/xc'    = $excludeChanged
        '/xn'    = $excludeNewer
        '/xo'    = $excludeOlder
        
        '/np'    = $noProgress
        '/ns'    = $noFileSize
        '/nfl'   = $noFileList
        '/ndl'   = $noDirectoryList
        '/njh'   = $noJobHeader
        '/njs'   = $noJobSummary
    })

    $filesString = ($files | % { "`"$_`"" }) -Join ' '
    $command = "$PSScriptRoot\robocopy.exe `"$sourceDirectory`" `"$destinationDirectory`" $filesString $options"
    Write-Host $command
    Invoke-Expression $command
    if ($LastExitCode -ge 8) {
        throw "Robocopy exited with exit code $LastExitCode"
    }
}

function Write-FileToConsole([string]$fileName)
{	
	$line=""

	if ([System.IO.File]::Exists($fileName))
	{
		$streamReader=new-object System.IO.StreamReader($fileName)
		$line=$streamReader.ReadLine()
		while ($line -ne $null)
		{
			write-host $line
			$line=$streamReader.ReadLine()
		}
		$streamReader.close()		
	}
	else
	{
	   write-host "Source file ($fileName) dose not exist." 
	}
}

function Grant-PathFullControl(
    [Parameter(Mandatory=$true)][string] $path,
    [Parameter(Mandatory=$true)][string] $user
)
{
    Write-Host "Granting full control of $path to $user."
    $acl = Get-Acl $path
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($user, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($rule)
    Set-Acl $path $acl
}

function Copy-FilteredDirectory(
	[Parameter(Mandatory=$true)][string] $sourcePath,
	[Parameter(Mandatory=$true)][string] $destinationPath,
    [string[]] $includeFilter,
    [string[]] $excludeFilter
) {
    Ensure-Directory $destinationPath
    $source = Get-Item $sourcePath
    $destination = Get-Item $destinationPath

	Get-ChildItem -Recurse -Path $sourcePath | 
        Where-Object { Test-ObjectFullName -ObjectFullName $_.FullName -IncludeFilter $includeFilter -ExcludeFilter $excludeFilter } |
        ForEach-Object {
            $itemDestination = $_.FullName -replace [regex]::escape($source.FullName), $destination.FullName
            Copy-Item -Path $_.FullName -Destination $itemDestination
        }
}

function Test-ObjectFullName(
    [string] $objectFullName,
    [string[]] $includeFilter,
    [string[]] $excludeFilter    
) {
    foreach ($item in $includeFilter) {
        if ($objectFullName -like $item) {
            return $true
        }
    }

    foreach ($item in $excludeFilter) {
        if ($objectFullName -like $item) {
            return $false
        }
    }

    return $true
}

function Remove-DirectoryFailSafe(
    [Parameter(Mandatory=$true)] [string] $path
) {
    if (!(Test-Path $path)) {
        Write-Host "Directory '$path' does not exist (no need to delete)."
        return
    }

    Remove-DirectoryFailSafeInternal (Get-Item $path)
}

function Remove-DirectoryFailSafeInternal(
    [Parameter(Mandatory=$true)] [IO.DirectoryInfo] $directory
) {
    $directory.EnumerateFileSystemInfos() | % {
        if ($_ -is [IO.DirectoryInfo]) {
            Remove-DirectoryFailSafeInternal $_
        }
        else {
            Remove-NonRecursiveFailSafeInternal $_
        }
    }
    
    Remove-NonRecursiveFailSafeInternal $directory
}

function Remove-NonRecursiveFailSafeInternal(
    [Parameter(Mandatory=$true)] [IO.FileSystemInfo] $item
) {
    Write-Host "Deleting $($item.FullName)"
    $success = $false
    while ($item.Exists) {
        try {
            $item.Attributes = 'Normal'
            $item.Delete()
        }
        catch {
            $exception = $_.Exception
            while ($exception -is [Management.Automation.MethodInvocationException]) {
                $exception = $exception.InnerException
            }

            if ($exception -isnot [IO.IOException]) {
                throw $exception
            }
            
            Write-Error "Failed to delete '$($item.FullName)':`r`n$($exception.Message)" -ErrorAction Continue

            $holders = @(&("$PSScriptRoot\handle") $item.FullName | % { $_ } | select -skip 5) # 5 = header in current handle.exe
            if ($holders.Length -gt 0) {
                Write-Host "Processes holding '$($item.FullName)':`r`n$($holders -join "`r`n")"
            }
            Write-Host "`r`nRetrying in 30 seconds..."

            Start-Sleep -Seconds 30
        }
    }
}

Export-ModuleMember -Alias * -Function  Write-FileToConsole,
                                        Ensure-Directory,
                                        Copy-Directory,
                                        Copy-MirroredDirectory,
                                        Grant-PathFullControl,
                                        Invoke-Robocopy,
                                        Copy-FilteredDirectory,
                                        Remove-DirectoryFailSafe,
                                        Reset-Directory