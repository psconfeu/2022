param($ProtocolUri)
$ProtocolUri
$Path = $ProtocolUri.Replace("psu://", "").TrimEnd("/")
$Path
Start-Process $Path