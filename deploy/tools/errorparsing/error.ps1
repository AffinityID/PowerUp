$path = 'C:\Atlassian\Application Data\bamboo-home\'
$buildkey = cat .\build-info.txt | Select-Object -First 1
$buildnumber = cat .\build-info.txt | Select-Object -Last 1
$1 = Select-String $path\xml-data\builds\$buildkey\download-data\build_logs\$buildkey-$buildnumber.log -Pattern "Error Occurred"
$1a = Select-String $path\xml-data\builds\$buildkey\download-data\build_logs\$buildkey-$buildnumber.log -pattern "Error Occurred" -Context 0,12
Write-host $1a -ForegroundColor Red
if ($1 -eq $null) {write-host No Errors; Exit 0}
else {write-host ERROR; Exit 1}