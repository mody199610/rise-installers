#!/bin/bash
set -x

echo "initializing rise-core installation"

date
ps axjf

AZUREUSER=$2
HOMEDIR="/home/$AZUREUSER"
VMNAME=`hostname`
echo "User: $AZUREUSER"
echo "User home dir: $HOMEDIR"
echo "rise-core path: $HOMEDIR/rise-core"
echo "vmname: $VMNAME"

platform='ubuntu'
echo "Ubuntu detected - installing Rise-Core"

	#Install pre-reqs
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -

sudo apt-get purge -y nodejs
sudo apt-get purge -y postgresql*

# Install Postgres, Node, Git
sudo apt-get update
sudo apt-get install -y nodejs postgresql
sudo apt-get install -y postgresql-contrib libpq-dev git build-essential

# Configure Firewall
sudo apt-get install -y ufw

sudo ufw disable
sudo ufw deny all
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow tcp/4000
sudo ufw enable

# Configure Postgres
sudo -u postgres psql -c "CREATE DATABASE rise_testnet;"
sudo -u postgres psql -c "CREATE USER risetest WITH PASSWORD 'risetestpassword';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE rise_testnet TO risetest;"

if sudo pgrep -x "ntpd" > /dev/null; then
    echo "√ NTP is running"
else
    echo "X NTP is not running"
    echo -e "\nInstalling NTP, please provide sudo password.\n"
    sudo apt-get install ntp -yyq
    sudo service ntp stop
    sudo ntpdate pool.ntp.org
    sudo service ntp start
fi

echo ""
echo ""

# Download Release
git clone https://bitbucket.org/risevisionfoundation/rise-core.git

# Configure
echo "Installing Dependencies for Rise-Core"
cd rise-core
sudo npm install -g forever
npm install --production

echo "Installing Dependencies for Web-UI"
cd public
npm install --production

cd ../

npm start

forever list
echo "You should rise-core running in the above list"
echo ""
echo "Run the following command to start Rise-Core on Testnet if you need to start Rise-Core after a reboot. You will
 need to be in the rise-core directory"
echo "npm start"
echo ""
echo "Exiting"
exit 0
