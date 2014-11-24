Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$nuget = "$PSScriptRoot\NuGet.exe"
Add-Type -Path "$PSScriptRoot\NuGet.Core.dll"

function Update-NuGet() {
    Write-Warning "Update-NuGet is obsolete and does nothing at the moment."
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

function Get-NuGetPackage(
    # in future this could have alt paramset to get from a server
    [string] $path
) {
    return New-Object NuGet.OptimizedZipPackage((Resolve-Path $path))
}

function Test-NuGetPackage(    
    [Parameter(Mandatory=$true)] [string] $id,
    [Parameter(Mandatory=$true)] [NuGet.SemanticVersion] $version,
    [Parameter(Mandatory=$true)] [string] $source
) {
    # command-line is useless for this
    return [NuGet.PackageRepositoryFactory]::Default.CreateRepository($source).Exists($id, $version);
}


function New-NuGetPackage(
    [Parameter(Mandatory=$true)][string] $nuspecPath,
    [Parameter(Mandatory=$true)][string] $outputDirectory,
    [string] $options,
    [NuGet.SemanticVersion] $version,
    [hashtable] $properties,
    [switch] $noPackageAnalysis,
    [switch] $noDefaultExcludes,
    [switch] $includeReferencedProjects
) {
    Import-Module PowerUpUtilities

    $command = "pack $nuspecPath " + (Format-ExternalArguments @{
        '-Version' = $version
        '-OutputDirectory' = $outputDirectory
        '-IncludeReferencedProjects' = $includeReferencedProjects
        '-NoPackageAnalysis' = $noPackageAnalysis
        '-NoDefaultExcludes' = $noDefaultExcludes
        '-Properties' = $(if ($properties) {
            ($properties.GetEnumerator() | % { "$($_.Name)=$($_.Value)" }) -join ';'
        })
    })
    if ($options) {
        Write-Warning "Options parameter is obsolete (though still supported). Add those as actual arguments instead."
        $command += " " + $options
    }

    Invoke-NuGet $command
}

function Send-NuGetPackage(
    [Parameter(Mandatory=$true)][string] $packagePath,
    [Parameter(Mandatory=$true)][uri] $serverUrl
) {
    Write-Warning "Send-NuGetPackage is obsolete, use Publish-NuGetPackage instead."
    Publish-NuGetPackage -PackagePath $packagePath -Source $serverUrl
}

function Publish-NuGetPackage(
    [Parameter(Mandatory=$true)][string] $packagePath,
    [Parameter(Mandatory=$true)][uri] $source
) {
    Invoke-NuGet "push `"$packagePath`" -s $source"
}

function Restore-NuGetPackages(
    [Parameter(Mandatory=$true)][string[]] $sources
) {
    Invoke-NuGet "restore -source $(Join-NuGetSources $sources)"
}

function Install-NuGetPackage(
    [Parameter(Mandatory=$true)][string] $name,
    [string] $outputDirectory,
    [version] $version,
    [string] $source
) {
    $command = "install `"$name`""
    if ($outputDirectory) {
        $outputDirectory = (Get-Item $outputDirectory).FullName
        $command += " -OutputDirectory `"$outputDirectory`""
    }
    
    if ($version) {
        $command += " -Version $version"
    }
    
    if ($source) {
        $server += " -Source $source"
    }
    
    Invoke-NuGet $command
}

function Invoke-NuGet([string] $parameters) {
    Import-Module PowerUpUtilities

    $command = "$nuget"
    if ($parameters) {
        $command += " " + $parameters
    }
    Invoke-External $command | Write-Host
}

function Join-NuGetSources(
    [Parameter(Mandatory=$true)][string[]]$sources
) {
    return "`"$($sources -join ';')`""
}

export-modulemember -function Update-NuGet,
                              Get-NuGetPackage,
                              Test-NuGetPackage,
                              Restore-NuGetPackages,
                              Update-NuSpecFromFiles,
                              New-NuGetPackage,
                              Send-NuGetPackage,
                              Publish-NuGetPackage,
                              Install-NuGetPackage,
                              Invoke-NuGet