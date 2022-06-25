﻿###############################################
## Demo B6: HardwareInformation, the blueprint
###############################################

function Get-SoftwareInventory {
    [CmdletBinding()]
    [Alias('gswi')]    
    Param     (        
        # Parameter "-Computername" supports pipeline input and also passing arrays 
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]        
        [string[]] $Computername, 
        [switch] $showUninstallString        
    )
    Begin {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()               
        
        ## GetSoftware, simplified
        $code = {
            $path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' 
            Get-ItemProperty -Path $path | Where-Object -Property DisplayName  | Select-Object -Property $properties
        }                

        $properties = 'PSComputername', 'DisplayVersion', 'DisplayName'
        if ($showUninstallString) { $properties += 'UninstallString' }        

    }
    Process {   
        ## Lets create an arry of computernames first!         
        [string[]] $Computernames += $Computername             
    }
    End {        
        ## MAIN  
        $sessionOptions = New-PSSessionOption -MaxConnectionRetryCount 1 ## Just an example for some customization
        $psSessions = New-PSSession -ComputerName $Computernames -ErrorAction SilentlyContinue -SessionOption $sessionOptions
        Invoke-Command -Session $psSessions -ScriptBlock $code | Select-Object -Property $properties                     
        $psSessions | Remove-PSSession
        
        ## Create some verbose output
        Write-Verbose -message "Runtime(ms): $($stopwatch.ElapsedMilliseconds) | InvocationLine: $($MyInvocation.Line)" 
        Write-Information -MessageData $($stopwatch.ElapsedMilliseconds) 
    }
}

## RUN
$Computernames = (Get-ADComputer -Filter { name -like 'vie-cl*' }).name
$result = $Computernames | Get-SoftwareInventory -Verbose
"Found $($result.DisplayName.count) software packages on $(($result.PSComputername | Select-Object -Unique).count) different computers."

## Display the results
Remove-Item -Path 'SoftwareInventory.xlsx' -ErrorAction SilentlyContinue
$result  | Export-Excel -WorksheetName 'Vienna' -Path 'SoftwareInventory.xlsx' -ClearSheet -Show -AutoSize -AutoFilter -FreezeTopRow -NoNumberConversion 'DisplayVersion'

## RUN multiple times
Clear-Host
Remove-Item -Path 'runtimes.txt' -ErrorAction SilentlyContinue
foreach ($i in 1..4) { $result = $Computernames | Get-SoftwareInventory -Verbose 6>> 'runtimes.txt' }

## Calculate average runtime
[int] $sum = 0
[int[]] $numbers = Get-Content -path 'runtimes.txt'
foreach ($n in $numbers) { $sum += $n }
[int] ($sum / $numbers.Count)
