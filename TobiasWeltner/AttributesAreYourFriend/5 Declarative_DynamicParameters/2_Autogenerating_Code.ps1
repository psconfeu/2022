#requires -Module dynpar

$parameter = {
    # submit a scriptblock with just a param() block
    # the param() block defines the parameter you want
    # designate the attribute [Dynamic()] to parameters that should be turned into dynamic parameters
    # dynamic parameters are visible only when certain conditions exist
    # the condition is specified as argument to [Dynamic()]. This argument is a scriptblock.
    # when the condition evaluates to $true, the parameter is added, else removed
    
    # for example, to show a parameter only before 11 a.m., add this:
    # [Dynamic({(Get-Date).Hour -lt 11})]
    
    # you can also use $PSBoundParameters to refer to other parameters that a user has already submitted
    # for example, to show a parameter only if the parameter -Test was also specified, add this:
    # [Dynamic({$PSBoundParameters.ContainsKey('Test')} )]
    # to show a parameter only if the parameter -Path start with a letter and a colon (not UNC path), try this:
    # [Dynamic({$PSBoundParameters['Path'] -match '^[a-z]:'})]


    param
    (
        [ValidateSet('New','Edit','Delete')]
        [string]
        $Action,
        
        # show -Id only when editing or deleting
        # when a new customer is added, the id is calculated automatically
        [Parameter(Mandatory)]
        [Dynamic({$PSBoundParameters['Action'] -match '(Edit|Delete)'})]
        [Guid]
        $Id,
        
        # show -CustomerName only when editing or adding a new customer:
        [Dynamic({$PSBoundParameters['Action'] -match '(Edit|New)'})]
        [string]
        $CustomerName,
        
        # show -Test only once (any) -Action value was submitted:
        [Dynamic({$PSBoundParameters.ContainsKey('Action')} )]
        [switch]
        $Test,
        
        # show -Coffee only before 11 a.m.
        [Dynamic({(Get-Date).Hour -lt 11})]
        [switch]
        $Coffee,
        
        # show -Lunch only at 11 a.m. or later
        [Dynamic({(Get-Date).Hour -ge 11})]
        [switch]
        $Lunch,
        
        # show -Mount only when -Path refers to a local path (and not a UNC path)
        [string]
        $Path,
        
        [Dynamic({$PSBoundParameters['Path'] -match '^[a-z]:'})]
        [switch]
        $Mount
        
    )
}

# turn definition into function with dynamic parameters
$definition = $parameter | Get-PsoDynamicParameterDefinition -FunctionName Start-Test

# copy function definition to clipboard
$definition | Set-ClipBoard

# paste it into the PowerShell editor of your choice, and run it to
# test dynamic parameter behavior. 
# Then, add the script logic you need to the begin, process, and/or end blocks.