#!/bin/bash
# see https://nixos.org/manual/nixos/stable/index.html#sec-installation-manual-summary
set -euxo pipefail

target_device=/dev/sda

# initialize the installation block device.
parted $target_device -- mklabel gpt
parted $target_device -- mkpart ESP fat32 1MB 512MB                # sda1 boot.
parted $target_device -- mkpart primary linux-swap 512MB 1024MB    # sda2 swap.
parted $target_device -- mkpart primary ext4 1024MB -1             # sda3 nixos.
parted $target_device -- set 1 esp on
mkfs.fat -F 32 -n boot "${target_device}1"
mkswap -L swap "${target_device}2"
swapon "${target_device}2"
mkfs.ext4 -L nixos "${target_device}3"
while [ ! -e /dev/disk/by-label/nixos ]; do sleep 1; done
mount /dev/disk/by-label/nixos /mnt
install -d /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
parted $target_device -- print
lsblk $target_device

# install.
nixos-generate-config --root /mnt
mv /mnt/etc/nixos/configuration.nix{,.orig}
install /provision/configuration.nix /mnt/etc/nixos/configuration.nix
nixos-install
reboot
