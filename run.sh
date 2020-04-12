#!/usr/bin/env bash
cloud_key=""~/.ssh/ubuntu_aws.pem""
cloud="ubuntu@ec2-52-30-255-12.eu-west-1.compute.amazonaws.com"
edge="parallels@10.211.55.7"
local_phone="http://admin:admin@192.168.1.83:8554/live"
local_ipad="http://admin:admin@192.168.1.73:8555/live"
local_phone2="http://admin:admin@192.168.1.86:8556/live"

forward_phone="http://admin:admin@86.157.196.185:8554/live"
forward_ipad="http://admin:admin@86.157.196.185:8555/live"
forward_phone2="http://admin:admin@86.157.196.185:8556/live"

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


test_stream () 
{
    # Variable Meanings:
    #     1 = the strem number
    #     2 = local webcam stream
    #     3 = remote webcam stream
    #     4 = The number of streams being tested
    #     5 = edge command to run test
    #     6 = edge location of output file 
    #     7 = this is a comment on the testing
    #     8 = cloud command to run test
    #     9 = cloud location of output file
    
    #Measure the number of frames captured on local device
    python3 ./stream_frames.py $2 > frames_captured.txt &
    P1=$!
    #open tream on the edge
    ssh $edge "docker exec test bash -c '$5 $2 > res$1.txt'" &
    P2=$!
    #open stream on the cloud,ue the webcam
    # ssh -X -i $cloud_key $cloud "$5 $3> res$1.txt" &
    ssh -X -i $cloud_key $cloud "docker exec test bash -c '$8 $3 > res$1.txt'" &
    P3=$!

    #wait for all processes
    wait $P1 $P2 $P3
    frames_captured=$(cat frames_captured.txt)

    res=$(ssh $edge "docker exec test bash -c 'cat $6res$1.txt && rm $6res$1.txt'")
    # res1=$(ssh -X -i $cloud_key $cloud "cat $6res$1.txt && rm $6res$1.txt")
    res1=$(ssh -X -i $cloud_key $cloud "docker exec test bash -c 'cat $9res$1.txt && rm $9res$1.txt'")
    
    echo $7 $4, $1,$frames_captured, $res,$res1
}
run_test()
{
    
    comment=$3
    END=$4
    if (($2 == 1))
    then 
        echo "Testing motion detection"
        cmd="cd ~/StreamMaze/Edge/deepgaze_stream_test/; python3 ex_particle_filter_object_tracking_video.py"
        cmd_c="cd ~/StreamMaze/Cloud/deepgaze_stream_test/; python3 ex_particle_filter_object_tracking_video.py"
        cmd2="~/StreamMaze/Edge/deepgaze_stream_test/"
        cmd2_c="~/StreamMaze/Cloud/deepgaze_stream_test/"
    elif (($2 == 2))
    then
        echo "Testing object detection"
        cmd="cd ~/StreamMaze/Edge/python_object_detect/; python3 objectdetect.py"
        cmd_c="cd ~/StreamMaze/Cloud/python_object_detect/; python3 objectdetect.py"
        cmd2="~/StreamMaze/Edge/python_object_detect/"
        cmd2_c="~/StreamMaze/Cloud/python_object_detect/"
    else
        echo "Please select a valid test"
        return
    fi

    if (($1 > 3)) || (($1 < 1))
    then
        echo "Please select a number of streams between 1 and 3"
        return
    fi

    for i in $(seq 1 $END);
    do 
        test_stream 1 $local_phone $forward_phone 1 "$cmd" "$cmd2" "$comment" "$cmd_c" "$cmd2_c"
    done 

    if(($1 > 1))
    then 
        for i in $(seq 1 $END);
        do 
            test_stream 1 $local_phone $forward_phone 2 "$cmd" "$cmd2" "$comment" "$cmd_c" "$cmd2_c"&
            P1=$!
            test_stream 2 $local_ipad $forward_ipad 2 "$cmd" "$cmd2" "$comment" "$cmd_c" "$cmd2_c"&
            P2=$!
            wait $P1 $P2
        done 
    fi

    if(($1 > 2))
    then
        for i in $(seq 1 $END);
        do 
            test_stream 1 $local_phone $forward_phone 3 "$cmd" "$cmd2" "$comment" "$cmd_c" "$cmd2_c"&
            P1=$!
            test_stream 2 $local_ipad $forward_ipad 3 "$cmd" "$cmd2" "$comment" "$cmd_c" "$cmd2_c"&
            P2=$!
            test_stream 3 $local_phone2 $forward_phone2 3 "$cmd" "$cmd2" "$comment" "$cmd_c" "$cmd2_c"&
            P3=$!
            wait $P1 $P2 $P3
        done
    fi
}

run_all()
{
    #Check for setup / update
    printf "Would you like to check for updates or setup test enviroment? (Y/N):  "
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
    printf "\nPlease Select the number of video streams you want to use for testing(1, 2, 3): "
    read stream_num
    if [ "$stream_num" != "1" ] && [ "$astream_numpp" != "2" ] && [ "$astream_numpp" != "3" ]; then
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
    printf "\n\nRunning benchamrk with $stream_num stream(s) and $reps replicates\n"
    run_test $stream_num $app $comment $reps
}

run_all