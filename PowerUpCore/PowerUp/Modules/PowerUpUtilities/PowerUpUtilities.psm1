Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

Add-Type @"
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Management.Automation;

public class PowerUpDynamicVariable : PSVariable {
    private readonly ScriptBlock _getter;
    private readonly ScriptBlock _setter;
    
    public PowerUpDynamicVariable(string name, ScriptBlock getter, ScriptBlock setter, ScopedItemOptions options)
        : base(name, null, options)
    {
        _getter = getter;
        _setter = setter;
    }

    public override object Value {
        get {
            if (_getter == null)
                throw new NotSupportedException("Dynamic variable " + Name + " has no get block and so can't be read.");
        
            Collection<PSObject> results = _getter.Invoke();
            if (results.Count == 1) {
                return results[0];
            }
            else {
                PSObject[] returnResults = new PSObject[results.Count];
                results.CopyTo(returnResults, 0);
                return returnResults;
            }
        }
        set {
            if (_setter == null)
                throw new NotSupportedException("Dynamic variable " + Name + " has no set block and so can't be set.");
        
            _setter.Invoke(value);
        }
    }
}
"@

function Set-DynamicVariable(
    [Parameter(Mandatory=$true)] [string] $name,
    [ScriptBlock] $get = $null,
    [ScriptBlock] $set = $null,
    [Management.Automation.ScopedItemOptions] $options = [Management.Automation.ScopedItemOptions]::None,
    [string] $scope = 'Local'
) {
    $variable = New-Object PowerUpDynamicVariable("$($scope):$name",$get,$set,$options)
    $ExecutionContext.SessionState.PSVariable.Set($variable)
}

function Merge-Defaults(
    [Parameter(Mandatory=$true)] [Hashtable] $target,
    [Parameter(Mandatory=$true)] [Hashtable] $defaults
) {
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
                    $newValue = &$newValueBlock
                    if ($newValue -is [Hashtable]) {
                        Merge-Defaults $oldValue $newValue
                    }

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
    $failed = $false
    try {
        return (&$action $object)
    }
    catch {
        $failed = $true
        throw
    }
    finally {
        if (!$failed) {
            $object.Dispose();
        }
        else {
            # avoiding overwrite of the original exception
            try { $object.Dispose(); } catch {}
        }
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
        $command += " 2>&1"
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

function Format-ExternalArguments(
    [Parameter(Mandatory=$true)] [hashtable] $arguments,
    [switch] $escapeAll = $false
) {
    $parts = $arguments.GetEnumerator() | 
        ? {
            $value = $_.Value
            return ($value -ne $null) -and
                    ($value -ne '') -and
                    ($value -isnot [switch] -or $value)
        } |
        % { 
            $argument = $_.Key
            $value = $_.Value
            if ($value -isnot [switch]) {
                if ($escapeAll) {
                    $value = Format-ExternalEscaped $value
                }
                
                $argument += " " + $value
            }
            
            return $argument
        }
        
    return $parts -join ' '
}

function Format-ExternalEscaped(
    [object] $argument
) {
    if ($argument -eq $null -or $argument -eq '') {
        return $argument
    }

    if ($argument -is [Collections.IEnumerable] -and $argument -isnot [string]) {
        return ($argument.GetEnumerator() | % { Format-ExternalEscaped $_ }) -join ' '
    }

    if ($argument -match '[`"]') {
        return "'$($argument.Replace('"', '\"').Replace("'", "''"))'"
        # " # this comment is just a highlighting fix for notepad 2
    }

    return "`"$argument`""
}

function Wait-Until(
    [Parameter(Mandatory=$true)] [ScriptBlock] $condition,
    [Parameter(Mandatory=$true)] [TimeSpan] $timeout,
    [TimeSpan] $waitPeriod = (New-TimeSpan -Seconds 30),
    [ScriptBlock] $beforeFirstWait
) {
    $start = Get-Date
    $firstWait = $true
    $waitSeconds = [Math]::Truncate($waitPeriod.TotalSeconds)
    
    while (!(&$condition)) {
        if ((New-TimeSpan -Start $start) -gt $timeout) {
            throw "Wait timed out."
        }

        if ($firstWait -and $beforeFirstWait) {
            &$beforeFirstWait
            $firstWait = $false
        }        
        
        Write-Host "Waiting for $waitSeconds seconds..."
        Start-Sleep $waitSeconds
    }
}

function Get-RealException(
    [Exception] $exception
) {
    $result = $exception
    while ($result -is [Management.Automation.RuntimeException] -and $result.InnerException -ne $null) {
        $result = $result.InnerException
    }

    return $result
}

Export-ModuleMember -function Set-DynamicVariable,
                               Merge-Defaults,
                               Use-Object,
                               Invoke-External,
                               Format-ExternalArguments,
                               Format-ExternalEscaped,
                               Wait-Until,
                               Get-RealException