# create a new custom validation attribute named "LogVariableAttribute":
class LogVariableAttribute  : System.Management.Automation.ValidateArgumentsAttribute
{
  # define two properties
  # they turn into optional attribute values later:
  [string]$VariableName
  [string]$SourceName = 'Undefined'
    
  # this is the class constructor. It defines all mandatory attribute values:
  LogVariableAttribute([string]$VariableName)
  {
    $this.VariableName = $VariableName
  }
    
  # this gets called whenever a new value is assigned to the variable:

  [void]Validate([object]$value, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics)
  {
    # get the global variable that logs all changes:
    [System.Management.Automation.PSVariable]$variable = Get-Variable $this.VariableName -Scope global -ErrorAction Ignore
    # if the variable exists and does not contain an ArrayList, delete it:
    if ($variable -ne $null -and $variable.Value -isnot [System.Collections.ArrayList]) { $variable = $null }
    # if the variable does not exist, set up an empty new ArrayList:
    if ($variable -eq $null) { $variable = Set-Variable -Name $this.VariableName -Value ([System.Collections.ArrayList]@()) -Scope global -PassThru }
    # log the variable change to the ArrayList:
    $null = $variable.Value.Add([PSCustomObject]@{
        # use the optional source name that can be defined by the attribute:
        Source = $this.SourceName
        Value = $value
        Timestamp = Get-Date
        # use the callstack to find out where the assignment took place:
        Line = (Get-PSCallStack).ScriptLineNumber | Select-Object -Last 1
        Path = (Get-PSCallStack).ScriptName | Select-Object -Last 1
    })
  }
}