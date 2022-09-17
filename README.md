# LAMP Web Development Enviroment

a lamp environment setup script on Ubuntu WSL1 for Lyquix

(as of *September 2nd, 2022*) all versions of Ubuntu that are available on the **Microsoft Store** are compatible: 18.04, 20.04, and 22.04

# Important Information

You have to run these commands (separately) every time you reboot your computer or change your instance of Ubuntu to a different version:

`sudo service mysql start`

`sudo service apache2 start`

This may seem redundant but is needed for WordPress sites:

`sudo service apache2 restart`

### Multiple Instances of Ubuntu

If you decide to run multiple instances of Ubuntu, you can only run **ONE** instance at a time.

Before opening a new instance, you should terminate ALL running instances of Ubuntu by using `wsl --shutdown` in Windows Terminal (PowerShell or CMD).

Do not install the same website onto multiple instances of Ubuntu.

### Outdated Lyquix Templates

If a website is running an outdated Lyquix Template, the [website-setup.sh script](website-setup.sh) will automatically patch a fix. Do not discard the changes in Git.

# Before You Start

If you are using websites that were previously set up on your local, make sure to create a backup of **ALL** databases.

# Prerequisites

1. Open **Turn Windows features on and off**:
   - Disable HYPER-V (*HYPER-V breaks WordPress sites*)
   - Disable HYPER-V Platform
   - Enable Virtual Machine Platform
   - Enable Windows Subsystem for Linux
   
2. Restart the computer.

3. Open Windows Terminal (PowerShell or CMD) and run `wsl --set-default-version 1` to set future WSL installations to Version 1.

4. Install **Ubuntu 18.04, 20.04, or 22.04 LTS** from the **Microsoft Store**.
   - Open up the application and wait a few minutes.
   - Once a prompt appears, input the following:
     - Enter new UNIX username: `ubuntu`
     - New password: `ubuntu`
     - Retype new password: `ubuntu`
     
5. **Important:** Double check and make sure you are on WSL Version 1.
     - To check, Open Windows Terminal (PowerShell or CMD) and run `wsl -l -v`
       - Run `wsl --set-version Ubuntu-18.04 1` if Ubuntu 18.04 is not on Version 1
       - Run `wsl --set-version Ubuntu-20.04 1` if Ubuntu 20.04 is not on Version 1
       - Run `wsl --set-version Ubuntu-22.04 1` if Ubuntu 22.04 is not on Version 1
     - In our use case, WSL Version 1 is ideal since our websites are stored in the Windows file system which runs faster over WSL Version 2.

# LAMP Setup Installation

Run the following commands in your Linux command line to download and run the LAMP setup script!

```
cd
curl https://raw.githubusercontent.com/paulllee/lamp-setup/main/setup.sh -o setup.sh
sudo bash setup.sh
```

# Example Website Installation

Run the following commands in your Linux command line to download and run the website setup script!

```
cd
curl https://raw.githubusercontent.com/paulllee/lamp-setup/main/website-setup.sh -o website-setup.sh
sudo bash website-setup.sh
```

# hosts file

1. Run Notepad as administrator

2. File → Open

3. C:\Windows\System32\drivers\etc

4. Change Text documents to All Files

5. Open hosts (NOT hosts.ics)

6. Update addresses to `127.0.0.1`
   - ex: `127.0.0.1 google.test`
