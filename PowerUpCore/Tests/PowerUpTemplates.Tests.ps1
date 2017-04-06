Import-Module PowerUpTemplates

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

Describe 'Expand-Template' {
    It 'should raise an error if an unknown variable is found' {
        { Expand-Template 'A ${unknown} B' } | Should Throw
    }

    It 'should expand variable (curly braces)' {
        Set-Variable -Name 'x x' -Value 5 -Scope Global
        Expand-Template 'A ${x x} B' | Should Be 'A 5 B'
    }

    It 'should expand expression' {
        Expand-Template 'A $(3+2) B' | Should Be 'A 5 B'
    }
    
    It 'should expand nested expressions' {
        Expand-Template 'A $(1+$(2)+2) $(3+$(1+$(1))) B' | Should Be 'A 5 5 B'
    }
}