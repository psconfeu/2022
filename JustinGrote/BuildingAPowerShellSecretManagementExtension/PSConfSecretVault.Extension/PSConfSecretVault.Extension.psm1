Write-Host 'Dont do this either but at least nested imported'

function Test-SecretVault {
    [CmdletBinding()]
    param (
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )

    # if ([String]::IsNullOrEmpty($AdditionalParameters.Path)) {
    #     throw 'Please specify a Path in your additionalparameters to the json file'
    # }
    Write-Host -ForegroundColor green 'They gave me a file!'
    return $true
}
function Get-Secret ($Name, $VaultName, $AdditionalParameters) { throw [System.NotImplementedException]'nice try' }
function Set-Secret ($Name, $VaultName, $AdditionalParameters, $Secret) { throw [System.NotImplementedException]'nice try' }
function Remove-Secret ($Name, $VaultName, $AdditionalParameters, $Secret) { throw [System.NotImplementedException]'nice try' }
function Get-SecretInfo ($Name, $VaultName, $Filter, $AdditionalParameters, $Secret) { throw [System.NotImplementedException]'nice try' }
