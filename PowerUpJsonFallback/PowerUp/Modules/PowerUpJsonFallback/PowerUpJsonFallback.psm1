Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

# We only need those if we are still using PowerShell 2

function ConvertFrom-Json([Parameter(Mandatory=$true)] [string] $inputObject) {
    # load the required dll
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
    $deserializer = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
    $data = $deserializer.DeserializeObject($inputObject)
    return $data | % { New-Object PSObject -Property $_ }
}

function ConvertTo-Json([Parameter(Mandatory=$true)] [object] $inputObject) {   
    # load the required dll
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
    $serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    return $serializer.Serialize($inputObject)
}

Export-ModuleMember -Function ConvertFrom-Json, ConvertTo-Json