function Execute-HttpCommand($target,$verb="GET", $content="") {

    function FullStatusCode($response) {
        return "$([int]$response.StatusCode) $($response.StatusDescription)";
    }
    
    function GetResponseString($response){
        $stream = $response.GetResponseStream()
        $reader = new-object System.IO.StreamReader($stream)
        $results = $reader.ReadToEnd();
        return $results;
    }
 
    $webRequest = [System.Net.WebRequest]::Create($target)
    $webRequest.Timeout = 10 * 60 * 1000 # 10 minutes
    $webRequest.Method = $verb
	

    write-host "Http Url: $target"
    write-host "Http Verb: $verb"

    if($content.length -gt 0) {
         #write-host "Http Content: $content"
         $encodedContent = [System.Text.Encoding]::UTF8.GetBytes($content)
         $webRequest.ContentLength = $encodedContent.length
		 $webRequest.ContentType="application/json; charset=utf-8"
         $requestStream = $webRequest.GetRequestStream()
         $requestStream.Write($encodedContent, 0, $encodedContent.length)
         $requestStream.Close()
    }
 
    try{
        $response = $webRequest.GetResponse();
        if($response -ne $null) {
			write-host "$(FullStatusCode($response))"
            return GetResponseString($response)
        }
    }
    catch [System.Net.WebException] {
        $response = $_.Exception.Response
        if ($response -eq $null) {
          throw;
        }
        $error =GetResponseString($response)

        write-host "$(FullStatusCode($response))"
        throw "Request to $target failed ($(FullStatusCode($response))): $error"
    }
    finally {
        if ($response -ne $null) {
            $response.Close();
        }
    }
}

function DeserializeFromJson($json)
{    
	# load the required dll
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
    $deserializer = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
    $dict = $deserializer.DeserializeObject($json)
    
    return $dict
}

function SerializeToJson($dict)
{   
    # load the required dll
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
    $serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $json = $serializer.Serialize($dict)
    return $json
}

export-modulemember -function Execute-HttpCommand,
							  DeserializeFromJson,
							  SerializeToJson