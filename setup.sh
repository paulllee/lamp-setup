#!/bin/bash

# Author: Paul Lee
# Company: Lyquix
# Description: Automate the installation for the LAMP Environment on WSL Ubuntu WSL1

if [ $EUID != 0 ]
then
	echo "please run this script as root, for example:"
	echo "sudo bash setup.sh"
	exit
fi

version="$(lsb_release -sr)"
if [ $version != '18.04' ] && [ $version != '20.04' ] && [ $version != '22.04' ]
then
	echo "Ubuntu $version is not supported"
	echo "please run on Ubuntu 18.04, 20.04, or 22.04 LTS - WSL1"
	exit
fi

echo "Starting the setup for the Local LAMP Development Environment for Ubuntu $version - WSL1"

echo ''
echo 'Please make sure you are on WSL Version 1 by going into Windows Terminal and running: wsl -l -v'
echo "If it is not on WSL Version 1 run: wsl --set-version Ubuntu-$version 1"
echo ''
echo 'If you are on WSL Version 1, press Enter'
read USER_CHECKPOINT

echo ''
echo 'Checking for updates then upgrading'
apt-get update && apt-get -y upgrade

# this package causes interruptions during the setup script on 22.04
if [ $version == '22.04' ]
then
	echo "Ubuntu $version only: removing needrestart package"
	apt-get -y purge needrestart
fi

echo 'Creating a /var/www directory and assigning permissions'

if [ -d /var/www ]
then
	echo "Directory already exists"
else
	mkdir /var/www
fi

chown -R www-data:www-data /var/www
chsh -s /bin/bash www-data

echo ''
echo ''
echo ''
echo ''

YOUR_WINDOWS_NAME=NULL
VALIDNAME=TRUE

# asks user for Windows username and checks if it exists
while [ ! -d /mnt/c/Users/$YOUR_WINDOWS_NAME/ ]
do
	echo ''
	if [ "$VALIDNAME" == 'FALSE' ]
	then
			echo 'Error: Invalid Windows name'
	fi
	echo 'Please type in your Windows name as shown in the file system (case sensitive):'
	read YOUR_WINDOWS_NAME
	if [ "$YOUR_WINDOWS_NAME" == '' ]
	then
			YOUR_WINDOWS_NAME=NULL
	fi
	VALIDNAME=FALSE
done

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

# Update Node.js when version 16 is no longer maintained
# It is scheduled to end in the 4th quarter of 2023
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

# Installing all supplemental files from the repository in the config-templates directory
PCKGS=("apache2conf-nl" "deflateconf-nl" "mimeconf-nl" "apache2-nl")
for PCKG in "${PCKGS[@]}"
do
	curl https://raw.githubusercontent.com/paulllee/lamp-setup/main/config-templates/${PCKG} -o ${PCKG}
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

sed -i '$r apache2-nl' /etc/logrotate.d/apache2

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

php_version="$(php -r 'echo substr(phpversion(),0,3);')"

sed -i 's/max_execution_time = 30/max_execution_time = 60/' /etc/php/$php_version/apache2/php.ini

if [ $version != '18.04' ]
then
	sed -i 's/;max_input_vars = 1000/max_input_vars = 5000/' /etc/php/$php_version/apache2/php.ini
else
	sed -i 's/; max_input_vars = 1000/max_input_vars = 5000/' /etc/php/$php_version/apache2/php.ini
fi

sed -i 's/memory_limit = 128M/memory_limit = 256M/' /etc/php/$php_version/apache2/php.ini
sed -i 's/error_reporting = E_ALL \& \~E_DEPRECATED \& \~E_STRICT/error_reporting = E_ALL \& \~E_NOTICE \& \~E_STRICT \& \~E_DEPRECATED/' /etc/php/$php_version/apache2/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 20M/' /etc/php/$php_version/apache2/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 20M/' /etc/php/$php_version/apache2/php.ini

sed -i 's/Require all denied/Require all granted/g' /etc/apache2/mods-available/php$php_version.conf

echo 'Installing MySQL'

if [ $version = '18.04' ]
then
	curl -o /etc/profile.d/wsl-integration.sh https://raw.githubusercontent.com/canonical/ubuntu-wsl-integration/master/wsl-integration.sh
fi

apt-get -y install mysql-server mysql-client

sudo chmod 755 /var/lib/mysql/mysql
sudo usermod -d /var/lib/mysql/ mysql
service mysql restart

echo ''
echo ''
echo ''
echo ''
echo ''

mysql --user="root" --password="ubuntu" --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password by 'ubuntu';"

echo 'Starting the mysql_secure_installation'
# Enter password for user root: ubuntu
# VALIDATE PASSWORD PLUGIN: N
# Change the password for root: N
# Remove anonymous user: Y
# Disallow root connect remotely: Y
# Remove test database: Y
# Reload privilege tables: Y

apt-get -y install expect

SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter password for user root:\"
send \"ubuntu\r\"
expect \"Press y|Y for Yes, any other key for No:\"
send \"n\r\"
expect \"Change the password for root ? ((Press y|Y for Yes, any other key for No) :\"
send \"n\r\"
expect \"Remove anonymous users? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Disallow root login remotely? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Remove test database and access to it? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Reload privilege tables now? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect eof
")

echo "$SECURE_MYSQL"

apt-get -y remove expect

echo 'Configuring MySQL files'

if [ $version != '18.04' ]
then
	sed -i 's/# max_allowed_packet    = 64M/max_allowed_packet    = 16M/' /etc/mysql/mysql.conf.d/mysqld.cnf
	sed -i 's/# thread_stack          = 256K/thread_stack          = 192K/' /etc/mysql/mysql.conf.d/mysqld.cnf
	sed -i 's/# thread_cache_size       = -1/thread_cache_size       = 8/' /etc/mysql/mysql.conf.d/mysqld.cnf
	sed -i 's/# table_open_cache       = 4000/table_open_cache       = 64/' /etc/mysql/mysql.conf.d/mysqld.cnf
	sed -i 's/# slow_query_log/slow_query_log/' /etc/mysql/mysql.conf.d/mysqld.cnf
	sed -i 's/# slow_query_log_file/slow_query_log_file/' /etc/mysql/mysql.conf.d/mysqld.cnf
	sed -i 's/# long_query_time = 2/long_query_time = 1/' /etc/mysql/mysql.conf.d/mysqld.cnf
else
	sed -i 's/#table_open_cache/table_open_cache/' /etc/mysql/mysql.conf.d/mysqld.cnf
	sed -i 's/#slow_query_log/slow_query_log/' /etc/mysql/mysql.conf.d/mysqld.cnf
	sed -i 's/#slow_query_log_file/slow_query_log_file/' /etc/mysql/mysql.conf.d/mysqld.cnf
	sed -i 's/#long_query_time = 2/long_query_time = 1/' /etc/mysql/mysql.conf.d/mysqld.cnf
fi

service mysql restart

service apache2 restart

apt-get -y autoremove

rm *-nl

echo 'Finished script!'
echo 'If you want to setup any websites on your local, run:'
echo ''
echo 'curl https://raw.githubusercontent.com/paulllee/lamp-setup/main/website-setup.sh -o website-setup.sh'
echo 'sudo bash website-setup.sh'
echo ''
echo "Don't forget to update the hosts file - check the hosts file header in the README on the repository."
