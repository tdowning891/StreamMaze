#!/usr/bin/env python

#The MIT License (MIT)
#Copyright (c) 2016 Massimiliano Patacchiola
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
#MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
#CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
#SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import cv2
import numpy as np
from deepgaze.color_detection import BackProjectionColorDetector
from deepgaze.mask_analysis import BinaryMaskAnalyser
from deepgaze.motion_tracking import ParticleFilter
import time
import sys
import os

# Setup vairables store the counted frames
count_frames_all = 0
count_frames_motion = 0

template = cv2.imread('template.png') #Load the image

# This will stop unwanted traceback messages 
sys.tracebacklimit = 0

#for the ip camera uses input to the script
video_capture = cv2.VideoCapture(sys.argv[1])

# This will warn the user if the camera cannot be opened
if not video_capture.isOpened(): raise Exception("Camera could not be opened on the edge system!")


# Default resolutions of the frame are obtained.The default resolutions are system dependent.
# We convert the resolutions from float to integer.
res_v = int(video_capture.get(4))
res_h = int(video_capture.get(3))

# Define the codec and create VideoWriter object
fourcc = cv2.VideoWriter_fourcc(*'XVID')
out = cv2.VideoWriter("./out_motion_filter.avi", fourcc, 25.0, (res_h,res_v))
out_motion = cv2.VideoWriter('out_motion.avi',cv2.VideoWriter_fourcc('M','J','P','G'), 10, (res_h,res_v))
out_all = cv2.VideoWriter('out_all.avi',cv2.VideoWriter_fourcc('M','J','P','G'), 10, (res_h,res_v))

#Declaring the binary mask analyser object
my_mask_analyser = BinaryMaskAnalyser()

#Defining the deepgaze color detector object
my_back_detector = BackProjectionColorDetector()
my_back_detector.setTemplate(template) #Set the template 

#Filter parameters
tot_particles = 3000
#Standard deviation which represent how to spread the particles in the prediction phase.
std = 25 
my_particle = ParticleFilter(res_h, res_v, tot_particles)

#Probability to get a faulty measurement
noise_probability = 0.15 #in range [0, 1.0]

#timer variable used to count 30 seconds for program to run, now is current time
timer = 0
now=time.time()

# The while loop and timer vairable are used to run the stream benchmark for exactly 30s 
while(timer < 30):
 
    # Capture frame-by-frame
    ret, frame = video_capture.read()
    if(frame is None): break #check for empty frames

    #Return the binary mask from the bacprojection algorithm
    frame_mask = my_back_detector.returnMask(frame, morph_opening=True, blur=True, kernel_size=5, iterations=2)
    
    #store all frames in output file
    out_all.write(frame)
    count_frames_all = count_frames_all + 1 
    
    if(my_mask_analyser.returnNumberOfContours(frame_mask) > 0):
        #Use the binary mask to find the contour with largest area
        #and the center of this contour which is the point we
        #want to track with the particle filter
        x_rect,y_rect,w_rect,h_rect = my_mask_analyser.returnMaxAreaRectangle(frame_mask)
        
        x_center, y_center = my_mask_analyser.returnMaxAreaCenter(frame_mask)
        
        #save video output file that only shows motion
        out_motion.write(frame)
        count_frames_motion = count_frames_motion + 1
        
        #Adding noise to the coords
        coin = np.random.uniform()
        if(coin >= 1.0-noise_probability): 
            x_noise = int(np.random.uniform(-300, 300))
            y_noise = int(np.random.uniform(-300, 300))
        else: 
            x_noise = 0
            y_noise = 0
        x_rect += x_noise
        y_rect += y_noise
        x_center += x_noise
        y_center += y_noise
        cv2.rectangle(frame, (x_rect,y_rect), (x_rect+w_rect,y_rect+h_rect), [255,0,0], 2) #BLUE rect


    #Predict the position of the target
    my_particle.predict(x_velocity=0, y_velocity=0, std=std)

    #Drawing the particles.
    my_particle.drawParticles(frame)

    #Estimate the next position using the internal model
    x_estimated, y_estimated, _, _ = my_particle.estimate()
    cv2.circle(frame, (x_estimated, y_estimated), 3, [0,255,0], 5) #GREEN dot

    #Resample the particles
    my_particle.resample()

    #Writing in the output file
    out.write(frame)

    # Getting the current time on timer
    end = time.time()
    timer = round(end-now)

#Release the camera
video_capture.release()
out_motion.release()

# Get the size of the entire stream 
command = "du ~/StreamMaze/Edge/python_object_detect/out_all.avi | awk '{printf $1}'"
out_all = os.popen(command).read()

# Get the size of the detected stream
command = "du ~/StreamMaze/Edge/python_object_detect/out_motion.avi | awk '{printf $1}'"
out_motion = os.popen(command).read()

# Print the collected Metrics
print(res_h,"x",res_v,",",count_frames_all,",",count_frames_motion, ",", out_all, ",", out_motion)
