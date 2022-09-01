
function Connect-Server
{
    param
    (
        [ValidateSet(IgnoreCase=$false,'Microsoft','Google','Apple')]
        [string]
        $Customer,

        [Parameter(DontShow=$true)]
        [switch]
        $SecretOverride
    )
    
    "Hello $Customer"
    if ($SecretOverride)
    {
        Write-Warning "God-mode enabled."
    }
}

# side effect: DontShow turns off all common parameters while preserving the advanced function status
Connect-Server 