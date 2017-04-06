Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Invoke-RemoteTasks(
    [Parameter(Mandatory = $true)][string] $serverName,
    [Parameter(Mandatory = $true)][string] $shareName,
    [Parameter(Mandatory = $true)][string] $packageName,
    [Parameter(Mandatory = $true)][string] $operation,
    [string] $tasks,
    [string] $profile
) {
    # TODO: Update to PowerUp remote
    Import-Module PowerUpUtilities
    Copy-PowerUpPackage -ServerName $serverName -ShareName $shareName -PackageName $packageName

    $hostName = [Net.DNS]::GetHostEntry($serverName).HostName
    Write-Host "===== Beginning execution of tasks $tasks on $serverName ($hostName) ====="  -ForegroundColor White    
    $session = New-PSSession -ComputerName $hostName
    try {
        Invoke-Command -Session $Session -ScriptBlock {
            param (
                $shareName,
                $packageName,
                $operation,
                $profile,
                $tasks
            )
            $ErrorActionPreference = 'Stop'

            Write-Host "Remote session on $([Net.Dns]::GetHostName())"
            $sharePath = ((Get-WmiObject -Class Win32_Share) | ? { $_.Name -eq $shareName }).Path
            Set-Location "$sharePath\$packageName"
            # TODO: consolidate with PowerUpMeta
            .\_powerup\RunPSake.ps1 -Operation $operation -OperationProfile $profile -Task $tasks | Out-Default
            if ($LastExitCode -ne 0) {
                Write-Error "RunPSake.ps1 failed with exit code $LastExitCode."
            }
        } -ArgumentList $shareName,$packageName,$operation,$profile,$tasks
    }
    finally {
        Remove-PSSession -Session $session
    }
    Write-Host "====== Finished execution of tasks $tasks on $serverName ====="  -ForegroundColor White
}

$packageAlreadyCopied = @{}
function Copy-PowerUpPackage(
    [Parameter(Mandatory = $true)] [string] $serverName,
    [Parameter(Mandatory = $true)] [string] $shareName,
    [Parameter(Mandatory = $true)] [string] $packageName
) {
    Import-Module PowerUpFileSystem

    $remoteRoot = "\\$serverName\$shareName"
    $remotePath = "$remoteRoot\$packageName"
    $packagePath = Get-Location

    $packageCopyKey = "$packagePath::$serverName::$remotePath"
    $packageCopyRequired = !$packageAlreadyCopied[$packageCopyKey]
    if ($packageCopyRequired) {	
        Write-Host "Copying deployment package to $remotePath"
        Copy-MirroredDirectory $packagePath $remotePath
        $packageAlreadyCopied[$packageCopyKey] = $true
    }
    else {
        Write-Host "Deployment package was already copied to $remotePath in this session."
    }
}

Export-ModuleMember -Function Invoke-RemoteTasks