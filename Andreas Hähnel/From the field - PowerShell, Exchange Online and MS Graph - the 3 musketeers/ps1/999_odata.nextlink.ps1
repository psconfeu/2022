$found = $false
while (-not $found)
{
    $user = $allUsers.Value | Where-Object {$_.proxyaddresses -ilike ("*" + $owner.Email + "*")}
    if($user){$found = $true;break}
    $uri = $allUsers.'@odata.nextLink'
    $allUsers = Invoke-RestMethod -Method Get -Uri $uri -ContentType 'application/json' -Headers $script:APIHeader
}