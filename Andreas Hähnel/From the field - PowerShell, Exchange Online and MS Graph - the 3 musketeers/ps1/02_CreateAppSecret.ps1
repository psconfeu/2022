Connect-AzureAD  #Module AzureAD required!
$myAppRegistrationID = "<YOUR APP ID>"
$newSecret = New-AzureADApplicationPasswordCredential -ObjectId $myAppRegistrationID -CustomKeyIdentifier "PowerShellGenerated" -StartDate (get-date) -endDate (get-date).AddDays(720)
