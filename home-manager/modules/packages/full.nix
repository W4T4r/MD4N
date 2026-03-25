{ pkgs, user, ... }:

let
  virtualizationEnabled = (user.enableVirtualization or true) && (user.packageProfile or "full") != "minimal";
in
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
      mpv
      typora
      vscode
      libsecret
    ]
    ++ (if user.enableVesktop or false then [ vesktop ] else [ ])
    ++ (if user.enableCava or false then [ cava ] else [ ])
    ++ (if user.enableGeminiCli or false then [ gemini-cli ] else [ ])
    ++ (if user.enableCodex or false then [ codex ] else [ ])
    ++ (if user.enableClaudeCode or false then [ claude-code ] else [ ])
    ++ (if user.enableGoogleChrome or false then [ google-chrome ] else [ ])
    ++ (if user.enableThunderbird or false then [ thunderbird ] else [ ])
    ++ (if user.enableObsStudio or false then [ obs-studio ] else [ ])
    ++ (if user.enableDavinciResolve or false then [ davinci-resolve ] else [ ])
    ++ (if user.enableZotero or false then [ zotero ] else [ ])
    ++ (if virtualizationEnabled && (user.enablePodmanDesktop or false) then [ podman-desktop ] else [ ])
    ++ (if virtualizationEnabled && (user.enableDistrobox or false) then [ distrobox ] else [ ])
    ++ (if virtualizationEnabled && (user.enableDistroshelf or false) then [ distroshelf ] else [ ]);
}
