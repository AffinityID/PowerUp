Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Grant-SelfHostUrl(
    [Parameter(Mandatory=$true)][string] $url,
    [Parameter(Mandatory=$true)][string] $user
) {
    netsh http add urlacl url="$url" user="$user"
    if ($LastExitCode -ne 0) {
        Write-Error "netsh failed, see previous messages for details."
    }
}