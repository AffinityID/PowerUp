param(
    [Parameter(Mandatory=$true)][string] $server,
    [int] $buildNumber = 0,
    [string] $outputPath = ".\_output"
)
$version = "0.9.$buildNumber"

if (Test-Path $outputPath) {
    Remove-Item -Recurse $outputPath
}

Import-Module .\PowerUpCore\PowerUp\Modules\PowerUpFileSystem\PowerUpFileSystem.psm1
Import-Module .\PowerUpCore\PowerUp\Modules\PowerUpNuGet\PowerUpNuGet.psm1

Copy-Directory .\PowerUpCore .\_output\PowerUpCore

Update-NuGet
New-NuGetPackage ".\_output\PowerUpCore\Package.nuspec" ".\_output" "-Version $version -NoPackageAnalysis"
Send-NuGetPackage ".\_output\*.nupkg" $server