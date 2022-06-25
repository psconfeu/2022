using namespace System.Net

param([HttpRequestContext]$Request, $TriggerMetadata)

$InstanceId = Start-DurableOrchestration -FunctionName 'CreateUserOrchestrator'
Write-Host "Started orchestration with ID = '$InstanceId'"

$Response = New-DurableOrchestrationCheckStatusResponse -Request $Request -InstanceId $InstanceId
Push-OutputBinding -Name Response -Value $Response
