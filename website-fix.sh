#!/bin/bash

# Author: Paul Lee
# Company: Lyquix
# Description: Fixes file_get_contents() remote script issue if the Lyquix template is not up to date

if [ $EUID != 0 ]
then
    echo "please run this script as root, for example:"
    echo "sudo bash website-fix.sh"
    exit
fi

echo 'Starting the Website Fix for Outdated Lyquix Templates'

echo ''
echo "I will ask you to verify that the credentials are correct at the end if you mess up"

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
    if [ "$USER_VERIFIED" == '' ]
    then
        USER_VERIFIED=NO
    fi
done

WEBSITE_ADDRESS=$WEBSITE_DOMAIN_NAME$WEBSITE_DOMAIN_EXTENSION

echo ''
echo "Has $WEBSITE_ADDRESS already been installed on your local?"
echo "If so, check if it is at C:/.../Documents/www/$WEBSITE_ADDRESS"
echo 'YES for it is installed / NO for it is not installed (case sensitive):'
read USER_VERIFIED
    if [ "$USER_VERIFIED" != 'YES' ]
    then
        echo "First install the website onto your local before running the fix"
        echo ''
        echo 'curl https://raw.githubusercontent.com/paulllee/lamp-setup/main/website-setup.sh -o website-setup.sh'
        echo 'sudo bash website-setup.sh'
        exit
    fi

cd /srv/www/$WEBSITE_ADDRESS/

curl https://raw.githubusercontent.com/paulllee/lamp-setup/main/config-templates/jsphp-fix -o jsphp-fix

JS_PATH="$(find /srv/www/$WEBSITE_ADDRESS/ -name 'js.php')"

sed -i '/ Remote script: /r jsphp-fix' $JS_PATH
sed -i '/curl_close($curl);/{
    n
    d
    }' $JS_PATH

rm jsphp-fix

cd

echo "The fix has been applied for $WEBSITE_ADDRESS"