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
echo "I will ask you to verify that the credentials are correct at the end if you mess up."

USER_VERIFIED=NO
while [ "$USER_VERIFIED" != 'YES' ]
do
    echo ''
    echo 'Enter the production website domain NAME (ex: google):'
    read WEBSITE_DOMAIN_NAME

    echo ''
    echo 'Enter the production website domain EXTENSION including the period (ex: .com):'
    read WEBSITE_DOMAIN_EXTENSION

    echo ''
    echo "WEBSITE DOMAIN NAME=$WEBSITE_DOMAIN_NAME"
    echo "WEBSITE DOMAIN EXTENSION=$WEBSITE_DOMAIN_EXTENSION"
    echo 'Can you verify that the credentials above is correct?'
    echo 'YES for correct / NO for not correct (case sensitive):'
    read USER_VERIFIED
done

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

cd

echo "Returning to Home directory; finished setting up $WEBSITE_ADDRESS"

echo ''
echo "Next: open up SourceTree and clone the $WEBSITE_ADDRESS repo into the public_html directory"
echo ''
echo 'When you are done press Enter'
read USER_CHECKPOINT

echo ''
echo 'Then open up PuTTY or Windows Terminal and SSH as root on the client side (check passwork for credentials)'
echo 'If you use Windows Terminal, here is how to SSH in:'
echo ''
echo 'ssh root@clientaddress'
echo 'Enter password: (check PassWork)'
echo 'cd /srv/www/dev.____.___/'
echo 'mysqldump -u username -p username > databasename.sql'
echo ''
echo 'In some circumstances, you will need to use the --no-tablespaces flag:'
echo 'mysqldump -u root -p rothman_dev > rothman_dev04062022.sql --no-tablespaces'
echo ''
echo 'When you are done press Enter'
read USER_CHECKPOINT

echo ''
echo "FTP (using FileZilla) and download the sql file to the www/$WEBSITE_ADDRESS/ directory."
echo 'Look through the htaccess and configuration.php files and modify the values to work for your local (ex: check any forcing for ssl, any directory paths...).'
echo 'Also look through the gitignore file and download all of the files (a majority is media files) that have been ignored to your local.'
echo ''
echo 'When you are done press Enter'
read USER_CHECKPOINT

echo ''
echo "Press Enter if you confirm the sql file is in the C:/.../Documents/www/$WEBSITE_ADDRESS/ directory"
read USER_CHECKPOINT

echo ''
echo "I will ask you to verify that the credentials are correct at the end if you mess up."

USER_VERIFIED=NO
while [ "$USER_VERIFIED" != 'YES' ]
do
    echo ''
    echo 'Type in the MySQL database name for this site:'
    read DATABASE_NAME

    echo ''
    echo 'Type in the MySQL database username for this site:'
    read DATABASE_USER

    echo ''
    echo 'Type in the MySQL database password for this site:'
    read DATABASE_PASS

    echo ''
    echo 'Type in the name of your sql file, including the .sql extension (ex: google_dev20220819.sql):'
    read SQL_FILE

    echo ''
    echo "DATABASE NAME=$DATABASE_NAME"
    echo "DATABASE USERNAME=$DATABASE_USER"
    echo "DATABASE PASSWORD=$DATABASE_PASS"
    echo "SQL FILE NAME=$SQL_FILE"
    echo 'Can you verify that the credentials above is correct?'
    echo 'YES for correct / NO for not correct (case sensitive):'
    read USER_VERIFIED
done

cd /srv/www/$WEBSITE_ADDRESS/

mysql --user="root" --password="ubuntu" --execute="CREATE DATABASE $DATABASE_NAME;"
mysql --user="root" --password="ubuntu" --execute="CREATE USER '$DATABASE_USER'@localhost IDENTIFIED BY '$DATABASE_PASS';"
mysql --user="root" --password="ubuntu" --execute="GRANT ALL PRIVILEGES ON $DATABASE_NAME.* TO '$DATABASE_USER'@localhost;"

mysql --user="$DATABASE_USER" -password="$DATABASE_PASS" < $SQL_FILE

cd

sudo service mysql start
sudo service apache2 start
sudo service apache2 restart

echo ''
echo 'The full installation of the website is now complete!'
