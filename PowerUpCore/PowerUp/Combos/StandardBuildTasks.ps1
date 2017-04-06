if (${powerup.profile} -eq $null -or ${powerup.profile} -eq '') {
    ${powerup.profile} = 'Default'
}
. .\_powerup\Combos\StandardSettings.ps1

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

Import-Module PowerUpUtilities
Import-Module PowerUpFileSystem
Import-Module PowerUpZip
Import-Module TestCombos

$testResultsDirectory = "_testresults"

properties {
    $Configuration = 'Release'

    $NuGetServerDefault = 'https://api.nuget.org/v3/index.json'
    $NuGetServers = ($NuGetServerDefault)
    $IntermediateRoot = '_buildtemp'
    $PackageRoot = '_package'

    $MSBuildArgs = '' # Obsolete, do not use
    $BuildCommandArgs = ''
    $UseDotnetExe = $false

    $TestOptions = @{}

    $PackageStucture = @()
    $StandardWebExcludes = @(
        "**\*.cs",
        "**\*.resx",
        "**\Thumbs.db",
        "*.csproj",
        "*.user",
        "**\obj\**",
        "**\App_Data\**"
    )
}

task Clean {
    Remove-DirectoryFailSafe $IntermediateRoot
    Remove-DirectoryFailSafe $PackageRoot
    Remove-DirectoryFailSafe $testResultsDirectory
}

task RestorePackages {
    if (!$UseDotnetExe) {
        Import-Module PowerUpNuGet
        Restore-NuGetPackages -Sources $NuGetServers
    }
    else {
        $command = "dotnet restore" + ($NuGetServers | % { " --source $_" }) -join ''
        Invoke-External $command
    }
}

task Build {
    if ($MSBuildArgs -ne '') {
        Write-Error 'Property $MSBuildArgs is obsolete, please use $BuildArgs instead.'
    }

    Ensure-Directory $IntermediateRoot
    
    if (!$UseDotnetExe) {
        $BuildArgsFull = @("/Target:Rebuild", "/Property:Configuration=$Configuration") + $BuildCommandArgs
        Invoke-External "msbuild $($BuildArgsFull -join ' ')"
    }
    else {
        $BuildArgsFull = @("--configuration $Configuration") + $BuildCommandArgs
        Invoke-External "dotnet build $($BuildArgsFull -join ' ')"
    }
}

task Test {
    $defaults = @{
        nunit = @{ paths = @( "**\bin\$Configuration\*Tests*.dll" ) }
    }
    if ($UseDotnetExe) {
        $defaults = @{
            dotnet = @{
                paths = @("**\*Tests*.csproj")
                configuration = $Configuration
            }
        }
    }

    Merge-Defaults $TestOptions $defaults
    Invoke-ComboTests $TestOptions
}

task Publish {
    if (!$UseDotnetExe) {
        Write-Error "Publish is supported only for projects using dotnet CLI at the moment."
    }
    Invoke-External "dotnet publish --configuration $Configuration"
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
    Copy-Item .\powerup.bat .\$PackageRoot
    Copy-Item .\deploy.ps1 .\$PackageRoot
    Copy-Item .\settings.txt .\$PackageRoot
    
    if (Test-Path .\servers.txt) {
        Write-Error "File servers.txt is obsolete and should be removed."
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