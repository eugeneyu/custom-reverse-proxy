#!/bin/bash

	
ulimit -n 99999
echo "fs.file-max=99999" >> /etc/sysctl.conf
echo "* soft nofile 99999" >> /etc/security/limits.conf
echo "* hard nofile 99999" >> /etc/security/limits.conf

# install some prerequisites needed by adding GPG public keys (could be removed later)
sudo apt-get -y install --no-install-recommends wget gnupg ca-certificates

# import our GPG key:
wget -O - https://openresty.org/package/pubkey.gpg | sudo apt-key add -

# for installing the add-apt-repository command
# (you can remove this package and its dependencies later):
sudo apt-get -y install --no-install-recommends software-properties-common

# add the our official APT repository:
sudo add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"

# to update the APT index:
sudo apt-get update

sudo apt-get -y install openresty
