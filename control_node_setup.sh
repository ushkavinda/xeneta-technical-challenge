#!/bin/bash

sudo apt update
# install git
sudo apt install git-all --yes
# install ansible
sudo apt install software-properties-common --yes
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible --yes