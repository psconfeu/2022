# this variable cannot store empty strings
[ValidateNotNullOrEmpty()][string]$Path = 'c:\somefolder'
# this fails:
$Path = ""

# computername must be a string between 8 and 12 characters:
[ValidateLength(8,12)][string]$computername ='Server2018'

# this works (string is between 8 and 12 char):
$computername = 'Server001'

# this fails (string is too short):
$computername = 'pc1'

# define the legal string values
[ValidateSet('NewYork','London','Berlin')][string]$City = 'Berlin'

# this works:
$city = 'Berlin'

# this fails:
$city = 'Hannover'

# allow any text that starts with "Server", followed by 2 to 4 digits:
[ValidatePattern('^Server\d{2,4}$')][string]$ComputerName = 'Server12'

# works:
$ComputerName = 'Server9999'

# fails:
$ComputerName = 'Server2'
$ComputerName = 'Server12345'


# allow any path that starts with the defined drives:
[ValidateDrive('c','d','env')][string]$Path = 'c:\windows'

# works:
$Path = 'env:username'

# fails:
$Path = 'e:\test'

# allow any path that starts with the defined drives:
[ValidateScript({ Test-Path -Path $_ -PathType Leaf } )][string]$Path = 'c:\windows\explorer.exe'

# works:
$Path = (Get-Process -Id $pid).Path

# fails (does not exist):
$Path = 'e:\doesnotexist.txt'

# fails (is no file):
$Path = 'c:\windows'