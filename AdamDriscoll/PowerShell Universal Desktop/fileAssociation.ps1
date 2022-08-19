param($File)

Set-PSUCache -Key Map -Value $File 
Show-PSUPage -Url "map"