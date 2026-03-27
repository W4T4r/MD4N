{...}: {
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      # Keep the starter useful without private font installs.
      sansSerif = [
        "Noto Sans"
        "DejaVu Sans"
        "Liberation Sans"
        "Noto Sans CJK JP"
        "Noto Sans CJK SC"
      ];
      serif = [
        "Noto Serif"
        "DejaVu Serif"
        "Liberation Serif"
      ];
      monospace = [
        "DejaVu Sans Mono"
        "Liberation Mono"
        "Noto Sans Mono"
      ];
    };
  };
}
