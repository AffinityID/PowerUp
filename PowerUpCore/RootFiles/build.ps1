. _powerup\Combos\StandardBuildTasks.ps1

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

properties {
    $TestOptions = @{
        NUnit = @{ RootPath = '.' }
    }
    $PackageStructure = @(
        @{
            SourcePath = 'Web'
            PackagePath = 'Web'
            Exclude = $StandardWebExcludes
        },
        @{
            SourcePath = 'Migrations\bin\Release'
            PackagePath = 'Migrations'
        }
    )
}

task Default -depends Clean, Build, Test, Package