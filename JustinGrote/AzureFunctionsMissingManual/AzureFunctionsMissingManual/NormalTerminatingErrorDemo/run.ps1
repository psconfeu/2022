using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$errType = Get-Random -min 1 -max 3
Write-Warning "Uh oh here comes error #$errType!"
switch ($errType) {
    1 { throw 'Kaboom Error 1!' }
    2 { Resolve-Path 'notreal' -ErrorAction Stop }
    3 { [array].thisisnotarealmethod() }
}
