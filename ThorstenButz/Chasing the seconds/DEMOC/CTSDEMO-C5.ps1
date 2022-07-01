################################################################################
## Demo C5: HardwareInformation via pipelining/end{}, psSession, ValidateScript
################################################################################

function Get-HardwareInformation {
    [CmdletBinding()]
    [Alias('ghwi')]    
    Param     (        
        # Parameter "-Computername" supports pipeline support accepting single strings/objects
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({
            Test-WSMan -ComputerName $_ -Authentication Kerberos 
        })]
        [string] $Computername
    )
    Begin {                
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()               
        
        ## Get-HardwareInformation
        $code = {

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
       }                

        $properties = 'PSComputername','BIOSManufacturer','BIOSVersion','BIOSReleaseDate','OSCaption','OSBuildNumber','OSInstallDate','OSLastBootUpTime' 
    }
    Process {
        ## Lets create an arry of computernames first!
        [string[]] $Computernames += $Computername           
    }
    End {   
        ## MAIN                        
        $psSessions = New-PSSession -ComputerName $Computernames 
        Invoke-Command -Session $psSessions -ScriptBlock $code | Select-Object -Property $properties                     
        $psSessions | Remove-PSSession

        ## Create some verbose output
        Write-Verbose -message "Runtime(ms): $($stopwatch.ElapsedMilliseconds) | InvocationLine: $($MyInvocation.Line)" 
        Write-Information -MessageData $($stopwatch.ElapsedMilliseconds) 
    }
}

## RUN
$Computernames = (Get-ADComputer -Filter { name -like 'vie-cl*' }).name
$result = $Computernames | Get-HardwareInformation -Verbose
"Found information about $(($result.PSComputername | Select-Object -Unique).count) different computers."

## Display the results
Remove-Item -Path 'HardwareInformation.xlsx' -ErrorAction SilentlyContinue
$result  | Export-Excel -WorksheetName 'Vienna' -Path 'HardwareInformation.xlsx' -ClearSheet -Show -AutoSize -AutoFilter -FreezeTopRow 

## RUN multiple times
Clear-Host
Remove-Item -Path 'runtimes.txt' -ErrorAction SilentlyContinue
foreach ($i in 1..10) { $result = $Computernames | Get-HardwareInformation -Verbose 6>> 'runtimes.txt'  }

## Calculate average runtime
[int] $sum = 0
[int[]] $numbers = Get-Content -path 'runtimes.txt'
foreach ($n in $numbers) { $sum += $n }
[int] ($sum / $numbers.Count)