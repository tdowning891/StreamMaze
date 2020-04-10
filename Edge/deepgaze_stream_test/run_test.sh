#!/usr/bin/env bash

#length of out_all
out_all_time=$(ffprobe -i out_all.avi -show_entries format=duration -v quiet -of csv='p=0' | awk '{print $1}')
#length of out_motion
out_motion_time=$(ffprobe -i out_motion.avi -show_entries format=duration -v quiet -of csv='p=0' | awk '{print $1}')
#calc precentage motion
calc_time=$(echo "$out_all_time $out_motion_time" | awk '{print $2/$1*100}')

#size of out_all
out_all_size=$(du out_all.avi | awk '{print $1}')
#size of out_motion
out_motion_size=$(du out_motion.avi | awk '{print $1}')
#calc precentage of memory saved
calc_size=$(echo "$out_all_size $out_motion_size" | awk '{print ($1-$2)/$1*100}')


echo Precentage of time there is motion: $calc_time
echo Precentage of bandwidth saved by only sending motion: $calc_size

#creating temp to return data
TMP=$(mktemp)
#send the sample mp4 file to edge system

