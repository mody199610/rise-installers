#!/bin/bash

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew install git node

# Install Postgres
echo "Downloading Postgres.app, unzipping it, and putting it into Applications"
curl -sO "https://rise.vision/cdn/Postgres.zip"

unzip Postgres.zip
mv Postgres.app /Applications
echo "Please enter your sudo password"
sudo spctl --master-disable
open -a Postgres
sudo spctl --master-enable
# Configure Postgres
psql -U $USER -c "CREATE DATABASE rise_testnet;"
psql -U $USER -c "CREATE USER risetest WITH PASSWORD 'risetestpassword';"
psql -U $USER -c "GRANT ALL PRIVILEGES ON DATABASE rise_testnet TO risetest;"

if pgrep -x "ntpd" > /dev/null; then
    echo "√ NTP is running"
else
    sudo launchctl load /System/Library/LaunchDaemons/org.ntp.ntpd.plist
    sleep 1
    if pgrep -x "ntpd" > /dev/null; then
        echo "√ NTP is running"
    else
        echo -e "\nNTP did not start, Please verify its configured on your system"
        exit 0
    fi
fi  #End Darwin Checks
# Download Release
git clone https://github.com/RiseVision/rise-core.git
git fetch master
git checkout master

# Configure
echo "Installing Dependencies for Rise-Core"
cd rise-core
sudo npm install -g forever forever-service
sudo forever-service install rise-core
npm install

echo "Installing Dependencies for Web-UI"
cd public
npm install

cd ../

sudo start rise-core

echo "To check the status of rise-core run:"
echo "status rise-core"
echo ""
echo "Exiting"
exit 1
