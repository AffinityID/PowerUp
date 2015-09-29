Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

function Invoke-ComboTests([Parameter(Mandatory=$true)] [hashtable] $options) {
    Import-Module PowerUpUtilities
    Import-Module PowerUpFileSystem
    Import-Module PowerUpTestRunner
    Write-Host "Test options: $($options | Out-String)"

    $testErrors = @()
    if ($options['default']) {
        Write-Error "Option 'default' is obsolete and no longer supported. Set test options per runner instead."
    }
    
    $nunit = $options['nunit']
    if ($nunit -ne $null) {
        Merge-Defaults $nunit @{ paths = @() }

        @('rootpath', 'pathfilter', 'filefilter') | % {
            if ($nunit[$_]) { Write-Error "Option '$_' is obsolete and no longer supported. Use 'paths' instead." }
        }

        Get-MatchedPaths -Includes $nunit.paths | % {
            Invoke-NUnitTests (Get-Item $_.FullPath) -ErrorAction Continue -ErrorVariable testError
            if ($testError) {
                $testErrors += $testError
            }
        }
    }
    else {
        Write-Host "Skipping NUnit tests (not enabled in options)."
    }

    $pester = $options['pester']
    if ($pester -ne $null) {
        Invoke-PesterTests $pester.rootpath -ErrorAction Continue -ErrorVariable testError
        if ($testError) {
            $testErrors += $testError
        }
    }
    else {
        Write-Host "Skipping Pester tests (not enabled in options)."
    }
    
    if ($testErrors.Length -gt 0) {
        Write-Error "One or more tests failed: $($testErrors | Out-String)" -ErrorAction Stop
    }
}