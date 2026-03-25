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
  virtualizationEnabled = (user.enableVirtualization or true) && packageProfile != "minimal";
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
    ++ (if virtualizationEnabled then [ ./modules/virtualization.nix ] else [ ]);
}
