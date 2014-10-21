Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\Initialize-SqlpsEnvironment.ps1"

function Get-SqlServerDatabase {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $name,
        [string] $server = 'localhost'
    )

    return (Get-Item "SQLSERVER:\SQL\$server\DEFAULT\Databases\$name" -ErrorAction $ErrorActionPreference)
}

function New-SqlServerDatabase(
    [Parameter(Mandatory=$true)] [string] $name,
    [string] $server = 'localhost'
) {
    $serverSmo = Get-Item "SQLSERVER:\SQL\$server\DEFAULT"    
    $database = New-Object Microsoft.SqlServer.Management.Smo.Database ($serverSmo, $name)
    $database.Create()
    Write-Host "Created database $name on $server."
    return $database
}

function Add-SqlServerLogin(
    [Parameter(Mandatory=$true)] [string] $name,
    [string] $server = 'localhost'
) {
    $serverSmo = Get-Item "SQLSERVER:\SQL\$server\DEFAULT"
    if ($serverSmo.Logins.Contains($name)) {
        Write-Host "Login $name already exists on $server."
        return $serverSmo.Logins[$name]
    }
    
    $login = New-Object Microsoft.SqlServer.Management.Smo.Login($serverSmo, $name)
    $login.LoginType = 'WindowsUser'
    $login.Create()
    Write-Host "Created login $name on $server."
    return $login
}

function Add-SqlServerDatabaseUser(
    [Parameter(Mandatory=$true)] [string] $login,
    [Parameter(Mandatory=$true)] [string] $database,
    [string] $server = 'localhost'
) {
    $databaseSmo = Get-SqlServerDatabase $database -server $server
    if ($databaseSmo.Users.Contains($login)) {
        Write-Host "User $login already exists in $database ($server)."
        return $databaseSmo.Users[$login]
    }
    
    $user = New-Object Microsoft.SqlServer.Management.Smo.User($databaseSmo, $login)
    $user.Login = $login
    $user.Create()
    Write-Host "Created user $login in $database ($server)."
    return $user
}

# we need to use same version of migrator runner as FM version in project, so
# there is an expectation that https://www.nuget.org/packages/fluentmigrator.tools
# is installed and included in package
function Invoke-DatabaseMigrations(
    [Parameter(Mandatory=$true)][string] $assemblyPath,
    [Parameter(Mandatory=$true)][string] $connectionString,
    [string] $provider = 'SqlServer'
) {
    Import-Module PowerUpNuGet
    Import-Module PowerUpUtilities
    
    $assembly = [Reflection.Assembly]::LoadFrom((Get-Item $assemblyPath).FullName)
    
    $fmReference = ($assembly.GetReferencedAssemblies() | ? { $_.Name -eq 'FluentMigrator' } | select -first 1)
    if (!$fmReference) {
        throw "Could not find FluentMigrator reference in $assemblyPath"
    }
    $fmVersion = $fmReference.Version
    
    $temp = '_temp\Invoke-DatabaseMigrations'
    $migrate = "$temp\FluentMigrator.$fmVersion\tools\Migrate.exe"
    if (!(Test-Path $migrate)) {
        New-Item "$temp" -Type Directory
        Install-NuGetPackage 'FluentMigrator' -version $fmVersion -outputDirectory "$temp" 
    }
    
    Invoke-External "$migrate --assembly `"$($assembly.Location)`" --provider $provider --conn `"$connectionString`""
}