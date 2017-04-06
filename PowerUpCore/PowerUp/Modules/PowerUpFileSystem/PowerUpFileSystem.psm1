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
    [string[]] $excludeFiles,
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

    if ($options.length > 0)
        $options += ' '

    $options += (Format-ExternalArguments @{
        '/e'     = $copyDirectoriesIncludingEmpty
        '/s'     = $copyDirectories
        '/purge' = $purge
        '/mir'   = $mirror
        
        '/xd'    = $(if ($excludeDirectories) { ($excludeDirectories | % { "`"$_`"" }) -Join ' ' } else { $null })
        '/xf'    = $(if ($excludeFiles) { ($excludeFiles | % { "`"$_`"" }) -Join ' ' } else { $null })
        
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

    if ($options.length > 0)
        $options += ' '
        
    $options += (Format-ExternalArguments (@{
        '/R'     = 10    # Set default number of retries
    }) ":")

    $filesString = ($files | % { "`"$_`"" }) -Join ' '
    $command = "&'$PSScriptRoot\robocopy.exe' `"$sourceDirectory`" `"$destinationDirectory`" $filesString $options"
    Write-Host $command
    Invoke-Expression $command
    if ($LastExitCode -ge 8) {
        throw "Robocopy exited with exit code $LastExitCode"
    }
    $global:LastExitCode = 0
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
    $inheritance = $(if (Test-Path $path -PathType Container) { 'ContainerInherit, ObjectInherit' } else { 'None' })

    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($user, "FullControl", $inheritance, "None", "Allow")
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
    $sources = Get-Item $sourcePath
    if (!$sources) {
        throw "Could not find source path $sourcePath to copy."
    }
    
    $destination = Get-Item $destinationPath
    
    if (!$includeFilter) {
        $includeFilter = @("**")
    }

    $createdDirectories = @()
    $sources | % {
        Write-Host "Copying $(Resolve-Path $_.FullName -Relative) => $destinationPath"
        Get-MatchedPaths -Path $($_.FullName) -Includes $includeFilter -Excludes $excludeFilter | % {    
            $itemDestination = Join-Path $destination.FullName $_.RelativePath
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($itemDestination)) | Out-Null
            Copy-Item -Path $_.FullPath -Destination $itemDestination
        }
    }
}

Add-Type -TypeDefinition @"
    public class PathMatch {
        public PathMatch(string rootPath, string relativePath, string fullPath) {
            RootPath = rootPath;
            RelativePath = relativePath;
            FullPath = fullPath;
        }
        
        public string RootPath { get; private set; }
        public string RelativePath { get; private set; }
        public string FullPath { get; private set; }
    }
"@ -Language CSharpVersion3
function Get-MatchedPaths(
    [string] $path,
    [string[]] $includes,
    [string[]] $excludes
) {
    if ($path -eq '') { $path = '.' }
    [Reflection.Assembly]::LoadFrom("$PSScriptRoot\Microsoft.Framework.FileSystemGlobbing.dll") | Out-Null
    $matcher = New-Object Microsoft.Framework.FileSystemGlobbing.Matcher
    foreach ($include in $includes) { $matcher.AddInclude($include) | Out-Null }
    foreach ($exclude in $excludes) { $matcher.AddExclude($exclude) | Out-Null }
    $directory = [IO.DirectoryInfo](Get-Item $path)
    $directoryWrapper = New-Object Microsoft.Framework.FileSystemGlobbing.Abstractions.DirectoryInfoWrapper $directory
    
    $result = $matcher.Execute($directoryWrapper)
    return $result.Files | % {
        New-Object PathMatch($path, $_, (Join-Path $path $_))
    }
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
    Import-Module PowerUpUtilities

    Write-Host "Deleting $($item.FullName)"
    $success = $false
    while ($item.Exists) {
        try {
            $item.Attributes = 'Normal'
            $item.Delete()
        }
        catch {
            $exception = Get-RealException($_.Exception)
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
                                        Reset-Directory,
                                        Get-MatchedPaths