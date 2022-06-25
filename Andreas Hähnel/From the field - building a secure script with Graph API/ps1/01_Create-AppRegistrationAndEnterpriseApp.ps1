Connect-AzureAD  #Module AzureAD required!
# https://docs.microsoft.com/en-us/powershell/microsoftgraph/azuread-msoline-cmdlet-map
$myAppRegistration = 'PSConfEU22'
$appHomepageURL = 'https://localhost:12345'
$appReplyURL = 'https://localhost:12345/signin-oidc'
$myCoolApp = New-AzureADApplication -DisplayName $myAppRegistration -AvailableToOtherTenants $false -Homepage $appHomePageUrl -ReplyUrls @($appReplyUrl)
# New-MgApplication
# now create the Service Principal from that app
$myEnterpriseApp = New-AzureADServicePrincipal -AppId $myCoolApp.AppID -Tags @(“WindowsAzureActiveDirectoryIntegratedApp”,”PSConfEU”)
# New-MgServicePrincipal

# now be happy with Conditional Access 
# afterwards grant Graph permissions