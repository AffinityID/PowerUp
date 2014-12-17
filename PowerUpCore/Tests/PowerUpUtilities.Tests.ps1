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

Describe 'Get-RealException' {
    It 'should unwrap non-existent file property set exception to IOException' {
        $real = $null
        $file = New-Object IO.FileInfo("file with this name is unlikely to exist")
        try {
            $file.Attributes= 'Normal'
        }
        catch {
            $real = Get-RealException($_.Exception)            
        }
        
        ($real -is [IO.IOException]) | Should Be $true
    }
    
    It 'should unwrap non-existent file method call exception to IOException' {
        $real = $null
        $file = New-Object IO.FileInfo("file with this name is unlikely to exist")
        try {
            $file.MoveTo("somewhere")
        }
        catch {
            $real = Get-RealException($_.Exception)
        }
        
        ($real -is [IO.IOException]) | Should Be $true
    }
}