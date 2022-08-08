####################################################
## Auphonic: Publish video, file upload via Dropbox
####################################################

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))
$uri = 'https://auphonic.com/api/simple/productions.json' 
$Form = @{        
    preset          = 'yP8qhASjirfXYMkUUz5krX' ## PSConfEU 2022
    service         = 'B9PvumxddC6sqyW7nq45JW' ## Dropbox
    title           = 'PSConfEU 2022: Interview Tobias Weltner'
    input_file      = 'IMG_1713_30fpsInOut.MP4'
    output_basename = 'IMG_1713'
    action          = 'start'
}
Invoke-RestMethod -UseBasicParsing -Uri $Uri -Method Post -Form $Form -Headers @{Authorization = "Basic $base64AuthInfo" }