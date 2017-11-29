#!/bin/bash

#This script will pull the latest code and proper dependancies for opensource xen-orchestra.

#see the xo project at https://github.com/vatesfr/

source resources/common.sh

##Main Script##

sudo_check #checks script is run as sudo/root

check_os $(get_os)

echo "Proceeding with install ..."

echo "Updating NodeJS"
n lts

echo "Installing npm"
command -v npm >/dev/null 2 || { apt-get install -qq npm >&2; }
npm -g install npm@latest

##clone xo repos
echo "Updating repositories"
cd ${install_root}xo-web
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
echo "Restarting Server"
systemctl restart xo-server
