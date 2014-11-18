param(
    [Parameter(Mandatory=$true)][string] $server,
    [int] $buildNumber = 0,
    [string] $outputPath = ".\_output"
)
$version = "0.9.$buildNumber"

if (Test-Path $outputPath) {
    Remove-Item -Recurse $outputPath
}

$env:PSModulePath += ";.\PowerUpCore\PowerUp\Modules\"
Import-Module PowerUpFileSystem
Import-Module PowerUpNuGet

# Core package
Copy-Directory .\PowerUpCore .\_output\PowerUpCore
New-NuGetPackage ".\_output\PowerUpCore\Package.nuspec" ".\_output" "-Version $version -NoPackageAnalysis -NoDefaultExcludes"

# Svn package
Copy-Directory .\PowerUpSvn .\_output\PowerUpSvn
New-NuGetPackage ".\_output\PowerUpSvn\Package.nuspec" ".\_output" "-Version $version -NoPackageAnalysis -NoDefaultExcludes"

Send-NuGetPackage ".\_output\*.nupkg" $server