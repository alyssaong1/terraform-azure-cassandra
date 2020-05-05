#!/bin/bash

sudo apt-get update
sudo apt-get -y install openjdk-8-jre

echo "deb http://www.apache.org/dist/cassandra/debian 39x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list

sudo apt install curl
wget --no-check-certificate -qO - https://www.apache.org/dist/cassandra/KEYS | sudo apt-key add -

sudo apt update
sudo apt -y install cassandra

sudo systemctl enable cassandra
sudo systemctl start cassandra

sudo systemctl status cassandra