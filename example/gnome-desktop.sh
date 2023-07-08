#!/usr/bin/env bash
set -euxo pipefail

# detect the hypervisor.
dmi_sys_vendor="$(cat /sys/devices/virtual/dmi/id/sys_vendor)"
case "$dmi_sys_vendor" in
  'QEMU')
    hypervisor='qemu'
    ;;
  'Microsoft Corporation')
    hypervisor='hyperv'
    ;;
  *)
    hypervisor=''
    ;;
esac

# create the gnome-desktop.nix file.
# see https://nixos.wiki/wiki/GNOME
# see https://nixos.wiki/wiki/Keyboard_Layout_Customization
# see https://nixos.wiki/wiki/Firefox
# see https://nixos.wiki/wiki/Chromium
# see https://nixos.wiki/wiki/VSCodium
cat >/etc/nixos/gnome-desktop.nix <<'EOF'
{ config, pkgs, ... }: {
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver = {
    layout = "pt";
    xkbVariant = "";
    xkbOptions = "";
  };
  environment.systemPackages = with pkgs; [
    chromium
    ffmpeg
    firefox
    git
    vim
    vlc
    vscodium
  ];
  services.xserver.excludePackages = with pkgs; [
    xterm
  ];
  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
  ]) ++ (with pkgs.gnome; [
    atomix # puzzle game
    cheese # webcam tool
    epiphany # web browser
    evince # document viewer
    geary # email reader
    gedit # text editor
    gnome-characters
    gnome-maps
    gnome-music
    gnome-weather
    hitori # sudoku game
    iagno # go game
    tali # poker game
    totem # video player
  ]);
}
EOF

# create the gnome-desktop-$hypervisor.nix file.
if [ "$hypervisor" == 'qemu' ]; then
  cat >/etc/nixos/gnome-desktop-$hypervisor.nix <<'EOF'
{ config, pkgs, ... }: {
  services.spice-vdagentd.enable = true;
}
EOF
elif [ "$hypervisor" == 'hyperv' ]; then
  cat >/etc/nixos/gnome-desktop-$hypervisor.nix <<'EOF'
{ config, pkgs, ... }: {
  users.users.gdm.extraGroups = ["video"];
  users.users.vagrant.extraGroups = ["video"];
}
EOF
fi

# include the gnome-desktop-$hypervisor.nix file in the system configuration.
if [ -n "$hypervisor" ] && ! grep -qE "gnome-desktop-$hypervisor\.nix" /etc/nixos/configuration.nix; then
  sed -i -E "s,^((.+)./hardware-configuration.nix),\1\n\2./gnome-desktop-$hypervisor.nix,g" /etc/nixos/configuration.nix
fi

# include the gnome-desktop.nix file in the system configuration.
if ! grep -qE 'gnome-desktop\.nix' /etc/nixos/configuration.nix; then
  sed -i -E 's,^((.+)./hardware-configuration.nix),\1\n\2./gnome-desktop.nix,g' /etc/nixos/configuration.nix
fi

# rebuild and add to boot.
# NB you must reboot for this to be effective.
nixos-rebuild boot
