#!/bin/bash

SERVICE_FILE="/etc/init.d/snailycad"

cat <<EOF | sudo tee "$SERVICE_FILE"
[Unit]
Description=SnailyCAD Startup Script

[Service]
Type=simple
ExecStart=/opt/mellowservices/snailyinstall.sh
TimeoutStartSec=7200

[Install]
WantedBy=default.target
EOF

sudo update-rc.d snailycad defaults
sudo systemctl enable snailycad
sudo systemctl start snailycad
