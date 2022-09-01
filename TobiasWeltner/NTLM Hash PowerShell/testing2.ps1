
# let's now try and find an item in a huge SORTED list:

function Find-Hash 
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Path,
        
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]
        $SearchText
    )

    # get the total size of the file:
    $file = Get-Item -Path $Path
    $size = $file.Length
    
    
    # define the range of the file that is interesting:
    [int64]$rangeStart = 0
    # search range end position:
    [int64]$rangeEnd = $size - 1
    
    # scan the range until there is a range to read:
    $c=0
    while ($rangeStart -lt $rangeEnd)
    {
        $c++
        # here is the trick: we start reading the file in the MIDDLE of the range:
        [int64] $offset = ($rangeStart + $rangeEnd) / 2
        $result = Get-ContentEx -Path $path -Position $offset
        $rangeSize = $rangeEnd - $rangeStart
        Write-Verbose ('{0} {1,38} {2} {3:n1}MB' -f $c, $result.Text, $result.Position, ($rangeSize/1MB))
            
        if ($result.Text -like "$SearchText*")
        {
            return $result.text.Split(':')[-1]
        }
        elseif ($SearchText -gt $result.text)
        {
            $rangeStart = $result.position + $result.text.Length + 1L
        }
        elseif ($SearchText -lt $result.text)
        {
            $rangeEnd = $result.position - 2L
        }
    }
    return 0
}

return

$hash= Get-Md4Hash
Find-Hash -SearchText $hash -Path $path

$line = Get-ContentEx -Path $path -Position 14.5GB
$hash = $line.Text.Split(':')[0]
$hash

Find-Hash -SearchText $hash -Path $path
Find-Hash -SearchText $hash -Path $path -Verbose

"SunshineXYZ" | 
  ConvertTo-SecureString -AsPlainText -Force |
  Get-Md4Hash |
  Find-Hash -Path $path 
