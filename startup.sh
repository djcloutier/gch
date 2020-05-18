#!/bin/bash
#define functions *************************************************************

baselocation="https://organization.glatt.com/ptpA/sw/gat/Documents/Deployment/"

getDeploy () {
echo "************************************************"
echo "******Please enter your Glatt credentials.******"
echo "************************************************"
echo
echo
read -p "Enter your username: " username
read -s -p "Enter your password: " password
echo
echo "Checking credentials"

filepath="${baselocation}getdeployment.sh"
wget -q --no-check-certificate --load-cookies cookies.txt --keep-session-cookies --user=$username --password=$password $filepath

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

# check for root privilege
if [ "$(id -u)" != "0" ]; then
   echo " this script must be run as root"
   echo
   sudo "$0" "$@"
   exit $?
fi

getDeploy
