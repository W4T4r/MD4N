{ pkgs, inputs, user, ... }:

let
  virtualizationPackages = with pkgs; [
    virt-manager
    dnsmasq
    phodav
  ];
  optionalWorkstationPackages = [
    pkgs.texliveFull
    inputs.globalprotect-openconnect.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
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
