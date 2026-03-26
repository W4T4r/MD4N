{lib, ...}: {
  xdg.configFile."gtk-3.0/settings.ini".source = lib.mkForce ../config/custom-fonts/gtk-3.0-settings.ini;
  xdg.configFile."gtk-4.0/settings.ini".source = lib.mkForce ../config/custom-fonts/gtk-4.0-settings.ini;
  xdg.configFile."fcitx5/conf/classicui.conf".source = lib.mkForce ../config/custom-fonts/fcitx5-classicui.conf;
}
