#
# ███╗   ███╗██████╗ ██╗  ██╗███╗   ██╗
# ████╗ ████║██╔══██╗██║  ██║████╗  ██║
# ██╔████╔██║██║  ██║███████║██╔██╗ ██║
# ██║╚██╔╝██║██║  ██║╚════██║██║╚██╗██║
# ██║ ╚═╝ ██║██████╔╝     ██║██║ ╚████║
# ╚═╝     ╚═╝╚═════╝      ╚═╝╚═╝  ╚═══╝
#
{ config, pkgs, inputs, user, ... }:

let
  packageProfile = user.packageProfile or "full";
in
{
  imports =
    [
      ./hardware-configuration.nix
      ./modules/core.nix
      ./modules/boot.nix
      ./modules/desktop.nix
      ./modules/services.nix
      ./modules/packages.nix
    ]
    ++ (if packageProfile == "minimal" then [ ] else [ ./modules/virtualization.nix ]);
}
