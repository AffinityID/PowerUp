Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

Import-Module PowerUpUtilities
Import-Module PowerUpTestRunner
Import-Module PowerUpFileSystem
Import-Module PowerUpZip
Import-Module PowerUpNuGet

$packageDirectory = "_package"
$testResultsDirectory = "_testresults"
$nugetServers = @()

properties {
    $MSBuildArgs = '';
    $TestRoot = '.tests'
}

task Clean {
    if ((Test-Path $testResultsDirectory -PathType Container)) {
        Remove-Item -Recurse -Force $testResultsDirectory
    }
    if ((Test-Path $packageDirectory -PathType Container)) {
        Remove-Item -Recurse -Force $packageDirectory
    }
}

task Restore {
	foreach ($nugetServer in $nugetServers) {
		Restore-NuGet $nugetServer
	}
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
            Invoke-TestSuite $_ -ErrorAction Continue -ErrorVariable testError
            if ($testError) {
                $anyTestError = $testError
            }
        }

    if ($anyTestError) {
        Write-Error "One of test suites failed: $anyTestError" -ErrorAction Stop
    }
}

function NuGetServers {
	[CmdletBinding()]
	param(
	    [Parameter(Position=0,Mandatory=1)][string[]]$serverUris
	)
	$nugetServers += $serverUris
}