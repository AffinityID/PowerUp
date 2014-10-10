. .\_powerup\Combos\StandardSettings.ps1

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

task ProcessTemplates {
    Import-Module PowerUpTemplates
    
    Write-Host 'Processing profile-specifc files'
    Merge-ProfileSpecificFiles ${powerup.profile}
    
    Write-Host 'Processing templates'
    Write-Host "Substituting and copying templated files"
    Merge-Templates ${powerup.profile}
}

task default -depends ProcessTemplates, deploy