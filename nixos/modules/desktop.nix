{pkgs, ...}: {
  hardware.bluetooth.enable = true;

  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  programs.niri.enable = true;
  programs.xwayland.enable = true;
  services.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = with pkgs; [
    atomix
    cheese
    epiphany
    evince
    geary
    gedit
    gnome-characters
    gnome-music
    gnome-photos
    gnome-terminal
    gnome-tour
    hitori
    iagno
    tali
    totem
  ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
}
