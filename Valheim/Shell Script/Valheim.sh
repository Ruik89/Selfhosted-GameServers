#!/bin/sh

# Am I root?, need root!

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit
fi

# Install steam dependences and steam
sudo yes | add-apt-repository multiverse
sudo yes | apt install software-properties-common
sudo yes | dpkg --add-architecture i386
sudo yes | apt update

# Unable to yes pipe steamcmd will have to maunally accept
echo 'enter "Yes" and accept the license agrement'
sleep -s 5
sudo apt install lib32gcc-s1 steamcmd
sudo yes | apt full-upgrade

# Install Valheim dependences
sudo yes | apt install libatomic1 libpulse-dev libpulse0

#password generator
array=()
for i in {a..z} {A..Z} {0..9};
   do
   array[$RANDOM]=$i
done
valheim_password=$(printf %s ${array[@]::128} $'\n')
echo "$valheim_password"

#Create valhelm user, set random password
sudo useradd -m valheim
yes $valheim_password | passwd valheim
sudo runuser -l valheim -c 'mkdir /home/valheim/server'
cd /home/valheim/

#Install Steam Updates & Install Valheim server files
sudo runuser -l valheim -c 'steamcmd +force_install_dir /home/valheim/server/ +login anonymous +app_update 896660 validate +exit'

#!/bin/bash
#obtain server details

echo "Enter your sever name"
read serverName
echo "Enter your world name"
read worldName
echo "Enter your sever password"
read serverPassword

sed -i "s/'My server'/$serverName/g" /home/valheim/server/start_server.sh
sed -i "s/Dedicated/$worldName/g" /home/valheim/server/start_server.sh
sed -i "s/secret/$serverPassword/g" /home/valheim/server/start_server.sh
sed -i "s/-crossplay/-crossplay -public 0/g" /home/valheim/server/start_server.sh
cat /home/valheim/server/start_server.sh

cp /home/valheim/server/start_server.sh /home/valheim/start_valheim.sh

echo """[Unit]
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
WantedBy=multi-user.target""" > /home/valheim/valheim.service

cp /home/valheim/valheim.service /etc/systemd/system

sudo systemctl enable valheim

sudo systemctl start valheim