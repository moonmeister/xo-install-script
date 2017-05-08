#!/bin/bash/

#this script contains common variables and functions for all xo install/updating related master scripts.

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
	os=$(uname -n)
	echo "${os}"
}

function check_os(){
case "$1" in
	"ubuntu" )
		;;	
	"debian" )
		;;
	* )
		echo "Operating system $1 is not compatible!"
		exit 1
		;;
esac

echo "Operating system is compatible"

}
