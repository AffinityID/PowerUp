. .\_powerup\Combos\StandardDeploymentTasks.ps1

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

framework '4.0'

task Deploy {
    Invoke-ComboRemotableTask DeployWeb @{
        remote = (Test-Setting execute.remotely -IsTrue)
        servers = ${web.server}
        workingSubFolder = ${project.name}
        getServerSettings = $serverSettingsScriptBlock
    }
}

task DeployWeb {
    Import-Module WebsiteCombos
    
    $options = @{
        websitename = ${website.name}
        webroot = ${website.deployment.folder.root}
        sourcefolder = 'Web'
        bindings = @(@{
            url = ${website.name}
        });
    }
    if (Test-Setting website.apppool.username) {
        $options.apppool = @{
            username = ${website.apppool.username}
            password = ${website.apppool.password}
        };
    }
    
    Invoke-ComboStandardWebsite $options
}