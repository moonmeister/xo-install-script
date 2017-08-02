#!/bin/bash/

#this script contains common variables and functions for all xo install/updating related master scripts.

#see the xo project at https://github.com/vatesfr/

set -e

install_root="/opt/"

##functions##

function sudo_check(){
	if [ "$EUID" -ne 0 ]
	  then echo "Please run as root"
		exit 1
	fi
}


function get_os(){
	os=$(uname -v)
	echo "${os}"
}

function check_os(){
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
