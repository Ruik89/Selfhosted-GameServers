## Overview

This guide is for setting up a Valheim server on a newly spun up ubuntu server. 
Below is a chart for the minimum and recommended requirements for the server

|               | Minimum                       | Recommended                   |
| ------------- | ----------------------------- | ----------------------------- |
| CPU           | Quad-Core Processor (4 Cores) | Hexa-Core Processor (6 Cores) |
| CPU Frequency | 2.8 GHz                       | 3.4 GHz+                      |
| RAM           | 2 GB                          | 4 GB+                         |
| Storage       | 2 GB                          | 4 GB+                         |
## Install Server files

Install steam dependences and steam

```
sudo add-apt-repository multiverse
sudo apt install software-properties-common
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install lib32gcc-s1 steamcmd
```

Install Valheim dependences
```
sudo apt install libatomic1 libpulse-dev libpulse0
```

Create valhelm user
Change to root user 
```
sudo useradd -m valheim -s /bin/bash sudo
sudo passwd valheim
```

Change to user make a dir for the server files and cd to the server file folder
```
sudo -u valheim 
mkdir /home/valheim/server
cd /home/valheim/server/
```

initialize steamcmd then exit
```
steam cmd
quit
```

Install the server files into the server folder
```
steamcmd +login anonymous +force_install_dir /home/valheim/server/ +app_update 896660 validate +exit
```

The above command can also be used to update the server if needed to it is recommended to save this has a shell script with the name update_valheim.sh

## Configure Server

Edit the startup script 
```
/home/valheim/server/start_server.sh
```

Example below
```
#!/bin/bash
export templdpath=$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
export SteamAppId=892970

echo "Starting server PRESS CTRL-C to exit"

# Tip: Make a local copy of this script to avoid it being overwritten by steam.
# NOTE: Minimum password length is 5 characters & Password cant be in the server name.
# NOTE: You need to make sure the ports 2456-2458 is being forwarded to your server through your local router & firewall.
./valheim_server.x86_64 -name "<Server Name>" -port 2456 -world "<World Name>" -password "<Server Password>" -crossplay -public 0

export LD_LIBRARY_PATH=$templdpath

```

Change all values in-between <> (including the <>) Description for each value below
1. \<Server Name> - Name of the server as seen on the community server list
2. \<World Name> - Name of the Valheim world
3. \<Server Password> - Password to enter the world (I recommend setting this to a randomly generated 32 character string)

As a note -public 0 is set to make the server private. Set this to 1 for it to show up in the community server list

When the server files are updated the start_server.sh script will be overwritten so we will copy this file to a new file call start_valheim.sh
```
cp /home/valheim/server/start_server.sh /home/valheim/start_valheim.sh
```

Test the server so we can make sure the script works 
```
cd /home/valheim
. start_valheim.sh
```

If this does not work then you'll have to troubleshoot why

## Create a Service

Once the server is confirmed to be working we will want to create a service
```
nano /home/valheim/valheim.service
```

If you followed along exactly you do not need to make any changes to the below file just save it to the home dir
```
[Unit]
Description=Valheim service
Wants=network.target
After=syslog.target network-online.target

[Service]
Type=simple
Restart=on-failure
RestartSec=10
User=valheim
WorkingDirectory=/home/valheim/server
ExecStart=/bin/sh /home/valheim/start_valheim.sh

[Install]
WantedBy=multi-user.target
```
Note, this will cause the game server to start on reboot

Now we'll create the service

1. Copy the file to `/etc/systemd/system`.
2. Activate the service so that systemd can start the service: `sudo systemctl enable valheim` (don't include the `.service` part here).
3. Start the service: `sudo systemctl start valheim`.
4. Check the server status and see if it's actually running: `sudo systemctl status valheim`.

If everything was set up correctly, the output of step 4 will show a line that looks something like this (truncated for brevity):
```
● valheim.service - Valheim service
	Loaded: loaded (/etc/systemd/system/valheim.service; enabled; vendor preset: enabled)
    Active: active (running)
```

In the event the server does not start I recommend running the base sh script to confirm there are no problems with the script/server itself. If it is able to run then verify the Valheim.service is correct.

## Security control

Create ufw (UncomplicatedFirewall) rules to restrict peoples access of the server

```
sudo ufw allow 22
sudo ufw enable
sudo ufw allow 2465
sudo ufw allow 2467
```
Note the server can still send communications from ports outside this list. I.E. the server can send a tftp request but is unable to retrieve any information from it. This means a Blind OS Command Injection attack is possible.

Reasoning for each port below
1. 22 - ssh port
2. 2465 - game server port
3. 2467 - server query port

The Valheim user / VM is only designed to run the server so we will need to reel in the permission given to the user

```
usermod valheim -s /no/shell 
gpasswd -d valheim sudo
```

Reasoning for each command
1. usermod - removed shell access
2.  gpasswd removes the user from the sudo group (cant use sudo anymore)

## Port Forwarding

In the event you wish for anyone not in your Lan to play on this server you will need to setup Port forwarding for the below ports

1.  2465 - Game server port
2. 2467 - Server query port

This step is unique to every individual so it is recommended to lookup your gateways name with "Port Forwarding" in google

