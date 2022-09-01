
# create new attribute to play with
class TobiasAttribute : System.Attribute
{
    [int]$SomeInfo = (Get-Random -Maximum 10000)

    [int]Calculate()
    {
        return ($this.SomeInfo * $this.SomeInfo)
    }

}

# attach attribute to a powershell item
[Tobias()]$test = 123

# retrieving attribute
$variable = Get-Variable -Name test
$variable.Attributes
$instance = $variable.Attributes | Where-Object { $_ -is [TobiasAttribute] }

$instance.SomeInfo
$instance.Calculate()

# named parameters refer to properties defined in the attribute:
[Tobias(SomeInfo=10)]$test = 123
$instance = $variable.Attributes | Where-Object { $_ -is [TobiasAttribute] }

$instance.SomeInfo
$instance.Calculate()

function test
{
    param
    (
        # attach attribute to a parameter:
        [Tobias(SomeInfo=99)]
        [string]
        $id = 123
    )

    # doable, but won't make much sense:
    $instance = (Get-Variable -Name id).Attributes | Where-Object { $_ -is [TobiasAttribute] }
    $instance.SomeInfo
    $instance.Calculate()

}

test -id 12

# using attributes in code to identify code components
$function:test

$function:test.Ast.FindAll({$args[0] -is [System.Management.Automation.Language.ParamBlockAst]}, $true).
    Parameters.Attributes | 
    ForEach-Object { $_.GetType().FullName }

$attribute = $function:test.Ast.FindAll({$args[0] -is [System.Management.Automation.Language.ParamBlockAst]}, $true).
    Parameters.Attributes | 
    Where-Object { $_ -is [System.Management.Automation.Language.AttributeAst] } |
    Where-Object { $_.TypeName.Name -eq 'Tobias' }

$attribute.NamedArguments
$attribute.PositionalArguments
$attribute.TypeName.Name

