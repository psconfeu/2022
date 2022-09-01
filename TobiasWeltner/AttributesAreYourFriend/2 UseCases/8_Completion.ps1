#region type-based argument completion
function Get-Computer
{
  param
  (
    # default completer falls back to path completion:
    [String]
    $ComputerName
  )
  
  # output submitted arguments
  $PSBoundParameters

}

function Get-Color
{
  param
  (
    # enum types provide completion:
    [ConsoleColor]
    $Color
  )
  
  # output submitted arguments
  $PSBoundParameters

}

enum Cities
{
  Hannover
  Redmond
  NewYork
}

function Get-City
{
  param
  (
    # PS-defined enum types provide completion (with a flaw):
    [Cities]
    $City
  )
  
  # output submitted arguments
  $PSBoundParameters

}

Add-Type -TypeDefinition @"
   public enum Shifts
   {
      Morning,
      Afternoon,
      Night,
      Off
   }
"@

function Get-Shift
{
  param
  (
    # C#-defined enum types provide completion (flawless):
    [Shifts]
    $Type
  )
  
  # output submitted arguments
  $PSBoundParameters

}
#endregion type-based argument completers


#region hint-based argument completers
function Get-Customer
{
  param
  (
    # ValidateSets restrict strings and provide IntelliSense
    [ValidateSet('Microsoft','Amazon','Google')]
    [string]
    $Customer
  )
  
  # output submitted arguments
  $PSBoundParameters

}

function Get-RemoteSystem
{
  param
  (
    # completion hints provide Intellisense (with a flaw)
    [ArgumentCompleter({'Server01','Server02','DC1'})]
    [string]
    $ComputerName
  )
  
  # output submitted arguments
  $PSBoundParameters

}

function Get-Server
{
  param
  (
    # completion hints provide Intellisense (PowerShell 7 and better only)
    [ArgumentCompletions('Server01','Server02','DC1')]
    [string]
    $ComputerName
  )
  
  # output submitted arguments
  $PSBoundParameters

}
function Get-Mood
{
  param
  (
    # hints are supplied later via Register-ArgumentCompleter
    $Current
  )
  
  # output submitted arguments
  $PSBoundParameters

}

# register the hints separately with PowerShell:
Register-ArgumentCompleter -CommandName Get-Mood -ParameterName Current -ScriptBlock {'Great','Soso','Depressed', 'WontTell'}

#endregion hint-based argument completers