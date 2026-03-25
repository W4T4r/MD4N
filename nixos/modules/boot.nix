{ pkgs, inputs, user, ... }:

{
  boot.loader = {
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = user.enableDualBoot or false;
      theme = inputs.nixos-grub-themes.packages.${pkgs.stdenv.hostPlatform.system}.nixos;
    };
    systemd-boot.enable = false;
    efi.canTouchEfiVariables = true;
  };

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 16 * 1024;
  }];
}
