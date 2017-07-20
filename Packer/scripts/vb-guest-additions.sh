#!/bin/bash -eux

## Install the VirtualBox guest additions

# determine the vbox version and the iso path
VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
VBOX_ISO=VBoxGuestAdditions_$VBOX_VERSION.iso

# mount the iso
mount -o loop $VBOX_ISO /mnt

# install
yes|sh /mnt/VBoxLinuxAdditions.run
umount /mnt

# cleanup VirtualBox
rm $VBOX_ISO
