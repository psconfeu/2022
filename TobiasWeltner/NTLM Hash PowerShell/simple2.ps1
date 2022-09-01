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

    $reader = [System.Io.StreamReader]::new($Path, $Encoding, $DetectBOM.IsPresent, $BufferSize)
    $null = $reader.BaseStream.Seek($Position, [System.IO.SeekOrigin]::Begin)
    $reader.DiscardBufferedData()
    # find the start of the current text line
    [System.IO.Stream] $baseStream = $reader.BaseStream
    while ($baseStream.Position -ne 0L -band $baseStream.ReadByte() -ne 10)
    {
        $null = $baseStream.Seek(-2L, [System.IO.SeekOrigin]::Current)
    }


    # get the start position of current line:
    [int64] $positionNew = $reader.BaseStream.Position
    # read this line:
    [PSCustomObject]@{
        Text = [string]$reader.ReadLine()
        Position = $positionNew
    }
    $reader.Dispose()
}


$path = 'C:\NTLMHash\pwned-passwords-ntlm-ordered-by-hash-v8.txt'
$file = Get-Item -Path $Path
$size = $file.Length

Get-ContentEx -Path $path -Position 100
Get-ContentEx -Path $path -Position ($size/2)
Get-Content -Path $path -tail 1

function Find-Hash 
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Hash
    )

    $path = 'C:\NTLMHash\pwned-passwords-ntlm-ordered-by-hash-v8.txt'
    $file = Get-Item -Path $Path
    $size = $file.Length
    
    [int64]$textStart = 0
    [int64]$textEnd = $size - 1L
    
    # search range start position:
    [int64]$rangeStart = $textStart
    # search range end position:
    [int64]$rangeEnd = $textEnd
    
    [int]$iterations = 0

    # Scanning the text from bottom to top until start of text is reached:
    while ($rangeStart -lt $rangeEnd)
    {
        $iterations++
        # set current reader position to the exact middle of file:
        [int64] $offset = ($rangeStart + $rangeEnd) / 2L
      
        $result = Get-ContentEx -Path $path -Position $offset
        $result | 
            Add-Member -MemberType NoteProperty -Name Range -Value ($rangeEnd - $rangeStart) -PassThru |
            Select-Object -Property *
            
        if ($null -ne $result.text)
        {
            if ($result.Text -like "$Hash*")
            {
                $compromises = $result.text.Split(':')[-1]
                Write-Warning "Hash is compromised, severity: $compromises"
                break
            }
            elseif ($Hash -gt $result.text)
            {
                $rangeStart = $result.position + $result.text.Length + 1L
            }
            elseif ($Hash -lt $result.text)
            {
                $rangeEnd = $result.position - 2L
            }
        }
        else
        {
            # no text, abort:
            break
        }
    }
}
cls
$hash= Get-Md4Hash
Find-Hash -Hash $hash

Get-ContentEx -Path $path -Position 4GB
Find-Hash -Hash '23FA7E6F0554709DA6E2EA8AA4D13054'
