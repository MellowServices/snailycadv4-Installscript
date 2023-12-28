#!/bin/bash

### BEGIN INIT INFO
# Provides:          snailycad
# Required-Start:    $local_fs $network $remote_fs $syslog
# Required-Stop:     $local_fs $network $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: SnailyCAD Startup Script
### END INIT INFO


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
