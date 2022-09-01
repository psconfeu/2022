filter Test-Attribute([Type]$DerivedFrom)
{
  # get the parent type of this type
  $baseType = $_.BaseType
  do
  {
    # if the parent is derived from the desired type,
    # return it
    if ($baseType -eq $DerivedFrom)
    {
      $_
    }
    # else walk up the inheritance chain
    # by looking at the parent of the 
    # current parent until no more
    # parent exists
    $baseType = $baseType.BaseType
  } while ($baseType)
}

# dump all PowerShell types by taking (any) powershell type,
# identify its assembly, and dump all public types
[PSObject].Assembly.GetTypes() | 
  # dump public types only
  Where-Object IsPublic |
  # take only types that derive from "System.Attribute"
  Test-Attribute -DerivedFrom ([System.Attribute]) |
  # remove "Attribute" suffix (this is a regex, "$" means 'end-of-text'
  ForEach-Object { $_ -replace 'Attribute$' } |
  # remove namespace prefix
  Foreach-Object { $_.Split('.')[-1] } |
  # output in attribute syntax
  ForEach-Object { "[$_()]"} |
  Sort-Object