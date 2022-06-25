#========================================================================
# Created on:		17.06.2022 11:39
# Created by:		Andreas Hähnel
# Organization:		Black Magic Cloud
# Function name:	99_UseCaseSampleScript.ps1
# Script Version: 	0.1
#========================================================================
# RequiredPermissions:
# Delegated (work or school account)		Not supported.
# Delegated (personal Microsoft account)	Not supported.
# Application								Sites.ReadWrite.All
#											User.ReadAll
# Grant admin consent for the tenant
#
#========================================================================
# Description:
# this script reads the AAD users and stores the data in SPO 
#
#========================================================================
# Useful links:
#
# 
#========================================================================
# 
# Changelog:
# Version 0.1 17.06.2022
# - initial creation
#
#========================================================================
#
# EXAMPLE (replace variables with actual values):
# 
#========================================================================
# TODO:
# 
#========================================================================

#========================================================================
# Global Variables
#========================================================================
#region global variables

New-Variable -Name appID -Value "<ID OF YOUR APP>" -Option ReadOnly
New-Variable -Name tenantID -Value "<ID OF YOUR AAD>" -Option ReadOnly
New-Variable -Name clientSecret -Value "<SECRET OF YOUR APP>" -Option ReadOnly
New-Variable -Name SharePointListURI -Value "https://graph.microsoft.com/v1.0/sites/<SITE ID>/lists/<LIST ID>/items" -Option ReadOnly
# find the IDs easy by using Graph Explorer

#endregion

#========================================================================
# Functions
#========================================================================
#region functions
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
#========================================================================

#endregion

#========================================================================
# Scriptstart
#========================================================================
Get-GraphAuthorizationToken -AppID $appID -TenantID $tenantID -ClientKey $clientSecret

$uri = "https://graph.microsoft.com/v1.0/users/"
$allUsers = Invoke-RestMethod -Method Get -Uri $uri -Headers $script:APIHeader

foreach($user in $allusers.value)
{
    #generate the bogy for the SPO request
    # be careful with special characters: e.g. ß -> _x00df_  
    $body = @{
        fields = @{
            "Title"                 = $user.surname
            "Firstname"             = $user.givenName
            "UserPrincipalName"     = $user.userPrincipalName
            "preferredLanguage"     = $user.preferredLanguage
        }
    } | ConvertTo-Json -Depth 4
    
    Invoke-RestMethod -Uri $SharePointListURI -Method Post -Headers $script:APIHeader -ContentType "application/json; charset=utf-8" -Body $body

}



