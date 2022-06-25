@{
    ModuleVersion   = '0.0.1'
    RootModule      = 'PSConfSecretVault.psm1'
    NestedModules   = @('.\PSConfSecretVault.Extension')
    CmdletsToExport = @()
    PrivateData     = @{
        PSData = @{
            Tags = @('SecretManagement')
        }
    }
}
