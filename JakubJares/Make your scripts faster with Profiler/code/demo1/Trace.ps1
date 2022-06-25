Import-Module Profiler

$trace =  Trace-Script -ScriptBlock { 
    & "$PSScriptRoot/Get-Icons.ps1"
} -ExportPath emojis.speedscope.json

$trace.Top50SelfDuration |
    Select-Object -First 5 |
    Format-Table SelfPercent, SelfDuration, HitCount, File, Line, Module, Function, Text 
