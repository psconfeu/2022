New-UDDashboard -Title 'PowerShell Universal' -Content {
    New-UDForm -Content {
        New-UDTextbox -Id 'name' -Label Name
    } -OnSubmit {
        Invoke-PSUScript -Name 'CreatePizza.ps1' -OrderName $EventData.Name -Integrated -Wait | ConvertTo-Json

    }
}