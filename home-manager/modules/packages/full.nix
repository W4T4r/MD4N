{ pkgs, user, ... }:

{
  home.packages =
    with pkgs;
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
      vesktop
      mpv
      cava
      typora
      vscode
      libsecret
      gemini-cli
      codex
      claude-code
    ]
    ++ (if user.enableGoogleChrome or true then [ google-chrome ] else [ ])
    ++ (if user.enableThunderbird or true then [ thunderbird ] else [ ])
    ++ (if user.enableObsStudio or true then [ obs-studio ] else [ ])
    ++ (if user.enableDavinciResolve or true then [ davinci-resolve ] else [ ])
    ++ (if user.enableZotero or true then [ zotero ] else [ ])
    ++ (if user.enablePodmanDesktop or true then [ podman-desktop ] else [ ])
    ++ (if user.enableDistrobox or true then [ distrobox ] else [ ])
    ++ (if user.enableDistroshelf or true then [ distroshelf ] else [ ]);
}
