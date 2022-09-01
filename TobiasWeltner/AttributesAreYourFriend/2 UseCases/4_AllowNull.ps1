
function Invoke-Test1
{
    param
    (
        [Parameter(Mandatory,ValueFromPipeline)]
        [Object]
        [AllowNull()]
        $InputData
    )
    process
    {
        "processing $InputData"
    }
}

1,2,$null,4 | Invoke-Test1

return


function Invoke-Test2
{
    param
    (
        [Parameter(Mandatory,ValueFromPipeline)]
        [AllowNull()]
        [Object]
        $InputData
    )
    process
    {
        "processing $InputData"
    }
}

1,2,$null,4 | Invoke-Test2