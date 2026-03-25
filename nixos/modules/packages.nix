{ pkgs, inputs, user, ... }:

let
  virtualizationPackages =
    (if user.enableVirtManager or true then [ pkgs.virt-manager ] else [ ])
    ++ (if user.enableVirtManager or true then [ pkgs.dnsmasq pkgs.phodav ] else [ ]);
  optionalWorkstationPackages =
    (if user.enableTexliveFull or true then [ pkgs.texliveFull ] else [ ])
    ++ (if user.enableGlobalProtect or true then [ inputs.globalprotect-openconnect.packages.${pkgs.stdenv.hostPlatform.system}.default ] else [ ]);
  btopPackage =
    if (user.gpuVendor or "generic") == "amd" then
      pkgs.btop-rocm
    else
      pkgs.btop;
  nvtopPackage =
    if (user.gpuVendor or "generic") == "amd" then
      pkgs.nvtopPackages.amd
    else
      pkgs.nvtopPackages.full;
in
{
  environment.systemPackages =
    with pkgs;
    [
      vim
      alacritty
      wget
      git
      firefox
      fzf
      home-manager
      nvtopPackage
      btopPackage
      pavucontrol
      networkmanagerapplet
      polkit_gnome
      noctalia-shell
      nemo
      xarchiver
      xwayland-satellite
    ]
    ++ (if (user.packageProfile or "full") == "minimal" then [ ] else optionalWorkstationPackages)
    ++ (if (user.packageProfile or "full") == "minimal" then [ ] else virtualizationPackages);
}
