Set-PSDebug -Trace 1

$sum = 0
1,1,1 | ForEach-Object { 
    $sum += $_
}
Write-Host $sum -ForegroundColor Magenta

Set-PSDebug -Off