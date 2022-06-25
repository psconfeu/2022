Connect-AzureAD  #Module AzureAD required!
$myAppRegistrationID = "<ID OF YOUR APP>"
$newSecret = New-AzureADApplicationPasswordCredential -ObjectId $myAppRegistrationID -CustomKeyIdentifier "PowerShellGenerated" -StartDate (get-date) -endDate (get-date).AddDays(720)
# Add-MgApplicationPassword