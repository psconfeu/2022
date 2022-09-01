<#
these are NO PowerShell-defined attributes yet PowerShell honors them:
[System.Diagnostics.DebuggerHidden()]        # hide completely
[System.Diagnostics.DebuggerStepThrough()]   # allows to step through once bp is hit
[System.Diagnostics.DebuggerNonUserCode()]   # same as above
#>


function test 
{
    [System.Diagnostics.DebuggerHidden()]
    
    [CmdletBinding()]
    param()

    # this is stepped through
    "I am doing some magic here"
    "more"
    "even more"
}

Wait-Debugger
test



function test2
{
    [System.Diagnostics.DebuggerNonUserCode()]
    
    [CmdletBinding()]
    param()

    # this is stepped through
    "I am doing some magic here"
    "more"
    "even more"
}

test2
