#!/bin/sh
echo "Broseki's Share Joiner"

# Check if rclone is installed and install it if it isn't
echo "Checking if rclone is installed..."
if ! type "rclone" > /dev/null;
then
    	echo "rclone is not installed...installing..."
	curl https://rclone.org/install.sh | sudo bash
	echo "rclone installed!"
else
	echo "rclone is installed!"
fi

echo "Checking if fuse is installed..."
if ! type "fusermount" > /dev/null;
then
        echo "fuse is not installed...installing..."
        apt install -y fuse
	echo "fuse installed!"
else
        echo "fuse is installed!"
fi

mkdir -p /root/.config/
mkdir -p /root/.config/rclone

# Check if the configuration file exists and create it if it doesn't
if [ -f "/root/.config/rclone/rclone.conf" ];
then
	echo "Configuration file already exists..."
else
	echo "Configuration file not found, creating it..."
	touch /root/.config/rclone/rclone.conf
fi

# Check if the config has our fileshare in it already, add it if it doesn't
if grep -q "$ANSIBLE_RCLONE_CONFIG_NAME" "/root/.config/rclone/rclone.conf"; then
	echo "Fileshare already configured"
else
	echo "[$ANSIBLE_RCLONE_CONFIG_NAME]" >> /root/.config/rclone/rclone.conf
	echo "type = sftp" >> /root/.config/rclone/rclone.conf
	echo "host = $ANSIBLE_RCLONE_HOSTNAME" >> /root/.config/rclone/rclone.conf
	echo "user = $ANSIBLE_RCLONE_USERNAME" >> /root/.config/rclone/rclone.conf
	echo "pass = null" >> /root/.config/rclone/rclone.conf
	echo "key_file_pass = $(openssl rand -hex 20)" >> /root/.config/rclone/rclone.conf
fi

# Update username and password just in case it change (and also to encrypt it the first time)
echo "Updating credentials..."
rclone config update $ANSIBLE_RCLONE_CONFIG_NAME user=$ANSIBLE_RCLONE_USERNAME
rclone config password $ANSIBLE_RCLONE_CONFIG_NAME pass=$ANSIBLE_RCLONE_PASSWORD
echo "Credentials updated!"

mkdir -p /mnt/rclone
mkdir -p /mnt/rclone/$ANSIBLE_RCLONE_CONFIG_NAME

# Setup the service
echo "Setting up service..."
echo "
[Unit]
Description=$ANSIBLE_RCLONE_CONFIG_NAME (rclone)
# Make sure we have network enabled
After=network.target

[Service]
Type=simple

ExecStart=$(which rclone) mount $ANSIBLE_RCLONE_CONFIG_NAME:/mounts/$ANSIBLE_RCLONE_CONFIG_NAME /mnt/rclone/$ANSIBLE_RCLONE_CONFIG_NAME

# Perform lazy unmount
ExecStop=$(which fusermount) -zu /mnt/rclone/$ANSIBLE_RCLONE_CONFIG_NAME

# Restart the service whenever rclone exists with non-zero exit code
Restart=on-failure
RestartSec=15

[Install]
# Autostart after reboot
WantedBy=default.target
" > /etc/systemd/system/$ANSIBLE_RCLONE_CONFIG_NAME.auto_rclone.service

systemctl daemon-reload
systemctl enable $ANSIBLE_RCLONE_CONFIG_NAME.auto_rclone
systemctl restart $ANSIBLE_RCLONE_CONFIG_NAME.auto_rclone
