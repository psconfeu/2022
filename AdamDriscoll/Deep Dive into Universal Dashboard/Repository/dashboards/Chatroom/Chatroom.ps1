New-UDDashboard -Title 'Chatroom' -Content {
    Show-UDToast "$User joined the room!" -Broadcast

    if (-not $Cache:Messages) {
        $Cache:Messages = [System.Collections.Generic.List[string]]::new()
    }

    if (-not $Cache:GuestList) {
        $Cache:GuestList = [System.Collections.Generic.List[string]]::new()
    }

    if (-not $Cache:GuestList.Contains($User)) {
        $Cache:GuestList.Add($User)
        Sync-UDElement -Id 'guestList'
    }


    New-UDRow -Columns {
        New-UDColumn -LargeSize 10 -Content {
            New-UDDynamic -Id 'chatroom' -Content {
                $Messages = ""
                if ($Cache:Messages) {
                    $Messages = $Cache:Messages -join ([Environment]::NewLine)
                }
                New-UDTextbox -Multiline -Rows 10 -FullWidth -Value $Messages
            }
        }
        New-UDColumn -LargeSize 2 -Content {
            New-UDDynamic -Id 'guestList' -Content {
                New-UDList -Children {
                    $Cache:GuestList | ForEach-Object {
                        New-UDListItem -Label $_
                    }
                }
            }
        }
    }

    New-UDForm -Content {
        New-UDTextbox -Id 'message' -Label 'message'
    } -OnSubmit {
        $Message = "[$(Get-Date)] $User - $($EventData.message)"
        $Cache:Messages.Add($Message)
        Sync-UDElement -Id 'chatroom' -Broadcast
        Set-UDElement -Id 'message' -Properties @{
            value = ''
        }
    }

    New-UDFloatingActionButton -Icon (New-UDIcon -Icon cog) -OnClick {
        Show-UDModal -Content {
            New-UDButton -Text 'Clear Chatroom' -OnClick {
                $Cache:Messages = [System.Collections.Generic.List[string]]::new()
                Sync-UDElement -Id 'chatroom' -Broadcast
            }
        } -Header {
            New-UDTypography "Toolbox"
        }
    } -Position bottomRight
    
}