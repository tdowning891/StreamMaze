#!/usr/bin/env python

#The MIT License (MIT)
#Copyright (c) 2016 Massimiliano Patacchiola
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
#MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
#CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
#SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#In this example the Particle Filter is used in order to stabilise some noisy detection.
#The Backprojection algorithm is used in order to find the pixels that have the same HSV 
#histogram of a predefined template. The template is a subframe of the main image or an external
#matrix that can be used as a filter. We track the object taking the contour with the largest area
#returned by a binary mask (blue rectangle). The center of the contour is the tracked point. 
#To test the Particle Filter we inject noise in the measurements returned by the Backprojection. 
#The Filter can absorbe the noisy measurements, giving a stable estimation of the target center (green dot).

#COLOR CODE:
#BLUE: the rectangle containing the target. Noise makes it shaky (unstable measurement).
#GREEN: the point estimated from the Particle Filter.
#RED: the particles generated by the filter.
count_frames_all = 0
count_frames_motion = 0
import cv2
import numpy as np
from deepgaze.color_detection import BackProjectionColorDetector
from deepgaze.mask_analysis import BinaryMaskAnalyser
from deepgaze.motion_tracking import ParticleFilter
import time
import sys

# from time import process_time

#Set to true if you want to use the webcam instead of the video.
#In this case you have to provide a valid tamplate, it can be
#a solid color you want to track or a frame containint your face.
#Substitute the frame to the default template.png.
USE_WEBCAM = True

template = cv2.imread('template.png') #Load the image

if(USE_WEBCAM == False):
    video_capture = cv2.VideoCapture("./cows.avi")
else:
    #video_capture = cv2.VideoCapture(0) #Open the webcam
    video_capture = cv2.VideoCapture(sys.argv[1])


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
#Standard deviation which represent how to spread the particles
#in the prediction phase.
std = 25 
my_particle = ParticleFilter(res_h, res_v, tot_particles)
#Probability to get a faulty measurement
noise_probability = 0.15 #in range [0, 1.0]

time_motion = 0
now=time.time()
timer = 0
#x_center = res_h/2
#y_center = res_v/2
while(timer < 30):
    

    # Capture frame-by-frame
    ret, frame = video_capture.read()
    if(frame is None): break #check for empty frames

    #Return the binary mask from the bacprojection algorithm
    frame_mask = my_back_detector.returnMask(frame, morph_opening=True, blur=True, kernel_size=5, iterations=2)
    
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

        #Update the filter with the last measurements
        #my_particle.update(x_center, y_center)

    #Predict the position of the target
    my_particle.predict(x_velocity=0, y_velocity=0, std=std)

    #Drawing the particles.
    my_particle.drawParticles(frame)

    #Estimate the next position using the internal model
    x_estimated, y_estimated, _, _ = my_particle.estimate()
    cv2.circle(frame, (x_estimated, y_estimated), 3, [0,255,0], 5) #GREEN dot

    #Update the filter with the last measurements
   # my_particle.update(x_center, y_center)

    #Resample the particles
    my_particle.resample()

    #Writing in the output file
    out.write(frame)

    #Showing the frame and waiting
    #for the exit command
    # cv2.imshow('Original Edge', frame) #show on window
    # cv2.imshow('Mask Edge', frame_mask) #show on window
    if cv2.waitKey(1) & 0xFF == ord('q'): break #Exit when Q is pressed
    
    end = time.time()
    timer = round(end-now)

#Release the camera
video_capture.release()
out_motion.release()

import os 
command = "du ~/StreamMaze/Edge/python_object_detect/out_all.avi | awk '{printf $1}'"
out_all = os.popen(command).read()
command = "du ~/StreamMaze/Edge/python_object_detect/out_motion.avi | awk '{printf $1}'"
out_motion = os.popen(command).read()
print(res_h,"x",res_v,",",count_frames_all,",",count_frames_motion, ",", out_all, ",", out_motion)
