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

# we need to use same version of migrator runner as FM version in project, so
# there is an expectation that https://www.nuget.org/packages/fluentmigrator.tools
# is installed and included in package
function Invoke-DatabaseMigrations(
    [Parameter(Mandatory=$true)][string] $assemblyPath,
    [Parameter(Mandatory=$true)][string] $connectionString,
    [string] $provider = 'SqlServer',
    [string] $context,
    [switch] $inProcess
) {
    Import-Module PowerUpFileSystem
    Import-Module PowerUpNuGet
    Import-Module PowerUpUtilities
    
    $assembly = [Reflection.Assembly]::LoadFrom((Get-Item $assemblyPath).FullName)
    $fmVersion = GetFluentMigratorVersion($assembly)
    if (!$fmVersion) {
        throw "Could not find FluentMigrator reference in $assemblyPath"
    }
    
    $temp = '_temp\Invoke-DatabaseMigrations'
    if (!$inProcess) {
        EnsureMigrationRunnerNuGetPackage -PackageId FluentMigrator -Version $fmVersion -RootPath $temp
        $migrate = "$temp\FluentMigrator.$fmVersion\tools\Migrate.exe"
    
        # TODO: Consider auto-escaping
        $arguments = Format-ExternalArguments @{
            '--assembly' = $assembly.Location
            '--provider' = $provider
            '--conn'     = $connectionString
            '--context'  = $context
        } -EscapeAll
        Invoke-External "$migrate $arguments"
    }
    else {
        EnsureMigrationRunnerNuGetPackage -PackageId FluentMigrator.Runner -Version $fmVersion -RootPath $temp
        Add-Type -Path "$temp\FluentMigrator.$fmVersion\lib\40\FluentMigrator.dll"
        Add-Type -Path "$temp\FluentMigrator.Runner.$fmVersion\lib\40\FluentMigrator.Runner.dll"
        
        $announcer = New-Object FluentMigrator.Runner.Announcers.ConsoleAnnouncer
        $runnerContext = New-Object FluentMigrator.Runner.Initialization.RunnerContext($announcer)
        $runnerContext.Target = $assembly.Location
        $runnerContext.Connection = $connectionString
        $runnerContext.Database = $provider
        $runnerContext.ApplicationContext = $context
        $executor = New-Object FluentMigrator.Runner.Initialization.TaskExecutor($runnerContext)
        $executor.Execute()
    }
}

function GetFluentMigratorVersion([Parameter(Mandatory=$true)][Reflection.Assembly] $migrationAssembly) {
    $fmReference = ($assembly.GetReferencedAssemblies() | ? { $_.Name -eq 'FluentMigrator' } | select -first 1)
    if (!$fmReference) {
        return $null
    }

    return $fmReference.Version
}

function EnsureMigrationRunnerNuGetPackage(
    [Parameter(Mandatory=$true)][string] $rootPath,
    [Parameter(Mandatory=$true)][string] $packageId,
    [Parameter(Mandatory=$true)][string] $version
) {
    if (Test-Path "$rootPath\$packageId.$version") {
        return
    }
    
    Ensure-Directory $rootPath
    Install-NuGetPackage $packageId -Version $version -OutputDirectory $rootPath
}

Export-ModuleMember -Function New-SqlServerConnectionString,
                              Get-SqlServerDatabase,
                              New-SqlServerDatabase,
                              Add-SqlServerLogin,
                              Add-SqlServerDatabaseUser,
                              Invoke-DatabaseMigrations