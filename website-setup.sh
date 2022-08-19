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

echo 'Enter the website domain NAME (ex: google):'
read WEBSITE_DOMAIN_NAME

echo 'Enter the website domain EXTENSION (ex: .com):'
read WEBSITE_DOMAIN_EXTENSION

WEBSITE_ADDRESS=$WEBSITE_DOMAIN_NAME$WEBSITE_DOMAIN_EXTENSION

echo $WEBSITE_ADDRESS