class PasswordManagerAttribute : System.Management.Automation.ArgumentTransformationAttribute
{
  [object] Transform([System.Management.Automation.EngineIntrinsics]$engineIntrinsics, [object] $inputData)
  {
    # this is where your encrypted passwords will be stored
    # change this pass if you want to store elsewhere, i.e. on a usb disk
    # the passwords are encrypted with your username and computer identity
    # they can only be used on the same machine, and only by you:
    [string]$StorePath = "$env:userprofile\secretstore.xml"
      
    # if the file already exists...
    [bool]$exists = Test-Path -Path $StorePath
    if ($exists)
    {
      # load it (including all previously stored credentials)
      [System.Collections.Hashtable]$store = Import-Clixml -Path $StorePath
    }
    else
    {
      # else, start with an empty hashtable:
      $store = @{}
    }

    # if the argument is a string...
    if ($inputData -is [string])
    {
      # does username start with "!"?
      [bool]$promptAlways = $inputData.StartsWith("!")

      # if not,...
      if (!$promptAlways)
      {
        # ...check to see if the username has been used before,
        # and re-use its credential (no need to enter password again)
        if ($store.ContainsKey($inputData))
        {
          return $store[$inputData]
        }
      }
      else
      {
        # ...else, remove the "!" at the beginning and prompt
        # again for the password (this way, passwords can be updated)
        $inputData = $inputData.SubString(1)
      }
      # ask for a credential:
      $cred = $engineIntrinsics.Host.UI.PromptForCredential("Enter password", "Please enter user account and password", $inputData, "")
      # add the credential to the hashtable:
      $store[$cred.UserName] = $cred
      # update the hashtable and write it to file:
      $store | Export-Clixml -Path $StorePath
      # return the credential:
      return $cred
    }
    # if a credential was submitted...
    elseif ($inputData -is [PSCredential])
    {
      # save it to the hashtable:
      $store[$inputData.UserName] = $inputData
      # update the hashtable and write it to file:
      $store | Export-Clixml -Path $StorePath
      # return the credential:
      return $inputData
    }
    throw [System.InvalidOperationException]::new('Unexpected error.')
  }
}