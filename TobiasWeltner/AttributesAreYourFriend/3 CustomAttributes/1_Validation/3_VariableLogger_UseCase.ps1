# attach the logger to the variable and specify the
# name of the global variable ('myLoggerVar') that should
# log variable changes, plus optionally a source identifier
# that gets added to the log:
[LogVariable('myLoggerVar', SourceName='Init')]$test = 1
[LogVariable('myLoggerVar', SourceName='Iterator')]$x = 0

# start using the variables:
for ($x = 1000; $x -lt 3000; $x += 300) 
{
  "Frequency $x Hz"
  [Console]::Beep($x, 500)
}

$test = "Hello"
Start-Sleep -Seconds 1
$test = 1,2,3

# looking at the log results:
$myLoggerVar | Out-GridView