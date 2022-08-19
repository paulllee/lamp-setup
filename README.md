# LAMP Web Development Enviroment

a lamp environment setup script on Ubuntu 18.04.5 WSL for Lyquix

# Important Information

You have to run these commands (separately) every time you reboot your computer:

`sudo service mysql start`

`sudo service apache2 start`

This may seem redundant but is needed for WordPress sites:

`sudo service apache2 restart`

# Before You Start

If you are using websites that were previously set up on your local, make sure to create a backup of **ALL** databases.

# Prerequisites

1. Open Turn Windows features on and off:
   - Disable HYPER-V (*HYPER-V breaks WordPress sites*)
   - Disable HYPER-V Platform
   - Enable Windows Subsystem for Linux
   
2. Restart the computer.

3. Install “Ubuntu 18.04.5 LTS” from the Microsoft Store.
   - Open up the application and wait a few minutes.
   - Once a prompt appears, input the following:
     - Enter new UNIX username: `ubuntu`
     - New password: `ubuntu`
     - Retype new password: `ubuntu`

# LAMP Setup Installation

Run the following commands in order to download and run the LAMP setup script!

`cd`

`curl https://raw.githubusercontent.com/paulllee/lamp-setup/main/setup.sh -o setup.sh`

`sudo bash setup.sh`

# Example Website Installation

Run the following commands in order to download and run the website setup script!

`cd`

`curl https://raw.githubusercontent.com/paulllee/lamp-setup/main/website-setup.sh -o website-setup.sh`

`sudo bash website-setup.sh`

# hosts file

1. Run Notepad as administrator

2. File → Open

3. C:\Windows\System32\drivers\etc

4. Change Text documents to All Files

5. Open hosts (NOT hosts.ics)

6. Update addresses to `127.0.0.1`
   - ex: `127.0.0.1 google.test`
