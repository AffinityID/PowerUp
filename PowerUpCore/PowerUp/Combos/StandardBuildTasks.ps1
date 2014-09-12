Import-Module PowerUpTestRunner

$testResultsDirectory = "_testresults"

task Build {
    msbuild /property:Configuration=Release
}

task Test {
    if ((Test-Path $testResultsDirectory -PathType Container)) {
		Remove-Item $testResultsDirectory
	}

    Get-ChildItem -Recurse -Path ".tests\**\bin\Release" -Filter "*.Tests.dll" | % {
        Invoke-TestSuite $_
    }
}