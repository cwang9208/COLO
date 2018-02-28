... and tell your mediatomb to transcode that, using an mencoder profile...
```
<transcode mimetype="video/subtitle" using="mencoder-srt"/>
```
...and have your mencoder-srt profile have a script as agent...
```
<agent command="/usr/local/bin/mediatomb-mencoder-srt" arguments="%in %out"/>
```
...and have this as mediatomb-mencoder-srt content...
```
#!/bin/bash
srt="$1"
output="$2"
# filename must be of the form "movie name.XX[X].srt" or "movie name.srt"
base_name="$(echo $srt | sed 's/\..\{2,3\}\.srt$//' | sed 's/\.srt$//')"

extensions="avi mp4 mpg mov"
for ext in $extensions ; do
    input=$base_name.$ext;

    # True if $input exists.
    if [[ -e $input ]]; then break; fi
done

exec mencoder "$input" \
-oac lavc -ovc lavc -of mpeg \
-lavcopts vcodec=mpeg2video:keyint=1:vbitrate=200000:vrc_maxrate=9000:vrc_buf_size=1835 \
-vf harddup -mpegopts muxrate=12000 \
-sub "$srt" -font "/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf" -subfont-autoscale 2 \
-o "$output"
```
