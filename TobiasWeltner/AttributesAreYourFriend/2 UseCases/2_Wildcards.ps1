
function Invoke-Search1
{
    param
    (
        [string]
        $Filter = '*'
    )

    $Filter
}


function Invoke-Search2
{
    [CmdletBinding()]
    param
    (
        [SupportsWildcards()]
        [PSDefaultValue(Help = "Wildcard")]
        [string]
        $Filter = '*'
    )

    $Filter
}

Get-Help -Name Invoke-Search1 -Parameter Filter
# unfortunately, these attributes are no longer read and honored by the engine:
Get-Help -Name Invoke-Search2 -Parameter Filter



