{lib, ...}: let
  gtk3Settings = ../config/custom-fonts/gtk-3.0-settings.ini;
  gtk4Settings = ../config/custom-fonts/gtk-4.0-settings.ini;
  fcitxClassicUi = ../config/custom-fonts/fcitx5-classicui.conf;
in
  lib.mkMerge [
    # Keep the module shared, but treat the actual font UI files as machine-local.
    (lib.mkIf (builtins.pathExists gtk3Settings) {
      xdg.configFile."gtk-3.0/settings.ini".source = lib.mkForce gtk3Settings;
    })
    (lib.mkIf (builtins.pathExists gtk4Settings) {
      xdg.configFile."gtk-4.0/settings.ini".source = lib.mkForce gtk4Settings;
    })
    (lib.mkIf (builtins.pathExists fcitxClassicUi) {
      xdg.configFile."fcitx5/conf/classicui.conf".source = lib.mkForce fcitxClassicUi;
    })
  ]
