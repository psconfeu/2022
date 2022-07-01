#####################################################################################################################################
## WMI: Get some basic system information
## Get-CimInstance -ClassName Win32_BIOS | Select-Object -Property 'Manufacturer','Version','ReleaseDate'
## Get-CimInstance -ClassName Win32_Operatingsystem | Select-Object -Property 'InstallDate','LastBootUpTime','Caption','BuildNumber'
#####################################################################################################################################

$win32Bios = Get-CimInstance -ClassName Win32_BIOS
$win32OS =   Get-CimInstance -ClassName Win32_Operatingsystem 

[PSCustomObject] @{

    'BIOSManufacturer' = $win32Bios.Manufacturer
    'BIOSVersion'      = $win32Bios.Version
    'BIOSReleaseDate'  = $win32Bios.ReleaseDate
                    
    'OSCaption'        = $win32OS.Caption
    'OSBuildNumber'    = $win32OS.BuildNumber
    'OSInstallDate'    = $win32OS.InstallDate
    'OSLastBootUpTime' = $win32OS.LastBootUpTime

}