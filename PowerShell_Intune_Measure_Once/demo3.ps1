$baseUri = "https://graph.microsoft.com/beta/deviceManagement/auditEvents"
$token = Get-MsalToken -TenantId 'intune.training' -ClientId "d1ddf0e4-d672-4dae-b554-9d5bdfd93547" -DeviceCode

#region Look at all "PowerShell" create events
$alertFilter = "?`$filter=(activityOperationType eq 'Create' and activityType eq 'createDeviceManagementScript DeviceManagementScript')"
$header = @{ Authorization = $token.CreateAuthorizationHeader() }
$params = @{
    Method      = "Get"
    Uri         = "$($baseUri)$alertFilter"
    Headers     = $header
    ContentType = 'Application/Json'
}
$result = Invoke-RestMethod @params
$result.value
#endregion

#region show me scripts added by the intern in the last day
$dateRange = [datetime]::now.AddDays(-1).ToUniversalTime().ToString("yyyy-MM-dd")
$alertFilter = "?`$filter=(activityOperationType eq 'Create' and activityType eq 'createDeviceManagementScript DeviceManagementScript' and activityDateTime gt $dateRange)"
$header = @{ Authorization = $token.CreateAuthorizationHeader() }
$result = Invoke-RestMethod @params -Uri "$($baseUri)$alertFilter"
$naughtyScript = $result.value | Where-Object { $_.actor.userPrincipalName -eq "ben@intune.training" }
$scriptId = $naughtyScript.resources.resourceId
#endregion

#region get the script fron the policy
$scriptUri = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$scriptId"
$scriptContent = (irm @params -Uri $scriptUri).scriptContent
$decodedContent = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String("$($scriptContent)"))
$decodedContent
#endregion