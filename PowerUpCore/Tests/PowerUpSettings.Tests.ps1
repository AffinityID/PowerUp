Import-Module PowerUpSettings

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

Describe 'Read-Settings' {
    Mock -ModuleName PowerUpSettings Test-Path { $true }
    Mock -ModuleName PowerUpSettings Resolve-Path { param($path) $path }

    It 'reads basic raw setting' {
        Mock -ModuleName PowerUpSettings Get-Content { @(
            'TestSection',
            '  setting  value'
        ) }

        $settings = Read-Settings 'mockpath' 'TestSection' -Raw
        $settings['setting'] | Should Be 'value'
    }

    It 'reads empty raw setting' {
        Mock -ModuleName PowerUpSettings Get-Content { @(
            'TestSection',
            '  setting'
        ) }

        $settings = Read-Settings 'mockpath' 'TestSection' -Raw
        $settings['setting'] | Should Be ''
    }

    It 'reads empty raw setting from Default section' {
        Mock -ModuleName PowerUpSettings Get-Content { @(
            'Default',
            '  setting'
        ) }

        $settings = Read-Settings 'mockpath' 'Default' -Raw
        $settings['setting'] | Should Be ''
    }

    It 'reads default raw setting' {
        Mock -ModuleName PowerUpSettings Get-Content { @(
            'Default'
            '  setting value'
            'TestSection'
        ) }

        $settings = Read-Settings 'mockpath' 'TestSection' -Raw
        $settings['setting'] | Should Be 'value'
    }

    It 'preserves empty non-default setting' {
        Mock -ModuleName PowerUpSettings Get-Content { @(
            'Default'
            '  setting defaultValue'
            'TestSection'
            '  setting'
        ) }

        $settings = Read-Settings 'mockpath' 'TestSection' -Raw
        $settings['setting'] | Should Be ''
    }

    It 'reads setting references' {
        Mock -ModuleName PowerUpSettings Get-Content { @(
            'TestSection'
            '  s1 x'
            '  s2 a${s1}b'
        ) }

        $settings = Read-Settings 'mockpath' 'TestSection'
        $settings['s2'] | Should Be 'axb'
    }
}

Describe 'Import-Settings' {
    It 'imports basic setting value correctly' {
        Import-Settings @{ 'test.setting.basic'='xyz' }
        ${test.setting.basic} | Should Be 'xyz'
    }

    It 'throws invalid reference error on access only' {
        Import-Settings @{ 'test.setting.invalidref'='${unknown}' }
        { ${test.setting.invalidref} } | Should Throw 'references unknown'
    }
}