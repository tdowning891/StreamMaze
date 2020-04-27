import cv2
import sys
import logging as log
import datetime as dt
import time
from time import sleep

# Specify the haar cascade classifier to be used 
cascPath = "haarcascade_frontalface_default.xml"
faceCascade = cv2.CascadeClassifier(cascPath)
log.basicConfig(filename='webcam.log',level=log.INFO)

# This will stop unwanted traceback messages 
sys.tracebacklimit = 0

#for the ip camera uses input to the script
video_capture = cv2.VideoCapture(sys.argv[1])

# This will warn the user if the camera cannot be opened
if not video_capture.isOpened(): 
    raise Exception("Camera could not be opened on the cloud system!")
    exit()

# Default resolutions of the frame are obtained.The default resolutions are system dependent.
# We convert the resolutions from float to integer.
res_v = int(video_capture.get(4))
res_h = int(video_capture.get(3))

# Define the codec and create VideoWriter object
fourcc = cv2.VideoWriter_fourcc(*'XVID')
out_motion = cv2.VideoWriter('out_motion.avi',cv2.VideoWriter_fourcc('M','J','P','G'), 10, (res_h,res_v))
out_all = cv2.VideoWriter('out_all.avi',cv2.VideoWriter_fourcc('M','J','P','G'), 10, (res_h,res_v))

anterior = 0

#variables to store the number of frames
count_frames_all = 0
count_frames_motion = 0

#timer variable used to count 30 seconds for program to run, now is current time
timer = 0
now=time.time()

# The while loop and timer vairable are used to run the stream benchmark for exactly 30s 
while (timer < 30):
    if not video_capture.isOpened():
        print('Unable to load camera.')
        sleep(5)
        pass

    # Capture frame-by-frame
    ret, frame = video_capture.read()

    #count all the frames
    count_frames_all = count_frames_all + 1

    #store all frames in output file
    out_all.write(frame)
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # Setup the object 
    faces = faceCascade.detectMultiScale(
        gray,
        scaleFactor=1.1,
        minNeighbors=5,
        minSize=(30, 30)
        )
    
    # If there is at least one object detected
    if len(faces) > 0:

        # Draw a rectangle around the faces
        for (x, y, w, h) in faces:
            cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 255, 0), 2)

        if anterior != len(faces):
            anterior = len(faces)
            log.info("faces: "+str(len(faces))+" at "+str(dt.datetime.now()))

        #save video output file that only shows motion
        out_motion.write(frame)

        #count the number of frames showing motion
        count_frames_motion = count_frames_motion + 1

    # Getting the current time on timer
    end = time.time()
    timer = round(end-now)

# When everything is done, release the capture
video_capture.release()
out_all.release()
out_motion.release()
cv2.destroyAllWindows()

# Print the collected metrics 
print(count_frames_all,",",count_frames_motion)
