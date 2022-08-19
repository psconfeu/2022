$Theme = Get-UDTheme -Name 'AntDesign'

New-UDDashboard -Title 'PowerShell Conference EU 2022' -Content {
    New-UDImage -Url 'https://psconf.eu/wp-content/uploads/2022/01/psconfeu_logo_300.png'
    New-UDTypography -Text 'PowerShell Conference EU 2022' -Variant h4

    New-UDDynamic -Content {
        $data = Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 10 | ForEach-Object {
            [PSCustomObject]@{
                Name  = $_.Name
                Value = $_.CPU
                Id    = $_.Id
            }
        }
        New-UDNivoChart -Bar -Keys "value" -IndexBy 'name' -Data $Data -Height 500 -Width 1000 -Id 'cpuChart' -Colors @{
            scheme = "category10"
        }

        New-UDTable -Data $data -Columns @(
            New-UDTableColumn -Property 'Name' -Title 'Name' 
            New-UDTableColumn -Property 'Value' -Title 'Value' 
            New-UDTableColumn -Property 'Actions' -Render {
                New-UDButton -Text 'Stop' -OnClick {
                    Stop-Process -Id $EVentData.Id
                }
            }
        )
    } -AutoRefresh -AutoRefreshInterval 1

    New-UDCard -Content {
        New-UDForm -Content {
            New-UDTextbox -Id 'file' -Placeholder 'File'
            New-UDTextbox -Id 'arguments' -Placeholder 'Arguments'
            New-UDSwitch -Id 'admin' -Label 'As Administrator?'
        } -OnSubmit {
            $verb = ""
            if ($EventData.admin) {
                $verb = "runas"
            }

            Start-Process -FilePath $EventData.File -ArgumentList $EventData.Arguments -Verb $verb
        }
    }
} -Theme $Theme