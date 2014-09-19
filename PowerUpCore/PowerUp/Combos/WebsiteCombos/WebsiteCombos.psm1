Add-Type -TypeDefinition "public enum WebsiteCopyMode { Default, NoMirror, NoCopy }"

function Invoke-Combo-StandardWebsite($options)
{
    import-module powerupfilesystem
    import-module powerupweb
    # import-module powerupappfabric\ApplicationServer
    # import-module poweruputils
    # Import-Module Pscx
    
    Set-StrictMode -Version 2
        
    # apply defaults            
    Merge-Defaults $options @{
        stopwebsitefirst = $true;
        startwebsiteafter = $true;
        tryrequestwebsite = $false;
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
          enabled = $false;
          location = { "$($options.sourcefolder)\backup" };
          media = $false;
          umbraco = $false;
          code = { Write-Warning "No backup code found"; @() }
        };
        '[ordered]' = @('destinationfolder','sourcefolder','fulldestinationpath','fullsourcepath','backup')
    }
    
    $options.bindings | % {
        Merge-Defaults $_ @{
            protocol = "http";
            ip = "*";
            port = 80;
            useselfsignedcert = $true;
            certname = { $options.websitename }
        }
    }
    
    $options.virtualdirectories | % {
       Merge-Defaults $_ @{
            fulldestinationpath = { "$($options.webroot)\$($_.destinationfolder)" };
            sourcefolder = $null;
            fullsourcepath = { if ($_.sourcefolder) { "$(get-location)\$($_.sourcefolder)" } else { $null } };
            isapplication = $false;
            useapppool = $false;
            '[ordered]' = @('sourcefolder','fullsourcepath')
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

    set-webapppool $options.apppool.name $options.apppool.executionmode $options.apppool.dotnetversion
    
    if ($options.apppool.username)
    {
        set-apppoolidentitytouser $options.apppool.name $options.apppool.username $options.apppool.password
    }
    
    if ($options.apppool.identity -eq "NT AUTHORITY\NETWORK SERVICE")
    {
        set-apppoolidentityType $options.apppool.name 2 #2 = NetworkService
    }
    
    $firstBinding = $options.bindings[0]
    set-website $options.websitename $options.apppool.name $options.fulldestinationpath $firstBinding.url $firstBinding.protocol $firstBinding.ip $firstBinding.port (!$options.recreatewebsite)
    
    foreach($binding in $options.bindings)
    {
        if($binding.protocol -eq "https")
        {
            Set-WebsiteForSsl $binding.useselfsignedcert $options.websitename $binding.certname $binding.ip $binding.port $binding.url        
        }
        else
        {
            set-websitebinding $options.websitename $binding.url $binding.protocol $binding.ip $binding.port
        }
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
                new-webapplication $options.websitename $options.apppool.name $virtualdirectory.directoryname $virtualdirectory.fulldestinationpath
            } else {
                Register-VirtualDirectory $options.websitename $virtualdirectory.directoryname $virtualdirectory.fulldestinationpath
            }
            
            if ($virtualdirectory.useapppool)
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
        $rootUrl = "$($firstBinding.protocol)://$($firstBinding.url):$($firstBinding.port)";
        try-webrequest $rootUrl
    
        if($options.virtualdirectories)
        {
            foreach ($directory in $options.virtualdirectories) {
                try-webrequest "$rootUrl/$($virtualdirectory.directoryname)"
            }
        }
    }
}