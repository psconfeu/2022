######################################################
## Registry: Get information about installed software
## (System-wide installations, basic version)
######################################################

$path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' 

Get-ItemProperty -Path $path | 
  Where-Object -Property 'DisplayName'  | 
    Select-Object -Property 'DisplayVersion','DisplayName','UninstallString'
