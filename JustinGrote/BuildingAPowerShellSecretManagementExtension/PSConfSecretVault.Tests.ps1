Describe 'Vault' {
    BeforeAll {
        #Register the vault temporarily
    }
    It 'Works' {
        $secret = Get-Secret 'something' -Vault $thiswillcomefromBeforeAll
        $secret | Should -Be 'MyPesterSecret'
    }
    AfterAll {
        #Unregister the vault
    }
}
