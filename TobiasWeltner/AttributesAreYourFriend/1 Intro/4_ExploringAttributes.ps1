function Get-AttributeInfo
{
  filter Test-Attribute([Type]$DerivedFrom = [System.Attribute])
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
  $attributes = [PSObject].Assembly.GetTypes() | 
  Where-Object IsPublic |
  # take only types that derive from "System.Attribute"
  Test-Attribute -DerivedFrom ([System.Attribute]) |
  Foreach-Object -begin {
    # create a new empty ordered hashtable
    $hash = [Ordered]@{}
  } -process {
    # for each attribute, get name:
    $name = $_.Name.Split('.')[-1] -replace 'Attribute$'
    
    # add hashtable entry and assign writeable properties
    # to it:
    $hash[$name] = $_.GetProperties() |
    ForEach-Object {
      # ignore property "TypeId"
      if ($_.Name -ne 'TypeId')
      {
        # if the property is writeable, it is
        # a named value
        $ValueName = $_.Name
        # else it is the default value and has
        # no key (we mark the name with brackets)
        if (!$_.CanWrite)
        {
          $ValueName = "[$ValueName]"
        }
        [PSCustomObject]@{
          Name = $ValueName
          Type = $_.PropertyType.FullName
        }
      }
    }   
  } -end { 
    # return filled hashtable
    $hash 
  }
  
  
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
  Where-Object IsPublic |
  # take only types that derive from "System.Attribute"
  Test-Attribute -DerivedFrom ([System.Attribute]) |
  Foreach-Object -begin {
    # create a new empty ordered hashtable
    $hash = [Ordered]@{}
  } -process {
    # for each attribute, get name:
    $name = $_.Name.Split('.')[-1] -replace 'Attribute$'
    
    # keep track of positional parameters so we can later
    # exclude named parameters of same name:
    $positional = @{}
    
    $hash[$name] = & {
      # all constructor arguments are positional parameters
      $_.GetConstructors() | ForEach-Object {
        $_.GetParameters() | ForEach-Object {
          $positional[$_.Name] = $true
          [PSCustomObject]@{
            Name = $_.Name
            Kind = 'Positional'
            Type = $_.ParameterType
          }
        }
      }
    
    
      $_.GetProperties() |
      ForEach-Object {
        # ignore property "TypeId" and include only writeable properties that
        # haven't been added before
        if ($_.Name -ne 'TypeId' -and $_.CanWrite -and !$positional.ContainsKey($_.Name))
        {
          [PSCustomObject]@{
            Name = $_.Name
            Kind = 'Named'
            Type = $_.PropertyType.FullName
          }
        }
      }
    }   
  } -end { 
    # return filled hashtable
    $hash 
  }
}

$attributes = Get-AttributeInfo
$attributes.Keys | Sort-Object | 
    Out-GridView -Title 'Select Attribute' -OutputMode Single |
    ForEach-Object { $attributes[$_] }