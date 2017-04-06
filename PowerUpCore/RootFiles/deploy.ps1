. .\_powerup\Combos\StandardDeploymentTasks.ps1

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

framework '4.0'

task Deploy {
    Invoke-ComboRemotableTask DeployWeb @{
        remote = (Test-Setting execute.remotely -IsTrue)
        servers = ${web.server}
        share = ${web.server.share}
        workingSubFolder = ${project.name}
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
    
    Invoke-ComboStandardWebsite $options
}