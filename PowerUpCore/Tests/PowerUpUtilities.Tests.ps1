Import-Module PowerUpUtilities

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

function EchoArgs([Parameter(Mandatory = $true)][string] $args) {
    $scriptPath = (Split-Path -Parent $script:MyInvocation.MyCommand.Path)
    $echoArgs = Resolve-Path (Join-Path $scriptPath 'Tools\EchoArgs.exe')
    Invoke-Expression "&`"$echoArgs`" $args" |
        ? { $_ -match '^Arg \d+ is <(.+)>$' } |
        % { $matches[1] }
}

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

Describe 'Format-ExternalEscaped' {
    @('o`o', 'o''o', 'o"o', 'o`"o', 'o`''o', 'o''"o', 'o`''"o', '`', '''', '"') | % {
        It "should escape $_ correctly" {
            $initial = $_
            $escaped = Format-ExternalEscaped $initial
            $received = EchoArgs $escaped
                    
            $received | Should Be $initial
        }
    }

    It "should escape list correctly" {
        $initial = @('a b', 'c d')
        $escaped = Format-ExternalEscaped $initial

        $escaped | Should Be '"a b" "c d"'
    }
}

Describe 'Format-ExternalArguments' {
    It "should format standard argument as '/key value'" {
        $result = Format-ExternalArguments @{ '/key' = 'value' }
        $result | Should Be '/key value'
    }
    
    It "should format argument ending in ':' as '/key:value'" {
        $result = Format-ExternalArguments @{ '/key:' = 'value' }
        $result | Should Be '/key:value'
    }

    It "should format `$true  switch argument as '/key' only (no value)" {
        $result = Format-ExternalArguments @{ '/key' = [switch]$true }
        $result | Should Be '/key'
    }
    
    It "should format `$false switch argument as empty" {
        $result = Format-ExternalArguments @{ '/key' = [switch]$false }
        $result | Should Be ''
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