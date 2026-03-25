{ pkgs, user, ... }:

{
  services.fprintd.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = false;
  services.printing.enable = true;
  services.gvfs.enable = true;
  services.input-remapper.enable = true;

  services.ollama = {
    enable = true;
    package =
      if (user.gpuVendor or "generic") == "amd" then
        pkgs.ollama-rocm
      else
        pkgs.ollama;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
}
