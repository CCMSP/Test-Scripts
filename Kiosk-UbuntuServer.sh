#!/bin/bash

KIOSK_USER="kiosk"
KIOSK_URL="https://login.pointclickcare.com/home/userLogin.xhtml"
AUTOLOGIN_SERVICE="/etc/systemd/system/getty@tty1.service.d/override.conf"
CHROMIUM_FLAGS="--kiosk --noerrdialogs --disable-infobars --disable-session-crashed-bubble --disable-features=TranslateUI"
VM_DISPLAY_RESOLUTION="1920x1080"

# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# Install necessary packages
sudo apt install -y xorg openbox chromium-browser

# Create a new user for the kiosk
sudo adduser --disabled-password --gecos "" $KIOSK_USER
sudo usermod -aG sudo $KIOSK_USER

# Set up auto-login for the kiosk user
sudo mkdir -p $(dirname $AUTOLOGIN_SERVICE)
echo "[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $KIOSK_USER --noclear %I \$TERM" | sudo tee $AUTOLOGIN_SERVICE

# Configure Openbox for the kiosk user
sudo mkdir -p /home/$KIOSK_USER/.config/openbox
echo "chromium-browser $CHROMIUM_FLAGS $KIOSK_URL" > /home/$KIOSK_USER/.config/openbox/autostart
sudo chown -R $KIOSK_USER:$KIOSK_USER /home/$KIOSK_USER/.config

# Disable screen blanking and power management
echo "xset s off
xset -dpms
xset s noblank" >> /home/$KIOSK_USER/.config/openbox/autostart

# Optionally set display resolution (uncomment to apply resolution setting)
# echo "xrandr --output <DISPLAY_OUTPUT> --mode $VM_DISPLAY_RESOLUTION" >> /home/$KIOSK_USER/.config/openbox/autostart

# Set Openbox as the default session for the kiosk user
echo "exec openbox-session" > /home/$KIOSK_USER/.xinitrc
sudo chown $KIOSK_USER:$KIOSK_USER /home/$KIOSK_USER/.xinitrc

# Enable automatic start of X server on login
echo "[[ -z \$DISPLAY && \$XDG_VTNR -eq 1 ]] && startx" >> /home/$KIOSK_USER/.profile

# Reboot to apply changes
echo "Setup complete. Rebooting now..."
sudo reboot
