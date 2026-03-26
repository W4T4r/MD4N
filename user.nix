# ███╗   ███╗██████╗ ██╗  ██╗███╗   ██╗
# ████╗ ████║██╔══██╗██║  ██║████╗  ██║
# ██╔████╔██║██║  ██║███████║██╔██╗ ██║
# ██║╚██╔╝██║██║  ██║╚════██║██║╚██╗██║
# ██║ ╚═╝ ██║██████╔╝     ██║██║ ╚████║
# ╚═╝     ╚═╝╚═════╝      ╚═╝╚═╝  ╚═══╝
#
# user.nix - Shared defaults committed to the repository
# Override these values locally in local/generated/user.nix.
let
  name = "user";
  fullname = "Your Name";
  locale = "en_US.UTF-8";
  timezone = "Asia/Tokyo";
  hostname = "nixos";
  gitName = "Your Name";
  gitEmail = "";
  packageProfile = "full";
  enableLocalFonts = false;
  enableVesktop = true;
  enableCava = true;
  enableCodex = true;
  enableClaudeCode = true;
  enableGoogleChrome = true;
  enableThunderbird = true;
  enableZotero = true;
  enablePodmanDesktop = true;
  enableDistrobox = true;
  enableDistroshelf = true;
  enableTexliveFull = true;
  enableVirtualization = true;
  enableVirtManager = true;
  enableOllama = true;
  enableSteam = true;
  gpuVendor = "generic";
  enableFingerprint = false;
  enableDualBoot = false;
  enableHibernate = false;
  home = "/home/${name}";
  dotroot = "/home/${name}/Documents/MD4N";
  homemanager = "${dotroot}/home-manager";
  cfg = "${homemanager}/config";
  app = "${homemanager}/applications";
  faceFile = "";
  browser = "firefox";
  niriBrowserScript = "${home}/.config/md4n/generated/niri/browser.sh";
  niriOutputsFile = "${home}/.config/niri/outputs.local.kdl";
in {
  inherit name fullname locale timezone hostname gitName gitEmail packageProfile enableLocalFonts enableVesktop enableCava enableCodex enableClaudeCode enableGoogleChrome enableThunderbird enableZotero enablePodmanDesktop enableDistrobox enableDistroshelf enableTexliveFull enableVirtualization enableVirtManager enableOllama enableSteam gpuVendor enableFingerprint enableDualBoot enableHibernate home dotroot homemanager cfg app faceFile browser niriBrowserScript niriOutputsFile;
}
