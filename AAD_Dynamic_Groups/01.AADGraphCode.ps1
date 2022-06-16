#region params
$result = [System.Collections.ArrayList]::new()
$appName = "Notepad++"
$encodedAppName = [System.Web.HttpUtility]::UrlEncode($appName)
$groupId = 'd20a418e-a00f-47a5-a8ed-e12a9d98f83a'
$baseGraphUri = 'https://graph.microsoft.com/beta'
$env:appId = ''
$env:secret = ''
$env:tenant = ''

$cred = (New-Object System.Management.Automation.PSCredential $env:appId, ($env:secret | ConvertTo-SecureString -AsPlainText -Force))
Connect-AzAccount -ServicePrincipal -Credential $cred -Tenant $env:tenant | Out-Null
$token = (Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com').Token
$script:authHeader = @{Authorization = "Bearer $token" }
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
        [string]$DeviceName,

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
        DeviceName  = $DeviceName
        IsCompliant = $IsCompliant
        IsMember    = $IsMember
        Action      = $Action
    }
    return $result
}
#endregion

#region Get existing group members
$graphUri = "$baseGraphUri/groups/$groupId/members"
$groupMembers = Invoke-GraphCall -Uri $graphUri
#endregion

#region Get devices with notepad++ installed
$detectedAppsBaseUri = "$baseGraphUri/deviceManagement/detectedApps"
$daItem = (Invoke-GraphCall -Uri "$($detectedAppsBaseUri)?`$filter=(contains(displayName,'$([System.Web.HttpUtility]::UrlEncode($encodedAppName))'))").value
if ($daItem.deviceCount -gt 0) {
    $detectedDevices = (Invoke-GraphCall -Uri "$detectedAppsBaseUri/$($daItem.id)/managedDevices").value | Select-Object id, deviceName
    foreach ($device in $detectedDevices) {
        #region Swap the detected device for Intune + AAD object from Intune object
        $intuneDevice = Invoke-GraphCall -Uri "$baseGraphUri/deviceManagement/managedDevices/$($device.id)"
        $aadDevice = (Invoke-GraphCall -Uri "$baseGraphUri/devices?`$filter=(deviceId eq '$($intuneDevice.azureADDeviceId)')").value
        $device | Add-Member -MemberType NoteProperty -Name "deviceId" -Value $aadDevice.deviceId
        #endregion
        #region add devices
        if ($groupMembers.value.deviceId -notcontains $aadDevice.deviceId) {
            #region Device not in group and has software
            $graphUri = "$baseGraphUri/groups/$groupId/members/`$ref"
            $body = @{"@odata.id" = "$baseGraphUri/directoryObjects/$($aadDevice.id)" }
            Invoke-GraphCall -Uri $graphUri -Method Post -Body $body
            $result.Add($(Format-Result -DeviceId $device.deviceId -DeviceName $device.deviceName -IsCompliant $true -IsMember $true -Action Added)) | Out-Null
            #endregion
        }
        else {
            #region device is compliant and already a member
            $result.Add($(Format-Result -DeviceId $device.deviceId -DeviceName $device.deviceName -IsCompliant $true -IsMember $true -Action NoActionTaken)) | Out-Null
            #endregion
        }
        #endregion
    }
    #region Remove devices
    $devicesToRemove = $groupMembers.value | Where-Object { $_.deviceId -notIn $detectedDevices.deviceId}
    if ($devicesToRemove.count -gt 0) {
        foreach ($dtr in $devicesToRemove){
            #region Device found in group, but doesnt have software.
            $graphUri = "$baseGraphUri/groups/$groupId/members/$($dtr.id)/`$ref"
            Invoke-GraphCall -Uri $graphUri -Method Delete
            $result.Add($(Format-Result -DeviceId $dtr.deviceId -DeviceName $dtr.displayName -IsCompliant $false -IsMember $false -Action Removed)) | Out-Null
            #endregion
        }
        
    }
    #endregion
}
#endregion
$result