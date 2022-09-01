function Start-Test
{
    # MUST be an advanced function so make sure you add [CmdletBinding()] just to be sure:
    [CmdletBinding()]
    param
    (
        [ValidateSet('New','Edit','Delete')]
        [string]
        $Action,

        [string]
        $Path
    )

    dynamicparam
    {
        # create container for all dynamically created parameters:
        $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()


        #region Start Parameter -Id ####
        if ($PSBoundParameters['Action'] -match '(Edit|Delete)') {
        # create container storing all attributes for parameter -Id
        $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()

        # Define attribute [Parameter()]:
        $attrib = [Parameter]::new()
        $attrib.Mandatory=$true
        $attributeCollection.Add($attrib)

        # compose dynamic parameter:
        $dynParam = [System.Management.Automation.RuntimeDefinedParameter]::new('Id',[Guid],$attributeCollection)

        # add parameter to parameter collection:
        $paramDictionary.Add('Id',$dynParam)
        }
        #endregion End Parameter -Id ####


        #region Start Parameter -CustomerName ####
        if ($PSBoundParameters['Action'] -match '(Edit|New)') {
        # create container storing all attributes for parameter -CustomerName
        $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()

        # Define attribute [Parameter()]:
        $attrib = [Parameter]::new()
        $attributeCollection.Add($attrib)

        # compose dynamic parameter:
        $dynParam = [System.Management.Automation.RuntimeDefinedParameter]::new('CustomerName',[string],$attributeCollection)

        # add parameter to parameter collection:
        $paramDictionary.Add('CustomerName',$dynParam)
        }
        #endregion End Parameter -CustomerName ####


        #region Start Parameter -Test ####
        if ($PSBoundParameters.ContainsKey('Action')) {
        # create container storing all attributes for parameter -Test
        $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()

        # Define attribute [Parameter()]:
        $attrib = [Parameter]::new()
        $attributeCollection.Add($attrib)

        # compose dynamic parameter:
        $dynParam = [System.Management.Automation.RuntimeDefinedParameter]::new('Test',[switch],$attributeCollection)

        # add parameter to parameter collection:
        $paramDictionary.Add('Test',$dynParam)
        }
        #endregion End Parameter -Test ####


        #region Start Parameter -Coffee ####
        if ((Get-Date).Hour -lt 11) {
        # create container storing all attributes for parameter -Coffee
        $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()

        # Define attribute [Parameter()]:
        $attrib = [Parameter]::new()
        $attributeCollection.Add($attrib)

        # compose dynamic parameter:
        $dynParam = [System.Management.Automation.RuntimeDefinedParameter]::new('Coffee',[switch],$attributeCollection)

        # add parameter to parameter collection:
        $paramDictionary.Add('Coffee',$dynParam)
        }
        #endregion End Parameter -Coffee ####


        #region Start Parameter -Lunch ####
        if ((Get-Date).Hour -ge 11) {
        # create container storing all attributes for parameter -Lunch
        $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()

        # Define attribute [Parameter()]:
        $attrib = [Parameter]::new()
        $attributeCollection.Add($attrib)

        # compose dynamic parameter:
        $dynParam = [System.Management.Automation.RuntimeDefinedParameter]::new('Lunch',[switch],$attributeCollection)

        # add parameter to parameter collection:
        $paramDictionary.Add('Lunch',$dynParam)
        }
        #endregion End Parameter -Lunch ####


        #region Start Parameter -Mount ####
        if ($PSBoundParameters['Path'] -match '^[a-z]:') {
        # create container storing all attributes for parameter -Mount
        $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()

        # Define attribute [Parameter()]:
        $attrib = [Parameter]::new()
        $attributeCollection.Add($attrib)

        # compose dynamic parameter:
        $dynParam = [System.Management.Automation.RuntimeDefinedParameter]::new('Mount',[switch],$attributeCollection)

        # add parameter to parameter collection:
        $paramDictionary.Add('Mount',$dynParam)
        }
        #endregion End Parameter -Mount ####


        # return dynamic parameter collection:
        $paramDictionary
    }
    
    begin
    {
        
        #region initialize variables for dynamic parameters

        if($PSBoundParameters.ContainsKey('Id')) { $Id = $PSBoundParameters['Id'] }
        else { $Id = $null}

        if($PSBoundParameters.ContainsKey('CustomerName')) { $CustomerName = $PSBoundParameters['CustomerName'] }
        else { $CustomerName = $null}

        if($PSBoundParameters.ContainsKey('Test')) { $Test = $PSBoundParameters['Test'] }
        else { $Test = $null}

        if($PSBoundParameters.ContainsKey('Coffee')) { $Coffee = $PSBoundParameters['Coffee'] }
        else { $Coffee = $null}

        if($PSBoundParameters.ContainsKey('Lunch')) { $Lunch = $PSBoundParameters['Lunch'] }
        else { $Lunch = $null}

        if($PSBoundParameters.ContainsKey('Mount')) { $Mount = $PSBoundParameters['Mount'] }
        else { $Mount = $null}
        #endregion initialize variables for dynamic parameters

        # place your own code that executes before pipeline processing starts
    }
 
    process
    {
        #region update variables for pipeline-aware parameters:
        #endregion update variables for pipeline-aware parameters
        
        #region output pipeline-aware parameters for diagnostic purposes:
        [PSCustomObject]@{
            ParameterSetName = $PSCmdlet.ParameterSetName
        } | Format-List

        #endregion output pipeline-aware parameters for diagnostic purposes

        # place your own code that executes for each incoming pipeline object
    }

    end
    {
        #region output submitted parameters for diagnostic purposes:
        [PSCustomObject]@{
            Coffee       = $Coffee
            CustomerName = $CustomerName
            Id           = $Id
            Lunch        = $Lunch
            Mount        = $Mount
            Test         = $Test
        } | Format-List

        #endregion output submitted parameters for diagnostic purposes

        # place your own code that executes after pipeline processing has finished
    }
}
