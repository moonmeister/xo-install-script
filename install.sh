#!/bin/bash

#This script will pull the latest code and proper dependancies for opensource xen-orchestra.

#see the xo project at https://github.com/vatesfr/

os=$(uname -n)
echo $os

if [ $os != "ubuntu" ]
	then
	 echo "Operating system $os is not compatible!"
	 exit
fi

echo "OS is compatible."
echo "Proceeding with install ..."

echo "Installing nodejs and npm"
curl -o /usr/local/bin/n https://raw.githubusercontent.com/visionmedia/n/master/bin/n
chmod +x /usr/local/bin/n
n lts

echo "Installing npm"
##fixes bug with n instalation of node and updates npm"
curl -0 -L https://npmjs.com/install.sh | sudo sh

echo "Adding Yarn Sources"
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

echo "Updating apt"
apt-get update -qq

echo "Installing dependancies from apt"
apt-get install -qq build-essential redis-server libpng-dev git python-minimal yarn

echo "Downloading XO code"

##move to opt directory
cd /opt/

##clone xo repos
echo "Cloning repositories"

git clone -b stable https://github.com/vatesfr/xo-server
git clone -b stable https://github.com/vatesfr/xo-web

##apply config patch to sample config
cd ./xo-server

git apply xo_server_mod-config.patch

##copy config to etc directory
mkdir /etc/xo-server/

cp ./sample.config.yaml /etc/xo-server/

##building xo-server
echo "Building XO-Server"

yarn && yarn run build


echo "Building XO-Web"

cd ../xo-web

yarn && yarn run build



