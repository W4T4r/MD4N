{
  config,
  pkgs,
  lib,
  user,
  ...
}: let
  symlink = config.lib.file.mkOutOfStoreSymlink;
in {
  home = {
    username = user.name;
    homeDirectory = user.home;
    stateVersion = "25.11";
    sessionPath = ["${user.dotroot}/scripts"];
    packages = with pkgs; [
      rime-ice
    ];
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

      "btop".source = symlink "${user.cfg}/btop";
      "fcitx5".source = symlink "${user.cfg}/fcitx5";
      "fish/config.fish".source = symlink "${user.cfg}/fish/config.fish";
      "fish/functions".source = symlink "${user.cfg}/fish/functions";
      "gtk-3.0".source = symlink "${user.cfg}/gtk-3.0";
      "gtk-4.0".source = symlink "${user.cfg}/gtk-4.0";
      "Kvantum".source = symlink "${user.cfg}/Kvantum";
      "niri/animations.kdl".source = symlink "${user.cfg}/niri/animations.kdl";
      "niri/config.kdl".source = symlink "${user.cfg}/niri/config.kdl";
      "niri/debug-options.kdl".source = symlink "${user.cfg}/niri/debug-options.kdl";
      "niri/input.kdl".source = symlink "${user.cfg}/niri/input.kdl";
      "niri/key-bindings.kdl".source = symlink "${user.cfg}/niri/key-bindings.kdl";
      "niri/layer-rules.kdl".source = symlink "${user.cfg}/niri/layer-rules.kdl";
      "niri/layout.kdl".source = symlink "${user.cfg}/niri/layout.kdl";
      "niri/miscellaneous.kdl".source = symlink "${user.cfg}/niri/miscellaneous.kdl";
      "niri/outputs.kdl".source = symlink user.niriOutputsFile;
      "niri/window-rules.kdl".source = symlink "${user.cfg}/niri/window-rules.kdl";
      "niri/scripts/browser.sh".source = symlink user.niriBrowserScript;
      "niri/scripts/polkit.sh".source = symlink "${user.cfg}/niri/scripts/polkit.sh";
      "noctalia".source = symlink "${user.cfg}/noctalia";
      "nvtop".source = symlink "${user.cfg}/nvtop";
      "nwg-look".source = symlink "${user.cfg}/nwg-look";
      "qt6ct".source = symlink "${user.cfg}/qt6ct";
      "xsettingsd".source = symlink "${user.cfg}/xsettingsd";
      "starship.toml".source = symlink "${user.cfg}/starship.toml";
    };
    dataFile = {
      "applications/code.desktop".source = ../applications/code.desktop;
      "applications/neovim.desktop".source = ../applications/neovim.desktop;
      "applications/typora.desktop".source = ../applications/typora.desktop;
      "fcitx5/rime".source = ../config/fcitx5/rime;
    };
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
