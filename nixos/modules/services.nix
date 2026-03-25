{ pkgs, user, ... }:

{
  services.fprintd.enable = user.enableFingerprint or false;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = false;
  services.printing.enable = true;
  services.gvfs.enable = true;
  services.input-remapper.enable = true;

  services.ollama = {
    enable = user.enableOllama or false;
    package =
      if (user.gpuVendor or "generic") == "amd" then
        pkgs.ollama-rocm
      else
        pkgs.ollama;
  };

  programs.steam = {
    enable = user.enableSteam or false;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
}
