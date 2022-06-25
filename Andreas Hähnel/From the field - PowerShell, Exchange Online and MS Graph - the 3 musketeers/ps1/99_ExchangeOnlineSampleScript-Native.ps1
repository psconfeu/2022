#========================================================================
# Created on:		16.06.2022 19:02
# Created by:		Andreas Hähnel
# Organization:		Black Magic Cloud
# Function name:	99_ExchangeOnlineSampleScript_Native.ps1
# Script Version: 	0.1
#========================================================================
# RequiredPermissions:
# Delegated (work or school account)		Not supported.
# Delegated (personal Microsoft account)	Not supported.
# Application								Mail.ReadWrite
#											
# Grant admin consent for the tenant
#
#========================================================================
# Description:
# this script reads the contents from the inbox of a specified mailbox
# and exports the content as XML
#
#========================================================================
# Useful links:
#
# 
#========================================================================
# 
# Changelog:
# Version 0.1 16.06.2022
# - initial creation
#
#========================================================================
#
# EXAMPLE (replace variables with actual values):
# 
#========================================================================
# TODO:
# - add logging
#========================================================================

#========================================================================
# Global Variables
#========================================================================
#region global variables
$TargetMailboxes = @("UPN OF YOUR MAILBOX")

New-Variable -Name appID -Value "<ID OF YYOUR APP>" -Option ReadOnly
New-Variable -Name tenantID -Value "<ID OF YOUR AAD>" -Option ReadOnly
New-Variable -Name clientSecret -Value "<SECRET OF YOUR APP>" -Option ReadOnly

#endregion

#========================================================================
# Functions
#========================================================================
#region functions
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
#========================================================================

function Normalize-String {
    param(
        [Parameter(Mandatory = $true)][string]$str
    )
	
    $str = $str.ToLower()
    $str = $str.Replace(" ", "")
    $str = $str.Replace("ä", "ae")
    $str = $str.Replace("ö", "oe")
    $str = $str.Replace("ü", "ue")
    $str = $str.Replace("ß", "ss")
    $str = $str.Replace("?","")
	
    Write-Output $str
}
#========================================================================
#endregion

#========================================================================
# Scriptstart
#========================================================================
Get-GraphAuthorizationToken -AppID $appID -TenantID $tenantID -ClientKey $clientSecret

foreach($mailbox in $TargetMailboxes)
{
    $uri = "https://graph.microsoft.com/v1.0/users/$mailbox/mailFolders/Inbox"
    #in v1.0 you need to use the well-known name, in beta there is a parameter wellKnownName
    $EmailFolderInbox = Invoke-RestMethod -Uri $uri -Method Get -Headers $script:APIHeader

    #list all emails in the inbox
    $uri = "https://graph.microsoft.com/v1.0/users/$mailbox/mailFolders/$($EmailFolderInbox.id)/messages"
    $allMails = Invoke-RestMethod -Uri $uri -Method Get -Headers $script:APIHeader

    #export all emails to 1 comprehensive XML
    $allMails | Export-Clixml -Path "C:\dev\allmails.xml"
    #each email to a single XML and delete it
    foreach($mail in $allMails.value)   #if you need to spend some hours of debugging, forget ".value" :)
    {
        $mail | Export-Clixml -Path "C:\dev\$(Normalize-String $mail.Subject).xml" -Force
        $uri = "https://graph.microsoft.com/v1.0/users/$mailbox/mailFolders/$($EmailFolderInbox.id)/messages/$($mail.id)"
        Invoke-RestMethod -Uri $uri -Method DELETE -Headers $script:APIHeader
    }
}