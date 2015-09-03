Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

Add-Type @"
using System;
using System.Collections.ObjectModel;
using System.Management.Automation;

public class PowerUpDynamicSetting : PSVariable {
    private readonly ScriptBlock _getter;
    
    public PowerUpDynamicSetting(string name, ScriptBlock getter)
        : base(name, null, ScopedItemOptions.AllScope | ScopedItemOptions.ReadOnly)
    {
        _getter = getter;
    }

    public override object Value {
        get {
            var results = _getter.Invoke();
            if (results.Count == 1) {
                return results[0];
            }
            else {
                var returnResults = new PSObject[results.Count];
                results.CopyTo(returnResults, 0);
                return returnResults;
            }
        }
    }
}
"@

function Resolve-SettingsInternal(
    [Parameter(Mandatory=$true)] [Hashtable] $settings,
    [ScriptBlock] $onUnresolved
) {
    $resolved = @{}
    function Resolve($name) {
        if ($resolved.ContainsKey($name)) {
            return $resolved[$name]
        }
    
        $missing = @()
        $result = [regex]::Replace($settings[$name], '\${([^}]+)}', {
            param ($match)
            $refName = $match.Groups[1].Value
            if (!$settings.ContainsKey($refName)) {
                $missing += $refName
                return $match.Value
            }
            return Resolve $refName
        })
        
        $resolvedValue = $result
        if ($missing.Length -gt 0) {
            $message = "Setting '$name' references unknown setting(s): '$($missing -join "', '")'"
            if ($onUnresolved -ne $null) {
                $resolvedValue = $onUnresolved.Invoke($name, $result, $message)
            }
            else {
                throw $message
            }
        }

        $resolved[$name] = $resolvedValue
        return $result
    }

    $settings.Keys |
        ? { !$_.StartsWith('_') } |
        % { Resolve $_ } |
        Out-Null

    return $resolved
}

function Read-Settings(
    [Parameter(Mandatory=$true)] [string] $path,
    [Parameter(Mandatory=$true)] [string] $section,
    [switch] $raw
) {
    if (!(Test-Path $path)) {
        throw "Settings file '$path' does not exist."
    }

    $sections = @{}
    $lastSection = $null
    Get-Content $path | % {
        if ($_ -match '^\s*$') { return }
        if ($_ -match '^\S.*$') {
            $sectionName = $matches[0].Trim()
            $lastSection = @{}
            $sections[$sectionName] = $lastSection
            return
        }

        if ($_ -match '^\s+(?<name>\S+)(?:\s+(?<value>.+))?$') {
            if (!$lastSection) {
                throw "Failed to parse '$path': expected first section name, got '$_' instead."
            }

            $lastSection[$matches.name] = $matches.value.Trim()
        }
    }

    $default = $sections['Default']
    $current = $sections[$section]
    if (!$current) {
        throw "Section '$section' was not found in '$path'. Found section(s): $($sections.Keys -join ',')."
    }
    
    if ($default) {
        $default.GetEnumerator() | % {
            if (!$current[$_.Key]) {
                $current[$_.Key] = $_.Value
            }
        }
    }
    
    $current['_source'] = @{ path = $path; section = $section }    
    if ($raw) {
        return $current
    }
    
    return (Resolve-SettingsInternal $current)
}

function Import-Settings(
    [Parameter(Mandatory=$true)] [Hashtable] $settings
) {
    $from = $(if($settings['_source']) {
        $sourceSection = $settings._source.section
        $sourceFileName = [IO.Path]::GetFileName($settings._source.path)
        " ($sourceFileName, $sourceSection)"
    } else { '' })
    
    Write-Host "Importing settings$($from):"

    $maxNameLength = [int]($settings.Keys | %{$_.Length} | sort -Descending | select -First 1)
    $unresolved = @{}
    $resolved = Resolve-SettingsInternal $settings -OnUnresolved {
        param ($name, $value, $message)
        # This would only be thrown if anything attempts to use it
        $variable = New-Object PowerUpDynamicSetting "global:$name", { throw $message }.GetNewClosure()
        $ExecutionContext.SessionState.PSVariable.Set($variable)
        $unresolved[$name] = $true
        return $value
    }
    $resolved.GetEnumerator() | % {
        Write-Host "  $($_.Key.PadRight($maxNameLength)) $($_.Value)"
        if (!$unresolved.ContainsKey($_.Key)) {
            Set-Variable -Name $_.Key -Value $_.Value -Scope Global -Option ReadOnly
        }
    }
}

function Test-Setting(
    [Parameter(Mandatory=$true)] [string] $setting,
    [switch] $isTrue
) {
    if (!(Test-Path variable:$setting)) {
        return $false
    }

    $value = (Get-Variable -Name $setting).Value
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $false;
    }
    
    if ($isTrue) {
        return [System.Boolean]::Parse($value)
    }
    
    return $true
}

Export-ModuleMember -Function Read-Settings, Import-Settings, Test-Setting