#!/bin/bash

# Author: Paul Lee
# Company: Lyquix
# Description: Automate the local website installation

if [ $EUID != 0 ]
then
	echo "please run this script as root, for example:"
	echo "sudo bash website-setup.sh"
  exit
fi

echo 'Starting the Setup for Local Websites'

echo ''
echo 'Enter the website domain NAME (ex: google):'
read WEBSITE_DOMAIN_NAME

echo ''
echo 'Enter the website domain EXTENSION including the period (ex: .com):'
read WEBSITE_DOMAIN_EXTENSION

WEBSITE_ADDRESS=$WEBSITE_DOMAIN_NAME$WEBSITE_DOMAIN_EXTENSION

echo ''
echo "Setting up $WEBSITE_ADDRESS"

echo ''
curl https://raw.githubusercontent.com/paulllee/lamp-setup/main/testconf-nl -o $WEBSITE_DOMAIN_NAME.test.conf
echo "" >> $WEBSITE_DOMAIN_NAME.test.conf

