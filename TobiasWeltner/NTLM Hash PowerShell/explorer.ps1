# download and unpack this huge file first
# you can download it from here: https://haveibeenpwned.com/Passwords
# make sure you select the version ORDERED BY HASH with NTLM hashes!

# I already downloaded it, and on my machine it is located here:
$Path = 'C:\NTLMHashes\pwned-passwords-ntlm-ordered-by-hash-v8.txt'

explorer /select,$Path
$file = Get-Item -Path $Path

$file.Length
'{0:n1}GB' -f ($file.Length/1GB)

# read a small portion of the HUGE file:
Get-Content -Path $path -TotalCount 300