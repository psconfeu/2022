$myAppRegistrationID = "<YOUR APP ID>"
New-SelfSignedCertificate -Subject "CN=PSConfEUCertificate" -KeySpec Signature -CertStoreLocation "cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears(10)
$thumbprint = (Get-ChildItem "cert:\CurrentUser\My" | Where-Object {$_.Subject -eq "CN=PSConfEUCertificate"}).Thumbprint
if ($tmppath -eq $false) {New-Item C:\cert -ItemType Directory}

#PFX
$certPW = "myUncrackableSecret123!"
$certPW = ConvertTo-SecureString -String $certPW -Force -AsPlainText
Export-PfxCertificate -cert "cert:\CurrentUser\my\$thumbprint" -FilePath C:\cert\PSConfEUCertificate.pfx -Password $certPW
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate("C:\cert\PSConfEUCertificate.pfx", $certPW)
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
New-AzureADApplicationKeyCredential -ObjectId $myAppRegistrationID -CustomKeyIdentifier "PSConfEU" -Type AsymmetricX509Cert -Usage Verify -Value $keyValue
# New-MgApplicationKey

#CER
Get-ChildItem "Cert:\CurrentUser\My\$thumbprint" | Export-Certificate -FilePath "C:\cert\PSConfEUCertificate.cer"
$CERcert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate("C:\cert\PSConfEUCertificate.cer")
$keyValue = [System.Convert]::ToBase64String($CERcert.GetRawCertData())
New-AzureADApplicationKeyCredential -ObjectId $myAppRegistrationID -CustomKeyIdentifier "PSConfEU" -Type AsymmetricX509Cert -Usage Verify -Value $keyValue
# New-MgApplicationKey
