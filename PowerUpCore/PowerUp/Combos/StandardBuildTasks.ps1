Import-Module PowerUpTestRunner
Import-Module PowerUpFileSystem
Import-Module PowerUpZip

$packageDirectory = "_package"
$testResultsDirectory = "_testresults"

task Clean {
    if ((Test-Path $testResultsDirectory -PathType Container)) {
        Remove-Item -Recurse -Force $testResultsDirectory
    }
    if ((Test-Path $packageDirectory -PathType Container)) {
        Remove-Item -Recurse -Force $packageDirectory
    }
}

task Build {
    msbuild /Target:Rebuild /Property:Configuration=Release
}

task Test {
    Get-ChildItem -Recurse -Path ".tests\**\bin\Release" -Filter "*.Tests.dll" | % {
        Invoke-TestSuite $_
    }
}