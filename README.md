# StreamMaze
## Edge vs Cloud Video Streaming Benchmarks

### How to Run
navigate to the StreamMaze folder:
```./run.sh```

### Dependencies Required on the Local System
The local system is required to run a bash and python script. 

The bash script will run on any linux based system. The python script using open CV therefor the local system will require both to be installed.

Resources to Install Python:
```https://www.python.org/downloads/```
Resources to Install OpenCV: 
```https://pypi.org/project/opencv-python/```

### Dependencies Required on the Edge and Cloud Systems
The Edge and Cloud systems used for testing must be linux based and have docker installed, an install guide for docker can be found below:
```https://runnable.com/docker/install-docker-on-linux```
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
* To check it has worked, you should login to each system and insure a password is not required.

### First Time Running StreamMaze or Checking for Updates
The StreamMaze application will automatically download and run the docker image before pulling the StreamMaze git repository. If the application has been previosuly run it will check the latest version of the docker container and StreamMaze application are used. The user simply needs to respond 'Y' to the following:
```Would you like to check for updates or setup the test environment? (Y/N): \n```
```Y ```
### Specifying the IP Address's for the Edge, Cloud and Video Streams


### Setting Up Video Streams

### Cloud Platform
* StreamMaze has been tested using an AWS EC2 Ubuntu 18.04 LTS instance.
* Create an AWS account and create an IAM user with the necessary privileges.
* Update the local .ssh and .aws with the IAM users credentials (secret access keys) on the user device and Edge Nodes.

AWS documentation can be found at: 
```https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html```

### Edge Platform
* StreamMaze has been tested using an AWS EC2 Ubuntu 18.04 LTS instance.
* Update the local .aws with the IAM users credentials on the edge Edge Nodes.
* Update the local .ssh with an `authorized_keys` file, containing the generated public rsa ssh key on the user device. Use ssh or scp to add this file to the .ssh folder.


### How to run Motion Detection / Object Detection


