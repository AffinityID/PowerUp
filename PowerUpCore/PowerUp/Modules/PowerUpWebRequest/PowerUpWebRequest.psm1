Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Send-HttpRequest(
    [Parameter(Mandatory=$true)] [string] $method,
    [Parameter(Mandatory=$true)] [string] $url,
    [string] $content = "",
    [string] $contentType = "application/json",
    [Hashtable] $headers = @{},
    [switch] $ignoreSslErrors = $false
) {
    Import-Module PowerUpUtilities

    function FullStatusCode($response) {
        return "$([int]$response.StatusCode) $($response.StatusDescription)";
    }
    
    function GetResponseString($response){
        $stream = $response.GetResponseStream()
        $results = (Use-Object (New-Object System.IO.StreamReader($stream)) {
            param ($stream)
            $stream.ReadToEnd();
        })
        return $results;
    }
 
    $request = [System.Net.WebRequest]::Create($url)
    $request.Method = $method
    $request.Timeout = 10 * 60 * 1000 # 10 minutes

    if ($ignoreSslErrors) {
        $request.ServerCertificateValidationCallback = { return $true }
    }

    write-Host "$method $url"
    foreach ($header in $headers.GetEnumerator()) {
        Write-Host "$($header.Key): $($header.Value)"
        $request.Headers.Add($header.Key, $header.Value);
    }
    
    if ($content) {
        $contentBytes = [System.Text.Encoding]::UTF8.GetBytes($content)
        $request.ContentLength = $contentBytes.Length
        $request.ContentType = "$contentType; charset=utf-8"
        Write-Host "Content-Type: $($request.ContentType)"
        Write-Host "Content-Length: $($request.ContentLength)"
        Write-Host ""
        write-Host $content
        Use-Object $request.GetRequestStream() {
            param ($stream)
            $stream.Write($contentBytes, 0, $contentBytes.Length)
        }
    }
    else {
        $request.ContentLength = 0
    }
    
    try {
        $response = $request.GetResponse();
        if ($response -ne $null) {
            Write-Host (FullStatusCode $response)
            return GetResponseString($response)
        }
    }
    catch [System.Net.WebException] {
        $response = $_.Exception.Response
        if ($response -eq $null) {
          throw;
        }
        $error = GetResponseString($response)

        write-Host (FullStatusCode $response)
        throw "Request to $url failed ($(FullStatusCode $response)): $error"
    }
    finally {
        if ($response -ne $null) {
            $response.Close();
        }
    }
}

Export-ModuleMember -Function Send-HttpRequest