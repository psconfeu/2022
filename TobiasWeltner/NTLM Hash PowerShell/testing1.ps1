
# test it:

$Path = 'C:\NTLMHashes\pwned-passwords-ntlm-ordered-by-hash-v8.txt'
$file = Get-Item -Path $Path
$size = $file.Length

# reading takes the same time, regardless of where inside the file:
Get-ContentEx -Path $path -Position 100
Get-ContentEx -Path $path -Position ($size/2)