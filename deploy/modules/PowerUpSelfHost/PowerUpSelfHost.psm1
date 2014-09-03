Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Revoke-SelfHostUrl([Parameter(Mandatory=$true)][string] $url)
{
    Write-Host "Revoking permissions to host $url"
    netsh http delete urlacl url="$url"
    # TODO: parse result so that errors are reported, but "does not exist" can be ignored
}

function Grant-SelfHostUrl(
    [Parameter(Mandatory=$true)][string] $url,
    [Parameter(Mandatory=$true)][string] $user
)
{
    Write-Host "Granting permissions to host $url for user $user"
    netsh http add urlacl url="$url" user="$user"
    if ($LastExitCode -ne 0) {
        Write-Error "netsh failed, see previous messages for details."
    }
}