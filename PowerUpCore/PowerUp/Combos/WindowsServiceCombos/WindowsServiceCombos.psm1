$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

Add-Type -TypeDefinition "public enum WindowsServiceCopyMode { Default, NoMirror, NoCopy }"

function Invoke-ComboStandardWindowsService($options) {
    Import-Module powerupfilesystem
    Import-Module powerupwindowsservice
    Import-Module PowerUpUtilities

    Merge-Defaults $options @{
        destinationfolder = { $options.servicename }
        sourcefolder = { $options.destinationfolder }
        fulldestinationpath = { Join-Path $options.serviceroot $options.destinationfolder }
        fullsourcepath = { Join-Path (Get-Location) $options.sourcefolder }
        exename = { "$($options.servicename).exe" }
        copymode = [WindowsServiceCopyMode]::Default
        beforecopy = { {} }
        aftercopy = { {} }
        failureoptions = @{
            enablerecovery = $false
            resetfailurecountafterseconds = 86400
            firstactiondelayseconds = 0
            secondaction = $null
            secondactiondelayseconds = 0
            subsequentaction = $null
            subsequentactiondelayseconds = 0
        }
        donotstartimmediately = $false
        '[ordered]' = @('destinationfolder','sourcefolder','fulldestinationpath','fullsourcepath')
    }
    
    if ($options.ContainsKey("copywithoutmirror")) {
        Write-Error "Option 'copywithoutmirror' is obsolete, use 'copymode' (Default/NoMirror) instead."
    }
    
    if ($options.ContainsKey("serviceaccountusername")) {
        Write-Error "Option 'serviceaccountusername' is obsolete, use 'credentials' (PSCredential) instead."
    }
    
    Write-Host "Service options: $($options | Out-String)"

    Uninstall-Service $options.servicename

    &($options.beforecopy)

    # same as website, worth consolidating at some point
    $copymode = [WindowsServiceCopyMode]$options.copymode
    switch ($copymode) {
        'Default'  { copy-mirroreddirectory $options.fullsourcepath $options.fulldestinationpath; break }
        'NoMirror' { copy-directory $options.fullsourcepath $options.fulldestinationpath; break }
        'NoCopy'   { Write-Host "Copying is not required for this service (copymode = NoCopy)"; break }
        default    { Throw "Copy mode not recognized: $copymode." }
    }

    &($options.aftercopy)

    Install-Service $options.servicename (Join-Path $options.fulldestinationpath $options.exename)
    if ($options.credentials) {        
        Set-ServiceCredentials $options.servicename $options.credentials
    }

    if ($options.failureoptions.enablerecovery) {
        $recovery = $options.failureoptions
        Set-ServiceFailureOptions $options.servicename $recovery.resetfailurecountafterseconds $recovery.firstaction $recovery.firstactiondelayseconds $recovery.secondaction $recovery.secondactiondelayseconds $recovery.subsequentaction $recovery.subsequentactiondelayseconds
    }

    if ($options.donotstartimmediately) {
        Write-Host "Service will not be started (donotstartimmediately = true)."
        return;
    }

    try {
        Start-Service $options.servicename
    }
    catch {
        Write-Error "Failed to start service $($options.servicename): $_" -ErrorAction Continue
        $logs = (Get-EventLog Application -Source $options.servicename -ErrorAction SilentlyContinue | Select-Object -First 5)
        if ($logs) {
            Write-Host "Recent Application event logs for $($options.servicename):"
            $logs | % {
                Write-Host "$($_.TimeGenerated) $($_.EntryType)" -ForegroundColor DarkMagenta
                Write-Host $_.Message
                Write-Host ""
            }
        }
        throw
    }
}
