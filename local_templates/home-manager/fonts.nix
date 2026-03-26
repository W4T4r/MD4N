{...}: {
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      sansSerif = [
        "Neue Frutiger World"
        "Noto Sans CJK JP"
        "Noto Sans CJK SC"
        "FiraCode Nerd Font"
      ];
      serif = [
        "Palatino Linotype"
        "Noto Serif JP"
        "Noto Serif SC"
        "FiraCode Nerd Font"
      ];
      monospace = [
        "MonoLisa"
        "Noto Sans CJK JP"
        "Noto Sans CJK SC"
        "FiraCode Nerd Font Mono"
      ];
    };
  };
}
