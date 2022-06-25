$SiteCollectionRelativePath = "<YOURTENANT>.sharepoint.com:/sites/PSConfEU22"
$tenantID = "<ID OF YOUR AAD>"
#Worker App
$appID = "<ID OF YOUR WORKER APP>"
#Admin App 
$secretAdminApp = "<SECRET OF YOUR ADMIN APP>"
$appIDAdminApp = "<ID OF YOUR ADMIN APP>"


function Get-GraphAuthorizationToken {
    param
    (
        [string]$ResourceURL = 'https://graph.microsoft.com',
        [string][parameter(Mandatory)]$TenantID,
        [string][Parameter(Mandatory)]$ClientKey,
        [string][Parameter(Mandatory)]$AppID
    )
	
    $Authority = "https://login.windows.net/$TenantID/oauth2/token"
	
    [Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
    $EncodedKey = [System.Web.HttpUtility]::UrlEncode($ClientKey)
	
    $body = "grant_type=client_credentials&client_id=$AppID&client_secret=$EncodedKey&resource=$ResourceUrl"
	
    # Request a Token from the graph api
    $result = Invoke-RestMethod -Method Post -Uri $Authority -ContentType 'application/x-www-form-urlencoded' -Body $body
	
    $script:APIHeader = @{ 'Authorization' = "Bearer $($result.access_token)" }
}

Get-GraphAuthorizationToken -TenantID $tenantID -AppID $appIDAdminApp -ClientKey $secretAdminApp

$uri = "https://graph.microsoft.com/v1.0/sites/$SiteCollectionRelativePath"
$GraphResultSiteCollection = Invoke-RestMethod -Method Get -Uri $uri -Headers $script:APIHeader
$siteID = $GraphResultSiteCollection.id.Split(",")[1] 

$body = @"
{ 
    "roles": ["write"],
    "grantedToIdentities": [
        {  
            "application": {
                "id": "$appID",
                "displayName": "PSConfEU22"
            }
        }  
    ]
}
"@

$uri = "https://graph.microsoft.com/v1.0/sites/$siteID/permissions"

# and store the permissions for the app:
Invoke-RestMethod -Method Post -uri $uri -Headers $script:APIHeader -Body $body -ContentType "application/json; charset=utf-8"
