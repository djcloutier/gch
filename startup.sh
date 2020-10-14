#!/bin/bash
#define functions *************************************************************

baselocation="https://organization.glatt.com/ptpA/sw/gat/Documents/Deployment/"

getCredentials () {

if [ "$username" == "" ]; then
if [[ $graphical == "true" ]]; 
then
username=$(zenity --entry --text="Enter your Glatt username (email address)");
password=$(zenity --password --text="Enter your password" );
else
	echo "************************************************"
	echo "******Please enter your Glatt credentials.******"
	echo "************************************************"
	echo
	echo
	read -p "Enter your username (email address): " username
	read -s -p "Enter your password: " password
	echo
	fi
fi

}

getDeployRem () {
getCredentials

filepath="${baselocation}getdeployment.sh"
wget -q --no-check-certificate --user=$username --password=$password $filepath

if [ "$?" = "0" ]; then
		echo "Login successful"
		
		#strip carriage returns from text file in case it was saved in DOS format
                sed -i -e 's/\r//g' ~/getdeployment.sh
		
		chmod +x ~/getdeployment.sh
		exec ~/getdeployment.sh $username $password
		rm ~/startup.sh
		exit 1
		
	
else
		credsStatus="fail"
		read -p "Invalid login. Try again?" retry
		retry=${retry:-y}

		if  [ "$retry" == "y" ];  then
		    getDeploy
		fi

fi

}

getDeployLoc () {
getCredentials
mountPAD
DeployRepo="Deployment"
git clone --depth 1  "/tmp/pad/Development/GIT/${DeployRepo}"

for file in ./${DeployRepo}/scripts/*
do
  chmod +x "$file"
done

unmountPAD

#install the GUI
./${DeployRepo}/scripts/install-gui.sh
}

unmountPAD () {
umount /tmp/pad
}

mountPAD () {

read -p "Enter shared folder name: (//192.168.101.108/EEDIV$/PAD)" padpath
		padpath=${padpath:-//192.168.101.108/EEDIV$/PAD}
		mkdir /tmp/pad
		umount /tmp/pad

mountstring="username=${username},password=${password} ${padpath} /tmp/pad"
sudo mount -t cifs -o $mountstring
}

# check for root privilege
if [ "$(id -u)" != "0" ]; then
   echo " this script must be run as root"
   echo
   sudo "$0" "$@"
   exit $?
fi

#see if user is inside GAT
if ping -c 1 192.168.101.108 &> /dev/null
then
  getDeployLoc
else
  read -p "I can't reach the file server. Are you connected to the Glatt network?(Y)" locGAT
locGat=${locGAT:-y}

if  [ "$locGAT" == "y" ];  then
	getDeployLoc

else
	getDeployRem
fi
fi
