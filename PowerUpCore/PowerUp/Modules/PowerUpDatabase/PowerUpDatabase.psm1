Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

Import-Module "$PSScriptRoot\sqlps\sqlps.psd1"

function New-SqlServerConnectionString(
    [string]         $base,
    [Nullable[bool]] $integratedSecurity,
    [string]         $userID,
    [string]         $password
)
{
    $builder = New-Object Data.SqlClient.SqlConnectionStringBuilder($base)
    if ($integratedSecurity -ne $null) {
        $builder.PSBase.IntegratedSecurity = [bool]$integratedSecurity
    }

    if ($userID -ne $null) {
        $builder.PSBase.UserID = $userID
    }

    if ($password -ne $null) {
        $builder.PSBase.Password = $password
    }
    
    return $builder.Tostring()
}

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

Export-ModuleMember -Function New-SqlServerConnectionString,
                              Get-SqlServerDatabase,
                              New-SqlServerDatabase,
                              Add-SqlServerLogin,
                              Add-SqlServerDatabaseUser