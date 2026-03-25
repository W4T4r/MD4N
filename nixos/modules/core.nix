{ pkgs, user, ... }:

let
  dualBootEnabled = user.enableDualBoot or false;
  hibernateEnabled = (user.enableHibernate or false) && !dualBootEnabled;
  virtualizationGroups =
    if (user.packageProfile or "full") == "minimal" then
      [ ]
    else
      [ "podman" "libvirtd" "kvm" ];
in
{
  networking.hostName = user.hostname;
  networking.networkmanager.enable = true;

  time.timeZone = user.timezone;
  i18n.defaultLocale = user.locale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = user.locale;
    LC_IDENTIFICATION = user.locale;
    LC_MEASUREMENT = user.locale;
    LC_MONETARY = user.locale;
    LC_NAME = user.locale;
    LC_NUMERIC = user.locale;
    LC_PAPER = user.locale;
    LC_TELEPHONE = user.locale;
    LC_TIME = user.locale;
  };

  users.users.${user.name} = {
    isNormalUser = true;
    description = user.fullname;
    extraGroups = [ "networkmanager" "wheel" ] ++ virtualizationGroups;
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "25.11";

  systemd.targets = {
    sleep.enable = true;
    suspend.enable = true;
    hibernate.enable = hibernateEnabled;
    "hybrid-sleep".enable = hibernateEnabled;
  };
}
