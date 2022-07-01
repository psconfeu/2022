######################################
## Write encoded Password to Registry
######################################

$service = 'Auphonic'
$username = 'PSConfEU'

## Does account already exist?
if (!(Test-Path -Path "HKCU:\myCreds\$service")){
    New-Item -Force -ItemType Directory -Path "HKCU:\myCreds\$service"
}
    
if (Get-ItemProperty -Path "HKCU:\myCreds\$service" -Name $username -ErrorAction SilentlyContinue) {
    $encPassword = Get-ItemProperty -Path "HKCU:\myCreds\$service\" -Name $username | 
      Select-Object -ExpandProperty $username 
    [PSCustomObject]@{
        'Service' = $service
        'Username' = $username
        'Encrypted PW' = $encPassword
    }
} else {
    $message = "User ""$username"" does not exist at ""HKCU:\myCreds\$service"". Please provide a password!"
    New-ItemProperty -Path "HKCU:\myCreds\$service" -Name $username -Value (Read-Host -AsSecureString -Prompt $message |
      ConvertFrom-SecureString )
}