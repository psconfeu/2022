

# create a variable that accepts both strings and securestrings
[SecureString][SecureStringTransform()]$secureText = "Hello"
$secureText

# accepts secure strings...
$secureText = Read-Host -AsSecureString -Prompt Password
$secureText

# accepts string...
$secureText = 'secret'
$secureText