function Add-FontsInDirectory([string]$path)
{
	$fontinstalldir = dir $path		
	foreach($fontFile in $fontinstalldir) {
		Write-Host $fontFile.fullname		
		& "$PSScriptRoot\FontInstaller.exe" "$fontFile.fullname"
    }
}

export-modulemember -function Add-FontsInDirectory