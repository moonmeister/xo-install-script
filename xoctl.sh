#!/bin/bash

#This script helps manage an open source version of Xen-Orchestra xen-orchestra.

#see the XO project at https://github.com/vatesfr/

set -e

SCRIPT_VERSION="v0.3.0-alpha"

install_root="/opt/"

##functions##

function sudo_check (){
	if [ "$EUID" -ne 0 ]; then
		echo "Please run as root"
		exit 1
	fi
}

function get_os (){
	os=$(uname -v)
	echo "${os}"
}

function check_os (){
	compatible=$false
	if [[ $1 == *"Ubuntu"* ]]
		then
			compatible=$true
	fi

	if [[ $1 == *"Debian"* ]]
		then
			compatible=$true
	fi

	if [! $compatible]
		then
			echo "Operating system $1 is not compatible!"
			exit 1
		fi

	echo "Operating system is compatible"
}

function check_install_state () {
	if [ -d "/etc/xo-server" ] && [ -d "${install_root}xo-web/" ] && [ -d "${install_root}xo-server/" ]; then
		true
	else
		false
	fi
}

function install_service {
	cd "${install_root}xo-server/"
	ln -s /opt/xo-server/bin/xo-server /usr/local/bin/xo-server &> /dev/null && echo "Creating symlink..."
	cp xo-server.service /etc/systemd/system/ && echo "copying system service file..."
	systemctl enable xo-server && echo "Enabling service at boot..."
	systemctl start xo-server && echo "Starting xo-server...please prepare for departure. :)!"
}

function install () {
	##check for prerequisits
	command -v curl >/dev/null 2 || { apt-get install -qq curl >&2; }

	dpkg-query -W -f='${Status}' apt-transpot-https 2>/dev/null | grep -c "ok installed" || { apt-get install -qq apt-transport-https >&2; }

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
	yarn build --non-interactive


	echo "Building XO-Web"

	cd ../xo-web

	yarn --non-interactive
	yarn build --non-interactive

	echo "Yay. All installed"

	while true; do
		service_config_default="Y"
		read -p "Would you like to install xo-server as a service? [$service_config_default/n]: " service_config
		service_config="${service_config:-$service_config_default}"

		case $service_config in
    	[yY][eE][sS]|[yY] )
				install_service
				break;;

    	[nN][oO]|[nN] ) break;;

    	* ) echo "Please answer (y)es or (n)o.";;
		esac
	done





	exit 0
}

function update () {
	echo "Proceeding with install ..."

	echo "Updating NodeJS"
	n lts

	echo "Updating npm"
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
	yarn build --non-interactive

	echo "re-building XO-Web"
	cd ../xo-web
	rm -rf ./node_modules
	yarn --non-interactive
	yarn build --non-interactive

	echo "Up to date!"
	echo "Restarting Server"
	systemctl restart xo-server
}

function status () {
	if check_install_state; then
		echo "Xen-Orchestra Installed"
		echo
		cd "${install_root}xo-web/"
		echo -n "xo-web: "
		git describe --tags
		echo
		cd "${install_root}xo-server/"
		echo -n "xo-server: "
		git describe --tags
		echo
	else
		echo "Xen-Orchestra not Installed. Please run \`xoctl install\` to install Xen-Orchestra"
		return 0
	fi

	if $(systemctl is-enabled xo-server.service &> /dev/null); then
		systemctl status xo-server
	else
		echo "xo-server.service is not installed or is disabled(not set to run at boot)"
	fi
}


##Main Script##
while getopts "vh" opt; do
	case $opt in
		h)
			printf "Usage:\n"
			printf "\t-h \t\t Display this help message.\n"
			printf "\t-v \t\t Display Script Version.\n"
			printf "\tinstall \t Installs Xen-Orchestra.\n"
			printf "\tupdate \t\t Updates an existing install of Xen-Orchestra.\n"
			printf "\tstatus \t\t Gives a status of Xen-Orchestra: Install status, version installed, service instalation status, and service status."
			exit 0
			;;
		v)
			echo "xoctl verion: $SCRIPT_VERSION"
			exit 0
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			exit 1
			;;
	esac
done

shift $((OPTIND -1))

sudo_check #check for running as sudo
#check_os $(get_os) #checks os is compatible

#save subcommand
subcommand=$1
shift

case $subcommand in
  "install")
		echo "Installing..."
		install
		exit 0
		;;
	"update")
		echo "Updating..."
		update
		exit 0
		;;
	"status")
		status
		exit 0
		;;
esac
