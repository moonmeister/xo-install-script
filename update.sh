#!/bin/bash

#This script will pull the latest code and proper dependancies for opensource xen-orchestra.

#    Copyright (C) 2017 AJ Moon 
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>. 
#

#see the xo project at https://github.com/vatesfr/

source resources/common.sh

##Main Script##

sudo_check #checks script is run as sudo/root

check_os $(get_os)

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
