{
  config,
  pkgs,
  lib,
  user,
  ...
}: let
  symlink = config.lib.file.mkOutOfStoreSymlink;
  rimeIceData = "${pkgs.rime-ice}/share/rime-data";
  rimeIceFiles = [
    "custom_phrase.txt"
    "double_pinyin.schema.yaml"
    "double_pinyin_abc.schema.yaml"
    "double_pinyin_flypy.schema.yaml"
    "double_pinyin_jiajia.schema.yaml"
    "double_pinyin_mspy.schema.yaml"
    "double_pinyin_sogou.schema.yaml"
    "double_pinyin_ziguang.schema.yaml"
    "melt_eng.dict.yaml"
    "melt_eng.schema.yaml"
    "radical_pinyin.dict.yaml"
    "radical_pinyin.schema.yaml"
    "rime_ice.dict.yaml"
    "rime_ice.schema.yaml"
    "rime_ice_suggestion.yaml"
    "symbols_caps_v.yaml"
    "symbols_v.yaml"
    "t9.schema.yaml"
  ];
in {
  home = {
    username = user.name;
    homeDirectory = user.home;
    stateVersion = "25.11";
    sessionPath = ["${user.dotroot}/scripts"];
  };

  nixpkgs.config.allowUnfree = true;

  home.activation = {
    fixScriptPermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -t 0 ]; then
        PATH="${pkgs.coreutils}/bin:${pkgs.findutils}/bin:$PATH" \
        ${pkgs.bash}/bin/bash ${../../scripts/fix-script-permissions.sh} "${user.dotroot}/scripts"
      fi
    '';

    pruneBackups = lib.hm.dag.entryAfter ["fixScriptPermissions"] ''
      if [ -t 0 ]; then
        PATH="${pkgs.coreutils}/bin:${pkgs.findutils}/bin:$PATH" \
        ${pkgs.bash}/bin/bash ${../../scripts/prune-backups.sh}
      fi
    '';
  };

  xdg = {
    enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/markdown" = ["typora.desktop"];
        "text/plain" = ["neovim.desktop"];
        "text/x-python" = ["neovim.desktop"];
        "text/x-shellscript" = ["neovim.desktop"];
        "text/x-csrc" = ["neovim.desktop"];
        "text/x-c++src" = ["neovim.desktop"];
        "text/x-java" = ["neovim.desktop"];
        "text/x-javascript" = ["neovim.desktop"];
      };
    };
    configFile = {
      "alacritty".source = ../config/alacritty;
      "cava".source = ../config/cava;
      "clipse/config.json".source = ../config/clipse/config.json;
      "clipse/custom_theme.json".source = ../config/clipse/custom_theme.json;
      "fastfetch".source = ../config/fastfetch;
      "gitui".source = ../config/gitui;
      "kitty".source = ../config/kitty;
      "yazi".source = ../config/yazi;

      "btop".source = ../config/btop;
      "fcitx5".source = ../config/fcitx5;
      "fish".source = symlink "${user.cfg}/fish";
      "gtk-3.0".source = ../config/gtk-3.0;
      "gtk-4.0".source = ../config/gtk-4.0;
      "Kvantum".source = ../config/Kvantum;
      "niri".source = symlink "${user.cfg}/niri";
      "noctalia".source = ../config/noctalia;
      "nvtop".source = ../config/nvtop;
      "nwg-look".source = ../config/nwg-look;
      "qt6ct".source = ../config/qt6ct;
      "xsettingsd".source = ../config/xsettingsd;
      "starship.toml".source = ../config/starship.toml;
    };
    dataFile =
      {
        "applications/code.desktop".source = ../applications/code.desktop;
        "applications/neovim.desktop".source = ../applications/neovim.desktop;
        "applications/typora.desktop".source = ../applications/typora.desktop;
        "fcitx5/rime/default.custom.yaml".source = ../config/fcitx5/rime/default.custom.yaml;
      }
      // builtins.listToAttrs (map (name: {
          name = "fcitx5/rime/${name}";
          value.source = "${rimeIceData}/${name}";
        })
        rimeIceFiles);
  };

  home.file =
    lib.optionalAttrs ((user ? faceFile) && user.faceFile != "") {
      ".face".source = symlink user.faceFile;
    }
    // {
      "./Pictures/Wallpapers/nixos-wallpaper-catppuccin-macchiato.png".source =
        ../Wallpapers/nixos-wallpaper-catppuccin-macchiato.png;
    };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-rime
      fcitx5-mozc-ut
      fcitx5-gtk
    ];
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };
}
