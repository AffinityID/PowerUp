Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Invoke-NUnitTests {
    [CmdletBinding()] # allows -ErrorAction
    param (
        [Parameter(Mandatory=$true)] $testSuitePathObject,
        [string] $resultsDirectory = "_testresults",
        [string] $nunitExePath = "$PSScriptRoot/../../../packages/NUnit.ConsoleRunner.*/tools/nunit3-console.exe"
    )

    Import-Module PowerUpUtilities
    $nunitExePath = (Get-Item $nunitExePath).FullName

    # Ensure results directory
    if (!(Test-Path $resultsDirectory -PathType Container)) {
        New-Item $resultsDirectory -type directory
    }

    # Run test
    $resultFileName = $testSuitePathObject.Name
    Invoke-External "$nunitExePath $testSuitePathObject --result $(Format-ExternalEscaped ".\$resultsDirectory\$resultFileName.xml;format=nunit2")" -ErrorAction $ErrorActionPreference
}

Export-ModuleMember -function Invoke-NUnitTests