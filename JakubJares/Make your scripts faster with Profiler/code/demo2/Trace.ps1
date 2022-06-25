Import-Module Profiler 

$trace =  Trace-Script -ScriptBlock { 
    . "$PSScriptRoot/Get-UserData.ps1"

    $script:users = Get-UserData -Path "$PSScriptRoot/data.json"
} -ExportPath users.speedscope.json

$trace.Top50SelfDuration |
    Where-Object File -NE Trace.ps1 |
    Select-Object -First 5 |
    Format-Table SelfPercent, SelfDuration, HitCount, File, Line, Function, Text 