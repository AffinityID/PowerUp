Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$testRunnerExe = "$PSScriptRoot\nunit-console.exe"

function Invoke-TestSuite {
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
    $cmd = "$testRunnerExe /result=.\$resultsDirectory\$resultFileName.xml $testSuitePathObject"
    Invoke-External $cmd -ErrorAction $ErrorActionPreference
}

Export-ModuleMember -function Invoke-TestSuite