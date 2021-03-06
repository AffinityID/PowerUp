Import-Module PowerUpNuGet

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

Describe ": Restore-NuGetPackages" {
    Context ": null is provided as the server url" {
        It "should throw an exception" {
            { Restore-NuGetPackages $null } | Should Throw
        }
    }

    Context ": empty array is provided as the server url" {
        It "should throw an exception" {
            { Restore-NuGetPackages @() } | Should Throw
        }
    }

    Context ": one server url is provided" {
        Mock -ModuleName PowerUpNuGet Invoke-NuGet {
            Write-Host "    (Mock) Invoke-NuGet `$parameters='$parameters'"
        }
        
        It "should invoke nuget restore providing the url as the -source parameter" {
            Restore-NuGetPackages -Sources @('https://nuget.org')
            Assert-MockCalled -ModuleName PowerUpNuGet Invoke-NuGet -Times 1 -Exactly -ParameterFilter { 
                $parameters -eq "restore -source `"https://nuget.org`""
            }
        }
    }

    Context ": more than one server url is provided" {
        Mock -ModuleName PowerUpNuGet Invoke-NuGet {
            Write-Host "    (Mock) Invoke-NuGet `$parameters='$parameters'"
        }
        
        It "should invoke nuget restore with array concatenated to ; delimited string as the -source parameter" {
            Restore-NuGetPackages -Sources @('http://nuget.web.dev.work/nuget', 'https://nuget.org')
            Assert-MockCalled -ModuleName PowerUpNuGet Invoke-NuGet -Times 1 -Exactly -ParameterFilter {
                $parameters -eq "restore -source `"http://nuget.web.dev.work/nuget;https://nuget.org`""
            }
        }
    }
}