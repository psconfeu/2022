# use this function if you do not want to test NTLM hashes but 
# would like to test plain-text passwords
# the function turns plain text into NTLM hashes for you:


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
