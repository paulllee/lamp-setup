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
    echo 'Are the the credentials above correct? YES or NO (case sensitive):'
    read USER_VERIFIED
    if [ "$USER_VERIFIED" == '' ]
    then
        USER_VERIFIED=NO
    fi
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

echo "Returning to Home directory; finished setting up the apache2 configuration files for $WEBSITE_ADDRESS"

HAS_DATABASE=NULL
while [ "$HAS_DATABASE" != 'YES' ] && [ "$HAS_DATABASE" != 'NO' ]
do
    echo ''
    echo "Does $WEBSITE_ADDRESS use a Content Management System (CMS)? YES or NO (case sensitive):"
    read HAS_DATABASE
    if [ "$HAS_DATABASE" == '' ]
    then
        HAS_DATABASE=NULL
    fi
done

if [ "$HAS_DATABASE" == 'YES' ]
then
    CMS_TYPE=NULL
    while [ "$CMS_TYPE" != 'JOOMLA' ] && [ "$CMS_TYPE" != 'WORDPRESS' ]
    do
        echo ''
        echo "Does $WEBSITE_ADDRESS use JOOMLA or WORDPRESS (case sensitive)?:"
        read CMS_TYPE
        if [ "$CMS_TYPE" == '' ]
        then
            CMS_TYPE=NULL
        fi
    done
fi

# SourceTree to clone repo
echo ''
echo "Next: open up SourceTree and clone the $WEBSITE_ADDRESS repo into the public_html directory"
echo ''
echo 'When you are done press Enter'
read USER_CHECKPOINT

# SSH for MySQL dump
if [ "$HAS_DATABASE" == 'YES' ]
then
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
fi

# FTP using FileZilla to retrieve necessary files
echo ''
if [ "$HAS_DATABASE" == 'YES' ]
then
    echo "FTP (using FileZilla) into the server as www-data user: download the sql file to the www/$WEBSITE_ADDRESS/ directory"
    echo "You can use the .gitignore file and download all the files that are ignored to the www/$WEBSITE_ADDRESS/public_html/ directory"
    echo "Make sure to have at least the .htaccess, wp-config.php (WordPress), and configuration.php (Joomla)"
    echo 'Look through the .htaccess, wp-config.php (WordPress), and configuration.php (Joomla) files and modify the values to work for your local if needed (ex: check any forcing for ssl, any directory paths...)'
else
    echo "FTP (using FileZilla) into the server as www-data user: use the .gitignore file and download all the files that are ignored to the www/$WEBSITE_ADDRESS/public_html/ directory" 
    echo 'Look through the .htaccess file and modify the values to work for your local (ex: check any forcing for ssl...)'
fi
echo ''
echo 'When you are done press Enter'
read USER_CHECKPOINT

if [ "$HAS_DATABASE" == 'YES' ]
then
    echo ''
    echo "Press Enter if you confirm the sql file is in the C:/.../Documents/www/$WEBSITE_ADDRESS/ directory"
    read USER_CHECKPOINT

    echo ''
    echo "I will ask you to verify that the credentials are correct at the end if you mess up"

    USER_VERIFIED=NO
    while [ "$USER_VERIFIED" != 'YES' ]
    do
        echo ''
        echo "Type in the MySQL database name for $WEBSITE_ADDRESS:"
        read DATABASE_NAME

        echo ''
        echo "Type in the MySQL database username for $WEBSITE_ADDRESS:"
        read DATABASE_USER

        echo ''
        echo "Type in the MySQL database password for $WEBSITE_ADDRESS:"
        read DATABASE_PASS

        echo ''
        echo 'Type in the name of your sql file, including the .sql extension (ex: google_dev20220819.sql):'
        read SQL_FILE

        echo ''
        echo "DATABASE NAME=$DATABASE_NAME"
        echo "DATABASE USERNAME=$DATABASE_USER"
        echo "DATABASE PASSWORD=$DATABASE_PASS"
        echo "SQL FILE NAME=$SQL_FILE"
        echo 'Are the credentials above correct? YES or NO (case sensitive):'
        read USER_VERIFIED
        if [ "$USER_VERIFIED" == '' ]
        then
            USER_VERIFIED=NO
        fi
    done

    cd /srv/www/$WEBSITE_ADDRESS/

    mysql --user="root" --password="ubuntu" --execute="CREATE DATABASE $DATABASE_NAME;"
    mysql --user="root" --password="ubuntu" --execute="CREATE USER '$DATABASE_USER'@localhost IDENTIFIED BY '$DATABASE_PASS';"
    mysql --user="root" --password="ubuntu" --execute="GRANT ALL PRIVILEGES ON $DATABASE_NAME.* TO '$DATABASE_USER'@localhost;"

    mysql --user="$DATABASE_USER" --password="$DATABASE_PASS" --database="$DATABASE_NAME" < $SQL_FILE

    cd public_html

    version="$(lsb_release -sr)"
    if [ "$CMS_TYPE" == 'WORDPRESS' ]
    then
        if [[ $(command -v unzip) ]]
        then
            echo ''
            echo 'unzip is already installed'
        else
            apt-get update
            apt-get -y install unzip
        fi

        if [ $version != '18.04' ]
        then
            HOST_NAME=127.0.0.1
            # Ubuntu 20+ uses 127.0.0.1
            sed -i 's/localhost/127.0.0.1/' wp-config.php
        else
            # Ubuntu 18 uses localhost
            HOST_NAME=localhost
            sed -i 's/127.0.0.1/localhost/' wp-config.php
        fi

        curl -L https://github.com/interconnectit/Search-Replace-DB/archive/refs/tags/4.1.2.zip -o srdb.zip
        unzip srdb.zip
        rm -f srdb.zip

        cd Search-Replace-DB*
        php srdb.cli.php -h $HOST_NAME -n $DATABASE_NAME -u $DATABASE_USER -p "$DATABASE_PASS" -s "dev.$WEBSITE_DOMAIN_NAME$WEBSITE_DOMAIN_EXTENSION" -r "$WEBSITE_DOMAIN_NAME.test"
        php srdb.cli.php -h $HOST_NAME -n $DATABASE_NAME -u $DATABASE_USER -p "$DATABASE_PASS" -s "https://$WEBSITE_DOMAIN_NAME.test" -r "http://$WEBSITE_DOMAIN_NAME.test"

    elif [ "$CMS_TYPE" == 'JOOMLA' ]
    then
        if [ $version != '18.04' ]
        then
            sed -i "s/host = 'localhost'/host = '127.0.0.1'/" configuration.php
        else
            sed -i "s/host = '127.0.0.1'/host = 'localhost'/" configuration.php
        fi
    fi

    JS_PATH="$(find /srv/www/$WEBSITE_ADDRESS/ -name 'js.php')"
    
    if grep -q "\$curl" "$JS_PATH"
    then
        echo ''
        echo 'The Lyquix template has the js.php curl fix'
    else
        curl https://raw.githubusercontent.com/paulllee/lamp-setup/main/config-templates/jsphp-fix -o jsphp-fix

        sed -i '/ Remote script: /r jsphp-fix' $JS_PATH
        sed -i '/curl_close($curl);/{
            n
            d
            }' $JS_PATH

        rm jsphp-fix

        echo ''
        echo 'The Lyquix template has been updated with the js.php curl fix'
        echo 'Do not discard the changes of this file in SourceTree'
        echo 'You have to keep the changes in the js.php file'
    fi

    sudo service mysql start
    sudo service apache2 start
    sudo service apache2 restart   
else
    sudo service mysql start
    sudo service apache2 start
    sudo service apache2 restart
fi

echo ''
echo "The full installation of the $WEBSITE_DOMAIN_NAME is now complete!"
