#!/bin/bash

#his script will pull the latest code and proper dependancies for opensource xen-orchestra.

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


##check for prerequisits
command -v curl >/dev/null 2 || { sudo apt-get install -qq curl >&2; }

dpkg-query -W -f='${Status}' apt-transpot-https 2>/dev/null | grep -c "ok installed" || { sudo apt-get install -qq apt-transport-https >&2; }

echo "Proceeding with install ..."

echo "Preparing files"
cp ./patches/xo_server_mod-config.patch /tmp/

echo "Installing nodejs"
curl --progress-bar -o /usr/local/bin/n https://raw.githubusercontent.com/tj/n/master/bin/n
chmod +x /usr/local/bin/n
n lts

echo "Installing npm"
##fixes bug with n instalation of node and updates npm"
command -v npm >/dev/null 2 || { sudo apt-get install -qq npm >&2; }
npm -g install npm@latest

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

while true; do
	service_config_default="Y"
	read -p "Would you like to install xo-server as a service? [$service_config_default/n]: " service_config
	service_config="${service_config:-$service_config_default}"

	case $service_config in
        	[yY][eE][sS]|[yY] )
			cd ../xo-server/
			ln -s /opt/xo-server/bin/xo-server /usr/local/bin/xo-server
			cp xo-server.service /etc/systemd/system/
			systemctl enable xo-server
			systemctl start xo-server
			break;;
        	[nN][oO]|[nN] ) break;;
        	* ) echo "Please answer (y)es or (n)o.";;
	esac
done
