# plain text can be converted to a credential by using the
# appropriate transformation attribute.

# make sure you use the correct order: 
# works:
[PSCredential][System.Management.Automation.Credential()]$cred = 'Tobias'
# fails:
[System.Management.Automation.Credential()][PSCredential]$cred = 'Tobias'