#!/bin/bash

#This script will pull the latest code and proper dependancies for opensource xen-orchestra.

#see the xo project at https://github.com/vatesfr/

##Main Script##

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

os=$(uname -n)

if [ $os != "ubuntu" ]
	then
	 echo "Operating system $os is not compatible!"
	 exit
fi

echo "OS is compatible."
echo "Proceeding with install ..."

echo "Updating NodeJS"
n lts

echo "Installing npm"
##fixes bug with n instalation of node and updates npm"
curl -0 --progress-bar -L https://npmjs.com/install.sh | sudo sh

##clone xo repos
echo "Updating repositories"
cd /opt/xo-web
git pull --ff-only

cd ../xo-server
git pull --ff-only

##rebuilding xo-server
echo "re-building XO-Server"
rm -rf ./node_modules
yarn --non-interactive

echo "re-building XO-Web"
cd ../xo-web
rm -rf ./node_modules
yarn --non-interactive


echo "Up to date"
