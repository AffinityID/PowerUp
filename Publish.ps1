param(
    [Parameter(Mandatory=$true)][string] $server,
    [string] $buildNumber = 0,
    [string] $outputPath = ".\_output"
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$version = "0.$buildNumber"

if (Test-Path $outputPath) {
    Remove-Item -Recurse $outputPath
}

$env:PSModulePath += ";$(Resolve-Path '.\PowerUpCore\PowerUp\Modules\')"
Import-Module PowerUpFileSystem
Import-Module PowerUpNuGet

@('PowerUpCore', 'PowerUpFluentMigrator', 'PowerUpPester', 'PowerUpSql', 'PowerUpSqlServer', 'PowerUpSvn', 'PowerUpJsonFallback') | % {
    Invoke-Robocopy .\$_ .\_output\$_ -Mirror -NoFileList -NoDirectoryList -NoJobHeader -NoJobSummary
    New-NuGetPackage ".\_output\$_\Package.nuspec" ".\_output" -Version $version -NoPackageAnalysis -NoDefaultExcludes
}

Publish-NuGetPackage ".\_output\*.nupkg" $server