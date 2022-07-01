###################################
## Concatenating files with FFMPEG
###################################

## Re-encoding
& $ffmpeg -i $intro -i $newfile -i $outro -filter_complex "[0:v:0][0:a:0][1:v:0][1:a:0][2:v:0][2:a:0]concat=n=3:v=1:a=1[outv][outa]" -map "[outv]" -map "[outa]" $newfile.Replace('.MP4','InOut.MP4')

## Concatening 
& $ffmpeg -f concat -safe 0 -i mylist.txt -c copy $newfile.Replace('.MP4','InOut.MP4')
       