##########################################
## Basic tests with plain text passwords
## Username: PSConfEU
## Password: PowerShellRocks!
##########################################

## Simple test with curl.exe
curl.exe https://auphonic.com/api/presets.json -u PSConfEU:PowerShellRocks

## Simple test with Invoke-Restmethod 
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "PSConfEU","PowerShellRocks!")))
$uri = 'https://auphonic.com/api/presets.json' 
$request = Invoke-RestMethod -UseBasicParsing -Uri $uri -Headers @{Authorization = "Basic $base64AuthInfo" }
$request.data