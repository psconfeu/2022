
# https://github.com/TobiasPSP/Modules.dynpar
<#
    Install-Module -Name dynpar -Scope CurrentUser
#>

<#
in a perfect world, PowerShell would honor [Dynamic()]:
#>
param
(
    # regular static parameter
    [string]
    $Normal,
        
    # show -Lunch only at 11 a.m. or later
    [Dynamic({(Get-Date).Hour -ge 11})]
    [switch]
    $Lunch,
        
    # show -Mount only when -Path refers to a local path (and not a UNC path)
    [string]
    $Path,
        
    [Dynamic({$PSBoundParameters['Path'] -match '^[a-z]:'})]
    [switch]
    $Mount
)