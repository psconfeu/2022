function Connect-MyServer
{
    param
    (
        [string]
        [Parameter(Mandatory)]
        # auto-learn user names to user.hint
        [AutoLearn('user')]
        # auto-complete user names from user.hint
        [AutoComplete('user')]
        $UserName,

        [string]
        [Parameter(Mandatory)]
        # auto-learn computer names to server.hint
        [AutoLearn('server')]
        # auto-complete computer names from server.hint
        [AutoComplete('server')]
        $ComputerName
    )

    "hello $Username, connecting you to $ComputerName"
}