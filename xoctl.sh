#!/bin/bash

# This script helps manage an open source version of Xen-Orchestra xen-orchestra.

# See the XO project at https://github.com/vatesfr/

# Script Version
SCRIPT_VERSION="v0.3.0-alpha"

# Set script to exit if any subcommand returns non 0 (fails).
set -eux

## CONSTANTS ###

# Set XO_ROOT from sys var and validate input, this is the path where XO is installed.
if [[ -z "$XO_ROOT" ]]; then
	# if XO_ROOT is not set then set default value.
	XO_ROOT="/opt/"
else
	# check path ends in "/"
	case "$XO_ROOT" in
		*/)
    	echo "has slash"
    	;;
		*)
    	echo "doesn't have a slash"
    	;;
	esac

	#confirm path exists
	if [ -d "$XO_ROOT" ]; then
		echo "Path set in env var XO_ROOT dos not exist: ${XO_ROOT}"
    exit 1
	else
    true
	fi
fi

readonly XO_ROOT

## functions ##


err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

function sudo_check (){
	if [ "$EUID" -ne 0 ]; then
		echo "Please run as root"
		exit 1
	fi
}

function check_install_state () {
	if [ -d "/etc/xo-server" ] && [ -d "${XO_ROOT}xo-web/" ] && [ -d "${XO_ROOT}xo-server/" ]; then
		true
	else
		false
	fi
}

function install_service {
	cd "${XO_ROOT}xo-server/"
	ln -s /opt/xo-server/bin/xo-server /usr/local/bin/xo-server &> /dev/null && echo "Creating symlink..."
	cp xo-server.service /etc/systemd/system/ && echo "copying system service file..."
	systemctl enable xo-server && echo "Enabling service at boot..."
	systemctl start xo-server && echo "Starting xo-server...please prepare for departure. :)!"
}

function install_xo () {
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
	if [ -d "${XO_ROOT}xo-server/" ]; then
		rm -rf "${XO_ROOT}xo-server/"
	fi

	git clone -b stable https://github.com/vatesfr/xo-server ${XO_ROOT}xo-server/

	#check for existing repo and destory
	if [ -d "${XO_ROOT}xo-web/" ]; then
		rm -rf "${XO_ROOT}xo-web/"
	fi
	git clone -b stable https://github.com/vatesfr/xo-web ${XO_ROOT}xo-web/

	##apply config patch to sample config
	cd ${XO_ROOT}/xo-server

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

    	[nN][oO]|[nN] )
				break;;

    	* ) echo "Please answer (y)es or (n)o.";;
		esac
	done





	exit 0
}

function update_xo () {
	echo "Proceeding with install ..."

	echo "Updating NodeJS"
	n lts

	echo "Updating npm"
	command -v npm >/dev/null 2 || { apt-get install -qq npm >&2; }
	npm -g install npm@latest

	##clone xo repos
	echo "Updating repositories"
	cd ${XO_ROOT}xo-web
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

function xo_status () {
	if check_install_state; then
		echo "Xen-Orchestra Installed"
		echo
		cd "${XO_ROOT}xo-web/"
		echo -n "xo-web: "
		git describe --tags
		echo
		cd "${XO_ROOT}xo-server/"
		echo -n "xo-server: "
		git describe --tags
		echo
	else
		echo "Xen-Orchestra not Installed. Please run \`xoctl install\` to install Xen-Orchestra"
		return 0
	fi

	if systemctl is-enabled xo-server.service &> /dev/null; then
		systemctl status xo-server
	else
		echo "xo-server.service is not installed or is disabled(not set to run at boot)"
	fi
}

function main () {
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
			install_xo
			exit 0
			;;
		"update")
			echo "Updating..."
			update_xo
			exit 0
			;;
		"status")
			xo_status
			exit 0
			;;
	esac
}

##Main Script##

main "$@"
