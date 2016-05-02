#!/bin/bash -eux

# Cleaning up udev and dhcp leases
rm -rf /dev/.udev/ /var/lib/dhcp3/* /var/lib/dhcp/*;
