##################
## Demo A (final)
##################
function Invoke-Something {
    [CmdletBinding()]
    [Alias('ist')]    
    Param     (        
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]] $Computername
    )

    begin {        
        Write-Verbose -Message '(c) Thorsten Butz'
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    }

    process {      
        foreach ($Target in $Computername) {
            'Target system: ' + $Target
        }
    }
    end {
        Write-Verbose -Message ('Runtime(ms): ' + $stopwatch.ElapsedMilliseconds)        
    }

}


## A: Array (of strings) as parameter
Invoke-Something -Computername 'vie-cl10', 'vie-cl11' -Verbose

## B: Pipelining by Value
'vie-cl12', 'vie-cl13' | Invoke-Something -Verbose

## C: Pipelining by PropertyName
$objComputer = [PSCustomObject] @{
    Computername = 'vie-cl14'
    Vendor = 'Wortmann'
}
$objComputer | Invoke-Something -Verbose
