#!/bin/bash

#This script will pull the latest code and proper dependancies for opensource xen-orchestra.

#see the xo project at https://github.com/vatesfr/

set -e

install_root="/opt/"

##Main Script##

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

os=$(uname -n)

##if [ $os != "ubuntu" -o $os != "debian" ]
#	then
#	 echo "Operating system $os is not compatible!"
#	 exit 1
#fi

case "$os" in
	"ubuntu" )
		;;	
	"debian" )
		;;
	* )
		echo "Operating system $os is not compatible!"
		exit 1
		;;
esac

##check for prerequisits
command -v curl >/dev/null 2 || { sudo apt-get install -qq curl >&2; }

dpkg-query -W -f='${Status}' apt-transpot-https 2>/dev/null | grep -c "ok installed" || { sudo apt-get install -qq apt-transport-https >&2; }

echo "OS is compatible."
echo "Proceeding with install ..."

echo "Preparing files"
cp ./patches/xo_server_mod-config.patch /tmp/

echo "Installing nodejs and npm"
curl --progress-bar -o /usr/local/bin/n https://raw.githubusercontent.com/visionmedia/n/master/bin/n

chmod +x /usr/local/bin/n
n lts

echo "Installing npm"
##fixes bug with n instalation of node and updates npm"
curl -0 --progress-bar -L https://npmjs.com/install.sh | sudo sh

echo "Adding Yarn Sources"
curl -sS --progress-bar https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

echo "Updating apt"
apt-get update -qq

echo "Installing dependancies from apt"
apt-get install -qq build-essential redis-server libpng-dev git python-minimal yarn

##clone xo repos
echo "Cloning repositories"

#check for existing repo and remove
if [ -d "${install_root}xo-server/" ]; then 
	rm -rf "${install_root}xo-server/"
fi

git clone -b stable https://github.com/vatesfr/xo-server ${install_root}xo-server/

#check for existing repo and destory
if [ -d "${install_root}xo-web/" ]; then
	rm -rf "${install_root}xo-web/"
fi
git clone -b stable https://github.com/vatesfr/xo-web ${install_root}xo-web/

##apply config patch to sample config
cd ${install_root}/xo-server

git apply /tmp/xo_server_mod-config.patch

##copy config to etc directory
if [ ! -d "/etc/xo-server" ]; then
	mkdir /etc/xo-server/
fi

cp ./sample.config.yaml /etc/xo-server/config.yaml

##building xo-server
echo "Building XO-Server"

yarn --non-interactive 


echo "Building XO-Web"

cd ../xo-web

yarn --non-interactive

echo "Yay. All installed"
