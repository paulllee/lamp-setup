#!/bin/bash

# Author: Paul Lee
# Company: Lyquix
# Description: Automate the installation for the LAMP Environment on WSL

if [ $EUID != 0 ]
then
	echo "please run this script as root, for example:"
	echo "sudo bash lamp-ubuntu18.sh"
  exit
fi

echo 'Starting the setup for the Local LAMP Development Environment for Ubuntu 18.04.5 LTS - WSL'

echo 'Checking for updates then upgrading'
apt-get update && apt-get -y upgrade

echo 'Creating a /var/www directory and assigning permissions'

if [ -d /var/www ]
then
	echo "Directory already exists"
else
	mkdir /var/www
fi

chown -R www-data:www-data /var/www
chsh -s /bin/bash www-data

echo 'Please type in your Windows name as shown in the file system (case sensitive):'
read YOUR_WINDOWS_NAME

echo 'Making the www directory in the Documents directory'
if [ -d /mnt/c/Users/$YOUR_WINDOWS_NAME/Documents/www/ ]
then
	echo "Directory already exists"
else
	mkdir /mnt/c/Users/$YOUR_WINDOWS_NAME/Documents/www/
fi

echo 'Creating a symbolic link between the Documents/www directory with /srv/www directory'
if [ -d /srv/www ]
then
	echo "Directory already exists"
else
	cd /srv/
	ln -s /mnt/c/Users/$YOUR_WINDOWS_NAME/Documents/www/
fi

chown -R www-data:www-data /srv/www

echo 'Installing fundamental packages that may have already been installed'
PCKGS=("curl" "vim" "openssl" "git" "htop" "nload" "nethogs" "zip" "unzip" "sendmail" "sendmail-bin" "libcurl3-openssl-dev" "psmisc" "build-essential" "zlib1g-dev" "libpcre3" "libpcre3-dev" "memcached" "fail2ban" "nodejs" "cifs-utils")
for PCKG in "${PCKGS[@]}"
do
	apt-get -y install ${PCKG}
done

echo 'Installing Node.js version 16'
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
apt-get -y install nodejs

echo 'Installing APACHE packages'
PCKGS=("apache2" "apache2-doc" "apachetop" "libapache2-mod-php" "libapache2-mod-fcgid" "apache2-suexec-pristine" "libapache2-mod-security2")
for PCKG in "${PCKGS[@]}"
do
	apt-get -y install ${PCKG}
done

a2enmod expires headers rewrite ssl suphp mpm_prefork php

echo 'Updating config files'

PCKGS=("apache2conf-nl" "deflateconf-nl" "mimeconf-nl" "apache2-nl")
for PCKG in "${PCKGS[@]}"
do
	curl https://raw.githubusercontent.com/paulllee/lamp-setup/main/${PCKG} -o ${PCKG}
	echo "" >> ${PCKG}
done

sed -i 's/Timeout 300/Timeout 60/' /etc/apache2/apache2.conf
sed -i 's/MaxKeepAliveRequests 100/MaxKeepAliveRequests 0/' /etc/apache2/apache2.conf
sed -i '/<Directory \/srv\/>/{
n
n
n
n
n
r apache2conf-nl
}' /etc/apache2/apache2.conf

sed -i '/AddOutputFilterByType DEFLATE application\/xml/r deflateconf-nl' /etc/apache2/mods-available/deflate.conf

sed -i '/AddType application\/x-gzip .tgz/r mimeconf-nl' /etc/apache2/mods-available/mime.conf

sed -i '/}/r apache2-nl' /etc/logrotate.d/apache2

echo 'Installing mod_pagespeed'
curl -O https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb
dpkg -i mod-pagespeed*.deb
rm mod-pagespeed*.deb
apt-get -f install

sed -i 's/ModPagespeed on/ModPagespeed off/' /etc/apache2/mods-available/pagespeed.conf

service apache2 restart

echo 'Installing PHP'
PCKGS=("mcrypt" "imagemagick" "php" "php-common" "php-gd" "php-imap" "php-mysql" "php-cli" "php-cgi" "php-zip" "php-pear" "php-imagick" "php-curl" "php-mbstring" "php-bcmath" "php-xml" "php-soap" "php-opcache" "php-intl" "php-apcu" "php-mail" "php-mail-mime" "php-all-dev" "php-dev" "libapache2-mod-php" "php-memcached" "php-auth" "php-mcrypt")
for PCKG in "${PCKGS[@]}"
do
	apt-get -y install ${PCKG}
done

# after script is complete, add a for loop removing the files