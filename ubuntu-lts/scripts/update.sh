#!/bin/bash -eux

# Set locale
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
update-locale LC_ALL=en_US
source /etc/default/locale

# Disable release-upgrades
sed -i.bak 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades;

# Update the package list
apt-get -y update;

# Upgrade all installed packages incl. kernel and kernel headers
apt-get -y dist-upgrade --force-yes;
reboot;
sleep 60;

# update package index on boot
cat <<EOF >/etc/init/refresh-apt.conf;
description "update package index"
start on networking
task
exec /usr/bin/apt-get update
EOF
