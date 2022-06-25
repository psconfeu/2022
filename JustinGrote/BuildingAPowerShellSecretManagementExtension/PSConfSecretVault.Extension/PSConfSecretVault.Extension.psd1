@{
    ModuleVersion     = '0.0.1'
    RootModule        = '.\PSConfSecretVault.Extension.psm1'
    # RequiredAssemblies = '..\TestStoreImplementation.dll'
    FunctionsToExport = @(
        'Test-SecretVault'
        'Get-Secret'
        #TODO: Probably not today
        'Set-Secret'

        'Remove-Secret'
        'Get-SecretInfo'
    )
}
