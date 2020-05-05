#!/bin/bash

HELP="Takes a single argument containing the seed ip. If no seed ip provided, it is assumed that the VM this script runs on is a seed node."

sudo service cassandra stop

sudo sed -i "s/cluster_name: 'Test Cluster'/cluster_name: 'my_cluster'/g" /etc/cassandra/cassandra.yaml

myip=`hostname -I | awk '{print $1}'`

seedip=$1

if [ -z "${seedip}" ]; then
    echo "No seed ip provided. Assuming this is seed node."
    sudo sed -i "s/seeds: \"127.0.0.1\"/seeds: \"$myip\"/g" /etc/cassandra/cassandra.yaml
else
    echo "Using $seedip as seed node ip."
    sudo sed -i "s/seeds: \"127.0.0.1\"/seeds: \"$seedip\"/g" /etc/cassandra/cassandra.yaml
fi

sudo sed -i "s/listen_address: localhost/# listen_address: localhost/g" /etc/cassandra/cassandra.yaml
sudo sed -i "s/# listen_interface: eth0/listen_interface: eth0/g" /etc/cassandra/cassandra.yaml
sudo sed -i "s/rpc_address: localhost/# rpc_address: localhost/g" /etc/cassandra/cassandra.yaml
sudo sed -i "s/# rpc_interface: eth1/rpc_interface: eth0/g" /etc/cassandra/cassandra.yaml
sudo sed -i "s/# broadcast_rpc_address: 1.2.3.4/broadcast_rpc_address: $myip/g" /etc/cassandra/cassandra.yaml
sudo sed -i "s/endpoint_snitch: SimpleSnitch/endpoint_snitch: GossipingPropertyFileSnitch/g" /etc/cassandra/cassandra.yaml

sudo rm -rf /var/lib/cassandra/data/system/

sudo service cassandra start
