#!/bin/bash

# Replace 'snailycad' with your actual service name
SERVICE_NAME="MSsnailycad"
SERVICE_SCRIPT="/opt/mellowservices/snailyinstall.sh"
INIT_SCRIPT="/etc/init.d/$SERVICE_NAME"

cat <<EOF | sudo tee "$INIT_SCRIPT"
#!/bin/bash
### BEGIN INIT INFO
# Provides:          $SERVICE_NAME
# Required-Start:    $local_fs $network $remote_fs $syslog
# Required-Stop:     $local_fs $network $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: SnailyCAD StartUp Script
### END INIT INFO

SERVICE_SCRIPT="$SERVICE_SCRIPT"

case "\$1" in
    start)
        echo "Starting \$SERVICE_NAME..."
        \$SERVICE_SCRIPT start
        ;;
    stop)
        echo "Stopping \$SERVICE_NAME..."
        \$SERVICE_SCRIPT stop
        ;;
    restart)
        echo "Restarting \$SERVICE_NAME..."
        \$SERVICE_SCRIPT restart
        ;;
    *)
        echo "Usage: \$0 {start|stop|restart}"
        exit 1
        ;;
esac

exit 0
EOF

# Make the init.d script executable
sudo curl -o /opt/mellowservices/snailyinstall.sh https://raw.githubusercontent.com/MellowServices/snailycadv4-Installscript/main/snailyinstall.sh
sudo chmod +x "$INIT_SCRIPT"
sudo chmod +x /etc/init.d/MSsnailycad
