using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

#region config
$baseUri = "https://graph.microsoft.com/beta/deviceManagement/auditEvents"
$token = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com/").Token
$header = @{ Authorization = "Bearer $token" }
#endregion

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

#region functions
function Send-TeamsMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ActorUpn,

        [Parameter(Mandatory = $true)]
        [string]$ScriptDisplayName,

        [Parameter(Mandatory = $true)]
        [string]$CreatedDate,

        [Parameter(Mandatory = $true)]
        [string]$UrlToScript
    )
    try {
        $teamsUri = "https://intunetraining.webhook.office.com/webhookb2/ABCDEFG"
        $json = @"
            {
    "type": "message",
    "attachments": [
        {
            "contentType": "application/vnd.microsoft.card.adaptive",
            "content": {
                "type": "AdaptiveCard",
                "body": [
                    {
                        "type": "Container",
                        "items": [
                            {
                                "type": "TextBlock",
                                "size": "Large",
                                "weight": "Bolder",
                                "text": "Intune Script Creation Alert!!",
                                "style": "heading",
                                "color": "attention"
                            },
                            {
                                "type": "TextBlock",
                                "text": "Script metadata below..",
                                "wrap": true
                            },
                            {
                                "type": "FactSet",
                                "facts": [
                                    {
                                        "title": "Uploaded by:",
                                        "value": "$($ActorUpn)"
                                    },
                                    {
                                        "title": "Script Name:",
                                        "value": "$($ScriptDisplayName)"
                                    },
                                    {
                                        "title": "Created date:",
                                        "value": "$($CreatedDate)"
                                    },
                                    {
                                        "title": "Script contents:",
                                        "value": "[$($UrlToScript)]($($UrlToScript))"
                                    }
                                ]
                            }
                        ]
                    }
                ],
                "msteams": {
                    "width": "Full"
                },
                "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                "version": "1.2"
            }
        }
    ]
}
"@
        
        $restParams = @{
            Uri         = $teamsUri
            ContentType = "application/json"
            Method      = 'POST'
            Body        = $json
        }
        $null = Invoke-WebRequest @restParams
    }
    catch {
        Write-Warning $_.Exception.Message
    }

}
#endregion

#region find any scripts created in the last 24 hours

#region show me scripts added by the intern in the last day
$dateRange = [datetime]::now.AddDays(-1).ToUniversalTime().ToString("yyyy-MM-dd")
$alertFilter = "?`$filter=(activityOperationType eq 'Create' and activityType eq 'createDeviceManagementScript DeviceManagementScript' and activityDateTime gt $dateRange)"
$params = @{
    Method      = "Get"
    Uri         = "$($baseUri)$alertFilter"
    Headers     = $header
    ContentType = 'Application/Json'
}
$result = Invoke-RestMethod @params
$naughtyScript = $result.value | Where-Object { $_.actor.userPrincipalName -eq "ben@intune.training" }
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
    Write-Output "Getting script.."
    $scriptContent = (Invoke-RestMethod @params)
    $scriptContent | Format-List
    $decodedContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("$($scriptContent.scriptCOntent)"))
    $tempFile = New-TemporaryFile
    $decodedContent | Out-File $tempFile -Force -Encoding utf8

    Write-Output "Getting storage context.."
    $ctx = New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
    Write-Output "Getting storage container.. $($env:AZURE_CONTAINER)"
    $container = (Get-AzStorageContainer -Name $env:AZURE_CONTAINER -Context $ctx).CloudBlobContainer
    Write-Output "uploading file.."
    $result = Set-AzStorageBlobContent -File $tempFile -Blob $scriptContent.fileName -Container $container.Name -Context $ctx -Force
    $result | Format-List
    Write-Output "sending teams notif.."
    Send-TeamsMessage -ActorUpn $script.actor.userPrincipalName -ScriptDisplayName $scriptContent.displayName -CreatedDate $scriptContent.createdDateTime.ToString() -UrlToScript $result.ICloudBlob.Uri.AbsoluteUri
}
#endregion
#endregion


# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = "cool."
    })
