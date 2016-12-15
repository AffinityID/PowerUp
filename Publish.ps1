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

@(
    'PowerUpCore',
    'PowerUpFluentMigrator',
    'PowerUpFtp',
    'PowerUpJsonFallback',
    'PowerUpNUnit',
    'PowerUpPester',
    'PowerUpSql',
    'PowerUpSqlServer',
    'PowerUpSvn'
) | % {
    Write-Host $_ -ForegroundColor White
    if (Test-Path "$_\Prepare.ps1") {
        if (Test-Path "$_\packages.config") {
            Restore-NuGetPackages -Project "$_\packages.config" -PackagesDirectory "$_\_packages"
        }
    
        Push-Location "$_"
        try {
            &".\Prepare.ps1"
        }
        finally {
            Pop-Location
        }
    }
    Invoke-Robocopy .\$_ .\_output\$_ -Mirror `
        -ExcludeDirectories @('_*') -ExcludeFiles @('packages.config', 'Prepare.ps1') `
        -NoFileList -NoDirectoryList -NoJobHeader -NoJobSummary
    New-NuGetPackage ".\_output\$_\Package.nuspec" ".\_output" -Version $version -NoPackageAnalysis -NoDefaultExcludes
}

Publish-NuGetPackage ".\_output\*.nupkg" $server