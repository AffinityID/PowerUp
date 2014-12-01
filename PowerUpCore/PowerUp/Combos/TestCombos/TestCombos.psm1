Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

function Invoke-ComboTests([Parameter(Mandatory=$true)] [hashtable] $options) {
    Import-Module PowerUpUtilities
    Import-Module PowerUpTestRunner
    Write-Host "Test options: $($options | Out-String)"

    $testErrors = @()
    $defaults = $options['default']
    if ($defaults -eq $null) {
        $defaults = @{}
    }
    
    $nunit = $options['nunit']
    if ($nunit -ne $null) {
        Merge-Defaults $nunit $defaults
        Merge-Defaults $nunit @{
            filefilter = '*.dll'
            pathfilter = ''
        }
        Get-ChildItem -Recurse -Path $nunit.rootpath -Include $nunit.filefilter |
            ? { $_.FullName -match [regex]::Escape($nunit.pathfilter) } | # not great, but Split-Path would be much harder
            % { 
                Invoke-NUnitTests $_ -ErrorAction Continue -ErrorVariable testError
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
        Merge-Defaults $pester $defaults
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