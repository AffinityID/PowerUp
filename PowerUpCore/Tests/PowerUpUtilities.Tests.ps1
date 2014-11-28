Import-Module PowerUpUtilities

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"


Describe 'Wait-Until' {
    Mock Write-Host 

    It 'should handle $null in -BeforeFirstWait' {
        $waitCount = -1
        Wait-Until {
            $script:waitCount += 1
            return $waitCount -gt 0
        }.GetNewClosure() `
          -BeforeFirstWait $null `
          -WaitPeriod (New-TimeSpan -Seconds 0) `
          -Timeout (New-TimeSpan -Minutes 10)
    }

    It 'should execute -BeforeFirstWait block if wait happened' {
        $waitCount = -1
        $ref = @{ executed=$false }
        Wait-Until {
            $script:waitCount += 1
            return $waitCount -gt 0
        }.GetNewClosure() `
          -BeforeFirstWait { $script:ref.executed = $true }.GetNewClosure() `
          -WaitPeriod (New-TimeSpan -Seconds 0) `
          -Timeout (New-TimeSpan -Minutes 10)

        $ref.executed | Should Be $true
    }
}