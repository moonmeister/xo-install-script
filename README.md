# xo-install-script

A library of scripts for installing, updating, and managing [Xen-Orchestra](https://github.com/vatesfr/xo/)(XO). This script, its proccess, and the required packages are mostly based on the documentation found [here](https://github.com/vatesfr/xo/blob/master/docs/from_the_sources.md).

If you're running large produciton environments or in need of support it's recommended to use the XO Appliance available at https://xen-orchestra.com/.

## install.sh

This script will install the latest stable version of XO along with it's prerequisits and dependancies. The XO source is placed in the `/opt/` directory. The primary `/opt/xo-server/bin/xo-server` executable is sym-linked to `/usr/local/bin/xo-server` and a service is optionally installed to run the server.

### Other Installed Items
1. Prerequisits
   * curl
   * apt-transport-https
2. Depeandancies  
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

