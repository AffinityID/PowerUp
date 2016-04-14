Import-Module PowerUpUtilities

Add-Type -TypeDefinition "public enum WebsiteCopyMode { Default, NoMirror, NoCopy }"

function Invoke-ComboStandardWebsite([Parameter(Mandatory=$true)][hashtable] $options) {
    Import-Module PowerUpFileSystem
    Import-Module PowerUpWeb
    Import-Module PowerUpWebRequest
    
    Set-StrictMode -Version 2
        
    # apply defaults
    Merge-Defaults $options @{
        stopwebsitefirst = $true;
        recreatewebsite = $true;
        port = 80;
        copymode = {
            if ($options.ContainsKey("copywithoutmirror")) {
                Write-Warning "Option 'copywithoutmirror' is obsolete, use 'copymode' (Default/NoMirror) instead."
                if ($options.copywithoutmirror) {
                    return [WebsiteCopyMode]::NoMirror
                }
            }
            
            return [WebsiteCopyMode]::Default
        };
        beforecopy = { {} };
        destinationfolder = { $options.websitename };
        sourcefolder = { $options.destinationfolder };
        fulldestinationpath = { "$($options.webroot)\$($options.destinationfolder)" };
        fullsourcepath = { "$(get-location)\$($options.sourcefolder)" };
        aftercopy = { {} };
        apppool = @{
            executionmode = "Integrated";
            dotnetversion = "v4.0";
            name = { $options.websitename };
            username = $null;
            identity = $null
        };
        bindings = @(@{});
        virtualdirectories = @();
        appfabricapplications = @();
        backup = @{
            enabled = $false
            location = { "$($options.sourcefolder)\backup" }
            media = $false
            code = { Write-Warning "No backup code found"; @() }
        };
        startwebsiteafter = $true;
        tryrequestwebsite = $false;
        '[ordered]' = @('destinationfolder','sourcefolder','fulldestinationpath','fullsourcepath','backup')
    }
    
    $options.bindings | % {
        Merge-Defaults $_ @{
            protocol = "http"
            ip = "*"
            port = { if ($_.protocol -eq 'https') { 443 } else { 80 } }
            useselfsignedcert = $false
            certname = { $options.websitename }
            usesni = $false
            '[ordered]' = @('protocol','port')
        }
    }
    
    $options.virtualdirectories | % {
       Merge-Defaults $_ @{
            destinationfolder = { "$($options.destinationfolder)\$($_.directoryname)" }
            fulldestinationpath = { "$($options.webroot)\$($_.destinationfolder)" }
            sourcefolder = $null
            fullsourcepath = { if ($_.sourcefolder) { "$(get-location)\$($_.sourcefolder)" } else { $null } }
            isapplication = $false
            useapppoolidentity = {
                if ($options.ContainsKey("useapppool")) {
                    Write-Warning "Option 'useapppool' is obsolete, use 'useapppoolidentity' instead."
                    return $options.useapppool
                }
                
                return $false
            }
            apppool = $null
            stopappoolfirst = $false
            '[ordered]' = @('sourcefolder','fullsourcepath','destinationfolder','fulldestinationpath')
        }
        
        if ($_['apppool'] -ne $null) {
            Merge-Defaults $_.apppool @{
                name = { Write-Error "AppPool name must be specified for directory $($_.destinationfolder)."; }
                executionmode = "Integrated"
                dotnetversion = "v4.0"
                username = $null
                identity = $null
            }
        }
    }
        
    Write-Host "Website options: $($options | Out-String)"
    
    if($options.stopwebsitefirst)
    {
        stop-apppoolandsite $options.apppool.name $options.websitename
    }
    
    if ($options.backup.enabled)
    {
        if (!(Test-Path -path $options.backup.location)) {
            New-Item $options.backup.location -type directory
            Write-Host "Just created newDeploy\backup folder - $options.backup.location"
        }
        if ($options.backup.media)
        {
            cd "$($options.fulldestinationpath)\media";
            Get-ChildItem "$($options.fulldestinationpath)\media" -Recurse | Write-Zip -OutputPath "$($options.backup.location)\media.zip" -Level 1
        }
            
        $pathArray = @()
        foreach($backup in $options.backup.code)
        {
            if ((Test-Path "$($options.fulldestinationpath)\$($backup.folder)")) {
                $pathArray += "$($options.fulldestinationpath)\$($backup.folder)"
            }
        }
        Write-Host "Backing up $($pathArray) to $($options.backup.location)\code.zip"
        Write-Zip -Path $pathArray -OutputPath "$($options.backup.location)\code.zip" -IncludeEmptyDirectories -Level 1
    }

    &($options.beforecopy)

    $copymode = [WebsiteCopyMode]$options.copymode
    switch ($copymode) {
        'Default'  { copy-mirroreddirectory $options.fullsourcepath $options.fulldestinationpath; break }
        'NoMirror' { copy-directory $options.fullsourcepath $options.fulldestinationpath; break }
        'NoCopy'   { Write-Host "Copying is not required for this website (copymode = NoCopy)"; break }
        default    { Throw "Copy mode not recognized: $copymode." }
    }

    &($options.aftercopy)
    
    $setAppPoolIdentity = {
        param ($apppool)
        if ($apppool.username) {
            set-apppoolidentitytouser $apppool.name $apppool.username $apppool.password
        }
        if ($apppool.identity -eq "NT AUTHORITY\NETWORK SERVICE") {
            set-apppoolidentityType $apppool.name 2 #2 = NetworkService
        }
    }

    if ($options.apppool) {
        set-webapppool $options.apppool.name $options.apppool.executionmode $options.apppool.dotnetversion
        &$setAppPoolIdentity($options.apppool)
    }
    
    if ($options.apppool.idletimeout -ne $null) {
        Set-AppPoolIdleTimeout $options.apppool.name $options.apppool.idletimeout
    }

    $firstBinding = $options.bindings[0]
    set-website $options.websitename $options.apppool.name $options.fulldestinationpath $firstBinding.url $firstBinding.protocol $firstBinding.ip $firstBinding.port (!$options.recreatewebsite)
    
    foreach($binding in $options.bindings) {
        if($binding.protocol -eq "https") {
            if ($binding.useselfsignedcert) {
                Write-Host "Set-SelfSignedSslcCertificate $($binding.certname)"
                Set-SelfSignedSslCertificate $binding.certname
            }

            $sslHost = $(if ($binding.usesni) { $binding.url } else { '*' })
            Set-SslBinding $binding.certname -IP $binding.ip -Port $binding.port -Host $sslHost
        }
        Set-WebSiteBinding `
            -WebSiteName $options.websitename `
            -HostHeader $binding.url `
            -Protocol $binding.protocol `
            -IPAddress $binding.ip `
            -Port $binding.port `
            -UseSni:$($binding.usesni)
    }
    
    if($options.virtualdirectories)
    {
        foreach($virtualdirectory in $options.virtualdirectories)
        {
            write-host "Deploying virtual directory $($virtualdirectory.directoryname) to $($options.websitename)."

            if ($virtualdirectory.fullsourcepath)
            {
                copy-mirroreddirectory $virtualdirectory.fullsourcepath $virtualdirectory.fulldestinationpath
            }
            
            if ($virtualdirectory.isapplication) {
                $apppool = $virtualdirectory.apppool
                if ($apppool) {
                    Set-WebAppPool $apppool.name $apppool.executionmode $apppool.dotnetversion
                    &$setAppPoolIdentity($apppool)
                }
                else {
                    $apppool = $options.apppool
                }
                New-WebApplication $options.websitename $apppool.name $virtualdirectory.directoryname $virtualdirectory.fulldestinationpath -Force
            }
            else {
                if ($virtualdirectory.apppool) {
                    throw "Cannot use apppool option for directory $($virtualdirectory.directoryname) as it is not an application."
                }
                Register-VirtualDirectory $options.websitename $virtualdirectory.directoryname $virtualdirectory.fulldestinationpath
            }
            
            if ($virtualdirectory.useapppoolidentity)
            {
                write-host "Switching virtual directory $($options.websitename)/$($virtualdirectory.directoryname) to use app pool identity for anonymous authentication."
                set-webproperty "$($options.websitename)/$($virtualdirectory.directoryname)" "/system.WebServer/security/authentication/AnonymousAuthentication" "username" ""
            }
        }
    }
    
    # if($options.appfabricapplications)
    # {
    #     foreach($application in $options.appfabricapplications)
    #     {
    #         new-webapplication $options.websitename $options.apppool.name $application.virtualdirectory "$($options.fulldestinationpath)\$($application.virtualdirectory)" 
    #         Set-ASApplication -SiteName $options.websitename -VirtualPath $application.virtualdirectory -AutoStartMode All -EnableApplicationPool -Force
    #         set-apppoolstartMode $options.websitename 1
    #     }
    # }
    
    if($options.startwebsiteafter)
    {
        start-apppoolandsite $options.apppool.name $options.websitename
    }

    if($options.tryrequestwebsite)
    {
        foreach ($binding in $options.bindings)
        {
            $bindingRootUrl = "$($binding.protocol)://$($binding.url):$($binding.port)"
            $ignoreSslErrors = $binding.useselfsignedcert
            Send-HttpRequest GET $bindingRootUrl -IgnoreSslErrors:$ignoreSslErrors
        
            if($options.virtualdirectories)
            {
                foreach ($directory in $options.virtualdirectories)
                {
                    Send-HttpRequest GET "$bindingRootUrl/$($virtualdirectory.directoryname)" -IgnoreSslErrors:$ignoreSslErrors
                }
            }
        }
    }
}
