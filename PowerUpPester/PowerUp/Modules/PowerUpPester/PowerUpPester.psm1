Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$pesterTestRunnerModule = "$PSScriptRoot\Pester.3.0.0\Pester"

function Invoke-PesterTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] $testSuitePathObject,
        [string] $resultsDirectory = "_testresults"
    )

    # Ensure results directory
    if (!(Test-Path $resultsDirectory -PathType Container)) {
        New-Item $resultsDirectory -Type directory
    }

    Import-Module $pesterTestRunnerModule -Global
    Invoke-Pester -Path $testSuitePathObject -OutputXml "$resultsDirectory\pester.testresults.xml"
}

Export-ModuleMember -function Invoke-PesterTests