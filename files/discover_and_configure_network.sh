#!/usr/bin/env bash

# Purpose: discover network interface name and save in environment
# Author: Frank Dornheim <dornheim@posteo.de> under GPLv2+
# Category: Core
# Override: False

# This script is handeled by Ansible, all changes can be lost.

PATH_LSPCI=/usr/bin/lspci
PATH_AWK=/usr/bin/awk
PATH_FIND=/usr/bin/find
PATH_XARGS=/usr/bin/xargs
PATH_ECHO=/usr/bin/echo
PATH_SED=/usr/bin/sed

#
# Test Block
#

# test for lspci
if [[ ! -f "$PATH_LSPCI" ]] ; then
  echo "Can't find lspci at: $PATH_LSPCI"
  exit 1
fi

# test for awk
if [[ ! -f "$PATH_AWK" ]] ; then
  echo "Can't find awk at: $PATH_AWK"
  exit 1
fi

# test for find
if [[ ! -f "$PATH_FIND" ]] ; then
  echo "Can't find find at: $PATH_FIND"
  exit 1
fi

# test for xargs
if [[ ! -f "$PATH_XARGS" ]] ; then
  echo "Can't find xargs at: $PATH_XARGS"
  exit 1
fi

# test for echo
if [[ ! -f "$PATH_ECHO" ]] ; then
  echo "Can't find echo at: $PATH_ECHO"
  exit 1
fi

# test for sed
if [[ ! -f "$PATH_SED" ]] ; then
  echo "Can't find sed at: $PATH_SED"
  exit 1
fi

PCI_NETWORK_INTERFACES=`$PATH_LSPCI  | $PATH_AWK '/Ethernet/{print $1}'`
NETWORK_INTERFACE_NAME=`$PATH_FIND /sys/class/net ! -type d | $PATH_XARGS --max-args=1 realpath  | $PATH_AWK -v pciid=$PCI_NETWORK_INTERFACES -F\/ '{if($0 ~ pciid){print $NF}}'`

/usr/bin/sed -i 's/INTERFACE/'$NETWORK_INTERFACE_NAME'/g' /etc/netplan/50-cloud-init.yaml