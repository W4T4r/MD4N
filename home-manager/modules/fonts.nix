{lib, ...}: {
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      sansSerif = ["Neue Frutiger World" "Noto Sans CJK JP" "Noto Sans CJK SC" "FiraCode Nerd Font"];
      serif = ["Palatino Linotype" "Noto Serif JP" "Noto Serif SC" "FiraCode Nerd Font"];
      monospace = ["MonoLisa" "Noto Sans CJK JP" "Noto Sans CJK SC" "FiraCode Nerd Font Mono"];
    };
  };

  xdg.configFile."gtk-3.0/settings.ini".source = lib.mkForce ../config/custom-fonts/gtk-3.0-settings.ini;
  xdg.configFile."gtk-4.0/settings.ini".source = lib.mkForce ../config/custom-fonts/gtk-4.0-settings.ini;
  xdg.configFile."fcitx5/conf/classicui.conf".source = lib.mkForce ../config/custom-fonts/fcitx5-classicui.conf;
}
