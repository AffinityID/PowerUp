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
    $inputObject = [PowerUpJson]::Clean($inputObject)

    # load the required dll
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
    $serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    return $serializer.Serialize($inputObject)
}

Add-Type -TypeDefinition '
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;

public static class PowerUpJson {
    public static object Clean(object value) {
        if (value == null)
            return value;

        if (value is string)
            return value; // avoids confusion with Enumerable below

        var hashtable = value as Hashtable;
        if (hashtable != null) {
            var cleaned = new Hashtable();
            foreach (DictionaryEntry entry in hashtable) {
                cleaned[entry.Key] = Clean(entry.Value);
            }
            return cleaned;
        }

        var enumerable = value as IEnumerable;
        if (enumerable != null) {
            var cleaned = new List<object>();
            foreach (var item in enumerable) {
                cleaned.Add(Clean(item));
            }
            return cleaned;
        }

        var psObject = value as PSObject;
        if (psObject != null) {
            if (psObject.BaseObject != null) {
                return Clean(psObject.BaseObject);
            }

            var cleaned = new Hashtable();
            foreach (var property in psObject.Properties) {
                cleaned[property.Name] = Clean(property.Value);
            }
            return cleaned;
        }

        return value;
    }
}
'

Export-ModuleMember -Function ConvertFrom-Json, ConvertTo-Json