$baseUri = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts"
$token = Get-MsalToken -TenantId 'intune.training' -ClientId "d1ddf0e4-d672-4dae-b554-9d5bdfd93547" -DeviceCode

#region list all the scripts
$header = @{ Authorization = $token.CreateAuthorizationHeader() }
$params = @{
    Method      = "Get"
    Uri         = "$baseUri"
    Headers     = $header
    ContentType = 'Application/Json'
}
$result = Invoke-RestMethod @params
$result.value
#endregion

#region get the script fron the policy
$scriptId = ($result.value | Where-Object { $_.displayName -eq 'VeryImportantScript'}).id
$scriptUri = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$scriptId"
$scriptContent = (Invoke-RestMethod @params -Uri $scriptUri).scriptContent
$decodedContent = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String("$($scriptContent)"))
$decodedContent
#endregion