#!/usr/bin/env bash

# Print the StreamMaze Title
printf "\n / ____| |                          |  \/  | \n |(___ | |_ _ __ ___  __ _ _ __ ___ | \  / | __ _ _______  \n \___ \| __| '__/ _ \/ _\` | '_ \` _ \| |\/| |/ _\` |_  / _ \ \n ____) | |_| | |  __/ (_| | | | | | | |  | | (_| |/ /  __/ \n|_____/ \__|_|  \___|\__,_|_| |_| |_|_|  |_|\__,_/___\___|\n\n\n"

# Retrive the various IP address  for Edge, Cloud and Video Streams from the input.txt file
cloud_key=$(grep cloud_key input.txt | awk '{print $2}')
cloud=$(grep cloud_ip input.txt | awk '{print $2}')
edge=$(grep edge_ip input.txt | awk '{print $2}')
local_stream1=$(grep local_stream2 input.txt | awk '{print $2}')
local_stream3=$(grep local_stream1 input.txt | awk '{print $2}')
local_stream2=$(grep local_stream3 input.txt | awk '{print $2}')
forward_stream1=$(grep forward_stream2 input.txt | awk '{print $2}')
forward_stream3=$(grep forward_stream1 input.txt | awk '{print $2}')
forward_stream2=$(grep forward_stream3 input.txt | awk '{print $2}')

# The setup function will allow the StreamMaze application to setup the edge and cloud enviroment using both a docker and git pull
# If the enviroment is already setup setup will insure the latest version of the dicker and git repo are being used
setup ()
{
    #Pull the docker Container for the Edge and the Cloud
    echo "  >>> Insuring latest version of the Docker is being used for the Edge and Cloud <<<"
    ssh $edge "docker pull tdowning891/qub_4006"

    #if the "test" docker is already there first condition with be true and start the container, else if the container isnt first condition is false and image is ran and docker started
    ssh $edge "docker start test || docker run -t -d --name test -d 875c3cbb2fff"
    ssh -X -i $cloud_key $cloud "docker pull tdowning891/qub_4006"
    ssh -X -i $cloud_key $cloud "docker start test || docker run -t -d --name test -d 875c3cbb2fff"
    printf "\n\n"

    # Pull the latest version of Stream Maze on Edge and Cloud
    echo "  >>> Insuring latest version of StreamMaze is on Edge and Cloud <<<"
    ssh $edge "docker exec test bash -c 'cd ~/StreamMaze; git reset --hard; git pull'"
    ssh -X -i $cloud_key $cloud "docker exec test bash -c 'cd ~/StreamMaze; git reset --hard; git pull'"
    printf "\n\n"
}

# Run the desired application on both the edge and cloud system siltaniously, and store the collected metrics in the output.txt file
test_stream () 
{
    # Variable Definitions:
    #     1 = the strem number
    #     2 = local webcam stream
    #     3 = remote webcam stream
    #     4 = The number of streams being tested
    #     5 = edge command to run test
    #     6 = edge location of output file 
    #     7 = this is a comment on the testing
    #     8 = cloud command to run test
    #     9 = cloud location of output file

    # The start time that the application is ran on the edge and cloud 
    start_t=$(perl -MTime::HiRes -e 'printf("%.0f\n",Time::HiRes::time()*1000)')

    #Measure the number of frames captured on local device
    python3 ./stream_frames.py $2 > frames_captured.txt &
    P1=$!

    #Start the streram processing application on the edge
    ssh $edge "docker exec test bash -c '$5 $2 > res$1.txt'"  &
    P2=$!
 
    #Start the streram processing application on the cloud
    ssh -X -i $cloud_key $cloud "docker exec test bash -c '$8 $3 > res$1.txt'" &
    P3=$!

    #wait for all processes, and record the time the edge and cloud application finish
    wait $P1 
    wait $P2 
    edge_t=$(perl -MTime::HiRes -e 'printf("%.0f\n",Time::HiRes::time()*1000)')
    wait $P3
    cloud_t=$(perl -MTime::HiRes -e 'printf("%.0f\n",Time::HiRes::time()*1000)')

    # Calculate the latency of both the edge and cloud applications 
    edge_latency=$(($edge_t - $start_t - 30000))
    cloud_latency=$(($cloud_t - $start_t - 30000))

    # Retreive the number of frames that where captured locally
    frames_captured=$(cat frames_captured.txt)

    # Colecting the metrics calculated from both the edge and cloud system
    res=$(ssh $edge "docker exec test bash -c 'cat $6res$1.txt && rm $6res$1.txt'")
    res1=$(ssh -X -i $cloud_key $cloud "docker exec test bash -c 'cat $9res$1.txt && rm $9res$1.txt'")
    
    # Store the metrics calculated by both the edge and system in the file output.txt
    echo $7, $4, $1,$frames_captured, $res,$res1, $edge_latency, $cloud_latency >> output.txt
}

# Assign the location variables to run the specified application, run the application once for each repetition
run_test()
{
    # Store the user decripter feild as comment
    comment=$3

    # Sote the number of repetions desired as END
    END=$4

    # If the user selects application 1 the location variables are changed to point to the motion detection algorithm
    if (($2 == 1))
    then 
        echo "Testing motion detection"
        cmd="cd ~/StreamMaze/Edge/deepgaze_stream_test/; python3 ex_particle_filter_object_tracking_video.py"
        cmd_c="cd ~/StreamMaze/Cloud/deepgaze_stream_test/; python3 ex_particle_filter_object_tracking_video.py"
        cmd2="~/StreamMaze/Edge/deepgaze_stream_test/"
        cmd2_c="~/StreamMaze/Cloud/deepgaze_stream_test/"
    # If the user selects application 2 the location variables are changed to point to the object detection algorithm
    elif (($2 == 2))
    then
        echo "Testing object detection"
        cmd="cd ~/StreamMaze/Edge/python_object_detect/; python3 objectdetect.py"
        cmd_c="cd ~/StreamMaze/Cloud/python_object_detect/; python3 objectdetect.py"
        cmd2="~/StreamMaze/Edge/python_object_detect/"
        cmd2_c="~/StreamMaze/Cloud/python_object_detect/"
    else
        # Feedback for invalid response 
        echo "Please select a valid test"
        return
    fi

    if (($1 > 3)) || (($1 < 1))
    then
        # Feedback for invalid response
        echo "Please select a number of streams between 1 and 3"
        return
    fi

    # Call the test_stream method one for each repetion
    for i in $(seq 1 $END);
    do 
        test_stream 1 $local_stream1 $forward_stream1 1 "$cmd" "$cmd2" "$comment" "$cmd_c" "$cmd2_c"
    done 

    # test two streams siltaniously
    if(($1 > 1))
    then 
        # Call the test_stream method one for each repetion
        for i in $(seq 1 $END);
        do 
            test_stream 1 $local_stream1 $forward_stream1 2 "$cmd" "$cmd2" "$comment" "$cmd_c" "$cmd2_c"&
            P1=$!
            test_stream 2 $local_stream2 $forward_stream2 2 "$cmd" "$cmd2" "$comment" "$cmd_c" "$cmd2_c"&
            P2=$!
            wait $P1 $P2
        done 
    fi

    # test three streams siltaniously
    if(($1 > 2))
    then
        # Call the test_stream method one for each repetion
        for i in $(seq 1 $END);
        do 
            test_stream 1 $local_stream1 $forward_stream1 3 "$cmd" "$cmd2" "$comment" "$cmd_c" "$cmd2_c"&
            P1=$!
            test_stream 2 $local_stream2 $forward_stream2 3 "$cmd" "$cmd2" "$comment" "$cmd_c" "$cmd2_c"&
            P2=$!
            test_stream 3 $local_stream3 $forward_stream3 3 "$cmd" "$cmd2" "$comment" "$cmd_c" "$cmd2_c"&
            P3=$!
            wait $P1 $P2 $P3
        done
    fi
}

# This method takes user inputs, controls the CLI and cordinates the running of the application 
run_all()
{
    #remove the out output file, and create a new empty one
    rm output.txt
    touch output.txt
    echo "Descriptor, Stream ID, Number of Streams, Total Frames Local, Resolution, Frames Edge, Detected Frames Edge, Size of Strea, Size of Detected Stream, Frames Cloud, Detected Frames Cloud, Edge Latency, Cloud Latency"  >> output.txt

    # Display the warning to the user stating to place information in input file
    printf "PLEASE INSURE THE CORRECT EDGE, CLOUD & VIDEO STREAM IP ADDRESS ARE STORED WITHIN 'inputs.txt'  \n\n"


    # Check if the cloud and edge systems are online
    test=$(echo $cloud | awk -F '@' '{print $2}')
    test2=$(echo $edge | awk -F '@' '{print $2}')
    if nc -z -G 3  $test 22 &> /dev/null; then
        printf "Cloud Test System Online \n"
    else
        echo  "Cloud Test System Offline" 
        exit 1 
    fi

    if nc -z -G 3  $test2 22 &> /dev/null; then
        printf "Edge Test System Online \n"
    else
        echo  "Edge Test System Offline" 
        exit 1 
    fi
    
    #Check for setup / update
    printf "\n\nWould you like to check for updates or setup the test environment? (Y/N):  "
    read update

    if [ "$update" != "Y" ] && [ "$update" != "N" ]; then
        printf "Please Select a Valid Input \n"
        return
    elif [ "$update" = "Y" ]; then
        setup
    fi

    #Which benchmark Application
    printf "\nWhat stream processing application would you like to benchmark?:  "
    printf "\n      1. Motion Detection  "
    printf "      2. Object Detection  \n"
    printf "Application: "
    read app
    if [ "$app" != "1" ] && [ "$app" != "2" ]; then
        printf "Please Select a Valid Input \n"
        return
    fi
    
    #Use how many streams?
    printf "\nPlease Select the maximium number of video streams you want to use for testing (1, 2, 3): "
    read stream_num
    if [ "$stream_num" != "1" ] && [ "$stream_num" != "2" ] && [ "$stream_num" != "3" ]; then
        printf "Please Select a Valid Input \n"
        return
    fi

    #Use how many replicates?
    printf "\nHow many test replicates: "
    read reps
    re='^[0-9]+$'
    if ! [[ $reps =~ $re ]] ; then
        printf "Please enter a number \n"
        return
    fi
   
    #add comment to help identify benchmark
    printf "\nPlease add a benchmark Description e.g. Low Light:"
    read comment 

    #run the benchmark
    printf "\n\nRunning benchamrk with $stream_num stream(s) and $reps replicate(s)\n"
    run_test $stream_num $app $comment $reps
}

run_all