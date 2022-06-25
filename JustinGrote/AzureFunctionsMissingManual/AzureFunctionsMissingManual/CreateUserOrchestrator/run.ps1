param($Context)

$output = @()

$output += Invoke-DurableActivity -FunctionName 'CreateUser' -Input 'Frank'
$output += Invoke-DurableActivity -FunctionName 'CreateUser' -Input 'Steve'
$output += Invoke-DurableActivity -FunctionName 'CreateUser' -Input 'Phil'

$output
