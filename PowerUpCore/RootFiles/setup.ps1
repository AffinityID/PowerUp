${powerup.profile} = 'Local'
. .\_powerup\Combos\StandardSettings.ps1

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

task Build {
    Import-Module PowerUpMeta
    Invoke-PowerUp build -Task Build
}

task Website {
    Import-Module WebsiteCombos

    $options = @{
        websitename = "${website.name}";
        fulldestinationpath = Resolve-Path "Web";
        copymode = [WebsiteCopyMode]::NoCopy;
        bindings = @(@{ url = "${domain.name}"; });
    }

    Invoke-ComboStandardWebsite $options
}

task Hosts {
    $path = Join-Path ([System.Environment]::GetFolderPath('System')) "drivers\etc\hosts"
    $new = "127.0.0.1 ${domain.name}"
    $content = [IO.File]::ReadAllText($path)
        
    if ($content.Contains($new)) {
        Write-Host "* Domain ${domain.name} is already registered in hosts." -ForegroundColor Green
        return
    }
    
    if (!$content.EndsWith("`r`n")) {
        $content += "`r`n"
    }
        
    $content += $new
    [IO.File]::WriteAllText($path, $content)
    Write-Host "* Registered ${domain.name} in hosts." -ForegroundColor Green
}

task Default -depends Build, Hosts, Website