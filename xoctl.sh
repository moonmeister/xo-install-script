#!/bin/bash

# This script helps manage an open source version of Xen-Orchestra xen-orchestra.

# See the XO project at https://github.com/vatesfr/

# Script Version
SCRIPT_VERSION="v0.3.1-alpha"

# Set script to exit if any subcommand returns non 0 (fails).
set -e

## CONSTANTS ###
XO_SOURCE="https://github.com/vatesfr/xen-orchestra"
XO_FOLDER="xen-orchestra"

CONFIG_FILE="/etc/xo-server/config.yaml" #it is not recomended to modify this. It could break your Xen Orchestra install.



# Set XO_ROOT from sys var and validate input, this is the path where XO is installed.
if [[ -z "$XO_ROOT" ]]; then
    # if XO_ROOT is not set then set default value.
    XO_ROOT="/opt"
else
    #confirm path exists
    if [[ -d "$XO_ROOT" ]]; then
        echo "XO_ROOT path ($XO_ROOT) does not exist"
        exit 1
    fi
fi

readonly XO_ROOT XO_FOLDER CONFIG_FILE XO_SOURCE

## functions ##

function get_xo_version () {
    git describe --tags
}

function sudo_check (){
    if [[ "$EUID" -ne 0 ]]; then
        echo "Please run as root"
        exit 1
    fi
}

function check_install_state () {
    if [[ -d "$XO_ROOT/$XO_FOLDER/" ]]; then
        true
    else
        false
    fi
}

function install_service {
    cd "${XO_ROOT}/$XO_FOLDER/packages/xo-server/"
    ln -s /opt/xen-orchestra/packages/xo-server/bin/xo-server /usr/local/bin/xo-server &> /dev/null && echo "Creating symlink..."
    cp xo-server.service /etc/systemd/system/ && echo "copying system service file..."
    systemctl enable xo-server && echo "Enabling service at boot..."
    systemctl start xo-server && echo "Starting xo-server...please prepare for departure. :)!"
}

function install_xo () {
    
    ##check for prerequisits
    command -v curl >/dev/null 2 || { apt-get install -qq curl >&2; }
    
    
    # shellcheck disable=SC2016    
    dpkg-query -W -f='${Status}' apt-transpot-https 2>/dev/null | grep -c "ok installed" || { apt-get install -qq apt-transport-https >&2; }
    
    echo "Proceeding with install ..."
    
    echo "Installing nodejs"
    curl --progress-bar -o /usr/local/bin/n https://raw.githubusercontent.com/tj/n/master/bin/n
    
    chmod +x /usr/local/bin/n
    n lts
    
    echo "Installing npm"
    
    ##fixes bug with n instalation of node and updates npm"
    command -v npm >/dev/null 2 || { apt-get install -qq npm >&2; }
    npm -g install npm@latest
    
    echo "Adding Yarn Sources"
    curl -sS --progress-bar https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
    
    echo "Updating apt"
    apt-get update -qq
    
    echo "Installing dependancies from apt"
    apt-get install -qq build-essential redis-server libpng-dev git python-minimal yarn nfs-common
    
    ##clone xo repos
    echo "Cloning repositories"
    
    #check for existing repo and remove
    if [[ -d "${XO_ROOT}/$XO_FOLDER/" ]]; then
        rm -rf "${XO_ROOT:?}/$XO_FOLDER/"
    fi
    
    git clone -b master $XO_SOURCE ${XO_ROOT}/$XO_FOLDER/
    
    ##apply config patch to sample config
    cd ${XO_ROOT}/$XO_FOLDER/packages/xo-server
    
    # modify default config and create file
	if [[ ! -d "/etc/xo-server" ]]; then
		mkdir /etc/xo-server/
	fi

	cp ./sample.config.yaml $CONFIG_FILE

	commented="#'/':"
 	old_path='/path/to/xo-web/dist/'

	uncommented="'/':"
	new_path="$XO_ROOT/$XO_FOLDER/packages/xo-web/dist/"

	sed -i -e "s|$commented|$uncommented|" $CONFIG_FILE
 	sed -i -e "s|$old_path|$new_path|" $CONFIG_FILE
     
    echo "Building Xen-Orchestra"
    
    cd $XO_ROOT/$XO_FOLDER
    
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
}

function update_xo () {
    echo "Proceeding with update..."
    
    echo "Updating NodeJS"
    n lts
    
    echo "Updating npm"
    command -v npm >/dev/null 2 || { apt-get install -qq npm >&2; }
    npm -g install npm@latest
    
    ##clone xo repos
    echo "Updating repository"
    cd $XO_ROOT/$XO_FOLDER
    printf "Xen Orchestra current version: "
    get_xo_version
    git pull --ff-only
    
    printf "Xen Orchestra new version: "
    get_xo_version
    
    ##rebuilding xo-server
    echo "re-building Xen Orchestra"
    rm -rf ./node_modules
    yarn --non-interactive
    yarn build --non-interactive
    
    echo "Everything has updated succesfully!"
    if [[ -f "/etc/systemd/system/xo-server.service" ]]; then
        if systemctl is-active xo-server.service; then
            echo "Restarting xo-server service"
            systemctl restart xo-server
        else
            echo "xo-server service is not running and this script didn't stop it. Restart manually if desired using 'sudo systemctl start xo-server'."
        fi
    else
        echo "xo-server service not installed. Start/Restart manually to run the updated code."
    fi
}

function xo_status () {
    if check_install_state; then
        echo "Xen-Orchestra Installed"
        echo
        cd "$XO_ROOT/$XO_FOLDER/packages/xo-web"
        echo -n "xo-web: "
        get_xo_version
        echo
        cd "$XO_ROOT/$XO_FOLDER/packages/xo-server"
        echo -n "xo-server: "
        get_xo_version
        echo
    else
        echo "Xen-Orchestra not installed. Please run \`xoctl install\` to install Xen-Orchestra"
        return 0
    fi
    
    if [[ -f "/etc/systemd/system/xo-server.service" ]]; then
        systemctl status xo-server
    else
        echo "xo-server service is not installed."
    fi
}

function main () {
    while getopts "vh" opt; do
        case $opt in
            h)
                printf "XOCTL Usage:\n"
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
            echo "Attempting to install XO at $XO_ROOT"
            install_xo
        ;;
        "update")
            echo "Attempting to update XO at $XO_ROOT"
            update_xo
        ;;
        "status")
            xo_status
        ;;
    esac
}

## Main Script ##

main "$@"

exit 0
