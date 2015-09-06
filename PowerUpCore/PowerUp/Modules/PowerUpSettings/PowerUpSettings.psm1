Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

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
    Import-Module PowerUpUtilities

    $from = $(if($settings['_source']) {
        $sourceSection = $settings._source.section
        $sourceFileName = [IO.Path]::GetFileName($settings._source.path)
        " ($sourceFileName, $sourceSection)"
    } else { '' })
    
    Write-Host "Importing settings$($from):"

    $maxNameLength = [int]($settings.Keys | %{$_.Length} | sort -Descending | select -First 1)
    $unresolved = @{}
    $processed = Resolve-SettingsInternal $settings -OnUnresolved {
        param ($name, $value, $message)
        $unresolved[$name] = $message
        return $value
    }
    $processed.GetEnumerator() | % {
        $name = $_.Key
        Write-Host "  $($name.PadRight($maxNameLength)) $($_.Value)"
        $unresolvedMessage = $unresolved[$name]
        if (!$unresolvedMessage) {
            Set-Variable -Name $name -Scope Global -Option Constant -Value $_.Value
        }
        else {
            # This would only be thrown if anything attempts to use it
            Set-DynamicVariable -Name $name -Scope Global -Option Constant -Get { throw $unresolvedMessage }.GetNewClosure()
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