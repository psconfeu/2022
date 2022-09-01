# returns prevalence:
Get-Md4Hash | Test-Md4Hash

# returns boolean:
Get-Md4Hash | Test-Md4Hash -AsBoolean

# scales:
'Sonne', 'P@ssw0rd', 'ghdwiuzebx689', 'secret' | Get-Md4Hash | Test-Md4Hash

# why it is so fast:
Get-MD4Hash -InputData P@ssw0rd | Test-Md4Hash -Verbose
