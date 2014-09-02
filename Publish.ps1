param(
    [Parameter(Mandatory=$true)][string] $server,
    [int] $buildNumber = 0
)
$version = "0.99.$buildNumber"

Remove-Item -Recurse .\_output

Import-Module .\deploy\modules\PowerUpFileSystem\PowerUpFileSystem.psm1
Import-Module .\deploy\modules\PowerUpNuGet\PowerUpNuGet.psm1

Copy-Directory .\Nuget .\_output\PowerUpPackage
Copy-Directory .\Build .\_output\PowerUpPackage\PowerUp\Build
Copy-Directory .\Deploy .\_output\PowerUpPackage\PowerUp\Deploy

Update-NuGet
New-NuGetPackage ".\_output\PowerUpPackage\Package.nuspec" ".\_output" "-Version $version -NoPackageAnalysis"
Send-NuGetPackage ".\_output\*.nupkg" $server
