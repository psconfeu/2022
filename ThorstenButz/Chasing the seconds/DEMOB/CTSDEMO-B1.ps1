##############################################
## Demo B1: SoftwareInventory via parameter[] 
##############################################

function Get-SoftwareInventory {
    [CmdletBinding()]
    [Alias('gswi')]    
    Param     (        
        # Parameter "-Computername" supports multiple names, no pipeline support
        [Parameter(Mandatory)]
        [string[]] $Computername, 
        [switch] $showUninstallString        
    )
    Process {                
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()               
        
        ## GetSoftware, simplified
        $code = {
            $path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
                    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' 
            Get-ItemProperty -Path $path | Where-Object -Property DisplayName  | Select-Object -Property $properties
        }                

        $properties = 'PSComputername', 'DisplayVersion', 'DisplayName'
        if ($showUninstallString) { $properties += 'UninstallString' }        

        ## MAIN 
        Invoke-Command -ComputerName $Computername -ScriptBlock $code -ErrorAction SilentlyContinue | Select-Object -Property $properties                     
   
        ## Create some verbose output
        Write-Verbose -message "Runtime(ms): $($stopwatch.ElapsedMilliseconds) | InvocationLine: $($MyInvocation.Line)" 
        Write-Information -MessageData $($stopwatch.ElapsedMilliseconds) 
    }
}

## RUN
$Computernames = (Get-ADComputer -Filter { name -like 'vie-cl*' }).name
$result = Get-SoftwareInventory -Computername $Computernames -Verbose
"Found $($result.DisplayName.count) software packages on $(($result.PSComputername | Select-Object -Unique).count) different computers."

## Display the results
Remove-Item -Path 'SoftwareInventory.xlsx' -ErrorAction SilentlyContinue
$result  | Export-Excel -WorksheetName 'Vienna' -Path 'SoftwareInventory.xlsx' -ClearSheet -Show -AutoSize -AutoFilter -FreezeTopRow -NoNumberConversion 'DisplayVersion'

## RUN multiple times
Clear-Host
Remove-Item -Path 'runtimes.txt' -ErrorAction SilentlyContinue
foreach ($i in 1..10) { $result = Get-SoftwareInventory -Computername $Computernames -Verbose 6>> 'runtimes.txt' }

## Calculate average runtime
[int] $sum = 0
[int[]] $numbers = Get-Content -path 'runtimes.txt'
foreach ($n in $numbers) { $sum += $n }
[int] ($sum / $numbers.Count)