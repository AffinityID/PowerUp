Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$zipExe = "$PSScriptRoot\7za.exe"

function Compress-ZipFile(
    [Parameter(Mandatory=$true)][string] $sourcePath,
    [Parameter(Mandatory=$true)][string] $destinationPath,
) {
    $cmd = "$zipExe a -r -tzip $destinationPath $sourcePath"
    Write-Host $cmd
    Invoke-Expression $cmd
}

function Expand-ZipFile(
    [Parameter(Mandatory=$true)][string] $sourceZip
) {
    $cmd = "$zipExe x -y $sourceZip"
    Write-Host $cmd
    Invoke-Expression $cmd
}

Export-ModuleMember -function Compress-ZipFile, Expand-ZipFile