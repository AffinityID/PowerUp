Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Grant-SelfHostUrl(
    [Parameter(Mandatory=$true)][string] $url,
    [Parameter(Mandatory=$true)][string] $user
) {
    Write-Host "Granting permissions to host $url for user $user"
    netsh http add urlacl url="$url" user="$user"
    if ($LastExitCode -ne 0) {
        Write-Error "netsh failed, see previous messages for details."
    }
}