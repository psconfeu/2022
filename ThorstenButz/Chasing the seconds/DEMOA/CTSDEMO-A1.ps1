############
## Demo A.1
############
function Invoke-Something {
  [CmdletBinding()]
  [Alias('ist')]    
  Param     (        
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    $Computername
  )

    'Target system: ' + $Computername        

}

Clear-Host
Invoke-Something -Computername 'vie-cl10', 'vie-cl11'
'vie-cl12', 'vie-cl13' | Invoke-Something