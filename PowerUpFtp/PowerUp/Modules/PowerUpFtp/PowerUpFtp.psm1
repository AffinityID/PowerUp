Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

$ftpush = "$PSScriptRoot\tools\ftpush.exe"

function Invoke-Ftpush(
    [Parameter(Mandatory=$true)] [string] $sourcePath,
    [Parameter(Mandatory=$true)] [Uri] $ftpUrl,
    [Parameter(Mandatory=$true)] [PSCredential] $credentials,
    [string[]] $excludes,
    [switch] $active,
    [switch] $interimRetryLogin
) {
    Import-Module PowerUpUtilities
    $passwordEnvVarName = "PWP_FTP_PASS_$([Guid]::NewGuid().ToString('N'))"
    try {    
        $password = $credentials.GetNetworkCredential().Password
        New-Item -Name $passwordEnvVarName -value $password -ItemType Variable -Path env: | Out-Null
        $command = "$ftpush " + (Format-ExternalArguments @{
            '--source'   = $sourcePath
            '--target'   = $ftpUrl
            '--username' = $credentials.UserName
            '--passvar'  = $passwordEnvVarName
            '--exclude'  = $excludes
            '--active'   = $active
            '--interim-retry-login' = $interimRetryLogin
        } -EscapeAll)
        Invoke-External $command
    }
    finally {
        Remove-Item "env:$passwordEnvVarName"
    }
}

Export-ModuleMember -Function Invoke-Ftpush