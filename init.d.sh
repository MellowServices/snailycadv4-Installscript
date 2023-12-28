sudo mkdir -p /opt/mellowservices && cd /opt/mellowservices && \
curl -O https://raw.githubusercontent.com/MellowServices/snailycadv4-Installscript/main/snailyinstall.sh && \
chmod +x snailyinstall.sh && \
SCRIPT_PATH="/opt/mellowservices/snailyinstall.sh" && \
INITD_SCRIPT="/etc/init.d/snailycad" && \
sudo cp "$SCRIPT_PATH" "$INITD_SCRIPT" && \
sudo chmod +x "$INITD_SCRIPT" && \
sudo update-rc.d snailycad defaults && \
sudo service snailycad start && \
echo "SnailyCAD installation script has been downloaded to /opt/mellowservices, converted, and the init.d script has been created and started."
