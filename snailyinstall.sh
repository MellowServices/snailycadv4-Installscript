#!/bin/bash

# Install required packages
sudo apt install -y git
sudo apt update
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y net-tools
sudo apt install -y nodejs
sudo npm install --global yarn
sudo apt update && sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql.service
sudo systemctl enable postgresql.service




# Set up database () STILL NEEDS MAJOR WORK
rampassworduser=\$LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w "12" | head -n 1
export rampassworduser

database_setup_script="database_setuptest"
cat <<EOF > "$database_setup_script"
#!/bin/bash
sudo -u postgres -i <<EOM
psql -d postgres <<EOSQL
CREATE USER "snailycad";
ALTER USER "snailycad" WITH SUPERUSER;
ALTER USER "snailycad" PASSWORD :'replace_me';
CREATE DATABASE "snaily-cadv4";
\q
EOSQL
EOM
EOF

sed -i "s|:'replace_me'|'$rampassworduser'|" "$database_setup_script"


# Make the script executable
chmod +x "$database_setup_script"

# Run the script
./"$database_setup_script"


chmod +x database_setuptest
sleep 10

#END Database Setup

# Get the IP address
ip_address=$(ifconfig ens18 | awk '/inet /{print $2}')

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
git clone https://github.com/SnailyCAD/snaily-cadv4.git
cd snaily-cadv4

# Update .env file
env_file=".env"
cp .env.example "$env_file"
sed -i "s|POSTGRES_DB=\".*\"|POSTGRES_DB=\"snaily-cadv4\"|" "$env_file"
sed -i "s|POSTGRES_USER=\".*\"|POSTGRES_USER=\"snailycad\"|" "$env_file"
sed -i "s|POSTGRES_PASSWORD=\".*\"|POSTGRES_PASSWORD=\"$rampassworduser\"|" "$env_file"
sed -i "s|CORS_ORIGIN_URL=\".*\"|CORS_ORIGIN_URL=\"https://$valid_ip\"|" "$env_file"
sed -i "s|NEXT_PUBLIC_PROD_ORIGIN=\".*\"|NEXT_PUBLIC_PROD_ORIGIN=\"https://$valid_ip/v1\"|" "$env_file"

# Install dependencies
yarn

# Build the project
yarn turbo run build --filter="{packages/**/**}" && yarn turbo run build --filter="{apps/**/**}"

echo "Setup complete. The .env file has been updated with the necessary information."
