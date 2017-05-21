# xo-install-script

A library of scripts for installing, updating, and managing [Xen-Orchestra](https://github.com/vatesfr/xo/)(XO). This script, its proccess, and the required packages are mostly based on the documentation found [here](https://github.com/vatesfr/xo/blob/master/docs/from_the_sources.md).

If you're running large produciton environments or in need of support it's recommended to use the XO Appliance available at https://xen-orchestra.com/.

## Compatibility
These scripts should run on most Debian based distro but have only been tested on: 

* Ubuntu 16.04 LTS
* Debian 8

## Usage

The scripts reference various files in this repository during the course of execution. To run these scripts the entire repo should be cloned or downloaded via compressed package and the `install.sh` and `update.sh` scripts run from there.

## install.sh

This script will install the latest stable version of [xo-web](https://github.com/vatesfr/xo-web) and [xo-server](https://github.com/vatesfr/xo-server) along with their prerequisits and dependencies. The XO source is placed in the `/opt/` directory. The primary `/opt/xo-server/bin/xo-server` executable is sym-linked to `/usr/local/bin/xo-server` and a service is optionally installed to run the server.

### Other Installed Items
1. Prerequisits
   * curl
   * apt-transport-https
2. Dependencies  
   * node
   * npm
   * yarn
   * build-essential
   * redis-server
   * libpng-dev
   * redis-server

### XO Configuration

The default XO config is used with the exception that a line is added to point to the xo-web's `dist` folder. To modify the ports used or to add encryption please see the configuration file at `/etc/xo-server/config.yaml`. For more information on configuration see [this](https://github.com/vatesfr/xo/blob/master/docs/configuration.md).

## update.sh

This script will update xo-web and xo-server to the current stable release. It will also update node.js to the current LTS along with npm to the latest stable release. It will automatically restart the xo-server service before finishing.

## Bugs and feature requests

Have a bug or a feature request? Please first search for existing and closed issues. If your problem or idea is not addressed yet, please open a new issue or feel free to submit a pull request. Thanks!



