#requires -module AzureFunctionsHelpers
using namespace Microsoft.Azure.Functions.Worker

[Function('PushHttpOutputBindingDemo')]
param(
    [HttpTrigger('Anonymous', ('GET', 'POST'))]
    [HttpRequestContext]$Request,
    $TriggerMetadata
)

# Write to the Azure Functions INFORMATION log stream.
Write-Host 'PowerShell HTTP trigger function processed a request.'

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

$body = 'This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response.'

if ($name) {
    $body = "Hello, $name. This HTTP triggered function executed successfully."
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
$body | Push-HttpBinding -StatusCode OK -Name Response -Headers @{
    'X-Why-Are-Reindeer-Ghosts-So-Empathetic' = 'They Caribou!'
}
