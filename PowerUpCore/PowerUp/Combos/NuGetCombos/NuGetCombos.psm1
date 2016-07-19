Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

function Invoke-Combo-NuGet([Parameter(Mandatory=$true)][hashtable] $options) {
    Write-Warning "Invoke-Combo-NuGet is obsolete: use New-NuGetPackage in build phase to generate packages and Publish-NuGetPackage during deployemnt."
    import-module PowerUpNuGet

    Write-Host "NuGet options: $($options | Out-String)"

    $options.directories | % {
        $directory = $_
        Write-Host "Processing $directory" -ForegroundColor White
    
        $nuspec = (Get-ChildItem -Path $directory *.nuspec)
        if (!$nuspec) {
            throw "Could not find a .nuspec file in $directory."
        }
        $nuspec = $nuspec.FullName
        
        Write-Host "Creating package from $nuspec"
        Update-NuSpecFromFiles $nuspec $directory
        New-NuGetPackage $nuspec -outputDirectory $directory

        $package = (Get-ChildItem -Path $directory *.nupkg)
        if (!$package) {
            throw "Could not find a .nupkg file in $directory, did NuGet fail?"
        }
        
        $package = $package.FullName
        Send-NuGetPackage $package $options.server
    }
}