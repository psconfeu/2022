New-UDDashboard -Title 'PowerShell Universal' -Content {
    $Nodes = 1..5 | % { New-UDDiagramNode -Id "node$_" -Name "node$_" -OutPort 'out' -InPort 'in' -Color blue -xOffset (100 * $_) }
    $Links = 1..4 | % { New-UDDiagramLink -OutNode "node$_" -OutPort 'out' -InNode "node$($_ + 1)" -InPort 'in' }

    New-UDDiagram -Node $Nodes -Link $Links -Locked -OnSelected {
        Show-UDToast -Message $EventData
    }
}