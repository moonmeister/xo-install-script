# XOCTL
#### Xen-Orchestra Control

## Getting Started

A library of scripts for installing, updating, and managing [Xen-Orchestra](https://github.com/vatesfr/xo/)(XO). This script, its process, and the required packages are mostly based on the documentation found [here](https://github.com/vatesfr/xo/blob/master/docs/from_the_sources.md).

If you're running large production environments or in need of support it's recommended to use the XO Appliance available at https://xen-orchestra.com/.

### Compatibility
These scripts should run on most Debian based distributions but have only been tested on:

* Ubuntu 16.04 LTS
* Debian 8

### Required Packages
Both **prerequisites** and **dependencies** are installed by the script itself.

1. Prerequisites (for script execution)
   * curl
   * apt-transport-https
2. Dependencies (for Xen-Orchestra)
   * node
   * npm
   * yarn
   * build-essential
   * redis-server
   * libpng-dev

## Usage

The scripts reference various files in this repository during the course of execution. To run this script the entire repo should be cloned or downloaded via compressed package and the `xoctl.sh` script run from there.

To run the script you can execute it directly e.g. `sudo ./xoctl.sh` or you may place symlink in your `/bin/` folder (e.g. `ln -s ~/folder-with-repo/repo/xoctl.sh /bin/xoctl`) linking to the script in order that you may excute the script simply by typing `sudo xoctl <subcommand>` from anywhere.

**Default Flags:**  
  **-h** --  Displays help and available commands  
  **-v** -- Displays XOCTL version number

### Install

`sudo ./xoctl.sh install`

The `install` subcommand will install the latest stable version of [xo-web](https://github.com/vatesfr/xo-web) and [xo-server](https://github.com/vatesfr/xo-server) along with their dependencies. The XO source is placed in the `/opt/` directory by default. The primary `/opt/xo-server/bin/xo-server` executable is symlinked to `/usr/local/bin/xo-server` and a service is optionally installed to run the server.

#### Default Configuration

The default XO config is used with the exception that a line is added to point to the xo-web's `dist` folder. To modify the ports used or to add encryption please see the configuration file at `/etc/xo-server/config.yaml`. For more information on configuration see [this](https://github.com/vatesfr/xo/blob/master/docs/configuration.md).

### Update

`sudo ./xoctl.sh update`

The `update` subcommand will update xo-web and xo-server to the current stable release. It will also update node.js to the current LTS along with npm to the latest stable release. It will automatically restart the `xo-server` service before finishing.

### Status

`sudo ./xoctl.sh status`

The `status` subcommand will first check if xo is installed. If it's installed it'll report the currently installed version. Next, it'll check if the `xo-server` service is installed, if so it'll report the service status.

## Testing

If you want to test these scripts a [Vagrant](https://www.vagrantup.com/) file is included. Vagrant is a great way to easily setup, config, manage, etc... VMs from command line. Once you have installed Vagrant...  

1. To create and config the VM run `vagrant up <distro>`

**Current Distros:**
* ubuntu
* debian

2. Once vagrant has created and configure your vm `vagrant ssh <distro>` will connect you to the terminal.

3. When you're done with your VM you can stop it using `vagrant halt <distro>` and destroy it using `vagrant destroy <distro>`.


## Future Features

- [x] Single script with flags and sub commands
- [x] Build out `Status` subcommand.
- [x] set XO_ROOT (Install location) script variable via global variables.
- [ ] Include subcommand specific flags for changing script behavior such as install location.
- [ ] Subcommand for plugin management.
- [ ] add functionality to manage service.
- [x] Include git patch in file to make XOCTL a single file.
- [ ] Include more error checking logic to make more robust.
- [ ] xo config database backup and restore.


## Bugs and feature requests

Have a bug or a feature request? Please first search for existing and closed issues. If your problem or idea is not addressed yet, please open a new issue or feel free to submit a pull request. Thanks!
