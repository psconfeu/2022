
class AutoLearnAttribute : System.Management.Automation.ValidateArgumentsAttribute
{
    # define path to store hint lists
    [string]$Path = "$env:temp\hints"

    # define id to manage multiple hint lists:
    [string]$Id = 'default'

    # define parameterless constructor:
    AutoLearnAttribute() : base()
    {}

    # define constructor with parameter for id:
    AutoLearnAttribute([string]$Id) : base()
    {
        $this.Id = $Id
    }
    
    # Validate() is called whenever there is a variable or parameter assignment
    [void]Validate([object]$value, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics)
    {
        # make sure the folder with hints exists
        $exists = Test-Path -Path $this.Path
        if (!$exists) { $null = New-Item -Path $this.Path -ItemType Directory }

        # create filename for hint list
        $filename = '{0}.hint' -f $this.Id
        $hintPath = Join-Path -Path $this.Path -ChildPath $filename
        
        # use a hashtable to keep hint list
        $hints = @{}

        # read hint list if it exists
        $exists = Test-Path -Path $hintPath
        if ($exists) 
        {
            Get-Content -Path $hintPath -Encoding Default |
              # remove leading and trailing blanks
              ForEach-Object { $_.Trim() } |
              # remove empty lines
              Where-Object { ![string]::IsNullOrEmpty($_) } |
              # add to hashtable
              ForEach-Object {
                # value is not used, set it to $true:
                $hints[$_] = $true
              }
        }

        # add new value to hint list
        if(![string]::IsNullOrWhiteSpace($value))
        {
            $hints[$value] = $true
        }
        # save hints list
        $hints.Keys | Sort-Object | Set-Content -Path $hintPath -Encoding Default 
        
        # skip any validation (we only care about logging)
    }
}


class AutoCompleteAttribute : System.Management.Automation.ArgumentCompleterAttribute
{
    # define path to store hint lists
    [string]$Path = "$env:temp\hints"

    # define id to manage multiple hint lists:
    [string]$Id = 'default'
  
    # define parameterless constructor:
    AutoCompleteAttribute() : base([AutoCompleteAttribute]::_createScriptBlock($this)) 
    {}

    # define constructor with parameter for id:
    AutoCompleteAttribute([string]$Id) : base([AutoCompleteAttribute]::_createScriptBlock($this))
    {
        $this.Id = $Id
    }

    # create a static helper method that creates the scriptblock that the base constructor needs
    # this is necessary to be able to access the argument(s) submitted to the constructor
    # the method needs a reference to the object instance to (later) access its optional parameters:
    hidden static [ScriptBlock] _createScriptBlock([AutoCompleteAttribute] $instance)
    {
    $scriptblock = {
        # receive information about current state:
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
   
        # create filename for hint list
        $filename = '{0}.hint' -f $instance.Id
        $hintPath = Join-Path -Path $instance.Path -ChildPath $filename
        
        # use a hashtable to keep hint list
        $hints = @{}

        # read hint list if it exists
        $exists = Test-Path -Path $hintPath
        if ($exists) 
        {
            Get-Content -Path $hintPath -Encoding Default |
              # remove leading and trailing blanks
              ForEach-Object { $_.Trim() } |
              # remove empty lines
              Where-Object { ![string]::IsNullOrEmpty($_) } |
              # filter completion items based on existing text:
              Where-Object { $_.LogName -like "$wordToComplete*" } | 
              # create argument completion results
              Foreach-Object { 
                  [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
              }
        }
    }.GetNewClosure()
    return $scriptblock
    }
}