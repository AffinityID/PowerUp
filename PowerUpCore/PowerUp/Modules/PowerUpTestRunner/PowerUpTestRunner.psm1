Set-StrictMode -Version 2
$testRunnerExe = "$PSScriptRoot\nunit-console.exe"

function Invoke-TestSuite(
    [Parameter(Mandatory=$true)] $testSuitePathObject,
    [string] $resultsDirectory = "_testresults"
) {
    # Ensure results directory
    if (!(Test-Path $resultsDirectory -PathType Container)) {
		New-Item $resultsDirectory -type directory
	}

    # Run test
    $resultFileName = $testSuitePathObject.Name
    $cmd = "$testRunnerExe /result=.\$resultsDirectory\$resultFileName.xml $testSuitePathObject"
    Write-Host $cmd
    Invoke-Expression $cmd
}

Export-ModuleMember -function Invoke-TestSuite