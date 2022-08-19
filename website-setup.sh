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
echo 'IF FIREWALL IS PROMPTED, allow BOTH public and private networks'

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
mkdir -p /srv/www/$WEBSITE_ADDRESS/public_html
mkdir /srv/www/$WEBSITE_ADDRESS/logs
mkdir /srv/www/$WEBSITE_ADDRESS/ssl
chown -R www-data:www-data /srv/www

echo ''
curl https://raw.githubusercontent.com/paulllee/lamp-setup/main/config-templates/testconf-nl -o $WEBSITE_DOMAIN_NAME.test.conf
echo "" >> $WEBSITE_DOMAIN_NAME.test.conf

sed -i "s/example/$WEBSITE_DOMAIN_NAME/g" $WEBSITE_DOMAIN_NAME.test.conf
sed -i "s/.extension/$WEBSITE_DOMAIN_EXTENSION/g" $WEBSITE_DOMAIN_NAME.test.conf

mv $WEBSITE_DOMAIN_NAME.test.conf /etc/apache2/sites-available/

echo ''
cd /etc/apache2/sites-available/
a2ensite $WEBSITE_DOMAIN_NAME.test.conf

service apache2 restart

cd ~

echo "Returned to Home directory. Finished setting up $WEBSITE_ADDRESS"
