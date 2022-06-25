Describe 'CreateUser' -Tag Integration {
    It 'Works with <Name>' {
        . $PSScriptRoot/../CreateUser/run.ps1 -Name $Name
        | Select-Object -Last 1
        | Should -BeLike "$Name completed!*"
    } -TestCases @(
        @{Name = '$(Arbitrary Code Injection)' }
        @{Name = 'Pester' }
        @{Name = 'Test1' }
        @{Name = 'Test@#$)(*@#$J)(1' }
    )
}
