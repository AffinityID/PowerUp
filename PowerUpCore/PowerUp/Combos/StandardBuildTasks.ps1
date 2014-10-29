Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

Import-Module PowerUpUtilities
Import-Module PowerUpTestRunner
Import-Module PowerUpFileSystem
Import-Module PowerUpZip
Import-Module PowerUpNuGet

$packageDirectory = "_package"
$testResultsDirectory = "_testresults"

properties {
    $NuGetServers = @('https://nuget.org');

    $MSBuildArgs = '';
    
    $TestRoot = '.tests';
	
    $PackageStucture = @();
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
    Remove-DirectoryFailSafe $packageDirectory
}

task RestorePackages {
	Restore-NuGetPackages $NuGetServers
}

task Build {    
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
        Copy-FilteredDirectory .\$($_.SourcePath) .\_package\$($_.PackagePath) -excludeFilter $exclude
    }
    
    Copy-Directory .\_templates\ .\_package\_templates
    Copy-Item .\deploy.ps1 .\_package
    Copy-Item .\settings.txt .\_package
    Copy-Item .\servers.txt .\_package

    $zip = ".\_package\package_${build.number}.zip"
    Compress-ZipFile .\_package\* $zip
}