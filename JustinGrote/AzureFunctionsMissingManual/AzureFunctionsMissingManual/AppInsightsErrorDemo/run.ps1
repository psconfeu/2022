#requires -module AzureFunctionsHelpers
using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

trap {
    Write-Warning 'Caught an exception! Gonna log it to app insights before continuing to fail'
    Write-AIException $_.Exception
    throw
}

# This is a normal error, which gets logged as an operationException
Write-Error 'This is a normal error'

#This will trigger a terminating error
Resolve-Path 'notarealpath' -ErrorAction Stop

#We won't actually get this far so no output binding required
# Associate values to output bindings by calling 'Push-OutputBinding'.
# 'An error was logged! Check Application Insights!' | Push-HttpBinding -StatusCode InternalServerError
