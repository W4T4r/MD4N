{
  pkgs,
  user,
  ...
}: let
  virtualizationEnabled = (user.enableVirtualization or true) && (user.packageProfile or "full") != "minimal";
in {
  # Author's kitchen-sink profile: enable the whole desktop/tooling set.
  home.packages = with pkgs;
    [
      fastfetch
      yazi
      yaziPlugins.gitui
      clipse
      cliphist
      wl-clipboard
      brightnessctl
      wlsunset
      wdisplays
      hyprpicker
      qt6Packages.qt6ct
      kdePackages.qtmultimedia
      kdePackages.qtstyleplugin-kvantum
      nwg-look
      kdePackages.breeze-icons
      adwaita-icon-theme
      candy-icons
      sweet
      catppuccin-qt5ct
      catppuccin-kvantum
      kitty-themes
      google-chrome
      vesktop
      thunderbird
      mpv
      obs-studio
      cava
      davinci-resolve
      typora
      zotero
      vscode
      libsecret
      gemini-cli
      codex
      claude-code
    ]
    ++ (
      if virtualizationEnabled
      then [
        podman-desktop
        distrobox
        distroshelf
      ]
      else []
    );
}
