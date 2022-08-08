############
## Demo A.3
############
function Invoke-Something {
    [CmdletBinding()]
    [Alias('ist')]    
    Param     (        
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]] $Computername
    )

    begin {        
    }

    process {      
        foreach ($Target in $Computername) {
            'Target system: ' + $Target
        }
    }
    end {        
    }

}

Clear-Host
Invoke-Something -Computername 'vie-cl10', 'vie-cl11' -Verbose
'vie-cl12', 'vie-cl13' | Invoke-Something
