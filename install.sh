#!/bin/bash

#This script will pull the latest code and proper dependancies for opensource xen-orchestra.

#see the xo project at https://github.com/vatesfr/

set -e

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
	"debian" )
		;;
	* )
		echo "Operating system $os is not compatible!"
		exit 1
		;;
esac

##check for prerequisits
command -v curl >/dev/null 2 || { sudo apt-get install -qq curl >&2; }

dpkg-query -W -f='${Status}' apt-transpot-https 2>/dev/null | grep -c "ok installed" || {sudo apt-get install -qq apt-transport-https; }

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

git clone -b stable https://github.com/vatesfr/xo-server /opt/xo-server/
git clone -b stable https://github.com/vatesfr/xo-web /opt/xo-web/

##apply config patch to sample config
cd /opt/xo-server

git apply /tmp/xo_server_mod-config.patch

##copy config to etc directory
mkdir /etc/xo-server/

cp ./sample.config.yaml /etc/xo-server/config.yaml

##building xo-server
echo "Building XO-Server"

yarn --non-interactive && yarn run build


echo "Building XO-Web"

cd ../xo-web

yarn --non-interactive && yarn run build

echo "Yay. All installed"
