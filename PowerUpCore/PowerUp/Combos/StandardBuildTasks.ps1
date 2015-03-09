Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

Import-Module PowerUpUtilities
Import-Module PowerUpTestRunner
Import-Module PowerUpFileSystem
Import-Module PowerUpZip
Import-Module PowerUpNuGet
Import-Module TestCombos

$testResultsDirectory = "_testresults"

properties {
    $Configuration = 'Release'

    $NuGetServers = ('https://nuget.org')
    $IntermediateRoot = '_buildtemp'
    $PackageRoot = '_package'

    $MSBuildArgs = ''

    $TestOptions = @{}

    $PackageStucture = @()
    $StandardWebExcludes = @(
        "*.cs",
        "*.csproj",
        "*.resx",
        "*.user"
        "*Thumbs.db",
        "*\obj",
        "*\obj\*",
        "*\App_Data*"
    )
}

task Clean {
    Remove-DirectoryFailSafe $testResultsDirectory
    Remove-DirectoryFailSafe $PackageRoot
}

task RestorePackages {
    Restore-NuGetPackages $NuGetServers
}

task Build {
    Ensure-Directory $IntermediateRoot
    $MSBuildArgsFull = @("/Target:Rebuild", "/Property:Configuration=$Configuration") + $MSBuildArgs
    Invoke-External msbuild $MSBuildArgsFull
}

task Test {
    Merge-Defaults $TestOptions @{
        default = @{
            rootpath = '.tests'
        }
        nunit = @{
            filefilter = '*Tests*.dll'
            pathfilter = "bin\$Configuration"
        }
    }
    Invoke-ComboTests $TestOptions
}

task Package {
    $PackageStructure | % {
        $exclude = if ($_.ContainsKey("Exclude")) { $_["Exclude"]; } else { @() }
        Copy-FilteredDirectory .\$($_.SourcePath) .\$PackageRoot\$($_.PackagePath) -excludeFilter $exclude
    }
    
    if (Test-Path .\_templates) {
        Invoke-Robocopy .\_templates\ .\$PackageRoot\_templates `
            -Mirror -CopyDirectories `
            -NoFileSize -NoProgress -NoDirectoryList -NoJobHeader -NoJobSummary
    }
    Copy-Item .\deploy.ps1 .\$PackageRoot
    Copy-Item .\settings.txt .\$PackageRoot
    
    if (Test-Path .\servers.txt) {
        Copy-Item .\servers.txt .\$PackageRoot
    }
    CreatePackageIdFile ".\$PackageRoot"
    $zip = ".\$PackageRoot\package_${build.number}.zip"
    Compress-ZipFile .\$PackageRoot\* $zip
}

function CreatePackageIdFile([string]$directory) {
    New-Item $directory\package.id -type file
    Add-Content $directory\package.id "PackageInformation"
    Add-Content $directory\package.id "`tpackage.build`t${build.number}"
    Add-Content $directory\package.id "`tpackage.date`t$(Get-Date -Format yyyyMMd-HHmm)"
}