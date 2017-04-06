param(
    [Parameter(Mandatory=$true)][string] $server,
    [string] $buildNumber = 0,
    [string] $outputPath = ".\_output"
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$version = "0.$buildNumber"

.\PrepareAll.ps1

if (Test-Path $outputPath) {
    Remove-Item -Recurse $outputPath
}

Import-Module PowerUpFileSystem
Import-Module PowerUpNuGet

@(
    'PowerUpCore',
    'PowerUpFluentMigrator',
    'PowerUpFtp',
    'PowerUpIIS',
    'PowerUpJsonFallback',
    'PowerUpNuGet',
    'PowerUpNUnit',
    'PowerUpPester',
    'PowerUpSql',
    'PowerUpSqlServer',
    'PowerUpSvn'
) | % {
    Write-Host $_ -ForegroundColor White
    Invoke-Robocopy .\$_ .\_output\$_ -Mirror `
        -ExcludeDirectories @('_*') -ExcludeFiles @('packages.config', 'Prepare.ps1') `
        -NoFileList -NoDirectoryList -NoJobHeader -NoJobSummary
    New-NuGetPackage ".\_output\$_\Package.nuspec" ".\_output" -Version $version -NoPackageAnalysis -NoDefaultExcludes
}

Publish-NuGetPackage ".\_output\*.nupkg" $server