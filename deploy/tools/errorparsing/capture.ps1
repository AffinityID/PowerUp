param(
    [Parameter(Mandatory=$true)][String]$buildkey,
    [Parameter(Mandatory=$true)][String]$buildnumber
    )
$buildkey > build-info.txt
$buildnumber >> build-info.txt

exit 0
