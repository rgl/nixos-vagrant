{ config, pkgs, ... }: {
  # install the qemu-guest-agent service.
  services.qemuGuest.enable = true;
}
