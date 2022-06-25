$mailbox = "<UPN OF YOUR MAILBOX>"

New-Variable -Name appID -Value "<ID OF YOUR APP>" -Option ReadOnly
New-Variable -Name tenantID -Value "<ID OF YOUR AAD>" -Option ReadOnly
New-Variable -Name clientSecret -Value "<SECRET OF YOUR APP>" -Option ReadOnly

function Get-GraphAuthorizationToken {
    param
    (
        [string]$ResourceURL = 'https://graph.microsoft.com',
        [string][parameter(Mandatory)] $TenantID,
        [string][Parameter(Mandatory)] $ClientKey,
        [string][Parameter(Mandatory)] $AppID
    )
	
    $Authority = "https://login.windows.net/$TenantID/oauth2/token"
	[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
    $EncodedKey = [System.Web.HttpUtility]::UrlEncode($ClientKey)
	$body = "grant_type=client_credentials&client_id=$AppID&client_secret=$EncodedKey&resource=$ResourceUrl"
    # Request a Token from the graph api
    $result = Invoke-RestMethod -Method Post -Uri $Authority `
        -ContentType 'application/x-www-form-urlencoded' -Body $body
    $script:APIHeader = @{ 'Authorization' = "Bearer $($result.access_token)" }
}

Get-GraphAuthorizationToken -TenantID $tenantID -AppID $appID -ClientKey $clientSecret

$uri = "https://graph.microsoft.com/v1.0/users/$mailbox/mailFolders/Inbox"

$EmailFolderInboxIRM = Invoke-RestMethod -Uri $uri -Method Get -Headers $script:APIHeader
$EmailFolderInboxIWR = Invoke-WebRequest -Uri $uri -Method Get -Headers $script:APIHeader

#get the body:
$EmailFolderInboxIWR.Content | Convertfrom-Json