# StreamMaze
## Edge vs Cloud Video Streaming Benchmarks

### How to Run
Navigate to the StreamMaze folder:
```./run.sh```

### Dependencies Required on the Local System
The local system is required to run a bash and python script. 

The bash script will run on any linux based system. The python script using open CV therefor the local system will require both to be installed.

* Resources to Install Python:
```
https://www.python.org/downloads/
```
* Resources to Install OpenCV: 
```
https://pypi.org/project/opencv-python/
```

### Dependencies Required on the Edge and Cloud Systems
The Edge and Cloud systems used for testing must be linux based and have docker installed, an install guide for docker can be found below:
```
https://runnable.com/docker/install-docker-on-linux
```
In order for StreamMaze to function properly passphraseless ssh must be setup. You can use the following steps to do so.
* Generate a passphraseless SSH key. If you have you have already generated an SSH key you can skip the following step. 
```
$ ssh-keygen -t rsa -b 2048
Generating public/private rsa key pair.
Enter file in which to save the key (/home/username/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/username/.ssh/id_rsa.
Your public key has been saved in /home/username/.ssh/id_rsa.pub.
```
* Copy your SSH key to both the Edge and Cloud system.
```
$ ssh-copy-id id@server
id@server's password: 
```
* To check it has worked, you should ssh to each system and insure a password is not required.

### First Time Running StreamMaze or Checking for Updates
The StreamMaze application will automatically download and run the docker image before pulling the StreamMaze git repository. If the application has been previosuly run it will check the latest version of the docker container and StreamMaze application are used. The user simply needs to respond 'Y' to the following:
```
Would you like to check for updates or setup the test environment? (Y/N):
Y 
```
### Specifying the IP Address's for the Edge, Cloud and Video Streams
The IP addresses should be specified within the ```input.txt``` file in the following format:
```
cloud_key ~/.ssh/key.pem
cloud_ip id@server
edge_ip parallels@10.211.55.7
local_stream1 http://username:password@192.168.1.1:8554/live
local_stream2 http://username:password@192.168.1.1:8555/live
local_stream3 http://username:password@192.168.1.1:8556/live
forward_stream1 http://username:password@86.182.174.1:8554/live
forward_stream2 http://username:password@86.182.174.1:8555/live
forward_stream3 http://username:password@86.182.174.1:8556/live
```

### Setting Up Video Streams
Any IP video stream can be used as a test platform, simply provide the IP address as previously detailed. StreamMaze has been tested using "IPCamera" on an IPhone and IPad. A link to th e IPCamera app can be found below:
```
https://apps.apple.com/us/app/ipcamera-high-end-networkcam/id570912928
```

### Cloud Platform
StreamMaze has been tested using an AWS EC2 Ubuntu 18.04 LTS instance. For information on how to setup an AWS Instance please see the documentation below:
```
https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html
```

### Edge Platform
StreamMaze has been tested using a Ubuntu 18.04 LTS virtual machine. Parallels ans VirtualBox where both used as hypervisors. 
* VirtualBox Documentation:
```
https://www.virtualbox.org/wiki/Documentation
```
* Parallels Documentation:
```
https://www.parallels.com/uk/products/ras/resources/
```