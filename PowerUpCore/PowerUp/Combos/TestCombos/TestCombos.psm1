Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

function Invoke-ComboTests([Parameter(Mandatory=$true)] [hashtable] $options) {
    Import-Module PowerUpUtilities
    Import-Module PowerUpFileSystem
    Write-Host "Test options: $($options | Out-String)"

    $testErrors = @()
            
    $nunit = $options['nunit']
    if ($nunit -ne $null) {
        if (!(Get-Module -ListAvailable -Name PowerUpNUnit)) {
            Write-Error "PowerUpNUnit module is not found: make sure PowerUp.NUnit package is installed."
        }
        
        Import-Module PowerUpNUnit
        Merge-Defaults $nunit @{ paths = @() }
        Get-MatchedPaths -Includes $nunit.paths | % {
            Invoke-NUnitTests (Get-Item $_.FullPath) -ErrorAction Continue -ErrorVariable testError
            if ($testError) {
                $testErrors += $testError
            }
        }
    }

    $pester = $options['pester']
    if ($pester -ne $null) {
        if (!(Get-Module -ListAvailable -Name PowerUpPester)) {
            Write-Error "PowerUpPester module is not found: make sure PowerUp.Pester package is installed."
        }
    
        Import-Module PowerUpPester
        Invoke-PesterTests $pester.rootpath -ErrorAction Continue -ErrorVariable testError
        if ($testError) {
            $testErrors += $testError
        }
    }

    if ($testErrors.Length -gt 0) {
        Write-Error "One or more tests failed: $($testErrors | Out-String)" -ErrorAction Stop
    }
}