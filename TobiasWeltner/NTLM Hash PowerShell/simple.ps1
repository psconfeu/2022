function Get-ContentEx
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [int64]
        $Position,

        [System.Text.Encoding]
        $Encoding = [System.Text.Encoding]::ASCII,

        [int]
        $BufferSize = 128,

        [switch]
        $DetectBOM
    )

    $reader = [System.IO.StreamReader]::new($Path, $Encoding, $DetectBOM.IsPresent, $BufferSize)
    [System.IO.Stream] $baseStream = $reader.BaseStream
    
    $null = $baseStream.Seek($Position, [System.IO.SeekOrigin]::Begin)
    $reader.DiscardBufferedData()
    # find the start of the current text line
    # if we don't hit a line end (ASCII 10) or the beginning (0)...
    while ($baseStream.Position -ne 0L -band $baseStream.ReadByte() -ne 10)
    {
        # ...we go back two chars (the one just read plus one more):
        $null = $baseStream.Seek(-2L, [System.IO.SeekOrigin]::Current)
    }

    # now we are at a line start for sure:
    [int64] $positionNew = $baseStream.Position
    
    # read line and return:
    [PSCustomObject]@{
        Text = [string]$reader.ReadLine()
        Position = $positionNew
    }
    
    # dispose reader and free memory:
    $reader.Dispose()
}

# test it:

$path = 'C:\NTLMHash\pwned-passwords-ntlm-ordered-by-hash-v8.txt'
$file = Get-Item -Path $Path
$size = $file.Length

# reading takes the same time, regardless of where inside the file:
Get-ContentEx -Path $path -Position 100
Get-ContentEx -Path $path -Position ($size/2)

# let's now try and find an item in a huge SORTED list:

function Find-Hash 
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Path,
        
        [Parameter(Mandatory)]
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
    while ($rangeStart -lt $rangeEnd)
    {
        # here is the trick: we start reading the file in the MIDDLE of the range:
        [int64] $offset = ($rangeStart + $rangeEnd) / 2
        $result = Get-ContentEx -Path $path -Position $offset
        
        $result | 
        Add-Member -MemberType NoteProperty -Name Range -Value ($rangeEnd - $rangeStart) -PassThru |
        Select-Object -Property *
            
        if ($result.Text -like "$SearchText")
        {
            $compromises = $result.text.Split(':')[-1]
            Write-Warning "Hash is compromised, severity: $compromises"
            break
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
}

cls
$hash= Get-Md4Hash
Find-Hash -SearchText "$hash*" -Path $path

Get-ContentEx -Path $path -Position 4GB
Find-Hash -SearchText '23FA7E6F0554709DA6E2EA8AA4D13054*' -Path $path
