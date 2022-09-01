
function Do-Something
{
    [Alias('doit','oh-man','run')]         # Function Alias(es)
    param
    (
        [Alias('id','numbers','whatever')]   # Parameter Alias(es)
        [int]
        $Count=6
    )

    $result = 1..49 | Get-Random -Count $Count | Sort-Object 
    "Your lottery numbers: $result"
}

Do-Something -Count 6
oh-man -whatever 6
