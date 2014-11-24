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

@('PowerUpCore', 'PowerUpSvn') | % {
    Invoke-Robocopy .\$_ .\_output\$_ -Mirror -NoFileList -NoDirectoryList -NoJobHeader -NoJobSummary
    New-NuGetPackage ".\_output\$_\Package.nuspec" ".\_output" -Version $version -NoPackageAnalysis -NoDefaultExcludes
}

Publish-NuGetPackage ".\_output\*.nupkg" $server