#!/bin/bash
set -x

echo "initializing rise-core installation"

date
ps axjf

VMNAME=`hostname`
BLOCK="/etc/nginx/sites-enabled/default"

echo "What is your email address? This is for SSL configuration"
read email

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
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
touch ~/.profile
echo "export PATH=~/.npm-global/bin:$PATH" >> ~/.profile
source ~/.profile

sudo apt-get install -y postgresql-contrib libpq-dev git build-essential

# Configure Firewall
sudo apt-get install -y ufw

sudo ufw disable
sudo ufw default deny incoming
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 4242/tcp
sudo ufw --force enable

# Configure Postgres
sudo -u postgres psql -c "CREATE DATABASE rise_mainnet;"
sudo -u postgres psql -c "CREATE USER rise WITH PASSWORD '8E&)J}pzHt=4sHya';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE rise_mainnet TO rise;"

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
git clone https://github.com/mody199610/Rise-Classic.git

# Configure
echo "Installing Dependencies for Rise-Core"
cd rise-core
npm install -g forever
npm install --production

echo "Installing Dependencies for Web-UI"
cd public
npm install --production

cd ../

echo "Installing Nginx and SSL"
sudo apt-get install -y nginx
sudo service nginx stop

sudo tee $BLOCK > /dev/null <<EOF 

server {
    listen 80;
    server_name $VMNAME;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $VMNAME;

    ssl_certificate /etc/letsencrypt/live/$VMNAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$VMNAME/privkey.pem;

    location / {
        proxy_pass http://localhost:4242;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

wget https://dl.eff.org/certbot-auto
chmod a+x ./certbot-auto
./certbot-auto certonly -d $VMNAME -m $email --agree-tos -n --no-verify-ssl 

sudo mkdir /etc/nginx/ssl
cp -R /etc/letsencrypt/live/$VMNAME /etc/nginx/ssl
sudo chmod -R 600 /etc/nginx/ssl

sudo service nginx start

forever start app.js

echo "You should rise-core running in the above list"
echo ""
echo "Run the following command to start Rise-Core on Testnet if you need to start Rise-Core after a reboot. You will
 need to be in the rise-core directory"
echo "npm start"
echo ""
echo "Exiting"
exit 0
