############################################
## Basic tests WITHOUT plain text passwords
## Username/Password stored in the registry
############################################

## A: Create a credentials object 
$service = 'Auphonic'
$username = 'PSConfEU'
$encPassword = Get-ItemProperty -Path "HKCU:\myCreds\$service\" -Name $username | 
  Select-Object -ExpandProperty $username 
$cred = [System.Management.Automation.PSCredential]::new($username,($encPassword | ConvertTo-SecureString)) 
$password = $cred.GetNetworkCredential().Password

## Simple test with Invoke-Restmethod 
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))
$uri = 'https://auphonic.com/api/presets.json' 
$request = Invoke-RestMethod -UseBasicParsing -Uri $uri -Headers @{Authorization = "Basic $base64AuthInfo" }
$request.data | Select-Object -Property preset_name