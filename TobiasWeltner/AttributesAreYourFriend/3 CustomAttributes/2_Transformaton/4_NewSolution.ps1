# create a transform attribute that transforms plain text to secure string
class SecureStringTransformAttribute : System.Management.Automation.ArgumentTransformationAttribute
{
    [object] Transform([System.Management.Automation.EngineIntrinsics]$engineIntrinsics, [object] $inputData)
    {
        # if a securestring was submitted...
        if ($inputData -is [SecureString])
        {
            # return as-is:
            return $inputData
        }
        # if the argument is a string...
        elseif ($inputData -is [string])
        {
            # convert to secure string:
            return $inputData | ConvertTo-SecureString -AsPlainText -Force
        }
        
        # anything else throws an exception:
        throw [System.InvalidOperationException]::new('Unexpected error.')
    }
}
