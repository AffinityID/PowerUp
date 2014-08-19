function New-Share($Path, $ShareName) {
	# $Path - The full path to the share
	# $ShareName  - The share name
	try {
		$ErrorActionPreference = 'Stop'
		if (!(GET-WMIOBJECT Win32_Share | Where { $_.Name -eq $ShareName}) ){
			if ( (Test-Path $Path) -eq $false) {
				$null = New-Item -Path $Path -ItemType Directory
			}
			net share $ShareName=$Path /GRANT:Everyone`,FULL
		}
		else{
		 # Share name already exists
		write-host "$ShareName already exists"
		}
	}
	catch {
    #This will warn
		Write-Warning "Create a new share $ShareName Failed, $_"
	}
}
export-modulemember -function New-Share