param (
    [string] $container = 'PowerUp'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

$key = New-Object byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($key)

$encryptedString = (Read-Host "Enter the value to encrypt" -AsSecureString) | ConvertFrom-SecureString -Key $key

$csp = New-Object Security.Cryptography.CspParameters
$csp.KeyContainerName = $container
$csp.KeyNumber = 1    # Exchange
$csp.ProviderType = 1 # PROV_RSA_FULL
$csp.Flags = [Security.Cryptography.CspProviderFlags]::UseMachineKeyStore
$rsa = New-Object Security.Cryptography.RSACryptoServiceProvider(4096, $csp)
$rsa.PersistKeyInCsp = $true
$encryptedKey = $rsa.Encrypt($key, $true)

Write-Output "$($container):$([Convert]::ToBase64String($encryptedKey)):$($encryptedString)"