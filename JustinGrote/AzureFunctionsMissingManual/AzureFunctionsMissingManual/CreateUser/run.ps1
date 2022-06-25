param($name)

$sleepInterval = (Get-Random -min 2000 -max 5000) / 1000
"Creating User $name!"
Start-Sleep $sleepInterval
"$name Completed! It took $sleepInterval seconds to create the user"
