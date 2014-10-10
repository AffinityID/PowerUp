Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Merge-ProfileSpecificFiles($deploymentProfile) {
    $currentPath = Get-Location

    if ((Test-Path $currentPath\_profilefiles\$deploymentProfile -PathType Container) -eq $true) {
        Copy-Item $currentPath\_profilefiles\$deploymentProfile\* -destination $currentPath\ -recurse -force   
    }
}

function Merge-Templates($profile) {
    Import-Module PowerUpFileSystem

    $currentPath = Get-Location
    if (!(Test-Path $currentPath\_templates\ -PathType Container)) {
        Write-Host "Path $currentPath\_templates was not found -- templates would not be copied."
        return
    }

    Copy-Directory $currentPath\_templates $currentPath\_templatesoutput\$profile
    Get-ChildItem $currentPath\_templatesoutput\$profile -Recurse | ? { !($_.PSIsContainer) } | % {
        Expand-Template $_.FullName
    }

    if ((Test-Path $currentPath\_templatesoutput\$profile -PathType Container)) {
        Copy-Item $currentPath\_templatesoutput\$profile\* -destination $currentPath\ -recurse -force    
    }
}

function Expand-Template($path) {
    Write-Host "Expanding template '$path'"
    $content = [IO.File]::ReadAllText($path)
    $errors = @()
    $content = [regex]::Replace($content, '\$(?:{.*}|\(.*\))', {
        param ($match)
        try {
            $result = (Invoke-Expression "Set-StrictMode -Version 2; `$ErrorActionPreference = 'Stop'; `"$($match.Value)`"")
        }
        catch {
            $errors += "$($match.Value): $_"
            $result = 'error!'
        }
        Write-Host "  $($match.Value) => $result"
        return $result
    })
    
    if ($errors.Length -gt 0) {
        Write-Error "Failed to expand values in $path`:`r`n  $($errors -join "  `r`n")"
    }

    [IO.File]::WriteAllText($path, $content)
}

Export-ModuleMember -function Merge-Templates, Merge-ProfileSpecificFiles