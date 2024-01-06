#!/bin/bash

# Check if script has already run
if [ -f "/opt/mellowservices/startup_check.txt" ]; then
    echo "Script has already run on startup."
    if pm2 status SnailyCADv4 | grep -q "online"; then
        echo "SnailyCAD is already running."
        exit 0
    else
        echo "SnailyCAD is not running."
        cd ~/snaily-cadv4/
        pm2 start npm --name SnailyCADv4 -- run start
        exit 0
    fi
fi


# Install Nginx
apt-get update
apt-get install -y nginx

# Create Nginx configuration
nginx_config="/etc/nginx/sites-available/snailycad"
html_file="/var/www/html/index.html"

# Generate HTML file
cat <<EOF | sudo tee "$html_file"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Embedded Website</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            overflow: hidden;
        }

        iframe {
            width: 100%;
            height: 100vh;
            border: none;
        }
    </style>
</head>
<body>

<iframe src="https://scinstall.mellowservices.com"></iframe>

</body>
</html>
EOF

# Create Nginx configuration
cat <<EOF | sudo tee "$nginx_config"
server {
    listen 3000;
    server_name localhost;

    location / {
        proxy_pass http://localhost:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    # Redirect other ports to port 3000
    error_page 497 =301 https://\$host:\$server_port\$request_uri;


    location /snailycad {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable Nginx site
sudo ln -s "$nginx_config" "/etc/nginx/sites-enabled/"
sudo systemctl restart nginx

# Check if script has already run
if [ -f "/opt/mellowservices/startup_check.txt" ]; then
    echo "Script has already run on startup."
    if pm2 status SnailyCADv4 | grep -q "online"; then
        echo "SnailyCAD is already running."
        exit 0
    else
        echo "SnailyCAD is not running."
        cd ~/snaily-cadv4/ || exit 1
        pm2 start npm --name SnailyCADv4 -- run start
        exit 0
    fi
fi

# Install required packages
sudo apt-get update
sudo apt-get install -y git ca-certificates curl gnupg net-tools

# Install Node.js
NODE_MAJOR=18
curl -fsSL https://deb.nodesource.com/setup_$NODE_MAJOR.x | sudo -E bash -
apt-get install -y nodejs
apt install net-tools

# Install other dependencies
apt-get install -y postgresql postgresql-contrib
systemctl start postgresql.service
systemctl restart packagekit.service
#systemctl enable postgresql.service

# Set up database
rampassworduser=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w "12" | head -n 1)
export rampassworduser

ranstring=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w "12" | head -n 1)
export ranstring

echo "Datbase Start"   
database_setup_script="database_setuptest"
cat <<EOF > "$database_setup_script"
#!/bin/bash
sudo -u postgres -i <<EOM
psql -d postgres <<EOSQL
CREATE USER "snailycad";
ALTER USER "snailycad" WITH SUPERUSER;
ALTER USER "snailycad" PASSWORD '$rampassworduser';
CREATE DATABASE "snaily-cadv4";
\q
EOSQL
EOM
EOF

echo "Database End"

# Replace the placeholder with the random password
sed -i "s|ALTER USER \"snailycad\" PASSWORD.*|ALTER USER \"snailycad\" PASSWORD '$rampassworduser';|" "$database_setup_script"

# Make the script executable
chmod +x "$database_setup_script"

# Run the script
./"$database_setup_script"

chmod +x database_setuptest
sleep 10

# END Database Setup

# Get the IP address
ip_address=$(ifconfig ens3 | awk '/inet /{print $2}')

# Ping check
ping_result=$(ping -c 1 1.1.1.1)
if [[ $ping_result =~ "1 packets transmitted, 1 received" ]]; then
    echo "Ping successful!"
    valid_ip=$ip_address
    echo "Valid IP address: $valid_ip"
else
    echo "Ping failed!"
fi

# Clone the repository
cd ~ || exit 1
git clone https://github.com/SnailyCAD/snaily-cadv4.git
cd snaily-cadv4 || exit 1

# Update .env file
env_file=".env"
cp .env.example "$env_file"
sed -i "s|POSTGRES_DB=\".*\"|POSTGRES_DB=\"snaily-cadv4\"|" "$env_file"
sed -i "s|POSTGRES_USER=\".*\"|POSTGRES_USER=\"snailycad\"|" "$env_file"
sed -i "s|POSTGRES_PASSWORD=\".*\"|POSTGRES_PASSWORD=\"$rampassworduser\"|" "$env_file"
sed -i "s|JWT_SECRET=\".*\"|JWT_SECRET=\"$ranstring\"|" "$env_file"
sed -i "s|CORS_ORIGIN_URL=\".*\"|CORS_ORIGIN_URL=\"http://$valid_ip:3000\"|" "$env_file"
sed -i "s|NEXT_PUBLIC_PROD_ORIGIN=\".*\"|NEXT_PUBLIC_PROD_ORIGIN=\"http://$valid_ip:8080/v1\"|" "$env_file"
sed -i "s|NEXT_PUBLIC_CLIENT_URL=\".*\"|NEXT_PUBLIC_CLIENT_URL=\"http://$valid_ip:3000\"|" "$env_file"

sudo npm install -g pnpm

# Install dependencies
pnpm install

# Build the project
pnpm run build

npm install pm2 -g
cd ~/snaily-cadv4/ || exit 1

touch /opt/mellowservices/startup_check.txt

# Remove Nginx configuration
sudo rm -f "/etc/nginx/sites-enabled/snailycad"
sudo systemctl stop nginx
echo "Setup complete. The .env file has been updated with the necessary information."
pm2 start npm --name SnailyCADv4 -- run start
