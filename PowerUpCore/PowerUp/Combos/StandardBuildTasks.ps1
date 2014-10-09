Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

Import-Module PowerUpTestRunner
Import-Module PowerUpFileSystem
Import-Module PowerUpZip
Import-Module PowerUpNuGet

$packageDirectory = "_package"
$testResultsDirectory = "_testresults"
$nugetServers = @()

task Clean {
    if ((Test-Path $testResultsDirectory -PathType Container)) {
        Remove-Item -Recurse -Force $testResultsDirectory
    }
    if ((Test-Path $packageDirectory -PathType Container)) {
        Remove-Item -Recurse -Force $packageDirectory
    }
}

task Build {
	foreach ($nugetServer in $nugetServers) {
		Restore-NuGet $nugetServer
	}
	
	msbuild /Target:Rebuild /Property:Configuration=Release
}

task Test {
    Get-ChildItem -Recurse -Path ".tests\**\bin\Release" -Filter "*.Tests.dll" | % {
        Invoke-TestSuite $_
    }
}

function NuGetServers {
	[CmdletBinding()]
	param(
	    [Parameter(Position=0,Mandatory=1)][string[]]$serverUris
	)
	$nugetServers += $serverUris
}