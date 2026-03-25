{ inputs, user, ... }:

# ███╗   ███╗██████╗ ██╗  ██╗███╗   ██╗
# ████╗ ████║██╔══██╗██║  ██║████╗  ██║
# ██╔████╔██║██║  ██║███████║██╔██╗ ██║
# ██║╚██╔╝██║██║  ██║╚════██║██║╚██╗██║
# ██║ ╚═╝ ██║██████╔╝     ██║██║ ╚████║
# ╚═╝     ╚═╝╚═════╝      ╚═╝╚═╝  ╚═══╝

let
  packageProfile = user.packageProfile or "full";
  packageModule =
    if builtins.elem packageProfile [ "minimal" "full" "custom" "max" ] then
      ./modules/packages + "/${packageProfile}.nix"
    else
      throw "Unsupported package profile '${packageProfile}' in user.nix";
in
{
  imports =
    [
      ./modules/core.nix
      ./modules/programs.nix
      ./modules/services.nix
      packageModule
      inputs.nix4nvchad.homeManagerModule
      inputs.nix-hazkey.homeModules.hazkey
    ]
    ++ (if user.enableCustomFonts or false then [ ./modules/fonts.nix ] else [ ]);
}
