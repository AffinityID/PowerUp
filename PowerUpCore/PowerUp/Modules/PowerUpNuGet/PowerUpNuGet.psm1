Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$nuget = "$PSScriptRoot\NuGet.exe"

function Update-NuGet() {
    Write-Host "$nuget update -self"
    &$nuget update -self
}

function Update-NuSpecFromFiles(
    [Parameter(Mandatory=$true)][string] $nuspecPath,
    [Parameter(Mandatory=$true)][string] $baseDirectory
) {
    $assemblyFile = (Get-ChildItem -recurse -path $baseDirectory *.dll | Select-Object -first 1)
    if (!$assemblyFile) {
        Write-Warning "No assembly files found in $baseDirectory."
        return
    }

    Write-Host "$($assemblyFile.Name) metadata:"
    $assembly = [Reflection.Assembly]::LoadFrom($assemblyFile.FullName)
    $assemblyName = $assembly.GetName()
    $attributes = $assembly.GetCustomAttributes($false)
        
    $variables = @{
        version = ((
            (Get-AttributeValue $attributes $([Reflection.AssemblyInformationalVersionAttribute]) InformationalVersion),
            $assemblyName.Version
        ) -ne $null)[0];
        author = (Get-AttributeValue $attributes $([Reflection.AssemblyCompanyAttribute]) Company);
        description = (Get-AttributeValue $attributes $([Reflection.AssemblyDescriptionAttribute]) Description);
        title = (Get-AttributeValue $attributes $([Reflection.AssemblyTitleAttribute]) Title);
    };
    
    $variables.GetEnumerator() | ? { $_.Value -ne $null } | % {
        Write-Host "  $($_.Key) = $($_.Value)"
    }
    $nuspecContent = [IO.File]::ReadAllText($nuspecPath)
    $nuspecContent = [regex]::Replace($nuspecContent, '\$([^\$]+)\$', {
        param ($match)

        $name = $match.Groups[1].Value
        $value = $variables[$name]
        if ($value -eq $null) {
            Write-Warning "No substitution found for $name."
            return $match.Value
        }
        
        return $value
    })
    [IO.File]::WriteAllText($nuspecPath, $nuspecContent)
}

function Get-AttributeValue(
    [Parameter(Mandatory=$true)][Attribute[]] $attributes,
    [Parameter(Mandatory=$true)][type] $attributeType,
    [Parameter(Mandatory=$true)][string] $property
) {
    $attribute = ($attributes | ? { $_ -is $attributeType })
    if (!$attribute) {
        return $null;
    }
    
    return $attribute.$property
}

function New-NuGetPackage(
    [Parameter(Mandatory=$true)][string] $nuspecPath,
    [Parameter(Mandatory=$true)][string] $outputDirectory,
    [string] $options
) {
    $packCmd = "$nuget pack $nuspecPath -outputdirectory $outputDirectory"
    if ($options) {
        $packCmd += " " + $options
    }
    Write-Host $packCmd
    Invoke-Expression $packCmd
}

function Send-NuGetPackage(
    [Parameter(Mandatory=$true)][string] $packagePath,
    [Parameter(Mandatory=$true)][uri] $serverUrl
) {
  Write-Host "$nuget push $packagePath -s $serverUrl"
  &$nuget push $packagePath -s $serverUrl
}

function Restore-NuGetPackages(
    [Parameter(Mandatory=$true)][uri] $serverUrl
) {
    Write-Host "$nuget restore -source $serverUrl"
    &$nuget restore -source $serverUrl
}

function Install-NuGetPackage(
    [Parameter(Mandatory=$true)][string] $name,
    [string] $outputDirectory,
    [version] $version,
    [uri] $server
) {
    Import-Module PowerUpUtilities
    
    $command = "$nuget install `"$name`""
    if ($outputDirectory) {
        $outputDirectory = (Get-Item $outputDirectory).FullName
        $command += " -OutputDirectory `"$outputDirectory`""
    }
    
    if ($version) {
        $command += " -Version $version"
    }
    
    if ($server) {
        $server += " -Source $server"
    }
    
    Invoke-External $command
}

export-modulemember -function Update-NuGet,
                              Restore-NuGetPackages,
                              Update-NuSpecFromFiles,
                              New-NuGetPackage,
                              Send-NuGetPackage,
                              Install-NuGetPackage