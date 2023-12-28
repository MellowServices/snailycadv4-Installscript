#!/bin/bash


SERVICE_FILE="/etc/systemd/system/snailycad.service"

cat <<EOF | sudo tee "$SERVICE_FILE"
### BEGIN INIT INFO
# Provides:          snailycad
# Required-Start:    $local_fs $network $remote_fs $syslog
# Required-Stop:     $local_fs $network $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: SnailyCAD Startup Script
### END INIT INFO

[Unit]
Description=SnailyCAD Startup Script

[Service]
Type=simple
ExecStart=/opt/mellowservices/snailyinstall.sh
TimeoutStartSec=7200

[Install]
WantedBy=default.target
EOF
sudo mkdir -p /opt/mellowservices/
sudo curl -o /opt/mellowservices/snailyinstall.sh https://raw.githubusercontent.com/MellowServices/snailycadv4-Installscript/main/snailyinstall.sh

sudo update-rc.d snailycad defaults
sudo systemctl enable snailycad
sudo systemctl start snailycad
