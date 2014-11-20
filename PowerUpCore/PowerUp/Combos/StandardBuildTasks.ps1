Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

Import-Module PowerUpUtilities
Import-Module PowerUpTestRunner
Import-Module PowerUpFileSystem
Import-Module PowerUpZip
Import-Module PowerUpNuGet

$testResultsDirectory = "_testresults"

properties {
    $NuGetServers = ('https://nuget.org')
    $IntermediateRoot = '_buildtemp'
    $PackageRoot = '_package'

    $MSBuildArgs = ''
    
    $TestRoot = '.tests'

    $PackageStucture = @()
    $StandardWebExcludes = @(
        "*.cs",
        "*.csproj",
        "*.resx",
        "*.user"
        "*Thumbs.db",
        "*\obj*",
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
    $MSBuildArgsFull = @("/Target:Rebuild", "/Property:Configuration=Release") + $MSBuildArgs
    Invoke-External msbuild $MSBuildArgsFull
}

task Test {
    $anyTestError = $null
    Get-ChildItem -Recurse -Path $TestRoot -Include "*Tests*.dll" |
        ? { $_.FullName -match "bin\\Release" } | # not great, but Split-Path would be much harder
        % { 
            Invoke-NUnitTests $_ -ErrorAction Continue -ErrorVariable testError
            if ($testError) {
                $anyTestError = $testError
            }
        }

    if ($anyTestError) {
        Write-Error "One of NUnit tests failed: $anyTestError" -ErrorAction Stop
    }

    Invoke-PesterTests $TestRoot -ErrorAction Continue -ErrorVariable testError
    if ($testError) {
        $anyTestError = $testError
    }

    if ($anyTestError) {
        Write-Error "One of PowerShell tests failed: $anyTestError" -ErrorAction Stop
    }
}

task Package {
    $PackageStructure | % {
        $exclude = if ($_.ContainsKey("Exclude")) { $_["Exclude"]; } else { @() }
        Copy-FilteredDirectory .\$($_.SourcePath) .\$PackageRoot\$($_.PackagePath) -excludeFilter $exclude
    }
    
    Copy-Directory .\_templates\ .\$PackageRoot\_templates
    Copy-Item .\deploy.ps1 .\$PackageRoot
    Copy-Item .\settings.txt .\$PackageRoot
    Copy-Item .\servers.txt .\$PackageRoot
	CreatePackageIdFile ".\$PackageRoot"
	
    $zip = ".\$PackageRoot\package_${build.number}.zip"
    Compress-ZipFile .\$PackageRoot\* $zip
}

function CreatePackageIdFile([string]$directory){
	New-Item $directory\package.id -type file
	Add-Content $directory\package.id "PackageInformation"
	Add-Content $directory\package.id "`tpackage.build`t${build.number}"
	Add-Content $directory\package.id "`tpackage.date`t$(Get-Date -Format yyyyMMd-HHmm)"
}