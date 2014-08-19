Set-StrictMode -Version 2

function Merge-Defaults($target, $defaults)
{
    $orderedDefaults = $defaults.GetEnumerator()
    if ($defaults.ContainsKey("[ordered]"))
    {
        # Sort-Object here is a hack. PowerShell 2 does not provide [ordered],
        # so I allow users to provide order
        $order = $defaults['[ordered]']
        $orderedDefaults = $orderedDefaults | Sort-Object @{expression = {[array]::IndexOf($order, $_.Key)}}
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

Export-ModuleMember -function Merge-Defaults