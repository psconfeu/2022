
function Start-Pause ()
{
    Start-Sleep -Seconds 1
}

$trace = Trace-Script { 
    Start-Pause
}

$trace.Top50SelfDuration | 
    Where-Object Text -notin "{", "}"| 
    Format-Table SelfDuration, Text, Duration