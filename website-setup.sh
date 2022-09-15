#!/bin/bash

# Author: Paul Lee
# Company: Lyquix
# Description: Automate the local website installation

# conditional to check if root
if [ $EUID != 0 ]
then
    echo "please run this script as root, for example:"
    echo "sudo bash website-setup.sh"
    exit
fi

echo 'Starting the Setup for Local Websites'
echo 'IF FIREWALL IS PROMPTED, allow BOTH public and private networks'

# asking user for website info
# all info gathered from the user is ran through a while loop to check that the credentials are correct
USER_VERIFIED=NO
while [ "$USER_VERIFIED" != 'YES' ]
do
    echo ''
    echo 'Enter the production website domain NAME (ex: google):'
    read WEBSITE_DOMAIN_NAME

    echo ''
    echo 'Enter the development website subdomain NAME including the period (ex: dev.):'
    read WEBSITE_SUBDOMAIN_NAME

    echo ''
    echo 'Enter the production website domain EXTENSION including the period (ex: .com):'
    read WEBSITE_DOMAIN_EXTENSION

    echo ''
    echo "WEBSITE DOMAIN NAME=$WEBSITE_DOMAIN_NAME"
    echo "DEVELOPMENT WEBSITE SUBDOMAIN NAME=$WEBSITE_SUBDOMAIN_NAME"
    echo "WEBSITE DOMAIN EXTENSION=$WEBSITE_DOMAIN_EXTENSION"
    echo 'Are the the credentials above correct? YES or NO (case sensitive):'
    read USER_VERIFIED
    if [ "$USER_VERIFIED" == '' ]
    then
        USER_VERIFIED=NO
    fi
done

WEBSITE_ADDRESS=$WEBSITE_DOMAIN_NAME$WEBSITE_DOMAIN_EXTENSION

# asking if website is using a CMS and if so, JOOMLA or WORDPRESS
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

echo ''
echo "Setting up $WEBSITE_ADDRESS"

# setting up the directories
echo ''
mkdir -p /srv/www/$WEBSITE_ADDRESS/public_html
mkdir /srv/www/$WEBSITE_ADDRESS/logs
mkdir /srv/www/$WEBSITE_ADDRESS/ssl
chown -R www-data:www-data /srv/www

# downloading the apache2 template config
echo ''
curl https://raw.githubusercontent.com/paulllee/lamp-setup/main/config-templates/testconf-nl -o $WEBSITE_DOMAIN_NAME.test.conf
echo "" >> $WEBSITE_DOMAIN_NAME.test.conf

sed -i "s/domain/$WEBSITE_DOMAIN_NAME/g" $WEBSITE_DOMAIN_NAME.test.conf
sed -i "s/.extension/$WEBSITE_DOMAIN_EXTENSION/g" $WEBSITE_DOMAIN_NAME.test.conf

mv $WEBSITE_DOMAIN_NAME.test.conf /etc/apache2/sites-available/

# enabling the test.conf
echo ''
cd /etc/apache2/sites-available/
a2ensite $WEBSITE_DOMAIN_NAME.test.conf

service apache2 restart

cd

echo "Returning to Home directory; finished setting up the apache2 configuration files for $WEBSITE_ADDRESS"

# SourceTree to clone repo
echo ''
echo "Next: open up SourceTree and clone the $WEBSITE_ADDRESS repo (development branch) into the public_html directory"
echo ''
echo 'When you are done press Enter'
read USER_CHECKPOINT

if [ "$HAS_DATABASE" == 'YES' ]
then
    # asking for MySQL credentials
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
        echo 'Type in what you would like to name the sql file, including the .sql extension (ex: google_dev20220819.sql):'
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

    # SSH for MySQL dump
    echo ''
    echo 'Then open up PuTTY or Windows Terminal and SSH as root on the client side (check passwork for credentials)'
    echo 'If you use Windows Terminal, here is how to SSH in:'
    echo ''
    echo "ssh root@$WEBSITE_ADDRESS"
    echo 'Enter password: (check PassWork)'
    echo "cd /srv/www/$WEBSITE_SUBDOMAIN_NAME$WEBSITE_ADDRESS/"
    echo "mysqldump -u $DATABASE_USER -p $DATABASE_NAME > $SQL_FILE"
    echo ''
    echo 'In some circumstances, you will need to use the --no-tablespaces flag:'
    echo "mysqldump -u $DATABASE_USER -p $DATABASE_NAME > $SQL_FILE --no-tablespaces"
    echo ''
    echo 'In some circumstances, you will need to be logged in as root user for MySQL:'
    echo "mysqldump -u root -p $DATABASE_NAME > $SQL_FILE --no-tablespaces" 
    echo ''
    echo 'When you are done press Enter'
    read USER_CHECKPOINT

    # FTP using FileZilla to retrieve necessary files
    echo "FTP (using FileZilla) into the server as www-data user: download the sql file to the www/$WEBSITE_ADDRESS/ directory"
    echo "You can use the .gitignore file and download all the files that are ignored to the www/$WEBSITE_ADDRESS/public_html/ directory"
    echo ''
    echo "Make sure to have at least the .htaccess, wp-config.php (WordPress), and configuration.php (Joomla)"
    echo 'Look through the .htaccess and modify/remove the values to work for your local if needed (ex: check for redirecting and forcing ssl, password protection, ModPageSpeed must be turned Off)'
    echo "You do NOT have to edit wp-config.php (WordPress) or configuration.php (Joomla), they will be automatically updated later in the script!"
    echo ''
    echo 'When you are done press Enter'
    read USER_CHECKPOINT

    echo ''
    echo "Press Enter if you confirm that $SQL_FILE is in the C:/.../Documents/www/$WEBSITE_ADDRESS/ directory"
    read USER_CHECKPOINT

    # Inserting remote MySQL dump into local MySQL table
    cd /srv/www/$WEBSITE_ADDRESS/

    sudo service mysql start

    mysql --user="root" --password="ubuntu" --execute="CREATE DATABASE $DATABASE_NAME;"
    mysql --user="root" --password="ubuntu" --execute="CREATE USER '$DATABASE_USER'@localhost IDENTIFIED BY '$DATABASE_PASS';"
    mysql --user="root" --password="ubuntu" --execute="GRANT ALL PRIVILEGES ON $DATABASE_NAME.* TO '$DATABASE_USER'@localhost;"

    mysql --user="$DATABASE_USER" --password="$DATABASE_PASS" --database="$DATABASE_NAME" < $SQL_FILE

    # updating necessary values and srdb for WORDPRESS websites
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
        php srdb.cli.php -h $HOST_NAME -n $DATABASE_NAME -u $DATABASE_USER -p "$DATABASE_PASS" -s "$WEBSITE_SUBDOMAIN_NAME$WEBSITE_DOMAIN_NAME$WEBSITE_DOMAIN_EXTENSION" -r "$WEBSITE_DOMAIN_NAME.test" --allow-old-php
        php srdb.cli.php -h $HOST_NAME -n $DATABASE_NAME -u $DATABASE_USER -p "$DATABASE_PASS" -s "https://$WEBSITE_DOMAIN_NAME.test" -r "http://$WEBSITE_DOMAIN_NAME.test" --allow-old-php

    elif [ "$CMS_TYPE" == 'JOOMLA' ]
    then
        if [ $version != '18.04' ]
        then
            sed -i "s/host = 'localhost'/host = '127.0.0.1'/" configuration.php
        else
            sed -i "s/host = '127.0.0.1'/host = 'localhost'/" configuration.php
        fi
        # replacing all dev. addresses to test addresses
        sed -i "s/$WEBSITE_SUBDOMAIN_NAME$WEBSITE_ADDRESS/$WEBSITE_ADDRESS/g" configuration.php
        # disabling ssl
        sed -i "s/force_ssl = '1'/force_ssl = '0'/" configuration.php
        sed -i "s/force_ssl = '2'/force_ssl = '0'/" configuration.php
        # cookie domain to test address
        sed -i "s/cookie_domain = '$WEBSITE_SUBDOMAIN_NAME$WEBSITE_ADDRESS'/cookie_domain = '$WEBSITE_DOMAIN_NAME.test'/" configuration.php
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

    sudo service mysql restart
    sudo service apache2 start
    sudo service apache2 restart   
else
    # FTP using FileZilla to retrieve necessary files for non-cms websites
    echo "FTP (using FileZilla) into the server as www-data user: use the .gitignore file and download all the files that are ignored to the www/$WEBSITE_ADDRESS/public_html/ directory" 
    echo 'Look through the .htaccess file and modify the values to work for your local (ex: check any forcing for ssl...)'
    echo ''
    echo 'When you are done press Enter'
    read USER_CHECKPOINT

    sudo service mysql restart
    sudo service apache2 start
    sudo service apache2 restart
fi

echo ''
echo "The full installation of the $WEBSITE_DOMAIN_NAME is now complete!"
