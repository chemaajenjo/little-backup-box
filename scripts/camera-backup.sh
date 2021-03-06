#!/usr/bin/env bash

set -x

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# IMPORTANT:
# Run the install-little-backup-box.sh script first
# to install the required packages and configure the system.

# Specify a storage device and its mount point
HOME_DIR="/home/pi/BACKUP" # Home directory path
SHUTD="5" # Minutes to wait before shutdown due to inactivity

# Set the ACT LED to heartbeat
sudo sh -c "echo heartbeat > /sys/class/leds/led0/trigger"

# Set gpio 21 in mode out
gpio -g mode 21 out

# Shutdown after a specified period of time (in minutes) if no device is connected.
sudo shutdown -h $SHUTD "Shutdown is activated. To cancel: sudo shutdown -c"

# Wait for camera
DEVICE=$(gphoto2 --auto-detect | grep usb | cut -b 36-42 | sed 's/,/\//')
while [ -z "${DEVICE}" ]
	do
	sleep 1
	DEVICE=$(gphoto2 --auto-detect | grep usb | cut -b 36-42 | sed 's/,/\//')
	gpio -g toggle 21
done

# Cancel shutdown
sudo shutdown -c

gpio -g blink 21 &
pid_blink=$!

# Obtain camera model
# Create the target directory with the camera model as its name
CAMERA=$(gphoto2 --summary | grep "Model" | cut -d: -f2 | tr -d '[:space:]')
NUM_FILES=$(gphoto2 --summary | grep "Images" | cut -d: -f2 | tr -d '[:space:]')
STORAGE_MOUNT_POINT="$HOME_DIR/$CAMERA"
mkdir -p "$STORAGE_MOUNT_POINT"

#create files with info for screen
echo $STORAGE_MOUNT_POINT > /tmp/BACKUP_PATH
echo $NUM_FILES > /tmp/NUM_FILES
echo $CAMERA > /tmp/DEVICE

# Switch to STORAGE_MOUNT_POINT and transfer files from the camera
# Rename the transferred files using the YYYYMMDD-HHMMSS format
cd $STORAGE_MOUNT_POINT

sudo kill $pid_blink > /dev/null

chmod -R a=rwx $HOME_DIR

# Shutdown
shutdown -h now 
