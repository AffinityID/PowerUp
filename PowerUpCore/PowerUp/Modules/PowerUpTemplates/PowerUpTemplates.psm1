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
        $path = $_.FullName

        Write-Host "Expanding template '$path'"
        $content = [IO.File]::ReadAllText($path)
        $expanded = Expand-Template $content -OriginalPath $path
        [IO.File]::WriteAllText($path, $content)
    }

    if ((Test-Path $currentPath\_templatesoutput\$profile -PathType Container)) {
        Copy-Item $currentPath\_templatesoutput\$profile\* -destination $currentPath\ -recurse -force    
    }
}

function Expand-Template(
    [Parameter(Mandatory=$true)] [string] $content,
    [string] $originalPath = '<unknown>'
) {
    $errors = New-Object Collections.Generic.List[string]
    $regex = New-Object Regex(
@'
    \$
    (?:
        \{
          [^{}]*
          (?:
            (?:(?<CurlyOpen>\{)[^{}]*)+
            (?:(?<CurlyClose-CurlyOpen>\})[^{}]*)+
          )*
          (?(CurlyOpen)(?!))
        \}
        |
        \(
          [^()]*
          (?:
            (?:(?<ParenOpen>\()[^()]*)+
            (?:(?<ParenClose-ParenOpen>\))[^()]*)+
          )*
          (?(ParenOpen)(?!))
        \)
    )
'@, [Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace)
    $content = $regex.Replace($content, {
        param ($match)
        try {
            $result = (Invoke-Expression "Set-StrictMode -Version 2; `$ErrorActionPreference = 'Stop'; `"$($match.Value)`"")
        }
        catch {
            $errors.Add("$($match.Value): $_")
            $result = 'error!'
        }
        Write-Host "  $($match.Value) => $result"
        return $result
    })

    if ($errors.Count -gt 0) {
        Write-Error "Failed to expand values in $originalPath`:`r`n  $($errors -join "  `r`n")"
    }
    
    return $content
}

Export-ModuleMember -Function Merge-Templates,
                              Merge-ProfileSpecificFiles,
                              Expand-Template