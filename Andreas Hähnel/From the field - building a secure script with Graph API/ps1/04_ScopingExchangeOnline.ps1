$myAppRegistrationID = "<ID OF YOUR APP>" #AppID, not ObjectID!
New-ApplicationAccessPolicy -AppId $myAppRegistrationID -PolicyScopeGroupId "TargetedUsers@contoso.com" -AccessRight RestrictAccess -Description "Restrict this app to members of this security or distribution group"
