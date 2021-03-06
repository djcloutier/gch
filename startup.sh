#!/bin/bash


SPLocation="https://organization.glatt.com/ptpA/sw/gat/Documents/Deployment/"

LocalServer="192.168.101.150"
LocalPath="ptp"
DeployPath="PAD-Development/GIT"
DeployRepo="Deployment"


#define functions *************************************************************
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

installGuiRemote () {
sudo apt install -y --no-install-recommends ubuntu-desktop
sudo apt install -y remmina firefox gedit nautilus-admin xrdp gnome-startup-applications gnome-tweaks p7zip 
curl -L -o ~/teamviewer-host_amd64.deb https://download.teamviewer.com/download/linux/teamviewer-host_amd64.deb
sudo apt install -y ./teamviewer-host_amd64.deb
rm -f ~/teamviewer-host_amd64.deb
rm -f ~/install-gui.sh

read -p "Enter a Teamviewer password" tvpass

sudo teamviewer passwd $tvpass
reboot

}

getDeployRem () {

if [ -d "./${DeployRepo}" ]; then
echo "Found local repository...Using that."
find ./${DeployRepo}/ -type f -iname "*.sh" -exec chmod +x {} \;

#install the GUI
./${DeployRepo}/scripts/install-gui.sh

else
getCredentials

filepath="${SPLocation}getdeployment.sh"
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
fi

}


getDeployLoc () {
getCredentials
mountPAD
DeployRepo="Deployment"
sudo -u glatt git clone --depth 1  "/tmp/pad/${DeployPath}/${DeployRepo}"

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

read -p "Enter shared folder name: (//${LocalServer}/${LocalPath})" padpath
		padpath=${padpath:-//${LocalServer}/${LocalPath}}
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

##intall additional packages
apt install -y nfs-common sshpass openssh-server ovmf cifs-utils
apt install -y -t bionic-backports cockpit cockpit-bridge cockpit-dashboard cockpit-docker cockpit-machines cockpit-networkmanager cockpit-storaged cockpit-system cockpit-ws libguestfs-tools p7zip-full

##install TailScale
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/bionic.gpg | sudo apt-key add -
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/bionic.list | sudo tee /etc/apt/sources.list.d/tailscale.list
apt update
apt install -y tailscale
apt install -y qrencode

#update users
adduser glatt libvirt 
adduser glatt libvirt-qemu
adduser glatt kvm

#create default storage pool
virsh pool-define-as default dir - - - - "/var/lib/libvirt/images"
virsh pool-start default
virsh pool-autostart default

#update path
sudo -u glatt echo "export PATH=/home/glatt/Deployment/scripts/:$PATH" | tee -a  .bashrc > /dev/null

#see if user is inside GAT
if ping -c 1 ${LocalServer} &> /dev/null
then
  	getDeployLoc
else
  	read -p "I can't reach the file server. Are you connected to the Glatt network?(Y)" locGAT
	locGat=${locGAT:-y}

	if  [ "$locGAT" == "y" ];  then
		getDeployLoc
	else
	read -p "Are you a Glatt customer?(Y)" cust
	cust=${cust:-y}
		if  [ "$cust" == "y" ];  then
			installGuiRemote
		else
			read -p "Do you want to start tailscale for VPN access?(Y)" tscale
			if  [ "$tscale" == "y" ];  then
#	show qrcode for tailscale url
				tsURL=$(sudo service tailscaled status | grep -oP "(https)://login.([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?")                           
				echo "To authenticate, visit or scan QR code: "
				echo " "
				echo "   $tsURL"
				echo " "
				qrencode $tsURL -m 2 -t ansi
				echo " "
				echo "Press ENTER key once authentication has succeeded,"
				read -p ""
				sudo tailscale up --accept-routes --advertise-tags=tag:customer,tag:hypervisor
				getDeployLoc
			else
				getDeployRem
			fi
		fi
	fi
fi
