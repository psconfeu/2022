using namespace System.Diagnostics.CodeAnalysis
Describe 'TestHttpOutputBinding' -Tag E2E {
    BeforeAll {
        try {
            Get-Process func -ErrorAction stop | Out-Null
        } catch {
            throw 'Azure Functions Tools (func.exe) is not running. Run the task stupid!'
        }
        # [SuppressMessageAttribute(
        #     'PSUseDeclaredVarsMoreThanAssignments',
        #     Justification = 'Pester Scope can be weird'
        # )]
        $baseUri = 'http://localhost:7071/api/'
    }
    It 'Works with no parameter' {
        $result = Invoke-RestMethod -Uri ($baseUri + 'PushHttpOutputBindingDemo')
        $result | Should -BeLike 'This HTTP Triggered function executed successfully*'
    }
    It 'Works with a query string' {
        $result = Invoke-RestMethod -Uri ($baseUri + 'PushHttpOutputBindingDemo') -Method GET -Body @{Name = 'FaintingGoat' }
        $result | Should -BeLike 'Hello, FaintingGoat*'
    }
    It 'Works with a JSON body' {
        $result = Invoke-RestMethod -Uri ($baseUri + 'PushHttpOutputBindingDemo') -Method GET -Body (@{Name = 'FaintingGoat' } | ConvertTo-Json)
        $result | Should -BeLike 'Hello, FaintingGoat*'
    }
    It 'Works if the name is PowershellSummit' {
        $result = Invoke-RestMethod -Uri ($baseUri + 'PushHttpOutputBindingDemo') -Method GET -Body @{Name = 'PowershellSummit' }
        $result | Should -BeLike 'Hello, PowershellSummit*'
    }
}
