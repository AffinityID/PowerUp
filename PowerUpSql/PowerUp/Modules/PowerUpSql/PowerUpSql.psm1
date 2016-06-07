Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

function Invoke-Sql(
    [Parameter(Mandatory=$true)] [string] $connectionString,
    [Parameter(Mandatory=$true)] [string] $sql,
    [Hashtable] $parameters = @{},
    [Type] $connectionType = [Data.SqlClient.SqlConnection]
)
{
    
    $connection = $null    
    $command = $null
    $reader = $null
    try {
        $connection = New-Object $connectionType($connectionString)
        $connection.Open()
           
        $command = $connection.CreateCommand()
        $command.CommandText = $sql
        
        Write-Host "SQL: $sql"
        foreach ($parameter in $parameters.GetEnumerator()) {
            Write-Host "  $($parameter.Key): $($parameter.Value)"
            $dbParameter = $command.CreateParameter()
            $dbParameter.ParameterName = $parameter.Key
            $dbParameter.Value = $(if ($parameter.Value -ne $null) { $parameter.Value } else { [DBNull]::Value })
            $command.Parameters.Add($dbParameter) | Out-Null
        }
        
        $reader = $command.ExecuteReader()
        $columns = $null
        while ($reader.Read()) {
            if (!$columns) {
                $columns = New-Object object[] $reader.FieldCount
                for ($i = 0; $i -lt $columns.Length; $i++) {
                    $columns[$i] = $reader.GetName($i)
                }
            }
            $row = @{}
            for ($i = 0; $i -lt $columns.Length; $i++) {
                $value = $reader[$i]
                $row[$columns[$i]] = $(if ($value -isnot [DBNull]) { $value } else { $null })
            }

            Write-Output (New-Object PSObject -Property $row)
        }
    }
    finally {
        if ($reader -ne $null) {
            $reader.Dispose()
        }

        if ($command -ne $null) {
            $command.Dispose()
        }

        if ($connection -ne $null) {
            $connection.Dispose()
        }
    }
}

Export-ModuleMember -Function Invoke-Sql