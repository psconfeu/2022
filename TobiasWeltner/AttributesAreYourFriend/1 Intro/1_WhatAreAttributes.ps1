param
(
    [Parameter(Mandatory)]  # "official" attribute: [NameOfAttribute()]
    [int]                   # "inofficial" attribute, handled internally by PowerShell
    $Id
)

$Id

$variable = Get-Variable -Name Id
$variable.Attributes
[System.Management.Automation.ParameterAttribute]              # public
[System.Management.Automation.ArgumentTypeConverterAttribute]  # non-public, internal use

# Attributes are always derived from the System.Attribute base type
$type = [System.Management.Automation.ParameterAttribute]
while ($type -ne [Object])
{
    $type.FullName
    $type = $type.BaseType
}