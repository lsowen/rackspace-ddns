#!/bin/sh

CURRENT_IP=$( ifconfig eth1 | grep "inet addr" | sed -n 's/.*inet addr:\([0-9.]*\).*/\1/p' )
OLD_IP=''

IP_CACHE=/tmp/ip.txt

if [ -e "${IP_CACHE}" ]
then
    OLD_IP=$( cat "${IP_CACHE}" )
fi

if [ "${CURRENT_IP}" != "${OLD_IP}" ]
then
    /usr/bin/rackspace-ddns.sh /etc/config/rackspace-ddns "${CURRENT_IP}"
    echo "${CURRENT_IP}" > "${IP_CACHE}"
fi
