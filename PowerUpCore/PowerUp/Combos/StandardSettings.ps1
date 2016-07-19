({
    # Importing profile settings    
    Import-Module PowerUpSettings

    $profileSettings = Read-Settings settings.txt ${powerup.profile}  -Raw
    if (Test-Path "package.id") {
        # TODO: Do we still use/need this?
        $packageInformation = Read-Settings "package.id" "PackageInformation" -Raw
        if ($packageInformation) {
            $packageInformation.GetEnumerator() | ? { !$_.Key.StartsWith('_') } | % {
                $profileSettings.Add($_.Key, $_.Value)
            }
        }
    }

    Import-Settings $profileSettings
}).Invoke()

({
    Import-Module PowerUpUtilities
    Set-DynamicVariable 'serverSettingsScriptBlock' -Scope Global -Options Constant -Get {
        Write-Warning "Variable 'serverSettingsScriptBlock' is obsolete and should not be used (note that getServerSettings option is also obsolete, so there is no use case for it anyway)."
        return {}
    }
}).Invoke()