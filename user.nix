# ███╗   ███╗██████╗ ██╗  ██╗███╗   ██╗
# ████╗ ████║██╔══██╗██║  ██║████╗  ██║
# ██╔████╔██║██║  ██║███████║██╔██╗ ██║
# ██║╚██╔╝██║██║  ██║╚════██║██║╚██╗██║
# ██║ ╚═╝ ██║██████╔╝     ██║██║ ╚████║
# ╚═╝     ╚═╝╚═════╝      ╚═╝╚═╝  ╚═══╝
#
# user.nix - Shared defaults committed to the repository
# Override these values locally in user.local.nix.

let
  name = "user";
  fullname = "Your Name";
  locale = "en_US.UTF-8";
  timezone = "Asia/Tokyo";
  hostname = "nixos";
  gitName = "Your Name";
  gitEmail = "";
  packageProfile = "full";
  enableCustomFonts = false;
  enableBcompare5 = true;
  enableGoogleChrome = true;
  enableThunderbird = true;
  enableObsStudio = true;
  enableDavinciResolve = true;
  enableZotero = true;
  enablePodmanDesktop = true;
  enableDistrobox = true;
  enableDistroshelf = true;
  enableTexliveFull = true;
  enableGlobalProtect = true;
  enableVirtManager = true;
  gpuVendor = "generic";
  enableFingerprint = false;
  enableDualBoot = false;
  enableHibernate = false;
  home = "/home/${name}";
  dotroot = "/home/${name}/Documents/MD4N";
  homemanager = "${dotroot}/home-manager";
  cfg = "${homemanager}/config";
  app = "${homemanager}/applications";
in
{
  inherit name fullname locale timezone hostname gitName gitEmail packageProfile enableCustomFonts enableBcompare5 enableGoogleChrome enableThunderbird enableObsStudio enableDavinciResolve enableZotero enablePodmanDesktop enableDistrobox enableDistroshelf enableTexliveFull enableGlobalProtect enableVirtManager gpuVendor enableFingerprint enableDualBoot enableHibernate home dotroot homemanager cfg app;
}
