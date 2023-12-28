#!/bin/bash

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
sudo apt-get install -y nodejs
apt install net-tools

# Install other dependencies
sudo apt-get install -y pnpm postgresql postgresql-contrib
sudo systemctl start postgresql.service
sudo systemctl enable postgresql.service

# Set up database
rampassworduser=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w "12" | head -n 1)
export rampassworduser

ranstring=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w "12" | head -n 1)
export ranstring

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
echo "Setup complete. The .env file has been updated with the necessary information."
pm2 start npm --name SnailyCADv4 -- run start
