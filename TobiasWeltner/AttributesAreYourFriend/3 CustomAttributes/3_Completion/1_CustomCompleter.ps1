class MyAutoCompleteAttribute : System.Management.Automation.ArgumentCompleterAttribute
{
  
  # constructor calls base constructor and submits the completion code:
  # added a mandatory positional argument $Values with the autocompletion values
  # this argument is passed to a static method that creates the scriptblock that the base constructor wants:
  
  MyAutoCompleteAttribute([string[]] $Items) : base([MyAutoCompleteAttribute]::_createScriptBlock($Items)) 
  {
    # constructor has no own code
  }
    
  # create a static helper method that creates the scriptblock that the base constructor needs
  # this is necessary to be able to access the argument(s) submitted to the constructor
  hidden static [ScriptBlock] _createScriptBlock([string[]] $Items)
  {
    $scriptblock = {
      # receive information about current state:
      param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
   
      # list all submitted values...
      
      $Items | 
      Sort-Object |
      # filter results by word to complete
      Where-Object { $_ -like "$wordToComplete*" } | 
      Foreach-Object { 
        [System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", $_)
      }
    }.GetNewClosure()
    return $scriptblock
  }
}