function Invoke-FluentMigrator(
    [Parameter(Mandatory=$true)][string] $toolsPath,
    [Parameter(Mandatory=$true)][string] $assemblyPath,
    [Parameter(Mandatory=$true)][string] $connectionString,
    [string] $provider = 'SqlServer',
    [string] $context,
    [switch] $inProcess
) {
    Import-Module PowerUpUtilities
    $assembly = [Reflection.Assembly]::LoadFrom((Get-Item $assemblyPath).FullName)
    
    if (!$inProcess) {
        $migrate = "$toolsPath\Migrate.exe"
    
        $arguments = Format-ExternalArguments @{
            '--assembly' = $assembly.Location
            '--provider' = $provider
            '--conn'     = $connectionString
            '--context'  = $context
        } -EscapeAll
        Invoke-External "$migrate $arguments"
    }
    else {
        Add-Type -Path "$toolsPath\FluentMigrator.dll"
        Add-Type -Path "$toolsPath\FluentMigrator.Runner.dll"
        
        $announcer = New-Object FluentMigrator.Runner.Announcers.ConsoleAnnouncer
        $runnerContext = New-Object FluentMigrator.Runner.Initialization.RunnerContext($announcer)
        if ($runnerContext.GetType().GetProperty('Targets')) {
            # Latest version
            $runnerContext.Targets = @($assembly.Location)
        }
        else {
            # Older versions
            $runnerContext.Target = $assembly.Location
        }
        $runnerContext.Connection = $connectionString
        $runnerContext.Database = $provider
        $runnerContext.ApplicationContext = $context
        $executor = New-Object FluentMigrator.Runner.Initialization.TaskExecutor($runnerContext)
        $executor.Execute()
    }
}

Export-ModuleMember -Function Invoke-FluentMigrator