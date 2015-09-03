({
    function Import-PowerUpProfileSettings() {
        Import-Module PowerUpSettings

        $profileSettings = Read-Settings settings.txt ${powerup.profile}  -Raw
        if (Test-Path "package.id") {
            # TODO: Do we still use/need this?
            $packageInformation = Read-Settings "package.id" "PackageInformation" -Raw
            if ($packageInformation) {
                foreach ($item in $packageInformation.GetEnumerator()) {
                    $profileSettings.Add($item.Key, $item.Value)
                }
            }
        }

        Import-Settings $profileSettings
    }

    Import-PowerUpProfileSettings
}).Invoke()

# This is obsolete and will be removed in the future:
$serverSettingsScriptBlock = {}