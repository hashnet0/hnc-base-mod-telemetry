#!powershell
# Copyright (c) 2020 HashNet Services

$Api_key = "[api key]"
$Container_id = "[container id]"
$URL = "https://api.hashsploit.net/telemetry/v1/hnc"

$_cpu = (Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select Average)

$Body = "container_id=" $Container_id "&kernel=windows_nt&hostname=" $env:computername "&key=value";

# Convert the message body to a byte array
$BodyBytes = [System.Text.Encoding]::UTF8.GetBytes($Body);

# Create a new web request
$WebRequest = [System.Net.HttpWebRequest]::CreateHttp($URI);

# Set the HTTP method
$WebRequest.Method = "POST";

# Set the MIME type
$WebRequest.ContentType = "application/x-www-form-urlencoded";

# Add headers
$WebRequest.Headers.Add("Api-Key", $Api_key);

# Write the message body to the request stream
$WebRequest.GetRequestStream().Write($BodyBytes, 0, $BodyBytes.Length);

$Response = $WebRequest.GetResponse()
