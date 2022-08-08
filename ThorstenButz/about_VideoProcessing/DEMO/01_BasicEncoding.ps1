######################################################
## Basic commands to encode video footage with FFMPEG
######################################################

$ffmpeg    = 'C:\bin\ffmpeg\bin\ffmpeg.exe'
$ffprobe   = 'C:\bin\ffmpeg\bin\ffprobe.exe'
$videofile = 'C:\aboutVideoProcessing\TobiasInterview\IMG_1713.MOV'
$newfile   = 'C:\aboutVideoProcessing\TobiasInterview\IMG_1713_30fps.MP4'
$intro     = 'C:\aboutVideoProcessing\IntroOutro\IntroPSConfEU2022.mp4'
$outro     = 'C:\aboutVideoProcessing\IntroOutro\OutroPSConfEU2022.mp4'
$start     = '00:00:08'
$end       = '00:06:16'

## A: Check the current video length 
Import-Module -Name 'C:\aboutVideoProcessing\VideoProcessing.psm1'
Get-MP4Duration -File $videofile -asTimeSpanObject

## B: Check the current dimensions
& $ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of csv=s=x:p=0 $videofile

## C: Basic file encoding (with cutting) 
& $ffmpeg -i $videofile -c:v libx264 -crf 23 -maxrate 1M -bufsize 2M $newfile  
& $ffmpeg -i $videofile -c:v libx264 -crf 23 -maxrate 1M -bufsize 2M -filter:v fps=30 $newfile  

## D: File encoding and cutting 
& $ffmpeg -ss $start -i $videofile -to $end -c:v libx264 -crf 23 -maxrate 1M -bufsize 2M -filter:v fps=30 $newfile 