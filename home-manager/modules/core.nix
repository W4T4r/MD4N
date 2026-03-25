{
  config,
  pkgs,
  lib,
  user,
  ...
}: let
  symlink = config.lib.file.mkOutOfStoreSymlink;
  niriSharedFiles = [
    "animations.kdl"
    "config.kdl"
    "debug-options.kdl"
    "input.kdl"
    "key-bindings.kdl"
    "layer-rules.kdl"
    "layout.kdl"
    "miscellaneous.kdl"
    "window-rules.kdl"
  ];
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

    linkNiriSharedConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
      niri_dir="$HOME/.config/niri"
      mkdir -p "$niri_dir" "$niri_dir/scripts"

      for file in ${lib.concatStringsSep " " niriSharedFiles}; do
        target="${user.cfg}/niri/$file"
        link="$niri_dir/$file"

        if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
          continue
        fi

        if [ -e "$link" ] && [ ! -L "$link" ]; then
          mv "$link" "$link.md4nbak"
        else
          rm -f "$link"
        fi

        ln -s "$target" "$link"
      done

      polkit_target="${user.cfg}/niri/scripts/polkit.sh"
      polkit_link="$niri_dir/scripts/polkit.sh"

      if [ -L "$polkit_link" ] && [ "$(readlink "$polkit_link")" != "$polkit_target" ]; then
        rm -f "$polkit_link"
      fi

      if [ ! -e "$polkit_link" ]; then
        ln -s "$polkit_target" "$polkit_link"
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
      "fish/functions".source = ../config/fish/functions;
      "gtk-3.0".source = ../config/gtk-3.0;
      "gtk-4.0".source = ../config/gtk-4.0;
      "Kvantum".source = ../config/Kvantum;
      "niri/outputs.kdl".source = symlink user.niriOutputsFile;
      "niri/scripts/browser.sh".source = symlink user.niriBrowserScript;
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
