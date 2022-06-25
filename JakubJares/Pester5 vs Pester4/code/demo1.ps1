param ($a) 
BeforeAll {
    Write-Host -F Yellow "Before all on top"
}


Describe "Get-Avocado <_>" -ForEach @(1..10) {
    Write-Host -F Cyan "Top of Describe"

    BeforeAll { Write-Host -F Yellow " $_ BeforeAll" }
    BeforeEach { Write-Host -F Yellow "BeforeEach" }
    AfterEach { Write-Host -F Yellow "AfterEach" }
    AfterAll { Write-Host -F Yellow "AfterAll" }
    
    Write-Host -F Cyan "Describe just before It"
    It "First It $(Write-Host -F Cyan "Name of First It ")" {
        Write-Host -F Yellow "First It"
    }

    It "Second It" {
        Write-Host -F Yellow "Second It"
    }
    Write-Host -F Cyan "Describe just after It"
}