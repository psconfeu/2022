#========================================================================
# Created on:		16.06.2022 19:02
# Created by:		Andreas Hähnel
# Organization:		Black Magic Cloud
# Function name:	99_ExchangeOnlineSampleScript_GraphSDK.ps1
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

Import-Module Microsoft.Graph.Mail
Import-Module Microsoft.Graph.Authentication

New-Variable -Name appID -Value "<ID OF YOUR APP>" -Option ReadOnly
New-Variable -Name tenantID -Value "<ID OF YOUR AAD>" -Option ReadOnly

# Graph SDK only supports certificate based auth for unattended scripts, no secret (currently):
# https://docs.microsoft.com/en-us/powershell/microsoftgraph/app-only?view=graph-powershell-1.0&tabs=powershell


Connect-MgGraph -Scopes Mail.Read.Shared,User.Read.All -ClientId $appID -TenantId $tenantID -
$user = Get-MgUser -Search '"DisplayName:Spiderman"' -ConsistencyLevel eventual 
#$inbox = Get-MgUserMailFolder -UserId $user.Id | Where-Object {$_.DisplayName -eq "Inbox"}

$allMails = Get-MgUserMessage -UserId $user.Id
$allMails | Export-Clixml -Path "C:\dev\allmails.xml"
foreach($mail in $allMails.Value) 
{
    $mail | Export-Clixml -Path "C:\dev\$($mail.Subject).xml"
    #here you can use the UPN
    #Remove-MgUserMessage -UserId $user.Id -MessageId $mail.id
}

