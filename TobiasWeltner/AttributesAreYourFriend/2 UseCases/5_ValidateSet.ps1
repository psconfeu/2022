
function Connect-Server
{
    param
    (
        [ValidateSet(IgnoreCase=$false,'Microsoft','Google','Apple')]
        [string]
        $Customer
    )
    
    "Hello $Customer"
}


Connect-Server -Customer apple