import-module ./src/pscafnaming.psd1 -Force





New-CAFResourceName -Name test -Prefixes psconf, prod -Suffixes 001 -ResourceType 'storage account' -Separator 1




New-CAFResourceName -IgnoreValidations -ResourceType 'storage account' -Prefixes a, b -Suffixes y, z -CleanInput $false




New-CAFResourceName -name 'mysupercool---storageaccount' -ResourceType 'storage account' -CleanInput $false -AddResourceAbbreviation $false -Separator

Update-CAFOnlineResourceDefinitions




function New-VerySpecificCompanyNamingConventionThatHasBeenThoughtOutVeryWellAndTook2YearsToDecide {
    param(
        [parameter(Mandatory)]
        [ValidateLength(3)]
        [string]
        $Project,

        [parameter(Mandatory)]
        [ValidateSet('Dev', 'UAT', 'Prod')]
        [string]
        $Environment,

        [parameter(Mandatory)]
        [int32]
        $Count,

        [parameter(Mandatory)]
        [int32]
        $IdSeed
    )

    DynamicParam {
        # Set the dynamic parameter for Resource Types
        $ParameterName = 'ResourceType'

        # Create the dictionary
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet
        $arrSet = Get-CAFUniqueResources
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }

    process {
        $i = -1
        while ($IdSeed + ++$i) {
            $index = IdSeed + $i
            New-CAFResourceName -Name $Project -Prefixes 'psconf', $Environment -Suffixes $index -ResourceType $PSBoundParameters["ResourceType"]
        }
    }
}
