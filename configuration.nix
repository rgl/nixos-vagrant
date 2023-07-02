{ config, pkgs, ... }: {
  imports = [
    # include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # set the time zone.
  time.timeZone = "Europe/Lisbon";

  # set the keyboard layout.
  console.keyMap = "pt-latin9";

  # install the OpenSSH service.
  services.openssh.enable = true;

  # configure sudo to not ask for passwords to the wheel group members.
  security.sudo.wheelNeedsPassword = false;

  # create the vagrant user.
  users.users.vagrant = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"];
  };
}
