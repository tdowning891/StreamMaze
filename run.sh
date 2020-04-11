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
    

    # Pull the latest version of Stream Maze on Edge and Cloud
    echo "Insuring latest version of StreamMaze is on Edge and Cloud"
    ssh $edge "docker exec test3 bash -c 'cd ~/StreamMaze; git pull'"
    ssh -X -i $cloud_key $cloud "docker exec test3 bash -c 'cd ~/StreamMaze; git pull'"

    echo "Starting Testing"
    #Measure the number of frames captured on local device
    python3 ./stream_frames.py $2 > frames_captured.txt &
    P1=$!
    #open tream on the edge
    ssh $edge "docker exec test3 bash -c '$5 $2 > res$1.txt'" &
    P2=$!
    #open tream on the cloud,ue the webcam
    # ssh -X -i $cloud_key $cloud "$5 $3> res$1.txt" &
    ssh -X -i $cloud_key $cloud "docker exec test3 bash -c '$8 $3 > res$1.txt'" &
    P3=$!

    #wait for all processes
    wait $P1 $P2 $P3
    frames_captured=$(cat frames_captured.txt)

    res=$(ssh $edge "docker exec test3 bash -c 'cat $6res$1.txt && rm $6res$1.txt'")
    # res1=$(ssh -X -i $cloud_key $cloud "cat $6res$1.txt && rm $6res$1.txt")
    res1=$(ssh -X -i $cloud_key $cloud "docker exec test3 bash -c 'cat $9res$1.txt && rm $9res$1.txt'")
    
    echo $7 $4, $1,$frames_captured, $res,$res1
}
run_test()
{

    comment=$3
    if (($2 == 1))
    then 
        echo "Testing motion detection"
        # cmd="cd ~/deepgaze/stream_test/; python3 ex_particle_filter_object_tracking_video.py"
        # cmd2="~/deepgaze/stream_test/"
        cmd="cd ~/StreamMaze/Edge/deepgaze_stream_test/; python3 ex_particle_filter_object_tracking_video.py"
        cmd_c="cd ~/StreamMaze/Cloud/deepgaze_stream_test/; python3 ex_particle_filter_object_tracking_video.py"
        cmd2="~/StreamMaze/Edge/deepgaze_stream_test/"
        cmd2_c="~/StreamMaze/Cloud/deepgaze_stream_test/"
    elif (($2 == 2))
    then
        echo "Testing face detection"
        cmd="cd ~/python_face_detect/; python3 facedetect.py"
        cmd2="~/python_face_detect/"
    else
        echo "Please select a valid test"
        return
    fi

    if (($1 > 3)) || (($1 < 1))
    then
        echo "Please select a number of streams between 1 and 3"
        return
    else
        echo "Testing with up to" $1 "streams."
    fi

    echo "Starting with one stream"
    for i in {1..1}
    do 
        test_stream 1 $local_phone $forward_phone 1 "$cmd" "$cmd2" "$comment" "$cmd_c" "$cmd2_c"
    done 

    if(($1 > 1))
    then 
        echo "Starting with two streams"
        for i in {1..3}
        do 
            test_stream 1 $local_phone $forward_phone 2 "$cmd" "$cmd2" "$comment"&
            P1=$!
            test_stream 2 $local_ipad $forward_ipad 2 "$cmd" "$cmd2" "$comment"&
            P2=$!
            wait $P1 $P2
        done 
    fi

    if(($1 > 2))
    then
        echo "Starting with three streams"
        for i in {1..3}
        do 
            test_stream 1 $local_phone $forward_phone 3 "$cmd" "$cmd2" "$comment"&
            P1=$!
            test_stream 2 $local_ipad $forward_ipad 3 "$cmd" "$cmd2" "$comment"&
            P2=$!
            test_stream 3 $local_phone2 $forward_phone2 3 "$cmd" "$cmd2" "$comment"&
            P3=$!
            wait $P1 $P2 $P3
        done
    fi
}

run_test 1 1 "This is a comment"
