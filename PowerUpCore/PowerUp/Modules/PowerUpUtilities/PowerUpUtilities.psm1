Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Merge-Defaults($target, $defaults) {
    $orderedDefaults = $defaults.GetEnumerator()
    if ($defaults.ContainsKey("[ordered]")) {
        # Sort-Object here is a hack. PowerShell 2 does not provide [ordered],
        # so I allow users to provide order
        $order = $defaults['[ordered]']
        $orderedDefaults = $orderedDefaults | sort @{expression = {[array]::IndexOf($order, $_.Key)}}
    }

    $orderedDefaults | % {
        $key = $_.Key;
        if ($key -eq '[ordered]') {
            return
        }
        
        try {    
            # The comma in else is important (in PowerShell 2 at least), see http://stackoverflow.com/a/18477004/39068
            $newValueBlock = if ($_.Value -is [ScriptBlock]) { $_.Value } else { {,$_.Value} }
            
            if ($target.ContainsKey($key)) {
                $oldValue = $target[$key];
                if ($oldValue -is [Hashtable]) {
                    Merge-Defaults $oldValue (&$newValueBlock)
                    return
                }
                
                return
            }
             
            $newValue = &$newValueBlock 
            if ($newValue -is [Hashtable]) {
                $newValueNoInnerBlocks = @{};
                Merge-Defaults $newValueNoInnerBlocks $newValue
                $newValue = $newValueNoInnerBlocks
            }
            
            $target[$key] = $newValue;
        }
        catch {
            $ex = $_.Exception;
            throw (New-Object Exception("Error while processing '$key': $($ex.Message)", $ex))
        }
    }
}

function Use-Object(
    [Parameter(Mandatory=$true)][IDisposable]$object,
    [Parameter(Mandatory=$true)][ScriptBlock]$action
) {
    try {
        &$action $object
    }
    finally {
        $object.Dispose();
    }
}

function Invoke-External {
    [CmdletBinding()]
    param ([parameter(Mandatory=$true, ValueFromRemainingArguments=$true)] $command)
    
    if ($command -is [Collections.IEnumerable] -and $command -isnot [string]) {
        $command = @($command | % { $_ })
        if (($command | measure).Count -eq 1) {
            $command = $command[0]
        }
        elseif (!($command | ? { $_ -isnot [string] })) {
            $command = $command -join ' '
        }
        else {
            $commandsWithTypes = ($command | % { "[$($_.GetType())] $_" }) -join ', '
            throw "Unsupported command list: ($commandsWithTypes)"
        }
    }

    Write-Host $command
    if ($command -is [string]) {
        Invoke-Expression $command
    }
    elseif ($command -is [ScriptBlock]) {
        $command.Invoke();
    }
    else {
        throw "Unsupported command type: " + $command.GetType()
    }
    
    if ($LastExitCode -ne 0) {
        Write-Error "$command failed with exit code $LastExitCode"
    }
}

Export-ModuleMember -function Merge-Defaults, Use-Object, Invoke-External