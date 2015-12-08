Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$nunitTestRunnerExe = "$PSScriptRoot\Nunit\nunit-console.exe"

function Invoke-NUnitTests {
    [CmdletBinding()] # allows -ErrorAction
    param (
        [Parameter(Mandatory=$true)] $testSuitePathObject,
        [string] $resultsDirectory = "_testresults"
    )

    Import-Module PowerUpUtilities

    # Ensure results directory
    if (!(Test-Path $resultsDirectory -PathType Container)) {
        New-Item $resultsDirectory -type directory
    }

    # Run test
    $resultFileName = $testSuitePathObject.Name
    $cmd = "$nunitTestRunnerExe /result=.\$resultsDirectory\$resultFileName.xml $testSuitePathObject"
    Invoke-External $cmd -ErrorAction $ErrorActionPreference
}

Export-ModuleMember -function Invoke-NUnitTests