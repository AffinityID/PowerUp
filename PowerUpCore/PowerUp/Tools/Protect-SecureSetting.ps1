$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

# Can be run as one-line without the above
(Read-Host "Enter the value to encrypt" -AsSecureString) | ConvertFrom-SecureString | % { "$([Environment]::MachineName):$([Environment]::UserDomainName)\$([Environment]::UserName):$_" }