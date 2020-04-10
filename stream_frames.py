# import the necessary packages
import cv2
import time
import sys

video = cv2.VideoCapture(sys.argv[1])

def count_frames_manual(video):
    # initialize the total number of frames read
    total = 0
    now=time.time()
    timer = 0
    # loop over the frames of the video
    while timer != 30:

		# grab the current frame
        (grabbed, frame) = video.read()
	 
        # check to see if we have reached the end of the
		# video
        if not grabbed:
            break
		# increment the total number of frames read
        total += 1
        end = time.time()
        timer = round(end-now)
    # return the total number of frames in the video file
    return total

num_frames = count_frames_manual(video)

print(num_frames)

