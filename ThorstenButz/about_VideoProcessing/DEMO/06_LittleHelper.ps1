##################
## Little helpers
##################
function Get-MP4Duration {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [ValidateScript({ Test-Path -Path $_ })]
    [string] $File,
    [switch] $asTimeSpanObject
  )
  process {
    [System.IO.FileSystemInfo ] $file = Get-Item -Path $file
    $shellObj = New-Object -ComObject Shell.Application 
    $folderObj = $shellObj.Namespace("$($file.Directory)")
    $fileObj = $folderObj.ParseName("$($file.Name)")
    $duration = $folderObj.GetDetailsOf($fileObj, 27)
    ## Create a TimeSpan object    
    $durationArray = $duration.Split(':')
    if ($asTimeSpanObject) { New-TimeSpan -Hours $durationArray[0] -Minutes $durationArray[1] -Seconds $durationArray[2] } else { $duration }
  }
}