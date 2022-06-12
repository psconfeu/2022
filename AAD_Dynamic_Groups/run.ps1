#region params
$result = [System.Collections.ArrayList]::new()
$appName = "Notepad++"
$groupId = 'd20a418e-a00f-47a5-a8ed-e12a9d98f83a'
$baseGraphUri = 'https://graph.microsoft.com/beta/'
$script:authHeader = @{Authorization = "Bearer $((Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com/").Token)"}
#endregion

#region functions
function Invoke-GraphCall {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $false)]
        [ValidateSet('Get', 'Post', 'Delete')]
        [string]$Method = 'Get',

        [parameter(Mandatory = $false)]
        [hashtable]$Headers = $script:authHeader,

        [parameter(Mandatory = $true)]
        [string]$Uri,

        [parameter(Mandatory = $false)]
        [string]$ContentType = 'Application/Json',

        [parameter(Mandatory = $false)]
        [hashtable]$Body
    )
    try {
        $params = @{
            Method      = $Method
            Headers     = $Headers
            Uri         = $Uri
            ContentType = $ContentType
        }
        if ($Body) {
            $params.Body = $Body | ConvertTo-Json -Depth 20
        }
        $query = Invoke-RestMethod @params
        return $query
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}
function Format-Result {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)]
        [string]$DeviceID,

        [parameter(Mandatory = $true)]
        [bool]$IsCompliant,

        [parameter(Mandatory = $true)]
        [bool]$IsMember,

        [parameter(Mandatory = $true)]
        [ValidateSet('Added', 'Removed', 'NoActionTaken')]
        [string]$Action
    )
    $result = [PSCustomObject]@{
        DeviceID    = $DeviceID
        IsCompliant = $IsCompliant
        IsMember    = $IsMember
        Action      = $Action
    }
    return $result
}
#endregion