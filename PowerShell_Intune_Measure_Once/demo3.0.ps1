Connect-AzAccount
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
$result = Invoke-RestMethod @params -Uri "$($baseUri)$alertFilter"
$naughtyScript = $result.value | Where-Object { $_.actor.userPrincipalName -eq "ben@intune.training" }
$scriptId = $naughtyScript.resources.resourceId
#endregion

#region get the script fron the policy
$scriptUri = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$scriptId"
$scriptContent = irm @params -Uri $scriptUri
$decodedContent = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String("$($scriptContent)"))
$decodedContent
#endregion

#region get the scripts fron the policy
foreach ($script in $naughtyScript){
    $scriptUri = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$($script.resources.resourceId)"
    $params = @{
        Method      = "Get"
        Uri         = $scriptUri
        Headers     = $header
        ContentType = 'Application/Json'
    }
    $scriptContent = (Invoke-RestMethod @params)
    $decodedContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("$($scriptContent.scriptContent)"))
    $tempFile = New-TemporaryFile
    $decodedContent | Out-File $tempFile -Force -Encoding utf8

    Write-Output "Getting storage context.."
    $ctx = New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
    Write-Output "Getting storage container.. $($env:AZURE_CONTAINER)"
    $container = (Get-AzStorageContainer -Name $env:AZURE_CONTAINER -Context $ctx).CloudBlobContainer
    Write-Output "uploading file.."
    $result = Set-AzStorageBlobContent -File $tempFile -Blob $scriptContent.fileName -Container $container.Name -Context $ctx
    $result
    Send-TeamsMessage -ActorUpn $script.actor.userPrincipalName -ScriptDisplayName $scriptContent.displayName -UrlToScript $result.ICloudBlob.Uri.AbsoluteUri
}
#endregion